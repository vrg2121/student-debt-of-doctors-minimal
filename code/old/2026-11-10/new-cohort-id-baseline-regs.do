*** Baseline Regressions After Claude Code Cohort_ID ***

/*
See "Claude Work to Identify Cohorts" folder for details.

*/
clear all
global id_strat "2K2K8K"
import excel "$dropbox/Claude/Claude Work to Identify Cohorts/cms-aamc-allmedschoolyears-with-all-cohort-scenarios.xlsx", sheet("2K 2K 8K") cellrange(A1:I2866) firstrow clear
rename npi npi_count

//drop if Cohort_ID == 0

summarize Cohort_ID
local max_id = r(max)
**# Bookmark #1

* Generate a counter for rows where id==0
generate temp_counter = sum(Cohort_ID == 0)

* Replace id==0 with new sequential IDs
replace Cohort_ID = `max_id' + temp_counter if Cohort_ID == 0

* Drop the temporary counter
drop temp_counter

* merge on doctor data *

merge 1:m med_school grad_year using "$working_data/panels/cms-panel"
keep if _merge == 3
drop _merge

g time_since_grad_id = year - grad_year
encode phySpec, g(phySpec_id)
//g cohort_zero = (Cohort_ID == 0)


global outcome "all_total_payments fg_sel3_total_payments fg_sel5_total_payments"

foreach var of global outcome {
    generate ln_`var' = ln(`var')
}

global ln_outcome "ln_all_total_payments ln_fg_sel3_total_payments ln_fg_sel5_total_payments"

g ln_tuition = ln(tuition)
g ln_tuition_bill = ln(tuition_bill)

label variable ln_tuition_bill "Tuition Bill (logs)"
label variable tuition_bill "Tuition Bill"

label variable all_total_payments "All Total Payments"
label variable fg_sel3_total_payments "CMS Payments"
label variable fg_sel5_total_payments "CMS E/M Payments"

label variable ln_all_total_payments "All Total Payments (logs)"
label variable ln_fg_sel3_total_payments "CMS Payments (logs)"
label variable ln_fg_sel5_total_payments "CMS E/M Payments (logs)"

** REGRESSIONS IN LOGS **

// outcomes as elasticities
foreach oc of global ln_outcome {
	
	local oc "ln_fg_sel3_total_payments"
		
	g tag = 1 if `oc' == 0 | `oc' == .
	
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
		
	esttab est* using "$tables/claudecohortid_newbaseline-$id_strat-fe-regs-`oc'.html", ///
		keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N unique_drs N_clust /* unique_schools */ mean pct_mean nzero, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1 %9.0fc) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef. \% of Mean" "Zeroes")) ///
		title("Effect of Tuition on `: variable label `oc'', $id_strat") ///
		addnotes("Standard errors clustered at Cohort level") /// 
		replace
		
	drop tag
}



** REGRESSIONS IN LEVELS **	
foreach oc of global outcome {
		
	g tag = 1 if `oc' == 0
	
	eststo clear
	
	* row 1: Cohort#Year
	
	eststo : reghdfe `oc' tuition_bill, a(Cohort_ID#year) vce(cluster Cohort_ID)

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
	
	eststo : reghdfe `oc' tuition_bill, a(Cohort_ID#year hrr#year) vce(cluster Cohort_ID)

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
	eststo : reghdfe `oc' tuition_bill, a(Cohort_ID#year hrr#year time_since_grad_id#year) vce(cluster Cohort_ID)

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
	eststo : reghdfe `oc' tuition_bill, a(Cohort_ID#year hrr#year time_since_grad_id#year phySpec_id#year) vce(cluster Cohort_ID)

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
	eststo : reghdfe `oc' tuition_bill, a(Cohort_ID#year hrr#year phySpec_id#time_since_grad_id#year) vce(cluster Cohort_ID)

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
	estfe . est*, labels(Cohort_ID#year "Cohort-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career-Year FE" phySpec_id#year "Specialization-Year FE" phySpec_id#time_since_grad_id#year "Specialization-Career-Year FE")						
		
	esttab est* using "$tables/claudecohortid_newbaseline-$id_strat-fe-regs-`oc'.html", ///
		keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N unique_drs N_clust /* unique_schools */ mean pct_mean nzero, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1 %9.0fc) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef. \% of Mean" "Zeroes")) ///
		title("Effect of Tuition on `: variable label `oc'', $id_strat") ///
		addnotes("Standard errors clustered at Cohort level") ///
		replace
		
	drop tag
}
