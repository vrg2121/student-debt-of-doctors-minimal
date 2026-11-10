****************************
*** BASELINE REGRESSIONS ***
****************************

* corresponds with round 10, tasks 1-3

use "$working_data/panels/aamc_cms_id_2k2k10k_singleton", clear

**# Table 1 - Effect of Tuition on Physician Billing
foreach oc of varlist ln_fg_sel3_total_payments ln_fg_sel5_total_payments {
	g tag = 1 if `oc' == 0
	
	eststo clear
	
	* row 1: Cohort#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year) vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
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
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year) vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
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
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year time_since_grad_id#year) vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
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
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year time_since_grad_id#year phySpec_id#year) vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
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
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_id#time_since_grad_id#year) vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
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

	esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(Cohort_ID#year "Cohort-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career-Year FE" phySpec_id#year "Specialization-Year FE" phySpec_id#time_since_grad_id#year "Specialization-Career-Year FE")					
		
	esttab est* using "$tables/fe-regs-$id_strat-`oc'.html", ///
		keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N unique_drs N_clust /* unique_schools */ mean pct_mean nzero, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1 %9.0fc) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef. % of Mean" "Zeroes")) ///
		title("Effect of Tuition on `: variable label `oc'', $id_strat") ///
		addnotes("Standard errors clustered at Cohort level") /// 
		replace
		
	drop tag
}

**# Table 2 - Decomposing E&M Billing Effect into Volume and Price
foreach fe in "Cohort_ID#year" "Cohort_ID#year hrr#year" "Cohort_ID#year hrr#year time_since_grad_id#year" "Cohort_ID#year hrr#year time_since_grad_id#year phySpec_id#year" "Cohort_ID#year hrr#year phySpec_id#time_since_grad_id#year" {

	eststo clear
	
	qui eststo m1 : reghdfe ln_fg_sel5_total_payments ln_tuition_bill, a(`fe') vce(cluster Cohort_ID)

	qui eststo m2 : reghdfe ln_fg_sel5_nServ ln_tuition_bill, a(`fe') vce(cluster Cohort_ID)

	qui eststo m3 : reghdfe ln_fg_sel5_avg_pymt ln_tuition_bill, a(`fe') vce(cluster Cohort_ID)

	esttab m1 m2 m3, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		mtitles("E&M Payments (log)" "Number of Services (log)" "Avg Price per Service (log)")

}

**# Table 3 - Decomposing CMS Billing Effect into Volume and Price
foreach fe in "Cohort_ID#year" "Cohort_ID#year hrr#year" "Cohort_ID#year hrr#year time_since_grad_id#year" "Cohort_ID#year hrr#year time_since_grad_id#year phySpec_id#year" "Cohort_ID#year hrr#year phySpec_id#time_since_grad_id#year" {

	eststo clear
	
	qui eststo m1 : reghdfe ln_fg_sel3_total_payments ln_tuition_bill, a(`fe') vce(cluster Cohort_ID)

	qui eststo m2 : reghdfe ln_fg_sel3_nServ ln_tuition_bill, a(`fe') vce(cluster Cohort_ID)

	qui eststo m3 : reghdfe ln_fg_sel3_avg_pymt ln_tuition_bill, a(`fe') vce(cluster Cohort_ID)

	esttab m1 m2 m3, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		mtitles("E&M Payments (log)" "Number of Services (log)" "Avg Price per Service (log)")

}