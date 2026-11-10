 *** Tuition and Career Choice (Task 2) ***

* fulfills 2026-07-14_round6_tasks *

** Task 1: Specialty Choice by Training Length **

**# Build Specialty Training Length Crosswalk
* convert to dta *

import delimited "$working_data/temp/physpec_training_length_crosswalk_2026-07-22_manual_edits.csv", clear
rename physpec phySpec
save "$working_data/temp/physpec_training_crosswalk_manual_edits", replace

import delimited "$working_data/temp/physpec_training_length_crosswalk_2026-07-22.csv", clear
rename physpec phySpec
save "$working_data/temp/physpec_training_crosswalk", replace

**# Merge Doximity and singleton-cohort doctors (Claude Duplication)
* data of cms ever-billers singleton-cohort doctors cms ever-billers*
use "$working_data/panels/cms-aamc-2k2k10k-singleton.dta", clear

sort npi year
bys npi : egen ever_cms = max(fg_sel3_total_payments != 0 & fg_sel3_total_payments != .)

* assign each doc spec and hrr in first year of cms billing

keep if ever_cms == 1

bys npi (year) : gen cumsum = sum(cms_npi) // first year that doctor billed cms

keep if cumsum == 1

drop if cms_npi == 0

* merge avg_compensation_2024 via phySpec

merge m:1 phySpec using "$working_data/temp/physpec_training_crosswalk"

keep if _merge == 3
drop _merge

* drop doctors with confidence_tier == unmatched | non_physician

drop if confidence_tier == "unmatched" | confidence_tier == "non_physician"

eststo clear

* row 1: Cohort FE

eststo : reghdfe total_training_years ln_tuition_bill, a(Cohort_ID) vce(cluster Cohort_ID)

** Mean:
sum total_training_years if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
estadd scalar pct_mean

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

* row 2: Cohort + grad_year FE
eststo : reghdfe total_training_years ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

** Mean:
sum total_training_years if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
estadd scalar pct_mean

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

* row 3: Cohort + grad_year + hrr FE
eststo : reghdfe total_training_years ln_tuition_bill, a(Cohort_ID grad_year hrr) vce(cluster Cohort_ID)

** Mean:
sum total_training_years if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
estadd scalar pct_mean

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(Cohort_ID "Cohort FE" grad_year "Grad Year FE" hrr "HRR FE")						
	
esttab est* using "$tables/fe-regs-total_training_years.html", ///
	keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N  N_clust /* unique_schools */ mean pct_mean, fmt(%9.0fc %9.0fc /* %9.0fc */ 3 1 %9.0fc) labels("Observations (doctors)" "Clusters" /* "Schools" */ "Mean" "Coef. % of Mean")) ///
	title("Specialty Choice by Training Length [Claude Replication]") ///
	note("Standard Errors clustered at Cohort level." "2K2K10K, singleton Cohort parameters." "Training length data manually collected, primarily from ACMGE.") ///
	replace
	
**# Merge Doximity and singleton-cohort doctors (Manual Edits)
* data of cms ever-billers singleton-cohort doctors cms ever-billers*
use "$working_data/panels/cms-aamc-2k2k10k-singleton.dta", clear

sort npi year
bys npi : egen ever_cms = max(fg_sel3_total_payments != 0 & fg_sel3_total_payments != .)

* assign each doc spec and hrr in first year of cms billing

keep if ever_cms == 1

bys npi (year) : gen cumsum = sum(cms_npi) // first year that doctor billed cms

keep if cumsum == 1

drop if cms_npi == 0

* merge avg_compensation_2024 via phySpec

merge m:1 phySpec using "$working_data/temp/physpec_training_crosswalk_manual_edits"

keep if _merge == 3
drop _merge

* drop doctors with confidence_tier == unmatched | non_physician

drop if confidence_tier == "unmatched" | confidence_tier == "non_physician"

eststo clear

* row 1: Cohort FE

eststo : reghdfe total_training_years ln_tuition_bill, a(Cohort_ID) vce(cluster Cohort_ID)

** Mean:
sum total_training_years if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
estadd scalar pct_mean

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

* row 2: Cohort + grad_year FE
eststo : reghdfe total_training_years ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

** Mean:
sum total_training_years if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
estadd scalar pct_mean

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

* row 3: Cohort + grad_year + hrr FE
eststo : reghdfe total_training_years ln_tuition_bill, a(Cohort_ID grad_year hrr) vce(cluster Cohort_ID)

** Mean:
sum total_training_years if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
estadd scalar pct_mean

** unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(Cohort_ID "Cohort FE" grad_year "Grad Year FE" hrr "HRR FE")						
	
esttab est* using "$tables/v_edit-fe-regs-total_training_years.html", ///
	keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N  N_clust /* unique_schools */ mean pct_mean, fmt(%9.0fc %9.0fc /* %9.0fc */ 3 1 %9.0fc) labels("Observations (doctors)" "Clusters" /* "Schools" */ "Mean" "Coef. % of Mean")) ///
	title("Specialty Choice by Training Length [Manual Edits]") ///
	note("Standard Errors clustered at Cohort level." "2K2K10K, singleton Cohort parameters." "Training length data manually collected, primarily from ACMGE.") ///
	replace