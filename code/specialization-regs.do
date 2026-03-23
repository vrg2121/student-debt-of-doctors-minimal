* specialization regressions

* average level of cms billing for each specialization
use "$working_data/cms_aamc_cohort_id", clear

drop if phySpec == "" // 1 doctor

bys npi : egen num_spec = nvals(phySpec)

tab num_spec 

// drop if num_spec > 1 // 15% of observations deleted

// generate dummy variables that correspond to label key

g d_phySpec = phySpec
replace d_phySpec = lower(d_phySpec)
replace d_phySpec = subinstr(d_phySpec, " ", "_", .)
replace d_phySpec = subinstr(d_phySpec, "(", "", .)
replace d_phySpec = subinstr(d_phySpec, ")", "", .)
replace d_phySpec = subinstr(d_phySpec, "/", "_", .)
replace d_phySpec = substr(d_phySpec, 1, 28)
replace d_phySpec = "dum_" + d_phySpec
levelsof d_phySpec, local(specs)

foreach c in `specs' {
	g `c' = (d_phySpec == "`c'")
}


// drop variables omitted due to collinearity (these have very few observations)
drop dum_adult_congenital_heart_disea dum_epileptologists dum_oral_surgery dum_preventive_medicine dum_qualified_speech_language_pa dum_registered_dietitian_or_nutr dum_undersea_and_hyperbaric_medi dum_vascular_surgery

save "$working_data/cms_aamc_cohort_specdum", replace

reghdfe fg_sel3_total_payments dum_*, a(time_since_grad_id#year#hrr)

regsave

keep var coef
rename var d_phySpec
rename coef spec_coef

save "$working_data/phySpec_dummy_coef", replace

use "$working_data/cms_aamc_cohort_specdum", clear

sort d_phySpec
merge m:1 d_phySpec using "$working_data/phySpec_dummy_coef"

keep if _merge == 3 // drops variables without coef due to collinearity
drop _merge dum_*

* regression
g tag = 1 if spec_coef == 0

eststo clear 

eststo : reghdfe spec_coef tuition_bill, a(cohort_id year) vce(cluster school_id)

** Mean:
sum spec_coef if e(sample) == 1
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


esttab est*, keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(cohort_id "Cohort FE" year "Year FE")

esttab est* using "$tables/fe-regs-specialization.tex", ///
	drop(_cons) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_drs N_clust /* unique_schools */ mean pct_mean nzero, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1 %9.0fc) labels("Observations (doctor-year)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef. /% of Mean" "Number of Zeroes")) ///
	replace


