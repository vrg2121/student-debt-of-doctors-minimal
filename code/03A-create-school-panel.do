
*************************************************************
*** CREATE TUITION PANELS FROM DOWNLOADED AAMC/IPEDS DATA ***
*************************************************************

* Description of this do-file:

* 	Takes a prepared Excel for AAMC tuition and creates a panel for the AAMC schools
*	Takes files for IPEDS tuition and creates a panel for the IPEDS schools
* 	Combines the AAMC an IPEDS panels into one panel
*	For this combined panel we calculate tuition across four years, etc

* Note: Simon suggests skipping IPEDS?

*************************************************************
*************************************************************
*************************************************************



*** AAMC ***

* Finding all sheets in the Excel and looping over them:
import excel using "$git/data/original/aamc/excels/modified/data/aamc-tuition-1995-2024", describe
return list
local n_sheets `r(N_worksheet)'

local sheets
forvalues j = 1 / `n_sheets' {
	
    local sheet `r(worksheet_`j')'
	local sheets `sheets' `sheet'
	
	import excel ///
		"$git/data/original/aamc/excels/modified/data/aamc-tuition-1995-2024", ///
		clear firstrow sheet("`sheet'")
	
	g aca_year = substr("`sheet'", 1, 4)
	
	assert "`: type aca_year'" == "str4"
	
	* Make aca_year integer:
// 	destring aca_year, replace // loop breaks down with this, why?
		
	save "$temp/aamc-tuition-`sheet'", replace
		
}

clear
foreach sheet of local sheets {
	
	append using "$temp/aamc-tuition-`sheet'"

}

* Make aca_year integer:
destring aca_year, replace

* Require on-campus:
keep if ResidenceStatus == "Resident"

* To replicate Emiel:
keep if CostType == "Tuition"

* Health insurance included from 2002:
// keep if ///
// 	(aca_year <  2002 & CostType == "Tuition and Fees") | ///
// 	(aca_year >= 2002 & CostType == "Tuition, Fees, and Health Insurance")
	
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

keep MedicalSchoolName tuition aca_year PublicSchool

* Change to name as in our key:
rename MedicalSchoolName med_school

* Make names lower-case because of our keys (uniqueness was verified to be preserved earlier):
replace med_school = lower(med_school)

* Only care about selected schools:
   merge m:1 med_school using "$temp/aamc-schools-nr-obs"
// keep if _merge == 3
   drop if _merge == 2
   drop _merge

// keep if our_nr_obs > $min_nr_obs // filtering

save "$temp/pre-aamc-tuition", replace


*** IPEDS ***

forvalues j = 2000/2023 {
	
	if !inlist(`j', 2009, 2010, 2011) { // think about the revised years
	
		* IPEDS file:
		cap import delimited "$git/data/original/ipeds/data/ic`j'_ay_data_stata.csv", clear

	// 	if _rc != 0 {
	//
	// 		* For some years, we use the revised files:
	// 		import delimited "$git/data/original/ipeds/data/ic`j'_ay_rv_data_stata.csv", clear
	//
	// 	}
		
		g int aca_year = `j'
		
		* See dictionaries in $git/data/original/ipeds/data/documentation:
		rename isprof1 chiro_tuition
		rename isprof3 medic_tuition
		rename isprof4 optom_tuition
		rename isprof5 osteo_tuition
		rename isprof7 podia_tuition
		
		keep unitid *_tuition aca_year
		
		tostring unitid, replace
		
		rename unitid med_school
		
		* Keep only relevant schools:
		merge m:1 med_school using "$temp/aamc-schools-nr-obs"
// 		keep if _merge == 3
		drop if _merge == 2
		drop _merge
		
// 		keep if our_nr_obs > $min_nr_obs // filtering
		
		* Comment from Simon 2025-10-21:
		
		*	Redo this by merging in the school name from the IPEDS name-unitid key-file:
		*		"$git/data/original/ipeds/ipeds-2012.csv"
		
		*	Then do similarly as in $do/02B-create-key-aamc-cms-names.do:
		*		g chiro_school = regexm(institutionname, "chiro")
		
		* 	And same for osteo, optom, and podia.
		
		* 	Define medic_school as the residual (not belonging to any of the four specializations). 
		
		g 		tuition = .
		replace tuition = chiro_tuition if chiro_school == 1
		replace tuition = osteo_tuition if osteo_school == 1
		replace tuition = optom_tuition if optom_school == 1
		replace tuition = podia_tuition if podia_school == 1
		replace tuition = medic_tuition if medic_school == 1
		
		drop *_tuition
		
		drop if tuition == .
		
		save "$temp/ipeds-tuition-`j'", replace
		
	}
	
}

clear
forvalues j = 2000/2023 {
	
	if !inlist(`j', 2009, 2010, 2011) { // think about the revised years
	
		append using "$temp/ipeds-tuition-`j'"
		
	}

}

save "$temp/pre-ipeds-tuition", replace


*** COMBINED AAMC/IPEDS PANEL ***

use          "$temp/pre-aamc-tuition", clear
append using "$temp/pre-ipeds-tuition"

label var aca_year "Academic year (e.g. academic year 2000-2001 -> aca_year = 2000)"

replace tuition = tuition / 1000

* Copy of nominal tuition:
g nominal_tuition = tuition

* Inflation adjustment for tuition:
inflationAdjust tuition aca_year

* Check so the data is unique in (school, year):
bys med_school aca_year : assert _N == 1

order med_school aca_year

* Drop if we only have one observation (cannot calculate increase then):
bys med_school (aca_year) : g drop = _N == 1

drop if drop == 1
drop    drop

* Drop if tuition is constantly 0:
bys med_school (tuition) : g drop = tuition[1] == 0 & tuition[1] == tuition[_N]

drop if drop == 1
drop    drop

assert tuition != .

* Mark where chronological order is respected:
bys med_school (aca_year) : g med_school_chrono = aca_year[_n] == aca_year[_n - 1] + 1

* Delta tuition:
foreach var in nominal_tuition tuition {
	
	bys med_school (aca_year) : g delta_`var' = /// dollar amount
		`var'[_n] - `var'[_n - 1] if ///
			med_school_chrono == 1 & /// chronological order is respected
			`var'[_n - 1]   != 0    // the increase is not from zero	
			
	* Total tuition during four years:
	bys med_school (aca_year) : g `var'_bill = ///
		`var'[_n - 3] + ///
		`var'[_n - 2] + ///
		`var'[_n - 1] + ///
		`var'[_n - 0] if ///
			med_school_chrono[_n - 2] == 1 & ///
			med_school_chrono[_n - 1] == 1 & ///
			med_school_chrono[_n - 0] == 1
	
}

* Defining tuition quantile:
egen Tuition_quantile = xtile(tuition), n(4) by(aca_year) // ssc install egenmore

* Label variables:
label var tuition_bill "Tuition bill (USD 1,000)"
label var PublicSchool "Public school (Dummy)"

save "$temp/aamc-tuition", replace




