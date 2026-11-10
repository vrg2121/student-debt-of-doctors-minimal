****************************************
*** AGGREGATE DATA TO NPI-YEAR LEVEL ***
****************************************

clear

global npi_invariant ///
		year phySpec* cred isMD  ///
		gy_cnt ms_cnt mult_grad_year mult_med_school grad_year med_school ///
		mdcr_participant zip5 groupPAC event_time hrr ///
		aca_year tuition PublicSchool source nominal_tuition med_school_chrono ///
		delta_nominal_tuition nominal_tuition_bill delta_tuition tuition_bill Tuition_quantile
		
global to_sum ///
		nServ hcpcs_tot_pymt hcpcs_tot_stdzd_pymt fg_sel1_* fg_sel2_* fg_sel3_* fg_sel4_* fg_sel5_*

forvalues n = 12/19 {
		
	use "$working_data/panels/aamc_cms_20`n'", clear

	// generate outcome variables	
	foreach o of varlist fg_sel1 fg_sel2 fg_sel3 fg_sel4 fg_sel5 {
		g `o'_total_payments = `o' * hcpcs_tot_pymt
		g `o'_stdzd_tot_pymts = `o' * hcpcs_tot_stdzd_pymt
		g `o'_nServ = `o' * nServ
		g `o'_betos_pymt = `o' * betos_hcpcs_pymt
	}


	// aggregate to facility level
	collapse (first) $npi_invariant (sum) $to_sum, by(npi place_of_srvc)

	preserve

	keep npi place_of_srvc $to_sum

	reshape wide $to_sum, i(npi) j(place_of_srvc) string

	foreach var of varlist nServ*O hcpcs*O fg*O {
		local base = subinstr("`var'", "O", "", .)
		
		// carry over missing data into %
		replace `base'O = . if `base'O == 0 
		replace `base'F = . if `base'F == 0
		
		egen tot_`base' = rowtotal(`base'O `base'F)
		gen pct_`base'_O = (`base'O / tot_`base') * 100
		gen pct_`base'_F = (`base'F / tot_`base') * 100
		
		replace pct_`base'_O = 0 if tot_`base' == 0
		replace pct_`base'_F = 0 if tot_`base' == 0 
		
		replace pct_`base'_O = 100 if pct_`base'_O >= 99.99 & pct_`base'_F == .
		replace pct_`base'_F = 100 if pct_`base'_F >= 99.99 & pct_`base'_O == .
		
		// carry over missing data
		replace pct_`base'_O = 0 if pct_`base'_O == . & pct_`base'_F == 100
		replace pct_`base'_F = 0 if pct_`base'_F == . & pct_`base'_O == 100
		
		replace pct_`base'_O = 0 if `base'O == . & `base'F == .
		replace pct_`base'_F = 0 if `base'O == . & `base'F == .
	}

	keep npi pct_*

	tempfile facility_pct
	save `facility_pct'

	restore

	collapse (first) $npi_invariant (sum) $to_sum, by(npi)
	
	// carry over fraction of billing by facility category

	merge 1:1 npi using `facility_pct'
	drop _merge
	
	rename hcpcs_tot_pymt total_payments
	rename hcpcs_tot_stdzd_pymt total_standardized_payments
	save "$working_data/temp/aamc_cms_npi_20`n'", replace
}

use "$working_data/temp/aamc_cms_npi_2012", clear

forvalues n = 13/19 {
	append using "$working_data/temp/aamc_cms_npi_20`n'"
}

sort npi year

// clean phySpec 

do "$do/clean-phySpec.do"

encode(phySpec), g(phySpec_id)

save "$working_data/panels/aamc_cms_npi_year", replace