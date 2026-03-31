*******************************************
*** DOCTOR-YEAR-isEM REGRESSIONS ***
*******************************************

* Description of this do-file:

* 	Regressions with isEM fixed effects

*****************************************
*****************************************
*****************************************

use "$working_data/cms_aamc_isEM_id", clear

keep if both == 1


*** All Cohorts ***

g tag = 1 if all_total_payments == 0

eststo clear


eststo : reghdfe all_total_payments c.tuition_bill#1.isEM, a(npi#year cohort_id#year#isEM hrr#year#isEM phySpec_id#year#isEM#time_since_grad_id) vce(cluster cohort_id)

** Mean:
sum all_total_payments if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[c.tuition_bill#1.isEM] / r(mean)
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

esttab est*, drop(_cons) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(npi#year "Doctor-Year FE" cohort_id#year#isEM "Cohort-Year-EM FE" hrr#year#isEM "Region-Year-EM FE" phySpec_id#year#isEM#time_since_grad_id "Specialization-Year-EM-Career FE")						
	
esttab est* using "$tables/fe-regs-isEM-all_total_payments.tex", ///
	drop(_cons) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_drs N_clust /* unique_schools */ mean pct_mean nzero, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1) labels("Observations (doctor-year-em)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef. % of Mean" "nzero")) ///
	replace
	


*** Cohorts with Variation (Tuition Spread > $1000 USD2014) ***

use "$working_data/cms_aamc_isEM_id", clear

drop if med_school == "medical university of south carolina college of medicine" // incorrect tuition data

bysort cohort_id: egen max_tbill = max(tuition_bill)
bysort cohort_id: egen min_tbill = min(tuition_bill)
g spread = max_tbill - min_tbill
label variable spread "Tuition Bill Spread (Thousands)"

keep if spread > 1 // keep if tuition bill spread > $1000
// 1,119,538 / 2,261,032 = ~50% of observations deleted 

g tag = 1 if all_total_payments == 0

eststo clear

eststo : reghdfe all_total_payments c.tuition_bill#1.isEM, a(npi#year cohort_id#year#isEM hrr#year#isEM phySpec_id#year#isEM#time_since_grad_id) vce(cluster cohort_id)

** Mean:
sum all_total_payments if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[c.tuition_bill#1.isEM] / r(mean)
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

esttab est*, drop(_cons) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(npi#year "Doctor-Year FE" cohort_id#year#isEM "Cohort-Year-EM FE" hrr#year#isEM "Region-Year-EM FE" phySpec_id#year#isEM#time_since_grad_id "Specialization-Year-EM-Career FE")						
	
esttab est* using "$tables/variation-fe-regs-isEM-all_total_payments.tex", ///
	drop(_cons) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_drs N_clust /* unique_schools */ mean pct_mean nzero, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1) labels("Observations (doctor-year-em)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef. % of Mean" "nzero")) ///
	replace

