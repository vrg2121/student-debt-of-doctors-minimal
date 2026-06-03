* To Do From April, 2 2026 *


** do we have doctors that never bill? ***
use "$working_data/temp/cms-panel-clean-name", clear

* Exploring the raw doctor data *
// Merge in payments variable (already inflation adjusted):
merge 1:1 npi year using "$working_data/temp/emiel-total_payments-fg-hcpcs-codes"

// Doctors who never receive a payment:
bys npi (_merge) : g no_pay_ever = _merge[1] == 1 & _merge[_N] == 1

keep if ent_cd == "I" // only measure individuals, not organizations
tab no_pay_ever // 100% of doctors receive payments at some point

* exploring the merged doctor data *
use "$working_data/cms_aamc_cohort_id", clear

g missing_pymt = (fg_sel3_total_payments == .)

bys npi: g pre_career = (year - grad_year < 5)

// how many doctors bill in the "pre-career" period, before the 4 years post-graduation
by npi: g pre_career_missing = (pre_career == 1 & missing_pymt == 1) // 18.19% of doc-year data
drop if pre_career_missing == 1

by npi: g pre_career_bill = (pre_career == 1 & missing_pymt == 0) // 3.88% of doc-year data

tab missing_pymt // 19.26% of doctor-years missing cms payment data (within career)

preserve
bysort npi: egen ever_missing = max(missing_pymt)
egen tag = tag(npi)
keep if tag == 1
tab missing_pymt // 22.18% of doctors are missing cms payment data at some point 2012-2019
restore

preserve

collapse (mean) frac_missing = missing_pymt, by(year)
g pct_missing = frac_missing * 100

graph bar (asis) pct_missing, over(year) ytitle("Percent (%)")

graph export "$figures/missing_doc_per_year.png", replace

restore

sort npi year

by npi: egen last_year_bill = max(year) // 98.36% of the data last_year == 2019
g missing_type = ""
replace missing_type = "open_ended" if (last_year_bill < 2019 & missing_pymt == 1) // 0.64% of doc-year data
replace missing_type = "book_ended" if (last_year_bill == 2019 & missing_pymt == 1) // 18.62% of doc-year data
replace missing_type = "not_missing" if missing_pymt == 0

preserve

keep if missing_pymt == 1
tab missing_type
// 96.69% of missings are book ended
// 3.31% of missings are open ended

restore

* regression on doctor-years that acccept / do not accept CMS payments *

drop if med_school == "medical university of south carolina college of medicine" // incorrect tuition data

bysort cohort_id: egen max_tbill = max(tuition_bill)
bysort cohort_id: egen min_tbill = min(tuition_bill)
g spread = max_tbill - min_tbill
label variable spread "Tuition Bill Spread (Thousands)"

keep if spread > 1 // keep if tuition bill spread > $1000
// 702,150 / 1,536,599 = ~46% of observations deleted 
		
g tag = 1 if missing_pymt == 0

drop if pre_career == 1 // drop doctors not yet practicing
eststo clear

* row 1: Cohort#Year

eststo : reghdfe missing_pymt tuition_bill, a(cohort_id#year) vce(cluster cohort_id)

** Mean:
sum missing_pymt if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[tuition_bill] / r(mean)
estadd scalar pct_mean

** Unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

** number of zeros
sum tag if e(sample) == 1
estadd scalar nzero = r(sum)

* row 2: Cohort#Year HRR#Year

eststo : reghdfe missing_pymt tuition_bill, a(cohort_id#year hrr#year) vce(cluster cohort_id)

** Mean:
sum missing_pymt if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[tuition_bill] / r(mean)
estadd scalar pct_mean

** Unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

** number of zeros
sum tag if e(sample) == 1
estadd scalar nzero = r(sum)

* row 3: Cohort#Year HRR#Year Career_Time#Year 
eststo : reghdfe missing_pymt tuition_bill, a(cohort_id#year hrr#year time_since_grad_id#year) vce(cluster cohort_id)

** Mean:
sum missing_pymt if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[tuition_bill] / r(mean)
estadd scalar pct_mean

** Unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

** number of zeros
sum tag if e(sample) == 1
estadd scalar nzero = r(sum)

* row 4: Cohort#Year HRR#Year Career_Time#Year Specialization#Year 
eststo : reghdfe missing_pymt tuition_bill, a(cohort_id#year hrr#year time_since_grad_id#year phySpec_id#year) vce(cluster cohort_id)

** Mean:
sum missing_pymt if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[tuition_bill] / r(mean)
estadd scalar pct_mean

** Unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

** number of zeros
sum tag if e(sample) == 1
estadd scalar nzero = r(sum)

* row 5: Cohort#Year HRR#Year Specialization#Career_Time#Year 
eststo : reghdfe missing_pymt tuition_bill, a(cohort_id#year hrr#year phySpec_id#time_since_grad_id#year) vce(cluster cohort_id)

** Mean:
sum missing_pymt if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[tuition_bill] / r(mean)
estadd scalar pct_mean


** Unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

** number of zeros
sum tag if e(sample) == 1
estadd scalar nzero = r(sum)

* format output

esttab est*, keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(cohort_id#year "Cohort-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career-Year FE" phySpec_id#year "Specialization-Year FE" phySpec_id#time_since_grad_id#year "Specialization-Career-Year FE")						
	
esttab est* using "$tables/nozero_newbaseline-fe-regs-missing_pymt.tex", ///
	keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_drs N_clust /* unique_schools */ mean pct_mean nzero, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1 %9.0fc) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef. \% of Mean" "Zeroes")) ///
	replace
	
drop tag

