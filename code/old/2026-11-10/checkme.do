*** COEFFICIENT PLOTS FOR INCREASING TUITION BILL SPREAD ***
** 2K 2K NK, where N=5:10 **

/*
1. merge the identified data together
2. load in identified data
3. save regression coefficients
4. 


*/
forvalues s = 5(1)10{
	global id_strat "2K2K8K"
	import excel "$dropbox/Claude Work to Idenitfy Cohorts/cms-aamc-allmedschoolyears-with-all-cohort-scenarios.xlsx", sheet("2K 2K 8K") cellrange(A1:I2866) firstrow clear
	rename npi npi_count

	summarize Cohort_ID
	local max_id = r(max)

	* Generate a counter for rows where id==0
	generate temp_counter = sum(Cohort_ID == 0)

	* Replace id==0 with new sequential IDs
	replace Cohort_ID = `max_id' + temp_counter if Cohort_ID == 0

	* Drop the temporary counter
	drop temp_counter

	* merge on doctor data *

	merge 1:m med_school grad_year using "$working_data/panels/cms-panel"
	keep if _merge == 3
	drop _merge

	g time_since_grad_id = year - grad_year
	encode phySpec, g(phySpec_id)

	global ln_outcome "ln_all_total_payments ln_fg_sel3_total_payments ln_fg_sel5_total_payments"

	g ln_tuition = ln(tuition)
	g ln_tuition_bill = ln(tuition_bill)

}
clear all
global id_strat "2K2K8K"
import excel "$dropbox/Claude Work to Idenitfy Cohorts/cms-aamc-allmedschoolyears-with-all-cohort-scenarios.xlsx", sheet("2K 2K 8K") cellrange(A1:I2866) firstrow clear
rename npi npi_count

summarize Cohort_ID
local max_id = r(max)

* Generate a counter for rows where id==0
generate temp_counter = sum(Cohort_ID == 0)

* Replace id==0 with new sequential IDs
replace Cohort_ID = `max_id' + temp_counter if Cohort_ID == 0

* Drop the temporary counter
drop temp_counter

* merge on doctor data *

merge 1:m med_school grad_year using "$working_data/panels/cms-panel"
keep if _merge == 3
drop _merge

g time_since_grad_id = year - grad_year
encode phySpec, g(phySpec_id)

global ln_outcome "ln_all_total_payments ln_fg_sel3_total_payments ln_fg_sel5_total_payments"

g ln_tuition = ln(tuition)
g ln_tuition_bill = ln(tuition_bill)

