*** Tuition and Physician Billing (M) ***

* fulfills 2026-07-27_round7_tasks *


**# CMS Regressions

clear all
import excel "$dropbox/Claude/Claude Work to Identify Cohorts/cms-aamc-allmedschoolyears-with-all-cohort-scenarios.xlsx", sheet("2K 2K 10K") cellrange(A1:I2866) firstrow clear
rename npi npi_count

//drop if Cohort_ID == 0

summarize Cohort_ID
local max_id = r(max)

* Generate a counter for rows where id==0
generate temp_counter = sum(Cohort_ID == 0)

* Replace id==0 with new sequential IDs
replace Cohort_ID = `max_id' + temp_counter if Cohort_ID == 0

* Drop the temporary counter
drop temp_counter

** remove cohorts with singleton observations **
duplicates tag Cohort_ID, g(is_dup)
drop if is_dup == 0
drop is_dup

* merge on doctor data *

merge 1:m med_school grad_year using "$working_data/panels/cms-hcpcsgrp-panel" // all docs in using have em data
keep if _merge == 3 // ever-em-billers only
drop _merge

sort npi year

keep if event_time > 2 // career year >= 3
encode phySpec, g(phySpec_id)
g ln_tuition_bill = ln(tuition_bill)
g ln_tot_em_pymt = ln(tot_em_pymt)
g ln_em_nserv = ln(nsrvcs)
g ln_em_avgppserv = ln(avg_mdcr_pymt_amt)

label variable ln_tot_em_pymt "Total EM Payment (logs)"
label variable ln_em_nserv "Number of EM Services (logs)"
label variable ln_em_avgppserv "Avg Pymt Per EM Service (logs)"
label variable ln_tuition_bill "Tuition Bill (logs)"

global em_outcomes "ln_tot_em_pymt ln_em_nserv ln_em_avgppserv"

foreach oc of global em_outcomes {
			
	g tag = 1 if `oc' == 0 | `oc' == .

	* regression
	eststo clear
		
	* row 1: HCPCS Group#Year Career#Year
	eststo : reghdfe `oc' ln_tuition_bill, a(hcpcsgroup#year event_time#year) vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	** Unique doctors
	unique npi if e(sample) == 1
	estadd scalar unique_drs = r(unique)

	** number of zeros
	sum tag if e(sample) == 1
	local nz = r(sum)
	estadd scalar nzero = `nz'

	* row 2: HCPCS Group#Year Career#Year Cohort#Year
	eststo : reghdfe `oc' ln_tuition_bill, a(hcpcsgroup#year event_time#year Cohort_ID#year) vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	** Unique doctors
	unique npi if e(sample) == 1
	estadd scalar unique_drs = r(unique)

	** number of zeros
	sum tag if e(sample) == 1
	local nz = r(sum)
	estadd scalar nzero = `nz'

	esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(hcpcsgroup#year "HCPCS Group-Year FE" event_time#year "Career-Year FE" Cohort_ID#year "Cohort-Year FE")					
		
	esttab est* using "$tables/em_pymt_decomp-2K2K10K-fe-regs_`oc'.html", ///
		keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') ///
		stats(N unique_drs N_clust nzero , fmt(%9.0fc %9.0fc 3 1) labels("Observations (doc-yr-hcpcs grp)" "Doctors" "Clusters" "Zeroes")) ///
		title("Effect of Tuition on E&M UpCoding, `: var label `oc'' , 2K2K10K") ///
		addnotes("Standard errors clustered at Cohort level") /// 
		replace
		
		drop tag
	
}