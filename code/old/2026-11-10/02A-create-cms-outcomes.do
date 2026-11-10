
**********************************************************
*** PREPARE FOR CREATION OF YEARLY DOCTOR CMS OUTCOMES ***
**********************************************************

* Description of this do-file:

* 	Translates FG's 2012 CMS data to same variables names etc as in our downloaded 2013-2019 data
*	Creates auxiliary files which will be used to calculate yearly CMS payments

**********************************************************
**********************************************************
**********************************************************



********************************
*** TRANSLATE FG's 2012 DATA ***
********************************

* We have downloaded CMS data from 2013-2019
* In FG's replication package they have data also for 2012
* We want to use also their data
* Therefore, we translate FG's 2012 data to have the same variables as our other files:

import delimited ///
	"$fang_gong_replication/input/Medicare_Provider_Util_Payment_PUF_CY2012.txt", ///
	clear
	
rename hcpcs_code 					hcpcs_cd
rename hcpcs_description 			hcpcs_desc
rename hcpcs_drug_indicator 		hcpcs_drug_ind
rename place_of_service 			place_of_srvc
rename npi 							rndrng_npi
rename line_srvc_cnt 				tot_srvcs
rename average_medicare_payment_amt avg_mdcr_pymt_amt

order ///
	rndrng_npi              		 ///  1
	nppes_provider_last_org_name 	 ///  2
	nppes_provider_first_name 		 ///  3
	nppes_provider_mi 				 ///  4
	nppes_credentials 			 	 ///  5
	nppes_provider_gender 			 ///  6
	nppes_entity_code 				 ///  7
	nppes_provider_street1 			 ///  8
	nppes_provider_street2 			 ///  9
	nppes_provider_city 			 /// 10
	nppes_provider_zip 				 /// 11
	nppes_provider_state 			 /// 12
	nppes_provider_country 			 /// 13
	provider_type 					 /// 14
	medicare_participation_indicator /// 15
	place_of_srvc 					 /// 16
	tot_srvcs 						 /// 17
	bene_unique_cnt 				 /// 18
	hcpcs_cd 						 /// 19
	hcpcs_desc 						 /// 20
	hcpcs_drug_ind					  // 21
	
export delimited ///
	"$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D12_Prov_Svc.csv", ///
	replace


***********************
*** AUXILIARY FILES ***
***********************

*** Identifying HCPCS codes in one of FG's output files ***

use "$fang_gong_replication/output/phy_serv_time", clear

keep hcpcs

duplicates drop

save "$working_data/temp/fg-hcpcs-codes", replace


*** Checking so relevant columns are always ordered the same ***

forvalues n = 12/19 {

	import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D`n'_Prov_Svc.csv", ///
		clear colrange(19:21) rowrange(1:1)
	
	ds
	
	assert "`r(varlist)'" == "hcpcs_cd hcpcs_desc hcpcs_drug_ind"
	
}


*** Identifying drugs and HCPCS codes by year ***

forvalues n = 12/19 {

	tempfile fg_`n'

	import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D`n'_Prov_Svc.csv", ///
		clear colrange(19:21) varnames(1)
	
	g year = `n'
	
	rename hcpcs_cd hcpcs
	
	g isDrug = hcpcs_drug_ind == "Y"
	
	* Identify HPPCS Level I (procedures, aka CPT) and Level II (products) codes
	destring hcpcs, generate(hcpcsGroup) force
	replace hcpcsGroup = 1 if hcpcsGroup != .
	replace hcpcsGroup = 2 if strpos(hcpcs, "F") == 5
	replace hcpcsGroup = 3 if strpos(hcpcs, "T") == 5
	replace hcpcsGroup = 0 if hcpcsGroup == .
	
	keep if isDrug == 0 & hcpcsGroup == 1
	
	keep hcpcs year
	
	save `fg_`n''
	
}

clear
forvalues n = 12/19 {

	append using `fg_`n''
	
}

sort hcpcs year
duplicates drop hcpcs, force // from FG

save "$working_data/temp/fg_selection_appended_hcpcs_code", replace


*** Identifying EM codes ***

import delimited "$fang_gong_replication/input/hcpcslist_timed_with_min.csv", clear

keep hcpcs isem hcpcsdesc

rename isem isEM

tostring hcpcs, replace

encode hcpcsdesc, gen(hcpcsgroup)

save "$working_data/temp/hcpcs-isEM", replace


