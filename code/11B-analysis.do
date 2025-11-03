
***************
*** FIGURES ***
***************

* Description of this do-file:

* 	Creates figures for Overleaf
*	https://www.overleaf.com/project/686ce654c75b2401fd5b530e

***************
***************
***************



*** excel export to build map manually ***

* Link: https://www.google.com/maps/d/u/0/edit?mid=18MUBvTRUCk63n8UxFjrDu3bUFaLktRw&usp=sharing

use "$temp/cms-panel-with-treatment", clear

merge 1:1 npi year using "$temp/main-sample-npi-year"
keep if _merge == 3
drop    _merge

bys npi (year) : keep if _n == 1

keep our_med_school orig_med_school

duplicates drop

export excel "$temp/school-names-map.xlsx", replace firstrow(var)


*** tuition-bill-per-treatment-group ***

*** FIX THE p-VALUE FOR THE F-TEST!

use "$temp/cms-panel-with-treatment", clear

merge 1:1 npi year using "$temp/main-sample-npi-year"
keep if _merge == 3
drop    _merge

bys npi (year) : keep if _n == 1

local m_titles // titles

eststo clear

foreach var in tuition_bill /* PublicSchool */ {

	local m_titles `" `m_titles' "`: var label `var''" "' // labels as titles
	
	if "`var'" == "PublicSchool" {
		local FE "grad_year"
	}
	else {
		local FE "med_school grad_year"
	}
	
	eststo : reghdfe ///
		`var' ///
		$years_treated, ///
		cl(orig_med_school) absorb(`FE')
		
	* Mean:
	sum `var' if e(sample) == 1
	
	estadd r(mean)
		
	* To get p-value of regression (F-test):
	test (years_treated_1 = years_treated_2 = years_treated_3) // WRONG!
		
	estadd r(p)
	
	* Unique schools:
// 	unique orig_med_school if e(sample) == 1
//	
// 	estadd scalar unique_schools = r(unique)
		
	coefplot, ///
		keep($years_treated) ///
		ci(95) vertical recast(bar) ///
		barwidth(0.5) ///
		citop cirecast(rcap) ///
		ytitle("`: var label `var''")
		
	graph export ///
		"$git/plots/`var'-per-treatment-group.jpg", ///
		replace
		
}

esttab est*, ///
	keep($years_treated) ///
	se star(* 0.10 ** 0.05 *** 0.01) label

estfe est*, labels(                 /// ssc install erepost
	med_school "School FE"          ///
	grad_year  "Graduation Year FE")
	
esttab est* using "$git/tables/first-stage-reg.tex", ///
	keep($years_treated) ///
	se star(* 0.10 ** 0.05 *** 0.01) indicate(`r(indicate_fe)') ///
	stats(N N_clust /* unique_schools */ r2 F /* p */ mean, fmt(%9.0fc %9.0fc /* %9.0fc */ 3 3 /* 3 */ 3) ///
	labels("Observations (doctors)" "Clusters" /* "Schools" */ "\$R^{2}\$" "\$F\$-test" /* "\$p\$-value" */ "Mean")) ///
	label mtitles(`m_titles') replace


*** distribution-of-shocks ***

use "$temp/all-tuition-shocks", clear

rename aca_year increase_aca_year

merge 1:1 shock_id using "$temp/main-sample-shock_id"
assert       _merge != 2
g in_panel = _merge == 3
drop         _merge

sum increase_aca_year if in_panel == 1
local min = r(min)
local max = r(max)

keep if inrange(increase_aca_year, `min', `max')

g n = 1

forvalues m = 1/2 {

	preserve

	if (`m' == 2) {
		keep if in_panel == 1
	}
	
	collapse (sum) count = n, by(increase_aca_year)

	twoway bar count increase_aca_year, ///
		xlabel(`min'(2)`max') ///
		xtitle("Shock Year") ///
		ytitle("Number of Shocks")

	graph export ///
		"$git/plots/shock-years-`m'.jpg", ///
		replace
		
	restore

}


*** distribution-of-tuition-increases ***

use "$temp/aamc-tuition", clear

sum delta_tuition, d

hist delta_tuition ///
	if 0 < delta_tuition & delta_tuition < r(p99), /// r(p1)
	frac xtitle("Tuition Increase (USD 1,000)") width(0.2) start(0) ///
	xline(2, lcolor(red))

graph export "$git/plots/dist-tuition-increases.jpg", replace

sum delta_nominal_tuition, d

hist delta_nominal_tuition ///
	if 0 < delta_nominal_tuition & delta_nominal_tuition < r(p99), /// r(p1)
	frac xtitle("Tuition Increase (USD 1,000)") width(0.2) start(0)

graph export "$git/plots/dist-nominal-tuition-increases.jpg", replace
