***********************************
*** WITHIN DOC EM BILLING SHARE ***
***********************************

* corresponds with round 10, Table 8

use "$working_data/panels/aamc_cms_id_2k2k10k_nonsingleton", clear

keep if event_time > 2 // career year >= 3

g billing1 = fg_sel5_total_payments // em billing
g billing0 = fg_sel3_total_payments - fg_sel5_total_payments // non-em billing

keep if billing1 > 0 & billing0 > 0

// reshape wide to long with binary for is_em
reshape long billing, i(npi year) j(is_em)

g ln_billing = ln(billing)
g ln_tuition_bill_em = ln_tuition_bill*is_em

**# Table 8: Within Doc EM Billing Share
eststo clear
eststo : reghdfe ln_billing ln_tuition_bill_em, a(npi#year event_time#year#is_em Cohort_ID#year#is_em hrr#year#is_em) vce(cluster Cohort_ID)

** unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

esttab est*, keep(ln_tuition_bill_em) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(npi#year "Doctor-Year FE" event_time#year#is_em "Career Year-Year-E&M FE" Cohort_ID#year#is_em "Cohort-Year-E&M FE" hrr#year#is_em "HRR-Year-E&M FE")

esttab est* using "$tables/fe-regs-within-doc-em-share.html", ///
	keep(ln_tuition_bill_em) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_drs N_clust, fmt(%9.0fc %9.0fc %9.0fc) labels("Observations (doc-year)" "Doctors" "Clusters")) ///
	title("Within-Doctor E&M Billing Share") addnotes("Standard errors clustered at Cohort level.") ///
	replace