
use "$temp/cms-panel", clear

keep npi

duplicates drop

save "$temp/cms-panel-unique-npi", replace


use "$dropbox/FullDataCMSPANEL_final.dta", clear

keep npi

duplicates drop

save "$temp/FullDataCMSPANEL_final-unique-npi", replace


use "$dropbox/FullData/RawData/CMSPANEL.dta"

keep npi

duplicates drop

save "$temp/CMSPANEL-unique-npi", replace


use "emiel-total_payments-fg-hcpcs-codes", clear

keep npi

duplicates drop

save "$temp/emiel-total_payments-fg-hcpcs-codes-unique-npi", replace


use "$fang_gong_replication/output/phy_time", clear

keep npi

duplicates drop

save "$temp/phy_time-unique-npi", replace



use "$temp/emiel-total_payments-fg-hcpcs-codes-unique-npi", clear

merge 1:1 npi using "$temp/FullDataCMSPANEL_final-unique-npi"

use "$temp/emiel-total_payments-fg-hcpcs-codes-unique-npi", clear

merge 1:1 npi using "$temp/cms-panel-unique-npi"


* FG is subset to Emiel CMS:
use "$temp/FullDataCMSPANEL_final-unique-npi", clear
merge 1:1 npi using "$temp/phy_time-unique-npi"

* Emiel CMS is subset to payments:
use "$temp/FullDataCMSPANEL_final-unique-npi", clear
merge 1:1 npi using "$temp/emiel-total_payments-fg-hcpcs-codes-unique-npi"

* FG is subset to payments:
use "$temp/phy_time-unique-npi", clear
merge 1:1 npi using "$temp/emiel-total_payments-fg-hcpcs-codes-unique-npi"

* Emiel final CMS is subset of CMS:
use "$temp/CMSPANEL-unique-npi", clear
merge 1:1 npi using "$temp/FullDataCMSPANEL_final-unique-npi"

* Emiel final CMS is subset of CMS (VERIFYING):
use "$dropbox/FullDataCMSPANEL_final.dta", clear
merge 1:1 npi year using "$dropbox/FullData/RawData/CMSPANEL.dta"


use "$temp/cms-panel-unique-npi", clear
merge 1:1 npi using "$temp/FullDataCMSPANEL_final-unique-npi"

use "$temp/cms-panel-unique-npi", clear
merge 1:1 npi using "$temp/phy_time-unique-npi"

use "$temp/cms-panel-unique-npi", clear
merge 1:1 npi using "$temp/emiel-total_payments-fg-hcpcs-codes-unique-npi"





use "$dropbox/FullData/RawData/CMSPANEL", clear

use "$temp/cms-panel", clear

merge m:1 npi using "/Users/simonalmerstromprzybyl/new-dropbox/Dropbox/Student Debt of Doctors/FullData/RawData/characteristics_suplemented.dta", keepusing(gradYear grd_yr)

tab _merge if grd_yr   >= $min_grad_year, m
tab _merge if gradYear >= $min_grad_year, m


use "$temp/cms-panel", clear

bys npi (grad_year) : assert grad_year[1] == grad_year[_N]

collapse (first) grad_year, by(npi)

merge 1:1 npi using ///
	"$dropbox/FullData/RawData/characteristics_suplemented.dta", ///
	keepusing(gradYear grd_yr)
	
tab _merge if grd_yr   >= $min_grad_year & !missing(grd_yr)  , m
tab _merge if gradYear >= $min_grad_year & !missing(gradYear), m

tab grad_year if grd_yr   >= $min_grad_year & !missing(grd_yr)  , m
tab grad_year if gradYear >= $min_grad_year & !missing(gradYear), m









use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

rename grad_year grad_year_old
rename our_med_school our_med_school_old
rename med_school med_school_old

merge 1:1 npi year using "$temp/cms-panel"

assert grad_year_old == grad_year if _merge == 3
assert our_med_school_old == our_med_school if _merge == 3
assert med_school_old == med_school if _merge == 3


use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

// rename grad_year grad_year_old
// rename our_med_school our_med_school_old
// rename med_school med_school_old

keep npi year

merge 1:1 npi year using "$temp/cms-panel-with-treatment"

// keep if inrange(year, 2012, 2019)
bys npi : keep if _n == 1

tab _merge, m

tab no_pay_ever, m
tab no_pay_ever if _merge == 2, m

assert no_pay_ever == 0 if _merge == 3

tab _merge if no_pay_ever != 1, m
tab _merge, m
