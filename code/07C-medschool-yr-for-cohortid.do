******************************************
*** MED SCHOOL YEARS TO ASSIGN COHORTS ***
******************************************

* INPUT: 
	* aamc-cms-npi-year level data
	* clean aamc tuition data
* OUTPUT:
	* aamc tuition data for identifying cohorts
	

use "$working_data/panels/aamc_cms_npi_year", clear

collapse (count) npi, by(med_school grad_year)

rename npi npi_count

tempfile npi_ct
save `npi_ct'

use "$working_data/panels/aamc-tuition", clear
bys med_school : g prev_year = grad_year[_n - 1]
bys med_school : g skipped_year = (grad_year - prev_year > 1)
replace skipped_year = 0 if prev_year == .

merge 1:1 med_school grad_year using `npi_ct'

drop if _merge == 2
drop _merge

bys med_school : egen total_npi = total(npi_count)
drop if total_npi == 0
drop total_npi

replace npi_count = 0 if npi_count == .

keep if grad_year > 1995
keep if grad_year < 2019

keep med_school grad_year npi_count tuition delta_tuition tuition_bill skipped_year

export delimited "$git/code/Claude Work to Identify Cohorts/cms-aamc-allmedschoolyears.csv", replace
