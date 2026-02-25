*** Stats for Presentation, Feb 2026 ***



* doctor billing data *

use "$working_data/cms_aamc_cohort_id.dta", clear

egen tag = tag(npi)
quietly sum tag
display "Number of doctors: `r(sum)'"
drop tag

quietly sum year
display "Sample period for billing data: `r(min)' - `r(max)'"

egen tag = tag(npi year)
quietly sum tag
display "Number of doctor-year observations: `r(sum)'"
drop tag

sort groupPAC
g tag = 1 if groupPAC != ""
quietly sum tag
display "Data includes identifier for medical center in which doctor works: `r(sum)'"
drop tag

egen tag = tag(groupPAC)
quietly sum tag
display "Number of medical centers: `r(sum)'"
drop tag

sort hrr
g tag = 1 if hrr != .
quietly sum tag
display "Data includes indentifier for hospital referral regions in which doctor works: `r(sum)'"
drop tag

egen tag = tag(hrr)
quietly sum tag
display "Number of hospital referral regions: `r(sum)'"
drop tag

g tag = 0
foreach code in avg_mdcr* {
	quietly sum(`code')
	replace tag = 1 if `r(max)' != 0
}
quietly sum tag
display "Includes procedure identifier billed to Medicare: `r(sum)'"
drop tag

g tag = 1 if phySpec_id != .
quietly sum tag
display "Includes identifier for specialization: `r(sum)'"
drop tag

egen tag = tag(phySpec_id)
quietly sum tag
display "Number of specializations: `r(sum)'"
drop tag


* tuition data *

use "$working_data/panels/aamc-tuition", clear

egen tag = tag(med_school)
quietly sum tag
display "Number of schools: `r(sum)'"
drop tag

quietly sum aca_year
display "Sample period for medical school data: `r(min)' - `r(max)'"

egen tag = tag(med_school aca_year)
sum(tag)
display "Number of school-year observations: `r(sum)'"



* statistics on cohorts *

use "$working_data/cms_aamc_cohort_id.dta", clear

egen tag = tag(med_school)
quietly sum(tag)
display "Total number of schools: `r(sum)'"
drop tag

egen tag = tag(cohort_id)
quietly sum(tag)
display "Total number of school cohorts: `r(sum)'"

preserve

keep if tag == 1
keep med_school grad_year cohort_id cohort_reason
sort med_school grad_year cohort_id
egen n_cohort_school = count(cohort_id), by(med_school)
quietly sum(n_cohort_school), d
display "Number of cohorts per school: `r(p50)' (median), `r(mean)' (mean)"

graph pie, over(cohort_reason) sort descending legend(off) plabel(_all percent, color(black) size(medium) format(%9.1f)) plabel(1 name, color(black) size(medium) gap(32)) plabel(2 name, color(black) size(medium) gap(21)) plabel(3 name, color(black) size(medium) gap(26)) plabel(4 name, color(black) size(medium) gap(20))

graph export "$figures/cohort_reset_reason.png", width(976) height(600) replace

restore

* histogram of cohort lengths, % of cohorts *

drop tag
egen tag = tag(cohort_id grad_year)

preserve

keep if tag == 1
egen cohort_length = count(cohort_id), by(cohort_id)
tostring cohort_length, replace
encode cohort_length, g(length_id)
destring cohort_length, replace

drop tag

egen tag = tag(cohort_id)
label variable length_id "Cohort Length"
hist length_id, percent ytitle("Fraction of All Cohorts")
graph export "$figures/cohort_length_pctcohorts.png", replace


tempfile c_length
keep cohort_id length_id tag
keep if tag == 1
save `c_length'

restore

drop tag

preserve

egen tag = tag(npi)
keep if tag == 1

merge m:1 cohort_id using `c_length'
keep if _merge == 3
drop _merge

hist length_id, percent ytitle("Fraction of All Doctors")
graph export "$figures/cohort_length_pctdoctors.png", replace

restore




