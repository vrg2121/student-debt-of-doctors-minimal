****************************************************
*** V SCRATCH: CREATE YEARLY DOCTOR CMS OUTCOMES ***
****************************************************

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

***************************************************************
*** YEARLY AVERAGE PAYMENTS PER HCPCS – ONLY FOR E/M CODES ***
***************************************************************

* Only for E/M codes currently for computational reasons (bad implementation by Simon)

//forvalues n = 12/19 {
	
	local n = 12

	import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D`n'_Prov_Svc.csv", ///
		clear

	rename rndrng_npi npi
	rename hcpcs_cd   hcpcs
	rename tot_srvcs  nsrvcs

	* Merging on isEM:
	merge m:1 hcpcs using "$working_data/temp/hcpcs-isEM"
	drop if _merge == 2
	drop    _merge

	keep if isEM == 1
	
	assert hcpcs != ""
	
	replace avg_mdcr_pymt_amt = avg_mdcr_pymt_amt / 1000
	
	collapse (mean) avg_mdcr_pymt_amt, by(npi hcpcsgroup) // why take the mean here? why not sum the means and the nservices?
	
	g year = 2000 + `n'
	
	reshape wide avg_mdcr_pymt_amt, i(npi) j(hcpcs) string
	
	order year, after(npi)
	
	save "$working_data/temp/em-average-payments-`n'", replace
	
//}

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
