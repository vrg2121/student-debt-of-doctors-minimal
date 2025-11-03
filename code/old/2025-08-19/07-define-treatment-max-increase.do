
*************************
*** STATS FOR SCHOOLS ***
*************************

use "$git/data/original/aamc/modified/aamc-tuition", clear

* Fix this:
// assert grd_yr != . & max_tuition_increase != .

bys med_school (grd_yr) : keep if grd_yr == max_tuition_increase

* Number of schools:
tab max_tuition_increase, sort m

* Distribution of delta tutiton for max percent increases:
sum delta_tuition, d

hist delta_tuition, freq ///
title("Delta tuition for max percent increases")

graph export "$git/plots/05-initial-analysis/delta-tutiton-max-percent-increases.jpg", replace


*****************************
*** STATS FOR INDIVIDUALS ***
*****************************

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear // 25 % subsample!

* "Time" of panel:
tab year, sort m

bys npi : keep if _n == 1

* Individuals per grade group:
tab grade, sort m


*****************
*** SUM STATS ***
*****************

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

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
	title("Mean total tuition") ///
	yscale(range(0 140000)) ///
	ylabel(0(20000)140000, format(%15.0fc)) ///
	legend(order( ///
		1 "Total tuition" ///
		))

graph export "$git/plots/05-initial-analysis/grade-groups-tot-tuition.jpg", replace

graph bar (mean) ///
	mean_total_payments, ///
	over(grade) ///
	title("Mean mean total payments") ///
	yscale(range(0 140000)) ///
	ylabel(0(20000)140000, format(%15.0fc)) ///
	legend(order( ///
		1 "Mean total payments" ///
		))

graph export "$git/plots/05-initial-analysis/grade-groups-mean-total-payments.jpg", replace


*****************
*** SUM STATS ***
*****************

// use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear
//
// g et_grd = year - grd_yr
//
// tab et_grd if grade == 1, sort m
// tab et_grd if grade == 2, sort m
// tab et_grd if grade == 3, sort m
// tab et_grd if grade == 4, sort m
//
// g total_payments_11 = total_payments if et_grd == 11
// g total_payments_13 = total_payments if et_grd == 13 // based on tabs above
// g total_payments_15 = total_payments if et_grd == 15
//
// collapse ///
// 	(first) tot_tuition grade ///
// 	(mean)  mean_total_payments = total_payments ///
// 	(sum)    sum_total_payments = total_payments ///
// 			     total_payments_11 total_payments_13 total_payments_15, ///
// 	by(npi)
//	
// graph bar (mean) ///
// 	tot_tuition ///
// 	mean_total_payments sum_total_payments ///
// 	total_payments_11 total_payments_13 total_payments_15, ///
// over(grade) missing ///
// title("Means per group") ///
// legend(order( ///
// 	1 "Total tuition" ///
// 	2 "Total payments (mean)" ///
// 	3 "Total payments (sum)" ///
// 	4 "Total payments (11 yrs after grad)" ///
// 	5 "Total payments (13 yrs after grad)" ///
// 	6 "Total payments (15 yrs after grad)" ///
// 	))
//
// graph export "$git/plots/05-initial-analysis/grade-groups-v1.jpg", replace
//
// replace sum_total_payments = sum_total_payments / 10
//
// graph bar (mean) ///
// 	tot_tuition ///
// 	mean_total_payments sum_total_payments ///
// 	total_payments_11 total_payments_13 total_payments_15, ///
// over(grade) missing ///
// title("Means per group") ///
// subtitle("Total payments (sum) divided by 10") ///
// legend(order( ///
// 	1 "Total tuition" ///
// 	2 "Total payments (mean)" ///
// 	3 "Total payments (sum)" ///
// 	4 "Total payments (11 yrs after grad)" ///
// 	5 "Total payments (13 yrs after grad)" ///
// 	6 "Total payments (15 yrs after grad)" ///
// 	))
//
// graph export "$git/plots/05-initial-analysis/grade-groups-v2.jpg", replace
//
//
use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

g et_grd = year - grd_yr

collapse (mean) total_payments, by(grade et_grd)

twoway ///
	(line total_payments et_grd if grade == 1, color(blue)) ///
	(line total_payments et_grd if grade == 2, color(red)) ///
	(line total_payments et_grd if grade == 3, color(green)) ///
	(line total_payments et_grd if grade == 4, color(black)), ///
	legend(order(1 "1" 2 "2" 3 "3" 4 "4")) ///
	title("Mean total payments at x years after graduation")

graph export "$git/plots/05-initial-analysis/total-payments-development.jpg", replace
