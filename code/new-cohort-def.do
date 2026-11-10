*** DEFINE COHORTS NEW, APRIL 30 2026 ***

/*
For tuition data relevant to merge:
1. Identify 2 year cohorts for each school, including overlap.
2. Calculate tuition-bill spread
	a. Show the distrubtion of tuition-bill spread
3. Identify cohorts with $7000 tuition-bill spread
4. Eliminate cohorts based on Reset Criteria:
	a. level of tuition has changed more than $2000 between s-1 and s
	b. level of tuition has changed more than $4000 since the start of the cohort
5. See how many overlapping cohorts are left
	a. keep based on number of doctor-year observations
	b. keep based on size of tuition spread
	
Repeat for 3 year and 4 year cohorts.


Process up to two year data, which will output a list of obs_id and associated 2-year-cohorts

reload data
Produce 3 year cohorts 
Merge on two year cohorts and drop obs_id from 2-year cohorts
Identify 3 year cohorts that have cohort* (sum) < 3 (non-sequential years); this will also drop cohorts made for 2018-med_school, which is fine bc the 2K rule would also take them out
Process and output list of obs_id for 3-year cohorts

reload data
produce 4 year cohorts
merge 2-year-cohorts and 3-year-cohorts. drop obs_id if 2-year-cohort or 3-year-cohort*
Identify 4 year cohorts that have cohort* (sum) < 4 (non-sequential years)
process and output list of obs_id for 4-year cohorts

reload data
produce master dataset with all of the cohorts so far
produce 2 year cohorts, keep only the ones with cohort[obs_id] from 2-year-cohorts, assign to 2-year-cohort-column
produce 3 year cohorts, keep only the ones with cohort[obs_id] from 3-year-cohort, assign to 3-year-cohort-column
produce 4 year cohorts, keep only the ones with cohort[obs_id] from 4-year-cohort, assign to 4-year-cohort-column

check that the 2-year; 3-year; 4-year cohort columns do not overlap (maybe do this earlier to catch errors immediately)
	
*/

** retrieve tuition data relevant to merge **
use "$working_data/panels/aamc-tuition", clear
g grad_year = aca_year + 1 // Adjusting for grad_year; e.g. 2001 if graduating in academic year 2000-2001

merge 1:m med_school grad_year using "$working_data/panels/cms-panel"
bysort med_school: egen school_in_doctor = max(_merge == 3)
keep if school_in_doctor == 1 & aca_year != . // keep if the school is there and year is available in the tuition data
drop _merge

collapse (count) npi (first) tuition delta_tuition tuition_bill, by(med_school grad_year)

rename npi npi_count
sort med_school grad_year
by med_school: gen prev_year = grad_year[_n-1]

gen skipped_year = 0
by med_school: replace skipped_year = 1 if grad_year - prev_year > 1 & _n > 1  // 2 donuts: louisiana state university school of medicine in new orleans, west virginia university school of medicine

drop if grad_year >= 2019 // no npi observed for folks with grad year 2019-2025

save "$working_data/panels/cms-aamc-allmedschoolyears.dta", replace

export delimited "$working_data/panels/cms-aamc-allmedschoolyears.csv", replace

set maxvar 10000


** create cohort dummies **
use "$working_data/panels/cms-aamc-allmedschoolyears.dta", clear

* bysort school_id (grad_year): gen cohort = ceil(_n/4)
sort med_school grad_year
gen obs_id = _n
egen school_id = group(med_school)


quietly count
local total_obs = r(N)

* Create cohort variables for each observation
forvalues i = 1/`total_obs' {
    gen cohort`i' = 0
    
    * Get the school and year for observation i
    local school_i = school_id[`i']
    local year_i = grad_year[`i']
    
    * Mark all observations in the same school within 4-year window
    replace cohort`i' = 1 if school_id == `school_i' & ///
                              grad_year >= `year_i' & ///
                              grad_year <= `year_i' + 1
} 

* calculate total npi count for each cohort
preserve

foreach var of varlist cohort* {
replace `var' = `var' * npi
}
collapse (sum) cohort*
g id = 1
reshape long cohort, i(id) j(obs_id)
drop id
rename cohort total_cohort_npi
tempfile cohort_npi
save `cohort_npi'

restore

merge 1:1 obs_id using `cohort_npi'
drop _merge

* calculate the total tuition delta for each cohort (ensures that the tuition delta is less than $4000 total)
// tuition reset 2: the level of tuition has changed more than $4,000 since the start of the most recent cohort*
// the cumulative tuition change within that cohort > 4
// sum of delta_tuition over the cohort

preserve

foreach var of varlist cohort* {
	replace `var' = `var' * delta_tuition // 1 or 0 * delta_tuition
}
collapse (sum) cohort*
g id = 1
reshape long cohort, i(id) j(obs_id)
drop id
rename cohort tuition_delta_cohort
tempfile tdelta
save `tdelta'

restore

merge 1:1 obs_id using `tdelta'
drop _merge


* Calculate tuition spread for each  cohort
sort med_school grad_year
quietly count
local total_obs = r(N)

forvalues i = 1/`total_obs' {
    bysort cohort`i': egen max_tuition`i' = max(tuition_bill) if cohort`i' == 1
    bysort cohort`i': egen min_tuition`i' = min(tuition_bill) if cohort`i' == 1
    gen tuition_spread`i' = max_tuition`i' - min_tuition`i' 
    drop max_tuition`i' min_tuition`i'
}

sort med_school grad_year

save "$working_data/panels/intermediate-2y-cohorts", replace

* number of cohorts 
* cdf of cohorts by spread

use "$working_data/panels/intermediate-2y-cohorts", clear


keep tuition_spread*
collapse tuition_spread*
g id = 1
tempfile tspread
save `tspread'


tempfile final
local first = 1

forvalues start = 1(650)2865 {
    local end = min(`start' + 649, 2865)
    
    use `tspread', clear
    
    keep id tuition_spread`start'-tuition_spread`end'
    
    reshape long tuition_spread, i(id) j(cohort_id)
    
    if `first' == 1 {
        save `final', replace
        local first = 0
    }
    else {
        append using `final'
        save `final', replace
    }
}

use `final', clear

sort tuition_spread
bys tuition_spread: g n_ids = _N
bys tuition_spread: keep if _n == 1
g c_count = sum(n_ids)

sum cohort_id

twoway line c_count tuition_spread, title("CDF of Tuition Bill Spread") ytitle("Number of Cohorts") xtitle("Tuition Bill Spread (Thousands)") xline(10) note("Line drawn at $10,000 tuition bill spread. Total number of cohorts is `r(max)'.")

graph export "$figures/number_cohorts_tbillspread.png", replace



* identify cohorts with small yoy tuition change (<2000) or large cohort tuition change (>4000)
use "$working_data/panels/intermediate-2y-cohorts", clear

g small_tuition_change = .
g large_tuition_change = .
g small_tuition_spread = .

quietly count
local total_obs = r(N)

forvalues i = 1/`total_obs'{
	replace small_tuition_change = 1 if (delta_tuition < 2)
	replace large_tuition_change = 1 if (tuition_delta_cohort > 4)
	replace small_tuition_spread = 1 if (tuition_spread`i' < 7 & tuition_spread`i' != .)
}

sort med_school grad_year

* apply 2K and 4K rules
gen master_index = obs_id if !missing(small_tuition_change) | !missing(large_tuition_change)

levelsof master_index, local(m_i)

foreach s of local m_i {
	drop cohort`s'
	drop tuition_spread`s'
}

* CDF of cohorts after first two constraints applied
preserve

collapse tuition_spread*
g id = 1
reshape long tuition_spread, i(id) j(cohort_number)
drop id

sort tuition_spread
bys tuition_spread: g n_ids = _N
bys tuition_spread: keep if _n == 1
g c_count = sum(n_ids)

sum c_count

twoway line c_count tuition_spread, title("CDF of Tuition Bill Spread") ytitle("Number of Cohorts") xtitle("Tuition Bill Spread (Thousands)") xline(10) note("Line drawn at $10,000 tuition bill spread. Total number of cohorts is `r(max)'." "2K rule and 4K rule applied." "Tuition Spread = 0 for cohorts that start at first observation of med school (no tuition bill for first three years)" "or the cohort starts on the last observation of med school (tuition bill only available for one year)")

graph export "$figures/number_cohorts_tbillspread_constraints.png", replace

restore

* identify cohorts with small tuition spread (tuition spread < 7K)
g master_index2 = obs_id if !missing(small_tuition_spread)
replace master_index2 = . if master_index == master_index2

sort med_school grad_year

* drop cohorts with small tuition spread between years
levelsof master_index2, local(m_i2)

foreach s of local m_i2 {
	drop cohort`s'
	drop tuition_spread`s'
}

* CDF of cohorts after 7K tuition spread applied
preserve

collapse tuition_spread*
g id = 1
reshape long tuition_spread, i(id) j(cohort_number)
drop id

sort tuition_spread
bys tuition_spread: g n_ids = _N
bys tuition_spread: keep if _n == 1
g c_count = sum(n_ids)
sum c_count

twoway line c_count tuition_spread, title("CDF of Tuition Bill Spread") ytitle("Number of Cohorts") xtitle("Tuition Bill Spread (Thousands)") xline(10) note("Line drawn at $10,000 tuition bill spread. Total number of cohorts is `r(max)'." "2K rule, 4K rule and tuition spread > 7K rule applied." "Tuition Spread = 0 for cohorts that start at first observation of med school (no tuition bill for first three years)" "or the cohort starts on the last observation of med school (tuition bill only available for one year)")

graph export "$figures/number_cohorts_tbillspread_allconstraints.png", replace

restore


* check school-year observations with multiple cohorts
egen cohort_count = rowtotal(cohort*)

sort med_school grad_year
g multi_cohort_index = obs_id if cohort_count > 1

replace multi_cohort_index = . if multi_cohort_index == master_index | multi_cohort_index == master_index2 // these have already been dropped
replace multi_cohort_index = obs_id if multi_cohort_index[_n + 1] != . // these are the cohorts to compare with

* save dataset before selecting final cohorts
save "$working_data/panels/intermediate-2y-cohorts", replace

* select final cohorts based on npi observations
use "$working_data/panels/intermediate-2y-cohorts", clear

** identify overlapping cohorts to drop based on total npi observations
drop tuition_spread*
g all_dropped = master_index
replace all_dropped = master_index2 if all_dropped == .
reshape long cohort, i(obs_id all_dropped) j(cohort_id)
keep if cohort == 1
keep if all_dropped == .

bys obs_id : g n_obs_id = _N
bys cohort_id : g n_cohort_id = _N
g dd = n_obs_id * n_cohort_id
keep if dd > 1 // keeps instances where the obs_id and cohort_id appear more than once in their respective columns --> observations with overlapping cohorts

drop dd n_obs_id n_cohort_id

gsort cohort_id -npi

bys cohort_id : drop if _n == 1 // drops cohorts with more npi observations

rename cohort_id drop_cohorts
levelsof drop_cohorts, local(dc)

** drop the cohorts with fewer npi
use "$working_data/panels/intermediate-cohorts", clear

foreach m of local dc {
	drop cohort`m' tuition_spread`m'
}

** count the cohorts again
egen cohort_count2 = rowtotal(cohort*)
replace cohort_count2 = cohort_count2 - cohort_count // this categorized 341 school-year observations as cohorts
total(npi) if cohort_count2 == 1 // 173,203

drop cohort_count*
collapse cohort*
g id = 1
reshape long cohort, i(id) j(cohort_id) // makes 91 cohorts


* select final cohorts based on largest tuition spread
use "$working_data/panels/intermediate-cohorts", clear
g all_dropped = master_index
replace all_dropped = master_index2 if all_dropped == .

reshape long cohort tuition_spread, i(obs_id master_index) j(drop_cohorts)
keep if cohort == 1
keep if all_dropped == .
duplicates t obs_id, g(dups)
keep if dups == 1
sort obs_id tuition_spread // smaller tuition spread first
bys obs_id : keep if _n == 1 // keep obs_id with smaller tuitions spread to make list to drop
levelsof drop_cohorts, local(dc_ts)

use "$working_data/panels/intermediate-cohorts", clear
foreach m of local dc_ts {
drop cohort`m' tuition_spread`m'
}

** count the cohorts again
egen cohort_count2 = rowtotal(cohort*)
replace cohort_count2 = cohort_count2 - cohort_count // this made 345 cohorts

total(npi) if cohort_count2 == 1 // 177,827 doctor-year observations

drop cohort_count*
collapse cohort*
g id = 1
reshape long cohort, i(id) j(cohort_id)
duplicates drop
total(id) // 92 cohorts

* checking for donuts in the merged dataset
use "$working_data/panels/aamc-tuition", clear
g grad_year = aca_year + 1 // Adjusting for grad_year; e.g. 2001 if graduating in academic year 2000-2001

merge 1:m med_school grad_year using "$working_data/panels/cms-panel"
keep if _merge == 3
drop _merge

collapse (count) npi (first) tuition delta_tuition tuition_bill, by(med_school grad_year)

sort med_school grad_year
by med_school: gen prev_year = grad_year[_n-1]

gen skipped_year = 0
by med_school: replace skipped_year = 1 if grad_year - prev_year > 1 & _n > 1 // 8 donuts


* redo cohort count and multi cohort index
/*
drop cohort_count multi_cohort_index
egen cohort_count = rowtotal(cohort*)
sort med_school grad_year
g multi_cohort_index = obs_id if cohort_count > 1
*/

* pick the one with most doctor-year in the cms data
** how many cohorts: 91
** how many doctor-year observations: 173,203
** how many cohorts have doctor-year observations in each year (fully populated): all

* pick based on largest spread
** how many cohorts: 92
** how many doctor-year observations: 177,827
** how many cohorts have doctor-year observations in each year (fully populated): all


* check for donuts in school-tuition-year 