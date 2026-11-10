*******************************************
*** CMS AND CMS E/M PAYMENTS DATA STATS ***
*******************************************

*** HOW MANY DOCTORS HAVE YEARS SKIPPED IN THE DATA? HOW MANY RETURN? ***

use "$working_data/cms_aamc_cohort_id.dta", clear

preserve

* missing cms payments
g missing_payments = 1 if missing(fg_sel3_total_payments)
replace missing_payments = 0 if missing_payments != 1
tab missing_payments

drop if missing(fg_sel3_total_payments)
keep npi year

// how many years observed per npi
bysort npi: g years_obs = _N
tab years_obs

// how many npi have gaps (approx 1.5%, most drop from data if incomplete)
bysort npi (year): gen year_gap = (year - year[_n-1] > 1) if _n > 1
tab year_gap

restore

preserve
* missing cms e/m payments
g missing_payments = 1 if missing(fg_sel5_total_payments)
replace missing_payments = 0 if missing_payments != 1
tab missing_payments

drop if missing(fg_sel5_total_payments)
keep npi year

// how many years observed per npi
bysort npi: g years_obs = _N
tab years_obs

// how many npi have gaps
bysort npi (year): gen year_gap = (year - year[_n-1] > 1) if _n > 1
tab year_gap

restore

* missing cms or cms e/m payments
g missing_payments = 1 if missing(fg_sel3_total_payments) | missing(fg_sel5_total_payments)
replace missing_payments = 0 if missing_payments != 1
tab missing_payments

drop if missing(fg_sel3_total_payments) | missing(fg_sel5_total_payments)
keep npi year

// how many years observed per npi
bysort npi: g years_obs = _N
tab years_obs

// how many npi have gaps (approx 1.7%, most drop from data if incomplete)
bysort npi (year): gen year_gap = (year - year[_n-1] > 1) if _n > 1
tab year_gap


******************************************
*** CDFs FOR DATA USED IN REGRESSIONS ****
******************************************

global payments "fg_sel3_total_payments fg_sel5_total_payments"

foreach pymt of global payments{
		use "$working_data/cms_aamc_cohort_id.dta", clear

		drop if missing(`pymt')

		drop if med_school == "medical university of south carolina college of medicine" // incorrect tuition data

		sort npi
		egen tag = tag(npi)
		keep if tag == 1

		keep tuition_bill cohort_id med_school grad_year

		bysort cohort_id: egen max_tbill = max(tuition_bill)
		bysort cohort_id: egen min_tbill = min(tuition_bill)
		g spread = max_tbill - min_tbill
		label variable spread "Tuition Spread (Thousands)"

		sort cohort_id
		egen tag = tag(cohort_id)
		keep if tag == 1
		drop tag

		** By Cohort **

		preserve 

		cumul spread, gen(c)
		sort c
		replace c = c * 100
		label variable c "% of Cohorts"

		line c spread

		graph export "$figures/cdf_spread_cohorts_cmspymts_`pymt'.png", width(800) height(600) replace

		keep if spread > 1 // tuition spread > $1000 USD2014

		drop c 

		cumul spread, gen(c)
		sort c
		replace c = c * 100
		label variable c "% of Cohorts"

		line c spread
		graph export "$figures/cdf_spread_cohorts_variation_cmspymts_`pymt'.png", width(800) height(600) replace

		restore


		** By Doc within Cohort **
		preserve

		bysort cohort_id : egen cdoc = count(cohort_id)

		egen tdoc = total(cdoc)
		g pdoc = (cdoc / tdoc) * 100

		sort spread pdoc

		g cu_pdoc = sum(pdoc)
		label variable cu_pdoc "% of Doctors within Cohorts"

		line cu_pdoc spread

		graph export "$figures/cdf_spread_doctors_cmspymts_`pymt'.png", width(800) height(600) replace

		drop tdoc pdoc cu_pdoc

		keep if spread > 1 // tuition spread > $1000 USD2014

		egen tdoc = total(cdoc)
		g pdoc = (cdoc / tdoc) * 100

		sort spread pdoc

		g cu_pdoc = sum(pdoc)
		label variable cu_pdoc "% of Doctors within Cohorts"

		line cu_pdoc spread

		graph export "$figures/cdf_spread_doctors_variation_cmspymts_`pymt'.png", width(800) height(600) replace
		
		restore
}