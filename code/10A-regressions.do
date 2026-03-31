/*
PREAMBLE

New Baseline regression.
   
Victoria Garcia 
March 2026

*/

clear all

*** SET VARIABLES FOR REGRESSIONS ***

/* Outcome Variable Descriptions

	fg_sel3_total_payments = Total CMS Payments
	fg_sel3_nServ = Total Number of CMS Services
	fg_sel5_total_payments = Payments: E/M Codes
	fg_sel5_nServ = Total Number of CMS E/M Services
	pp_payment = Dummy Variable for Kickback Payments

*/

global outcome "all_total_payments fg_sel3_total_payments fg_sel3_nServ fg_sel5_nServ fg_sel5_total_payments pp_payment"


*** BASELINE REGRESSIONS WITH TUITION BILL VARIATION ***
use "$working_data/cms_aamc_cohort_id", clear

drop if med_school == "medical university of south carolina college of medicine" // incorrect tuition data

bysort cohort_id: egen max_tbill = max(tuition_bill)
bysort cohort_id: egen min_tbill = min(tuition_bill)
g spread = max_tbill - min_tbill
label variable spread "Tuition Bill Spread (Thousands)"

keep if spread > 1 // keep if tuition bill spread > $1000
// 702,150 / 1,536,599 = ~46% of observations deleted 

foreach oc of global outcome {
		
	g tag = 1 if `oc' == 0
	
	eststo clear
	
	* row 1: Cohort#Year
	
	eststo : reghdfe `oc' tuition_bill, a(cohort_id#year) vce(cluster cohort_id)

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
	
	* row 2: Cohort#Year HRR#Year
	
	eststo : reghdfe `oc' tuition_bill, a(cohort_id#year hrr#year) vce(cluster cohort_id)

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
	
	* row 3: Cohort#Year HRR#Year Career_Time#Year 
	eststo : reghdfe `oc' tuition_bill, a(cohort_id#year hrr#year time_since_grad_id#year) vce(cluster cohort_id)

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
	
	* row 4: Cohort#Year HRR#Year Career_Time#Year Specialization#Year 
	eststo : reghdfe `oc' tuition_bill, a(cohort_id#year hrr#year time_since_grad_id#year phySpec_id#year) vce(cluster cohort_id)

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
	
	* row 5: Cohort#Year HRR#Year Specialization#Career_Time#Year 
	eststo : reghdfe `oc' tuition_bill, a(cohort_id#year hrr#year phySpec_id#time_since_grad_id#year) vce(cluster cohort_id)

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
	estfe . est*, labels(cohort_id#year "Cohort-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career-Year FE" phySpec_id#year "Specialization-Year FE" phySpec_id#time_since_grad_id#year "Specialization-Career-Year FE")						
		
	esttab est* using "$tables/nozero_newbaseline-fe-regs-`oc'.tex", ///
		keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N unique_drs N_clust /* unique_schools */ mean pct_mean nzero, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1 %9.0fc) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef. \% of Mean" "Zeroes")) ///
		replace
		
	drop tag
}


