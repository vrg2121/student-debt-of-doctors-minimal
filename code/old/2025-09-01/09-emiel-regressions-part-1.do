
*********************************************************
*** Mail from Emiel -- Monday, 17 March 2025 at 15:55 ***
*********************************************************

cap log close
log using "$temp/tuition-regressions-2025-03-18.smcl", replace

global outcomes ///
	total_payments // total_amount_of_payment_usdollar servicesEM


*** PART 1 -- CROSS-SECTIONAL REGRESSIONS -- INCLUDES EVERYONE ***

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

* Missings:
// replace total_amount_of_payment_usdollar = 0 if total_amount_of_payment_usdollar == . // DON'T REPLACE HERE
   replace servicesEM                       = 0 if                       servicesEM == . //       REPLACE HERE

* Check so the following vars are unique within npi:
foreach var in tot_tuition grade grd_yr med_school {
	
	bys npi (`var') : assert `var'[1] == `var'[_N]
	 
}

g       increase_dummy = 1 if grade == 2
replace increase_dummy = 0 if grade == .

collapse ///
	(first) tot_tuition grade grd_yr med_school ///
	(mean)  $outcomes ///
	(first) pri_spec hrr ///    careful
	(max)   increase_dummy, /// careful
	by(npi)
	
tab grade, m // missing = no large tuition increase
	
* outcome = mean:
foreach outcome of global outcomes {

// 	reghdfe `outcome' tot_tuition, ///
// 		absorb(grd_yr med_school pri_spec hrr) vce(cluster med_school)
		
	reghdfe `outcome' increase_dummy, ///
		absorb(grd_yr med_school pri_spec hrr) vce(cluster med_school)
		
	* 1) ADD HRR + SPECIALTY FEs -- Emiel checks if these are available per npi!
	* 2) Replace tot_tuition with "large increase dummy"
	* 3) ADD MORE FEs ("QUARTILES" etc...)
	
}

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

g       increase_dummy = 1 if inrange(grade, 2, 2)
replace increase_dummy = 0 if grade == .

* outcome = yearly:
sum year
forvalues n = `r(min)'/`r(max)' {
	
	disp "year below: `n'"
	
	foreach outcome of global outcomes {
	
		reghdfe `outcome' tot_tuition    if year == `n', ///
			absorb(grd_yr med_school pri_spec hrr) vce(cluster med_school)
			
		reghdfe `outcome' increase_dummy if year == `n', ///
			absorb(grd_yr med_school pri_spec hrr) vce(cluster med_school)
	
	}
	
}


*** PART 2 -- IV REGRESSIONS -- GRADE GROUPS ***

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

* Missings:
// replace total_amount_of_payment_usdollar = 0 if total_amount_of_payment_usdollar == .
   replace servicesEM                       = 0 if                       servicesEM == .

collapse ///
	(first) tot_tuition grade grd_yr med_school ///
	(mean)  $outcomes, ///
	by(npi)

keep if inrange(grade, 2, 4)

tab grade, m

g grade_2 = grade == 2
g grade_3 = grade == 3
g grade_4 = grade == 4

tab grade_2 grade, m
tab grade_3 grade, m
tab grade_4 grade, m

foreach outcome of global outcomes {

	ivreghdfe ///
		`outcome' ///
		(tot_tuition = grade_2 grade_3 grade_4), ///
		absorb(grd_yr med_school) vce(cluster med_school)

}


*** QUESTIONS ***

* a) "All people" = schools without tuition increases + all grades?
* b) Treatment of total_amount_of_payment_usdollar and servicesEM?
* c) IV regression: panel or cross-section?

cap log close
