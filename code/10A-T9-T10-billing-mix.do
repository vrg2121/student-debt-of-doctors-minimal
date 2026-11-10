**************************************
*** OFFICE VS FACILITY BILLING MIX ***
**************************************

* corresponds with round 10, task 9

use "$working_data/panels/aamc_cms_id_2k2k10k_singleton", clear

keep if fg_sel3_total_payments > 0

g frac_cms_billing_O = pct_fg_sel3_total_payments_O / 100 // Panel A Outcome
g frac_cms_srvc_O = pct_fg_sel3_nServ_O / 100         // Panel B Outcome

label variable frac_cms_billing_O "Share of CMS Billing in Other Setting (non-facility)"
label variable frac_cms_srvc_O "Share of CMS Services in Other Setting (non-facility)"

foreach oc of varlist frac*  {
	g tag = 1 if `oc' == 0
	//drop if `oc' == 0
	
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

use "$working_data/panels/aamc_cms_id_2k2k10k_singleton", clear

keep if fg_sel5_total_payments > 0

g frac_em_billing_O = pct_fg_sel5_total_payments_O / 100 // Panel A Outcome
g frac_em_srvc_O = pct_fg_sel5_nServ_O / 100         // Panel B Outcome

label variable frac_em_billing_O "Share of E&M Billing in Other Setting (non-facility)"
label variable frac_em_srvc_O "Share of E&M Services in Other Setting (non-facility)"

foreach oc of varlist frac*  {
	g tag = 1 if `oc' == 0
	//drop if `oc' == 0
	
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