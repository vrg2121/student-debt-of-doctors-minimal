
*****************************************
*** CREATE YEARLY DOCTOR CMS OUTCOMES ***
*****************************************

* Description of this do-file:

* 	Calculates different versions of yearly total CMS payments to doctors
* 	Calculates average CMS payments to doctors within certain HCPCS codes (the E/M codes)
* 	Calculates the number of total and unique HCPCS codes used by a doctor per year

*****************************************
*****************************************
*****************************************



*****************************
*** YEARLY TOTAL PAYMENTS ***
*****************************

forvalues n = 12/19 {

	import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D`n'_Prov_Svc.csv", clear

	rename rndrng_npi npi
	rename hcpcs_cd   hcpcs
	rename tot_srvcs  amount_services

	cap rename nppes_entity_code   ent_cd
	cap rename rndrng_prvdr_ent_cd ent_cd
	
	confirm var ent_cd
	
	bys npi (ent_cd) : assert ent_cd[1] == ent_cd[_N]
	
	* Drug indicator:
	g isDrug = hcpcs_drug_ind == "Y"
	
	* Compute total amount paid per row and adjust scale:
	gen all_total_payments = amount_services * avg_mdcr_pymt_amt / 1000

	* Compute total amount paid per HCPCS code and doctor:
	collapse (sum) all_total_payments (max) isDrug (first) ent_cd, by(npi hcpcs)

	*** EMIEL BETOS ***
	
	* BETOS is wider categories of HCPCS codes
	* In one of Emiel's old implementations, choose certain BETOS codes to be included in the calculation
	* That's what we recreate here:
	
	merge m:1 hcpcs using "$dropbox/FullData/RawData/BETOS2", keepusing(rbcs_cat_subcat)
	drop if _merge == 2
	drop    _merge
	
	* Assign value when BETOS is in Emiel's list:
	g emiel_betos_total_payments = .
	foreach betos of global emiel_betos {
		replace emiel_betos_total_payments = all_total_payments if rbcs_cat_subcat == "`betos'"
	}
	
	drop rbcs_cat_subcat
	
	*** FG ***
	
	* FG's HCPCS codes:
	merge m:1 hcpcs using "$working_data/temp/fg-hcpcs-codes"
	drop if          _merge == 2
	g fg_included =  _merge == 3 // for restriction
	drop             _merge

	* Exclude non-matched from FG payments variable:
	g fg_hcpcs_total_payments = all_total_payments if fg_included == 1
	
	* Large percentage of the data is excluded by FG:
// 	tab fg_included, m

	* The following HCPCS subcodes are excluded by FG:
// 	tab hcpcs if fg_included == 0, m
	
	*** FG SELECTIONS ***
	
	* Identify HPPCS Level I (procedures, aka CPT) and Level II (products) codes
	destring hcpcs, generate(hcpcsGroup) force
	replace hcpcsGroup = 1 if hcpcsGroup != .
	replace hcpcsGroup = 2 if strpos(hcpcs, "F") == 5
	replace hcpcsGroup = 3 if strpos(hcpcs, "T") == 5
	replace hcpcsGroup = 0 if hcpcsGroup == .
	
	g fg_sel1_total_payments = all_total_payments if hcpcsGroup == 1
	g fg_sel2_total_payments = all_total_payments if 				   isDrug == 0
	g fg_sel3_total_payments = all_total_payments if hcpcsGroup == 1 & isDrug == 0 // MAIN OUTCOME!

	merge m:1 hcpcs using "$working_data/temp/fg_selection_appended_hcpcs_code", keepusing(hcpcs)
	
	g fg_sel4_total_payments = all_total_payments if _merge == 3
	
	drop _merge
	
	* Merging on isEM:
	merge m:1 hcpcs using "$working_data/temp/hcpcs-isEM"
	drop if _merge == 2
	drop    _merge

	replace isEM = isEM == 1
	
	g fg_sel5_total_payments = all_total_payments if isEM == 1
	
	* Recall:
	* 	        all_total_payments = includes everything
	* 	emiel_betos_total_payments = includes Emiel's BETOS codes
	* 	   fg_hcpcs_total_payments = includes FG's HCPCS codes
	* 	    fg_seln_total_payments = different versions where we've used FG's data selection code
	
	* Preparing to take care of missings (i.e. when doctor doesn't use relevant codes at all):
	foreach var of global payment_vars {
	
		bys npi (`var'_total_payments) : g `var'_missing = ///
			`var'_total_payments[1]  == . & ///
			`var'_total_payments[_N] == .
	
	}
	
	* Collapse payments by npi:
	collapse (sum) *_total_payments (first) *_missing ent_cd, by(npi)

	* Taking care of missings:
	foreach var of global payment_vars {
	
		assert  `var'_total_payments == 0 if `var'_missing == 1
		replace `var'_total_payments =  . if `var'_missing == 1
	
	}
	
	drop *_missing
	
	g year = 2000 + `n'
	
	save "$working_data/temp/emiel-total_payments-fg-hcpcs-codes-20`n'", replace
	
}

* Put files together:
clear
forvalues n = 12/19 {
	
	append using "$working_data/temp/emiel-total_payments-fg-hcpcs-codes-20`n'"
	
}

replace ent_cd = "MISSING" if ent_cd == ""

foreach var of global payment_vars {
	
	* Inflation adjustment:
	inflationAdjust `var'_total_payments year
	
}

save "$working_data/temp/emiel-total_payments-fg-hcpcs-codes", replace


***************************************************************
*** YEARLY AVERAGE PAYMENTS PER HCPCS – ONLY FOR E/M CODES ***
***************************************************************

* Only for E/M codes currently for computational reasons (bad implementation by Simon)

forvalues n = 12/19 {

	import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D`n'_Prov_Svc.csv", ///
		clear

	rename rndrng_npi npi
	rename hcpcs_cd   hcpcs

	* Merging on isEM:
	merge m:1 hcpcs using "$working_data/temp/hcpcs-isEM"
	drop if _merge == 2
	drop    _merge

	keep if isEM == 1
	
	assert hcpcs != ""
	
	replace avg_mdcr_pymt_amt = avg_mdcr_pymt_amt / 1000
	
	collapse (mean) avg_mdcr_pymt_amt, by(npi hcpcs)
	
	g year = 2000 + `n'
	
	reshape wide avg_mdcr_pymt_amt, i(npi) j(hcpcs) string
	
	order year, after(npi)
	
	save "$working_data/temp/em-average-payments-`n'", replace
	
}

* Put files together:
clear
forvalues n = 12/19 {
	
	append using "$working_data/temp/em-average-payments-`n'"
	
}

ds avg_mdcr_pymt_amt*
foreach var in `r(varlist)' {
	
	* Inflation adjustment:
	inflationAdjust `var' year
	
}

save "$working_data/temp/em-average-payments", replace


****************************************************
*** TOTAL NUMBER OF SERVICES AND UNIQUE SERVICES ***
****************************************************

forvalues n = 12/19 {

	import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D`n'_Prov_Svc.csv", clear

	g year = 2000 + `n'
	
	drop if place_of_srvc == "" // Probably from FG

	rename rndrng_npi npi
	rename hcpcs_cd   hcpcs
	
	* Drug indicator:
	g isDrug = hcpcs_drug_ind == "Y"
	
	* Identify HPPCS Level I (procedures, aka CPT) and Level II (products) codes
	destring hcpcs, generate(hcpcsGroup) force
	replace hcpcsGroup = 1 if hcpcsGroup != .
	replace hcpcsGroup = 2 if strpos(hcpcs, "F") == 5
	replace hcpcsGroup = 3 if strpos(hcpcs, "T") == 5
	replace hcpcsGroup = 0 if hcpcsGroup == .
	
	g fg_sel3 = hcpcsGroup == 1 & isDrug == 0
	
	keep npi year hcpcs tot_srvcs fg_sel3
	
	save "$working_data/temp/nServ-20`n'-new", replace
	
}

clear
forvalues n = 12/19 {
	append using "$working_data/temp/nServ-20`n'-new"
}

* Merging on isEM:
merge m:1 hcpcs using "$working_data/temp/hcpcs-isEM"
drop if _merge == 2
drop    _merge

g fg_sel5 = isEM == 1

drop isEM

rename tot_srvcs nServ

* To be sure if we get big numbers etc (not strictly necessary):
recast double nServ

assert nServ != .

* Marking if code is used by doctor in year:
g nCode = nServ > 0

* For restricted categories:
foreach n in 3 5 { // 3 is our ordinary selection and 5 is EM
	
	* Below will be either:
	*	1 * number = number, or
	*	0 * number = 0
	
	* Total number of services:
	g double fg_sel`n'_nServ = fg_sel`n' * nServ
	
	* Marking if code is used by doctor in year:
	g double fg_sel`n'_nCode = fg_sel`n' * nCode
	
}

collapse (sum) *nServ *nCode, by(npi year)

save "$working_data/temp/nCodes-new", replace
