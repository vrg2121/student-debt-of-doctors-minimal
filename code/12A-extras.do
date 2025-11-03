
**************
*** EXTRAS ***
**************

* Description of this do-file:

* 	Creates basic payment per event time graphs
*	Creates exports for scraping and magazines

**************
**************
**************



*** payments-by-event-time ***

* Not in Overleaf (as of 20th Oct 2025)

use "$temp/cms-panel", clear

collapse ///
	(p10) p10 = fg_sel3_total_payments ///
	(p25) p25 = fg_sel3_total_payments ///
	(p50) p50 = fg_sel3_total_payments ///
	(p75) p75 = fg_sel3_total_payments ///
	(p90) p90 = fg_sel3_total_payments, ///
	by(event_time)

twoway ///
    (scatter p10 event_time, mcolor(gs12) msymbol(O)) ///
    (scatter p25 event_time, mcolor(blue) msymbol(+)) ///
    (scatter p50 event_time, mcolor(red) msymbol(D)) ///
    (scatter p75 event_time, mcolor(blue) msymbol(X)) ///
    (scatter p90 event_time, mcolor(gs12) msymbol(T)), ///
    legend(order(1 "10th" 2 "25th" 3 "Median" 4 "75th" 5 "90th")) ///
    xtitle("Event Time") ytitle("Payments") title("Payments")
	
graph export ///
	"$git/plots/payments-by-event-time.jpg", ///
	replace

use "$temp/cms-panel", clear

bys npi (event_time) : ///
	g csum_fg_sel3_total_payments = ///
		sum(fg_sel3_total_payments)

collapse ///
	(p10) p10 = csum_fg_sel3_total_payments ///
	(p25) p25 = csum_fg_sel3_total_payments ///
	(p50) p50 = csum_fg_sel3_total_payments ///
	(p75) p75 = csum_fg_sel3_total_payments ///
	(p90) p90 = csum_fg_sel3_total_payments, ///
	by(event_time)

twoway ///
    (scatter p10 event_time, mcolor(gs12) msymbol(O)) ///
    (scatter p25 event_time, mcolor(blue) msymbol(+)) ///
    (scatter p50 event_time, mcolor(red) msymbol(D)) ///
    (scatter p75 event_time, mcolor(blue) msymbol(X)) ///
    (scatter p90 event_time, mcolor(gs12) msymbol(T)), ///
    legend(order(1 "10th" 2 "25th" 3 "Median" 4 "75th" 5 "90th")) ///
    xtitle("Event Time") ytitle("Payments") title("Cumulative Payments")
	
graph export ///
	"$git/plots/cumulative-payments-by-event-time.jpg", ///
	replace

***************************
*** EXPORT FOR SCRAPING ***
***************************

// use "$temp/cms-panel-with-treatment", clear
//
// keep if sample_fg_sel3_total_payments == 1
//
// bys npi : keep if _n == 1
//
// keep npi grad_year our_med_school orig_med_school
//
// save "$temp/npi-etc-victoria-scraping-2025-10-07", replace

* For old R script:
// use "$temp/cms-panel-with-treatment", clear
//
// keep if sample_fg_sel3_total_payments == 1
//
// keep npi
//
// duplicates drop
//
// tostring npi, replace
//
// export delimited "$temp/main-sample-npi.csv"


***********************************
*** EXPORT FOR SCHOOL MAGAZINES ***
***********************************

// use "$temp/cms-panel-with-treatment", clear
//
// keep if sample_fg_sel3_total_payments == 1
//
// // keep if event_time == 5
//
// ivreghdfe ///
// 	fg_sel3_total_payments ///
// 	(tuition_bill = $years_treated) $controls, /// controls here?
// 	cl(orig_med_school) absorb(med_school grad_year) // NOT MAIN SAMPLE! TO GET ALL SCHOOLS.
//
// keep if e(sample) == 1
//
// preserve
//
// collapse ///
// 	(min) min_grad_year = grad_year  ///
// 	(max) max_grad_year = grad_year, ///
// 	by(orig_med_school)
//
// export excel "$temp/schools-grad-years", replace firstrow(var)
//	
// restore
//
// keep orig_med_school our_med_school
//
// duplicates drop
//
// bys orig_med_school (our_med_school) : g n = _n
//
// reshape wide our_med_school, i(orig_med_school) j(n)
//
// export excel "$temp/alternative-school-names", replace firstrow(var)

