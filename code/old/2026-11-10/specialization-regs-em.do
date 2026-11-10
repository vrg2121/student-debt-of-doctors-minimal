* specialization regressions (all cms payments)

* average level of cms billing for each specialization
use "$working_data/cms_aamc_cohort_id", clear

replace phySpec = "FAMILY PRACTICE" if phySpec == "FAMILY MEDICINE"

replace phySpec = "OCCUPATIONAL THERAPY" if phySpec == "OCCUPATIONAL THERAPIST"

// should we combine Physical Therapist / Therapy and preventive / preventative medicine?

drop if phySpec == "" // 1 doctor

bys npi : egen num_spec = nvals(phySpec)

// generate dummy variables that correspond to label key

g d_phySpec = phySpec
replace d_phySpec = lower(d_phySpec)
replace d_phySpec = subinstr(d_phySpec, " ", "_", .)
replace d_phySpec = subinstr(d_phySpec, "(", "", .)
replace d_phySpec = subinstr(d_phySpec, ")", "", .)
replace d_phySpec = subinstr(d_phySpec, "/", "_", .)
replace d_phySpec = subinstr(d_phySpec, ",", "", .)
replace d_phySpec = substr(d_phySpec, 1, 28)
replace d_phySpec = "dum_" + d_phySpec
levelsof d_phySpec, local(specs) clean

foreach c in `specs' {
	g `c' = (d_phySpec == "`c'")
}

// drop variables omitted due to collinearity (these have very few observations)
drop dum_adult_congenital_heart_disea dum_anesthesiology_assistant dum_audiologist dum_certified_registered_nurse_a dum_clinical_psychologist dum_clinical_social_worker dum_epileptologists dum_physical_therapist dum_physical_therapy dum_preventive_medicine dum_psychologist_clinical dum_qualified_audiologist dum_qualified_speech_language_pa dum_registered_dietitian_or_nutr dum_vascular_surgery

save "$working_data/cms_aamc_cohort_specdum_em", replace

reghdfe fg_sel5_total_payments dum_*, a(time_since_grad_id#year#hrr)

regsave

keep var coef
rename var d_phySpec
rename coef spec_coef

save "$working_data/phySpec_dummy_coef_em", replace

use "$working_data/cms_aamc_cohort_specdum", clear

sort d_phySpec
merge m:1 d_phySpec using "$working_data/phySpec_dummy_coef_em"

keep if _merge == 3 // drops variables without coef due to collinearity
drop _merge dum_*

save "$working_data/cms_aamc_avgspecpymt_em", replace

* check number of specifications per doc *
tab num_spec 

* column 1: no change in specialization
use "$working_data/cms_aamc_avgspecpymt_em", clear
drop if num_spec > 1 // 15% of observations deleted

* regression
g tag = 1 if spec_coef == 0

eststo clear 

eststo : reghdfe spec_coef tuition_bill, a(cohort_id grad_year) vce(cluster cohort_id)

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

* column 2: keep first spec per doc *
use "$working_data/cms_aamc_avgspecpymt_em", clear

sort npi year
egen first_docspec = tag(npi)

bys npi phySpec (year): gen spec_seq = (_n == 1)
bys npi: replace spec_seq = sum(spec_seq)

keep if spec_seq == 1

//keep if first_docspec == 1

* regression
g tag = 1 if spec_coef == 0

eststo : reghdfe spec_coef tuition_bill, a(cohort_id grad_year) vce(cluster cohort_id)

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

* column 3: specialization with the most years or most years and chosen first *

use "$working_data/cms_aamc_avgspecpymt_em", clear

sort npi year
egen first_docspec = tag(npi)

bys npi phySpec : g no_year_spec = _N

bys npi : egen longest_spec = max(no_year_spec)

sort npi year
g longest_spec_dum = (no_year_spec == longest_spec)

bys npi phySpec: egen spec_first_year = min(year)
bys npi: egen earliest_max = min(spec_first_year) if longest_spec_dum
gen first_longest_spec = (longest_spec_dum == 1 & spec_first_year == earliest_max)

drop spec_first_year earliest_max longest_spec_dum

keep if first_longest_spec == 1

g tag = 1 if spec_coef == 0

* regression
eststo : reghdfe spec_coef tuition_bill, a(cohort_id grad_year) vce(cluster cohort_id)

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
estfe . est*, labels(cohort_id "Cohort FE" year "Grad Year FE")

esttab est* using "$tables/fe-regs-specialization-empymt.tex", ///
	drop(_cons) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') ///
	stats(N unique_drs N_clust /* unique_schools */ mean pct_mean nzero, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1 %9.0fc) labels("Observations (doctor-grad year)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef. \% of Mean" "Zeros")) ///
	mtitles("One Spec" "First Spec" "Longest Spec") ///
	replace
	
	
* Check for Differences in career outcomes for those who change careers in Cardio *
use "$working_data/cms_aamc_avgspecpymt_em", clear

collapse (count) npi (mean) num_spec (first) spec_coef, by(phySpec)

rename num_spec avg_num_spec
rename npi num_npi

gen cardio_tag = (strpos(phySpec, "CARDI") > 0 | strpos(phySpec, "HEART") > 0)

sum spec_coef, d

sum spec_coef if cardio_tag == 1, d

sum spec_coef if cardio_tag != 1, d

// based on st dev, there is a relatively normal amt of variation


