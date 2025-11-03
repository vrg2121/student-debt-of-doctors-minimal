
**************************************
*** RECREATING EMIEL'S REGRESSIONS ***
**************************************

use "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", clear

recode dum_tuition2kincrease (. = 0)

egen gradyearXphyspec = group(phySpec gradYear)
egen gradyearXhrr     = group(hrr     gradYear)

global main_controls ///
	male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR PublicSchool

global FEs ///
	hrr phySpec gradYear Tuition_quantile groupPAC gradyearXphyspec
	
keep ///
	npi dum_tuition2kincrease totPaid_2012 totPaid_2013 ///
	$main_controls nCode_* nCodeEM_* ///
	$FEs

* Emiel has many controls:
forvalues j = 2012/2013 {
	
	local controls $main_controls nCode_`j' nCodeEM_`j'
	
	eststo clear
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec gradYear)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec gradYear Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(    phySpec gradYear Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr gradyearXphyspec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr gradyearXphyspec Tuition_quantile)
	esttab est*,                keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
} // recreated results for 2012 -- results for 2013 less significant but directionally similar.

* Restrict to our doctors:
merge 1:m npi using "$git/data/working/FullDataCMSPANEL_final_subsample_tuition"
keep if _merge == 3
drop _merge

* Run for 2013:
keep if year == 2013
foreach outcome in totPaid_2013 total_payments total_amount_of_payment_usdollar {
	
	local controls $main_controls nCode_2013 nCodeEM_2013
	
	eststo clear
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec gradYear)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec gradYear Tuition_quantile)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(    phySpec gradYear Tuition_quantile groupPAC)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr gradyearXphyspec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr gradyearXphyspec Tuition_quantile)
	esttab est*,              keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
}

* Conclusion:
* 	totPaid_2013   					 -- similar as before
*	total_payments 					 -- similar when taking scale into account?
*	total_amount_of_payment_usdollar -- directionally different but weak significance


* Question: Can we easily make dummy matching Emiel's dummy?

* Based on max increase year and USD 4k limit -- stricter than Emiel:

disp $delta_tuition_limit

g increase_dummy = grade != .

tab increase_dummy dum_tuition2kincrease, m // a lot of disagreement -- not only stricter

* Answer: No, further investigation is needed!


*************************************
*** COMPARE EMIEL'S DATA WITH NEW ***
*************************************

* Recall that we for our panel, I have temporarily done the following to reproduce Emiel's data:
*	Changed to "Tuition" in AAMC selection (instead of e.g. "Tuition, Fees, and Health Insurance")
*	Restricted years for schools
* 	(Ignored an assert)

* Support file:
// use "$dropbox/FullDataCMSPANEL_final.dta", clear
//
// bys npi (grd_yr) : assert grd_yr[1] == grd_yr[_N]
//
// collapse (first) grd_yr, by(npi)
//
// save "$temp/grd_yr-npi", replace

cd "$temp"

import excel "$dropbox/Brown Bag presentation/PrelimData/medical schools.xlsx", clear firstrow

merge 1:m MedicalSchoolName using "$dropbox/Brown Bag presentation/PrelimData/tuitionPANEL.dta", nogen keep(match)

replace MedicalSchoolName = lower(MedicalSchoolName) // by SAP for later merge with new data

drop if medSchool == .

* Compute tuition changes
bys MedicalSchoolName (year) : g tuitionprev = tuition[_n - 1]
recode tuitionprev (0 = .) if tuitionprev == 0 // SAP: to avoid increases from zero, makes sense
by MedicalSchoolName : g tuition_increase_abs = tuition - tuitionprev

gen large_tuition_abs2000_ = year if tuition_increase_abs > 3499 & tuition_increase_abs != .

drop if year == 1996

keep MedicalSchoolName medSchool OwnershipType year tuition tuitionprev large_tuition_abs2000_

* Mark where chronological order is respected:
bys medSchool (year) : g med_school_chrono = year[_n] == year[_n - 1] + 1
	
* Total tuition during four years:
bys medSchool (year) : g tot_tuition = ///
	tuition[_n - 3] + ///
	tuition[_n - 2] + ///
	tuition[_n - 1] + ///
	tuition[_n - 0] if ///
		med_school_chrono[_n - 2] == 1 & ///
		med_school_chrono[_n - 1] == 1 & ///
		med_school_chrono[_n - 0] == 1

save "tuitionLONG_minimal", replace

	* Check -- increase dummy is the same in Emiel's panel and SAP's:
	replace large_tuition_abs2000_ = large_tuition_abs2000_ == year

	rename MedicalSchoolName med_school
	rename year grd_yr

	* Merge with SAP's new tuition panel:
	merge 1:1 med_school grd_yr using "$git/data/original/aamc/modified/aamc-tuition"
	keep if _merge == 3
	drop _merge

	g delta_tuition_dummy = delta_tuition > 3499 & delta_tuition != .

	tab    delta_tuition_dummy    large_tuition_abs2000_, m
	assert delta_tuition_dummy == large_tuition_abs2000_ // same!

* Continuing:
use "tuitionLONG_minimal", clear
	
drop tuition tuitionprev med_school_chrono tot_tuition

// replace tot_tuition = . if large_tuition_abs2000_ == .

reshape wide large_tuition_abs2000_, i(medSchool) j(year)

save "tuitionWIDE_minimal", replace

use "$dropbox/Brown Bag presentation/PrelimData/phy_time.dta", clear

drop if medSchool == 222
drop if gradYear < 1997

merge m:1 medSchool using "tuitionWIDE_minimal.dta"
keep if _merge == 3
drop _merge

	* Think about this, should be ok:
	// count

	rename gradYear year

	merge m:1 medSchool year using "tuitionLONG_minimal.dta", keepusing(tot_tuition)
	drop if _merge == 2 // note difference here from above merge!
	drop _merge

	rename year gradYear

	// count

* Added by SAP -- get grd_yr:
bys npi : assert _N == 1

merge 1:1 npi using "grd_yr-npi"
keep if _merge == 3
drop _merge

keep npi large_tuition_abs2000_* MedicalSchoolName gradYear grd_yr tot_tuition totPaid*

// save "dummy-investigation-file-2025-03-21", replace // see do-file 11
// use  "dummy-investigation-file-2025-03-21", clear

forval k = 0(1)6 { // changed
	
	forval i = 1997(1)2011 {
		g Atuition2kincrease`k'`i' = 1 if large_tuition_abs2000_`i' == gradYear - `k'     // Original: one-off error?
		g Btuition2kincrease`k'`i' = 1 if large_tuition_abs2000_`i' == grd_yr   - `k'
		g Ctuition2kincrease`k'`i' = 1 if large_tuition_abs2000_`i' == gradYear - `k' + 1
		g Dtuition2kincrease`k'`i' = 1 if large_tuition_abs2000_`i' == grd_yr   - `k' + 1 // New adjusted: grd_yr and plus one
	}
	
	egen Atuition2kincrease`k' = rowmax(Atuition2kincrease`k'*)
	egen Btuition2kincrease`k' = rowmax(Btuition2kincrease`k'*)
	egen Ctuition2kincrease`k' = rowmax(Ctuition2kincrease`k'*)
	egen Dtuition2kincrease`k' = rowmax(Dtuition2kincrease`k'*)

}

* Examples of where difference comes from, note:
* 	gradYear == grd_yr for both examples
* 	i == 2004 in both examples

* Example where Emiel sets missing (i.e. zero) and SAP sets 1 -- k = 1:
// br npi gradYear grd_yr large_tuition_abs2000_2004 ///
// 	Atuition2kincrease12004 ///
// 	Dtuition2kincrease12004 ///
// 	if npi == 1003991449

* Example where Emiel sets 1 and SAP sets missing (i.e. zero) -- k = 4:
// br npi gradYear grd_yr large_tuition_abs2000_2004 ///
// 	Atuition2kincrease42004 ///
// 	Dtuition2kincrease42004 ///
// 	if npi == 1003072687

egen Adum_tuition2kincrease = rowmax(Atuition2kincrease1 Atuition2kincrease2 Atuition2kincrease3 Atuition2kincrease4)
egen Ddum_tuition2kincrease = rowmax(Dtuition2kincrease1 Dtuition2kincrease2 Dtuition2kincrease3 Dtuition2kincrease4)

recode Adum_tuition2kincrease (. = 0)
recode Ddum_tuition2kincrease (. = 0)

tab Adum_tuition2kincrease Ddum_tuition2kincrease // not same!

keep npi *tuition2kincrease* MedicalSchoolName tot_tuition totPaid*

rename Adum_tuition2kincrease dum_tuition2kincrease_recreated

save "dum_tuition2kincrease_recreated", replace

	* Check in doctor panel -- recreated increase dummy is the same as in Emiel's old files:
	use "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", clear
	
	recode dum_tuition2kincrease (. = 0)
	
	drop _merge
	
	merge 1:1 npi using "dum_tuition2kincrease_recreated"
	assert _merge == 3
	drop _merge
	
	assert dum_tuition2kincrease_recreated == dum_tuition2kincrease // same!

	* Check in doctor panel -- adjusted increase dummy created above is the same as in SAP's panel:
	use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear // SAP panel

	merge m:1 npi using "dum_tuition2kincrease_recreated"
	keep if _merge == 3
	drop _merge

	foreach var in med_school grd_yr gradYear MedicalSchoolName delta_tuition_dummy grade {
	
		bys npi (`var') : assert `var'[1] == `var'[_N]
	 
	}
	
	collapse ///
		(max) *dum_tuition2kincrease* ///
		(first) med_school grd_yr gradYear MedicalSchoolName delta_tuition_dummy grade, ///
		by(npi)

	* Comparing dummy from SAP's doctor panel with adjusted dummy created above:
	tab    delta_tuition_dummy    Ddum_tuition2kincrease                                   , m
	tab    delta_tuition_dummy    Ddum_tuition2kincrease if med_school == MedicalSchoolName, m // only compare when name matching is ok
	assert delta_tuition_dummy == Ddum_tuition2kincrease if med_school == MedicalSchoolName    // same!
	
	g   increase_dummy = grade != .
	tab increase_dummy Ddum_tuition2kincrease if med_school == MedicalSchoolName, m
	
// 	br if ///
// 		increase_dummy         == 1 & ///
// 		Ddum_tuition2kincrease == 0 & ///
// 		med_school == MedicalSchoolName // investigate! npi == 1215099023, probably late year
	
// g max_tuition_increase_dummy = max_tuition_increase == grd_yr
//
// tab max_tuition_increase_dummy large_tuition_abs2000_, m
//
// br if delta_tuition_dummy == 1 & large_tuition_abs2000_ == 0
//
// br if med_school == "university of california, los angeles david geffen school of medicine"


***************************************
*** SANITY CHECK – PLOTS BY "GRADE" ***
***************************************

use "dum_tuition2kincrease_recreated", clear

bys npi : assert _N == 1

foreach ver in A B C D {
	
	* Note -- mapping 4 to 1 etc because of how the loop works:
	g 		grade =  .
	replace grade = -2 if `ver'tuition2kincrease6 == 1
	replace grade = -1 if `ver'tuition2kincrease5 == 1
	replace grade =  1 if `ver'tuition2kincrease4 == 1
	replace grade =  2 if `ver'tuition2kincrease3 == 1
	replace grade =  3 if `ver'tuition2kincrease2 == 1
	replace grade =  4 if `ver'tuition2kincrease1 == 1
	replace grade =  5 if `ver'tuition2kincrease0 == 1

	graph bar (mean) ///
		tot_tuition, ///
		over(grade) ///
		title("`ver' -- Mean total tuition") ///
		yscale(range(0 140000)) ///
		ylabel(0(20000)140000, format(%15.0fc)) ///
		legend(order( ///
			1 "Total tuition" ///
			))

	graph export "$git/plots/05-initial-analysis/version-`ver'-tot-tuition.jpg", replace
	
	forvalues n = 2012/2013 {
	
		graph bar (mean) ///
		totPaid_`n', ///
		over(grade) ///
		title("`ver' -- Mean totPaid_`n'") ///
		yscale(range(0 140)) ///
		ylabel(0(20)140, format(%15.0fc)) ///
		legend(order( ///
			1 "Total tuition" ///
			))

		graph export "$git/plots/05-initial-analysis/version-`ver'-totPaid`n'.jpg", replace
	
	}
	
	drop grade
	
}
		
use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear // SAP panel

// drop tot_tuition

merge m:1 npi using "dum_tuition2kincrease_recreated"
keep if _merge == 3
drop _merge

drop grade

foreach ver in A B C D {

	preserve

	g 		grade =  .
	replace grade = -2 if `ver'tuition2kincrease6 == 1
	replace grade = -1 if `ver'tuition2kincrease5 == 1
	replace grade =  1 if `ver'tuition2kincrease4 == 1
	replace grade =  2 if `ver'tuition2kincrease3 == 1
	replace grade =  3 if `ver'tuition2kincrease2 == 1
	replace grade =  4 if `ver'tuition2kincrease1 == 1
	replace grade =  5 if `ver'tuition2kincrease0 == 1

	* Check so var is unique within npi:
	foreach var in tot_tuition grade grd_yr our_med_school {
		
		bys npi (`var') : assert `var'[1] == `var'[_N]
		 
	}

	collapse ///
		(first) tot_tuition grade grd_yr our_med_school ///
		(mean)  mean_total_payments = total_payments, ///
		by(npi)
		
	graph bar (mean) ///
		tot_tuition, ///
		over(grade) ///
		title("`ver' -- Mean total tuition") ///
		yscale(range(0 140000)) ///
		ylabel(0(20000)140000, format(%15.0fc)) ///
		legend(order( ///
			1 "Total tuition" ///
			))

	graph export "$git/plots/05-initial-analysis/version-`ver'-tot-tuition-merged.jpg", replace

	graph bar (mean) ///
		mean_total_payments, ///
		over(grade) ///
		title("`ver' -- Mean mean total payments") ///
		yscale(range(0 140000)) ///
		ylabel(0(20000)140000, format(%15.0fc)) ///
		legend(order( ///
			1 "Mean total payments" ///
			))

	graph export "$git/plots/05-initial-analysis/version-`ver'-mean-total-payments-merged.jpg", replace
	
	restore
	
}


********************************************
*** RUN REGRESSIONS WITH UPDATED DUMMIES ***
********************************************

use "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", clear

recode dum_tuition2kincrease (. = 0)

drop _merge

merge 1:1 npi using "dum_tuition2kincrease_recreated"
assert _merge == 3
drop _merge

egen gradyearXphyspec = group(phySpec gradYear)
egen gradyearXhrr     = group(hrr     gradYear)
	
keep ///
	npi *dum_tuition2kincrease* totPaid_2012 totPaid_2013 ///
	$main_controls nCode_* nCodeEM_* ///
	$FEs

* Recreated dummy:
local dummy dum_tuition2kincrease_recreated
forvalues j = 2012/2013 {
	
	local controls $main_controls nCode_`j' nCodeEM_`j'
	
	eststo clear
	qui: eststo: reghdfe totPaid_`j' `dummy' `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' `dummy' `controls', cluster(hrr) a(hrr phySpec gradYear)
	qui: eststo: reghdfe totPaid_`j' `dummy' `controls', cluster(hrr) a(hrr phySpec gradYear Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' `dummy' `controls', cluster(hrr) a(    phySpec gradYear Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' `dummy' `controls', cluster(hrr) a(hrr gradyearXphyspec)
	qui: eststo: reghdfe totPaid_`j' `dummy' `controls', cluster(hrr) a(hrr gradyearXphyspec Tuition_quantile)
	esttab est*,                keep(`dummy') se star(* 0.10 ** 0.05 *** 0.01)
	
} // same results as before.

* Adjusted dummy:
local dummy Ndum_tuition2kincrease
forvalues j = 2012/2013 {
	
	local controls $main_controls nCode_`j' nCodeEM_`j'
	
	eststo clear
	qui: eststo: reghdfe totPaid_`j' `dummy' `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' `dummy' `controls', cluster(hrr) a(hrr phySpec gradYear)
	qui: eststo: reghdfe totPaid_`j' `dummy' `controls', cluster(hrr) a(hrr phySpec gradYear Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' `dummy' `controls', cluster(hrr) a(    phySpec gradYear Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' `dummy' `controls', cluster(hrr) a(hrr gradyearXphyspec)
	qui: eststo: reghdfe totPaid_`j' `dummy' `controls', cluster(hrr) a(hrr gradyearXphyspec Tuition_quantile)
	esttab est*,                keep(`dummy') se star(* 0.10 ** 0.05 *** 0.01)
	
} // weaker results.

* Restrict to our doctors:
merge 1:m npi using "$git/data/working/FullDataCMSPANEL_final_subsample_tuition"
keep if _merge == 3
drop _merge

* Run for 2013 with adjusted dummy -- several outcomes:
keep if year == 2013
local dummy Ndum_tuition2kincrease
foreach outcome in totPaid_2013 total_payments total_amount_of_payment_usdollar {
	
	local controls $main_controls nCode_2013 nCodeEM_2013
	
	eststo clear
	qui: eststo: reghdfe `outcome' `dummy' `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe `outcome' `dummy' `controls', cluster(hrr) a(hrr phySpec gradYear)
	qui: eststo: reghdfe `outcome' `dummy' `controls', cluster(hrr) a(hrr phySpec gradYear Tuition_quantile)
	qui: eststo: reghdfe `outcome' `dummy' `controls', cluster(hrr) a(    phySpec gradYear Tuition_quantile groupPAC)
	qui: eststo: reghdfe `outcome' `dummy' `controls', cluster(hrr) a(hrr gradyearXphyspec)
	qui: eststo: reghdfe `outcome' `dummy' `controls', cluster(hrr) a(hrr gradyearXphyspec Tuition_quantile)
	esttab est*,              keep(`dummy') se star(* 0.10 ** 0.05 *** 0.01)
	
} // even weaker results.

* Stricter dummy -- we have selected year of max percent increase in schools and demanded $4k increase:
g increase_dummy = grade != . // maybe ignore 1s etc?

local dummy increase_dummy
foreach outcome in totPaid_2013 total_payments total_amount_of_payment_usdollar {
	
	local controls $main_controls nCode_2013 nCodeEM_2013
	
	eststo clear
	qui: eststo: reghdfe `outcome' `dummy' `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe `outcome' `dummy' `controls', cluster(hrr) a(hrr phySpec gradYear)
	qui: eststo: reghdfe `outcome' `dummy' `controls', cluster(hrr) a(hrr phySpec gradYear Tuition_quantile)
	qui: eststo: reghdfe `outcome' `dummy' `controls', cluster(hrr) a(    phySpec gradYear Tuition_quantile groupPAC)
	qui: eststo: reghdfe `outcome' `dummy' `controls', cluster(hrr) a(hrr gradyearXphyspec)
	qui: eststo: reghdfe `outcome' `dummy' `controls', cluster(hrr) a(hrr gradyearXphyspec Tuition_quantile)
	esttab est*,              keep(`dummy') se star(* 0.10 ** 0.05 *** 0.01)
	
}
