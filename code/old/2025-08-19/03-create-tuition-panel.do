
*************************************************************
*** CREATE TUITION PANELS FROM DOWNLOADED AAMC/IPEDS DATA ***
*************************************************************


*** AAMC ***

* Finding all sheets in the Excel and looping over them:
import excel using "$git/data/original/aamc/modified/aamc-tuition-1995-2024", describe
return list
local n_sheets `r(N_worksheet)'

local sheets
forvalues j = 1 / `n_sheets' {
	
    local sheet `r(worksheet_`j')'
	local sheets `sheets' `sheet'
	
	import excel ///
		"$git/data/original/aamc/modified/aamc-tuition-1995-2024", ///
		clear firstrow sheet("`sheet'")
	
	g grd_yr = substr("`sheet'", 1, 4)
	
	assert "`: type grd_yr'" == "str4"
	
	* Make grd_yr integer:
// 	destring grd_yr, replace // loop breaks down with this, why?
		
	save "$git/data/original/aamc/modified/aamc-tuition-`sheet'", replace
		
}

clear
foreach sheet of local sheets {
	
	append using "$git/data/original/aamc/modified/aamc-tuition-`sheet'"

}

* Make grd_yr integer:
destring grd_yr, replace

* Add one to get the right graduation year?
// replace grd_yr = grd_yr + 1 // no? Think about grd_yr vs gradYear

* Require on-campus:
keep if ResidenceStatus == "Resident"

* To replicate Emiel:
keep if CostType == "Tuition"

* Health insurance included from 2002:
// keep if ///
// 	(grd_yr <  2002 & CostType == "Tuition and Fees") | ///
// 	(grd_yr >= 2002 & CostType == "Tuition, Fees, and Health Insurance")
	
* Question: or calculate Tuition + Fees from rows so all years are the same?

* For whatever reason, ReportedCost in 2001 and 2002 contains dollar signs and commas:
replace ReportedCost = subinstr(ReportedCost, "$", "", .)
replace ReportedCost = subinstr(ReportedCost, ",", "", .)

* Make ReportedCost integer:
destring ReportedCost, replace // check why long and not int?

rename ReportedCost tuition

* Define type of school:
encode OwnershipType, gen(PublicSchool)

recode PublicSchool (1 = 0)
recode PublicSchool (2 = 1)

label define public 0 "Private" 1 "Public"
label values PublicSchool public

keep MedicalSchoolName tuition grd_yr PublicSchool

* Change to name as in our key:
rename MedicalSchoolName med_school

* Make names lower-case because of our keys (uniqueness was verified to be preserved earlier):
replace med_school = lower(med_school)

* Only care about selected schools:
merge m:1 med_school using "$git/data/working/unique-names/keys/aamc-schools-nr-obs"
keep if _merge == 3
drop _merge

// keep if our_nr_obs > $min_nr_obs // filtering

save "$git/data/original/aamc/modified/pre-aamc-tuition", replace


*** IPEDS ***

forvalues j = 2000/2023 {
	
	if !inlist(`j', 2009, 2010, 2011) { // think about the revised years
	
		* IPEDS file:
		cap import delimited "$git/data/original/ipeds/ic`j'_ay_data_stata.csv", clear

	// 	if _rc != 0 {
	//
	// 		* For some years, we use the revised files:
	// 		import delimited "$git/data/original/ipeds/ic`j'_ay_rv_data_stata.csv", clear
	//
	// 	}
		
		g int grd_yr = `j'
		
		* See dictionaries in $git/data/original/ipeds/documentation:
		rename isprof1 chiro_tuition
		rename isprof3 medic_tuition
		rename isprof4 optom_tuition
		rename isprof5 osteo_tuition
		rename isprof7 podia_tuition
		
		* Temp --- CONTINUE HERE ON MONDAY! ASSIGN CHIRO SCHOOLS TO CHIRO TUITION ETC.
		keep unitid *_tuition grd_yr
		
		tostring unitid, replace
		
		rename unitid med_school
		
		* Keep only relevant schools:
		merge m:1 med_school using "$git/data/working/unique-names/keys/aamc-schools-nr-obs"
		keep if _merge == 3
		drop _merge
		
		// keep if our_nr_obs > $min_nr_obs // filtering
		
		g 		tuition = .
		replace tuition = chiro_tuition if chiro_school == 1
		replace tuition = medic_tuition if medic_school == 1
		replace tuition = optom_tuition if optom_school == 1
		replace tuition = osteo_tuition if osteo_school == 1
		replace tuition = podia_tuition if podia_school == 1
		
		drop *_tuition
		
		drop if tuition == .
		
		save "$git/data/original/ipeds/modified/ipeds-tuition-`j'", replace
		
	}
	
}

clear
forvalues j = 2000/2023 {
	
	if !inlist(`j', 2009, 2010, 2011) { // think about the revised years
	
		append using "$git/data/original/ipeds/modified/ipeds-tuition-`j'"
		
	}

}

save "$git/data/original/ipeds/modified/pre-ipeds-tuition", replace


*** COMBINED AAMC/IPEDS PANEL ***

use          "$git/data/original/aamc/modified/pre-aamc-tuition", clear
append using "$git/data/original/ipeds/modified/pre-ipeds-tuition"

* Check so the data is unique in (school, year):
bys med_school grd_yr : assert _N == 1

order med_school grd_yr

* Drop if we only have one observation (cannot calculate increase then):
bys med_school (grd_yr) : g drop = _N == 1

drop if drop == 1
drop    drop

* Drop if tuition is constantly 0:
bys med_school (tuition) : g drop = tuition[1] == 0 & tuition[1] == tuition[_N]

drop if drop == 1
drop    drop

assert tuition != .

* Mark where chronological order is respected:
bys med_school (grd_yr) : g med_school_chrono = grd_yr[_n] == grd_yr[_n - 1] + 1

* Delta tuition:
bys med_school (grd_yr) : g delta_tuition = /// dollar amount
	tuition[_n] - tuition[_n - 1] if ///
		med_school_chrono == 1 & /// chronological order is respected
		tuition[_n - 1]   != 0    // the increase is not from zero
	
* Tuition increase:
bys med_school (grd_yr) : g tuition_increase = /// percent increase, decimal form
	delta_tuition / tuition[_n - 1] // if med_school_chrono == 1

* Find max percent tuition increase:
bys med_school (grd_yr) : egen max_tuition_increase = max(tuition_increase)

* The following check ensures that every by-group has a non-missing max:
assert max_tuition_increase != .

replace max_tuition_increase = max_tuition_increase == tuition_increase

* Temp fix below:
bys med_school (max_tuition_increase) : assert ///
	max_tuition_increase[_N - 1] == 0 & /// no ties for max
	max_tuition_increase[_N]     == 1   /// there exists a max
	if med_school != "university of connecticut school of medicine" // has ties for max

* Ignore too low dollar increases:
sum delta_tuition if max_tuition_increase == 1, d

global delta_tuition_limit = r(p75)

* Ignore too low percent increases:
// sum tuition_increase if max_tuition_increase == 1, d
//
// global tuition_increase_limit = r(p25)

   replace max_tuition_increase = 0 if    delta_tuition <    $delta_tuition_limit
// replace max_tuition_increase = 0 if tuition_increase < $tuition_increase_limit

* Year distribution of max years:
tab grd_yr if max_tuition_increase == 1, m sort

* Print the year instead of dummy:
replace max_tuition_increase = grd_yr if max_tuition_increase == 1

* Print it across the school:
bys med_school (max_tuition_increase) : replace max_tuition_increase = max_tuition_increase[_N]

* Drop years with too low dollar increases:
// drop if max_tuition_increase == 0

* Actually, keep them:
replace max_tuition_increase = . if max_tuition_increase == 0

* Total tuition during four years:
bys med_school (grd_yr) : g tot_tuition = ///
	tuition[_n - 3] + ///
	tuition[_n - 2] + ///
	tuition[_n - 1] + ///
	tuition[_n - 0] if ///
		med_school_chrono[_n - 2] == 1 & ///
		med_school_chrono[_n - 1] == 1 & ///
		med_school_chrono[_n - 0] == 1

* Defining tuition quantile:
egen Tuition_quantile = xtile(tuition), n(4) by(grd_yr) // ssc install egenmore
		
save "$git/data/original/aamc/modified/aamc-tuition", replace
use  "$git/data/original/aamc/modified/aamc-tuition", clear

* COMMENT THIS BETTER!

keep if inrange(grd_yr, $lower_year_limit, $upper_year_limit)

bys med_school grd_yr : assert _N == 1

rename grd_yr gradYear

* Adjusting for gradYear being e.g. 2001 if graduating in academic year 2000-2001:
replace gradYear = gradYear + 1

* Note that the above translation means that for everything below:
* 	For a given academic year x-y, we think of y as being the academic year
*	Previously we have thought of x as being the academic year

* Simple limit (3499 is Emiel's limit):
g delta_tuition_dummy = delta_tuition > $dollar_limit & delta_tuition != .

keep if delta_tuition_dummy == 1

keep delta_tuition_dummy med_school gradYear

expand $med_school_length + $extra_window_length

g increase_year = gradYear

bys med_school gradYear : replace gradYear = gradYear + _n - 1

g grade = increase_year - gradYear + $med_school_length

bys  med_school increase_year gradYear : assert _N == 1
sort med_school increase_year gradYear // becomes arranged by grade from large to small

replace grade = grade - 1 if grade <= 0

expand $extra_window_length + 1 if grade == $med_school_length

sort med_school increase_year gradYear grade

bys med_school increase_year gradYear grade : replace gradYear = ///
	gradYear - ($extra_window_length + 1 - _n) if grade == $med_school_length

replace grade = increase_year - gradYear + $med_school_length ///
	if grade >= $med_school_length

g 		treatment_ranking = .
replace treatment_ranking = grade if inrange(grade, 1, $med_school_length)
replace treatment_ranking = $med_school_length - grade if grade < 0
replace treatment_ranking = grade + $extra_window_length if grade > $med_school_length

bys med_school gradYear (treatment_ranking) : keep if _n == 1

drop increase_year treatment_ranking

replace delta_tuition_dummy = inrange(grade, 1, 4)

save "$temp/delta-tuition-dummy", replace

* Note, the following will give -graduation- years with high tuition increase:
// sum gradYear if grade == 1, d

* It is not "out of range": we now look at graduation years instead of start years!


// use  "$git/data/original/aamc/modified/aamc-tuition", clear
//
// * To replicate Emiel:
// keep if inrange(grd_yr, 1997, 2011)
//
// * Simple limit:
// g delta_tuition_dummy = delta_tuition > 3499 & delta_tuition != . // 3499 is Emiel's limit
//
// keep if delta_tuition_dummy == 1
//
// keep delta_tuition_dummy med_school grd_yr
//
// bys med_school grd_yr : assert _N == 1
//
// expand 4 // medical school is four years
//
// // bys med_school grd_yr : replace grd_yr = grd_yr + _n - 1 // will ensure that all cohorts affected by increase get dummy = 1
//   
//    bys med_school grd_yr : g grade_dummy = 4 - _n + 1
//    by  med_school grd_yr : replace grd_yr = grd_yr + _n
//   
// bys med_school grd_yr : keep if _n == 1 // above can have produced duplicates
//
// rename grd_yr gradYear
//
// save "$temp/delta-tuition-dummy", replace


*** OLD ***

// * Mark where panel has no gaps:
// bys med_school (grd_yr) : g        one_year_jump = grd_yr[_n] - 1 == grd_yr[_n - 1] if _n > 1
// bys med_school (grd_yr) : egen min_one_year_jump = min(one_year_jump)
//
// drop if min_one_year_jump == 0 // i.e. if there exists a gap
//
// drop *one_year_jump
//
// * Checking so panel doesn't have any gaps now:
// bys med_school (grd_yr) : assert grd_yr[_n] - 1 == grd_yr[_n - 1] if _n > 1

* Total tuition increase:
// bys med_school (grd_yr) : g tot_tuition_increase = /// percent increase, decimal form
// 	(tot_tuition[_n] - tot_tuition[_n - 1]) / tot_tuition[_n - 1] ///
// 	if _n > 4
//
// * Find large tuition increases (maybe this should be done "within year"?):
// sum tot_tuition_increase, d
//
// g treatment = tot_tuition_increase > `r(p90)' if tot_tuition_increase != .
// g control   = treatment == 0
//
// * Above/below median tuition increase:
// sum tot_tuition_increase, d
// g aboveMed_tot_tuition_increase = tot_tuition_increase > `r(p50)' if tot_tuition_increase != .
