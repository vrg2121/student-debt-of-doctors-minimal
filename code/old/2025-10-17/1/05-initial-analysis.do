
************************
*** INITIAL ANALYSIS ***
************************


*** MEAN TUITION PER YEAR ***

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

bys npi : keep if _n == 1

collapse (mean) tot_tuition, by(grd_yr)

scatter tot_tuition grd_yr, title("Mean total tuition per graduation year")
graph export "$git/plots/05-initial-analysis/mean-tuition-per-grd_yr.jpg", replace


*** MEAN INCREASE PER YEAR ***

// import excel ///
// 	"$git/data/working/external/CORESTICKM159SFRBATL.xlsx", ///
// 	clear firstrow sheet("Annual")
//	
// replace observation_date = year(observation_date)
//
// rename observation_date grd_yr
//
// replace CORESTICKM159SFRBATL = CORESTICKM159SFRBATL / 100
//
// rename CORESTICKM159SFRBATL inflation
//
// save "$git/data/working/external/inflation", replace

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

bys npi : keep if _n == 1

collapse (mean) tot_tuition_increase, by(grd_yr)

replace grd_yr = grd_yr - 3 // "lag" because definition of total tuition

merge 1:1 grd_yr using "$git/data/working/external/inflation"
drop if _merge == 2
drop _merge

twoway ///
	(scatter tot_tuition_increase grd_yr, mcolor(red)) ///
    (scatter inflation 		      grd_yr, mcolor(blue)), ///
	title("Mean total tuition increase per graduation year") ///
	subtitle("Graduation year translated e.g. 2000 = tuition for 2000-2003") ///
	xtitle("grd_yr - 3") ///
	legend(order(1 "Mean total tuition increase" 2 "Inflation"))

graph export "$git/plots/05-initial-analysis/mean-increase-per-grd_yr.jpg", replace


*** TREATMENT/CONTROL SPLITS ***

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

// * Find large tuition increases:
// sum tot_tuition_increase, d
//
// g treatment = tot_tuition_increase > `r(p90)'

assert tot_tuition_increase != .

bys npi : assert tot_tuition_increase[1] == tot_tuition_increase[_N]

bys npi : g tot_tuition_increase_mod = tot_tuition_increase if _n == 1 // only one per npi

bys grd_yr : egen treatment_limit = pctile(tot_tuition_increase_mod), p(90)

g treatment = tot_tuition_increase > treatment_limit // splitting doctors into treatment/control (note: not mod here)

sort npi year

bys npi : assert tot_tuition[1] == tot_tuition[_N]
bys npi : assert   treatment[1] ==   treatment[_N]

collapse (sum) total_payments (first) tot_tuition treatment, by(npi)

collapse (mean) total_payments tot_tuition, by(treatment)

graph bar (mean) total_payments, ///
over(treatment) ///
bar(1, color(blue)) ///
title("Mean values per control (0) and treatment (1)") ///
subtitle("Total payments")

graph export "$git/plots/05-initial-analysis/treatment-split-payments.jpg", replace

graph bar (mean) tot_tuition, ///
over(treatment) ///
bar(1, color(red)) ///
title("Mean values per control (0) and treatment (1)") ///
subtitle("Total tuition")

graph export "$git/plots/05-initial-analysis/treatment-split-tuition.jpg", replace


*** MEAN TOTAL TUITION PER TUITION INCREASE DECILE ***

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

assert tot_tuition_increase != .

bys npi : assert tot_tuition_increase[1] == tot_tuition_increase[_N]

bys npi : keep if _n == 1

bys grd_yr : egen decile = xtile(tot_tuition_increase), n(10) // ssc install egenmore

collapse (mean) tot_tuition*, by(decile)

scatter tot_tuition decile, ///
	title("Mean total tuition per increase decile") ///
	subtitle("Further right ≈ higher percent increase tuition")
	
graph export "$git/plots/05-initial-analysis/tuition-per-increase-decile.jpg", replace


*** ... ***

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

assert tot_tuition_increase != .

bys npi : assert tot_tuition_increase[1] == tot_tuition_increase[_N]

bys npi : g tot_tuition_increase_mod = tot_tuition_increase if _n == 1 // only one per npi

bys grd_yr : egen decile = xtile(tot_tuition_increase_mod), n(10) // ssc install egenmore

bys npi (decile) : replace decile = decile[1]

collapse (sum) total_payments (first) decile tot_tuition*, by(npi)

collapse (mean) total_payments tot_tuition*, by(decile)

scatter total_payments decile, ///
	title("Mean total payments per increase decile") ///
	subtitle("Further right ≈ higher percent increase tuition")
	
graph export "$git/plots/05-initial-analysis/payments-per-increase-decile.jpg", replace

scatter tot_tuition decile, ///
	title("Mean total tuition per increase decile") ///
	subtitle("Further right ≈ higher percent increase tuition")
	
graph export "$git/plots/05-initial-analysis/tuition-per-increase-decile-2.jpg", replace
