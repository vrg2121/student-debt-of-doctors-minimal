
************************
*** TO-DO 2025-08-29 ***
************************

foreach var in ///
	fg_sel3_total_payments ///
	fg_sel5_total_payments ///
	S_nCode ///
	S_nCodeEM ///
	pp_payment ///
	pp_quotient {

	disp ""
	disp "RESULTS FOR: `var'"
	disp ""
	
	*** PUT THE INCREASE YEARS TOGETHER IN THE GRAPHS ***

	use "$temp/cms-panel-with-treatment", clear

// 	keep if osteo_school == 1 // specialisations etc
	
	keep if inrange(year, 2012, 2019)

	forvalues n = $lower_year_limit/$upper_year_limit {
		
		disp ""
		disp "increase_aca_year `n'-`=`n'+1':"
		
		tab event_time years_treated if ///
			increase_aca_year == `n' & `var' != ., m
		
	}

	if substr("`var'", 1, 2) == "pp" {
		keep if ///
			(increase_aca_year == 2011 & event_time == 2) | ///
			(increase_aca_year == 2012 & event_time == 1)
	}
	else {
		keep if increase_aca_year + 3 + event_time <= 2019
	}

	forvalues n = $lower_year_limit/$upper_year_limit {
		
		disp ""
		disp "increase_aca_year `n'-`=`n'+1':"
		
		tab event_time years_treated if ///
			increase_aca_year == `n' & `var' != ., m
		
	}

	preserve

	* Old data:
	use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear
	
	g years_treated = 5 - grade
	
	if substr("`var'", 1, 2) == "pp" {
		keep if ///
			(increase_year == 2011 & event_time == 2) | ///
			(increase_year == 2012 & event_time == 1)
	}
	else {
		keep if increase_year + 3 + event_time <= 2019
	}

	collapse (mean) `var', by(years_treated event_time)

	twoway ///
		scatter `var' event_time if years_treated == 3, lcolor(blue)  || ///
		scatter `var' event_time if years_treated == 2, lcolor(green) || ///
		scatter `var' event_time if years_treated == 1, lcolor(red)   || ///
		scatter `var' event_time if years_treated == 0, lcolor(black)    ///
		legend(order(1 "3 Years Treated" 2 "2 Years Treated" 3 "1 Years Treated" 4 "0 Years Treated")) ///
		title("Academic Increase Years: $lower_year_limit-$upper_year_limit")
		
	graph export ///
		"$git/plots/`var'-eventtime-increase-together-$lower_year_limit-$upper_year_limit-old.jpg", ///
		replace

	restore

	preserve

	* New data, all:
	collapse (mean) `var', by(years_treated event_time)

	twoway ///
		scatter `var' event_time if years_treated == 3, lcolor(blue)  || ///
		scatter `var' event_time if years_treated == 2, lcolor(green) || ///
		scatter `var' event_time if years_treated == 1, lcolor(red)   || ///
		scatter `var' event_time if years_treated == 0, lcolor(black)    ///
		legend(order(1 "3 Years Treated" 2 "2 Years Treated" 3 "1 Years Treated" 4 "0 Years Treated")) ///
		title("Academic Increase Years: $lower_year_limit-$upper_year_limit")
		
	graph export ///
		"$git/plots/`var'-eventtime-increase-together-$lower_year_limit-$upper_year_limit-all.jpg", ///
		replace

	restore

	preserve

	* New data, excluding those who never receive payment:
	drop if no_pay_ever == 1

	collapse (mean) `var', by(years_treated event_time)

	twoway ///
		scatter `var' event_time if years_treated == 3, lcolor(blue)  || ///
		scatter `var' event_time if years_treated == 2, lcolor(green) || ///
		scatter `var' event_time if years_treated == 1, lcolor(red)   || ///
		scatter `var' event_time if years_treated == 0, lcolor(black)    ///
		legend(order(1 "3 Years Treated" 2 "2 Years Treated" 3 "1 Years Treated" 4 "0 Years Treated")) ///
		title("Academic Increase Years: $lower_year_limit-$upper_year_limit")
		
	graph export ///
		"$git/plots/`var'-eventtime-increase-together-$lower_year_limit-$upper_year_limit-excl-no_pay_ever.jpg", ///
		replace

	restore


	*** IV ***

	* New data, all:
	foreach outcome in `var' {

		disp ""
		disp "Outcome = `: variable label `outcome''"
		disp ""

		eststo clear

		foreach FE of global FEs {

			qui : eststo : ivreghdfe ///
				`outcome' ///
				(tuition_bill = i.grade) $controls, /// controls here?
				cl(med_school) absorb(`FE')

		}

		disp ""
		disp "Outcome = `: variable label `outcome''"
		disp "Explained by = `: variable label tuition_bill'"
		
		esttab est*, keep(tuition_bill) p star(* 0.10 ** 0.05 *** 0.01) label

	}

	* New data, excluding those who never receive payment:
	drop if no_pay_ever == 1

	foreach outcome in `var' {

		disp ""
		disp "Outcome = `: variable label `outcome''"
		disp ""

		eststo clear

		foreach FE of global FEs {

			qui : eststo : ivreghdfe ///
				`outcome' ///
				(tuition_bill = i.grade) $controls, /// controls here?
				cl(med_school) absorb(`FE')

		}

		disp ""
		disp "Outcome = `: variable label `outcome''"
		disp "Explained by = `: variable label tuition_bill'"
		
		esttab est*, keep(tuition_bill) p star(* 0.10 ** 0.05 *** 0.01) label

	}

	tab years_treated delta_tuition_dummy, m

	foreach outcome in `var' {

		disp ""
		disp "Outcome = `: variable label `outcome''"
		disp ""

		eststo clear

		foreach FE of global FEs {

			qui : eststo : ivreghdfe ///
				`outcome' ///
				(tuition_bill = i.delta_tuition_dummy) $controls, /// controls here?
				cl(med_school) absorb(`FE')

		}

		disp ""
		disp "Outcome = `: variable label `outcome''"
		disp "Explained by = `: variable label tuition_bill'"
		
		esttab est*, keep(tuition_bill) p star(* 0.10 ** 0.05 *** 0.01) label

	}

}
	
// count
// count if tuition_bill == .
// br if med_school == "194091"
//
// use "$git/data/original/aamc/modified/aamc-tuition", clear
//
// br if med_school == "194091"


// use "$temp/cms-panel-with-treatment", clear
//
// tab phySpec, m
//
// tab medic_school, m
// tab chiro_school, m
// tab osteo_school, m
// tab optom_school, m
// tab podia_school, m
//
// tab no_pay_ever if osteo_school == 1, m

// use "$temp/cms-panel", clear
//
// g n = 1
//
// collapse (sum) n, by(phySpec)
//
// egen total = total(n)
//
// g percent = round(100 * n / total, 0.1)
//
// drop total
//
// gsort -n
//
// export excel using "$temp/doctor-specialisations-2025-09-05.xlsx", ///
// 	replace firstrow(var)
