
****************************************
*** COMPARE EMIEL'S AND FG'S totPaid ***
****************************************

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

* Conclusion: Emiel's data is subset of FG's

* Extend this definition to later years? Is that what total_payments is?

// import delimited ///
// 	"$fang_gong_replication/input/Medicare_Provider_Util_Payment_PUF_CY2012.txt", ///
// 	clear rowrange(1:10)

*******************************************
*** COMPARE total_payments AND tot_Paid ***
*******************************************

use npi year total_payments using "$dropbox/FullDataCMSPANEL_final.dta", clear

keep if year == 13 // 2013

bys npi : assert _N == 1

preserve

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

recast double total_payments

assert total_payments == totPaid_2013 // false

// g delta = total_payments - totPaid_2013
//
// sum delta, d
//
// replace delta = r( p1) if delta < r( p1)
// replace delta = r(p99) if delta > r(p99)
//
// hist delta, bin(100)

replace total_payments = round(total_payments, 0.1)
replace totPaid_2013   = round(totPaid_2013  , 0.1)

assert total_payments == totPaid_2013 // false

assert total_payments < totPaid_2013 if total_payments != totPaid_2013


use "$temp/tot_amount_paid_2013", clear

merge 1:1 npi using "$fang_gong_replication/output/phy_time", keepusing(totPaid_2013)
keep if _merge == 3 // think about this?
drop    _merge

replace tot_amount_paid = tot_amount_paid / 1000 // to get same unit as totPaid

assert tot_amount_paid == totPaid_2013

g delta = tot_amount_paid - totPaid_2013

sum delta, d

replace delta = r( p1) if delta < r( p1)
replace delta = r(p99) if delta > r(p99)

hist delta, bin(100)


* Different variable names:
// Emiel: "MUP_PHY_R19_P04_V10_D`i'_Prov_Svc.csv"
// FG: "Medicare_Provider_Util_Payment_PUF_CY2013.txt"

* Different methods: Emiel -> codes and rowsum, FG -> collapse to tot.

import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D13_Prov_Svc.csv", clear

rename rndrng_npi npi
rename tot_srvcs amount_services

g tot_amount_paid             = amount_services * avg_mdcr_pymt_amt
g tot_amount_paid_standarized = amount_services * avg_mdcr_stdzd_amt // keeping typo

collapse (sum) tot_amount_paid*, by(npi)

save "$temp/tot_amount_paid_2013", replace

import delimited "$fang_gong_replication/input/Medicare_Provider_Util_Payment_PUF_CY2013.txt", clear

drop if _n == 1

g totPaid_replicate = line_srvc_cnt * average_medicare_payment_amt

collapse (sum) totPaid_replicate, by(npi)

merge 1:1 npi using "$temp/tot_amount_paid_2013"
keep if _merge == 3
drop    _merge

g same       = totPaid_replicate == tot_amount_paid
g same_stdzd = totPaid_replicate == tot_amount_paid_standarized

tab same      , m
tab same_stdzd, m

merge 1:1 npi using "$fang_gong_replication/output/phy_time", keepusing(totPaid_2013)
keep if _merge == 3
drop    _merge

replace totPaid_replicate = totPaid_replicate / 1000

assert totPaid_replicate == totPaid_2013

g totPaid_replicate_round = round(totPaid_replicate, 0.1)
g totPaid_2013_round      = round(totPaid_2013     , 0.1)

assert totPaid_replicate_round == totPaid_2013_round

g same_replicate_2013 = totPaid_replicate == totPaid_2013

format totPaid_replicate totPaid_2013 %12.0g // IMPORTANT!

br totPaid_replicate totPaid_2013 if same_replicate_2013 == 0




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

	assert totPaid > totPaid_2013 if totPaid != totPaid_2013 // probably just rounding...


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


* Tuesday:
*	Compare rounded total sums to avoid problems as above in this file
*	If rounded sums are different, is there some selection of what's included in sums?
* 	E.g. Emiel's loop for the BETOS code might not cover everything...
*	Maybe differences are small, what happens if we run regressions with FG's data?

*	And types + formats...
*	What happens if we run previous total_payments regressions but divide data with 1000 first?







************************************************
*** ... ***
************************************************

use "$temp/emiel-csv-2013-minimal", clear

g new_totPaid_2013 = tot_srvcs * avg_mdcr_pymt_amt

collapse (sum) new_totPaid_2013, by(npi)

save "new_totPaid_2013", replace

use "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", clear

drop _merge

merge 1:1 npi using "new_totPaid_2013"
keep if _merge == 3
drop    _merge

rename gradYear grd_yr

recode dum_tuition2kincrease (. = 0)

egen grd_yrXphyspec = group(phySpec grd_yr)
egen grd_yrXhrr     = group(hrr     grd_yr)

global main_controls ///
	male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR PublicSchool

global FEs ///
	hrr phySpec grd_yr Tuition_quantile groupPAC grd_yrXphyspec
	
keep ///
	npi dum_tuition2kincrease totPaid_2012 totPaid_2013 new_totPaid_2013 ///
	$main_controls nCode_* nCodeEM_* ///
	$FEs

bys npi : assert _N == 1

foreach j in totPaid_2013 new_totPaid_2013 {
	
	local controls $main_controls nCode_2013 nCodeEM_2013
	
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
