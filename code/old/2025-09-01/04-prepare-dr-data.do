
**************************************
*** PREPARE DOCTOR-LEVEL DATA SETS ***
**************************************

*** CROSSWALK: zip5-hrr ***

use "$dropbox/FullData/zip_hrr", clear

bys zip5 : assert _N == 1 // uniqueness

destring zip5, replace

bys zip5 : assert _N == 1 // uniqueness remains

save "$temp/destringed-zip5-hrr", replace


*** CMS ***

use "$dropbox/FullDataCMSPANEL_final.dta", clear

* VERY UGLY, BUT FOR NOW -- REMOVE THIS TO REPRODUCE EMIEL:
// 	rename gradYear foo
// 	rename grd_yr gradYear
// 	rename foo grd_yr

// assert grd_yr == gradYear // false, why?

assert gndr != ""

g male = gndr == "M"

replace credentials = subinstr(credentials, " ", "", .)
replace credentials = subinstr(credentials, ".", "", .)
replace credentials = subinstr(credentials, ",", "", .) ///
	if strpos(credentials, ",") == length(credentials)

g isMD = strpos(credentials, "MD") > 0

* Keep only important variables for now (code becomes slow otherwise):
keep ///
	npi ///
	year ///
	med_sch ///
	grd_yr ///
	gradYear ///
	total_payments ///
	servicesEM ///
	pri_spec ///
	zip5 ///
	state_abrvtn ///
	state_fips ///
	male ///
	isMD

// drop if grd_yr   == .
// drop if gradYear == .

// bys npi : g subsample = runiform() < 0.50 if _n == 1
//
// by  npi : replace subsample = subsample[1]
//
// keep if subsample == 1
//
// drop subsample

* Check so var is unique within npi:
foreach var in pri_spec { // zip5
	
	bys npi (`var') : assert `var'[1] == `var'[_N]
	 
}

* Merge on HRR (code for geographies):
merge m:1 zip5 using "$temp/destringed-zip5-hrr"
drop if _merge == 2
drop _merge

bys npi year : assert _N == 1

replace year = year + 2000

save "$git/data/working/FullDataCMSPANEL_final_subsample", replace


*** PROPUBLICA ***

* Key, physician id -- npi:
import delimited ///
	"$dropbox/ProRepublica/20191003-docdollars-physician_npi_crosswalk/P062819-20190912T1756-pid-npi-crosswalk 2.csv", ///
	clear
	
* False in small number of cases:
// bys npi                  : assert _N == 1
// bys physician_profile_id : assert _N == 1
	
bys npi 				 : keep if _n == 1
bys physician_profile_id : keep if _n == 1	

save "$temp/propublica-npi-pid", replace

import delimited "$dropbox/ProRepublica/20180702b-docdollars-payments.csv", clear colrange(32:32)

g double row = _n

save "$temp/propublica-docdollars-total-amount-temp", replace

import delimited "$dropbox/ProRepublica/20180702b-docdollars-payments.csv", clear colrange(59:59)

g double row = _n

save "$temp/propublica-docdollars-year-temp", replace

import delimited "$dropbox/ProRepublica/20180702b-docdollars-payments.csv", clear colrange(7:7)

g double row = _n

merge 1:1 row using "$temp/propublica-docdollars-total-amount-temp"
assert _merge == 3
drop _merge

merge 1:1 row using "$temp/propublica-docdollars-year-temp"
assert _merge == 3
drop _merge

drop row

merge m:1 physician_profile_id using "$temp/propublica-npi-pid"
keep if _merge == 3
drop _merge

drop physician_profile_id

rename program_year year

collapse (sum) total_amount_of_payment_usdollar, by(npi year)

save "$temp/propublica-docdollars-total-amount", replace

* Brand claims and beneficiaries:
forvalues n = 2013/2016 {

	cap import delimited ///
		"$dropbox/ProRepublica/rx-checkup-`n'/DOC_SUM_`n'.csv", ///
		clear
		
	cap import delimited ///
		"$dropbox/ProRepublica/rx-checkup-`n'/PartD_DOC_SUM_`n'.csv", ///
		clear

	cap import delimited ///
		"$dropbox/ProRepublica/PrescriberCheckup2016Data/DOC_SUM_`n'.csv", ///
		clear
	
	confirm variable provider_`n'_id
	
	keep provider_`n'_id brand_claim_count ben_count
	
	rename provider_`n'_id npi
	
	g year = `n'
	
	cap append using "$temp/propublica-brand-claims-beneficiaries"
	
	save "$temp/propublica-brand-claims-beneficiaries", replace
	
}


***********************************
*** DESCRIPTION OF THIS DO-FILE ***
***********************************


* We extend FG's 2012-13 data to 2013-19 using Emiel's data and run regressions
* While doing this, we also replicate various versions of Emiel's brown bag results


* This do-file is organized in the following sections:


* 	1) We create a modified total payments variable for 2013-19

* 	2) We create the nCode variables for 2013-19

*	3) We show that Simon's and Emiel's tuition dummies are similar

*	4) We run regressions: reproduce Emiel's brown bag, comparing versions, etc


*******************
*** PREPARATION ***
*******************

* Translate FG's 2012 data to our format:
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


****************************************************************
*** 1) CREATE PAYMENTS FOR 2013-19 USING HCPCS CODES FROM FG ***
****************************************************************

* Identifying HCPCS code in one of FG's output files:
use "$fang_gong_replication/output/phy_serv_time", clear

keep hcpcs

duplicates drop

save "$temp/fg-hcpcs-codes", replace


*** FOR FG SELECTION ***

* Checking so we always have the right column:
forvalues n = 12/19 {

	import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D`n'_Prov_Svc.csv", ///
		clear colrange(19:21) rowrange(1:1)
	
	ds
	
	assert "`r(varlist)'" == "hcpcs_cd hcpcs_desc hcpcs_drug_ind"
	
}

* Identifying drugs and HCPCS codes:
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

save "fg_selection_appended_hcpcs_code", replace

* Identify EM codes:
import delimited "$fang_gong_replication/input/hcpcslist_timed_with_min.csv", clear

keep hcpcs isem

rename isem isEM

tostring hcpcs, replace

save "$temp/hcpcs-isEM", replace


*** DIFFERENT VERSIONS OF PAYMENTS CALCULATIONS ***
forvalues n = 12/19 {

	* (Different implementation than Emiel's BETOS restriction because there are many HCPCS codes)

	import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D`n'_Prov_Svc.csv", clear

	rename rndrng_npi npi
	rename hcpcs_cd   hcpcs
	rename tot_srvcs  amount_services

	* Drug indicator:
	g isDrug = hcpcs_drug_ind == "Y"
	
	* Compute total amount paid per row and adjust scale:
	gen all_total_payments = amount_services * avg_mdcr_pymt_amt / 1000

	* Compute total amount paid per HCPCS code and doctor:
	collapse (sum) all_total_payments (max) isDrug, by(npi hcpcs)

	*** EMIEL BETOS ***
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
	merge m:1 hcpcs using "$temp/fg-hcpcs-codes"
	drop if          _merge == 2
	g fg_included =  _merge == 3 // for restriction
	drop             _merge

	* Exclude non-matched from FG payments variable:
	g fg_hcpcs_total_payments = all_total_payments if fg_included == 1
	
	* Large percentage of the data is excluded by FG:
	tab fg_included, m

	* The following HCPCS subcodes are excluded by FG:
	tab hcpcs if fg_included == 0, m
	
	*** FG SELECTIONS ***
	
	* Identify HPPCS Level I (procedures, aka CPT) and Level II (products) codes
	destring hcpcs, generate(hcpcsGroup) force
	replace hcpcsGroup = 1 if hcpcsGroup != .
	replace hcpcsGroup = 2 if strpos(hcpcs, "F") == 5
	replace hcpcsGroup = 3 if strpos(hcpcs, "T") == 5
	replace hcpcsGroup = 0 if hcpcsGroup == .
	
	g fg_sel1_total_payments = all_total_payments if hcpcsGroup == 1
	g fg_sel2_total_payments = all_total_payments if 				   isDrug == 0
	g fg_sel3_total_payments = all_total_payments if hcpcsGroup == 1 & isDrug == 0

	merge m:1 hcpcs using "fg_selection_appended_hcpcs_code", keepusing(hcpcs)
	
	g fg_sel4_total_payments = all_total_payments if _merge == 3
	
	drop _merge
	
	* Merging on isEM:
	merge m:1 hcpcs using "$temp/hcpcs-isEM"
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
	collapse (sum) *_total_payments (first) *_missing, by(npi)

	* Taking care of missings:
	foreach var of global payment_vars {
	
		assert  `var'_total_payments == 0 if `var'_missing == 1
		replace `var'_total_payments =  . if `var'_missing == 1
	
	}
	
	drop *_missing
	
	g year = 2000 + `n'
	
	save "$temp/emiel-total_payments-fg-hcpcs-codes-20`n'", replace
	
}

* Put files together:
clear
forvalues n = 12/19 {
	
	append using "$temp/emiel-total_payments-fg-hcpcs-codes-20`n'"
	
}

save "emiel-total_payments-fg-hcpcs-codes", replace


*********************************************
*** 2) CREATE NCODE VARIABLES FOR 2013-19 ***
*********************************************

* Create nServ data sets:
forvalues n = 12/19 {

	import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D`n'_Prov_Svc.csv", clear
	
	drop if place_of_srvc == ""
	
	g inOffice = (place_of_srvc == "O")

	rename rndrng_npi npi
	rename hcpcs_cd   hcpcs
	rename tot_srvcs  nServ_20`n'
	
	keep npi hcpcs inOffice nServ_20`n'
	
	bys npi hcpcs inOffice : assert _N == 1
	
	save "$temp/nServ-20`n'", replace
	
}

* Modified implementation from FG (since I think there is a mistake in their code, discussed below):
clear
forvalues n = 12/19 {
	append using "$temp/nServ-20`n'"
}

* Collapsing away inOffice:
collapse (sum) nServ*, by(npi hcpcs)

* Merging on isEM:
merge m:1 hcpcs using "$temp/hcpcs-isEM"
drop if _merge == 2
drop    _merge

replace isEM = isEM == 1

* Restricting to FG's HCPCS codes:
merge m:1 hcpcs using "$temp/fg-hcpcs-codes"
keep if _merge == 3
drop    _merge

bys npi hcpcs : assert _N == 1

forvalues n = 12/19 {

	* Indicator, doctor uses specific hcpcs:
	g S_nCode_20`n' = nServ_20`n' > 0
	
	* Indicator, doctor uses specific EM:
	g S_nCodeEM_20`n' = isEM * S_nCode_20`n'

}

collapse (sum) S_nCode*, by(npi)

save "$temp/nCodes", replace

* Ignore for now:

// * Comparison with FG:
// use "$fang_gong_replication/output/phy_time", clear
//
// * Merge in my nCodes:
// merge 1:1 npi using "$temp/nCodes"
// drop if _merge == 2
//
// * These fail:
//
// assert S_nCode_2013   == nCode_2013
// assert S_nCodeEM_2013 == nCodeEM_2013
//
// assert S_nCode_2013   == nCode_2013   if _merge == 3
// assert S_nCodeEM_2013 == nCodeEM_2013 if _merge == 3
//
// * Possible coding mistake in FG, for investigation:
//
// *	Compare with above code when replicating FG
// *	There, when defining isNewHcpcs_2013, look at for example:
// * 	br if npi == 1003001645 & hcpcs == "99213"
// *	There isNewHcpcs_2013 is zero for both rows which is not correct
// *	Possibly, there are other qualitatively different errors


*********************************************************
*** 3A) CHECK SO emiel_betos_total_payments == EMIEL'S ***
*********************************************************

use npi year total_payments using "$dropbox/FullDataCMSPANEL_final.dta", clear

replace year = year + 2000

merge 1:1 npi year using "emiel-total_payments-fg-hcpcs-codes", keepusing(emiel_betos_total_payments)
keep if _merge == 3
drop    _merge

replace total_payments = total_payments / 1000

* Careful with missings:
assert total_payments == 0 if emiel_betos_total_payments == .

// assert     emiel_betos_total_payments == total_payments // not true, float vs double etc
   assert abs(emiel_betos_total_payments -  total_payments) < 0.01 ///
	if emiel_betos_total_payments != .

* Conclusion: emiel_betos_total_payments is the same as Emiel's total_payments


***************************
*** 3B) CHARACTERISTICS ***
***************************

forvalues n = 2015/2017 { // skipping 2014

	import delimited ///
		"$git/data/original/cms-characteristics/extracted/raw-characteristics-`n'.csv", ///
		clear varnames(1)

	* male
	drop if gender == ""
	g byte male = gender == "M"
	drop gender

	* isMD
	rename credential phyCred
	g isMD = strpos(phyCred, "MD") > 0

	* experYear -- should maybe define using our own gradYear?
	rename graduationyear gradYear
	g experYear = `n' - gradYear + 1

	* nPhyInGroup
	rename numberofgrouppracticemembers nPhyInGroup

	* hosAff
	if (`n' == 2015) {
	
		rename claimsbasedhospitalaffiliationcc hosCCN1
		rename v30 hosCCN2
		rename v32 hosCCN3
		rename v34 hosCCN4
		rename v36 hosCCN5
		
	}
	
	if (`n' >= 2016) {
	
		rename hospitalaffiliationccn1 hosCCN1
		rename hospitalaffiliationccn2 hosCCN2
		rename hospitalaffiliationccn3 hosCCN3
		rename hospitalaffiliationccn4 hosCCN4
		rename hospitalaffiliationccn5 hosCCN5
		
	}
	
	forvalues i = 1/5 {
	// 	destring hosCCN`i', replace
		destring hosCCN`i', replace force
	}

	g hosAff = ///
		hosCCN1 != . + ///
		hosCCN2 != . + ///
		hosCCN3 != . + ///
		hosCCN4 != . + ///
		hosCCN5 != .

	* inMedicare
	rename professionalacceptsmedicareassig inMedicare_Str

	* in:
	foreach var in ERX PQRS EHR {
		
		cap rename participatingin`=lower("`var'")' in`var'_Str
		if _rc != 0 {
			g in`var'_Str = 0
		}
		
	}

	foreach var in inMedicare inERX inPQRS inEHR {

		local vartype : type `var'
		
		if (substr("`vartype'", 1, 3) == "str") {			
			g `var' = `var'_Str == "Y"
			drop      `var'_Str
		}
		else {
			rename `var'_Str `var'
		}
		
	}

	* phySpec
	rename primaryspecialty phySpec1
	egen phySpec = group(phySpec1), label
	drop phySpec1

	* groupPAC
	rename grouppracticepacid groupPAC

	* Collapse to get data by npi:
	collapse ///
		(max) male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR ///
		(first) phySpec groupPAC, ///
		by(npi)

	g year = `n'
		
	save "$temp/characteristics-`n'", replace

}

clear
forvalues n = 2015/2017 { // skipping 2014
	append using "$temp/characteristics-`n'"
	save         "$temp/characteristics", replace
	erase        "$temp/characteristics-`n'.dta"
}


***************************
*** NEW CHARACTERISTICS ***
***************************

* 2014-2017:
forvalues n = 2014/2017 {

	import delimited ///
		"$git/data/original/cms-characteristics/extracted/raw-characteristics-`n'.csv", ///
		clear varnames(1) // rowrange(1:2)

	confirm var npi graduationyear
	keep 		npi graduationyear
	rename 			graduationyear grad_year // Simon's name!
	
	g year = `n'
	
	save "$temp/minimal-chars-`n'", replace

}

* 2018-2025:
forvalues n = 2018/2025 {

	import delimited ///
		"$git/data/original/cms-characteristics/extracted/raw-characteristics-`n'.csv", ///
		clear varnames(1) // rowrange(1:2)

	confirm var npi grd_yr
	keep 		npi grd_yr
	rename 			grd_yr grad_year
	
	g year = `n'
	
	save "$temp/minimal-chars-`n'", replace
	
}

* Put the files together:
clear
forvalues n = 2014/2025 {

	append using "$temp/minimal-chars-`n'"
	
}

* 69,291 contradictions in 2,106,293 by-groups:
// bys npi (year) : assert grad_year[1] == grad_year[_N]

* Keep last updated entry:
bys npi (year) : keep if _n == _N

rename year cms_source_year

order npi cms_source_year grad_year

save "$temp/cms-graduation-years", replace



