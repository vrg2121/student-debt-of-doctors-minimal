*******************************************************************
*** CREATE YEARLY DOCTOR CMS OUTCOMES FOR E/M AND NON-E/M CODES ***
*******************************************************************

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
	
	drop if npi == 1
	
	bys npi (ent_cd) : assert ent_cd[1] == ent_cd[_N]
	
	* Drug indicator:
	g isDrug = hcpcs_drug_ind == "Y"
	
	* EM indicator:
	merge m:1 hcpcs using "$working_data/temp/hcpcs-isEM"
	drop if _merge == 2
	drop _merge
	replace isEM = "." if isEM == ""
	destring isEM, replace
	
	* Compute total amount paid per row and adjust scale:
	replace avg_mdcr_pymt_amt = avg_mdcr_pymt_amt / 1000
	
	gen all_total_payments = amount_services * avg_mdcr_pymt_amt

	* Compute total amount paid per HCPCS code and doctor:
	collapse (sum) all_total_payments amount_services (max) isDrug, by(npi isEM)

	
	save "$working_data/temp/all_total_payments-em-grps-20`n'", replace
	
}

* Put files together:
clear
forvalues n = 12/19 {
	
	append using "$working_data/temp/all_total_payments-em-grps-20`n'"
	
}

	
* Inflation adjustment:
inflationAdjust all_total_payments year
	

save "$working_data/tempall_total_payments-em-grps", replace