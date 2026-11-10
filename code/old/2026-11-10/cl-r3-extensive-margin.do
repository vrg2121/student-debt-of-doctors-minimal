*** Extensive Margin Analysis: Regressions ***

* fulfills 2026-06-18_round3_extensive_margin *

**# Binary Extensive Margin 
use "$working_data/panels/cms-aamc-2k2k10k-nonsingleton.dta", clear

* career year >= 3 *
keep if time_since_grad_id > 2

* binary outcome *
g biller_cms = (fg_sel3_total_payments > 0 & fg_sel3_total_payments != .)
g biller_em = (fg_sel5_total_payments > 0 & fg_sel5_total_payments != .)

label variable biller_cms "Positive CMS Bill"
label variable biller_em "Positive E/M Bill"

global outcome "biller_cms biller_em"


foreach oc of global outcome {
		
	g tag = 1 if `oc' == 0
	
	eststo clear
	
	* row 1: No FE
	
	eststo : reghdfe `oc' ln_tuition_bill, vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
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
	
	* row 2: Cohort FE
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID) vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
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
	
	* row 3: Cohort#Year FE
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year) vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
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
	
	* row 4: Cohort#Year HRR#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year) vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
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
	
	* row 5: Cohort#Year HRR#Year Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year time_since_grad_id#year) vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
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

	* format output

	esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(Cohort_ID "Cohort FE" Cohort_ID#year "Cohort-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career-Year FE")						
		
	esttab est* using "$tables/extmarg-noPhyspec-fe-regs-`oc'.html", ///
		keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N unique_drs N_clust /* unique_schools */ mean pct_mean nzero, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1 %9.0fc) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef. % of Mean" "Zeroes")) ///
		title("Binary Extensive Margin: `: var label `oc''") ///
		note("Standard Errors clustered at Cohort level." "2K2K10K, non-singleton Cohort parameters.") ///
		replace
		
	drop tag
}

foreach oc of global outcome {
			
	g tag = 1 if `oc' == 0 | `oc' == .
	
	eststo clear
	
	* row 1: Cohort#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year) vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
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
	
	* row 2: Cohort#Year HRR#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year) vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
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
	
	* row 3: Cohort#Year HRR#Year Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year time_since_grad_id#year) vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
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
	
	* row 4: Cohort#Year HRR#Year Career_Time#Year Specialization#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year time_since_grad_id#year phySpec_id#year) vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
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
	
	* row 5: Cohort#Year HRR#Year Specialization#Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_id#time_since_grad_id#year) vce(cluster Cohort_ID)

	** Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[ln_tuition_bill] / r(mean)
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

	* format output

	esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(Cohort_ID#year "Cohort-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career-Year FE" phySpec_id#year "Specialization-Year FE" phySpec_id#time_since_grad_id#year "Specialization-Career-Year FE")					
		
	esttab est* using "$tables/extmarg-Physpec-fe-regs-`oc'.html", ///
		keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N unique_drs N_clust /* unique_schools */ mean pct_mean nzero, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1 %9.0fc) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef. % of Mean" "Zeroes")) ///
		title("Binary Extensive Margin: `: variable label `oc'' (Baseline FE)") ///
		note("Standard Errors clustered at Cohort level." "2K2K10K non-singleton Cohort parameters.") ///
		replace
		
	drop tag
}

**# Count regression: Does tuition affect how many doctors from a cohort enter Medicare billing? *

use "$working_data/panels/cms-aamc-2k2k10k-singleton.dta", clear

collapse (first) ln_tuition_bill npi_count Cohort_ID (sum) em_npi cms_npi, by(med_school grad_year)
rename em_npi em_count
rename cms_npi cms_count

g ln_cms_count = ln(cms_count)
g ln_em_count = ln(em_count)

label variable ln_tuition_bill "Tuition Bill (logs)"

drop if ln_cms_count == . | ln_em_count == .

eststo clear
eststo : reghdfe ln_cms_count ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

unique Cohort_ID if e(sample) == 1
estadd scalar unique_cohort = r(unique)

eststo : reghdfe ln_em_count ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

unique Cohort_ID if e(sample) == 1
estadd scalar unique_cohort = r(unique)

esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(Cohort_ID "Cohort FE" grad_year "Grad Year FE")
	
esttab est* using "$tables/countdoc-fe-regs-2k2k10k.html", ///
	keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') mtitles("CMS Count (log)" "E/M Count (log)") ///
	stats(N N_clust, fmt(%9.0fc %9.0fc) labels("Observations (school-grad years)" "Clusters")) ///
	title("Count Regressions") ///
	note("Standard Errors clustered at Cohort level." "2K2K10K singleton Cohort parameters.") ///
	replace
	
	
* robustness check: 1K1K10K *
use "$working_data/panels/cms-aamc-1k1k10k-singleton.dta", clear

collapse (first) ln_tuition_bill npi_count Cohort_ID (sum) em_npi cms_npi, by(med_school grad_year)
rename em_npi em_count
rename cms_npi cms_count

g ln_cms_count = ln(cms_count)
g ln_em_count = ln(em_count)

label variable ln_tuition_bill "Tuition Bill (logs)"

drop if ln_cms_count == . | ln_em_count == .

eststo clear
eststo : reghdfe ln_cms_count ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

unique Cohort_ID if e(sample) == 1
estadd scalar unique_cohort = r(unique)

eststo : reghdfe ln_em_count ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

unique Cohort_ID if e(sample) == 1
estadd scalar unique_cohort = r(unique)

esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(Cohort_ID "Cohort FE" grad_year "Grad Year FE")
	
esttab est* using "$tables/countdoc-fe-regs-1k1k10k.html", ///
	keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') mtitles("CMS Count (log)" "E/M Count (log)") ///
	stats(N N_clust, fmt(%9.0fc %9.0fc) labels("Observations (school-grad years)" "Clusters")) ///
	title("Count Regressions: Robustness Check") ///
	note("Standard Errors clustered at Cohort level." "1K1K10K singleton Cohort parameters.") ///
	replace
	
**# Career Onset

* PREP DATA: STANDARD COHORT DEF
use "$working_data/panels/cms-aamc-2k2k10k-nonsingleton.dta", clear

keep if grad_year > 2009 & grad_year < 2015 // grad year 2010-2014

* keep only doctors that bill
bys npi: egen cms_ever_nonzero = max(cms_npi != 0)
bys npi: egen em_ever_nonzero = max(em_npi != 0)

g tag = (cms_ever_nonzero == 0 & em_ever_nonzero == 0)

drop if tag == 1
drop tag cms_ever_nonzero em_ever_nonzero

* count number of grad_years per Cohort_ID
egen d1 = tag(Cohort_ID grad_year)
bys Cohort_ID: replace d1 = sum(d1)
bys Cohort_ID: egen cohort_gycount = max(d1)
drop d1
g mult_gy_cohort = (cohort_gycount > 1)


* identify first billing year per doctor
sort npi year
bys npi (year): g bill_year = year if cms_npi == 1
bys npi: egen first_bill_year = min(bill_year)

g years_to_first_billing = first_bill_year - grad_year

* keep only one observation of npi
bys npi: keep if _n == 1

save "$working_data/panels/career-onset-2k2k10k-standard-nonsingleton", replace

* PREP DATA: WINDOW-TARGED COHORT DEF
import delimited "$dropbox/Claude/From Claude/cms-aamc-allmedschoolyears-with-cohorts-2k2k10k-window2010-2014.csv", clear
rename npi npi_count
rename cohort_id Cohort_ID

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

merge 1:m med_school grad_year using "$working_data/panels/cms-panel"
keep if _merge == 3
drop _merge

g time_since_grad_id = year - grad_year
encode phySpec, g(phySpec_id)
//g cohort_zero = (Cohort_ID == 0)

global outcome "all_total_payments fg_sel3_total_payments fg_sel5_total_payments"

foreach var of global outcome {
    generate ln_`var' = ln(`var')
}

destring tuition, replace
g ln_tuition = ln(tuition)
g ln_tuition_bill = ln(tuition_bill)

label variable ln_tuition_bill "Tuition Bill (logs)"
label variable tuition_bill "Tuition Bill"

label variable all_total_payments "All Total Payments"
label variable fg_sel3_total_payments "CMS Payments"
label variable fg_sel5_total_payments "CMS E/M Payments"

label variable ln_all_total_payments "All Total Payments (logs)"
label variable ln_fg_sel3_total_payments "CMS Payments (logs)"
label variable ln_fg_sel5_total_payments "CMS E/M Payments (logs)"

label variable grad_year "Med School Graduation Year"
label variable time_since_grad_id "Career Length"

egen cms_npi = tag(npi year) if fg_sel3_total_payments != 0 & fg_sel3_total_payments != .
label variable cms_npi "Doctor Billed CMS (Binary)"

egen em_npi = tag(npi year) if fg_sel5_total_payments != 0 & fg_sel5_total_payments != .
label variable em_npi "Doctor Billed E/M CMS (Binary)"

keep if grad_year > 2009 & grad_year < 2015 // grad year 2010-2014

* keep only doctors that bill
bys npi: egen cms_ever_nonzero = max(cms_npi != 0)
bys npi: egen em_ever_nonzero = max(em_npi != 0)

g tag = (cms_ever_nonzero == 0 & em_ever_nonzero == 0)

drop if tag == 1
drop tag cms_ever_nonzero em_ever_nonzero

* count number of grad_years per Cohort_ID
egen d1 = tag(Cohort_ID grad_year)
bys Cohort_ID: replace d1 = sum(d1)
bys Cohort_ID: egen cohort_gycount = max(d1)
drop d1
g mult_gy_cohort = (cohort_gycount > 1)


* identify first billing year per doctor
sort npi year
bys npi (year): g bill_year = year if cms_npi == 1
bys npi: egen first_bill_year = min(bill_year)

g years_to_first_billing = first_bill_year - grad_year

* keep only one observation of npi
bys npi: keep if _n == 1

save "$working_data/panels/career-onset-2k2k10k-windows-nonsingleton.dta", replace


* REGRESSION ANALYSIS 

eststo clear

* col 1
use "$working_data/panels/career-onset-2k2k10k-standard-nonsingleton", clear
g tag = 1 if years_to_first_billing == 0

* Standard Cohort Def
eststo: reghdfe years_to_first_billing ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

** Mean:
sum years_to_first_billing if e(sample) == 1
estadd r(mean)
estadd r(sd)

** unique cohort
unique Cohort_ID if e(sample) == 1
estadd scalar cohort_count = r(unique)

** unique cohort with multiple grad years
unique Cohort_ID if e(sample) == 1 & mult_gy_cohort == 1
estadd scalar cohort_mult_gy = r(unique)

** number of zeros
sum tag if e(sample) == 1
estadd scalar nzero = r(sum)

* col 2
use "$working_data/panels/career-onset-2k2k10k-windows-nonsingleton", clear
g tag = 1 if years_to_first_billing == 0

* Standard Cohort Def
eststo: reghdfe years_to_first_billing ln_tuition_bill, a(Cohort_ID grad_year) vce(cluster Cohort_ID)

* stats to report:
	* years_to_first_billing: mean, st. dev /
	* number of doctors /
	* number of cohorts with at least 2 grad years in 2010-2014 window (cohort_gycount) /
** Mean:
sum years_to_first_billing if e(sample) == 1
estadd r(mean)
estadd r(sd)

** unique cohort
unique Cohort_ID if e(sample) == 1
estadd scalar cohort_count = r(unique)

** unique cohort with multiple grad years
unique Cohort_ID if e(sample) == 1 & mult_gy_cohort == 1
estadd scalar cohort_mult_gy = r(unique)

** number of zeros
sum tag if e(sample) == 1
estadd scalar nzero = r(sum)

esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(Cohort_ID "Cohort FE" grad_year "Grad Year FE")						
		
esttab est* using "$tables/career-onset-fe-regs.html", ///
	keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') mtitles("Standard Cohort" "Window Cohort") ///
	stats(N mean sd cohort_count cohort_mult_gy nzero, fmt(%9.0fc %10.0g %10.0g %9.0fc %9.0fc %9.0fc) labels("Observations (doctors)" "Mean" "St. Dev." "Cohort Count" "Multi-Year Cohort Count" "Zeroes")) ///
	title("Career Onset: Years to First Billing") ///
	note("Standard Errors clustered at Cohort level." "2K2K10K non-singleton Cohort parameters.") ///
	replace
