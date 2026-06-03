*** COEFFICIENT PLOTS FOR INCREASING TUITION SPREADS ***

**# 2K 2K 5K-12K COL 5 

* clean cohort_id data, export as dta for merges *
forvalues s = 5(1)12{
	import excel "$dropbox/Claude Work to Identify Cohorts/cms-aamc-allmedschoolyears-with-all-cohort-scenarios.xlsx", sheet("2K 2K `s'K") cellrange(A1:I2866) firstrow clear
	rename npi npi_count
	g original_cohort = Cohort_ID

	// replace Cohort_ID == 0 with sequential ID's
	summarize Cohort_ID
	local max_id = r(max)
	generate temp_counter = sum(Cohort_ID == 0)
	replace Cohort_ID = `max_id' + temp_counter if Cohort_ID == 0
	drop temp_counter
	
	g ln_tuition = ln(tuition)
	g ln_tuition_bill = ln(tuition_bill)
	
	label variable ln_tuition_bill "Tuition Bill (logs)"
	
	save "$working_data/cohorts2K2K`s'K", replace
}

* CLUSTERING AT COHORT LEVEL *

* total cms billing *
forvalues s = 5(1)12{
	use "$working_data/panels/cms-panel", clear
	g time_since_grad_id = year - grad_year
	encode phySpec, g(phySpec_id)

	// log of relevant variables
	g ln_fg_sel3_total_payments = ln(fg_sel3_total_payments)
	g ln_fg_sel5_total_payments = ln(fg_sel5_total_payments)
	// merge on doctor data 
	merge m:1 med_school grad_year using "$working_data/cohorts2K2K`s'K"
	keep if _merge == 3
	drop _merge

	// regression
	quietly reghdfe ln_fg_sel3_total_payments ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_id#time_since_grad_id#year) vce(cluster Cohort_ID)
	
	eststo Spread_`s'000
	
	unique original_cohort if e(sample) == 1
	local n_`s' `r(unique)'
	
	unique npi year if original_cohort != 0 & e(sample) == 1
	local o_`s' `r(unique)'
}

coefplot Spread_*, vertical yline(0) keep(ln_tuition_bill) note("Number of Cohorts (Tuition Spread):" "`n_5' ($5K), `n_6' ($6K), `n_7' ($7K), `n_8' ($8K), `n_9' ($9K), `n_10' ($10K), `n_11' ($11K), `n_12' ($12K)" "Doctor-Year Observations (Tuition Spread):" "`o_5' ($5K), `o_6' ($6K), `o_7' ($7K), `o_8' ($8K), `o_9' ($9K), `o_10' ($10K), `o_11' ($11K), `o_12' ($12K)" "Cohort-Year FE, HRR-Year FE, Specialization-Career-Year FE" "SE Clustered at the Cohort Level") ytitle("Tuition Bill Coefficient (logs)" " ")
graph export "$figures/inc_lntuitionbill_cms_pymt_cidcluster2k2k.png", replace


eststo clear

* total cms e/m billing *
forvalues s = 5(1)12{
	use "$working_data/panels/cms-panel", clear
	g time_since_grad_id = year - grad_year
	encode phySpec, g(phySpec_id)

	// log of relevant variables
	g ln_fg_sel3_total_payments = ln(fg_sel3_total_payments)
	g ln_fg_sel5_total_payments = ln(fg_sel5_total_payments)
	// merge on doctor data 
	merge m:1 med_school grad_year using "$working_data/cohorts2K2K`s'K"
	keep if _merge == 3
	drop _merge

	// regression
	quietly reghdfe ln_fg_sel5_total_payments ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_id#time_since_grad_id#year) vce(cluster Cohort_ID)
	
	eststo Spread_`s'000
	
	unique original_cohort if e(sample) == 1
	local n_`s' `r(unique)'
	
	unique npi year if original_cohort != 0 & e(sample) == 1
	local o_`s' `r(unique)'
}

coefplot Spread_*, vertical yline(0) keep(ln_tuition_bill) note("Number of Cohorts (Tuition Spread):" "`n_5' ($5K), `n_6' ($6K), `n_7' ($7K), `n_8' ($8K), `n_9' ($9K), `n_10' ($10K), `n_11' ($11K), `n_12' ($12K)" "Doctor-Year Observations (Tuition Spread):" "`o_5' ($5K), `o_6' ($6K), `o_7' ($7K), `o_8' ($8K), `o_9' ($9K), `o_10' ($10K), `o_11' ($11K), `o_12' ($12K)" "Cohort-Year FE, HRR-Year FE, Specialization-Career-Year FE" "SE Clustered at the Cohort Level") ytitle("Tuition Bill Coefficient (logs)" " ")

graph export "$figures/inc_lntuitionbill_cms_em_cidcluster2k2k.png", replace


* CLUSTERING AT MED SCHOOL LEVEL *
* total cms billing *
forvalues s = 5(1)12{
	use "$working_data/panels/cms-panel", clear
	g time_since_grad_id = year - grad_year
	encode phySpec, g(phySpec_id)

	// log of relevant variables
	g ln_fg_sel3_total_payments = ln(fg_sel3_total_payments)
	g ln_fg_sel5_total_payments = ln(fg_sel5_total_payments)
	// merge on doctor data 
	merge m:1 med_school grad_year using "$working_data/cohorts2K2K`s'K"
	keep if _merge == 3
	drop _merge

	// regression
	quietly reghdfe ln_fg_sel3_total_payments ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_id#time_since_grad_id#year) vce(cluster med_school)
	
	eststo Spread_`s'000
	
	unique original_cohort if e(sample) == 1
	local n_`s' `r(unique)'
	
	unique npi year if original_cohort != 0 & e(sample) == 1
	local o_`s' `r(unique)'
}

coefplot Spread_*, vertical yline(0) keep(ln_tuition_bill) note("Number of Cohorts (Tuition Spread):" "`n_5' ($5K), `n_6' ($6K), `n_7' ($7K), `n_8' ($8K), `n_9' ($9K), `n_10' ($10K), `n_11' ($11K), `n_12' ($12K)" "Doctor-Year Observations (Tuition Spread):" "`o_5' ($5K), `o_6' ($6K), `o_7' ($7K), `o_8' ($8K), `o_9' ($9K), `o_10' ($10K), `o_11' ($11K), `o_12' ($12K)" "Cohort-Year FE, HRR-Year FE, Specialization-Career-Year FE" "SE Clustered at the Med School Level") ytitle("Tuition Bill Coefficient (logs)" " ")

graph export "$figures/inc_lntuitionbill_cms_pymt_mscluster2k2k.png", replace


eststo clear

* total cms e/m billing *
forvalues s = 5(1)12{
	use "$working_data/panels/cms-panel", clear
	g time_since_grad_id = year - grad_year
	encode phySpec, g(phySpec_id)

	// log of relevant variables
	g ln_fg_sel3_total_payments = ln(fg_sel3_total_payments)
	g ln_fg_sel5_total_payments = ln(fg_sel5_total_payments)
	// merge on doctor data 
	merge m:1 med_school grad_year using "$working_data/cohorts2K2K`s'K"
	keep if _merge == 3
	drop _merge

	// regression
	quietly reghdfe ln_fg_sel5_total_payments ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_id#time_since_grad_id#year) vce(cluster med_school)
	
	eststo Spread_`s'000
	
	unique original_cohort if e(sample) == 1
	local n_`s' `r(unique)'
	
	unique npi year if original_cohort != 0 & e(sample) == 1
	local o_`s' `r(unique)'
}

coefplot Spread_*, vertical yline(0) keep(ln_tuition_bill) note("Number of Cohorts (Tuition Spread):" "`n_5' ($5K), `n_6' ($6K), `n_7' ($7K), `n_8' ($8K), `n_9' ($9K), `n_10' ($10K), `n_11' ($11K), `n_12' ($12K)" "Doctor-Year Observations (Tuition Spread):" "`o_5' ($5K), `o_6' ($6K), `o_7' ($7K), `o_8' ($8K), `o_9' ($9K), `o_10' ($10K), `o_11' ($11K), `o_12' ($12K)" "Cohort-Year FE, HRR-Year FE, Specialization-Career-Year FE" "SE Clustered at the Med School Level") ytitle("Tuition Bill Coefficient (logs)" " ") 

graph export "$figures/inc_lntuitionbill_cms_em_mscluster2k2k.png", replace

**# 2K 2K 5K-12K COL 3 

* CLUSTERING AT COHORT LEVEL *

* total cms billing *
forvalues s = 5(1)12{
	use "$working_data/panels/cms-panel", clear
	g time_since_grad_id = year - grad_year
	encode phySpec, g(phySpec_id)

	// log of relevant variables
	g ln_fg_sel3_total_payments = ln(fg_sel3_total_payments)
	g ln_fg_sel5_total_payments = ln(fg_sel5_total_payments)
	// merge on doctor data 
	merge m:1 med_school grad_year using "$working_data/cohorts2K2K`s'K"
	keep if _merge == 3
	drop _merge

	// regression
	quietly reghdfe ln_fg_sel3_total_payments ln_tuition_bill, a(Cohort_ID#year hrr#year time_since_grad_id#year) vce(cluster Cohort_ID)
	
	eststo Spread_`s'000
	
	unique original_cohort if e(sample) == 1
	local n_`s' `r(unique)'
	
	unique npi year if original_cohort != 0 & e(sample) == 1
	local o_`s' `r(unique)'
}

coefplot Spread_*, vertical yline(0) keep(ln_tuition_bill) note("Number of Cohorts (Tuition Spread):" "`n_5' ($5K), `n_6' ($6K), `n_7' ($7K), `n_8' ($8K), `n_9' ($9K), `n_10' ($10K), `n_11' ($11K), `n_12' ($12K)" "Doctor-Year Observations (Tuition Spread):" "`o_5' ($5K), `o_6' ($6K), `o_7' ($7K), `o_8' ($8K), `o_9' ($9K), `o_10' ($10K), `o_11' ($11K), `o_12' ($12K)" "Cohort-Year FE, HRR-Year FE, Career-Year FE" "SE Clustered at the Cohort Level") ytitle("Tuition Bill Coefficient (logs)" " ")
graph export "$figures/inc_lntuitionbill_cms_pymt_cidcluster2k2k_col3.png", replace


eststo clear

* total cms e/m billing *
forvalues s = 5(1)12{
	use "$working_data/panels/cms-panel", clear
	g time_since_grad_id = year - grad_year
	encode phySpec, g(phySpec_id)

	// log of relevant variables
	g ln_fg_sel3_total_payments = ln(fg_sel3_total_payments)
	g ln_fg_sel5_total_payments = ln(fg_sel5_total_payments)
	// merge on doctor data 
	merge m:1 med_school grad_year using "$working_data/cohorts2K2K`s'K"
	keep if _merge == 3
	drop _merge

	// regression
	quietly reghdfe ln_fg_sel5_total_payments ln_tuition_bill, a(Cohort_ID#year hrr#year time_since_grad_id#year) vce(cluster Cohort_ID)
	
	eststo Spread_`s'000
	
	unique original_cohort if e(sample) == 1
	local n_`s' `r(unique)'
	
	unique npi year if original_cohort != 0 & e(sample) == 1
	local o_`s' `r(unique)'
}

coefplot Spread_*, vertical yline(0) keep(ln_tuition_bill) note("Number of Cohorts (Tuition Spread):" "`n_5' ($5K), `n_6' ($6K), `n_7' ($7K), `n_8' ($8K), `n_9' ($9K), `n_10' ($10K), `n_11' ($11K), `n_12' ($12K)" "Doctor-Year Observations (Tuition Spread):" "`o_5' ($5K), `o_6' ($6K), `o_7' ($7K), `o_8' ($8K), `o_9' ($9K), `o_10' ($10K), `o_11' ($11K), `o_12' ($12K)" "Cohort-Year FE, HRR-Year FE, Career-Year FE" "SE Clustered at the Cohort Level") ytitle("Tuition Bill Coefficient (logs)" " ")

graph export "$figures/inc_lntuitionbill_cms_em_cidcluster2k2k_col3.png", replace


**# 1K 1K 4K-10K COL 5

* clean cohort_id data, export as dta for merges *
forvalues s = 4(1)10{
	import excel "$dropbox/Claude Work to Identify Cohorts/cms-aamc-allmedschoolyears-with-all-cohort-scenarios.xlsx", sheet("1K 1K `s'K") cellrange(A1:I2866) firstrow clear
	rename npi npi_count
	g original_cohort = Cohort_ID
	recast int Cohort_ID

	// replace Cohort_ID == 0 with sequential ID's
	summarize Cohort_ID
	local max_id = r(max)
	generate temp_counter = sum(Cohort_ID == 0)
	replace Cohort_ID = `max_id' + temp_counter if Cohort_ID == 0
	drop temp_counter
	
	destring tuition, replace
	g ln_tuition = ln(tuition)
	g ln_tuition_bill = ln(tuition_bill)
	
	label variable ln_tuition_bill "Tuition Bill (logs)"
	
	save "$working_data/cohorts1K1K`s'K", replace
}

* CLUSTERING AT COHORT LEVEL *

* total cms billing *
forvalues s = 4(1)10{
	use "$working_data/panels/cms-panel", clear
	g time_since_grad_id = year - grad_year
	encode phySpec, g(phySpec_id)

	// log of relevant variables
	g ln_fg_sel3_total_payments = ln(fg_sel3_total_payments)
	g ln_fg_sel5_total_payments = ln(fg_sel5_total_payments)
	// merge on doctor data 
	merge m:1 med_school grad_year using "$working_data/cohorts1K1K`s'K"
	keep if _merge == 3
	drop _merge

	// regression
	quietly reghdfe ln_fg_sel3_total_payments ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_id#time_since_grad_id#year) vce(cluster Cohort_ID)
	
	eststo Spread_`s'000
	
	unique original_cohort if e(sample) == 1
	local n_`s' `r(unique)'
	
	unique npi year if original_cohort != 0 & e(sample) == 1
	local o_`s' `r(unique)'
}

coefplot Spread_*, vertical yline(0) keep(ln_tuition_bill) note("Number of Cohorts (Tuition Spread):" "`n_4' ($4K), `n_5' ($5K), `n_6' ($6K), `n_7' ($7K), `n_8' ($8K), `n_9' ($9K), `n_10' ($10K)" "Doctor-Year Observations (Tuition Spread):" "`o_4' ($4K), `o_5' ($5K), `o_6' ($6K), `o_7' ($7K), `o_8' ($8K), `o_9' ($9K), `o_10' ($10K)" "Cohort-Year FE, HRR-Year FE, Specialization-Career-Year FE" "SE Clustered at the Cohort Level") ytitle("Tuition Bill Coefficient (logs)" " ")
graph export "$figures/inc_lntuitionbill_cms_pymt_cidcluster1k1k.png", replace


eststo clear

* total cms e/m billing *
forvalues s = 4(1)10{
	use "$working_data/panels/cms-panel", clear
	g time_since_grad_id = year - grad_year
	encode phySpec, g(phySpec_id)

	// log of relevant variables
	g ln_fg_sel3_total_payments = ln(fg_sel3_total_payments)
	g ln_fg_sel5_total_payments = ln(fg_sel5_total_payments)
	// merge on doctor data 
	merge m:1 med_school grad_year using "$working_data/cohorts1K1K`s'K"
	keep if _merge == 3
	drop _merge

	// regression
	quietly reghdfe ln_fg_sel5_total_payments ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_id#time_since_grad_id#year) vce(cluster Cohort_ID)
	
	eststo Spread_`s'000
	
	unique original_cohort if e(sample) == 1
	local n_`s' `r(unique)'
	
	unique npi year if original_cohort != 0 & e(sample) == 1
	local o_`s' `r(unique)'
}

coefplot Spread_*, vertical yline(0) keep(ln_tuition_bill) note("Number of Cohorts (Tuition Spread):" "`n_4' ($4K), `n_5' ($5K), `n_6' ($6K), `n_7' ($7K), `n_8' ($8K), `n_9' ($9K), `n_10' ($10K)" "Doctor-Year Observations (Tuition Spread):" "`o_4' ($4K), `o_5' ($5K), `o_6' ($6K), `o_7' ($7K), `o_8' ($8K), `o_9' ($9K), `o_10' ($10K)" "Cohort-Year FE, HRR-Year FE, Specialization-Career-Year FE" "SE Clustered at the Cohort Level") ytitle("Tuition Bill Coefficient (logs)" " ")

graph export "$figures/inc_lntuitionbill_cms_em_cidcluster1k1k.png", replace


* CLUSTERING AT MED SCHOOL LEVEL *
* total cms billing *
forvalues s = 4(1)10{
	use "$working_data/panels/cms-panel", clear
	g time_since_grad_id = year - grad_year
	encode phySpec, g(phySpec_id)

	// log of relevant variables
	g ln_fg_sel3_total_payments = ln(fg_sel3_total_payments)
	g ln_fg_sel5_total_payments = ln(fg_sel5_total_payments)
	// merge on doctor data 
	merge m:1 med_school grad_year using "$working_data/cohorts1K1K`s'K"
	keep if _merge == 3
	drop _merge

	// regression
	quietly reghdfe ln_fg_sel3_total_payments ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_id#time_since_grad_id#year) vce(cluster med_school)
	
	eststo Spread_`s'000
	
	unique original_cohort if e(sample) == 1
	local n_`s' `r(unique)'
	
	unique npi year if original_cohort != 0 & e(sample) == 1
	local o_`s' `r(unique)'
}

coefplot Spread_*, vertical yline(0) keep(ln_tuition_bill) note("Number of Cohorts (Tuition Spread):" "`n_4' ($4K), `n_5' ($5K), `n_6' ($6K), `n_7' ($7K), `n_8' ($8K), `n_9' ($9K), `n_10' ($10K)" "Doctor-Year Observations (Tuition Spread):" "`o_4' ($4K), `o_5' ($5K), `o_6' ($6K), `o_7' ($7K), `o_8' ($8K), `o_9' ($9K), `o_10' ($10K)" "Cohort-Year FE, HRR-Year FE, Specialization-Career-Year FE" "SE Clustered at the Med School Level") ytitle("Tuition Bill Coefficient (logs)" " ")

graph export "$figures/inc_lntuitionbill_cms_pymt_mscluster1k1k.png", replace


eststo clear

* total cms e/m billing *
forvalues s = 4(1)10{
	use "$working_data/panels/cms-panel", clear
	g time_since_grad_id = year - grad_year
	encode phySpec, g(phySpec_id)

	// log of relevant variables
	g ln_fg_sel3_total_payments = ln(fg_sel3_total_payments)
	g ln_fg_sel5_total_payments = ln(fg_sel5_total_payments)
	// merge on doctor data 
	merge m:1 med_school grad_year using "$working_data/cohorts1K1K`s'K"
	keep if _merge == 3
	drop _merge

	// regression
	quietly reghdfe ln_fg_sel5_total_payments ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_id#time_since_grad_id#year) vce(cluster med_school)
	
	eststo Spread_`s'000
	
	unique original_cohort if e(sample) == 1
	local n_`s' `r(unique)'
	
	unique npi year if original_cohort != 0 & e(sample) == 1
	local o_`s' `r(unique)'
}

coefplot Spread_*, vertical yline(0) keep(ln_tuition_bill) note("Number of Cohorts (Tuition Spread):" "`n_4' ($4K), `n_5' ($5K), `n_6' ($6K), `n_7' ($7K), `n_8' ($8K), `n_9' ($9K), `n_10' ($10K)" "Doctor-Year Observations (Tuition Spread):" "`o_4' ($4K), `o_5' ($5K), `o_6' ($6K), `o_7' ($7K), `o_8' ($8K), `o_9' ($9K), `o_10' ($10K)" "Cohort-Year FE, HRR-Year FE, Specialization-Career-Year FE" "SE Clustered at the Med School Level") ytitle("Tuition Bill Coefficient (logs)" " ") 

graph export "$figures/inc_lntuitionbill_cms_em_mscluster1k1k.png", replace
