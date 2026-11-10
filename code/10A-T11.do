****************************
*** DOC SPECIALTY CHANGE ***
****************************

* corresponds with round 10, T11

use "$working_data/panels/aamc_cms_id_2k2k10k_singleton", clear

sort npi year
egen n_phySpec = nvals(phySpec_id), by(npi)
gen mult_phySpec = n_phySpec > 1

bys npi : g count = _n
keep if count == 1
drop count

**# Table 11

eststo clear
eststo : reghdfe mult_phySpec ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(Cohort_ID "Cohort FE" grad_year "Grad Year FE")

esttab est* using "$tables/fe-regs-doc-specialty-switch.html", ///
	keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N N_clust, fmt(%9.0fc %9.0fc) labels("Observations (doc)" "Clusters")) ///
	title("Doctor Switches Specialty and Tuition Bill") addnotes("Standard errors clustered at Cohort level.") ///
	replace

