*** Intensive & Extensive Margin Analysis: Regressions ***

* fulfills 2026-07-01_round4_tasks *

**# Data Set-Up
* non-singleton cohort CMS ever-billers
use "$working_data/panels/cms-aamc-2k2k10k-nonsingleton.dta", clear

sort npi year
bys npi : egen ever_cms = max(fg_sel3_total_payments != 0 & fg_sel3_total_payments != .)

keep if ever_cms == 1 // 37,942 d-y observations deleted, docs that never billed cms

sort npi year
bys npi : egen ever_em = max(fg_sel5_total_payments != 0 & fg_sel5_total_payments != .)
label variable ever_em "Ever Billed EM"

bys npi (year) : gen cumsum = sum(cms_npi) // first year that doctor billed cms

keep if cumsum == 1

drop if cms_npi == 0


**# Tuition and Ever-EM Biller

* data: doctor-panel
	
eststo clear

* row 1: No FE

eststo : reghdfe ever_em ln_tuition_bill, vce(cluster Cohort_ID)

** Mean:
sum ever_em if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
estadd scalar pct_mean

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

* row 2: Cohort FE

eststo : reghdfe ever_em ln_tuition_bill, a(Cohort_ID) vce(cluster Cohort_ID)

** Mean:
sum ever_em if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
estadd scalar pct_mean

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

* row 3: Cohort + grad_year FE
eststo : reghdfe ever_em ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

** Mean:
sum ever_em if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
estadd scalar pct_mean

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

* row 4: Cohort + grad_year + HRR 
eststo : reghdfe ever_em ln_tuition_bill, a(Cohort_ID grad_year hrr) vce(cluster Cohort_ID)

** Mean:
sum ever_em if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
estadd scalar pct_mean

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

* row 5: Cohort + grad_year + HRR + specialization 
eststo : reghdfe ever_em ln_tuition_bill, a(Cohort_ID grad_year hrr phySpec) vce(cluster Cohort_ID)

** Mean:
sum ever_em if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
estadd scalar pct_mean

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

* format output

esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(Cohort_ID "Cohort FE" grad_year "Grad Year FE" hrr "HRR FE" phySpec "Specialization FE")						
	
esttab est* using "$tables/extmarg-fullCareer-fe-regs-ever_em.html", ///
	keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N  N_clust /* unique_schools */ mean pct_mean, fmt(%9.0fc %9.0fc /* %9.0fc */ 3 1 %9.0fc) labels("Observations (doctors)" "Clusters" /* "Schools" */ "Mean" "Coef. % of Mean")) ///
	title("Binary Extensive Margin: `: var label ever_em'") ///
	note("Standard Errors clustered at Cohort level." "2K2K10K, non-singleton Cohort parameters.") ///
	replace
	
**# Cox Proportional Hazards (SKIPPED)

/*
use "$working_data/panels/cms-aamc-2k2k10k-nonsingleton.dta", clear

sort npi year
bys npi : egen ever_cms = max(fg_sel3_total_payments != 0 & fg_sel3_total_payments != .)

keep if ever_cms == 1 // 37,942 d-y observations deleted, docs that never billed cms

sort npi year
bys npi : egen ever_em = max(fg_sel5_total_payments != 0 & fg_sel5_total_payments != .)
label variable ever_em "Ever Billed EM"

keep if grad_year > 2008 & grad_year < 2017
g t_enter = max(grad_year + 3, 2012)

sort npi year
bysort npi (year): gen first_em = (em_npi == 1 & sum(em_npi == 1) == 1)

g t_exit = year

format t_enter t_exit %ty
stset t_exit, id(npi) failure(first_em==1) enter(time t_enter)

* Cox Regressions
stcox ln_tuition_bill, strata(Cohort_ID) vce(cluster Cohort_ID) efron nohr
stcox ln_tuition_bill i.grad_year, strata(Cohort_ID) vce(cluster Cohort_ID) efron nohr
stcox ln_tuition_bill i.grad_year i.hrr, strata(Cohort_ID) vce(cluster Cohort_ID) efron nohr
stcox ln_tuition_bill i.grad_year i.hrr i.phySpec, strata(Cohort_ID) vce(cluster Cohort_ID) efron

*/

**# T3 Specialty Choice via Billing Onset

use "$working_data/panels/cms-aamc-2k2k10k-singleton.dta", clear

sort npi year
bys npi : egen ever_cms = max(fg_sel3_total_payments != 0 & fg_sel3_total_payments != .)

keep if ever_cms == 1 // 251,658 d-y observations deleted, docs that never billed cms

keep if grad_year > 2009 & grad_year < 2017

bysort npi (year): gen first_cms = (cms_npi == 1 & sum(cms_npi == 1) == 1)

g years_to_first_billing = first_cms * event_time
replace years_to_first_billing = . if first_cms == 0

bys npi: g first_spec = phySpec if first_cms == 1
gsort npi -first_cms
bys npi: replace first_spec = first_spec[_n - 1] if missing(first_spec)

keep if years_to_first_billing != . // should result in one observation per doctor; 45,694 docs

reg years_to_first_billing i.phySpec_id i.grad_year

regsave using "$working_data/temp/physpec_coef.dta", replace

use "$working_data/temp/physpec_coef.dta", clear
g phySpec_id = real(regexs(1)) if regexm(var, "^([0-9]+)o?\.phySpec_id$")
keep if !missing(phySpec_id)
keep phySpec_id coef
tempfile coefs
save `coefs'

* analyze on non-singleton cohorts
use "$working_data/panels/cms-aamc-2k2k10k-nonsingleton.dta", clear
keep if grad_year > 2009 & grad_year < 2017
bysort npi (year): gen first_cms = (cms_npi == 1 & sum(cms_npi == 1) == 1)
keep if first_cms == 1

merge m:1 phySpec_id using `coefs'

drop _merge
replace coef = 0 if coef == .
rename coef specialty_onset

eststo clear

* row 1: No FE

eststo : reghdfe specialty_onset ln_tuition_bill, a(Cohort_ID) vce(cluster Cohort_ID)

** Mean and SD:
sum specialty_onset if e(sample) == 1
estadd r(mean)
estadd r(sd)

* row 2: Cohort FE

eststo : reghdfe specialty_onset ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

** Mean and SD:
sum specialty_onset if e(sample) == 1
estadd r(mean)
estadd r(sd)

* row 3: Cohort + grad_year FE
eststo : reghdfe specialty_onset ln_tuition_bill, a(Cohort_ID grad_year hrr) vce(cluster Cohort_ID)
7
** Mean and SD:
sum specialty_onset if e(sample) == 1
estadd r(mean)
estadd r(sd)

esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(Cohort_ID "Cohort FE" grad_year "Grad Year FE" hrr "HRR FE")						
	
esttab est* using "$tables/specialty-billing-onset-fe-regs.html", ///
	keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N  N_clust mean sd, fmt(%9.0fc %9.0fc 3 3) labels("Observations (doctors)" "Clusters" "Mean" "Standard Dev")) ///
	title("Specialty Choice and Billing Onset") ///
	note("Standard Errors clustered at Cohort level." "2K2K10K, non-singleton Cohort parameters.") ///
	replace
	
**# IHS Regressions Including Zero-Billing Years

use "$working_data/panels/cms-aamc-2k2k10k-nonsingleton.dta", clear

keep if time_since_grad > 5 // career year >= 6

* replace missing total payments with 0
replace fg_sel3_total_payments = 0 if fg_sel3_total_payments == .
replace fg_sel5_total_payments = 0 if fg_sel5_total_payments == .

* calculate asinh of cms and em payments
g ihs_cms = asinh(fg_sel3_total_payments)
g ihs_em = asinh(fg_sel5_total_payments)

label variable ihs_cms "CMS Billing (IHS)"
label variable ihs_em "EM Billing (IHS)"

global asinh_outcome "ihs_cms ihs_em"

foreach oc of global asinh_outcome {
		
	g tag = 1 if `oc' == 0 | `oc' == .
	
	eststo clear
	
	* row 1: Cohort#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year) vce(cluster Cohort_ID)

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
	
	** pct of observations with zeros
	sum `oc' if e(sample) == 1
	estadd scalar pct_zero = (`nz' / r(N)) * 100
	
	* row 2: Cohort#Year HRR#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year) vce(cluster Cohort_ID)

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
	
	** pct of observations with zeros
	sum `oc' if e(sample) == 1
	estadd scalar pct_zero = (`nz' / r(N)) * 100
	
	
	* row 3: Cohort#Year HRR#Year Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year time_since_grad_id#year) vce(cluster Cohort_ID)

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
	
	** pct of observations with zeros
	sum `oc' if e(sample) == 1
	estadd scalar pct_zero = (`nz' / r(N)) * 100
	
	* row 4: Cohort#Year HRR#Year Career_Time#Year Specialization#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year time_since_grad_id#year phySpec_id#year) vce(cluster Cohort_ID)

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
	
	** pct of observations with zeros
	sum `oc' if e(sample) == 1
	estadd scalar pct_zero = (`nz' / r(N)) * 100
	
	* row 5: Cohort#Year HRR#Year Specialization#Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_id#time_since_grad_id#year) vce(cluster Cohort_ID)

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
	
	** pct of observations with zeros
	sum `oc' if e(sample) == 1
	estadd scalar pct_zero = (`nz' / r(N)) * 100

	* format output

	esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(Cohort_ID#year "Cohort-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career-Year FE" phySpec_id#year "Specialization-Year FE" phySpec_id#time_since_grad_id#year "Specialization-Career-Year FE")					
		
	esttab est* using "$tables/ihs-2K2K10K-fe-regs-`oc'.html", ///
		keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N unique_drs N_clust mean pct_zero nzero, fmt(%9.0fc %9.0fc %9.0fc 3 1 %9.0fc) labels("Observations (doctor-years)" "Doctors" "Clusters" "Mean (IHS)" "% Zeroes" "Zeroes")) ///
		title("Effect of Tuition on `: variable label `oc'', 2K2K10K") ///
		addnotes("Standard errors clustered at Cohort level") /// 
		replace
		
	drop tag
}

**# T5 Within-Group E&M UpCoding

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

g tag = 1 if ln_tot_em_pymt == 0 | ln_tot_em_pymt == .

* regression
eststo clear
	
* row 1: HCPCS Group#Year Career#Year
eststo : reghdfe ln_tot_em_pymt ln_tuition_bill, a(hcpcsgroup#year event_time#year) vce(cluster Cohort_ID)

** Mean:
sum ln_tot_em_pymt if e(sample) == 1
estadd r(mean)

** Unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

** number of zeros
sum tag if e(sample) == 1
local nz = r(sum)
estadd scalar nzero = `nz'

* row 2: HCPCS Group#Year Career#Year Cohort#Year
eststo : reghdfe ln_tot_em_pymt ln_tuition_bill, a(hcpcsgroup#year event_time#year Cohort_ID#year) vce(cluster Cohort_ID)

** Mean:
sum ln_tot_em_pymt if e(sample) == 1
estadd r(mean)

** Unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

** number of zeros
sum tag if e(sample) == 1
local nz = r(sum)
estadd scalar nzero = `nz'

* row 3: HCPCS Group#Year Career#Year Cohort#Year hrr#Year
* reghdfe ln_tot_em_pymt ln_tuition_bill, a(hcpcsgroup#year event_time#year Cohort_ID#year hrr#year) vce(cluster Cohort_ID)

* row 4: HCPCS Group#Year Career#Year Cohort#Year specialization#Year
eststo : reghdfe ln_tot_em_pymt ln_tuition_bill, a(hcpcsgroup#year event_time#year Cohort_ID#year phySpec_id#year) vce(cluster Cohort_ID)

** Mean:
sum ln_tot_em_pymt if e(sample) == 1
estadd r(mean)

** Unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

** number of zeros
sum tag if e(sample) == 1
local nz = r(sum)
estadd scalar nzero = `nz'

esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(hcpcsgroup#year "HCPCS Group-Year FE" event_time#year "Career-Year FE" Cohort_ID#year "Cohort-Year FE" phySpec_id#year "Specialization-Year FE")					
	
esttab est* using "$tables/em_pymt-2K2K10K-fe-regs.html", ///
	keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_drs N_clust mean nzero , fmt(%9.0fc %9.0fc %9.0fc 3 1) labels("Observations (doc-yr-hcpcs grp)" "Doctors" "Clusters" "Mean" "Zeroes")) ///
	title("Effect of Tuition on E&M UpCoding, 2K2K10K") ///
	addnotes("Standard errors clustered at Cohort level") /// 
	replace
	
**# Within-Doc E&M Billing Share
use "$working_data/panels/cms-aamc-2k2k10k-nonsingleton.dta", clear

keep if time_since_grad > 2 // career year >= 3
drop if fg_sel3_total_payments == 0 | fg_sel3_total_payments == .
drop if fg_sel5_total_payments == 0 | fg_sel5_total_payments == .

rename fg_sel5_total_payments pymt_em
g pymt_non_em = fg_sel3_total_payments - pymt_em
drop if pymt_non_em == 0

* wide to long with time_since_grad_id, cohort_id, npi, year, hrr
reshape long pymt_, i(npi year) j(em_type) str
rename pymt_ pmt
g is_em = (em_type == "em")
drop em_type

g ln_pymt = ln(pmt)

eststo clear
eststo : reghdfe ln_pymt c.ln_tuition_bill#1.is_em, a(npi#year is_em#year#time_since_grad_id Cohort_ID#year#is_em hrr#year#is_em) vce(cluster Cohort_ID)

** Unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

esttab est*, drop(_cons) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(npi#year "Doctor-Year FE" is_em#year#time_since_grad_id "Career-Year-EM FE" Cohort_ID#year#is_em "Cohort-Year-EM FE" hrr#year#is_em "HRR-Year-EM FE")					
	
esttab est* using "$tables/within_em-2K2K10K-fe-regs.html", ///
	drop(_cons) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_drs N_clust, fmt(%9.0fc %9.0fc %9.0fc) labels("Observations (Doctor-Year)" "Doctors" "Clusters")) ///
	title("Within-Doctor EM Billing Share, 2K2K10K") ///
	addnotes("Standard errors clustered at Cohort level") /// 
	replace



