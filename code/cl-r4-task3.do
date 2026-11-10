*** Intensive & Extensive Margin Analysis: Regressions (Task 3)***

* fulfills 2026-07-01_round4_tasks *

**# Prep phySpec numerical ID
use "$working_data/panels/cms-aamc-2k2k10k-singleton.dta", clear

keep phySpec
sort phySpec
duplicates drop
drop if phySpec == ""
g phySpec_num = _n
save "$working_data/temp/physpec_num_crosswalk", replace

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

merge m:1 phySpec using "$working_data/temp/physpec_num_crosswalk"
keep if _merge == 3
drop _merge

reg years_to_first_billing i.phySpec_num i.grad_year

regsave using "$working_data/temp/physpec_coef.dta", replace

use "$working_data/temp/physpec_coef.dta", clear
g phySpec_num = real(regexs(1)) if regexm(var, "^([0-9]+)o?\.phySpec_num$")
keep if !missing(phySpec_num)
keep phySpec_num coef
tempfile coefs
save `coefs'

* analyze on non-singleton cohorts
use "$working_data/panels/cms-aamc-2k2k10k-nonsingleton.dta", clear

merge m:1 phySpec using "$working_data/temp/physpec_num_crosswalk"
keep if _merge == 3
drop _merge

keep if grad_year > 2009 & grad_year < 2017
bysort npi (year): gen first_cms = (cms_npi == 1 & sum(cms_npi == 1) == 1)
keep if first_cms == 1

merge m:1 phySpec_num using `coefs'

keep if _merge == 3
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