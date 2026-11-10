************************************
*** SPECIALTY CHOICE REGRESSIONS ***
************************************

* corresponds with round 10

use "$working_data/panels/aamc_cms_id_2k2k10k_nonsingleton", clear

sort npi year
g phySpec_num = phySpec_id

preserve

keep if grad_year > 2009 & grad_year < 2017

by npi : keep if _n == 1 // only keep year of first billing activity

reg event_time i.phySpec_num i.grad_year

regsave
keep var coef
rename var phySpec_num
rename coef bill_onset
replace phySpec_num = subinstr(phySpec_num, ".phySpec_num", "", .)
replace phySpec_num = subinstr(phySpec_num, "b", "", .)
drop if strpos(phySpec_num, ".grad_year") > 0
drop if phySpec_num == "_cons"
destring phySpec_num, replace

tempfile onset
save `onset'

restore

sort npi year
by npi : keep if _n == 1

merge m:1 phySpec_num using  `onset'
drop _merge

**# Table 5
eststo clear

eststo : reghdfe bill_onset ln_tuition_bill, a(Cohort_ID) vce(cluster Cohort_ID)

** unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

eststo : reghdfe bill_onset ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

** unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

eststo : reghdfe bill_onset ln_tuition_bill, a(Cohort_ID grad_year hrr) vce(cluster Cohort_ID)

** unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(Cohort_ID "Cohort FE" grad_year "Grad Year FE" hrr "HRR FE")

esttab est* using "$tables/fe-regs-spec-choice-billing-onset.html", ///
	keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_drs N_clust, fmt(%9.0fc %9.0fc %9.0fc) labels("Observations (doc-year)" "Doctors" "Clusters")) ///
	title("Specialty Choice and Billing Onset") addnotes("Standard errors clustered at Cohort level.") ///
	replace