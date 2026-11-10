****************************************
*** MERGING AAMC AND MAT / GRAD DATA ***
****************************************

use "$working_data/panels/aamc_grad_apps_mats", clear

// tag first 5 rows when school first reports matriculant data after 1990 

preserve
drop if start_aca_year == .
sort med_school start_aca_year
drop if matriculants == .
bys med_school (start_aca_year) : g n = _n
g new_school = (start_aca_year > 1990 & n == 1)

bys med_school : g first_5 = (n < 6)
keep if first_5 == 1
bys med_school : egen new_school_first_5 = max(new_school)
keep if new_school_first_5 == 1

tab new_school
keep med_school grad_year new_school_first_5

save "$working_data/temp/newschools_first_5yrs", replace

restore

merge 1:1 med_school grad_year using "$working_data/temp/newschools_first_5yrs"
drop _merge


// merge on cohort id

merge 1:m med_school grad_year using "$working_data/panels/aamc_id_2k2k10k_singleton"

keep if _merge == 3
drop _merge

sort med_school aca_year

drop if new_school_first_5 == 1

bys Cohort_ID : g singular_cohortid = (_N == 1)


// generate variables
bys med_school : g r1_mat_app = matriculants / applicants
label variable r1_mat_app "Matriculants / Applicants"

bys med_school : g r2_grad_mat = graduates / matriculants
label variable r2_grad_mat "Graduates / Matriculants"



**# Task 1: Ratio Matriculants to Applicants
sum r1_mat_app
sum r1_mat_app if singular_cohortid == 0

drop if r1_mat_app == 1
hist r1_mat_app, freq width(0.01) title("Matriculants / Applicants, Frequency (Full Sample)")
graph export "$figures/ratio1_distribution_fullsample.png", replace
hist r1_mat_app if singular_cohortid == 0, freq width(0.01) title("Matriculants / Applicants, Frequency (Regression Sample)")
graph export "$figures/ratio1_distribution_regsample.png", replace


eststo clear
eststo : reghdfe r1_mat_app ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(Cohort_ID "Cohort FE" grad_year "Grad Year FE")

esttab est* using "$tables/fe-regs-ratio-matriculants-applicants.html", ///
	keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_schools N_clust, fmt(%9.0fc %9.0fc %9.0fc) labels("Observations (school-year)" "Schools" "Clusters")) ///
	title("Selection into Starting Program, Matriculants / Applicants") addnotes("Standard errors clustered at Cohort level." "2K2K10K Cohort ID used, singletons included.") ///
	replace
	
**# Task 2: Ratio Graduates to Matriculants
sum r2_grad_mat
sum r2_grad_mat if singular_cohortid == 0

hist r2_grad_mat, freq width(0.01) title("Graduates / Matriculants, Frequency (Full Sample)")
graph export "$figures/ratio2_distribution_fullsample.png", replace
hist r2_grad_mat if singular_cohortid == 0, freq width(0.01) title("Graduates / Matriculants, Frequency (Regression Sample)")
graph export "$figures/ratio2_distribution_regsample.png", replace

eststo clear
eststo : reghdfe r2_grad_mat ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(Cohort_ID "Cohort FE" grad_year "Grad Year FE")

esttab est* using "$tables/fe-regs-ratio-graduates-matriculant.html", ///
	keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_schools N_clust, fmt(%9.0fc %9.0fc %9.0fc) labels("Observations (school-year)" "Schools" "Clusters")) ///
	title("Selection into Finishing Program, Graduates / Matriculants (unreliable)") addnotes("Standard errors clustered at Cohort level." "Estimates of graduation rates are unreliable due to matriculants and graduation rates reported for multiple MD-granting programs, including MD-PhD and MD-MBA." "2K2K10K Cohort ID used, singletons included.") ///
	replace
	
**# Task 4 A-C: level effects

g ln_applicants = ln(applicants)
label variable ln_applicants "Applicants (logs)"
g ln_matriculants = ln(matriculants)
label variable ln_matriculants "Matriculants (logs)"
g ln_graduates = ln(graduates)
label variable ln_graduates "Graduates (logs)"

sum applicants
sum applicants if singular_cohortid == 0

hist applicants, freq width(500) title("Applicants, Frequency (Full Sample)")
graph export "$figures/applicants_distribution_fullsample.png", replace
hist applicants if singular_cohortid == 0, freq width(500) title("Applicants, Frequency (Regression Sample)")
graph export "$figures/applicants_distribution_regsample.png", replace

sum matriculants
sum matriculants if singular_cohortid == 0

hist matriculants, freq width(20) title("Matriculants, Frequency (Full Sample)")
graph export "$figures/matriculants_distribution_fullsample.png", replace
hist matriculants if singular_cohortid == 0, freq width(20) title("Matriculants, Frequency (Regression Sample)")
graph export "$figures/matriculants_distribution_regsample.png", replace

sum graduates
sum graduates if singular_cohortid == 0

hist graduates, freq width(20) title("Graduates, Frequency (Full Sample)")
graph export "$figures/graduates_distribution_fullsample.png", replace
hist graduates if singular_cohortid == 0, freq width(20) title("Graduates, Frequency (Regression Sample)")
graph export "$figures/graduates_distribution_regsample.png", replace

foreach v of varlist ln_applicants ln_matriculants ln_graduates {
	eststo clear
	eststo : reghdfe `v' ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

	** unique schools
	unique med_school if e(sample) == 1
	estadd scalar unique_schools = r(unique)

	esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(Cohort_ID "Cohort FE" grad_year "Grad Year FE")

	esttab est* using "$tables/fe-regs-`v'.html", ///
		keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N unique_schools N_clust, fmt(%9.0fc %9.0fc %9.0fc) labels("Observations (school-year)" "Schools" "Clusters")) ///
		title("Level Effects of `: variable label `v''") addnotes("Standard errors clustered at Cohort level." "2K2K10K Cohort ID used, singletons included.") ///
		replace
} // TODO: IMPROVE TITLE



**# Task 3: Ratio CMS Billers to Graduates - still not correct

use "$working_data/panels/aamc_grad_apps_mats", clear

merge 1:1 med_school grad_year using "$working_data/temp/newschools_first_5yrs"
drop _merge

// merge on cohort id

merge 1:m med_school grad_year using "$working_data/panels/aamc_cms_id_2k2k10k_singleton"

keep if _merge == 3
drop _merge

sort med_school aca_year

keep if grad_year < 2017
drop if new_school_first_5 == 1

bys npi: egen ever_cms_bill = max(fg_sel3_total_payments > 0)
bys npi (year) : g first_npi_obs = (_n == 1)
keep if first_npi_obs == 1

sort med_school grad_year npi
collapse (sum) ever_cms_bill (first) graduates matriculants applicants Cohort_ID ln_tuition_bill, by(med_school grad_year)
rename ever_cms_bill cms_biller

bys Cohort_ID : g singular_cohortid = (_N == 1)

bys med_school : g r3_biller_grad = cms_biller / graduates
label variable r3_biller_grad "CMS Biller / Graduates"

g tag = (r3_biller_grad > 1) 
// drexel, grad_year 1996 has 18 cms_biller and missing graduates. 
// drexel, grad_year 1997 has 14 cms_biller and 1 graduate.
// This may be an error from attributing graduates of "university college of medicine" to Drexel in the clean-npi-medschool-names.do file. This has since been corrected.

// university of central florida college of medicine, grad_year 2012 has 1 cms_biller and missing graduates. was founded in 2006 --> "new" until 2011 --> 2012 is first year of potential cms_biller, unclear why graduates data is missing.

drop if tag == 1 // temporary fix

// summary statistics

sum r3_biller_grad
sum r3_biller_grad if singular_cohortid == 0

hist r3_biller_grad, freq width(0.05) title("CMS Billers / Graduates, Frequency (Full Sample)")
graph export "$figures/ratio3_distribution_fullsample.png", replace
hist r3_biller_grad if singular_cohortid == 0, freq width(0.05) title("CMS Billers / Graduates, Frequency (Regression Sample)")
graph export "$figures/ratio3_distribution_regsample.png", replace

// regression

eststo clear
eststo : reghdfe r3_biller_grad ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(Cohort_ID "Cohort FE" grad_year "Grad Year FE")

esttab est* using "$tables/fe-regs-ratio-cmsbiller-graduates.html", ///
	keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_schools N_clust, fmt(%9.0fc %9.0fc %9.0fc) labels("Observations (school-year)" "Schools" "Clusters")) ///
	title("Selection into Billing") addnotes("Standard errors clustered at Cohort level." "2K2K10K Cohort ID used, singletons included.") ///
	replace
	
**# Task 4D: Level Effects for CMS Biller
g ln_cms_biller = ln(cms_biller)

eststo clear
eststo : reghdfe ln_cms_biller ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(Cohort_ID "Cohort FE" grad_year "Grad Year FE")

esttab est* using "$tables/fe-regs-ln_cms_biller.html", ///
	keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_schools N_clust, fmt(%9.0fc %9.0fc %9.0fc) labels("Observations (school-year)" "Schools" "Clusters")) ///
	title("Level Effects of CMS Biller (logs)") addnotes("Standard errors clustered at Cohort level." "2K2K10K Cohort ID used, singletons included.") ///
	replace
	
	

