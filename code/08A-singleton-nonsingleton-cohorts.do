************************************************************
*** MERGE SINGLETON AND NONSINGLETON COHORT ID ONTO DATA ***
************************************************************

**# Identify Singleton Cohorts

clear all

global id_strat "2K2K10K"
import excel "$dropbox/Claude/Claude Work to Identify Cohorts/cms-aamc-allmedschoolyears-with-cohorts-with-all-cohort-scenarios.xlsx", sheet("2K 2K 10K") firstrow clear

summarize Cohort_ID
local max_id = r(max)

generate temp_counter = sum(Cohort_ID == 0)

replace Cohort_ID = `max_id' + temp_counter if Cohort_ID == 0

drop temp_counter

destring tuition, replace

foreach var of varlist tuition tuition_bill {
    generate ln_`var' = ln(`var')
}

label variable ln_tuition_bill "Tuition Bill (logs)"
label variable tuition_bill "Tuition Bill"

save "$working_data/panels/aamc_id_2k2k10k_singleton", replace

* Merge on Doctor Data
merge 1:m med_school grad_year using "$working_data/panels/aamc_cms_npi_year"
keep if _merge == 3
drop _merge

g time_since_grad_id = event_time

drop *fg_sel1* *fg_sel2* *fg_sel4* 

global outcome "fg_sel3_total_payments fg_sel5_total_payments nServ fg_sel5_nServ fg_sel3_nServ"

foreach var of varlist $outcome {
    generate ln_`var' = ln(`var')
}

label variable fg_sel3_total_payments "CMS Payments"
label variable fg_sel5_total_payments "CMS E/M Payments"
label variable nServ "CMS Service Count"

label variable ln_fg_sel3_total_payments "CMS Payments (logs)"
label variable ln_fg_sel5_total_payments "CMS E/M Payments (logs)"
label variable ln_nServ "CMS Service Count (logs)"

g ln_fg_sel5_avg_pymt = ln_fg_sel5_total_payments - ln_fg_sel5_nServ
g ln_fg_sel3_avg_pymt = ln_fg_sel3_total_payments - ln_fg_sel3_nServ

save "$working_data/panels/aamc_cms_id_2k2k10k_singleton", replace
export delimited "$working_data/panels/aamc_cms_id_2k2k10k_singleton.csv", replace


**# Identify non-singleton cohorts
clear all

global id_strat "2K2K10K"
import excel "$dropbox/Claude/Claude Work to Identify Cohorts/cms-aamc-allmedschoolyears-with-cohorts-with-all-cohort-scenarios.xlsx", sheet("2K 2K 10K") firstrow clear

destring tuition, replace

drop if Cohort_ID == 0

* Merge on Doctor Data
merge 1:m med_school grad_year using "$working_data/panels/aamc_cms_npi_year"
keep if _merge == 3
drop _merge

g time_since_grad_id = event_time

drop *fg_sel1* *fg_sel2* *fg_sel4* 

global outcome "fg_sel3_total_payments fg_sel5_total_payments nServ fg_sel5_nServ fg_sel3_nServ"

foreach var of varlist $outcome tuition tuition_bill {
    generate ln_`var' = ln(`var')
}

label variable ln_tuition_bill "Tuition Bill (logs)"
label variable tuition_bill "Tuition Bill"

label variable fg_sel3_total_payments "CMS Payments"
label variable fg_sel5_total_payments "CMS E/M Payments"
label variable nServ "CMS Service Count"

label variable ln_fg_sel3_total_payments "CMS Payments (logs)"
label variable ln_fg_sel5_total_payments "CMS E/M Payments (logs)"
label variable ln_nServ "CMS Service Count (logs)"

g ln_fg_sel5_avg_pymt = ln_fg_sel5_total_payments - ln_fg_sel5_nServ
g ln_fg_sel3_avg_pymt = ln_fg_sel3_total_payments - ln_fg_sel3_nServ

save "$working_data/panels/aamc_cms_id_2k2k10k_nonsingleton", replace
export delimited "$working_data/panels/aamc_cms_id_2k2k10k_nonsingleton.csv", replace
