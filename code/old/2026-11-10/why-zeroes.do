****************************************
*** CHECK FOR ZEROES IN RAW CMS DATA ***
****************************************

use "$working_data/temp/emiel-total_payments-fg-hcpcs-codes", clear

g tag = 1 if fg_sel3_total_payments == 0 | fg_sel5_total_payments == 0

replace tag = 0 if tag != 1

tab tag

// there are some zeroes in the raw cms payment data

*******************************************
*** CHECK FOR ZEROES IN FINAL CMS PANEL ***
*******************************************

use "$working_data/panels/cms-panel", clear

g tag = 1 if fg_sel3_total_payments == 0 | fg_sel5_total_payments == 0

replace tag = 0 if tag != 1

tab tag

g tagm = 1 if fg_sel3_total_payments == . | fg_sel5_total_payments == .

replace tagm = 0 if tagm != 1

tab tagm

// there are 8 zeroes in the final cms panel

*********************************************
*** CHECK FOR ZEROES AFTER CMS-AAMC MERGE ***
*********************************************

use "$working_data/cms_aamc_cohort_id", clear

g tag = 1 if fg_sel3_total_payments == 0 | fg_sel5_total_payments == 0

replace tag = 0 if tag != 1

tab tag

// there are 5 zeroes after the cms-aamc merge


***************************************************
*** CHECK FOR ZEROES FOR COHORTS WITH VARIATION ***
***************************************************

use "$working_data/cms_aamc_cohort_id", clear

drop if med_school == "medical university of south carolina college of medicine" // incorrect tuition data

bysort cohort_id: egen max_tbill = max(tuition_bill)
bysort cohort_id: egen min_tbill = min(tuition_bill)
g spread = max_tbill - min_tbill
label variable spread "Tuition Bill Spread (Thousands)"

keep if spread > 1 // keep if tuition bill spread > $1000

g tag = 1 if fg_sel3_total_payments == 0 | fg_sel5_total_payments == 0

replace tag = 0 if tag != 1

tab tag

// there is 1 zero in the merged cms-aamc data with variation