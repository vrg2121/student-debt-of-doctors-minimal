

***********
*** ... ***
***********

use "$temp/treatment-data-2025-09-10", clear

bys med_school increase_aca_year : g n = 1 if _n == 1

bys med_school increase_aca_year : replace increase_aca_year = . if _n != 1
// tab increase_aca_year

collapse (sum) n, by(med_school)

// sum n, d
   tab n, m

use "$temp/treatment-data", clear

bys med_school increase_aca_year : g n = 1 if _n == 1

bys med_school increase_aca_year : replace increase_aca_year = . if _n != 1
// tab increase_aca_year

collapse (sum) n, by(med_school)

// sum n, d
   tab n, m

************************
*** TO-DO 2025-08-29 ***
************************

use "$temp/cms-panel-with-treatment", clear

keep if isMD == 1

*** MANUAL CHECK OF SELECTION ***

// foreach outcome of global outcomes {
//	
// 	disp ""
// 	disp "variable `outcome':"
// 	disp ""
//	
// 	forvalues n = $lower_year_limit/$upper_year_limit {
//		
// 		disp ""
// 		disp "increase_aca_year `n'-`=`n'+1':"
//
// // 		tab event_time years_treated if ///
// // 			increase_aca_year == `n' & `outcome' != ., m
//		
// 		tab event_time years_treated if ///
// 			increase_aca_year == `n' & sample_`outcome' == 1, m
//		
// 	}
// }


*** GRAPHS ***

foreach outcome of global outcomes {
	
	forvalues drop = 0/1 {
	
		preserve

		if `drop' == 1 {
			drop if no_pay_ever == 1
		}
		
		keep if sample_`outcome' == 1
		
		count
		if r(N) == 0 {
			restore
			continue
		}

		sum increase_aca_year
		local start_yr = r(min)
		local end_yr   = r(max)
		
		collapse (mean) `outcome', by(years_treated event_time)

		twoway ///
			scatter `outcome' event_time if years_treated == 3, lcolor(blue)  || ///
			scatter `outcome' event_time if years_treated == 2, lcolor(green) || ///
			scatter `outcome' event_time if years_treated == 1, lcolor(red)   || ///
			scatter `outcome' event_time if years_treated == 0, lcolor(black)    ///
			legend(order(1 "3 Years Treated" 2 "2 Years Treated" 3 "1 Years Treated" 4 "0 Years Treated")) ///
			title("Shock Years: `start_yr'-`end_yr'") ///
			subtitle("Drop (yes = 1): `drop'")
			
		graph export ///
			"$git/plots/`outcome'-`start_yr'-`end_yr'-`drop'.jpg", ///
			replace

		restore
	
	}
	
}


*** FIRST STAGE ***

use "$temp/cms-panel-with-treatment", clear

keep if isMD == 1

bys med_school increase_aca_year : g n = 1 if _n == 1

collapse (sum) n, by(med_school)

save "$temp/med_school_shock_count", replace

use "$temp/cms-panel-with-treatment", clear

keep if isMD == 1

bys npi (year) : keep if _n == 1

merge m:1 med_school using "$temp/med_school_shock_count"
assert _merge == 3
drop   _merge

reghdfe ///
	tuition_bill ///
	ib(0).years_treated, ///
	cl(med_school) absorb(med_school grad_year)
	
coefplot, keep(1.years_treated 2.years_treated 3.years_treated) ci(95) vertical

preserve

keep if n == 1

reghdfe ///
	tuition_bill ///
	ib(0).years_treated, ///
	cl(med_school) absorb(med_school grad_year) resid
	
predict fit, xb

// br years_treated fit if inlist(years_treated, 0, 3)

// coefplot, keep(1.years_treated 2.years_treated 3.years_treated) ci(95) vertical

// egen med_school_group = group(med_school)
//
// reg ///
// 	tuition_bill ///
// 	ib(0).years_treated i.med_school_group i.grad_year

restore

preserve

keep if ///
	n == 1 | ///
	med_school == "michigan state university college of human medicine"
	
reghdfe ///
	tuition_bill ///
	ib(0).years_treated, ///
	cl(med_school) absorb(med_school grad_year) resid

// coefplot, keep(1.years_treated 2.years_treated 3.years_treated) ci(95) vertical
	
restore

preserve

keep if n > 1

reghdfe ///
	tuition_bill ///
	ib(0).years_treated, ///
	cl(med_school) absorb(med_school grad_year)
	
// coefplot, keep(1.years_treated 2.years_treated 3.years_treated) ci(95) vertical

restore

use "$temp/cms-panel-with-treatment", clear

keep if isMD == 1

merge m:1 med_school using "$temp/med_school_shock_count"
assert _merge == 3
drop   _merge


*** IV ***

tab years_treated delta_tuition_dummy, m

foreach instrument in years_treated delta_tuition_dummy {
//    foreach instrument in years_treated {
	
// 	foreach outcome of global outcomes {
	foreach outcome in fg_sel3_total_payments {
		
		forvalues drop = 0/1 {
// 		forvalues drop = 0/0 {
		
			preserve

// 			keep if n >  1
// 			keep if n == 1
			
			if `drop' == 1 {
				drop if no_pay_ever == 1
			}
				
			keep if sample_`outcome' == 1
			
			count
			if r(N) == 0 {
				restore
				continue
			}

			disp ""
			disp "Outcome = `: variable label `outcome''"
			disp ""

			eststo clear

			foreach FE of global FEs {

				qui : eststo : ivreghdfe ///
					`outcome' ///
					(tuition_bill = i.`instrument') $controls, /// controls here?
					cl(med_school) absorb(`FE')

			}

			disp ""
			disp "Drop (yes = 1): `drop'"
			disp "Instrument: `instrument'"
			disp "Outcome = `: variable label `outcome''"
			disp "Explained by = `: variable label tuition_bill'"
			
			esttab est*, keep(tuition_bill) p star(* 0.10 ** 0.05 *** 0.01) label
			
			restore

		}
		
	}
	
}


*** SHARE OF DOCTORS NEVER CLAIMING BY GROUPPAC ***

use "$temp/cms-panel", clear

bys npi groupPAC : keep if _n == 1

collapse (mean) no_pay_ever (count) n = npi, by(groupPAC)

sum no_pay_ever, d
sum n if no_pay_ever == 1, d


*** CHECK SELECTION INTO MEDICARE ***

use "$temp/cms-panel-with-treatment", clear

bys npi (year) : keep if _n == 1

foreach FE of global FEs {

	reghdfe ///
		no_pay_ever ///
		ib(0).years_treated, ///
		cl(med_school) absorb(`FE')

}


*******************************
*** COMPARE NR OF GRADUATES ***
*******************************

// use "$temp/cms-panel-with-treatment", clear
//
// keep if isMD == 1
//
// collapse (count) n = npi, by(med_school)
//
// gsort -n
//
// use "$temp/cms-panel", clear
//
// keep if isMD == 1
//
// keep if inlist(med_school, ///
// 	"university of illinois college of medicine", ///
// 	"sidney kimmel medical college at thomas jefferson university", ///
// 	"indiana university school of medicine", ///
// 	"wayne state university school of medicine", ///
// 	"new york medical college")
//
// bys npi (year) : keep if _n == 1
//
// collapse (count) n = npi, by(med_school grad_year)
//
//
// twoway ///
//     line n grad_year if med_school == "university of illinois college of medicine", lcolor(blue) || ///
//     line n grad_year if med_school == "sidney kimmel medical college at thomas jefferson university", lcolor(red) || ///
//     line n grad_year if med_school == "indiana university school of medicine", lcolor(green) || ///
//     line n grad_year if med_school == "wayne state university school of medicine", lcolor(orange) || ///
//     line n grad_year if med_school == "new york medical college", lcolor(purple) ///
//     legend(order(1 "Illinois" 2 "Sidney Kimmel" 3 "Indiana" 4 "Wayne State" 5 "NYMC"))

