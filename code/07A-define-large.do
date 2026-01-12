/* 

PREAMBLE

This file defines large in 4 different ways:

1. Absolute change in real tuition across all time and med schools
	(e.g. $2000 increase in real tuition)
2. Relative change in real tuition across all time and med schools 
	(e.g. 7% increase in real tuition)
3. Relative change in real tuition within each year across all med schools 
	(e.g. med school A had an increase in tuition in the 90th percentile in 2001 when compared to all other med schools.)
4. Relative change in real tuition across all years within each med school
	(e.g. med school A had an increase in tuition in the 90th percentile in 2001 when compared to its usual variation in tuition.)
   
This file identifies cohort-dummies as specified in the Revamp of Empirical Strategy.

Victoria Garcia 
10.24.2025
*/


*** DEFINE LARGE TUITION INCREASE ***

global abs_large = 2 // absolute change of real tuition in thousands

global rel_large = 7 // relative change of real tuition in %


*** Reviewing the Data ***
* Check for Tuition Decreases *

use "$working_data/panels/aamc-tuition", clear


/*  ANLYSIS OF NEGATIVE TUITION CHANGES
g neg_delta_nominal = delta_nominal_tuition <= 0
g neg_delta = delta_tuition <= 0

count if delta_nominal_tuition != . // 3,950
count if delta_tuition != . 		// 3,950

count if neg_delta_nominal 			// 682 (17%)
count if neg_delta 					// 1242 (31%)
*/

/* * Graphs to Check Tuition Trends *

graph box tuition, over(aca_year, lab(angle(45))) ytitle("Reported Tuition" "1,000 USD (2014 Base Year)")
graph export "real_tuition.png", as(png) replace

graph box tuition_bill, over(aca_year, lab(angle(45))) ytitle("4 Years of Tuition" "1,000 USD (2014 Base Year)") // Manually Added Xtitle because the code would not allow me for some reason
graph export "4_Year_Tuition_bill_no_xtitle.png", as(png) replace
*/

* Quartiles for Real Tuition Deltas*

sum delta_tuition, detail
generate delta_tuition_q = 1
replace delta_tuition_q = 2 if delta_tuition > r(p25)
replace delta_tuition_q = 3 if delta_tuition > r(p50)
replace delta_tuition_q = 4 if delta_tuition > r(p75)
replace delta_tuition_q = . if missing(delta_tuition)
// sum delta_tuition if delta_tuition_q == 4 // mean = 2.162174, min = 1.024298


*** Absolute Value of Large Tuition Delta ***

g abs_lg_delta = 1 if delta_tuition >= $abs_large
replace abs_lg_delta = . if missing(delta_tuition)
label variable abs_lg_delta "Large absolute change in real tuition, delta_tuition >= $abs_large"


*** Relative Value of Large Tuition Delta ***

g pct_delta = (delta_tuition / tuition) * 100
replace pct_delta = . if missing(delta_tuition)
label variable pct_delta "Percent change in tuition from previous year (%)"
sum pct_delta, detail // 6.8% is the 90th percentile

g pct_nom_delta = (delta_nominal_tuition / nominal_tuition) * 100
replace pct_nom_delta = . if missing(delta_nominal_tuition)
replace pct_nom_delta = delta_nominal_tuition if missing(delta_nominal_tuition)
label variable pct_nom_delta "Percent change in nominal tuition from previous year (%)" // 9% is the 90th percentile

/* note: pct_delta vs pct_nom_delta
It's probably best to use the pct_delta, which is built on real tuition values to compare the actual changes in tuition across years. For example, a tuition that did not change would be correctly identified as reducing in actual cost because it failed to adjust for inflation.
*/

g rel_lg_delta = 1 if pct_delta >= $rel_large
replace rel_lg_delta = . if missing(pct_delta)
label variable rel_lg_delta "Large relative change in real tuition, pct_delta >= `rel_large'"


*** Relative Value of Large Tuition Delta by Year ***

/* note: relative value reasoning and the 90th pctile
i.e. if the average tuition change was negative for all schools, a small positive increase would be relatively large
e.g. in 2022, the % change in tuition on average was -56.255%, whereas the average % change in 2015 was 3.854%

Note: This is automatically set to approx 1/10 of the dataset having a "large" increase in tuition. It's a little less than a 10th of the data because some of the cutoff points were negative.
*/

g rel_ann_lg_delta = 0
forvalues i = 1996/2024 {
	sum pct_delta if aca_year == `i', detail
	loc min_sig_pct = r(p90)
	display "The minimum significant 90th percentile change in tuition for `i' is `min_sig_pct'"
	
	// ensure that  large increases are strictly positive
	if `min_sig_pct' >= 0 {
		replace rel_ann_lg_delta = 1 if (aca_year==`i') & (pct_delta >= `min_sig_pct')
	}
	else {
		replace rel_ann_lg_delta = 1 if (aca_year==`i') & (pct_delta > 0)
	}
}
replace rel_ann_lg_delta = . if missing(delta_tuition)
label variable rel_ann_lg_delta "Large relative change in real tuition within year, 90th pctile"


*** Set a Relative Value of Large Tuition Delta by School ***
g rel_sch_lg_delta = 0
foreach school in med_school {
	sum pct_delta if med_school == `school', detail
	loc min_sig_pct = r(p90)
	display "The minimum significant 90th percentile change in tuition for `med_school' is `min_sig_pct'"
	
	// ensure that  large increases are strictly positive
	if `min_sig_pct' >= 0 {
		replace rel_sch_lg_delta = 1 if (med_school==`school') & (pct_delta >= `min_sig_pct')
	}
	else {
		replace rel_sch_lg_delta = 1 if (med_school==`school') & (pct_delta > 0)
	}
}
replace rel_sch_lg_delta = . if missing(delta_tuition)
label variable rel_sch_lg_delta "Large relative change in real tuition within med school, 90th pctile"

tabstat abs_lg_delta rel_lg_delta rel_ann_lg_delta rel_sch_lg_delta, statistics(sum mean count) columns(statistics)

/**** How Aligned are the Definitions of Large? ***
g only_abs_lg = 0
replace only_abs_lg = 1 if (abs_lg_delta == 1) & (rel_lg_delta == 0) & (rel_ann_lg_delta == 0) & (rel_sch_lg_delta == 0)
replace only_abs_lg = . if missing(delta_tuition)

g only_rel_lg = 0
replace only_rel_lg = 1 if (abs_lg_delta == 0) & (rel_lg_delta == 1) & (rel_ann_lg_delta == 0) & (rel_sch_lg_delta == 0)
replace only_rel_lg = . if missing(delta_tuition)

g only_ann_rel_lg = 0
replace only_ann_rel_lg = 1 if (abs_lg_delta == 0) & (rel_lg_delta == 0) & (rel_ann_lg_delta == 1) & (rel_sch_lg_delta == 0)
replace only_ann_rel_lg = . if missing(delta_tuition)

g only_sch_rel_lg = 0
replace only_sch_rel_lg = 1 if (abs_lg_delta == 0) & (rel_lg_delta == 0) & (rel_ann_lg_delta == 0) & (rel_sch_lg_delta == 1)
replace only_sch_rel_lg = . if missing(delta_tuition)

tabstat only_abs_lg only_rel_lg only_ann_rel_lg only_sch_rel_lg, statistics(sum mean count) columns(statistics)

/* summary: unique tags for different def of large (last updated: 10.24)
relatively large for all years and all med schools: 0 / 390 (0%) 
absolutely large for all years and all med schools: 57 / 324 (18%)
relatively large for each year and all med schools: 105 / 412 (25%)
relatively large for all years and each med school: 12 / 425 (3%)
*/
*/

*** Create Cohort Dummies ***
g grad_year = aca_year + 1 // Adjusting for grad_year; e.g. 2001 if graduating in academic year 2000-2001
					 
egen school_id = group(med_school)
sort school_id grad_year

by school_id : g obsnum = _n

// Create cohort change indicators
g cohort_reason = ""
by school_id : g new_cohort = 1 if abs_lg_delta == 1 // CHANGE DEF OF LARGE HERE
replace cohort_reason = "tuition-change" if new_cohort == 1
replace new_cohort = 1 if obsnum == 1 // new cohort marker begins with new school
replace cohort_reason = "first-yr-data" if new_cohort == 1 & obsnum == 1

global base_yr = .
global tot = _N

forval i = 1/$tot {
	if new_cohort[`i'] == 1 {
		global base_yr = aca_year[`i']
	}
	else{
		if $base_yr != . {
			loc current = aca_year[`i']
			if `current' - $base_yr > 3 {
				replace new_cohort = 1 in `i'
				global base_yr = aca_year[`i']
			}
		}
	}
} // new cohort marker every 4 years 
replace cohort_reason = "4-yr-cohort" if new_cohort == 1 & cohort_reason == ""

g cohort_year = grad_year if new_cohort == 1
replace cohort_year = cohort_year[_n - 1] if missing(cohort_year) // cohorts are defined by the year they STARTED

save "$working_data/aamc_large_id_cohort_analysis", replace
replace cohort_reason = cohort_reason[_n - 1] if cohort_reason == ""

// create dum_* variables
by school_id : g counter = mod(grad_year - cohort_year, 4) + 1
by school_id : g group = sum(counter == 1)

levelsof school_id

foreach school in `r(levels)' {
	quietly summarize group if school_id == `school'
	loc max_group = r(max)
	
	forvalues i = 1/`max_group'{
		loc lett = char(96+`i')
		g dum_`school'`lett' = (school_id == `school' & group == `i')
	}
	
}

label var cohort_reason "new cohort assignment reason"

drop new_cohort cohort_year group counter obsnum


*** Export School data with "large" identifiers ***
save "$working_data/aamc_large_identifier", replace


