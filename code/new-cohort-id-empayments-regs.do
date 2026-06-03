*** WITHIN HCPCS GROUP REGRESSIONS AFTER CLAUDE CODE COHORT ID ***

clear all
global id_strat "2K2K8K"
import excel "$dropbox/Claude Work to Idenitfy Cohorts/cms-aamc-allmedschoolyears-with-all-cohort-scenarios.xlsx", sheet("2K 2K 8K") cellrange(A1:I2866) firstrow clear
rename npi npi_count

//drop if Cohort_ID == 0

* merge on doctor data *

merge 1:m med_school grad_year using "$working_data/panels/cms-panel"
keep if _merge == 3
drop _merge

g time_since_grad_id = year - grad_year
encode phySpec, g(phySpec_id)

* merge on hcpcs group payments *

merge 1:m npi year using "$working_data/temp/em-hcpcsgrp-payments"
keep if _merge == 3
drop _merge

global outcome "tot_em_pymt avg_mdcr_pymt_amt nsrvcs"

* run regressions *
foreach oc of global outcome {
	
	g tag = 1 if `oc' == 0
	
	eststo clear

	
	eststo : reghdfe `oc' tuition_bill, a(Cohort_ID#year time_since_grad_id#year phySpec_id#year hrr#year hcpcsgroup#year) vce(cluster Cohort_ID)

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
	estfe . est*, labels(Cohort_ID#year "Cohort-Year FE" phySpec_id#year "Specialization-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career Time-Year FE" hcpcsgroup#year "HCPCS Group-Year FE")						
		
	esttab est* using "$tables/claudecohortid-fe-regs-hcpcsgrp-`oc'.tex", ///
		keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N unique_drs N_clust /* unique_schools */ mean pct_mean nzero, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1 %9.0fc) labels("Observations (doctor-years-hcpcsgroup)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef.\ \% of Mean" "Zeros")) ///
		replace
		
	drop tag
}