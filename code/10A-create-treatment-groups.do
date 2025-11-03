
****************************************************************
*** DEFINE GRADE PER (SCHOOL, GRAD YEAR) FOR TREATED SCHOOLS ***
****************************************************************

* Description of this do-file:

* The purpose of this code is the create the mapping:

* 	If a doctor attended a treated school and graduated in a certain year,
*	then what grade was the doctor in when the treatment happened?
*	That is, how many years was the doctor treated?

* We need to be careful since treatment at school can occur multiple times
* E.g. in both 2000 and 2001, or even more times

****************************************************************
****************************************************************
****************************************************************



use "$temp/aamc-tuition", clear

* Check so panel is still well-behaved:
bys med_school aca_year : assert _N == 1

* We want everyone to have graduated before we look at outcomes (maybe not necessary):
// keep if inrange(aca_year, $lower_year_limit, $upper_year_limit)

* For later use:
bys med_school (aca_year) : g min_aca_year = aca_year[1]
bys med_school (aca_year) : g max_aca_year = aca_year[_N]

* Keep only treated pairs of (school, grad year):
keep if delta_tuition > $dollar_limit & delta_tuition != .

egen shock_id = group(med_school aca_year)

save "$temp/all-tuition-shocks", replace
use  "$temp/all-tuition-shocks", clear

*** Non-overlapping -- needs to be at least 5 year time difference before and after shock ***

bys med_school (aca_year) : g backward_delta = aca_year[_n]     - aca_year[_n - 1]
bys med_school (aca_year) : g  forward_delta = aca_year[_n + 1] - aca_year[_n]

* TAKE AWAY THE PLUS ONE HERE (MAYBE ONLY FOR THE BACKWARD, THINK):
bys med_school (aca_year) : replace backward_delta = aca_year - min_aca_year + 1 if _n == 1
bys med_school (aca_year) : replace  forward_delta = max_aca_year - aca_year + 1 if _n == _N

* Keep relevant shocks:
   keep if backward_delta >= 5 & forward_delta >= 5
// keep if backward_delta >= 5
// keep if                       forward_delta >= 5

drop *_delta

* Shock nr per school (first, second, etc):
bys med_school (aca_year) : g nr_shocks = _n

* Max shock (can be multiple):
bys med_school : egen max_delta_tuition = max(delta_tuition)

g max_shock = delta_tuition == max_delta_tuition

* Choose max:
// keep if max_shock == 1
//
// * When necessary:
// // bys med_school (aca_year) : keep if _n == 1 // careful here!
// // bys med_school : drop if _N > 1
//
// bys med_school : assert _N == 1

* Continuing:
keep med_school aca_year delta_*tuition shock_id max_shock nr_shocks

* Adjusting for grad_year being e.g. 2001 if graduating in academic year 2000-2001:
g grad_year = aca_year + 1

drop aca_year

* Note that the above translation means that for everything below:
* 	For a given academic year x-y, we think of y as being the academic year
*	Previously we have thought of x as being the academic year

*** The following section expands our selection into a panel and defines grade ***


* Expand into panel, including grades below zero:
expand $med_school_length + $extra_window_length

g increase_year = grad_year // will adjust this later

* Build a timeline:
bys med_school grad_year : replace grad_year = grad_year + _n - 1

* Check so panel is well-behaved:
bys med_school increase_year grad_year : assert _N == 1

* Define grade:
g grade = increase_year - grad_year + $med_school_length

* Adjust to skip zero grade (go from -1 to 1 instead of -1, 0, 1):
// replace grade = grade - 1 if grade <= 0

* Expand to grades above 4:
expand $extra_window_length + 1 if grade == $med_school_length

sort med_school increase_year grad_year grade

bys med_school increase_year grad_year grade : replace grad_year = ///
	grad_year - ($extra_window_length + 1 - _n) if grade == $med_school_length

replace grade = increase_year - grad_year + $med_school_length ///
	if grade >= $med_school_length

preserve

* Check so panel is well-behaved:
keep if inrange(grade, 2, 5)
bys med_school grad_year : assert _N == 1

restore
	
* In case a pair (school, grad year) has multiple grades, choose the most relevant:
g 		treatment_ranking = .
replace treatment_ranking = grade if inrange(grade, 2, $med_school_length + 1)
replace treatment_ranking = 6 if grade == 1
replace treatment_ranking = $med_school_length + 3 - grade if grade <= 0
replace treatment_ranking = grade + $extra_window_length + 1 if grade > $med_school_length + 1

bys med_school grad_year (treatment_ranking) : keep if _n == 1

drop /* increase_year */ treatment_ranking
	
* Observations we care about:
// keep if inrange(grade, 2, 5)

* Check so panel is well-behaved:
bys med_school grad_year : assert _N == 1

* Easier to think in terms of:
g years_treated = 5 - grade

* Define potential dummy here:
g delta_tuition_dummy = grade == 2 if inlist(years_treated, 0, 3)

replace increase_year = increase_year - 1 // adjusting back to academic year
rename  increase_year   increase_aca_year // and therefore changing name

save "$temp/treatment-data", replace





