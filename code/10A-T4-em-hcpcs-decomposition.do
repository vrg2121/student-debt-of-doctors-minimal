****************************
*** HCPCS REGRESSIONS ***
****************************

* corresponds with round 10

**# Table 4 - Decomposing E&M Billing Within a Fixed HCPCS Category

// aggregate data to doctor-year-em_hcpcs level
clear

global npi_invariant ///
		year phySpec* cred isMD  ///
		gy_cnt ms_cnt mult_grad_year mult_med_school grad_year med_school ///
		mdcr_participant zip5 groupPAC event_time hrr ///
		aca_year tuition PublicSchool source nominal_tuition med_school_chrono ///
		delta_nominal_tuition nominal_tuition_bill delta_tuition tuition_bill Tuition_quantile
		
global to_sum ///
		nServ hcpcs_tot_pymt hcpcs_tot_stdzd_pymt

forvalues n = 12/19 {
		
	use "$working_data/panels/aamc_cms_20`n'", clear
	
	destring isEM, replace
	keep if isEM == 1

	collapse (first) $npi_invariant (sum) $to_sum, by(npi hcpcsgroup)

	save "$working_data/temp/aamc_cms_npi_hcpcsgrp_20`n'", replace
}

use "$working_data/temp/aamc_cms_npi_hcpcsgrp_2012", clear

forvalues n = 13/19 {
	append using "$working_data/temp/aamc_cms_npi_hcpcsgrp_20`n'"
}

sort npi year

save "$working_data/panels/aamc_cms_npi_year_hcpcsgrp", replace


**# Identify Cohorts

clear all

global id_strat "2K2K10K"
import excel "$dropbox/Claude/Claude Work to Identify Cohorts/cms-aamc-allmedschoolyears-with-all-cohort-scenarios.xlsx", sheet("2K 2K 10K") cellrange(A1:I2866) firstrow clear
rename npi npi_count

summarize Cohort_ID

drop if Cohort_ID == 0 // drop singleton cohorts

* Merge on Doctor Data
merge 1:m med_school grad_year using "$working_data/panels/aamc_cms_npi_year_hcpcsgrp"
keep if _merge == 3
drop _merge

keep if event_time >= 3

* derive variables
g ln_tot_pymt = ln(hcpcs_tot_pymt)
g ln_nServ = ln(nServ)
g ln_tuition_bill = ln(tuition_bill)
g ln_avg_pymt = ln_tot_pymt - ln_nServ

do "$do/clean-phySpec.do"

encode phySpec, g(phySpec_ID)

// Table 4
foreach fe in "hcpcsgroup#year event_time#year" "hcpcsgroup#year event_time#year Cohort_ID#year" "hcpcsgroup#year event_time#year Cohort_ID#year hrr#year" "hcpcsgroup#year event_time#year Cohort_ID#year hrr#year phySpec_ID#year" {

	eststo clear
	
	qui eststo m1 : reghdfe ln_tot_pymt ln_tuition_bill, a(`fe') vce(cluster Cohort_ID)

	qui eststo m2 : reghdfe ln_nServ ln_tuition_bill, a(`fe') vce(cluster Cohort_ID)

	qui eststo m3 : reghdfe ln_avg_pymt ln_tuition_bill, a(`fe') vce(cluster Cohort_ID)

	esttab m1 m2 m3, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		mtitles("E&M Payments (log)" "Number of Services (log)" "Avg Price per Service (log)") ///
		addnotes("Standard errors clustered at Cohort level." "Fixed Effects: `fe'")

}
