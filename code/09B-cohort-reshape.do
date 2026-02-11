/*

This file reshapes the merged data so that the cohorts are recorded as categorical variables rather than dummies

Victoria Garcia
2.5.2026
*/

use "$working_data/cms_aamc_merge_identifier", clear

g cohort = ""
label variable cohort "Cohort ID"

foreach dum of varlist dum_* {
	replace cohort = "`dum'" if cohort == "" & `dum' == 1
}

encode cohort, g(cohort_id)
label variable cohort_id "Categorical Cohort ID"

drop dum_*

g time_since_grad = year - grad_year

tostring time_since_grad, replace

encode time_since_grad, g(time_since_grad_id)
encode phySpec, g(phySpec_id)

save "$working_data/cms_aamc_cohort_id", replace
