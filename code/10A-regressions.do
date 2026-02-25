/*
PREAMBLE

Regressions as specified in the Revamp of Empirical Strategy.
   
Victoria Garcia 
February 2026
*/

clear all

*** SET VARIABLES FOR REGRESSIONS ***

/* Outcome Variable Descriptions

	all_total_payments = Total CMS Payments ( I think )
	fg_sel3_total_payments = Total CMS Payments, unclear how it differs from all_total_payments, they do differ
	fg_sel3_nServ = Total Number of Services ( I think, what is nServ? )
	fg_sel5_total_payments = Payments: EM Codes ( What is E/M? Emergency? )
	fg_sel5_nServ = Total Number of E/M Services
	pp_payment = kickback payments (?)

*/

/* Fixed Effects
	
	Year refers to the year of doctor billing data (event time)
	
	Baseline: Cohort-Year FE (cohort_id#year) & Career Time FE (time_since_grad_id)
	Additionally fix Specialization: Specialization-Year FE (phySpec_id#year)
	Additionally fix Regional Referral Area (location): HRR-Year FE (hrr#year)
	
	Replace Career Time FE with time_since_grad_id#year "Career Time-Year FE", keep additional.

*/

global outcome "all_total_payments fg_sel3_total_payments fg_sel3_nServ fg_sel5_nServ fg_sel5_total_payments pp_payment"



*** IDENTIFIED DATA ***
use "$working_data/cms_aamc_cohort_id", clear

*** BASELINE REGRESSIONS ***
foreach oc of global outcome {
	
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

	* format output

	esttab est*, keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(cohort_id#year "Cohort-Year FE" time_since_grad_id "Career Time FE" phySpec_id#year "Specialization-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career Time-Year FE")						
		
	esttab est* using "$tables/fe-regs-`oc'.tex", ///
		keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N unique_drs N_clust /* unique_schools */ mean pct_mean, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef.\ \% of Mean")) ///
		replace
}


*** REGRESSIONS WITH TUITION BILL VARIATION ***
use "$working_data/cms_aamc_cohort_id", clear

drop if med_school == "medical university of south carolina college of medicine" // incorrect tuition data

bysort cohort_id: egen max_tbill = max(tuition_bill)
bysort cohort_id: egen min_tbill = min(tuition_bill)
g spread = max_tbill - min_tbill
label variable spread "Tuition Bill Spread (Thousands)"

keep if spread > 1 // keep if tuition bill spread > $1000
// 406,610 / 1,549,937 = ~26% of observations deleted 

foreach oc of global outcome {
	
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

	* format output

	esttab est*, keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(cohort_id#year "Cohort-Year FE" time_since_grad_id "Career Time FE" phySpec_id#year "Specialization-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career Time-Year FE")						
		
	esttab est* using "$tables/variation-fe-regs-`oc'.tex", ///
		keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N unique_drs N_clust /* unique_schools */ mean pct_mean, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef.\ \% of Mean")) ///
		replace
}


