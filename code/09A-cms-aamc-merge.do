/* 

PREAMBLE

This file merges cms data (doctor characteristics) onto aamc data (school characteristics).
Prepares data for cohort-dummies on Revamp of Empirical Strategy.
   
Victoria Garcia 
10.17.2025
*/

*** LOAD WORKING DATA ***

use "$working_data/aamc_large_identifier", clear

*** Merge school and doctor data ***
merge 1:m med_school grad_year using "$working_data/panels/cms-panel"

*** SAVE MERGED DATA ***
keep if _merge==3
drop _merge
									

egen id = group(year npi)
label variable id "doctor-year identifier"

encode groupPAC, gen(ngroupPAC)

save "$working_data/cms_aamc_merge_identifier.dta", replace

/* * ANLYSIS OF UNMERGED DATA *

use "$working_data/aamc_large_identifier", clear
merge 1:m med_school grad_year using "$working_data/panels/cms-panel"

by med_school grad_year, sort: gen nschool_yr = _n == 1
count if nschool_yr == 1
// count unique school and year combo = 7,588

by npi grad_year, sort: gen ndoc_yr = _n == 1
count if ndoc_yr == 1
// count unique doctor and year combo = 313,480


/* Merge Reference: 

	Not matched from school data = 1,120
		
	Not matched from doctor data = 580,565
		
	Matched = 1,600,942
		> med school names matched
		> med school data is available for that year
		
	To Check:
		> med schools are not missing exact name matches even though data is available for that year
		
	Notes:
		After cursory exploration, there does not seem to be mismatches in the data, but we can 
		identify additional data to collect using doc_data_missing_school.csv.
*/

*** Explore what parts of the merge are missing ***
* Which schools are not matched?
preserve

keep if _merge==1
count if nschool_yr == 1							  // 1,120 unique school + year dropped

keep med_school PublicSchool source grad_year
export delimited "$working_data/merge_unmatched/unmatched_schools_year.csv", replace // to check discrepencies in school name + year
by med_school, sort: gen nvals = _n == 1
count if nvals == 1										  // 463 school-year not matched
keep if nvals == 1

export delimited "$working_data/merge_unmatched/unmatched_schools.csv", replace	  // to check discrepencies in school name

restore

* Which doctors are not matched?
preserve

keep if _merge==2
count if ndoc_yr == 1								  // 75,108 unique doc + year dropped

keep if ndoc_yr == 1
keep grad_year npi med_school
export delimited "$working_data/merge_unmatched/unmatched_doctors.csv", replace

* Which schools do we have doctor data for but no matched school data?
by grad_year med_school, sort: gen ndoc_school_yr = _n == 1
count if ndoc_school_yr == 1 						  // 3,556 school-year data points have doctor data but no school data
keep if ndoc_school_yr == 1
drop ndoc_school_yr
export delimited "$working_data/merge_unmatched/doc_data_missing_school.csv", replace

restore
*/


/* * ANALYSIS OF MERGED DATA *


*** COHORT 	LENGTH FREQUENCIES ***

use "$working_data/aamc_large_identifier", clear

* distribution of cohort lengths

// identify cohort characteristics by cohort name (dum_*)
preserve

collapse (sum) dum_*

g id = 1

reshape long dum_, i(id) j(dum_str) string

rename dum_ cohort_length
replace dum_str = "dum_" + dum_str

g cvar = ""
replace cvar = "c1" if cohort_length == 1
replace cvar = "c2" if cohort_length == 2
replace cvar = "c3" if cohort_length == 3
replace cvar = "c4" if cohort_length == 4
save "$working_data/cohort_characteristics", replace
	
restore

// merge on the cohort characteristics and analyze
use "$working_data/cms_aamc_merge_identifier.dta", clear

keep school_id id year cohort_reason dum_* 

g split = ceil(_n / (_N/20))

forvalues i = 1/20 {
	preserve 
	keep if split == `i'
	save "$working_data/split_data/aamc_cms_merge_`i'.dta", replace
	restore
}


clear
save "$working_data/aamc_cms_cohort_character.dta", emptyok replace

forvalue i = 1/20 {
	use "$working_data/split_data/aamc_cms_merge_`i'.dta", clear
	reshape long dum_, i(id) j(dum_str) string
	keep if dum_ == 1 // keeps the cohort that individual belongs to
	replace dum_str = "dum_" + dum_str
	
	merge m:1 dum_str using "$working_data/cohort_characteristics.dta" // most are matched
	keep if _merge == 3
	drop _merge
	sort id
	
	append using "$working_data/aamc_cms_cohort_character.dta"
	save "$working_data/aamc_cms_cohort_character.dta", replace
	
}

*/
