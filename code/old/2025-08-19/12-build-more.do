

*** FOCUS ON SAMPLES 1 AND 2/3
*** Verify that replacements grd_yr/gradYear works well..!
***	RECALL: FOR SAMPLE 5/6, CHANGING THE CODING ERROR FROM grd_yr TO gradYear CHANGED COEFFICIENTS A LOT!
*** RETURN TO INVESTIGATE MERGE BELOW!


cap log close
log using "$temp/regressions-2025-03-26.smcl", replace

*************************
*** INVESTIGATE MERGE ***
*************************

* Get unique npi's from CMS:
// use "$dropbox/FullDataCMSPANEL_final.dta", clear
//
// keep npi
//
// bys npi : keep if _n == 1
//
// save "$temp/cms-unique-npi", replace
//
// * Brown bag is subset of CMS:
// use "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", clear
//
// bys npi : assert _N == 1
//
// drop _merge
//
// merge 1:1 npi using "$temp/cms-unique-npi"
//
// assert _merge != 1
//
// * Get unique npi's from our panel:
// use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition-reproduces-emiel", clear
//
// keep npi
//
// bys npi : keep if _n == 1
//
// save "$temp/our-panel-unique-npi", replace
//
// * Our panel is subset of CMS:
// use "$dropbox/FullDataCMSPANEL_final.dta", clear
//
// keep npi gradYear // using gradYear since we're now working with the original CMS data
//
// foreach var in gradYear {
//	
// 	bys npi (`var') : assert `var'[1] == `var'[_N]
//	 
// }
//
// bys npi : keep if _n == 1
//
// merge 1:1 npi using "$temp/our-panel-unique-npi"
//
// assert inlist(_merge, 1, 3)
//
//    assert gradYear != . if _merge == 3 // we delete observations where gradYear is missing
// // assert gradYear == . if _merge == 1 // not true, probably because we also delete doctors without tuition?
//
// tab _merge // doctor stats
//
// * Brown bag vs our panel:
// use "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", clear
//
// decode medSchool, generate(med_school_emiel)
//
// replace med_school_emiel = lower(med_school_emiel)
//
// drop _merge zip5
//
// merge 1:m npi using "$git/data/working/FullDataCMSPANEL_final_subsample_tuition-reproduces-emiel"
//
// foreach var in grd_yr {
//	
// 	bys npi (`var') : assert `var'[1] == `var'[_N]
//	 
// }
//
// bys npi : keep if _n == 1
//
// tab _merge
//
// tab grd_yr if _merge == 1, m sort
// tab grd_yr if _merge == 2, m sort
// tab grd_yr if _merge == 3, m sort
//
// assert         grd_yr == .         if _merge == 1 // all missing
// assert inrange(grd_yr, 1997, 2011) if _merge == 3 // Emiel probably restricted grad year to between 1997 and 2011
//
// // tab grd_yr if _merge == 2 & !inrange(grd_yr, 1997, 2011)
//
// * Restrict to Emiel's graduation years:
// keep if inrange(grd_yr, 1997, 2011)
//
// tab _merge
//
// g       data = "in current and brown bag" if _merge == 3
// replace data = "only in current"          if _merge == 2
//
// keep npi data
//
// merge 1:m npi using "$dropbox/FullDataCMSPANEL_final.dta"
// assert  _merge != 1
// keep if _merge == 3
// drop    _merge
//
// foreach var in gradYear { // using gradYear since we're now working with the original CMS data
//	
// 	bys npi (`var') : assert `var'[1] == `var'[_N]
//	 
// }
//
// assert gradYear != .
//
// bys npi (year) : keep if _n == 1
//
// tab data, m
//
// preserve
//
// use "$git/data/original/aamc/modified/aamc-tuition", clear
//
// keep med_school
//
// duplicates drop
//
// save "$temp/our-panel-unique-schools", replace
//
// use "tuitionLONG_minimal.dta", clear
//
// keep MedicalSchoolName
//
// rename MedicalSchoolName med_school
//
// duplicates drop
//
// save "$temp/emiel-unique-schools", replace
// use  "$temp/emiel-unique-schools", clear
//
// merge 1:1 med_school using "$temp/our-panel-unique-schools"
//
// g 		school_data = "both" if _merge == 3
// replace school_data = "only emiel"   if _merge == 1
// replace school_data = "only current" if _merge == 2
//
// drop _merge
//
// save "$temp/school-data", replace
//
// restore
//
// g med_school = lower(med_sch)
//
// merge m:1 med_school using "$temp/school-data"
//
// drop if _merge == 2
// drop _merge
//
// tab school_data, m
// tab        data, m
//
// tab school_data data, m
//
// // g same_med_school = med_school == med_school_emiel
// //
// // tab same_med_school _merge, m
// //
// // tab med_school_emiel if _merge == 1, m sort
// //
// // tab _merge inMedicare, m
// //
// // bys npi (year) : keep if _n == 1
// //
// // tab _merge, m
// //
// // assert grd_yr != . if _merge != 2
// //
// // tab _merge, m // how 
// //
// // drop if grd_yr == .
// //
// // tab _merge, m // how 


****************
*** SAMPLE 1 ***
****************

use "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", clear

rename gradYear grd_yr

recode dum_tuition2kincrease (. = 0)

egen grd_yrXphyspec = group(phySpec grd_yr)
egen grd_yrXhrr     = group(hrr     grd_yr)

global main_controls ///
	male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR PublicSchool

global FEs ///
	hrr phySpec grd_yr Tuition_quantile groupPAC grd_yrXphyspec
	
keep ///
	npi dum_tuition2kincrease totPaid_2012 totPaid_2013 ///
	$main_controls nCode_* nCodeEM_* ///
	$FEs

bys npi : assert _N == 1

forvalues j = 2012/2013 {
	
	local controls $main_controls nCode_`j' nCodeEM_`j'
	
	disp "BELOW = WITH CONTROLS"
	eststo clear // ssc install estout
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,                keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
	disp "BELOW = WITHOUT CONTROLS"
	eststo clear
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,                keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
} // recreated results for 2012 -- results for 2013 less significant but directionally similar.

*******************************
*** RESTRICT TO OUR DOCTORS ***
*******************************

merge 1:m npi using "$git/data/working/FullDataCMSPANEL_final_subsample_tuition-reproduces-emiel"
keep if _merge == 3
drop _merge

* Restrict to Emiel's graduation years:
// keep if inrange(grd_yr, 1997, 2011) // no effect

****************
*** SAMPLE 2 ***
****************

preserve

bys npi (year) : keep if _n == 1

foreach var in tot_tuition totPaid_2012 totPaid_2013 total_payments {

	if inlist("`var'", "totPaid_2012", "totPaid_2013") {

		graph bar (mean) ///
			`var', ///
			over(grade) ///
			title("Sample 2 – `var'") ///
			yscale(range(0 140)) ///
			ylabel(0(20)140, format(%15.0fc))
			
	}
	
	else {
		
		graph bar (mean) ///
			`var', ///
			over(grade) ///
			title("Sample 2 – `var'") ///
			yscale(range(0 140000)) ///
			ylabel(0(20000)140000, format(%15.0fc))
		
	}
		
	graph export "$git/plots/05-initial-analysis/sample-2-`var'.jpg", replace

}

forvalues j = 2012/2013 {
	
	local controls $main_controls nCode_`j' nCodeEM_`j'
	
	disp "BELOW = WITH CONTROLS"
	eststo clear
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,                keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
	disp "BELOW = WITHOUT CONTROLS"
	eststo clear
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,                keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
}

foreach outcome in total_payments {

	local controls $main_controls nCode_2013 nCodeEM_2013

	disp "BELOW = WITH CONTROLS"
	eststo clear
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,              keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)

	disp "BELOW = WITHOUT CONTROLS"
	eststo clear
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,              keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
}

keep if inrange(grade, 1, 4) // cannot put directly into reghdfe

foreach var in tot_tuition totPaid_2012 totPaid_2013 total_payments {
	
	reghdfe `var' ib(4).grade, absorb(med_school)
	
	if inlist("`var'", "totPaid_2012", "totPaid_2013") {

		coefplot, keep(1.grade 2.grade 3.grade) ci(95) vertical title("Sample 2 – `var'") /// ssc install coefplot
			yscale(range(-40 40)) ylabel(-40(10)40, format(%15.0fc))
	}
	
	else {
		
		coefplot, keep(1.grade 2.grade 3.grade) ci(95) vertical title("Sample 2 – `var'") ///
			yscale(range(-40000 40000)) ylabel(-40000(10000)40000, format(%15.0fc))
		
	}
	
	graph export "$git/plots/05-initial-analysis/sample-2-`var'-coefplot.jpg", replace
	
}

restore

****************
*** SAMPLE 3 ***
****************

preserve

keep if year == 2013

foreach var in tot_tuition totPaid_2012 totPaid_2013 total_payments {

	if inlist("`var'", "totPaid_2012", "totPaid_2013") {

		graph bar (mean) ///
			`var', ///
			over(grade) ///
			title("Sample 3 – `var'") ///
			yscale(range(0 140)) ///
			ylabel(0(20)140, format(%15.0fc))
			
	}
	
	else {
		
		graph bar (mean) ///
			`var', ///
			over(grade) ///
			title("Sample 3 – `var'") ///
			yscale(range(0 140000)) ///
			ylabel(0(20000)140000, format(%15.0fc))
		
	}
		
	graph export "$git/plots/05-initial-analysis/sample-3-`var'.jpg", replace

}

forvalues j = 2012/2013 {
	
	local controls $main_controls nCode_`j' nCodeEM_`j'
	
	disp "BELOW = WITH CONTROLS"
	eststo clear
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,                keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
	disp "BELOW = WITHOUT CONTROLS"
	eststo clear
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,                keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
}

foreach outcome in total_payments {

	local controls $main_controls nCode_2013 nCodeEM_2013

	disp "BELOW = WITH CONTROLS"
	eststo clear
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,              keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)

	disp "BELOW = WITHOUT CONTROLS"
	eststo clear
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,              keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
}

keep if inrange(grade, 1, 4) // cannot put directly into reghdfe

foreach var in tot_tuition totPaid_2012 totPaid_2013 total_payments {
	
	reghdfe `var' ib(4).grade, absorb(med_school)
	
	if inlist("`var'", "totPaid_2012", "totPaid_2013") {

		coefplot, keep(1.grade 2.grade 3.grade) ci(95) vertical title("Sample 3 – `var'") /// ssc install coefplot
			yscale(range(-40 40)) ylabel(-40(10)40, format(%15.0fc))
	}
	
	else {
		
		coefplot, keep(1.grade 2.grade 3.grade) ci(95) vertical title("Sample 3 – `var'") ///
			yscale(range(-40000 40000)) ylabel(-40000(10000)40000, format(%15.0fc))
		
	}
	
	graph export "$git/plots/05-initial-analysis/sample-3-`var'-coefplot.jpg", replace
	
}

restore

****************
*** SAMPLE 4 ***
****************

preserve

foreach var in tot_tuition totPaid_2012 totPaid_2013 grade dum_tuition2kincrease med_school {
	
	bys npi (`var') : assert `var'[1] == `var'[_N]
	 
}

sort npi year

collapse ///
	(first) tot_tuition totPaid_2012 totPaid_2013 grade dum_tuition2kincrease med_school /// constant
	(first) $main_controls nCode_* nCodeEM_* hrr phySpec grd_yr Tuition_quantile groupPAC grd_yrXphyspec /// uncertain if constant
	(mean)  total_payments, ///
	by(npi)

foreach var in tot_tuition totPaid_2012 totPaid_2013 total_payments {

	if inlist("`var'", "totPaid_2012", "totPaid_2013") {

		graph bar (mean) ///
			`var', ///
			over(grade) ///
			title("Sample 4 – `var'") ///
			yscale(range(0 140)) ///
			ylabel(0(20)140, format(%15.0fc))
			
	}
	
	else {
		
		graph bar (mean) ///
			`var', ///
			over(grade) ///
			title("Sample 4 – `var'") ///
			yscale(range(0 140000)) ///
			ylabel(0(20000)140000, format(%15.0fc))
		
	}
		
	graph export "$git/plots/05-initial-analysis/sample-4-`var'.jpg", replace

}

foreach outcome in total_payments {

	local controls $main_controls nCode_2013 nCodeEM_2013

	disp "BELOW = WITH CONTROLS"
	eststo clear
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,              keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)

	disp "BELOW = WITHOUT CONTROLS"
	eststo clear
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,              keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
}

keep if inrange(grade, 1, 4) // cannot put directly into reghdfe

foreach var in tot_tuition totPaid_2012 totPaid_2013 total_payments {
	
	reghdfe `var' ib(4).grade, absorb(med_school)
	
	if inlist("`var'", "totPaid_2012", "totPaid_2013") {

		coefplot, keep(1.grade 2.grade 3.grade) ci(95) vertical title("Sample 4 – `var'") /// ssc install coefplot
			yscale(range(-40 40)) ylabel(-40(10)40, format(%15.0fc))
	}
	
	else {
		
		coefplot, keep(1.grade 2.grade 3.grade) ci(95) vertical title("Sample 4 – `var'") ///
			yscale(range(-40000 40000)) ylabel(-40000(10000)40000, format(%15.0fc))
		
	}
	
	graph export "$git/plots/05-initial-analysis/sample-4-`var'-coefplot.jpg", replace
	
}

restore

*****************
*** SAMPLE 5A ***
*****************

preserve // should not be needed

foreach var in tot_tuition totPaid_2012 totPaid_2013 total_payments {

	if inlist("`var'", "totPaid_2012", "totPaid_2013") {

		graph bar (mean) ///
			`var', ///
			over(grade) ///
			title("Sample 5A – `var'") ///
			yscale(range(0 140)) ///
			ylabel(0(20)140, format(%15.0fc))
			
	}
	
	else {
		
		graph bar (mean) ///
			`var', ///
			over(grade) ///
			title("Sample 5A – `var'") ///
			yscale(range(0 140000)) ///
			ylabel(0(20000)140000, format(%15.0fc))
		
	}
		
	graph export "$git/plots/05-initial-analysis/sample-5A-`var'.jpg", replace

}

forvalues j = 2012/2013 {
	
	local controls $main_controls nCode_`j' nCodeEM_`j'
	
	disp "BELOW = WITH CONTROLS"
	eststo clear
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,                keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
	disp "BELOW = WITHOUT CONTROLS"
	eststo clear
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,                keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
}

foreach outcome in total_payments {

	local controls $main_controls nCode_2013 nCodeEM_2013

	disp "BELOW = WITH CONTROLS"
	eststo clear
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,              keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)

	disp "BELOW = WITHOUT CONTROLS"
	eststo clear
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe `outcome' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,              keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
}

keep if inrange(grade, 1, 4) // cannot put directly into reghdfe

foreach var in tot_tuition totPaid_2012 totPaid_2013 total_payments {
	
	reghdfe `var' ib(4).grade, absorb(med_school)
	
	if inlist("`var'", "totPaid_2012", "totPaid_2013") {

		coefplot, keep(1.grade 2.grade 3.grade) ci(95) vertical title("Sample 5A – `var'") /// ssc install coefplot
			yscale(range(-40 40)) ylabel(-40(10)40, format(%15.0fc))
	}
	
	else {
		
		coefplot, keep(1.grade 2.grade 3.grade) ci(95) vertical title("Sample 5A – `var'") ///
			yscale(range(-40000 40000)) ylabel(-40000(10000)40000, format(%15.0fc))
		
	}
	
	graph export "$git/plots/05-initial-analysis/sample-5A-`var'-coefplot.jpg", replace
	
}

restore

**************************************
*** COMPARE OUR DUMMY WITH EMIEL'S ***
**************************************

use "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", clear

recode dum_tuition2kincrease (. = 0)

decode medSchool, generate(med_school_emiel)

replace med_school_emiel = lower(med_school_emiel)

rename hrr hrr_emiel

decode phySpec, generate(phySpec_emiel)

keep npi dum_tuition2kincrease *_emiel

merge 1:m npi using "$git/data/working/FullDataCMSPANEL_final_subsample_tuition-reproduces-emiel"
keep if _merge == 3
drop _merge

* Should compare hrr_emiel with hrr and phySpec with pri_spec:
// restore
//
// keep if year == 2013
//
// assert hrr      == hrr_emiel     // not true
// assert pri_spec == phySpec_emiel // not true
//
// preserve

* Check so var is unique within npi:
foreach var in dum_tuition2kincrease med_school_emiel med_school grd_yr delta_tuition_dummy grade {
	
	bys npi (`var') : assert `var'[1] == `var'[_N]
	 
}

collapse ///
	(first) dum_tuition2kincrease med_school_emiel med_school grd_yr delta_tuition_dummy grade, ///
	by(npi)

* Comparing dummy from SAP's doctor panel with adjusted dummy created above:
tab    delta_tuition_dummy    dum_tuition2kincrease                                  , m
tab    delta_tuition_dummy    dum_tuition2kincrease if med_school == med_school_emiel, m // only compare when name matching is ok
assert delta_tuition_dummy == dum_tuition2kincrease if med_school == med_school_emiel    // same!

****************
*** SAMPLE 5 ***
****************

use "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", clear

rename gradYear grd_yr

recode dum_tuition2kincrease (. = 0)

egen grd_yrXphyspec = group(phySpec grd_yr)
egen grd_yrXhrr     = group(hrr     grd_yr)

global main_controls ///
	male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR PublicSchool

global FEs ///
	hrr phySpec grd_yr Tuition_quantile groupPAC grd_yrXphyspec
	
keep ///
	npi dum_tuition2kincrease totPaid_2012 totPaid_2013 ///
	$main_controls nCode_* nCodeEM_* ///
	$FEs

bys npi : assert _N == 1

forvalues j = 2012/2013 {
	
	local controls $main_controls nCode_`j' nCodeEM_`j'
	
	disp "BELOW = WITH CONTROLS"
	eststo clear // ssc install estout
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,                keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
}

merge 1:m npi using "$git/data/working/FullDataCMSPANEL_final_subsample_tuition-reproduces-emiel"
keep if _merge == 3
drop _merge

bys npi (year) : keep if _n == 1

forvalues j = 2012/2013 {
	
	local controls $main_controls nCode_`j' nCodeEM_`j'
	
	disp "BELOW = WITH CONTROLS"
	eststo clear
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,                keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
	
}

forvalues j = 2012/2013 {
	
	local controls $main_controls nCode_`j' nCodeEM_`j'
	
	disp "BELOW = WITH CONTROLS"
	eststo clear
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,                keep(delta_tuition_dummy) se star(* 0.10 ** 0.05 *** 0.01)
	
}

* Question: Fix experYear?

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition-reproduces-emiel", clear

* Restrict to Emiel's graduation years:
keep if inrange(grd_yr, 1997, 2011)

* Merge in my nCodes:
merge m:1 npi using "$temp/nCodes"
drop if _merge == 2
drop    _merge

* Think about this:
forvalues j = 2013/2019 {
	
	replace S_nCode_`j'   = 0 if S_nCode_`j'   == .
	replace S_nCodeEM_`j' = 0 if S_nCodeEM_`j' == .
	
}

* Merge in my new payments variable:
merge 1:1 npi year using "emiel-total_payments-fg-hcpcs-codes"
keep if _merge == 3
drop    _merge

* Merge in FG's controls:
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

preserve

* For now, keep one observation per doctor:
bys npi (year) : keep if _n == 1

merge 1:1 npi using "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", keepusing(dum_tuition2kincrease)
keep if _merge == 3
drop    _merge

forvalues j = 2012/2013 {

	local controls $main_controls nCode_`j' nCodeEM_`j'

	disp "BELOW = WITH CONTROLS"
	eststo clear
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,              keep(delta_tuition_dummy) se star(* 0.10 ** 0.05 *** 0.01)

}

recode dum_tuition2kincrease (. = 0)
forvalues j = 2012/2013 {

	local controls $main_controls nCode_`j' nCodeEM_`j'

	disp "BELOW = WITH CONTROLS"
	eststo clear
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,              keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)

}

restore

preserve

* For now, keep one observation per doctor:
bys npi (year) : keep if _n == 1

forvalues j = 2012/2013 {

	local controls $main_controls nCode_`j' nCodeEM_`j'

	eststo clear
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,              keep(delta_tuition_dummy) se star(* 0.10 ** 0.05 *** 0.01)

}

forvalues j = 2013/2013 {

	local controls $main_controls S_nCode_`j' S_nCodeEM_`j' // my nCodes

	disp "BELOW = WITH CONTROLS"
	eststo clear
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe totPaid_`j' delta_tuition_dummy `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,              keep(delta_tuition_dummy) se star(* 0.10 ** 0.05 *** 0.01)

}

restore

local outcome totPaid_2013
forvalues j = 2013/2013 {
	
	preserve
	
	keep if year == `j'

	local controls $main_controls S_nCode_`j' S_nCodeEM_`j' // my nCodes

	disp ""
	disp "BELOW = `j'"
	
	eststo clear
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,              keep(delta_tuition_dummy) se star(* 0.10 ** 0.05 *** 0.01)

	restore
	
}

local outcome fg_hcpcs_total_payments
forvalues j = 2013/2019 {
	
	preserve
	
	keep if year == `j'

	local controls $main_controls S_nCode_`j' S_nCodeEM_`j' // my nCodes

	disp ""
	disp "BELOW = `j'"
	disp ""
	
	eststo clear
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,              keep(delta_tuition_dummy) se star(* 0.10 ** 0.05 *** 0.01)

	restore
	
}


*** LATER YEARS ***

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition-reproduces-emiel", clear

* Restrict to Emiel's graduation years:
keep if inrange(grd_yr, 1997, 2011)

* For now, keep one observation per doctor:
// bys npi (year) : keep if _n == 1

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

merge 1:1 npi year using "emiel-total_payments-fg-hcpcs-codes"
keep if _merge == 3
drop    _merge

local outcome fg_hcpcs_total_payments
forvalues j = 2013/2013 { // 2019
	
	preserve
	
	keep if year == `j'

	local controls $main_controls // nCode_`j' nCodeEM_`j'

	disp "BELOW = `j' WITH CONTROLS"
	eststo clear
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec grd_yr)
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(hrr grd_yrXphyspec)
	qui: eststo: reghdfe `outcome' delta_tuition_dummy `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,              keep(delta_tuition_dummy) se star(* 0.10 ** 0.05 *** 0.01)

	restore
	
}

****************
*** SAMPLE 6 ***
****************

preserve

foreach var in tot_tuition grade delta_tuition_dummy grd_yr med_school {
	
	bys npi (`var') : assert `var'[1] == `var'[_N]
	 
}

sort npi year

collapse ///
	(first) tot_tuition grade delta_tuition_dummy grd_yr med_school /// constant
	(first) hrr phySpec /// uncertain if constant
	(mean)  total_payments, ///
	by(npi)

foreach var in tot_tuition total_payments {

	if inlist("`var'", "totPaid_2012", "totPaid_2013") {

		graph bar (mean) ///
			`var', ///
			over(grade) ///
			title("Sample 6 – `var'") ///
			yscale(range(0 140)) ///
			ylabel(0(20)140, format(%15.0fc))
			
	}
	
	else {
		
		graph bar (mean) ///
			`var', ///
			over(grade) ///
			title("Sample 6 – `var'") ///
			yscale(range(0 140000)) ///
			ylabel(0(20000)140000, format(%15.0fc))
		
	}
		
	graph export "$git/plots/05-initial-analysis/sample-6-`var'.jpg", replace

}

foreach outcome in total_payments {

	disp "BELOW = WITHOUT CONTROLS"
	eststo clear
	qui: eststo: reghdfe `outcome' delta_tuition_dummy, cluster(hrr) a(hrr phySpec)
	qui: eststo: reghdfe `outcome' delta_tuition_dummy, cluster(hrr) a(hrr phySpec grd_yr)
// 	qui: eststo: reghdfe `outcome' delta_tuition_dummy, cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
// 	qui: eststo: reghdfe `outcome' delta_tuition_dummy, cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
// 	qui: eststo: reghdfe `outcome' delta_tuition_dummy, cluster(hrr) a(hrr grd_yrXphyspec)
// 	qui: eststo: reghdfe `outcome' delta_tuition_dummy, cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
	esttab est*,              keep(delta_tuition_dummy) se star(* 0.10 ** 0.05 *** 0.01)
	
}

keep if inrange(grade, 1, 4) // cannot put directly into reghdfe

foreach var in tot_tuition total_payments {
	
	reghdfe `var' ib(4).grade, absorb(med_school)
	
	if inlist("`var'", "totPaid_2012", "totPaid_2013") {

		coefplot, keep(1.grade 2.grade 3.grade) ci(95) vertical title("Sample 6 – `var'") /// ssc install coefplot
			yscale(range(-40 40)) ylabel(-40(10)40, format(%15.0fc))
	}
	
	else {
		
		coefplot, keep(1.grade 2.grade 3.grade) ci(95) vertical title("Sample 6 – `var'") ///
			yscale(range(-40000 40000)) ylabel(-40000(10000)40000, format(%15.0fc))
		
	}
	
	graph export "$git/plots/05-initial-analysis/sample-6-`var'-coefplot.jpg", replace
	
}

restore


****************
*** SAMPLE 7 ***
****************

// use "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", clear
//
// drop _merge
//
// rename gradYear grd_yr
//
// recode dum_tuition2kincrease (. = 0)
//
// egen grd_yrXphyspec = group(phySpec grd_yr)
// egen grd_yrXhrr     = group(hrr     grd_yr)
//
// rename totPaid_* totPaid_*_emiel
//
// merge 1:1 npi using "$fang_gong_replication/output/phy_time", ///
// 	keepusing(totPaid_2012 totPaid_2013)
// keep if _merge == 3 // think about this?
// drop    _merge
//
// forvalues j = 2012/2013 {
//	
// 	local controls $main_controls nCode_`j' nCodeEM_`j'
//	
// 	disp "BELOW = WITH CONTROLS"
// 	eststo clear // ssc install estout
// 	qui: eststo: reghdfe totPaid_`j'_emiel dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec)
// 	qui: eststo: reghdfe totPaid_`j'_emiel dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr)
// 	qui: eststo: reghdfe totPaid_`j'_emiel dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
// 	qui: eststo: reghdfe totPaid_`j'_emiel dum_tuition2kincrease `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
// 	qui: eststo: reghdfe totPaid_`j'_emiel dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec)
// 	qui: eststo: reghdfe totPaid_`j'_emiel dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
// 	esttab est*,                keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
//	
// 	disp "BELOW = WITHOUT CONTROLS"
// 	eststo clear
// 	qui: eststo: reghdfe totPaid_`j'_emiel dum_tuition2kincrease, cluster(hrr) a(hrr phySpec)
// 	qui: eststo: reghdfe totPaid_`j'_emiel dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr)
// 	qui: eststo: reghdfe totPaid_`j'_emiel dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
// 	qui: eststo: reghdfe totPaid_`j'_emiel dum_tuition2kincrease, cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
// 	qui: eststo: reghdfe totPaid_`j'_emiel dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec)
// 	qui: eststo: reghdfe totPaid_`j'_emiel dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
// 	esttab est*,                keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
//	
// }
//
// forvalues j = 2012/2013 {
//	
// 	local controls $main_controls nCode_`j' nCodeEM_`j'
//	
// 	disp "BELOW = WITH CONTROLS"
// 	eststo clear // ssc install estout
// 	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec)
// 	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr)
// 	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
// 	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
// 	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec)
// 	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease `controls', cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
// 	esttab est*,                keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
//	
// 	disp "BELOW = WITHOUT CONTROLS"
// 	eststo clear
// 	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec)
// 	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr)
// 	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
// 	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
// 	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec)
// 	qui: eststo: reghdfe totPaid_`j' dum_tuition2kincrease, cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
// 	esttab est*,                keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
//	
// }

cap log close







// use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear // SAP panel
//
// // drop tot_tuition
//
// merge m:1 npi using "dum_tuition2kincrease_recreated"
// keep if _merge == 3
// drop _merge
//
// * Check so var is unique within npi:
// foreach var in tot_tuition grade grd_yr our_med_school {
//	
// 	bys npi (`var') : assert `var'[1] == `var'[_N]
//	 
// }
//
// collapse ///
// 	(first) tot_tuition grade grd_yr our_med_school ///
// 	(mean)  mean_total_payments = total_payments, ///
// 	by(npi)
//	
// graph bar (mean) ///
// 	tot_tuition, ///
// 	over(grade) ///
// 	title("A -- Mean total tuition") ///
// 	yscale(range(0 140000)) ///
// 	ylabel(0(20000)140000, format(%15.0fc)) ///
// 	legend(order( ///
// 		1 "Total tuition" ///
// 		))
//
// graph export "$git/plots/05-initial-analysis/new-tot-tuition-merged.jpg", replace
//
// graph bar (mean) ///
// 	mean_total_payments, ///
// 	over(grade) ///
// 	title("A -- Mean mean total payments") ///
// 	yscale(range(0 140000)) ///
// 	ylabel(0(20000)140000, format(%15.0fc)) ///
// 	legend(order( ///
// 		1 "Mean total payments" ///
// 		))
//
// graph export "$git/plots/05-initial-analysis/new-mean-total-payments-merged.jpg", replace
//
//
// * Steps:
//
// * 	Reproduce dummy
// *	Reproduce tot_paid regression
// * 	Run total_payments regression
// *	Plots for reproduced
//
// *	Do we have controls in CMS panel?
// *	Extend total_payments regression (w or w/o controls) to our data
// *	Plots for whole data
//
// *	Talk with Marieke tomorrow (Thursday) about late meeting with Emiel on Friday?
//
//
//
//
