/* 

Statistical Analysis of Merged Data

*/

use "$working_data/cms_aamc_merge_identifier.dta", clear

collapse (sum) abs_lg_delta, by(grad_year)
sum grad_year
loc min = r(min)
loc max = r(max)
twoway bar abs_lg_delta grad_year, xlabel(`min'(2)`max') xtitle("Year") ytitle("Number of Large Tuition Shocks") note("Large Tuition Shock = $2000 (2014USD)") title("Frequency of Tuition Shocks Over Time")

graph export "$dropbox/Tuition Data/figures/freq_tuition_shocks.png", width(800) height(600) replace

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

**# How Many Doctors per School
use "$working_data/cms_aamc_merge_identifier", clear

// keep only one of the doctor observations so as not to double count 
sort npi
egen tag = tag(npi)
keep if tag == 1

tab med_school, collect
collect dir
collect label list med_school
collect export "$tables/medschool_freq.tex", tableonly replace
collect export "$tables/medschool_freq.html", replace

**# How Complete is School Data for Available Doctors
// count skipped grad_year?

**# Doctors per Cohort

use "$working_data/cms_aamc_merge_identifier", clear

sort npi
egen tag = tag(npi)
keep if tag == 1

collapse (sum) dum_* // each dum_ is a cohort 

g id = 1

reshape long dum_, i(id) j(cohort) string

rename dum_ cohort_size
label variable cohort_size "School-Cohort Size"

sum cohort_size, detail

local m = r(mean)
local med = r(p50)
local ten = r(p10)
local ninety = r(p90)

graph twoway hist cohort_size, freq fc(none) lc(green) xline(`m') xline(`med', lc(blue)) xline(`ten', lc(blue)) xline(`ninety', lc(blue)) title("Frequency of School-Cohort Sizes") note("Includes all cohorts of size 0, i.e. no doctor data available for school-grad_year." "10th pctile: `ten', 50th pctile: `med', 90th pctile: `ninety'" "Median: `med'")

drop if cohort_size == 0

sum cohort_size, detail
local m = r(mean)
local med = r(p50)
local ten = r(p10)
local ninety = r(p90)

graph twoway hist cohort_size, freq fc(none) lc(green) xline(`m') xline(`med', lc(blue)) xline(`ten', lc(blue)) xline(`ninety', lc(blue)) title("Frequency of School-Cohort Sizes") note("Drops all school-grad_year cohorts of size 0." "10th pctile: `ten', 50th pctile: `med', 90th pctile: `ninety'" "Median: `med'")

**# Within Cohort Tuition Bill Variation
use "$working_data/cms_aamc_merge_identifier", clear

sort npi
egen tag = tag(npi)
keep if tag == 1

reshape long dum_, i(tuition_bill npi) j(cohort) string



// number of cohorts observed per school

collapse (sum) dum_*, by(med_school) // each dum_ is a cohort 