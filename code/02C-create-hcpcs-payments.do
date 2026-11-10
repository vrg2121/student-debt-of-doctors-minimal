* Yearly Total HCPCS Payments *

forvalues n = 12/19 {
	import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D`n'_Prov_Svc.csv", clear
	
	g year = 20`n'

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
	gen hcpcs_tot_pymt = amount_services * avg_mdcr_pymt_amt / 1000
	
	keep npi hcpcs hcpcs_tot_pymt year
	
	save "$working_data/temp/hcpcs-total_payments-20`n'", replace

}

clear
forvalues n = 12/19 {
	
	append using "$working_data/temp/hcpcs-total_payments-20`n'"
	
}

drop if npi == 1

inflationAdjust hcpcs_tot_pymt year

save "$working_data/temp/hcpcs-total_payments", replace

