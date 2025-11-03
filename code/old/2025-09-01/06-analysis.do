
*************
*** TO DO ***
*************

* DONE:
* Characteristics (controls) are missing for some years, extend etc
* Adding FEs to IV and reghdfe fg_sel1_total_payments ib(5).grade regressions
* ACA -- implement

* NOT DONE:
* Size of tuition increase vs jumps in first stage -- looks OK
* inERX etc dummies, try without

* NOTES:
* For reproducing Excels, remember experYear + male/isMD + no grade restriction + USD 3 499!


***************
*** GLOBALS ***
***************

// global dollar_limit = 1
//
// do "$git/code/current/05-create-final-dr-panel.do"

* Controls:
global main_controls ///
	male isMD nPhyInGroup hosAff inMedicare inERX inPQRS inEHR // experYear

global controls ///
	$main_controls ///
	S_nCode S_nCodeEM
// 	PublicSchool

global controls

* Outcomes:
global selected_outcomes ///
	fg_sel1_total_payments ///
	fg_sel5_total_payments ///
	fg_sel6_total_payments ///
	pp_quotient ///
	pp_payment
	
* FEs:
// global FEs `"      "med_school grd_yr" "'
// global FEs `" $FEs "med_school grd_yr hrr phySpec" "'
// global FEs `" $FEs "med_school grd_yr     phySpec groupPAC" "'
// global FEs `" $FEs "med_school        hrr grd_yrXphyspec" "'

global FEs `"      "med_school" "'
global FEs `" $FEs "med_school phySpec" "'
global FEs `" $FEs "med_school phySpec hrr" "'
global FEs `" $FEs "med_school phySpec groupPAC" "'


************
*** DATA ***
************

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

* Constant controls:
foreach var of global const_vars {
	drop   `var'
	rename `var'_const `var'
}

* Controls are properly defined:
// sum $controls

* (School, grad year) pairs:
egen med_schoolXgrd_yr = group(med_school grd_yr)


*********************
*** OPEN ACA LOOP ***
*********************

// // forvalues n = 1/2 {
//    forvalues n = 1/1 {
//	
// 	preserve
//	
// 	if `n' == 1 {
//		
// 		local aca_adjustment "NOT ACA ADJUSTED"
//		
// 	}
//	
// 	else {
//		
// 		local aca_adjustment "ACA ADJUSTED"
//		
// 		keep if ACA_adjusted == 1
//		
// 	}
//
// 	cap log close
// 	log using ///
// 		"$temp/tuition-`aca_adjustment'-$dollar_limit.smcl", ///
// 		replace	
//
// 	disp ""
// 	disp "`aca_adjustment'"
// 	disp "Tuition Increase Limit = USD $dollar_limit"
// 	disp ""
	

*******************
*** FIRST STAGE ***
*******************

* Panel structure:
// br npi grade grd_yr med_school year tuition_bill fg_sel1_total_payments
//
// forvalues n = 2/4 {
//	
// 	cap drop grade_change_`n'
// 	g        grade_change_`n' = grade == `n'
//	
// }
//
// // preserve
// // bys npi (year) : keep if _n == 1
//
// * Reg 1 and 2 are the same but omits an extra grade:
// foreach var in tuition_bill fg_sel1_total_payments {
//
// 	* Reg 1:
// // 	reghdfe `var'  grade_change_2 grade_change_3 grade_change_4, cl(`cluster_var') a(`fe')
// 	reghdfe ///
// 		`var' ///
// 		grade_change_2 grade_change_3 grade_change_4, ///
// 		cl(med_school) absorb(med_school grd_yr)
//
// 	* Reg 2:
// 	reghdfe ///
// 		`var' ///
// 		ib(5).grade, ///
// 		cl(med_school) absorb(med_school grd_yr)
//		
// }
//
// * Reg 1 and 2 are the same and this works:
// foreach var in tuition_bill fg_sel1_total_payments {
//
// 	* Reg 1:
// // 	reghdfe `var'  grade_change_2 grade_change_3 grade_change_4, cl(`cluster_var') a(`fe')
// 	reghdfe ///
// 		`var' ///
// 		grade_change_2 grade_change_3 grade_change_4, ///
// 		cl(med_school) absorb(med_school)
//
// 	* Reg 2:
// 	reghdfe ///
// 		`var' ///
// 		ib(5).grade, ///
// 		cl(med_school) absorb(med_school)
//		
// }
//
// * What about this?
// // cap drop cluster_college
// // encode(college_code_branch), g(cluster_college)
// // egen college_fixed_effect = group(college_code_branch)
//
// cap drop cluster_college
// cap drop college_fixed_effect
// encode(med_school), g(cluster_college)
// egen college_fixed_effect = group(med_school)
//
// * Still -- Reg 1 and 2 are the same but omits an extra grade:
// foreach var in tuition_bill fg_sel1_total_payments {
//
// 	* Reg 1:
// // 	reghdfe `var'  grade_change_2 grade_change_3 grade_change_4, cl(`cluster_var') a(`fe')
// 	reghdfe ///
// 		`var' ///
// 		grade_change_2 grade_change_3 grade_change_4, ///
// 		cl(cluster_college) absorb(college_fixed_effect grd_yr)
//
// 	* Reg 2:
// 	reghdfe ///
// 		`var' ///
// 		ib(5).grade, ///
// 		cl(cluster_college) absorb(college_fixed_effect grd_yr)
//		
// }

// restore


*** CONTINUNING ***

// bys npi : keep if _n == 1

foreach var in tuition_bill fg_sel3_total_payments {
// foreach var of global selected_outcomes {

	reghdfe ///
		`var' ///
		ib(5).grade, ///
		cl(med_school) absorb(med_school /* grd_yr */)

	coefplot, keep(2.grade 3.grade 4.grade) ci(95) vertical ///
		title("`var' -- `aca_adjustment' -- Limit = USD $dollar_limit")

// 	graph export "$git/plots/`var'-`aca_adjustment'-$dollar_limit.jpg", replace
	graph export "$git/plots/`var'-`aca_adjustment'.jpg", replace
	
}

forvalues n = 2012/2013 {
	
	preserve
	
	keep if year == `n'
	
	foreach var in tuition_bill fg_sel3_total_payments {

		reghdfe ///
			`var' ///
			ib(5).grade, ///
			cl(med_school) absorb(med_school /* grd_yr */)

		coefplot, keep(2.grade 3.grade 4.grade) ci(95) vertical ///
			title("`n' -- `var' -- `aca_adjustment' -- Limit = USD $dollar_limit")

		graph export "$git/plots/`n'-`var'-`aca_adjustment'-$dollar_limit.jpg", replace
		
	}
	
	restore
	
}


*******************
*** REGRESSIONS ***
*******************

// disp ""
// disp "Outcome on instrument:"
// disp ""
//
// eststo clear
//
// foreach FE of global FEs {
//	
// 	eststo : reghdfe ///
// 		fg_sel1_total_payments ///
// 		ib(5).grade $controls, ///
// 		cl(med_schoolXgrd_yr) absorb(`FE')
//	
// }
//
// esttab est*, keep(*.grade) p star(* 0.10 ** 0.05 *** 0.01) label
//
//
// disp ""
// disp "Outcome on delta tuition dummy:"
// disp ""
//
// tab grade delta_tuition_dummy, m
//
// eststo clear
//
// foreach FE of global FEs {
//	
// 	eststo : reghdfe ///
// 		fg_sel1_total_payments ///
// 		delta_tuition_dummy $controls, ///
// 		cl(med_schoolXgrd_yr) absorb(`FE')
//
// }
//
// esttab est*, keep(delta_tuition_dummy) p star(* 0.10 ** 0.05 *** 0.01) label
//
//
// disp ""
// disp "Outcome on endogenous variable (naive aka reduced form regression):"
// disp ""
//
// eststo clear
//
// foreach FE of global FEs {
//	
// 	eststo : reghdfe ///
// 		fg_sel1_total_payments ///
// 		tuition_bill $controls, ///
// 		cl(med_schoolXgrd_yr) absorb(`FE')
//		
// }
//
// esttab est*, keep(tuition_bill) p star(* 0.10 ** 0.05 *** 0.01) label


disp ""
disp "IV:"
disp ""

foreach outcome of global selected_outcomes {

	disp ""
	disp "Outcome = `: variable label `outcome''"
	disp ""

	eststo clear

	foreach FE of global FEs {

		qui : eststo : ivreghdfe ///
			`outcome' ///
			(tuition_bill = i.grade) $controls, /// controls here?
			cl(med_schoolXgrd_yr) absorb(`FE')

	}

	disp ""
	disp "Outcome = `: variable label `outcome''"
	disp "Explained by = `: variable label tuition_bill'"
	
	esttab est*, keep(tuition_bill) p star(* 0.10 ** 0.05 *** 0.01) label

}
	

forvalues n = 2012/2013 {
	
	disp ""
	disp "IV `n':"
	disp ""

	preserve
	
	keep if year == `n'
	
	foreach outcome of global selected_outcomes {

		disp ""
		disp "Outcome = `: variable label `outcome''"
		disp ""

		eststo clear

		foreach FE of global FEs {

			qui : eststo : ivreghdfe ///
				`outcome' ///
				(tuition_bill = i.grade) $controls, /// controls here?
				cl(med_schoolXgrd_yr) absorb(`FE')

		}

		disp ""
		disp "Outcome = `: variable label `outcome''"
		disp "Explained by = `: variable label tuition_bill'"
		
		esttab est*, keep(tuition_bill) p star(* 0.10 ** 0.05 *** 0.01) label

	}
	
	restore
	
}
	
// disp ""
// disp "REMOVE ONE CONTROL AT A TIME FROM IV:"
// disp ""
//
// foreach control of global controls {
//
// 	disp ""
// 	disp "`control' IS REMOVED BELOW:"
// 	disp ""
//
// 	local new_controls
// 	foreach new_control of global controls {
// 		if "`new_control'" != "`control'" {
// 			local new_controls `new_controls' `new_control'
// 		}
// 	}
//
// 	eststo clear
//
// 	foreach FE of global FEs {
//
// 		qui : eststo : ivreghdfe ///
// 			fg_sel1_total_payments ///
// 			(tuition_bill = i.grade) `new_controls', /// controls here?
// 			cl(med_schoolXgrd_yr) absorb(`FE')
//
// 	}
//
// 	disp ""
// 	disp "SUMMARY BELOW WHEN `control' IS REMOVED:"
// 	disp ""
//	
// 	disp ""
// 	disp "Outcome = `: variable label fg_sel1_total_payments'"
// 	disp "Explained by = `: variable label tuition_bill'"
//	
// 	esttab est*, keep(tuition_bill) p star(* 0.10 ** 0.05 *** 0.01) label
//
// }


**********************
*** CLOSE ACA LOOP ***
**********************

// 	restore
//	
// 	log close
//
// }


**********************************
*** LOW-HANGING FRUIT TO MATCH ***
**********************************

use "$temp/delta-tuition-dummy", clear


**************************
*** EVENTTIME -- WRONG ***
**************************

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

g event_time = year - grd_yr

br event_time grd_yr year grade

collapse (mean) fg_sel1_total_payments, by(grd_yr /* med_school */ grade event_time)

sum grd_yr, d
forvalues n = 2007/`r(max)' {

	preserve

	keep if inrange(event_time, -5, 5)
	keep if grd_yr == `n'

	twoway ///
		scatter fg_sel1_total_payments event_time if grade ==  2, lcolor(blue)   || ///
		scatter fg_sel1_total_payments event_time if grade ==  3, lcolor(green)  || ///
		scatter fg_sel1_total_payments event_time if grade ==  4, lcolor(red)    || ///
		scatter fg_sel1_total_payments event_time if grade ==  5, lcolor(black)     ///
		legend(order(1 "Grade 2" 2 "Grade 3" 3 "Grade 4" 4 "Grade 5")) ///
		xlabel(-5(1)5) ///
		ylabel(0(50)200) ///
		title("grd_yr = `n'")
		
	graph export "$git/plots/`n'-eventtime.jpg", replace
	
	restore

}


use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

g event_time = year - grd_yr

br event_time grd_yr year grade

collapse (mean) fg_sel1_total_payments, by(grade event_time)

keep if inrange(event_time, -5, 5)

twoway ///
	scatter fg_sel1_total_payments event_time if grade ==  2, lcolor(blue)   || ///
	scatter fg_sel1_total_payments event_time if grade ==  3, lcolor(green)  || ///
	scatter fg_sel1_total_payments event_time if grade ==  4, lcolor(red)    || ///
	scatter fg_sel1_total_payments event_time if grade ==  5, lcolor(black)     ///
	legend(order(1 "Grade 2" 2 "Grade 3" 3 "Grade 4" 4 "Grade 5")) ///
	xlabel(-5(1)5)
	
graph export "$git/plots/eventtime.jpg", replace


*******************
*** EVENTTIME 2 ***
*******************

*** 2011-2015 ***

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

// g event_time = year - grd_yr

// br npi grd_yr increase_year grade year event_time

// g outcome_missing = fg_sel3_total_payments == .
//
// tab year outcome_missing, m
//
// tab grd_yr
//
// tab event_time grd_yr, m
//
// tab increase_year

tab event_time grd_yr if increase_year == 2010 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2011 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2012 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2013 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2014 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2015 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2016 & event_time >= 0, m


// tab event_time grd_yr if increase_year == 2008, m
// tab event_time grade  if increase_year == 2008, m // mirrored

// tab event_time grd_yr if increase_year == 2013 & event_time >= 0, m
// tab event_time grade  if increase_year == 2013 & event_time >= 0, m // mirrored
// tab year if              increase_year == 2013 & event_time >= 0, m

// tab event_time grd_yr if increase_year == 2014 & event_time >= 0, m
// tab event_time grade  if increase_year == 2014 & event_time >= 0, m // mirrored
// tab year if              increase_year == 2014 & event_time >= 0, m

// tab event_time grd_yr if increase_year == 2015 & event_time >= 0, m
// tab event_time grade  if increase_year == 2015 & event_time >= 0, m // mirrored
// tab year if              increase_year == 2015 & event_time >= 0, m

// br if increase_year == 2015 & year < 2015

* For increase_year = 2014, look at event times 0 to 2?

// br if increase_year == 2013

// br if med_school == "west virginia university school of medicine"
//
// assert our_med_school == "west virginia university school of medicine" if med_school == "west virginia university school of medicine"
//
// use "$dropbox/FullDataCMSPANEL_final.dta", clear
//
// br if npi == 1215099023
//
// br if med_sch == "WEST VIRGINIA UNIVERSITY SCHOOL OF MEDICINE"

collapse (mean) fg_sel3_total_payments, by(increase_year /* med_school */ grade event_time)

// sum increase_year, d
forvalues n = $lower_year_limit/$upper_year_limit {

	preserve

	local et_limit = 5 - (`n' - $lower_year_limit)
	
	keep if inrange(event_time, 1, `et_limit')
	keep if increase_year == `n'

	twoway ///
		scatter fg_sel3_total_payments event_time if grade ==  2, lcolor(blue)   || ///
		scatter fg_sel3_total_payments event_time if grade ==  3, lcolor(green)  || ///
		scatter fg_sel3_total_payments event_time if grade ==  4, lcolor(red)    || ///
		scatter fg_sel3_total_payments event_time if grade ==  5, lcolor(black)     ///
		legend(order(1 "Grade 2" 2 "Grade 3" 3 "Grade 4" 4 "Grade 5")) ///
		xlabel(1(1)`et_limit') ///
		ylabel(0(5)30) ///
		title("increase_year = `n'")
		
	graph export "$git/plots/`n'-eventtime-increase.jpg", replace
	
	restore

}

// // sum increase_year, d
// forvalues n = 2014/2014 {
//
// 	preserve
//
// 	keep if inrange(event_time, 0, 2)
// 	keep if increase_year == `n'
//
// 	twoway ///
// 		scatter fg_sel3_total_payments event_time if grade ==  2, lcolor(blue)   || ///
// 		scatter fg_sel3_total_payments event_time if grade ==  3, lcolor(green)  || ///
// 		scatter fg_sel3_total_payments event_time if grade ==  4, lcolor(red)    || ///
// 		scatter fg_sel3_total_payments event_time if grade ==  5, lcolor(black)     ///
// 		legend(order(1 "Grade 2" 2 "Grade 3" 3 "Grade 4" 4 "Grade 5")) ///
// 		xlabel(0(1)2) ///
// 		ylabel(0(5)30) ///
// 		title("increase_year = `n'")
//		
// 	graph export "$git/plots/`n'-eventtime-increase.jpg", replace
//	
// 	restore
//
// }
//
// // sum increase_year, d
// forvalues n = 2015/2015 {
//
// 	preserve
//
// 	keep if inrange(event_time, 0, 1)
// 	keep if increase_year == `n'
//
// 	twoway ///
// 		scatter fg_sel3_total_payments event_time if grade ==  2, lcolor(blue)   || ///
// 		scatter fg_sel3_total_payments event_time if grade ==  3, lcolor(green)  || ///
// 		scatter fg_sel3_total_payments event_time if grade ==  4, lcolor(red)    || ///
// 		scatter fg_sel3_total_payments event_time if grade ==  5, lcolor(black)     ///
// 		legend(order(1 "Grade 2" 2 "Grade 3" 3 "Grade 4" 4 "Grade 5")) ///
// 		xlabel(0(1)1) ///
// 		ylabel(0(5)30) ///
// 		title("increase_year = `n'")
//		
// 	graph export "$git/plots/`n'-eventtime-increase.jpg", replace
//	
// 	restore
//
// }

*****************


use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

g event_time = year - grd_yr

// br npi grd_yr increase_year grade year event_time

g outcome_missing = fg_sel3_total_payments == .

tab year outcome_missing, m

tab grd_yr

tab event_time grd_yr, m

tab increase_year

// tab event_time grd_yr if increase_year == 2008, m
// tab event_time grade  if increase_year == 2008, m // mirrored

tab event_time grd_yr if increase_year == 2013 & event_time >= 0, m
// tab event_time grade  if increase_year == 2013 & event_time >= 0, m // mirrored
// tab year if              increase_year == 2013 & event_time >= 0, m

tab event_time grd_yr if increase_year == 2014 & event_time >= 0, m
// tab event_time grade  if increase_year == 2014 & event_time >= 0, m // mirrored
// tab year if              increase_year == 2014 & event_time >= 0, m

tab event_time grd_yr if increase_year == 2015 & event_time >= 0, m
tab event_time grade  if increase_year == 2015 & event_time >= 0, m // mirrored
tab year if              increase_year == 2015 & event_time >= 0, m

// br if increase_year == 2015 & year < 2015

* For increase_year = 2014, look at event times 0 to 2?

// br if increase_year == 2013

// br if med_school == "west virginia university school of medicine"
//
// assert our_med_school == "west virginia university school of medicine" if med_school == "west virginia university school of medicine"
//
// use "$dropbox/FullDataCMSPANEL_final.dta", clear
//
// br if npi == 1215099023
//
// br if med_sch == "WEST VIRGINIA UNIVERSITY SCHOOL OF MEDICINE"

assert inrange(increase_year, 2013, 2015)

collapse (mean) fg_sel3_total_payments, by(grade event_time)

keep if inrange(event_time, 0, 1)

twoway ///
	scatter fg_sel3_total_payments event_time if grade ==  2, lcolor(blue)   || ///
	scatter fg_sel3_total_payments event_time if grade ==  3, lcolor(green)  || ///
	scatter fg_sel3_total_payments event_time if grade ==  4, lcolor(red)    || ///
	scatter fg_sel3_total_payments event_time if grade ==  5, lcolor(black)     ///
	legend(order(1 "Grade 2" 2 "Grade 3" 3 "Grade 4" 4 "Grade 5")) ///
	xlabel(0(1)1) ///
	ylabel(0(5)30) ///
	title("increase_year = together")
	
graph export "$git/plots/together-eventtime-increase.jpg", replace

******************

forvalues n = 2015/2015 {

	preserve

	keep if inrange(event_time, 0, 1)
	keep if increase_year == `n'

	twoway ///
		scatter fg_sel3_total_payments event_time if grade ==  2, lcolor(blue)   || ///
		scatter fg_sel3_total_payments event_time if grade ==  3, lcolor(green)  || ///
		scatter fg_sel3_total_payments event_time if grade ==  4, lcolor(red)    || ///
		scatter fg_sel3_total_payments event_time if grade ==  5, lcolor(black)     ///
		legend(order(1 "Grade 2" 2 "Grade 3" 3 "Grade 4" 4 "Grade 5")) ///
		xlabel(0(1)1) ///
		ylabel(0(5)30) ///
		title("increase_year = `n'")
		
	graph export "$git/plots/`n'-eventtime-increase.jpg", replace
	
	restore

}



use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

// drop if regexm(pri_spec, "NURS")

// keep if isMD == 1

// tab pri_spec, m sort

collapse (sum) fg_sel3_total_payments, by(increase_year med_school grade)

keep if inlist(grade, 2, 4)

bys increase_year med_school (grade) : g delta = fg_sel3_total_payments[2] - fg_sel3_total_payments[1] if _n == 1

sum delta, d

hist delta


use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

g event_time = year - grd_yr

collapse (mean) fg_sel3_total_payments, by(event_time)








use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

collapse ///
	(mean)   mean   = fg_sel3_total_payments  ///
	(median) median = fg_sel3_total_payments, ///
	by(event_time)
	
	
	
	
	
*******************
*** EVENTTIME 2 ***
*******************

*** 2000-2010 ***

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

forvalues n = $lower_year_limit/$upper_year_limit {

// 	tab event_time grd_yr if increase_year == `n' & event_time >= 0, m
	tab event_time grd_yr if increase_year == `n' & event_time >= 0 & fg_sel3_total_payments != ., m
	
}

collapse (mean) fg_sel3_total_payments, by(increase_year /* med_school */ grade event_time)

// sum increase_year, d
forvalues n = $lower_year_limit/$upper_year_limit {

	preserve

	local lower_et_limit = $lower_year_limit + 12 - `n'
	local upper_et_limit = 16 - (`n' - $lower_year_limit)
	
	keep if inrange(event_time, `lower_et_limit', `upper_et_limit')
	keep if increase_year == `n'

	twoway ///
		scatter fg_sel3_total_payments event_time if grade ==  2, lcolor(blue)   || ///
		scatter fg_sel3_total_payments event_time if grade ==  3, lcolor(green)  || ///
		scatter fg_sel3_total_payments event_time if grade ==  4, lcolor(red)    || ///
		scatter fg_sel3_total_payments event_time if grade ==  5, lcolor(black)     ///
		legend(order(1 "Grade 2" 2 "Grade 3" 3 "Grade 4" 4 "Grade 5")) ///
		xlabel(`lower_et_limit'(1)`upper_et_limit') ///
		ylabel(0(5)30) ///
		title("increase_year = `n'")
		
	graph export "$git/plots/`n'-eventtime-increase.jpg", replace
	
	restore

}


*** 2003-2005 ***

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

forvalues n = $lower_year_limit/$upper_year_limit {

// 	tab event_time grd_yr if increase_year == `n' & event_time >= 0, m
	tab event_time grd_yr if increase_year == `n' & event_time >= 0 & fg_sel3_total_payments != ., m
	
}

collapse (mean) fg_sel3_total_payments, by(increase_year /* med_school */ grade event_time)

// sum increase_year, d
forvalues n = $lower_year_limit/$upper_year_limit {

	preserve

	local lower_et_limit = $lower_year_limit + 9 - `n'
	local upper_et_limit = 13 - (`n' - $lower_year_limit)
	
	keep if inrange(event_time, `lower_et_limit', `upper_et_limit')
	keep if increase_year == `n'

	twoway ///
		scatter fg_sel3_total_payments event_time if grade ==  2, lcolor(blue)   || ///
		scatter fg_sel3_total_payments event_time if grade ==  3, lcolor(green)  || ///
		scatter fg_sel3_total_payments event_time if grade ==  4, lcolor(red)    || ///
		scatter fg_sel3_total_payments event_time if grade ==  5, lcolor(black)     ///
		legend(order(1 "Grade 2" 2 "Grade 3" 3 "Grade 4" 4 "Grade 5")) ///
		xlabel(`lower_et_limit'(1)`upper_et_limit') ///
		ylabel(0(5)30) ///
		title("increase_year = `n'")
		
	graph export "$git/plots/`n'-eventtime-increase.jpg", replace
	
	restore

}




*******************
*** EVENTTIME 2 ***
*******************

*** 2010-2015 ***

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

// g event_time = year - grd_yr

// br npi grd_yr increase_year grade year event_time

// g outcome_missing = fg_sel3_total_payments == .
//
// tab year outcome_missing, m
//
// tab grd_yr
//
// tab event_time grd_yr, m
//
// tab increase_year

tab event_time grd_yr if increase_year == 2010 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2011 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2012 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2013 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2014 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2015 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2016 & event_time >= 0, m

collapse (mean) fg_sel3_total_payments, by(increase_year /* med_school */ grade event_time)

// sum increase_year, d
forvalues n = $lower_year_limit/$upper_year_limit {

	preserve

	local et_limit = 6 - (`n' - $lower_year_limit)
	
	keep if inrange(event_time, 1, `et_limit')
	keep if increase_year == `n'

	twoway ///
		scatter fg_sel3_total_payments event_time if grade ==  2, lcolor(blue)   || ///
		scatter fg_sel3_total_payments event_time if grade ==  3, lcolor(green)  || ///
		scatter fg_sel3_total_payments event_time if grade ==  4, lcolor(red)    || ///
		scatter fg_sel3_total_payments event_time if grade ==  5, lcolor(black)     ///
		legend(order(1 "Grade 2" 2 "Grade 3" 3 "Grade 4" 4 "Grade 5")) ///
		xlabel(1(1)`et_limit') ///
		ylabel(0(5)30) ///
		title("increase_year = `n'")
		
	graph export "$git/plots/`n'-eventtime-increase.jpg", replace
	
	restore

}


*******************
*** EVENTTIME 2 ***
*******************

*** 2009-2015 ***

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

// g event_time = year - grd_yr

// br npi grd_yr increase_year grade year event_time

// g outcome_missing = fg_sel3_total_payments == .
//
// tab year outcome_missing, m
//
// tab grd_yr
//
// tab event_time grd_yr, m
//
// tab increase_year

tab event_time grd_yr if increase_year == 2009 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2010 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2011 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2012 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2013 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2014 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2015 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2016 & event_time >= 0, m

collapse (mean) fg_sel3_total_payments, by(increase_year /* med_school */ grade event_time)

// sum increase_year, d
forvalues n = $lower_year_limit/$upper_year_limit {

	preserve

	local et_limit = 7 - (`n' - $lower_year_limit)
	
	keep if inrange(event_time, 1, `et_limit')
	keep if increase_year == `n'

	twoway ///
		scatter fg_sel3_total_payments event_time if grade ==  2, lcolor(blue)   || ///
		scatter fg_sel3_total_payments event_time if grade ==  3, lcolor(green)  || ///
		scatter fg_sel3_total_payments event_time if grade ==  4, lcolor(red)    || ///
		scatter fg_sel3_total_payments event_time if grade ==  5, lcolor(black)     ///
		legend(order(1 "Grade 2" 2 "Grade 3" 3 "Grade 4" 4 "Grade 5")) ///
		xlabel(1(1)`et_limit') ///
		ylabel(0(5)30) ///
		title("increase_year = `n'")
		
	graph export "$git/plots/`n'-eventtime-increase.jpg", replace
	
	restore

}


*******************
*** EVENTTIME 2 ***
*******************

*** 2008-2015 ***

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

// g event_time = year - grd_yr

// br npi grd_yr increase_year grade year event_time

// g outcome_missing = fg_sel3_total_payments == .
//
// tab year outcome_missing, m
//
// tab grd_yr
//
// tab event_time grd_yr, m
//
// tab increase_year

tab event_time grd_yr if increase_year == 2008 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2009 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2010 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2011 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2012 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2013 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2014 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2015 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2016 & event_time >= 0, m

collapse (mean) fg_sel3_total_payments, by(increase_year /* med_school */ grade event_time)

// sum increase_year, d
forvalues n = $lower_year_limit/$upper_year_limit {

	preserve

	local et_limit = 8 - (`n' - $lower_year_limit)
	
	keep if inrange(event_time, 1, `et_limit')
	keep if increase_year == `n'

	twoway ///
		scatter fg_sel3_total_payments event_time if grade ==  2, lcolor(blue)   || ///
		scatter fg_sel3_total_payments event_time if grade ==  3, lcolor(green)  || ///
		scatter fg_sel3_total_payments event_time if grade ==  4, lcolor(red)    || ///
		scatter fg_sel3_total_payments event_time if grade ==  5, lcolor(black)     ///
		legend(order(1 "Grade 2" 2 "Grade 3" 3 "Grade 4" 4 "Grade 5")) ///
		xlabel(1(1)`et_limit') ///
		ylabel(0(5)30) ///
		title("increase_year = `n'")
		
	graph export "$git/plots/`n'-eventtime-increase.jpg", replace
	
	restore

}


*******************
*** EVENTTIME 2 ***
*******************

*** 2008-2011 ***

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

// g event_time = year - grd_yr

// br npi grd_yr increase_year grade year event_time

// g outcome_missing = fg_sel3_total_payments == .
//
// tab year outcome_missing, m
//
// tab grd_yr
//
// tab event_time grd_yr, m
//
// tab increase_year

tab event_time grd_yr if increase_year == 2008 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2009 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2010 & event_time >= 0, m
tab event_time grd_yr if increase_year == 2011 & event_time >= 0, m

collapse (mean) fg_sel3_total_payments, by(increase_year /* med_school */ grade event_time)

// sum increase_year, d
forvalues n = $lower_year_limit/$upper_year_limit {

	preserve

	local et_limit = 8 - (`n' - $lower_year_limit)
	
	keep if inrange(event_time, 1, `et_limit')
	keep if increase_year == `n'

	twoway ///
		scatter fg_sel3_total_payments event_time if grade ==  2, lcolor(blue)   || ///
		scatter fg_sel3_total_payments event_time if grade ==  3, lcolor(green)  || ///
		scatter fg_sel3_total_payments event_time if grade ==  4, lcolor(red)    || ///
		scatter fg_sel3_total_payments event_time if grade ==  5, lcolor(black)     ///
		legend(order(1 "Grade 2" 2 "Grade 3" 3 "Grade 4" 4 "Grade 5")) ///
		xlabel(1(1)`et_limit') ///
		ylabel(0(5)30) ///
		title("increase_year = `n'")
		
	graph export "$git/plots/`n'-eventtime-increase.jpg", replace
	
	restore

}
