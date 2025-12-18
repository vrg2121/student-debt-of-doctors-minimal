/* 

PREAMBLE

Figures to Explore Data
   
Victoria Garcia 
December, 2025
*/

clear

use "$working_data/aamc_cms_cohort_character.dta", clear

tab cvar, generate(c)
label variable c1 "1 Year Cohort"
label variable c2 "2 Year Cohort"
label variable c3 "3 Year Cohort"
label variable c4 "4 Year Cohort"

tab cohort_reason, generate(r_)
rename r_1 four_yr_cohort
rename r_2 first_yr_data
rename r_3 tuition_change

label variable four_yr_cohort "Four Year Cohort"
label variable first_yr_data "First Year of Data"
label variable tuition_change "Tuition Change ($2000 2014USD)"

global tot_2012_schools = .
global tot_2013_schools = .
global tot_2014_schools = .
global tot_2015_schools = .
global tot_2016_schools = .
global tot_2017_schools = .
global tot_2018_schools = .
global tot_2019_schools = .

forval y = 2012/2019 {
	preserve
	keep if year == `y'
	unique school_id
	global tot_`y'_schools = r(unique)
	restore
}

* GRAPH FREQUENCY OF COHORT LENGTH *
graph bar (percent), over(cvar) title("Frequency of Cohort Length") note("large tuition delta = $2000 (2014 USD)")
graph bar (count), over(cvar) title("Count of Cohort Length") note("large tuition delta = $2000 (2014 USD)")

preserve

collapse (sum) c1 c2 c3 c4
egen tot = rowtotal(c1 c2 c3 c4)
gen pct_c1 = (c1 / tot) * 100
gen pct_c2 = (c2 / tot) * 100
gen pct_c3 = (c3 / tot) * 100
gen pct_c4 = (c4 / tot) * 100

label variable pct_c1 "1 Year Cohort (%)"
label variable pct_c2 "2 Year Cohort (%)"
label variable pct_c3 "3 Year Cohort (%)"
label variable pct_c4 "4 Year Cohort (%)"

graph bar (asis) pct_c1 pct_c2 pct_c3 pct_c4, title("Frequency of Cohort Lengths") ytitle("Percent")

restore

* NUMBER OF COHORT-GROUP RESETS DUE TO LARGE PRICE INCREASE EACH YEAR *

preserve

collapse (sum) four_yr_cohort first_yr_data tuition_change, by(year)
egen tot = rowtotal(four_yr_cohort first_yr_data tuition_change)
gen pct_four_yr_cohort = (four_yr_cohort / tot) * 100
gen pct_first_yr_data = (first_yr_data / tot) * 100
gen pct_tuition_change = (tuition_change / tot) * 100

label variable pct_four_yr_cohort "Four Year Cohort (%)"
label variable pct_first_yr_data "First Year of Data (%)"
label variable pct_tuition_change "Tuition Change (%)"

gen pct_tuition_tot_school = .
label variable pct_tuition_tot_school "% Cohort-Grp by Tuition Change / Total Schools"

replace pct_tuition_tot_school = pct_tuition_change / $tot_2012_schools if year == 2012
replace pct_tuition_tot_school = pct_tuition_change / $tot_2013_schools if year == 2013
replace pct_tuition_tot_school = pct_tuition_change / $tot_2014_schools if year == 2014
replace pct_tuition_tot_school = pct_tuition_change / $tot_2015_schools if year == 2015
replace pct_tuition_tot_school = pct_tuition_change / $tot_2016_schools if year == 2016
replace pct_tuition_tot_school = pct_tuition_change / $tot_2017_schools if year == 2017
replace pct_tuition_tot_school = pct_tuition_change / $tot_2018_schools if year == 2018
replace pct_tuition_tot_school = pct_tuition_change / $tot_2019_schools if year == 2019

gen pct_tuition_4yr_tot_school = .
label variable pct_tuition_4yr_tot_school "% Cohort-Grp by Tuition or 4yr / Total Schools"

replace pct_tuition_4yr_tot_school = (pct_tuition_change + pct_four_yr_cohort) / $tot_2012_schools if year == 2012
replace pct_tuition_4yr_tot_school = (pct_tuition_change + pct_four_yr_cohort) / $tot_2013_schools if year == 2013
replace pct_tuition_4yr_tot_school = (pct_tuition_change + pct_four_yr_cohort) / $tot_2014_schools if year == 2014
replace pct_tuition_4yr_tot_school = (pct_tuition_change + pct_four_yr_cohort) / $tot_2015_schools if year == 2015
replace pct_tuition_4yr_tot_school = (pct_tuition_change + pct_four_yr_cohort) / $tot_2016_schools if year == 2016
replace pct_tuition_4yr_tot_school = (pct_tuition_change + pct_four_yr_cohort) / $tot_2017_schools if year == 2017
replace pct_tuition_4yr_tot_school = (pct_tuition_change + pct_four_yr_cohort) / $tot_2018_schools if year == 2018
replace pct_tuition_4yr_tot_school = (pct_tuition_change + pct_four_yr_cohort) / $tot_2019_schools if year == 2019

graph bar (asis) pct_tuition_change pct_first_yr_data pct_four_yr_cohort, over(year) title("Frequency of Reasons for Cohort Group Resets by Year") note("Tuition change corresponds to large tuition delta = $2000 (2014 USD)") ytitle("Percent")

graph bar (asis) pct_tuition_change, over(year) title("Frequency of Cohort-Group Resets Due to Large Tuition") note("Tuition change corresponds to large tuition delta = $2000 (2014 USD)") ytitle("Percent")

graph bar (asis) tuition_change, over(year) title("Count of Cohort-Group Resets Due to Large Tuition") note("Tuition change corresponds to large tuition delta = $2000 (2014 USD)") ytitle("Number of Cohorts")

// C-G Reset due to large tuition change
graph bar (asis) pct_tuition_tot_school, over(year) title("% Tuition Change Resets by Number of Schools per Year") ytitle("% C-G Change Due to Tuition / Total Number of Schools") note("Tuition change corresponds to large tuition delta = $2000 (2014 USD)")

// C-G Reset due to large tuition change or 4 year rule
graph bar (asis) pct_tuition_4yr_tot_school, over(year) title("% Tuition or 4 Year Resets by Number of Schools per Year") ytitle("% C-G Change Tuition or 4yr / Total Number of Schools") note("Tuition change corresponds to large tuition delta = $2000 (2014 USD)")

// fraction of C-G due to large price increase
graph bar (asis) pct_four_yr_cohort pct_first_yr_data pct_tuition_change, over(year) title("Frequency of Reasons for C-G Resets by Year") ytitle("Percent") note("Tuition change corresponds to large tuition delta = $2000 (2014 USD)") blabel(bar, position(outside) format(%9.0f) color(black))


restore

* NUMBER OF C-G RESETS DUE TO TUITION CHANGE / SCHOOL *
use "$working_data/aamc_large_id_cohort_analysis.dta", clear

tab cohort_reason, generate(r_)
rename r_1 four_yr_cohort
rename r_2 first_yr_data
rename r_3 tuition_change

label variable four_yr_cohort "Four Year Cohort"
label variable first_yr_data "First Year of Data"
label variable tuition_change "Tuition Change ($2000 2014USD)"

preserve

// for all years
collapse (sum) four_yr_cohort first_yr_data tuition_change, by(school_id)
tab tuition_change, generate(t_)

rename t_1 tuition_cnt_0
rename t_2 tuition_cnt_1
rename t_3 tuition_cnt_2
rename t_4 tuition_cnt_3
rename t_5 tuition_cnt_4
rename t_6 tuition_cnt_5
rename t_7 tuition_cnt_6
rename t_8 tuition_cnt_7
rename t_9 tuition_cnt_8

label variable tuition_cnt_0 "0 Changes due to Tuition"
label variable tuition_cnt_1 "1 Changes due to Tuition"
label variable tuition_cnt_2 "2 Changes due to Tuition"
label variable tuition_cnt_3 "3 Changes due to Tuition"
label variable tuition_cnt_4 "4 Changes due to Tuition"
label variable tuition_cnt_5 "5 Changes due to Tuition"
label variable tuition_cnt_6 "6 Changes due to Tuition"
label variable tuition_cnt_7 "7 Changes due to Tuition"
label variable tuition_cnt_8 "8 Changes due to Tuition"

keep tuition_cnt*
g n = _n
reshape long tuition_cnt_, i(n)
label define _j 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8"
label values _j _j

graph bar (sum) tuition_cnt_, over(_j, label) blabel(total) title("Number of Large Tuition Cohort Change Events per School") ytitle("Number of Schools") note("Large Tuition Change = $2000 (2014USD). All years and all schools in AAMC data. 154 schools.")

restore

// school_id found in merged data (cms and aamc)
preserve

merge 1:m med_school grad_year using "$working_data/panels/cms-panel"
keep if _merge == 1 // keep only the school-year data
drop _merge

tab cohort_reason, generate(r_)
rename r_1 four_yr_cohort
rename r_2 first_yr_data
rename r_3 tuition_change

label variable four_yr_cohort "Four Year Cohort"
label variable first_yr_data "First Year of Data"
label variable tuition_change "Tuition Change ($2000 2014USD)"

collapse (sum) four_yr_cohort first_yr_data tuition_change, by(school_id)
tab tuition_change, generate(t_)

rename t_1 tuition_cnt_0
rename t_2 tuition_cnt_1
rename t_3 tuition_cnt_2


label variable tuition_cnt_0 "0 Changes due to Tuition"
label variable tuition_cnt_1 "1 Changes due to Tuition"
label variable tuition_cnt_2 "2 Changes due to Tuition"

keep tuition_cnt*
g n = _n
reshape long tuition_cnt_, i(n)
label define _j 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8"
label values _j _j

graph bar (sum) tuition_cnt_, over(_j, label) blabel(total) title("Number of Large Tuition Cohort Change Events per School") ytitle("Number of Schools") note("Large Tuition Change = $2000 (2014USD). Years and schools in AAMC and CMS data. 154 schools.")

restore

* LARGE RELATIVE PRICE INCREASE AND REAL LEVEL OF TUITION INCREASE *
// using data from rel_lg_delta

use "$working_data/aamc_large_id_cohort_analysis.dta", clear

preserve

merge 1:m med_school grad_year using "$working_data/panels/cms-panel"
keep if _merge == 1 // keep only the school-year data
drop _merge

keep school_id delta_tuition pct_delta rel_lg_delta cohort_reason grad_year med_school

keep if rel_lg_delta == 1
drop if delta_tuition < 0

g delta_tuition_th = delta_tuition * 1000

g n = _n

graph bar (asis) delta_tuition_th, over(n) title("Real Level of Tuition Increase and Large Relative Price Increase") ytitle("Real Tuition Increase (2014 USD)") note("Large Tuition Change = 7% or greater increase in tuition across all time and schools." "School-Year data available in merged data (CMS and AAMC)." "Grad Years 2004-2025." "Outliers Dropped: Tuition Change < 0")

graph bar (mean) delta_tuition_th (median) delta_tuition_th, title("Mean and Median of Tuition Increase in Thsnds") ytitle("Real Tuition (2014 USD)") note("Large Tuition Change = 7% or greater increase in tuition across all time and schools." "School-Year data available in merged data (CMS and AAMC)." "Grad Years 2004-2025." "Outliers Dropped: Tuition Change < 0.") blabel(bar, position(outside) format(%9.0f) color(black))

drop if delta_tuition_th > 15000

drop n 
g n = _n

graph bar (asis) delta_tuition_th, over(n) title("Real Level of Tuition Increase and Large Relative Price Increase") ytitle("Real Tuition Increase (2014 USD)") note("Large Tuition Change = 7% or greater increase in tuition across all time and schools." "School-Year data available in merged data (CMS and AAMC)." "Grad Years 2004-2025." "Outliers Dropped: Tuition Change < 0. Tuition Change > $15,000 (2014USD).")

graph bar (mean) delta_tuition_th (median) delta_tuition_th, title("Mean and Median of Tuition Increase in Thsnds") ytitle("Real Tuition (2014 USD)") note("Large Tuition Change = 7% or greater increase in tuition across all time and schools." "School-Year data available in merged data (CMS and AAMC)." "Grad Years 2004-2025." "Outliers Dropped: Tuition Change < 0. Tuition Change > $15,000 (2014USD).") blabel(bar, position(outside) format(%9.0f) color(black))

restore

keep school_id delta_tuition pct_delta rel_lg_delta cohort_reason grad_year med_school

keep if rel_lg_delta == 1
drop if delta_tuition < 0

g delta_tuition_th = delta_tuition * 1000

sort delta_tuition_th
g n = _n

graph bar (asis) delta_tuition_th, over(n) title("Real Level of Tuition Increase and Large Relative Price Increase") ytitle("Real Tuition Increase (2014 USD)") note("Large Tuition Change = 7% or greater increase in tuition across all time and schools." "School-Year data available in AAMC data." "Grad Years 1996-2025." "Outliers Dropped: Tuition Change < 0" "Count of School-Year Rel Large Tuition Increase = 360.")

graph bar (mean) delta_tuition_th (median) delta_tuition_th, title("Mean and Median of Tuition Increase") ytitle("Real Tuition (2014 USD)") note("Large Tuition Change = 7% or greater increase in tuition across all time and schools." "School-Year data available in AAMC data." "Grad Years 1996-2025." "Outliers Dropped: Tuition Change < 0." "Count of Rel Large Tuition Increase = 360.") blabel(bar, position(outside) format(%9.0f) color(black))

drop if delta_tuition_th > 15000

sort delta_tuition_th
drop n 
g n = _n

graph bar (asis) delta_tuition_th, over(n) title("Real Level of Tuition Increase and Large Relative Price Increase") ytitle("Real Tuition Increase (2014 USD)") note("Large Tuition Change = 7% or greater increase in tuition across all time and schools." "School-Year data available in merged data (CMS and AAMC)." "Grad Years 2004-2025." "Outliers Dropped: Tuition Change < 0. Tuition Change > $15,000 (2014USD)." "Count of School-Year Rel Large Tuition Increase = 355.")

graph bar (mean) delta_tuition_th (median) delta_tuition_th, title("Mean and Median of Tuition Increase") ytitle("Real Tuition (2014 USD)") note("Large Tuition Change = 7% or greater increase in tuition across all time and schools." "School-Year data available in merged data (CMS and AAMC)." "Grad Years 2004-2025." "Outliers Dropped: Tuition Change < 0. Tuition Change > $15,000 (2014USD)." "Count of Rel Large Tuition Increase = 355.") blabel(bar, position(outside) format(%9.0f) color(black))

// school_id

// create a dict for each dum_* that categorizes based on number of years
// use the merged data to identify which cohort they belong to and merge on the category variable

* frequency of resets due to large price increase relative to number of schools in sample / year
// large price increase (year) / number of schools (year)