******************************************
*** DOC EXTENSIVE MARGIN EVER BILL E&M ***
******************************************

use "$working_data/panels/aamc_cms_id_2k2k10k_nonsingleton", clear

bys npi: egen ever_cms_bill = max(fg_sel3_total_payments > 0)
bys npi: egen ever_em_bill = max(fg_sel5_total_payments > 0)

sort npi year

g temp_year = year if fg_sel3_total_payments > 0
bys npi : egen first_bill_year = min(temp_year)
g first_bill_tag = (year==first_bill_year) if !missing(first_bill_year)

drop temp_year first_bill_year

keep if first_bill_tag == 1

**# Table 6
eststo clear

eststo : reghdfe ever_em_bill ln_tuition_bill, vce(cluster Cohort_ID)

** unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

eststo : reghdfe ever_em_bill ln_tuition_bill, a(Cohort_ID) vce(cluster Cohort_ID)

** unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

eststo : reghdfe ever_em_bill ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

** unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

eststo : reghdfe ever_em_bill ln_tuition_bill, a(Cohort_ID grad_year hrr) vce(cluster Cohort_ID)

** unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

eststo : reghdfe ever_em_bill ln_tuition_bill, a(Cohort_ID grad_year hrr phySpec_id) vce(cluster Cohort_ID)

** unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(Cohort_ID "Cohort FE" grad_year "Grad Year FE" hrr "HRR FE" phySpec_id "Specialization FE")

esttab est* using "$tables/fe-regs-ext-marg-ever-em-bill.html", ///
	keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_drs N_clust, fmt(%9.0fc %9.0fc %9.0fc) labels("Observations (doc-year)" "Doctors" "Clusters")) ///
	title("Doctor-Level Extensive Margin, Ever Bills E&M") addnotes("Standard errors clustered at Cohort level.") ///
	replace