/* 

Statistical Analysis of Merged Data

*/

**# Number of Schools with Tuition Shocks per Year

use "$working_data/cms_aamc_merge_identifier.dta", clear

keep med_school grad_year abs_lg_delta

sort med_school grad_year
by med_school grad_year : gen obsnum = _n
keep if obsnum == 1

collapse (sum) abs_lg_delta, by(grad_year)

drop if abs_lg_delta == 0

g shock_year = grad_year - 1
sum shock_year
local min = r(min)
local max = r(max)

twoway bar abs_lg_delta shock_year, xlabel(`min'(2)`max')title("Schools with Large Tuition Shocks Over Time") ytitle("Number of Schools") xtitle("Shock Year") note("Schools with large tuition shocks observed in combined CMS-AAMC data.")

graph export "$figures/freq_tuition_shocks.png", width(800) height(600) replace


**# How Many Doctors per Grad Year

use "$working_data/cms_aamc_merge_identifier", clear

// keep only one of the doctor observations so as not to double count 
sort npi
egen tag = tag(npi)
keep if tag == 1

collapse (count) npi, by(grad_year)
g npi_th = npi / 1000

label variable npi_th "Number of Doctors (thsnds)"
label variable grad_year "Graduation Year"

twoway bar npi_th grad_year, title("Doctors per Graduation Year") ysc(r(0 .)) ylabel(#12)
graph export "$figures/doc_grad_year.png", width(800) height(600) replace

**# How Many Doctors per School
use "$working_data/cms_aamc_merge_identifier", clear

// keep only one of the doctor observations so as not to double count 
sort npi
egen tag = tag(npi)
keep if tag == 1
drop tag

keep med_school
g doc_school = 1
collapse (count) doc_school, by(med_school)
label variable doc_school "Doctors Observed per School"

egen tag = tag(med_school)
sum tag
local nschool = r(N)

quietly sum doc_school
local totdoc = r(sum)

hist doc_school, freq title("Number of Doctors Observed per School") ytitle("Number of Schools") note("`nschool' schools and `totdoc' unique doctors observed.")

graph export "$figures/doc_per_school.png", width(800) height(600) replace

**# Doctors per Cohort

use "$working_data/cms_aamc_merge_identifier", clear

sort npi
egen tag = tag(npi)
keep if tag == 1 // don't double count doctors

collapse (sum) dum_* // each dum_ is a cohort 

g id = 1

reshape long dum_, i(id) j(cohort) string

rename dum_ cohort_size
label variable cohort_size "School-Cohort Size"

sum cohort_size, detail

local m = round(r(mean), 0.01)
local med = r(p50)
local ten = r(p10)
local ninety = r(p90)

graph twoway hist cohort_size, freq fc(none) lc(green) xline(`m') xline(`med', lc(blue)) xline(`ten', lc(blue)) xline(`ninety', lc(blue)) title("Doctors per School-Cohort") ytitle("Number of Doctors") note("Includes all cohorts of size 0, i.e. no doctor data available for school-grad_year." "10th pctile: `ten' doctors, 50th pctile: `med' doctors, 90th pctile: `ninety' doctors." "Mean: `m' doctors.")

graph export "$figures/school_cohort_size.png", width(800) height(600) replace


drop if cohort_size == 0

sum cohort_size, detail
local m = round(r(mean), 0.01)
local med = r(p50)
local ten = r(p10)
local ninety = r(p90)

graph twoway hist cohort_size, freq fc(none) lc(green) xline(`m') xline(`med', lc(blue)) xline(`ten', lc(blue)) xline(`ninety', lc(blue)) title("Doctors per School-Cohort, Cohort Size > 0") ytitle("Number of Doctors") note("Drops all School-Year cohorts of size 0, i.e. no doctor data available for that School-Year in CMS data." "10th pctile: `ten' doctors, 50th pctile: `med' doctors, 90th pctile: `ninety' doctors." "Mean: `m' doctors.")

graph export "$figures/school_cohort_size_nonzero.png", width(900) height(600) replace

**# Within Cohort Tuition Bill Variation
use "$working_data/cms_aamc_merge_identifier", clear

// Remove unusual data
drop if med_school == "medical university of south carolina college of medicine" // incorrect tuition data

sort npi
egen tag = tag(npi)
keep if tag == 1 

keep tuition_bill npi dum_* med_school grad_year

collapse (count) npi, by(tuition_bill med_school grad_year dum_*)

g spread = 0
g max_tbill = 0
g min_tbill = 0
label variable spread "Tuition Spread Within Cohort (Thsnds 2014USD)"

foreach var of varlist dum_* {
	quietly sum tuition_bill if `var' == 1
	replace min_tbill = r(min) if `var' == 1
	replace max_tbill = r(max) if `var' == 1
}

replace min_tbill = . if tuition_bill == . | tuition_bill[_n - 1] == .
// incomplete tuition data is computed as missing

replace spread = max_tbill - min_tbill
// cohort of one year has spread == 0
// 143 cohorts have only one year

/* Check Outlying Spreads for Incomplete School Data

	keep med_school spread npi grad_year
	collapse (count) npi, by(med_school spread grad_year)

	xtile pct = spread, nq(100)
	sort pct

	drop if spread == .

	egen npi_pop = total(npi)
	g npi_pop = sum(npi)

	g npi_frac = (npi / npi_pop) * 100
	sort npi_frac

	export delimited "$working_data/temp/tuition_spread.csv"

*/

preserve

collapse (mean) spread, by(grad_year)
drop if spread == .

twoway bar spread grad_year, title("Average Tuition Spread Over Time") ytitle("Average Tuition Spread (Th 2014USD)") xtitle("Year") note("Tuition bill is measured in 2014USD.")
graph export "$figures/avg_tuition_spread.png", width(800) height(600) replace

restore

sum spread, d

local m = r(mean)
local med = r(p50)
local ten = r(p10)
local ninety = r(p90)
local nn = r(p99)

local rm = round(`m', 0.001) * 1000
local rmed = round(`med', 0.001) * 1000
local rten = round(`ten', 0.001) * 1000
local rninety = round(`ninety', 0.001) * 1000
local rnn = round(`nn', 0.001) * 1000

graph twoway hist spread, percent fc(none) lc(green) xline(`m') xline(`med', lc(blue)) xline(`ten', lc(blue)) xline(`ninety', lc(blue)) title("Tuition Spread") note("10th pctile: $`rten', 50th pctile: $`rmed', 90th pctile: $`rninety'" "Mean: $`rm'" "Medical University of South Carolina was removed due to incorrect tuition data.")

graph twoway hist spread, freq bin(10) fc(none) lc(green) xline(`m') xline(`med', lc(blue)) xline(`ten', lc(blue)) xline(`ninety', lc(blue)) title("Tuition Spread") ytitle("Number of Cohorts") note("10th pctile: $`rten', 50th pctile: $`rmed', 90th pctile: $`rninety'" "Mean: $`rm'" "Medical University of South Carolina was removed due to incorrect tuition data.")

graph export "$figures/tuition_spread.png", width(800) height(600) replace

drop if spread == 0 // cohort of one year

graph box spread, over(grad_year, lab(angle(45))) title("Tuition Spread by Year (Spread > 0)") note("Spread of 0 is typically a cohort of one year. Removed for clarity." "Medical University of South Carolina was removed due to incorrect tuition data.")

graph export "$figures/yearly_tuition_spread.png", width(800) height(600) replace

sum spread, d

local m = r(mean)
local med = r(p50)
local ten = r(p10)
local ninety = r(p90)
local nn = r(p99)

local rm = round(`m', 0.001) * 1000
local rmed = round(`med', 0.001) * 1000
local rten = round(`ten', 0.001) * 1000
local rninety = round(`ninety', 0.001)* 1000
local rnn = round(`nn', 0.001) * 1000

graph twoway hist spread, freq bin(10) fc(none) lc(green) xline(`m') xline(`med', lc(blue)) xline(`ten', lc(blue)) xline(`ninety', lc(blue)) title("Tuition Spread (Spread > 0)") note("Spread of 0 is typically a cohort of one year. Removed for clarity." "10th pctile: $`rten', 50th pctile: $`rmed', 90th pctile: $`rninety'" "Mean: $`rm'" "Medical University of South Carolina was removed due to incorrect tuition data.")

graph export "$figures/tuition_spread_nonzero.png", width(800) height(600) replace


**# How many doctors per center-year (evaluate group-pac FE)
use "$working_data/cms_aamc_merge_identifier", clear

// keep only one of the doctor observations so as not to double count 
sort npi
egen tag = tag(npi)
keep if tag == 1
drop tag

keep npi groupPAC ngroupPAC year

drop if groupPAC == " "
drop if ngroupPAC == .
drop groupPAC


collapse (count) npi, by(ngroupPAC year)
rename npi doc_pac
label variable doc_pac "Doctors per GroupPAC-Year"

egen tag = tag(ngroupPAC year)
quietly sum tag

local tot_doc = r(sum)
count if doc_pac == 1
local one_doc = r(N)
local pct_onedoc = round((`one_doc' / `tot_doc') * 100, 0.01)

quietly sum doc_pac, d

local m = round(r(mean), 0.01)
local med = r(p50)
local ten = r(p10)
local ninety = r(p90)
local nf = r(p95)
local nn = r(p99)

graph twoway hist doc_pac, freq ylabel(, format(%9.0fc)) fc(none) lc(green) xline(`m') xline(`med', lc(blue)) xline(`ten', lc(blue)) xline(`ninety', lc(blue)) title("GroupPAC-Year Size") ytitle("Number of GroupPAC-Years") note("10th pctile: `ten' doctor, 50th pctile: `med' doctor, 90th pctile: `ninety' doctors" "Mean: `m' doctors" "GroupPAC-Year has size of 1 for `one_doc' GroupPAC-Year (~`pct_onedoc'%)")

graph export "$figures/grouppac_year_size_all.png", width(800) height(600) replace

preserve

quietly sum doc_pac, d

local m = round(r(mean), 0.01)
local med = r(p50)
local ten = r(p10)
local ninety = r(p90)
local nf = r(p95)
local nn = r(p99)

drop tag
egen tag = tag(ngroupPAC year)
quietly sum tag

local tot_doc = r(sum)
count if doc_pac == 1
local one_doc = r(N)
local pct_onedoc = round((`one_doc' / `tot_doc') * 100, 0.01)

local cut = `nf' + 1

keep if doc_pac <= `cut'

graph twoway hist doc_pac, freq bin(`nf') ylabel(, format(%9.0fc)) fc(none) lc(green) xline(`m') xline(`med', lc(blue)) xline(`ten', lc(blue)) xline(`ninety', lc(blue)) title("GroupPAC Size, 95%") ytitle("Number of GroupPAC-Years") note("Number of doctors per GroupPAC < `cut'" "10th pctile: `ten' doctor, 50th pctile: `med' doctor, 90th pctile: `ninety' doctors" "Mean: `m' doctors" "GroupPAC-Year has size of 1 for `one_doc' GroupPAC-Year (~`pct_onedoc'%)")

graph export "$figures/grouppac_year_size_95pct.png", width(800) height(600) replace


restore

preserve

quietly sum doc_pac, d

local m = round(r(mean), 0.01)
local med = r(p50)
local ten = r(p10)
local ninety = r(p90)
local nf = r(p95)
local nn = r(p99)

local cut = `nf' + 1

keep if doc_pac > `cut'

drop tag
egen tag = tag(ngroupPAC grad_year)
quietly sum tag

local tot_doc = r(sum)
count if doc_pac == 1
local one_doc = r(N)
local pct_onedoc = round((`one_doc' / `tot_doc') * 100, 0.01)

graph twoway hist doc_pac, freq ylabel(, format(%9.0fc)) fc(none) lc(green) xline(`m') xline(`med', lc(blue)) xline(`ten', lc(blue)) xline(`ninety', lc(blue)) title("GroupPAC Size, Top 5%") ytitle("Number of GroupPAC-Years") note("Number of doctors per GroupPAC > `cut'" "10th pctile: `ten' doctor, 50th pctile: `med' doctor, 90th pctile: `ninety' doctors" "Mean: `m' doctors")

graph export "$figures/grouppac_year_size_top5pct.png", width(800) height(600) replace


restore




