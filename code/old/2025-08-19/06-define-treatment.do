
******************************
*** DEFINE TREATMENT GROUP ***
******************************


*** HISTOGRAMS ***

* School panel:
use "$git/data/original/aamc/modified/aamc-tuition", clear

hist tot_tuition_increase, freq ///
title("Distribution of total tuition increase") ///
subtitle("From school panel")

graph export "$git/plots/05-initial-analysis/hist-tuition-increase-school-panel.jpg", replace

sum tot_tuition_increase, d

* Doctor panel:
use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

bys npi : g tot_tuition_increase_mod = tot_tuition_increase if _n == 1 // only one per npi

hist tot_tuition_increase_mod, freq ///
title("Distribution of total tuition increase") ///
subtitle("From doctor panel (one doctor = one increase)")

graph export "$git/plots/05-initial-analysis/hist-tuition-increase-doctor-panel.jpg", replace

sum tot_tuition_increase_mod, d

global treatment_limit = `r(p95)'
global   control_limit = `r(p5)'


*** "SUM STAT" ***

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

assert tot_tuition_increase != .

bys npi (tot_tuition_increase) : assert tot_tuition_increase[1] == tot_tuition_increase[_N]

g       treatment = 1 if tot_tuition_increase > $treatment_limit
replace treatment = 0 if tot_tuition_increase <   $control_limit

tab treatment, m

global constant_vars ///
	treatment tot_tuition tot_tuition_increase grd_yr aamc_med_school
	
foreach var of global constant_vars {
	bys npi (`var') : assert `var'[1] == `var'[_N] // check so var is constant within npi
}

collapse (sum) total_payments (first) $constant_vars, by(npi)

g       groups = "Treatment" if treatment == 1
replace groups = "Middle"	 if treatment == .
replace groups = "Control" 	 if treatment == 0

graph bar (mean) tot_tuition_increase, over(groups) ///
title("Mean total tuition increase per group")

graph export "$git/plots/05-initial-analysis/groups-increase.jpg", replace

graph bar (mean) tot_tuition, over(groups) ///
title("Mean total tuition per group")

graph export "$git/plots/05-initial-analysis/groups-tuition.jpg", replace

graph bar (mean) total_payments, over(groups) ///
title("Mean total payments per group") ///
subtitle("Sum by npi then mean per group")

graph export "$git/plots/05-initial-analysis/groups-payments.jpg", replace


*** NAIVE REGRESSION ***

// ssc install reghdfe
// ssc install ftools

reghdfe total_payments tot_tuition, absorb(grd_yr aamc_med_school)
