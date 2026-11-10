*** Extensive Margin Analysis: Stats ***

* fulfills 2026-06-10_round2_sample_overlap *
* assumes that number of docs that graduate from a med school remains stable over time *

* LOAD DATA *
clear all
import excel "$dropbox/Claude/Claude Work to Identify Cohorts/cms-aamc-allmedschoolyears-with-all-cohort-scenarios.xlsx", sheet("2K 2K 10K") cellrange(A1:I2866) firstrow clear
rename npi npi_count

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

global ln_outcome "ln_all_total_payments ln_fg_sel3_total_payments ln_fg_sel5_total_payments"

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

save "$working_data/panels/cms-aamc-2k2k10k-nonsingleton.dta", replace
* how many schools vs doc with billing data *

preserve
// need to count unique npi with cms_npi == 1
// separately count unique npi with em_npi == 1
// compare with number of grad school per grad year
egen un_cms_npi = tag(npi) if cms_npi == 1
egen un_em_npi = tag(npi) if em_npi == 1
bys med_school grad_year: gen ms_in_grad_year = (_n == 1)
collapse (sum) ms_in_grad_year un_cms_npi un_em_npi, by(grad_year)

sum un_cms_npi
local cms_npi_ct `r(sum)'

sum un_em_npi
local em_npi_ct `r(sum)'

graph twoway ///
    (bar ms_in_grad_year grad_year, fcolor(ltblue) lcolor(ltblue) yaxis(1)) ///
    (line un_cms_npi grad_year, yaxis(2)) ///
    (line un_em_npi grad_year, yaxis(2)) ///
    , xlabel(, angle(45)) ///
    ylabel(, axis(1)) ///
    ylabel(, axis(2)) ///
    ytitle("Number of Med Schools", axis(1)) ///
    ytitle("Number of Doctors", axis(2)) ///
    legend(order(1 "Med Schools" 2 "Doc: CMS Billing" 3 "Doc: E/M Billing")) ///
	title("Graduation Year Coverage") ///
	note("2K2K10K cohort parameters applied. Doctor counts restricted to non-singleton cohorts." "Total Doctors with CMS Billing: `cms_npi_ct'" "Total Doctors with E/M Billing: `em_npi_ct'")

graph export "$figures/grad_year_coverage.png", replace
restore

* distribution of first cms billing career year *

keep if cms_npi == 1 // only keep doctor-year observations that bill cms

bys npi (year): gen first_billing_year=(_n == 1)
label variable first_billing_year "First CMS Billing Year"

table grad_year year if first_billing_year == 1, stat(freq) stat(perc, across(year))
collect export "$tables/grad_firstbilling_year.html", tableonly replace

preserve

keep if first_billing_year == 1
collapse (count) npi, by(time_since_grad_id)

rename npi npi_count
label variable npi_count "Number of Doctors"

graph bar ///
	(asis) npi_count, over(time_since_grad_id) ///
	ytitle("Number of Doctors") ///
	title("Distribution of First CMS Billing Year") ///
	note("2K2K10K cohort parameters applied. Doctor counts restricted to non-singleton cohorts.")
	
graph export "$figures/first_cms_billing_year.png", replace

restore

* fraction first observed in 2012 by grad year *
preserve

g first_bill_2012 = (first_billing_year == 1 & year == 2012)
egen un_cms_npi = tag(npi) if cms_npi == 1


collapse (sum) un_cms_npi first_bill_2012, by(grad_year)

g frac_first_obs_2012 = (first_bill_2012 / un_cms_npi) * 100
label variable frac_first_obs_2012 "Percent of Doctors First Billed in 2012"

graph bar ///
	(asis) frac_first_obs_2012, over(grad_year, label(angle(45))) ///
	ytitle("Doctor Billing CMS (%)") ///
	title("Fraction of Doctors First Observed in 2012 by Grad Year") ///
	note("2K2K10K cohort parameters applied. Doctor counts restricted to non-singleton cohorts.")
	
graph export "$figures/frac_first_obs_2012.png", replace

restore