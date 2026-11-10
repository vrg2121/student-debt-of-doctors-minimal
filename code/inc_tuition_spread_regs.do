*** COEFFICIENT PLOTS FOR INCREASING TUITION BILL SPREAD ***

* To Do April 2, 2026 *

use "$working_data/cms_aamc_cohort_id", clear

drop if med_school == "medical university of south carolina college of medicine" // incorrect tuition data

bysort cohort_id: egen max_tbill = max(tuition_bill)
bysort cohort_id: egen min_tbill = min(tuition_bill)
g spread = max_tbill - min_tbill
label variable spread "Tuition Bill Spread (Thousands)"

// loop over spread = 1:9

* table 1 *
preserve

forvalues s = 1(1)9{
		
	keep if spread > `s'
	
	quietly reghdfe fg_sel3_total_payments tuition_bill, a(cohort_id#year hrr#year phySpec_id#time_since_grad_id#year) vce(cluster cohort_id)
	
	eststo Spread_`s'000
	
	unique cohort_id if e(sample) == 1
	local n_`s' `r(unique)'
	
	local o_`s' `e(N)'

	
}

coefplot Spread_*, vertical yline(0) keep(tuition_bill) note("Number of Cohorts (Tuition Spread):" "`n_1' ($1K), `n_2' ($2K), `n_3' ($3K), `n_4' ($4K), `n_5' ($5K), `n_6' ($6K), `n_7' ($7K), `n_8' ($8K), `n_9' ($9K)" "Doctor-Year Observations (Tuition Spread):" "`o_1' ($1K), `o_2' ($2K), `o_3' ($3K), `o_4' ($4K), `o_5' ($5K), `o_6' ($6K), `o_7' ($7K), `o_8' ($8K), `o_9' ($9K)" "Cohort-Year FE, HRR-Year FE, Specialization-Career-Year FE") ytitle("Tuition Bill Coefficient" " ")

graph export "$figures/inc_tuition_var_cms_pymt_.png", width(975) height(450) replace 

restore


* table 3 *
eststo clear

forvalues s = 1(1)9{
		
	keep if spread > `s'
	
	quietly reghdfe fg_sel5_total_payments tuition_bill, a(cohort_id#year hrr#year phySpec_id#time_since_grad_id#year) vce(cluster cohort_id)
	
	eststo Spread_`s'000
	
	unique cohort_id if e(sample) == 1
	local n_`s' `r(unique)'
	
	local o_`s' `e(N)'
}

coefplot Spread_*, vertical yline(0) keep(tuition_bill) note("Number of Cohorts (Tuition Spread):" "`n_1' ($1K), `n_2' ($2K), `n_3' ($3K), `n_4' ($4K), `n_5' ($5K), `n_6' ($6K), `n_7' ($7K), `n_8' ($8K), `n_9' ($9K)" "Doctor-Year-HCPCS Group Observations (Tuition Spread):" "`o_1' ($1K), `o_2' ($2K), `o_3' ($3K), `o_4' ($4K), `o_5' ($5K), `o_6' ($6K), `o_7' ($7K), `o_8' ($8K), `o_9' ($9K)" "Cohort-Year FE, HRR-Year FE, Specialization-Career-Year FE") ytitle("Tuition Bill Coefficient" " ")

graph export "$figures/inc_tuition_var_cms_em_pymt.png", width(975) height(450) replace

* table 6 *
eststo clear

use "$working_data/cms_aamc_hcpcsgrp_id", clear

drop if med_school == "medical university of south carolina college of medicine" // incorrect tuition data

forvalues s = 1(1)9{
		
	keep if spread > `s'
	
	quietly reghdfe tot_em_pymt tuition_bill, a(cohort_id#year time_since_grad_id#year phySpec_id#year hrr#year hcpcsgroup#year) vce(cluster cohort_id)
	
	eststo Spread_`s'000
	
	unique cohort_id if e(sample) == 1
	local n_`s' `r(unique)'
	
	local o_`s' `e(N)'
}

coefplot Spread_*, vertical yline(0) keep(tuition_bill) note("Number of Cohorts (Tuition Spread):" "`n_1' ($1K), `n_2' ($2K), `n_3' ($3K), `n_4' ($4K), `n_5' ($5K), `n_6' ($6K), `n_7' ($7K), `n_8' ($8K), `n_9' ($9K)" "Doctor-Year Observations (Tuition Spread):" "`o_1' ($1K), `o_2' ($2K), `o_3' ($3K), `o_4' ($4K), `o_5' ($5K), `o_6' ($6K), `o_7' ($7K), `o_8' ($8K), `o_9' ($9K)" "Cohort-Year FE, HRR-Year FE, Specialization-Year FE, Career Time-Year FE, HCPCS Group-Year FE") ytitle("Tuition Bill Coefficient" " ")

graph export "$figures/inc_tuition_var_hcpcsgrp_em_pymt.png", width(975) height(450) replace 


* table 10 *
eststo clear

use "$working_data/cms_aamc_isEM_id", clear

drop if med_school == "medical university of south carolina college of medicine" // incorrect tuition data

bysort cohort_id: egen max_tbill = max(tuition_bill)
bysort cohort_id: egen min_tbill = min(tuition_bill)
g spread = max_tbill - min_tbill
label variable spread "Tuition Bill Spread (Thousands)"

forvalues s = 1(1)9{
		
	keep if spread > `s'
	
	quietly reghdfe all_total_payments c.tuition_bill#1.isEM, a(npi#year cohort_id#year#isEM hrr#year#isEM phySpec_id#year#isEM#time_since_grad_id) vce(cluster cohort_id)
	
	eststo Spread_`s'000
	
	unique cohort_id if e(sample) == 1
	local n_`s' `r(unique)'
	
	local o_`s' `e(N)'

	
}

coefplot Spread_*, vertical yline(0) drop(_cons) note("Number of Cohorts (Tuition Spread):" "`n_1' ($1K), `n_2' ($2K), `n_3' ($3K), `n_4' ($4K), `n_5' ($5K), `n_6' ($6K), `n_7' ($7K), `n_8' ($8K), `n_9' ($9K)" "Doctor-Year-isEM Observations (Tuition Spread):" "`o_1' ($1K), `o_2' ($2K), `o_3' ($3K), `o_4' ($4K), `o_5' ($5K), `o_6' ($6K), `o_7' ($7K), `o_8' ($8K), `o_9' ($9K)" "Doctor-Year FE, Cohort-Year-EM FE, Region-Year-EM FE, Specializations-Year-EM-Career FE") ytitle("Tuition Bill Coefficient" " ")

graph export "$figures/inc_tuition_var_isEM.png", width(975) height(450) replace 

