* WHY NO STATISTICAL SIGNIFICANCE AFTER DROPPING ZEROES AND CHANGING REGRESSION SPECIFICATION? *

* Old regression specification without impouted zeroes, with tuition bill variation (10A-oldbaseline-regressions.do) *

global outcome "fg_sel3_total_payments fg_sel5_total_payments"

use "$working_data/cms_aamc_cohort_id", clear

drop if med_school == "medical university of south carolina college of medicine" // incorrect tuition data

bysort cohort_id: egen max_tbill = max(tuition_bill)
bysort cohort_id: egen min_tbill = min(tuition_bill)
g spread = max_tbill - min_tbill
label variable spread "Tuition Bill Spread (Thousands)"

keep if spread > 1 // keep if tuition bill spread > $1000
// 406,610 / 1,549,937 = ~26% of observations deleted 

foreach oc of global outcome {
	
	g tag = 1 if `oc' == 0
	
	eststo clear
	
	* row 1: baseline regression with cohort, event time and time since graduation *
	eststo : reghdfe `oc' tuition_bill, a(cohort_id#year time_since_grad_id) vce(cluster school_id)

	* Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[tuition_bill] / r(mean)
	estadd scalar pct_mean

	* Unique doctors
	unique npi if e(sample) == 1
	estadd scalar unique_drs = r(unique)

	* unique schools
	unique med_school if e(sample) == 1
	estadd scalar unique_schools = r(unique)
	
	* row 2: add phySpec_id and event time FE

	eststo : reghdfe `oc' tuition_bill, a(cohort_id#year time_since_grad_id phySpec_id#year) vce(cluster school_id)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[tuition_bill] / r(mean)
	estadd scalar pct_mean

	** Unique doctors
	unique npi if e(sample) == 1
	estadd scalar unique_drs = r(unique)

	** unique schools
	unique med_school if e(sample) == 1
	estadd scalar unique_schools = r(unique)
	
	* row 3: add referral region (HRR) and event time FE
	
	eststo : reghdfe `oc' tuition_bill, a(cohort_id#year time_since_grad_id phySpec_id#year hrr#year) vce(cluster school_id)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[tuition_bill] / r(mean)
	estadd scalar pct_mean

	** Unique doctors
	unique npi if e(sample) == 1
	estadd scalar unique_drs = r(unique)

	** unique schools
	unique med_school if e(sample) == 1
	estadd scalar unique_schools = r(unique)
	
	* row 4: replace, time since graduation and event time
	
	eststo : reghdfe `oc' tuition_bill, a(cohort_id#year time_since_grad_id#year phySpec_id#year hrr#year) vce(cluster school_id)

	** Mean:
	sum `oc' if e(sample) == 1
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
	estfe . est*, labels(cohort_id#year "Cohort-Year FE" time_since_grad_id "Career Time FE" phySpec_id#year "Specialization-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career Time-Year FE")						
		
	esttab est* using "$tables/variation-fe-regs-`oc'-nozeroes.tex", ///
		keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N unique_drs N_clust /* unique_schools */ mean pct_mean nzero, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1 %9.0fc) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef.\ \% of Mean" "Zeroes")) ///
		replace
		
	drop tag
}


* new regression specification with imputed zeroes * 


*** BASELINE REGRESSIONS WITH TUITION BILL VARIATION ***
use "$working_data/cms_aamc_cohort_id_zeros", clear

drop if med_school == "medical university of south carolina college of medicine" // incorrect tuition data

bysort cohort_id: egen max_tbill = max(tuition_bill)
bysort cohort_id: egen min_tbill = min(tuition_bill)
g spread = max_tbill - min_tbill
label variable spread "Tuition Bill Spread (Thousands)"

keep if spread > 1 // keep if tuition bill spread > $1000
// 406,610 / 1,549,937 = ~26% of observations deleted 

foreach oc of global outcome {
	
	g tag = 1 if `oc' == 0
	
	eststo clear

	
	* row 1: Specialization#Career Time#Year
	
	eststo : reghdfe `oc' tuition_bill, a(cohort_id#year phySpec_id#time_since_grad_id#year hrr#year) vce(cluster school_id)

	** Mean:
	sum `oc' if e(sample) == 1
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
	
	* row 2: no controls for Specialization
	eststo : reghdfe `oc' tuition_bill, a(cohort_id#year time_since_grad_id#year hrr#year) vce(cluster school_id)
	
	** Mean:
	sum `oc' if e(sample) == 1
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
	estfe . est*, labels(cohort_id#year "Cohort-Year FE" hrr#year "HRR-Year FE" phySpec_id#time_since_grad_id#year "Specialization-Career-Year FE" time_since_grad_id#year "Career-Year FE")						
		
	esttab est* using "$tables/newbaseline-fe-regs-`oc'.tex", ///
		keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N unique_drs N_clust /* unique_schools */ mean pct_mean nzero, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1 %9.0fc) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef.\ \% of Mean" "Zeroes")) ///
		replace
		
	drop tag
}