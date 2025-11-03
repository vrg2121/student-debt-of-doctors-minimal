
**********************************************
*** COMPARE EMIEL'S BROWN BAG DATA WITH FG ***
**********************************************

use "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", clear

rename totPaid_* totPaid_*_Emiel

drop _merge

merge 1:1 npi using "$fang_gong_replication/output/phy_time", keepusing(totPaid_*)
assert  _merge != 1 // Emiel's npi are subset of FG's
keep if _merge == 3

drop _merge

rename totPaid_2012 totPaid_2012_FG
rename totPaid_2013 totPaid_2013_FG

assert ///
	totPaid_2012_Emiel == totPaid_2012_FG & ///
	totPaid_2013_Emiel == totPaid_2013_FG

*** Conclusion ***

* Emiel's Brown bag data is subset of FG's.


*******************************************
*** COMPARE total_payments AND totPaid ***
*******************************************

use npi year total_payments using "$dropbox/FullDataCMSPANEL_final.dta", clear

keep if year == 13 // 2013

bys npi : assert _N == 1

preserve

	* Check so final panel file comes from CMS2013 file:
	
	rename total_payments total_payments_final

	merge 1:1 npi using "$dropbox/FullData/RawData/CMS2013", keepusing(total_payments)
	keep if _merge == 3 // think about this?
	drop    _merge

	assert total_payments_final == total_payments // true

restore
	
merge 1:1 npi using "$fang_gong_replication/output/phy_time", keepusing(totPaid_2013)
keep if _merge == 3 // think about this?
drop    _merge

replace total_payments = total_payments / 1000 // to get same unit as totPaid

recast double total_payments // to get same type as totPaid

assert total_payments == totPaid_2013 // false

g delta = total_payments - totPaid_2013

sum delta, d

replace delta = r( p1) if delta < r( p1)
replace delta = r(p99) if delta > r(p99)

hist delta, bin(100)

* Examine rounded variables:

replace total_payments = round(total_payments, 0.1)
replace totPaid_2013   = round(totPaid_2013  , 0.1)

assert total_payments == totPaid_2013 // false

assert total_payments < totPaid_2013 if total_payments != totPaid_2013 // false

*** Conclusion ***

* total_payments and totPaid are not the same.


************************************************
*** COMPARE EMIEL'S AND FG'S UNDERLYING DATA ***
************************************************

import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D13_Prov_Svc.csv", clear

bys rndrng_npi hcpcs_cd place_of_srvc : assert _N == 1

rename rndrng_npi npi

keep npi hcpcs_cd place_of_srvc tot_srvcs avg_mdcr_pymt_amt

save "$temp/emiel-csv-2013-minimal", replace

import delimited "$fang_gong_replication/input/Medicare_Provider_Util_Payment_PUF_CY2013.txt", clear

drop if _n == 1

bys npi hcpcs_code place_of_service : assert _N == 1

keep npi hcpcs_code place_of_service line_srvc_cnt average_medicare_payment_amt

save "$temp/fg-txt-2013-minimal", replace
use  "$temp/fg-txt-2013-minimal", clear

rename hcpcs_code hcpcs_cd
rename place_of_service place_of_srvc

merge 1:1 npi hcpcs_cd place_of_srvc using "$temp/emiel-csv-2013-minimal"
keep if _merge == 3
drop    _merge

// assert tot_srvcs         == line_srvc_cnt
// assert avg_mdcr_pymt_amt == average_medicare_payment_amt

g same_count = tot_srvcs         == line_srvc_cnt
g same_mean  = avg_mdcr_pymt_amt == average_medicare_payment_amt

tab same_count, m
tab same_mean , m

tab same_count same_mean, m // almost diagonal

*** Conclusion ***

* Underlying data sets have different variable names but are very similar.


************************************************
*** COMPARE FG FROM UNDERLYING WITH FG FINAL ***
************************************************

use "$temp/fg-txt-2013-minimal", clear

g totPaid = line_srvc_cnt * average_medicare_payment_amt

collapse (sum) totPaid, by(npi)

merge 1:1 npi using "$fang_gong_replication/output/phy_time", keepusing(totPaid_2013)
keep if _merge == 3
drop    _merge

replace totPaid = totPaid / 1000

assert totPaid == totPaid_2013

replace totPaid      = round(totPaid     , 0.1)
replace totPaid_2013 = round(totPaid_2013, 0.1)

assert totPaid == totPaid_2013

assert totPaid > totPaid_2013 if totPaid != totPaid_2013 // Only 8 contradictions, probably due to rounding

*** Conclusion ***

* From underlying and final are different:
* FG final probably restricts the data to e.g. certain HCPCS codes?


************************************************
*** EMIEL'S DATA CREATION FOR total_payments ***
************************************************

* Modified by SAP:

import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D13_Prov_Svc.csv", clear

rename rndrng_npi npi
rename hcpcs_cd   hcpcs
rename tot_srvcs  amount_services

merge m:1 hcpcs using "$dropbox/FullData/RawData/BETOS2.dta"
keep if _merge != 2
drop    _merge

* Compute total amount paid per HCPCS code:
gen tot_amount_paid = amount_services * avg_mdcr_pymt_amt

* Compute total amount paid per BETOS subcode (rbcs_cat_subcat):
collapse (sum) tot_amount_paid, by(npi rbcs_cat_subcat)

* For each BETOS subcode seperately create variables of total amount paid:
g obs_included = 0
foreach k in ///
	AA ///
	EB EC EE EH EI EM EN EO ER EV EX ///
	IC IM IN IS IU IX ///
	NA ///
	PC PE PG PM PO PS PV ///
	RB RD RH RI RR RT RX ///
	TA TC TN TP TX {
		replace obs_included = 1          if rbcs_cat_subcat == "`k'"
		g       paid`k' = tot_amount_paid if rbcs_cat_subcat == "`k'"
}

* Large percentage of the data is excluded:
tab obs_included, m

* The following BETOS subcodes are excluded:
tab rbcs_cat_subcat if obs_included == 0, m

* Drop redundant variables:
drop rbcs_cat_subcat tot_amount_paid obs_included

* Create a wide dataset with one row per npi and amounts paid etc (all vars are collapsed by npi):
collapse (firstnm) paid*, by(npi)

* Create total_payments:
egen total_payments = rowtotal(paid*)

keep npi total_payments

save "$temp/emiel-total_payments-replicated", replace
use  "$temp/emiel-total_payments-replicated", clear

rename total_payments total_payments_replicated

merge 1:1 npi using "$dropbox/FullData/RawData/CMS2013", keepusing(total_payments)
assert _merge == 3 // perfect match
drop   _merge

assert total_payments_replicated == total_payments // true

*** Conclusion ***

* Emiel excludes 11 BETOS subcodes, amounting to around 7.5 % of the data


***********************************************************
*** CREATING NEW VERSIONS OF totPaid AND total_payments ***
***********************************************************


* Will then compare different versions in regressions:


*** INCLUDE EVERYTHING ***

use "$temp/emiel-csv-2013-minimal", clear

g total_payments_full = tot_srvcs * avg_mdcr_pymt_amt

collapse (sum) total_payments_full, by(npi)

save "total_payments_full", replace


*** SAME BETOS CODES AS FG ***

use "$fang_gong_replication/output/phy_serv_time", clear

keep hcpcs

duplicates drop

merge 1:1 hcpcs using "$dropbox/FullData/RawData/BETOS2.dta"
keep if _merge == 3
drop    _merge

keep rbcs_cat_subcat

duplicates drop

sort rbcs_cat_subcat

levelsof rbcs_cat_subcat, miss local(fg_betos_codes)

global fg_betos_codes "`fg_betos_codes'"

import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D13_Prov_Svc.csv", clear

rename rndrng_npi npi
rename hcpcs_cd   hcpcs
rename tot_srvcs  amount_services

merge m:1 hcpcs using "$dropbox/FullData/RawData/BETOS2.dta"
keep if _merge != 2
drop    _merge

* Compute total amount paid per HCPCS code:
gen tot_amount_paid = amount_services * avg_mdcr_pymt_amt

* Compute total amount paid per BETOS subcode (rbcs_cat_subcat):
collapse (sum) tot_amount_paid, by(npi rbcs_cat_subcat)

* For each BETOS subcode seperately create variables of total amount paid:
g obs_included = 0
foreach k of global fg_betos_codes {
		replace obs_included = 1          if rbcs_cat_subcat == "`k'"
		g       paid`k' = tot_amount_paid if rbcs_cat_subcat == "`k'"
}

* Large percentage of the data is excluded:
tab obs_included, m

* The following BETOS subcodes are excluded:
tab rbcs_cat_subcat if obs_included == 0, m

* Drop redundant variables:
drop rbcs_cat_subcat tot_amount_paid obs_included

* Create a wide dataset with one row per npi and amounts paid etc (all vars are collapsed by npi):
collapse (firstnm) paid*, by(npi)

* Create total_payments:
egen fg_betos_total_payments = rowtotal(paid*)

keep npi fg_betos_total_payments

save "$temp/emiel-total_payments-fg-betos-codes", replace


*** SAME HCPCS CODES AS FG ***

* Other implementation than for BETOS because the amount of HCPCS codes

use "$fang_gong_replication/output/phy_serv_time", clear

keep hcpcs

duplicates drop

save "$temp/fg-hcpcs-codes", replace

forvalues n = 13/19 {

	import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D`n'_Prov_Svc.csv", clear

	rename rndrng_npi npi
	rename hcpcs_cd   hcpcs
	rename tot_srvcs  amount_services

	* Compute total amount paid per HCPCS code:
	gen tot_amount_paid = amount_services * avg_mdcr_pymt_amt

	* Compute total amount paid per BETOS subcode (rbcs_cat_subcat):
	collapse (sum) tot_amount_paid, by(npi hcpcs)

	merge m:1 hcpcs using "$temp/fg-hcpcs-codes"
	drop if          _merge == 2
	g obs_included = _merge == 3
	drop             _merge

	* Large percentage of the data is excluded:
	tab obs_included, m

	* The following HCPCS subcodes are excluded:
	tab hcpcs if obs_included == 0, m

	keep if obs_included == 1

	* Create a wide dataset with one row per npi and amounts paid etc (all vars are collapsed by npi):
	collapse (sum) fg_hcpcs_total_payments = tot_amount_paid, by(npi)

	g year = 2000 + `n'
	
	save "$temp/emiel-total_payments-fg-hcpcs-codes-20`n'", replace
	
}


*** Emiel: nServ = amount_services ***

import delimited "$fang_gong_replication/input/hcpcslist_timed_with_min.csv", clear

keep hcpcs isem

rename isem isEM

tostring hcpcs, replace

save "$temp/hcpcs-isEM", replace

forvalues n = 13/14 { // 19

	import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D`n'_Prov_Svc.csv", clear

	drop if place_of_srvc == ""
	g inOffice = (place_of_srvc == "O")
	
	rename rndrng_npi npi
	rename hcpcs_cd   hcpcs
	rename tot_srvcs  nServ

	keep npi hcpcs inOffice nServ
	sort npi hcpcs inOffice
	
	* Restricting to FG's HCPCS codes:
	merge m:1 hcpcs using "$temp/fg-hcpcs-codes"
	keep if _merge == 3
	drop    _merge
	
	* Merging on isEM:
	merge m:1 hcpcs using "$temp/hcpcs-isEM"
	drop if _merge == 2
	drop    _merge
	
	replace isEM = isEM == 1
	
	* Indicator: a new hcpcs for this npi
	g isNewHcpcs = ///
		(nServ > 0 & npi != npi[_n-1]) | ///
		(nServ > 0 & npi == npi[_n-1] & hcpcs != hcpcs[_n-1])
		
	g isNewEM = isEM * isNewHcpcs

	collapse (sum) ///
		S_nCode_20`n'   = isNewHcpcs ///
		S_nCodeEM_20`n' = isNewEM,   ///
		by(npi)
	
// 	g year = 2000 + `n'
	
	save "$temp/nCodes-20`n'", replace
	
}

*** 1) FG: Compare nCodes created directly with output ***

forvalues n = 12/12 {

// 	import delimited "$fang_gong_replication/input/Medicare_Provider_Util_Payment_PUF_CY20`n'.txt", clear
//
// 	drop if _n == 1
//	
// 	* Drops:
//	
// // 		* only keep individuals (about 95%; organizations about 5%)
// // 		drop if nppes_entity_code != "I"
// //		
// // 		* only keep physicians in continental US (>99.99%)
// // 		drop if nppes_provider_country != "US"
// //		
// // 		foreach st in XX AA AE AP AS GU MP PR VI ZZ {
// // 			drop if nppes_provider_state == "`st'"
// // 		}
// //		
// // 		* generate numerical gender
// // 		drop if nppes_provider_gender == ""
// //		
// // 		* generate numerical provider type
// // 		drop if provider_type == ""
//	
// 	drop if place_of_service == ""
// 	g inOffice = (place_of_service == "O")
//
// 	rename hcpcs_code    hcpcs
// 	rename line_srvc_cnt nServ
//
// 	recode nServ(. = 0)
	
	use "$fang_gong_replication/output/phy_serv_time", clear
	
	keep npi hcpcs inOffice nServ
	sort npi hcpcs inOffice
	
	* Restricting to FG's HCPCS codes:
// 	merge m:1 hcpcs using "$temp/fg-hcpcs-codes"
// 	keep if _merge == 3
// 	drop    _merge
		
	* Merging on isEM:
	merge m:1 hcpcs using "$temp/hcpcs-isEM"
	drop if _merge == 2
	drop    _merge
	
	replace isEM = isEM == 1
	
	* Indicator: a new hcpcs for this npi
	g isNewHcpcs = ///
		(nServ > 0 & npi != npi[_n-1]) | ///
		(nServ > 0 & npi == npi[_n-1] & hcpcs != hcpcs[_n-1])
		
	g isNewEM = isEM * isNewHcpcs

	collapse (sum) ///
		S_nCode_20`n'   = isNewHcpcs ///
		S_nCodeEM_20`n' = isNewEM,   ///
		by(npi)
	
// 	g year = 2000 + `n'
	
	save "$temp/fg-nCodes-20`n'", replace
	
}

use "$fang_gong_replication/output/phy_time", clear

* Merge in my nCodes:
forvalues j = 2012/2012 {
	
	merge 1:1 npi using "$temp/fg-nCodes-`j'"
	drop if _merge == 2
	drop    _merge
	
	* Think about this:
	replace S_nCode_`j'   = 0 if S_nCode_`j'   == .
	replace S_nCodeEM_`j' = 0 if S_nCodeEM_`j' == .
	
}

* New always larger:
forvalues j = 2012/2012 {
	
	assert S_nCode_`j'   >= nCode_`j'
	assert S_nCodeEM_`j' >= nCodeEM_`j'
	
}

*** 2) FG: Compare nCodes created directly with output ***

forvalues n = 12/13 {

	import delimited "$fang_gong_replication/input/Medicare_Provider_Util_Payment_PUF_CY20`n'.txt", clear

	drop if _n == 1
	
	drop if place_of_service == ""
	g inOffice = (place_of_service == "O")

	rename hcpcs_code    hcpcs
	rename line_srvc_cnt nServ_20`n'
	
	keep npi hcpcs inOffice nServ_20`n'
	
	bys npi hcpcs inOffice : assert _N == 1
	
	save "$temp/fg-nServ-20`n'", replace
	
}

clear
forvalues n = 12/13 {
	append using "$temp/fg-nServ-20`n'"
}

collapse (firstnm) nServ*, by(npi hcpcs inOffice)

ds nServ*
foreach var in `r(varlist)' {
	recode `var'(. = 0)
} 

* Merging on isEM:
merge m:1 hcpcs using "$temp/hcpcs-isEM"
drop if _merge == 2
drop    _merge

replace isEM = isEM == 1

* Restricting to FG's HCPCS codes:
merge m:1 hcpcs using "$temp/fg-hcpcs-codes"
keep if _merge == 3
drop    _merge

sort npi hcpcs inOffice

* Indicator: a new hcpcs for this npi
g isNewHcpcs_2012 = ///
	(nServ_2012 > 0 & npi != npi[_n-1]) | ///
	(nServ_2012 > 0 & npi == npi[_n-1] & hcpcs != hcpcs[_n-1])
	
g isNewHcpcs_2013 = ///
	(nServ_2013 > 0 & npi != npi[_n-1]) | ///
	(nServ_2013 > 0 & npi == npi[_n-1] & hcpcs != hcpcs[_n-1])
	
g isNewEM_2012 = isEM * isNewHcpcs_2012
g isNewEM_2013 = isEM * isNewHcpcs_2013

collapse (sum) ///
	S_nCode_2012   = isNewHcpcs_2012 ///
	S_nCodeEM_2012 = isNewEM_2012    ///
	S_nCode_2013   = isNewHcpcs_2013 ///
	S_nCodeEM_2013 = isNewEM_2013,   ///
	by(npi)

save "$temp/fg-nCodes", replace

use "$fang_gong_replication/output/phy_time", clear

keep npi nCode*

* Merge in my nCodes:
merge 1:1 npi using "$temp/fg-nCodes"
drop if _merge == 2
drop    _merge

* Equal:
forvalues j = 2012/2013 {
	
	assert S_nCode_`j'   == nCode_`j'
	assert S_nCodeEM_`j' == nCodeEM_`j'
	
}

*** 3) Translate to Emiel's data ***

* Modified from FG, think their code has coding mistake (discussed below)

forvalues n = 13/19 {

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

clear
forvalues n = 13/19 {
	append using "$temp/nServ-20`n'"
}

collapse (sum) nServ*, by(npi hcpcs)

// collapse (firstnm) nServ*, by(npi hcpcs inOffice)

// ds nServ*
// foreach var in `r(varlist)' {
// 	recode `var'(. = 0)
// }

* Merging on isEM:
merge m:1 hcpcs using "$temp/hcpcs-isEM"
drop if _merge == 2
drop    _merge

replace isEM = isEM == 1

* Restricting to FG's HCPCS codes:
merge m:1 hcpcs using "$temp/fg-hcpcs-codes"
keep if _merge == 3
drop    _merge

// sort npi hcpcs inOffice

bys npi hcpcs : assert _N == 1

forvalues n = 13/19 {

// 	g S_nCode_20`n' = /// FG calls this isNewHcpcs
// 		(nServ_20`n' > 0 & npi != npi[_n-1]) | ///
// 		(nServ_20`n' > 0 & npi == npi[_n-1] & hcpcs != hcpcs[_n-1])
//		
// 	g S_nCodeEM_20`n' = isEM * S_nCode_20`n' // FG calls this isNewEM

	* Indicator, doctor uses specific hcpcs:
	g S_nCode_20`n' = nServ_20`n' > 0
	
	g S_nCodeEM_20`n' = isEM * S_nCode_20`n'

}

collapse (sum) S_nCode*, by(npi)

save "$temp/nCodes", replace

use "$fang_gong_replication/output/phy_time", clear

* Merge in my nCodes:
merge 1:1 npi using "$temp/nCodes"
drop if _merge == 2

* NOT equal:

	assert S_nCode_2013   == nCode_2013
	assert S_nCodeEM_2013 == nCodeEM_2013

	assert S_nCode_2013   == nCode_2013   if _merge == 3
	assert S_nCodeEM_2013 == nCodeEM_2013 if _merge == 3

* Possible coding mistake in FG, for investigation:

*	Compare with above code when replicating FG
*	There, when defining isNewHcpcs_2013, look at for example:
* 	br if npi == 1003001645 & hcpcs == "99213"
*	There isNewHcpcs_2013 is zero for both rows which is not correct
*	Possibly, there are other qualitatively different errors


	
*** REGRESSIONS ***

use "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", clear

drop _merge

merge 1:1 npi using "$dropbox/FullData/RawData/CMS2013", keepusing(total_payments)
keep if _merge == 3
drop    _merge

merge 1:1 npi using "total_payments_full"
keep if _merge == 3
drop    _merge

merge 1:1 npi using "$temp/emiel-total_payments-fg-betos-codes"
keep if _merge == 3
drop    _merge

merge 1:1 npi using "$temp/emiel-total_payments-fg-hcpcs-codes-2013", keepusing(fg_hcpcs_total_payments)
keep if _merge == 3
drop    _merge

g orig_total_payments = total_payments

foreach j in total_payments total_payments_full fg_betos_total_payments fg_hcpcs_total_payments {
	replace `j' = `j' / 1000
}

rename gradYear grd_yr

recode dum_tuition2kincrease (. = 0)

egen grd_yrXphyspec = group(phySpec grd_yr)
egen grd_yrXhrr     = group(hrr     grd_yr)

global main_controls ///
	male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR PublicSchool

global FEs ///
	hrr phySpec grd_yr Tuition_quantile groupPAC grd_yrXphyspec
	
keep ///
	npi dum_tuition2kincrease ///
	totPaid_2012 totPaid_2013 orig_total_payments total_payments total_payments_full fg_betos_total_payments fg_hcpcs_total_payments ///
	$main_controls nCode_* nCodeEM_* ///
	$FEs

bys npi : assert _N == 1

foreach j in totPaid_2012 totPaid_2013 orig_total_payments total_payments total_payments_full fg_betos_total_payments fg_hcpcs_total_payments {
	
	if "`j'" == "totPaid_2012" {
		local controls $main_controls nCode_2012 nCodeEM_2012
	}
	else {
		local controls $main_controls nCode_2013 nCodeEM_2013
	}
	
	disp "BELOW = WITH CONTROLS"
	eststo clear // ssc install estout
	qui: eststo: reghdfe `j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe `j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe `j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe `j' dum_tuition2kincrease `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe `j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe `j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,                keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
}


*****

clear
forvalues n = 13/19 {
	
	append using "$temp/emiel-total_payments-fg-hcpcs-codes-20`n'"
	
}

replace fg_hcpcs_total_payments = fg_hcpcs_total_payments / 1000

// reshape wide fg_hcpcs_total_payments, i(npi) j(year)

save "emiel-total_payments-fg-hcpcs-codes", replace

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition-reproduces-emiel", clear

merge 1:1 npi year using "emiel-total_payments-fg-hcpcs-codes"
keep if _merge == 3
drop    _merge

// keep if inrange(grade, 1, 4) // cannot put directly into reghdfe

unique grade if grade != .
assert r(unique) == 8

sum grade
assert r(min) == -2 & r(max) == 6

replace tot_tuition = tot_tuition / 1000
replace grade = grade + 3

forvalues n = 2013/2019 {
	
	preserve
	
	keep if year == `n'
	
	foreach var in tot_tuition fg_hcpcs_total_payments {
	
		reghdfe `var' ib(7).grade, noabsorb

		coefplot, ///
			keep(*.grade) baselevels ///
			ci(95) vertical title("`var' -- `n' -- raw") ///
			yscale(range(-40 40)) ylabel(-40(10)40, format(%15.0fc)) ///
			xtitle("Grade group") ///
			xlabel(        ///
				1 "-2"     ///
				2 "-1"     ///
				3  "1 (T)" ///
				4  "2 (T)" ///
				5  "3 (T)" ///
				6  "4 (T)" ///
				7  "5"     ///
				8  "6")
				
		graph export "$git/plots/05-initial-analysis/raw-`var'-coefplot-`n'.jpg", replace
		
		reghdfe `var' ib(7).grade, absorb(med_school grd_yr)
		
		coefplot, ///
			keep(*.grade) baselevels ///
			ci(95) vertical title("`var' -- `n' -- FEs") ///
			yscale(range(-40 40)) ylabel(-40(10)40, format(%15.0fc)) ///
			xtitle("Grade group") ///
			xlabel(        ///
				1 "-2"     ///
				2 "-1"     ///
				3  "1 (T)" ///
				4  "2 (T)" ///
				5  "3 (T)" ///
				6  "4 (T)" ///
				7  "5"     ///
				8  "6")
		
		graph export "$git/plots/05-initial-analysis/FEs-`var'-coefplot-`n'.jpg", replace
	
	}
	
	foreach outcome in fg_hcpcs_total_payments {

		eststo clear
		qui: eststo: reghdfe `outcome' delta_tuition_dummy, noabsorb
		qui: eststo: reghdfe `outcome' delta_tuition_dummy, absorb(med_school grd_yr)
		esttab est*,              keep(delta_tuition_dummy) se star(* 0.10 ** 0.05 *** 0.01)
	
	}
	
	restore
	
}

preserve

foreach var in tot_tuition grade med_school grd_yr delta_tuition_dummy {
	
	bys npi (`var') : assert `var'[1] == `var'[_N]
	 
}

collapse ///
	(mean)  fg_hcpcs_total_payments ///
	(first) tot_tuition grade med_school grd_yr delta_tuition_dummy, ///
	by(npi)

foreach var in tot_tuition fg_hcpcs_total_payments {

		reghdfe `var' ib(7).grade, noabsorb

		coefplot, ///
			keep(*.grade) baselevels ///
			ci(95) vertical title("`var' -- panel mean by npi -- raw") ///
			yscale(range(-40 40)) ylabel(-40(10)40, format(%15.0fc)) ///
			xtitle("Grade group") ///
			xlabel(        ///
				1 "-2"     ///
				2 "-1"     ///
				3  "1 (T)" ///
				4  "2 (T)" ///
				5  "3 (T)" ///
				6  "4 (T)" ///
				7  "5"     ///
				8  "6")
		
		graph export "$git/plots/05-initial-analysis/raw-`var'-coefplot-collapsed.jpg", replace
		
		reghdfe `var' ib(7).grade, absorb(med_school grd_yr)

		coefplot, ///
			keep(*.grade) baselevels ///
			ci(95) vertical title("`var' -- panel mean by npi -- FEs") ///
			yscale(range(-40 40)) ylabel(-40(10)40, format(%15.0fc)) ///
			xtitle("Grade group") ///
			xlabel(        ///
				1 "-2"     ///
				2 "-1"     ///
				3  "1 (T)" ///
				4  "2 (T)" ///
				5  "3 (T)" ///
				6  "4 (T)" ///
				7  "5"     ///
				8  "6")
		
		graph export "$git/plots/05-initial-analysis/FEs-`var'-coefplot-collapsed.jpg", replace

}

foreach outcome in fg_hcpcs_total_payments {

	eststo clear
	qui: eststo: reghdfe `outcome' delta_tuition_dummy, noabsorb
	qui: eststo: reghdfe `outcome' delta_tuition_dummy, absorb(med_school grd_yr)
	esttab est*,              keep(delta_tuition_dummy) se star(* 0.10 ** 0.05 *** 0.01)

}

restore

* Include more FEs, try to include the same ones as before.

* nCode_2012 and nCodeEM_2012 are not number of codes but number of new codes for the doctor?
* See row 117 in FG's time_flag.do
* nCode_`j' nCodeEM_`j' seems important for the results in Emiel's Brown bag?


*************************
*** MORE CONTROLS/FEs ***
*************************

* Add delta_tuition_dummy people to the plot?
* Extend regressions in the other file to more years using new total_payments!

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition-reproduces-emiel", clear

* Restrict to Emiel's graduation years:
keep if inrange(grd_yr, 1997, 2011)

* For now, keep one observation per doctor:
bys npi (year) : keep if _n == 1

merge m:1 npi using "$fang_gong_replication/output/phy_time", ///
	keepusing( ///
		totPaid_2012 ///
		totPaid_2013 ///
		male         ///
		isMD         ///
		experYear    /// Maybe: g experYear = year - gradYear + 1
		nPhyInGroup  ///
		hosAff       ///
		inMedicare   ///
		inERX        ///
		inPQRS       ///
		inEHR        ///
		phySpec      ///
		groupPAC     ///
		nCode_*      /// not constant over time: see time_flag.do
		nCodeEM_*)    // not constant over time: see time_flag.do

keep if _merge == 3
drop    _merge
		
// rename gradYear grd_yr

egen grd_yrXphyspec = group(phySpec grd_yr)
egen grd_yrXhrr     = group(hrr     grd_yr)

// keep if inrange(grade, 1, 4) // cannot put directly into reghdfe

unique grade if grade != .
assert r(unique) == 8

sum grade
assert r(min) == -2 & r(max) == 6

replace tot_tuition = tot_tuition / 1000
replace grade = grade + 3

forvalues n = 2012/2013 {
	
	reghdfe totPaid_`n' ib(7).grade, noabsorb

	coefplot, ///
		keep(*.grade) baselevels ///
		ci(95) vertical title("New -- totPaid_`n' -- raw") ///
		yscale(range(-40 40)) ylabel(-40(10)40, format(%15.0fc)) ///
		xtitle("Grade group") ///
		xlabel(        ///
			1 "-2"     ///
			2 "-1"     ///
			3  "1 (T)" ///
			4  "2 (T)" ///
			5  "3 (T)" ///
			6  "4 (T)" ///
			7  "5"     ///
			8  "6")
			
	graph export "$git/plots/05-initial-analysis/new-raw-`var'-coefplot-`n'.jpg", replace
	
	local controls $main_controls nCode_`n' nCodeEM_`n'
	
	reghdfe totPaid_`n' ib(7).grade `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	
	coefplot, ///
		keep(*.grade) baselevels ///
		ci(95) vertical title("New -- totPaid_`n' -- FEs") ///
		yscale(range(-40 40)) ylabel(-40(10)40, format(%15.0fc)) ///
		xtitle("Grade group") ///
		xlabel(        ///
			1 "-2"     ///
			2 "-1"     ///
			3  "1 (T)" ///
			4  "2 (T)" ///
			5  "3 (T)" ///
			6  "4 (T)" ///
			7  "5"     ///
			8  "6")
	
	graph export "$git/plots/05-initial-analysis/new-FEs-`var'-coefplot-`n'.jpg", replace
	
}



