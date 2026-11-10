*************************************************
*** STANDARDIZE AND CLEAN DOC CHARACTERISTICS ***
*************************************************


**# Standardize Data

clear
forvalues n = 2013/2025 { // 2011/2025

	append using "$working_data/temp/minimal-chars-`n'"
	
}

label var grad_year "Calendar Graduation Year (e.g. graduating in 2000-2001 -> grad_year = 2001)"
label var our_med_school "Graduated from School (our name)"

do "$do/clean-phySpec.do"

rename phySpec phySpec_chara
label var phySpec_chara "Physician Characteristics as reported by Doctors and Clinicians"

* Drop if our_med_school or grad_year is always missing *

replace our_med_school = "" if our_med_school == "OTHER"
replace grad_year = . if grad_year < $min_grad_year

bys npi : egen has_grad_year = max(!missing(grad_year))
drop if has_grad_year == 0
drop has_grad_year

bys npi : egen has_ms = max(!missing(our_med_school))
drop if has_ms == 0
drop has_ms

* Populate credentials
replace cred = subinstr(cred, " ", "", .)
replace cred = subinstr(cred, ".", "", .)
replace cred = subinstr(cred, ",", "", .) if strpos(cred, ",") == length(cred)

g isMD_year = strpos(cred, "MD") > 0

bys npi : egen isMD = max(isMD_year)

drop isMD_year
replace cred = "MD" if isMD == 1
keep if isMD == 1 // Only Look At Doctors Relevant to Current Analysis

* Check to see how many different med schools / grad years each doc reported
egen tag_gy = tag(npi grad_year)
bys npi : egen gy_cnt = total(tag_gy) 											// 97.30% of npi-grad_year appear once

egen tag_ms = tag(npi our_med_school)
bys npi : egen ms_cnt = total(tag_ms)											// 95.96% of npi-our_med_school appear once
drop tag_*

g mult_grad_year = (gy_cnt > 1)
g mult_med_school = (ms_cnt > 1)

gen zip5 = ""
replace zip5 = substr(zip, 1, 5)

* Standardize med school names
do "$do/clean-npi-medschool-names.do"

* Save standardized data with all years 
save "$working_data/temp/doc_characteristics_standardized", replace


**# Remove Duplicates
use "$working_data/temp/doc_characteristics_standardized", clear

** Which zipcodes are also in the billing data

merge m:1 npi zip5 year using "$working_data/temp/unique_doc_zip_year"
drop if _merge == 2
drop _merge

replace doc_zip_year_inbilling = 0 if doc_zip_year_inbilling == .

gsort npi year grad_year our_med_school -doc_zip_year_inbilling, g(priority)

bys npi year priority : g nun = _n
keep if nun == 1

drop nun 

** Extract zipcode-groupPAC crosswalk, so data can be collapsed to npi-year level
preserve
drop if groupPAC == ""
drop if groupPAC == " "
bys groupPAC zip5 doc_zip_year_inbilling : g nun = _n 
keep if nun == 1

keep groupPAC zip5 doc_zip_year_inbilling
save "$working_data/temp/zip5_groupPAC_crosswalk", replace
restore

** Collapse to unique npi-year level, prioritize zipcodes in billing data, otherwise random
bys npi year (priority) : g nun_npi_year = _n
keep if nun_npi_year == 1 // data is unique at npi year level

** Select the most recent npi-year to standardize med_school and grad_year over time
bys npi : egen max_year = max(year) if grad_year != .
bys npi : egen min_year = min(year) if grad_year != .

g recent_grad_year = grad_year if(year == max_year)
gsort npi -recent_grad_year
bysort npi : replace recent_grad_year = recent_grad_year[1] if recent_grad_year == .

drop max_year min_year

bys npi : egen max_year = max(year) if our_med_school != ""
bys npi : egen min_year = min(year) if our_med_school != ""

g recent_med_school = our_med_school if(year == max_year)
bysort npi (recent_med_school): replace recent_med_school = recent_med_school[_N] if recent_med_school == ""

bys npi : egen has_ms = max(!missing(recent_med_school))
drop if has_ms == 0 // ensures all observations have med school
drop has_ms

bys npi : egen has_grad_year = max(!missing(recent_grad_year))
drop if has_grad_year == 0 // ensures all observations have grad year
drop has_grad_year

drop max_year min_year nun_npi_year our_med_school grad_year
rename recent_grad_year grad_year
rename recent_med_school med_school

sort npi year
* Save cleaned data with all years 
save "$working_data/temp/doc_characteristics_clean", replace


**# Make Panel Well Behaved
use "$working_data/temp/doc_characteristics_clean", clear

local time_invariant cred isMD gy_cnt ms_cnt mult_grad_year mult_med_school grad_year med_school

preserve

keep `time_invariant' npi
collapse (first) `time_invariant', by(npi)
tempfile invariant
save `invariant'

restore

preserve
keep npi year groupPAC phySpec_chara zip* doc_zip_year_inbilling
tempfile variant
save `variant'
restore

use `invariant', clear
keep npi 
tempfile npi_list
save `npi_list'

use `npi_list', clear
g year = 2012
expand 14
bys npi: replace year = 2012 + _n - 1
tempfile skeleton
save `skeleton'

use `skeleton', clear
merge m:1 npi using `invariant'
drop _merge

merge 1:1 npi year using `variant'
drop _merge

* Check consistency of panel:
bys npi  year  : assert _N == 1 // (npi, year) idenitifies observations
// bys npi (year) : g delta_year = year[_n + 1] - year[_n] if _n < _N // checking gaps
// drop delta_year

* Event time:
g event_time = year - grad_year
label var event_time "Years Since Graduation"

* Panel should start the year after the graduation year:
drop if event_time <= 0

save "$working_data/temp/doc_characteristics_clean_balanced", replace

use "$working_data/temp/doc_characteristics_clean_balanced", clear

forvalues n = 13/19 {
	preserve
	keep if year == 20`n'
	save "$working_data/temp/doc_characteristics_clean_balanced_`n'", replace
	restore
}