
*************
*** PATHS ***
*************

* ONLY PATH YOU NEED TO CHANGE TO RUN THIS DO-FILE:

// global dropbox ///
// 	"/Users/simonalmerstromprzybyl/new-dropbox/Dropbox/Student Debt of Doctors"
//
// * DON'T CHANGE, JUST RUN THESE:
//
// global fang_gong_replication ///
// 	"$dropbox/Tuition Data/Fang & Gong (AER 2017) – Replication package/119565-V1"
//
// global git ///
// 	"$dropbox/Tuition Data/simon/student-debt-of-doctors"
//
// global temp ///
// 	"$git/data/working/temp"
//
//
// cd "$temp"

cap log close
log using "$temp/2025-04-28-results.smcl", replace


**********************************
*** EXPORT OF SCHOOLS TO EMIEL ***
**********************************

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

bys our_med_school : keep if _n == 1

keep our_med_school med_school source

save "$temp/schools_in_sample", replace


*********************************************
*** EXPORT SCHOOLS WITH INCREASE TO EMIEL ***
*********************************************

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

assert start_yr == (grd_yr - ($med_school_length - 1))

keep if delta_tuition_dummy == 1

bys med_school start_yr grade : keep if _n == 1

keep med_school start_yr grade source

g increase_year = start_yr + (grade - 1)

bys med_school increase_year : keep if _n == 1

keep  med_school increase_year source
order med_school increase_year source

save "$temp/5000_increase_schools_in_sample", replace


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

* Identify EM codes:
import delimited "$fang_gong_replication/input/hcpcslist_timed_with_min.csv", clear

keep hcpcs isem

rename isem isEM

tostring hcpcs, replace

save "$temp/hcpcs-isEM", replace

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


*********************************************
*** 3) COMPARE SIMON'S DUMMY WITH EMIEL'S ***
*********************************************

use "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", clear

recode dum_tuition2kincrease (. = 0)

decode medSchool, generate(med_school_emiel)

replace med_school_emiel = lower(med_school_emiel)

keep npi dum_tuition2kincrease med_school_emiel

merge 1:m npi using "$git/data/working/FullDataCMSPANEL_final_subsample_tuition"
keep if _merge == 3
drop _merge

local relevant_vars       ///
	delta_tuition_dummy   ///
	dum_tuition2kincrease ///
	med_school            ///
	med_school_emiel

* Check so var is unique within npi:
foreach var of local relevant_vars {
	bys npi (`var') : assert `var'[1] == `var'[_N]
}

collapse ///
	(first) `relevant_vars', ///
	by(npi)

* Comparing dummy from SAP's doctor panel with adjusted dummy created above:
tab    delta_tuition_dummy    dum_tuition2kincrease                                  , m

* Only compare when name matching is ok:
tab    delta_tuition_dummy    dum_tuition2kincrease if med_school == med_school_emiel, m

* Assert that what we see in the tab above is true:
assert delta_tuition_dummy == dum_tuition2kincrease if med_school == med_school_emiel

* Conclusion: When med school name coincides, tuition dummies coincide.

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


**********************
*** 4) REGRESSIONS ***
**********************


* Regressions:

* Use Emiel's brown bag data:
use "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", clear

* Don't think about this:
rename gradYear grd_yr

recode dum_tuition2kincrease (. = 0)

egen grd_yrXphyspec = group(phySpec grd_yr)
egen grd_yrXhrr     = group(hrr     grd_yr)
	
keep ///
	npi dum_tuition2kincrease totPaid_2012 totPaid_2013 ///
	$main_controls PublicSchool nCode_* nCodeEM_* ///
	$FEs

bys npi : assert _N == 1

* Regression A – Emiel's brown bag:
forvalues j = 2012/2013 {
	
	runRegressions            ///
		totPaid_`j'           /// outcome from Emiel BB (FG)
		dum_tuition2kincrease /// dummy   from Emiel BB
		nCode_`j'             /// nCode   from Emiel BB (FG)
		nCodeEM_`j'            // nCodeEM from Emiel BB (FG)
	
}

* Extra regressions sheet:
preserve

merge 1:m npi using "emiel-total_payments-fg-hcpcs-codes"
assert  _merge != 1
keep if _merge == 3 & year == 2013

bys npi : assert _N == 1

foreach var in ///
	totPaid_2013               /// FG
	   fg_hcpcs_total_payments /// includes FG's HCPCS codes
	emiel_betos_total_payments /// includes Emiel's BETOS codes
	        all_total_payments /// includes everything
			{
				
				runRegressions            ///
					`var'                 /// loop
					dum_tuition2kincrease /// dummy   from Emiel BB
					nCode_2013            /// nCode   from Emiel BB (FG)
					nCodeEM_2013          // nCodeEM from Emiel BB (FG)
				
			}
			
restore

* Merge with Simon's panel and keep overlapping npi:
merge 1:m npi using "$git/data/working/FullDataCMSPANEL_final_subsample_tuition"
keep if _merge == 3
drop _merge

* Keep first observation per doctor:
bys npi (year) : keep if _n == 1

* Regression B – same as Regression A but now running for overlap:
forvalues j = 2012/2013 {
	
	runRegressions            ///
		totPaid_`j'           /// outcome from Emiel BB (FG)
		dum_tuition2kincrease /// dummy   from Emiel BB
		nCode_`j'             /// nCode   from Emiel BB (FG)
		nCodeEM_`j'            // nCodeEM from Emiel BB (FG)
	
}

* Regression C – replace Emiel's dummy with Simon's:
forvalues j = 2012/2013 {
	
	runRegressions          ///
		totPaid_`j'         /// outcome from Emiel BB (FG)
		delta_tuition_dummy /// dummy   from Simon
		nCode_`j'           /// nCode   from Emiel BB (FG)
		nCodeEM_`j'          // nCodeEM from Emiel BB (FG)
	
}

* Now use Simon's panel:
use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

* Check so 2013 is min:
sum year
assert r(min) == 2013

* Create 2012:
expand 2 if year == 2013
bys npi year : replace year = year - 1 if year == 2013 & _n == 1

* Verify panel is identified by (npi, year):
bys npi year : assert _N == 1

* Should maybe adjust by adding 3 (?) to each year?
keep if inrange(grd_yr, $lower_year_limit, $upper_year_limit)

* Merge in Simon's nCodes:
merge m:1 npi using "$temp/nCodes"
drop if _merge == 2
drop    _merge

* Simon will think about this later:
forvalues j = 2012/2019 {
	
	replace S_nCode_`j'   = 0 if S_nCode_`j'   == .
	replace S_nCodeEM_`j' = 0 if S_nCodeEM_`j' == .
	
}

* Merge in Simon's new payments variable:
merge 1:1 npi year using "emiel-total_payments-fg-hcpcs-codes"
keep if _merge == 3
drop    _merge

* Merge in FG's totPaid outcomes and controls:
merge m:1 npi using "$fang_gong_replication/output/phy_time", ///
	keepusing( ///
		totPaid_2012 /// outcome
		totPaid_2013 /// outcome
		male         /// control we keep constant
		isMD         /// control we keep constant
		experYear    /// control we keep constant
		nPhyInGroup  /// control we keep constant
		hosAff       /// control we keep constant
		inMedicare   /// control we keep constant
		inERX        /// control we keep constant
		inPQRS       /// control we keep constant
		inEHR        /// control we keep constant
		phySpec      /// control we keep constant
		groupPAC     /// control we keep constant
		nCode_*      /// control which varies by year
		nCodeEM_*)    // control which varies by year

* Keep overlap:
drop if _merge == 2
drop    _merge
		
global const_vars
foreach var in ///
		male         /// control we keep constant
		isMD         /// control we keep constant
		experYear    /// control we keep constant
		nPhyInGroup  /// control we keep constant
		hosAff       /// control we keep constant
		inMedicare   /// control we keep constant
		inERX        /// control we keep constant
		inPQRS       /// control we keep constant
		inEHR        /// control we keep constant
		phySpec      /// control we keep constant
		groupPAC     /// control we keep constant
		{
			rename `var' `var'_const
			global const_vars $const_vars `var'
		}
		
* Dynamic controls:
merge 1:1 npi year using "$temp/characteristics", ///
	keepusing( ///
		male         ///
		isMD         ///
		experYear    ///
		nPhyInGroup  ///
		hosAff       ///
		inMedicare   ///
		inERX        ///
		inPQRS       ///
		inEHR        ///
		phySpec      ///
		groupPAC)    //
		
* From here: all of the controls above, except for nCode and nCode EM, will be from FG!

* Keep overlap:
drop if _merge == 2
drop    _merge

egen grd_yrXphyspec = group(phySpec grd_yr)
egen grd_yrXhrr     = group(hrr     grd_yr)

egen grd_yrXphyspec_const = group(phySpec_const grd_yr)
global const_vars $const_vars grd_yrXphyspec

preserve

* For now, keep one observation per doctor:
bys npi (year) : keep if _n == 1

* Get Emiel's dummy:
merge 1:1 npi using "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", ///
	keepusing(dum_tuition2kincrease)
	
keep if _merge == 3
drop    _merge

recode dum_tuition2kincrease (. = 0)

* Regression D – overlap with Emiel:
forvalues j = 2012/2013 {

	runRegressions            ///
		totPaid_`j'           /// outcome from FG
		dum_tuition2kincrease /// dummy   from Emiel BB
		nCode_`j'             /// nCode   from FG
		nCodeEM_`j'            // nCodeEM from FG

}

* Regression E – replace Emiel's dummy with Simon's:
forvalues j = 2012/2013 {

	runRegressions          ///
		totPaid_`j'         /// outcome from FG
		delta_tuition_dummy /// dummy   from Simon
		nCode_`j'           /// nCode   from FG
		nCodeEM_`j'          // nCodeEM from FG

}

restore

* From here: ignoring Emiel's brown bag data for the rest of the regressions!

preserve

* For now, keep one observation per doctor:
bys npi (year) : keep if _n == 1

* Regression F – Simon's panel:
forvalues j = 2012/2013 {

	runRegressions          ///
		totPaid_`j'         /// outcome from FG
		delta_tuition_dummy /// dummy   from Simon
		nCode_`j'           /// nCode   from FG
		nCodeEM_`j'          // nCodeEM from FG

}

* Regression G – replace FG's nCode and nCodeEM variables with Simon's from Emiel's raw data:
forvalues j = 2013/2013 {

	runRegressions          ///
		totPaid_`j'         /// outcome from FG
		delta_tuition_dummy /// dummy   from Simon
		S_nCode_`j'         /// nCode   from Emiel's raw data
		S_nCodeEM_`j'        // nCodeEM from Emiel's raw data

}

restore

* Regression H – keeping 2013 instead of taking the first obs (shouldn't matter much):
forvalues j = 2013/2013 {
	
	preserve
	
	keep if year == `j'
	
	runRegressions          ///
		totPaid_`j'         /// outcome from FG
		delta_tuition_dummy /// dummy   from Simon
		S_nCode_`j'         /// nCode   from Emiel's raw data
		S_nCodeEM_`j'        // nCodeEM from Emiel's raw data

	restore
	
}

* Regression I – replace FG's payments variable with Simon's from Emiel's raw data:

g double S_nCode   = .
g double S_nCodeEM = .
forvalues n = 2012/2019 {
	replace S_nCode   = S_nCode_`n'   if year == `n'
	replace S_nCodeEM = S_nCodeEM_`n' if year == `n'
}

*** Three options:

* Temporarily put this here so options become implemented correctly:

// drop if ///	
// 	state_fips ==  4 & year >= 2014 | /// Arizona -- January 1, 2014
// 	state_fips ==  5 & year >= 2014 | /// Arkansas -- January 1, 2014
// 	state_fips ==  6 & year >= 2014 | /// California -- January 1, 2014
// 	state_fips ==  8 & year >= 2014 | /// Colorado -- January 1, 2014
// 	state_fips ==  9 & year >= 2014 | /// Connecticut -- January 1, 2014
// 	state_fips == 10 & year >= 2014 | /// Delaware -- January 1, 2014
// 	state_fips == 11 & year >= 2014 | /// District of Columbia -- January 1, 2014
// 	state_fips == 15 & year >= 2014 | /// Hawaii -- January 1, 2014
// 	state_fips == 17 & year >= 2014 | /// Illinois -- January 1, 2014
// 	state_fips == 19 & year >= 2014 | /// Iowa -- January 1, 2014
// 	state_fips == 21 & year >= 2014 | /// Kentucky -- January 1, 2014
// 	state_fips == 24 & year >= 2014 | /// Maryland -- January 1, 2014
// 	state_fips == 25 & year >= 2014 | /// Massachusetts -- January 1, 2014
// 	state_fips == 27 & year >= 2014 | /// Minnesota -- January 1, 2014
// 	state_fips == 32 & year >= 2014 | /// Nevada -- January 1, 2014
// 	state_fips == 34 & year >= 2014 | /// New Jersey -- January 1, 2014
// 	state_fips == 35 & year >= 2014 | /// New Mexico -- January 1, 2014
// 	state_fips == 36 & year >= 2014 | /// New York -- January 1, 2014
// 	state_fips == 38 & year >= 2014 | /// North Dakota -- January 1, 2014
// 	state_fips == 39 & year >= 2014 | /// Ohio -- January 1, 2014
// 	state_fips == 41 & year >= 2014 | /// Oregon -- January 1, 2014
// 	state_fips == 44 & year >= 2014 | /// Rhode Island -- January 1, 2014
// 	state_fips == 50 & year >= 2014 | /// Vermont -- January 1, 2014
// 	state_fips == 53 & year >= 2014 | /// Washington -- January 1, 2014
// 	state_fips == 54 & year >= 2014 | /// West Virginia -- January 1, 2014
// 	state_fips == 26 & year >= 2014 | /// Michigan -- April 1, 2014
// 	state_fips == 33 & year >= 2015 | /// New Hampshire -- August 15, 2014
// 	state_fips == 42 & year >= 2015 | /// Pennsylvania -- January 1, 2015
// 	state_fips == 18 & year >= 2015 | /// Indiana -- February 1, 2015
// 	state_fips ==  2 & year >= 2016 | /// Alaska -- September 1, 2015
// 	state_fips == 30 & year >= 2016 | /// Montana -- January 1, 2016
// 	state_fips == 22 & year >= 2016 | /// Louisiana -- July 1, 2016
// 	state_fips == 51 & year >= 2019 | /// Virginia -- January 1, 2019
// 	state_fips == 23 & year >= 2019 | /// Maine -- January 10, 2019
// 	state_fips == 16 & year >= 2020 | /// Idaho -- January 1, 2020
// 	state_fips == 49 & year >= 2020 | /// Utah -- January 1, 2020
// 	state_fips == 31 & year >= 2021 | /// Nebraska -- October 1, 2020
// 	state_fips == 40 & year >= 2021 | /// Oklahoma -- July 1, 2021
// 	state_fips == 29 & year >= 2022 | /// Missouri -- October 1, 2021
// 	state_fips == 46 & year >= 2023 | /// South Dakota -- July 1, 2023
// 	state_fips == 37 & year >= 2024   //  North Carolina -- December 1, 2023
//
// assert payment_dummy != .
//
// * Option 1 -- max across the doctor:
// bys npi (payment_dummy) : replace payment_dummy = payment_dummy[_N]
// sort npi year
//
// * Option 2 -- fill 1s after first 1
// g payment_year = year if payment_dummy == 1
//
// bys npi (year) : egen min_payment_year = min(payment_year)
//
// replace payment_dummy = 1 if year >= min_payment_year & min_payment_year != .
//
// * Option 3 -- fill 1s before last 1
// g payment_year = year if payment_dummy == 1
//
// bys npi (year) : egen max_payment_year = max(payment_year)
//
// replace payment_dummy = 1 if year <= max_payment_year & max_payment_year != .


cap log close
log using "$temp/2025-06-25-constant-controls-5000.smcl", replace

preserve

foreach var of global const_vars {
	drop   `var'
	rename `var'_const `var'
}

foreach outcome of global sel_payment_vars {
	
	disp ""
	disp "Outcome variable: `outcome'"
	disp ""

	runRegressions               ///
		`outcome'_total_payments ///
		delta_tuition_dummy      /// dummy   from Simon
		S_nCode                  /// nCode   from Emiel's raw data
		S_nCodeEM                //  nCodeEM from Emiel's raw data
	
}

restore

* Affordable Care Act (ACA) adjustment:

* Rollout: https://en.wikipedia.org/wiki/Medicaid_coverage_gap
* State codes: https://en.wikipedia.org/wiki/Federal_Information_Processing_Standard_state_code

disp ""
disp "ACA ADJUSTMENT BELOW"
disp ""

preserve

drop if ///	
	state_fips ==  4 & year >= 2014 | /// Arizona -- January 1, 2014
	state_fips ==  5 & year >= 2014 | /// Arkansas -- January 1, 2014
	state_fips ==  6 & year >= 2014 | /// California -- January 1, 2014
	state_fips ==  8 & year >= 2014 | /// Colorado -- January 1, 2014
	state_fips ==  9 & year >= 2014 | /// Connecticut -- January 1, 2014
	state_fips == 10 & year >= 2014 | /// Delaware -- January 1, 2014
	state_fips == 11 & year >= 2014 | /// District of Columbia -- January 1, 2014
	state_fips == 15 & year >= 2014 | /// Hawaii -- January 1, 2014
	state_fips == 17 & year >= 2014 | /// Illinois -- January 1, 2014
	state_fips == 19 & year >= 2014 | /// Iowa -- January 1, 2014
	state_fips == 21 & year >= 2014 | /// Kentucky -- January 1, 2014
	state_fips == 24 & year >= 2014 | /// Maryland -- January 1, 2014
	state_fips == 25 & year >= 2014 | /// Massachusetts -- January 1, 2014
	state_fips == 27 & year >= 2014 | /// Minnesota -- January 1, 2014
	state_fips == 32 & year >= 2014 | /// Nevada -- January 1, 2014
	state_fips == 34 & year >= 2014 | /// New Jersey -- January 1, 2014
	state_fips == 35 & year >= 2014 | /// New Mexico -- January 1, 2014
	state_fips == 36 & year >= 2014 | /// New York -- January 1, 2014
	state_fips == 38 & year >= 2014 | /// North Dakota -- January 1, 2014
	state_fips == 39 & year >= 2014 | /// Ohio -- January 1, 2014
	state_fips == 41 & year >= 2014 | /// Oregon -- January 1, 2014
	state_fips == 44 & year >= 2014 | /// Rhode Island -- January 1, 2014
	state_fips == 50 & year >= 2014 | /// Vermont -- January 1, 2014
	state_fips == 53 & year >= 2014 | /// Washington -- January 1, 2014
	state_fips == 54 & year >= 2014 | /// West Virginia -- January 1, 2014
	state_fips == 26 & year >= 2014 | /// Michigan -- April 1, 2014
	state_fips == 33 & year >= 2015 | /// New Hampshire -- August 15, 2014
	state_fips == 42 & year >= 2015 | /// Pennsylvania -- January 1, 2015
	state_fips == 18 & year >= 2015 | /// Indiana -- February 1, 2015
	state_fips ==  2 & year >= 2016 | /// Alaska -- September 1, 2015
	state_fips == 30 & year >= 2016 | /// Montana -- January 1, 2016
	state_fips == 22 & year >= 2016 | /// Louisiana -- July 1, 2016
	state_fips == 51 & year >= 2019 | /// Virginia -- January 1, 2019
	state_fips == 23 & year >= 2019 | /// Maine -- January 10, 2019
	state_fips == 16 & year >= 2020 | /// Idaho -- January 1, 2020
	state_fips == 49 & year >= 2020 | /// Utah -- January 1, 2020
	state_fips == 31 & year >= 2021 | /// Nebraska -- October 1, 2020
	state_fips == 40 & year >= 2021 | /// Oklahoma -- July 1, 2021
	state_fips == 29 & year >= 2022 | /// Missouri -- October 1, 2021
	state_fips == 46 & year >= 2023 | /// South Dakota -- July 1, 2023
	state_fips == 37 & year >= 2024   //  North Carolina -- December 1, 2023

foreach var of global const_vars {
	drop   `var'
	rename `var'_const `var'
}

foreach outcome of global sel_payment_vars {
	
	disp ""
	disp "Outcome variable: `outcome'"
	disp ""

	runRegressions               ///
		`outcome'_total_payments ///
		delta_tuition_dummy      /// dummy   from Simon
		S_nCode                  /// nCode   from Emiel's raw data
		S_nCodeEM                //  nCodeEM from Emiel's raw data
	
}

runRegressionsInteract  ///
	pp_quotient         ///
	delta_tuition_dummy /// dummy   from Simon
	payment_dummy       ///
	S_nCode             /// nCode   from Emiel's raw data
	S_nCodeEM            // nCodeEM from Emiel's raw data

restore
	
forvalues j = 2012/2017 {
	
	preserve
	
	foreach var of global const_vars {
		drop   `var'
		rename `var'_const `var'
	}
	
// 	replace PublicSchool = 0 if PublicSchool == .
	
	keep if year == `j'

	disp ""
	disp "BELOW = `j'"
	disp ""

	foreach outcome of global sel_payment_vars {
		
		disp ""
		disp "Outcome variable: `outcome'"
		disp ""

		runRegressions               ///
			`outcome'_total_payments ///
			delta_tuition_dummy      /// dummy   from Simon
			S_nCode_`j'              /// nCode   from Emiel's raw data
			S_nCodeEM_`j'             // nCodeEM from Emiel's raw data
		
	}
	
	restore
	
}

disp ""
disp "ACA ADJUSTMENT BELOW"
disp ""

forvalues j = 2012/2017 {
	
	preserve
	
	drop if ///	
		state_fips ==  4 & year >= 2014 | /// Arizona -- January 1, 2014
		state_fips ==  5 & year >= 2014 | /// Arkansas -- January 1, 2014
		state_fips ==  6 & year >= 2014 | /// California -- January 1, 2014
		state_fips ==  8 & year >= 2014 | /// Colorado -- January 1, 2014
		state_fips ==  9 & year >= 2014 | /// Connecticut -- January 1, 2014
		state_fips == 10 & year >= 2014 | /// Delaware -- January 1, 2014
		state_fips == 11 & year >= 2014 | /// District of Columbia -- January 1, 2014
		state_fips == 15 & year >= 2014 | /// Hawaii -- January 1, 2014
		state_fips == 17 & year >= 2014 | /// Illinois -- January 1, 2014
		state_fips == 19 & year >= 2014 | /// Iowa -- January 1, 2014
		state_fips == 21 & year >= 2014 | /// Kentucky -- January 1, 2014
		state_fips == 24 & year >= 2014 | /// Maryland -- January 1, 2014
		state_fips == 25 & year >= 2014 | /// Massachusetts -- January 1, 2014
		state_fips == 27 & year >= 2014 | /// Minnesota -- January 1, 2014
		state_fips == 32 & year >= 2014 | /// Nevada -- January 1, 2014
		state_fips == 34 & year >= 2014 | /// New Jersey -- January 1, 2014
		state_fips == 35 & year >= 2014 | /// New Mexico -- January 1, 2014
		state_fips == 36 & year >= 2014 | /// New York -- January 1, 2014
		state_fips == 38 & year >= 2014 | /// North Dakota -- January 1, 2014
		state_fips == 39 & year >= 2014 | /// Ohio -- January 1, 2014
		state_fips == 41 & year >= 2014 | /// Oregon -- January 1, 2014
		state_fips == 44 & year >= 2014 | /// Rhode Island -- January 1, 2014
		state_fips == 50 & year >= 2014 | /// Vermont -- January 1, 2014
		state_fips == 53 & year >= 2014 | /// Washington -- January 1, 2014
		state_fips == 54 & year >= 2014 | /// West Virginia -- January 1, 2014
		state_fips == 26 & year >= 2014 | /// Michigan -- April 1, 2014
		state_fips == 33 & year >= 2015 | /// New Hampshire -- August 15, 2014
		state_fips == 42 & year >= 2015 | /// Pennsylvania -- January 1, 2015
		state_fips == 18 & year >= 2015 | /// Indiana -- February 1, 2015
		state_fips ==  2 & year >= 2016 | /// Alaska -- September 1, 2015
		state_fips == 30 & year >= 2016 | /// Montana -- January 1, 2016
		state_fips == 22 & year >= 2016 | /// Louisiana -- July 1, 2016
		state_fips == 51 & year >= 2019 | /// Virginia -- January 1, 2019
		state_fips == 23 & year >= 2019 | /// Maine -- January 10, 2019
		state_fips == 16 & year >= 2020 | /// Idaho -- January 1, 2020
		state_fips == 49 & year >= 2020 | /// Utah -- January 1, 2020
		state_fips == 31 & year >= 2021 | /// Nebraska -- October 1, 2020
		state_fips == 40 & year >= 2021 | /// Oklahoma -- July 1, 2021
		state_fips == 29 & year >= 2022 | /// Missouri -- October 1, 2021
		state_fips == 46 & year >= 2023 | /// South Dakota -- July 1, 2023
		state_fips == 37 & year >= 2024   //  North Carolina -- December 1, 2023
	
	foreach var of global const_vars {
		drop   `var'
		rename `var'_const `var'
	}
	
// 	replace PublicSchool = 0 if PublicSchool == .
	
	keep if year == `j'

	disp ""
	disp "BELOW = `j'"
	disp ""

	foreach outcome of global sel_payment_vars {
		
		disp ""
		disp "Outcome variable: `outcome'"
		disp ""

		runRegressions               ///
			`outcome'_total_payments ///
			delta_tuition_dummy      /// dummy   from Simon
			S_nCode_`j'              /// nCode   from Emiel's raw data
			S_nCodeEM_`j'             // nCodeEM from Emiel's raw data
		
	}
	
	runRegressionsInteract  ///
		pp_quotient         ///
		delta_tuition_dummy /// dummy   from Simon
		payment_dummy       ///
		S_nCode_`j'         /// nCode   from Emiel's raw data
		S_nCodeEM_`j'        // nCodeEM from Emiel's raw data
	
	restore
	
}

log close

translate ///
	"$temp/2025-06-25-constant-controls-5000.smcl" ///
	"$temp/2025-06-25-constant-controls-5000.pdf", ///
	replace

cap log close
log using "$temp/2025-06-25-dynamic-controls-5000.smcl", replace

foreach outcome of global sel_payment_vars {
	
	disp ""
	disp "Outcome variable: `outcome'"
	disp ""

	runRegressions               ///
		`outcome'_total_payments ///
		delta_tuition_dummy      /// dummy   from Simon
		S_nCode                  /// nCode   from Emiel's raw data
		S_nCodeEM                //  nCodeEM from Emiel's raw data
	
}

disp ""
disp "ACA ADJUSTMENT BELOW"
disp ""

preserve

drop if ///	
	state_fips ==  4 & year >= 2014 | /// Arizona -- January 1, 2014
	state_fips ==  5 & year >= 2014 | /// Arkansas -- January 1, 2014
	state_fips ==  6 & year >= 2014 | /// California -- January 1, 2014
	state_fips ==  8 & year >= 2014 | /// Colorado -- January 1, 2014
	state_fips ==  9 & year >= 2014 | /// Connecticut -- January 1, 2014
	state_fips == 10 & year >= 2014 | /// Delaware -- January 1, 2014
	state_fips == 11 & year >= 2014 | /// District of Columbia -- January 1, 2014
	state_fips == 15 & year >= 2014 | /// Hawaii -- January 1, 2014
	state_fips == 17 & year >= 2014 | /// Illinois -- January 1, 2014
	state_fips == 19 & year >= 2014 | /// Iowa -- January 1, 2014
	state_fips == 21 & year >= 2014 | /// Kentucky -- January 1, 2014
	state_fips == 24 & year >= 2014 | /// Maryland -- January 1, 2014
	state_fips == 25 & year >= 2014 | /// Massachusetts -- January 1, 2014
	state_fips == 27 & year >= 2014 | /// Minnesota -- January 1, 2014
	state_fips == 32 & year >= 2014 | /// Nevada -- January 1, 2014
	state_fips == 34 & year >= 2014 | /// New Jersey -- January 1, 2014
	state_fips == 35 & year >= 2014 | /// New Mexico -- January 1, 2014
	state_fips == 36 & year >= 2014 | /// New York -- January 1, 2014
	state_fips == 38 & year >= 2014 | /// North Dakota -- January 1, 2014
	state_fips == 39 & year >= 2014 | /// Ohio -- January 1, 2014
	state_fips == 41 & year >= 2014 | /// Oregon -- January 1, 2014
	state_fips == 44 & year >= 2014 | /// Rhode Island -- January 1, 2014
	state_fips == 50 & year >= 2014 | /// Vermont -- January 1, 2014
	state_fips == 53 & year >= 2014 | /// Washington -- January 1, 2014
	state_fips == 54 & year >= 2014 | /// West Virginia -- January 1, 2014
	state_fips == 26 & year >= 2014 | /// Michigan -- April 1, 2014
	state_fips == 33 & year >= 2015 | /// New Hampshire -- August 15, 2014
	state_fips == 42 & year >= 2015 | /// Pennsylvania -- January 1, 2015
	state_fips == 18 & year >= 2015 | /// Indiana -- February 1, 2015
	state_fips ==  2 & year >= 2016 | /// Alaska -- September 1, 2015
	state_fips == 30 & year >= 2016 | /// Montana -- January 1, 2016
	state_fips == 22 & year >= 2016 | /// Louisiana -- July 1, 2016
	state_fips == 51 & year >= 2019 | /// Virginia -- January 1, 2019
	state_fips == 23 & year >= 2019 | /// Maine -- January 10, 2019
	state_fips == 16 & year >= 2020 | /// Idaho -- January 1, 2020
	state_fips == 49 & year >= 2020 | /// Utah -- January 1, 2020
	state_fips == 31 & year >= 2021 | /// Nebraska -- October 1, 2020
	state_fips == 40 & year >= 2021 | /// Oklahoma -- July 1, 2021
	state_fips == 29 & year >= 2022 | /// Missouri -- October 1, 2021
	state_fips == 46 & year >= 2023 | /// South Dakota -- July 1, 2023
	state_fips == 37 & year >= 2024   //  North Carolina -- December 1, 2023

foreach outcome of global sel_payment_vars {
	
	disp ""
	disp "Outcome variable: `outcome'"
	disp ""

	runRegressions               ///
		`outcome'_total_payments ///
		delta_tuition_dummy      /// dummy   from Simon
		S_nCode                  /// nCode   from Emiel's raw data
		S_nCodeEM                //  nCodeEM from Emiel's raw data
	
}

restore

forvalues j = 2015/2017 {
	
	preserve
	
// 	replace PublicSchool = 0 if PublicSchool == .
	
	keep if year == `j'

	disp ""
	disp "BELOW = `j'"
	disp ""

	foreach outcome of global sel_payment_vars {
		
		disp ""
		disp "Outcome variable: `outcome'"
		disp ""

		runRegressions               ///
			`outcome'_total_payments ///
			delta_tuition_dummy      /// dummy   from Simon
			S_nCode_`j'              /// nCode   from Emiel's raw data
			S_nCodeEM_`j'             // nCodeEM from Emiel's raw data
		
	}
	
	restore
	
}

disp ""
disp "ACA ADJUSTMENT BELOW"
disp ""

forvalues j = 2015/2017 {
	
	preserve
	
	drop if ///	
		state_fips ==  4 & year >= 2014 | /// Arizona -- January 1, 2014
		state_fips ==  5 & year >= 2014 | /// Arkansas -- January 1, 2014
		state_fips ==  6 & year >= 2014 | /// California -- January 1, 2014
		state_fips ==  8 & year >= 2014 | /// Colorado -- January 1, 2014
		state_fips ==  9 & year >= 2014 | /// Connecticut -- January 1, 2014
		state_fips == 10 & year >= 2014 | /// Delaware -- January 1, 2014
		state_fips == 11 & year >= 2014 | /// District of Columbia -- January 1, 2014
		state_fips == 15 & year >= 2014 | /// Hawaii -- January 1, 2014
		state_fips == 17 & year >= 2014 | /// Illinois -- January 1, 2014
		state_fips == 19 & year >= 2014 | /// Iowa -- January 1, 2014
		state_fips == 21 & year >= 2014 | /// Kentucky -- January 1, 2014
		state_fips == 24 & year >= 2014 | /// Maryland -- January 1, 2014
		state_fips == 25 & year >= 2014 | /// Massachusetts -- January 1, 2014
		state_fips == 27 & year >= 2014 | /// Minnesota -- January 1, 2014
		state_fips == 32 & year >= 2014 | /// Nevada -- January 1, 2014
		state_fips == 34 & year >= 2014 | /// New Jersey -- January 1, 2014
		state_fips == 35 & year >= 2014 | /// New Mexico -- January 1, 2014
		state_fips == 36 & year >= 2014 | /// New York -- January 1, 2014
		state_fips == 38 & year >= 2014 | /// North Dakota -- January 1, 2014
		state_fips == 39 & year >= 2014 | /// Ohio -- January 1, 2014
		state_fips == 41 & year >= 2014 | /// Oregon -- January 1, 2014
		state_fips == 44 & year >= 2014 | /// Rhode Island -- January 1, 2014
		state_fips == 50 & year >= 2014 | /// Vermont -- January 1, 2014
		state_fips == 53 & year >= 2014 | /// Washington -- January 1, 2014
		state_fips == 54 & year >= 2014 | /// West Virginia -- January 1, 2014
		state_fips == 26 & year >= 2014 | /// Michigan -- April 1, 2014
		state_fips == 33 & year >= 2015 | /// New Hampshire -- August 15, 2014
		state_fips == 42 & year >= 2015 | /// Pennsylvania -- January 1, 2015
		state_fips == 18 & year >= 2015 | /// Indiana -- February 1, 2015
		state_fips ==  2 & year >= 2016 | /// Alaska -- September 1, 2015
		state_fips == 30 & year >= 2016 | /// Montana -- January 1, 2016
		state_fips == 22 & year >= 2016 | /// Louisiana -- July 1, 2016
		state_fips == 51 & year >= 2019 | /// Virginia -- January 1, 2019
		state_fips == 23 & year >= 2019 | /// Maine -- January 10, 2019
		state_fips == 16 & year >= 2020 | /// Idaho -- January 1, 2020
		state_fips == 49 & year >= 2020 | /// Utah -- January 1, 2020
		state_fips == 31 & year >= 2021 | /// Nebraska -- October 1, 2020
		state_fips == 40 & year >= 2021 | /// Oklahoma -- July 1, 2021
		state_fips == 29 & year >= 2022 | /// Missouri -- October 1, 2021
		state_fips == 46 & year >= 2023 | /// South Dakota -- July 1, 2023
		state_fips == 37 & year >= 2024   //  North Carolina -- December 1, 2023
	
// 	replace PublicSchool = 0 if PublicSchool == .
	
	keep if year == `j'

	disp ""
	disp "BELOW = `j'"
	disp ""

	foreach outcome of global sel_payment_vars {
		
		disp ""
		disp "Outcome variable: `outcome'"
		disp ""

		runRegressions               ///
			`outcome'_total_payments ///
			delta_tuition_dummy      /// dummy   from Simon
			S_nCode_`j'              /// nCode   from Emiel's raw data
			S_nCodeEM_`j'             // nCodeEM from Emiel's raw data
		
	}
	
	restore
	
}

log close

translate ///
	"$temp/2025-06-25-dynamic-controls-5000.smcl" ///
	"$temp/2025-06-25-dynamic-controls-5000.pdf", ///
	replace
	

******************************
*** ProPublica REGRESSIONS ***
******************************

cap log close
log using "$temp/2025-07-07-propublica-constant-controls-5000.smcl", replace

preserve

* Use constant controls for now:
foreach var of global const_vars {
	drop   `var'
	rename `var'_const `var'
}

* Do ACA adjustment:
drop if ///	
	state_fips ==  4 & year >= 2014 | /// Arizona -- January 1, 2014
	state_fips ==  5 & year >= 2014 | /// Arkansas -- January 1, 2014
	state_fips ==  6 & year >= 2014 | /// California -- January 1, 2014
	state_fips ==  8 & year >= 2014 | /// Colorado -- January 1, 2014
	state_fips ==  9 & year >= 2014 | /// Connecticut -- January 1, 2014
	state_fips == 10 & year >= 2014 | /// Delaware -- January 1, 2014
	state_fips == 11 & year >= 2014 | /// District of Columbia -- January 1, 2014
	state_fips == 15 & year >= 2014 | /// Hawaii -- January 1, 2014
	state_fips == 17 & year >= 2014 | /// Illinois -- January 1, 2014
	state_fips == 19 & year >= 2014 | /// Iowa -- January 1, 2014
	state_fips == 21 & year >= 2014 | /// Kentucky -- January 1, 2014
	state_fips == 24 & year >= 2014 | /// Maryland -- January 1, 2014
	state_fips == 25 & year >= 2014 | /// Massachusetts -- January 1, 2014
	state_fips == 27 & year >= 2014 | /// Minnesota -- January 1, 2014
	state_fips == 32 & year >= 2014 | /// Nevada -- January 1, 2014
	state_fips == 34 & year >= 2014 | /// New Jersey -- January 1, 2014
	state_fips == 35 & year >= 2014 | /// New Mexico -- January 1, 2014
	state_fips == 36 & year >= 2014 | /// New York -- January 1, 2014
	state_fips == 38 & year >= 2014 | /// North Dakota -- January 1, 2014
	state_fips == 39 & year >= 2014 | /// Ohio -- January 1, 2014
	state_fips == 41 & year >= 2014 | /// Oregon -- January 1, 2014
	state_fips == 44 & year >= 2014 | /// Rhode Island -- January 1, 2014
	state_fips == 50 & year >= 2014 | /// Vermont -- January 1, 2014
	state_fips == 53 & year >= 2014 | /// Washington -- January 1, 2014
	state_fips == 54 & year >= 2014 | /// West Virginia -- January 1, 2014
	state_fips == 26 & year >= 2014 | /// Michigan -- April 1, 2014
	state_fips == 33 & year >= 2015 | /// New Hampshire -- August 15, 2014
	state_fips == 42 & year >= 2015 | /// Pennsylvania -- January 1, 2015
	state_fips == 18 & year >= 2015 | /// Indiana -- February 1, 2015
	state_fips ==  2 & year >= 2016 | /// Alaska -- September 1, 2015
	state_fips == 30 & year >= 2016 | /// Montana -- January 1, 2016
	state_fips == 22 & year >= 2016 | /// Louisiana -- July 1, 2016
	state_fips == 51 & year >= 2019 | /// Virginia -- January 1, 2019
	state_fips == 23 & year >= 2019 | /// Maine -- January 10, 2019
	state_fips == 16 & year >= 2020 | /// Idaho -- January 1, 2020
	state_fips == 49 & year >= 2020 | /// Utah -- January 1, 2020
	state_fips == 31 & year >= 2021 | /// Nebraska -- October 1, 2020
	state_fips == 40 & year >= 2021 | /// Oklahoma -- July 1, 2021
	state_fips == 29 & year >= 2022 | /// Missouri -- October 1, 2021
	state_fips == 46 & year >= 2023 | /// South Dakota -- July 1, 2023
	state_fips == 37 & year >= 2024   //  North Carolina -- December 1, 2023

collapse ///
	(mean)  pp_quotient S_nCode S_nCodeEM ///
	(first) $const_vars PublicSchool hrr grd_yr Tuition_quantile ///
	(max)   delta_tuition_dummy payment_dummy, ///
	by(npi)
	
* How many doctors recieve a payment?
tab payment_dummy, m

runRegressionsInteract  ///
	pp_quotient         ///
	delta_tuition_dummy /// dummy   from Simon
	payment_dummy       ///
	S_nCode             /// nCode   from Emiel's raw data
	S_nCodeEM            // nCodeEM from Emiel's raw data

restore

log close

translate ///
	"$temp/2025-07-07-propublica-constant-controls-5000.smcl" ///
	"$temp/2025-07-07-propublica-constant-controls-5000.pdf", ///
	replace

	
************************
*** GRADE 1 ANALYSIS ***
************************

forvalues j = 2013/2014 {
	
	cap log close
	log using "$temp/2025-06-10-grade-1-analysis-`j'-$dollar_limit.smcl", replace
	
	preserve
	
	foreach var of global const_vars {
		drop   `var'
		rename `var'_const `var'
	}
	
// 	replace PublicSchool = 0 if PublicSchool == .
	
	keep if year == `j'

	disp ""
	disp "BELOW = `j'"
	disp ""

	disp ""
	disp "Dummy for grade 1 is 1:"
	disp ""
	
	foreach outcome of global sel_payment_vars {
		
		disp ""
		disp "Outcome variable: `outcome'"
		disp ""

		runRegressions               ///
			`outcome'_total_payments ///
			delta_tuition_dummy      /// dummy   from Simon
			S_nCode_`j'              /// nCode   from Emiel's raw data
			S_nCodeEM_`j'             // nCodeEM from Emiel's raw data
		
	}
	
	replace delta_tuition_dummy = . if grade == 1
	
	disp ""
	disp "Dummy for grade 1 is missing:"
	disp ""
	
	foreach outcome of global sel_payment_vars {
		
		disp ""
		disp "Outcome variable: `outcome'"
		disp ""

		runRegressions               ///
			`outcome'_total_payments ///
			delta_tuition_dummy      /// dummy   from Simon
			S_nCode_`j'              /// nCode   from Emiel's raw data
			S_nCodeEM_`j'             // nCodeEM from Emiel's raw data
		
	}
	
	replace grade = 0 if delta_tuition_dummy == 0
	
	disp ""
	disp "Grade is 0 when dummy is 0:"
	disp ""
	
	foreach outcome of global sel_payment_vars {
		
		disp ""
		disp "Outcome variable: `outcome'"
		disp ""

		foreach fe of global FEs_list {
			
			reghdfe ///
				`outcome'_total_payments ///
				ib0.grade ///
				$main_controls PublicSchool S_nCode_`j' S_nCodeEM_`j', ///
				cluster(hrr) a(`fe')
			
		}
		
	}
	
	restore
	
	log close
	
	translate ///
		"$temp/2025-06-10-grade-1-analysis-`j'-$dollar_limit.smcl" ///
		"$temp/2025-06-10-grade-1-analysis-`j'-$dollar_limit.pdf", ///
		replace
	
}


**************
*** GRAPHS ***
**************

preserve

keep if inrange(grade, 1, 4)

bys npi (year) : keep if _n == 1
		
graph bar (mean) ///
	tot_tuition, ///
	over(grade) ///
	title("Total tuition By Grade") ///
	subtitle("Tuition limit: $dollar_limit") ///
	yscale(range(0 140000)) ///
	ylabel(0(20000)140000, format(%15.0fc))
	
graph export "$git/plots/tot-tuition-by-grade-$dollar_limit.jpg", replace

sum grd_yr
forvalues j = `r(min)' / `r(max)' {
	
	graph bar (mean) ///
	tot_tuition if grd_yr == `j', ///
	over(grade) ///
	title("Total tuition By Grade – Graduation Year: `j'") ///
	subtitle("Tuition limit: $dollar_limit") ///
	yscale(range(0 140000)) ///
	ylabel(0(20000)140000, format(%15.0fc))
	
	graph export "$git/plots/tot-tuition-by-grade-`j'-$dollar_limit.jpg", replace
	
}
	
reghdfe tot_tuition ib(4).grade, absorb(med_school)
	
coefplot, ///
keep(1.grade 2.grade 3.grade) ///
ci(95) vertical title("Total tuition By Grade – School FEs") ///
subtitle("Grade = 4 is Base (Zero) – Tuition limit: $dollar_limit") ///
yscale(range(0 30000)) ylabel(0(10000)30000, format(%15.0fc))

graph export "$git/plots/tot-tuition-by-grade-reg-$dollar_limit.jpg", replace

restore


********************************
*** CORRELATION MATRICES ETC ***
********************************

preserve

keep if year == 2013

log using "$temp/correlation-matrix-controls.smcl", replace

* So you can see the variable names:
disp "$main_controls"

* Correlation matrix:

* 1) Overview:
corr ///
	$main_controls    /// controls
	PublicSchool      /// control
	Tuition_quantile  // FE

* 2) Same table but with significance, unfortunately in two parts visually:
pwcorr ///
	$main_controls    /// controls
	PublicSchool      /// control
	Tuition_quantile, /// FE
	sig listwise
	
log close

restore

* Regression J – specializations:
preserve

keep if year == 2013

// log using "$temp/specializations-1-new.smcl", replace
//
// replace PublicSchool = 0 if PublicSchool == .

foreach spec of global specializations {
	
	disp ""
	disp "BELOW = `spec'"
	disp ""
	
	runRegressionsInteract      ///
		fg_hcpcs_total_payments /// outcome from Emiel's raw data
		delta_tuition_dummy     /// dummy   from Simon
		`spec'					/// specialization
		S_nCode_2013            /// nCode   from Emiel's raw data
		S_nCodeEM_2013           // nCodeEM from Emiel's raw data
	
}

// log close

restore


cap log close


******************
*** SCRAP CODE ***
******************

// sum grd_yr
// forvalues j = `r(min)' / `r(max)' {
//	
// 	preserve
//	
// 	keep if inrange(grade, 2, 4)
//
// 	bys npi (year) : keep if _n == 1
//	
// 	keep if grd_yr == `j'
//	
// 	count
//	
// 	if (r(N) > 0) {
//	
// 		reghdfe tot_tuition ib(4).grade, absorb(med_school)
//			
// 		coefplot, ///
// 		keep(2.grade 3.grade) ///
// 		ci(95) vertical title("Total tuition By Grade – School FEs – `j'") ///
// 		subtitle("Grade = 2, 3, 4 and 4 is Base (Zero)") ///
// 		yscale(range(0 20000)) ylabel(0(10000)20000, format(%15.0fc))
//
// 		graph export "$git/plots/tot-tuition-by-grade-reg-`j'.jpg", replace
//		
// 	}
//	
// 	restore
//	
// }

// * Payment:
// import delimited ///
// 	"$dropbox/ProRepublica/20180702b-docdollars-payments.csv", ///
// 	clear rowrange(1:100000)
//
// keep physician_profile_id total_amount_of_payment_usdollar
//
// merge m:1 physician_profile_id using "$temp/propublica-npi-pid"
// keep if _merge == 3
// drop    _merge
//
// drop physician_profile_id
//
// * Have since before:
// use "$temp/propublica-docdollars-total-amount", clear
//
// * ...and variable is already in the panel!

