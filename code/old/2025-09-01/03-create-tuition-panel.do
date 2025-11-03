
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

replace tuition = tuition / 1000

* Inflation adjustment for tuition:

drop if !inrange(grd_yr, 1992, 2019)

* CPI: (source https://www.bls.gov/cpi/tables/supplemental-files/historical-cpi-u-201811.pdf)
g       cpi = .
replace cpi = 138.1   if grd_yr == 1992
replace cpi = 142.6   if grd_yr == 1993
replace cpi = 146.2   if grd_yr == 1994
replace cpi = 150.3   if grd_yr == 1995
replace cpi = 154.4   if grd_yr == 1996
replace cpi = 159.1   if grd_yr == 1997
replace cpi = 161.6   if grd_yr == 1998
replace cpi = 164.3   if grd_yr == 1999
replace cpi = 168.8   if grd_yr == 2000
replace cpi = 175.1   if grd_yr == 2001
replace cpi = 177.1   if grd_yr == 2002
replace cpi = 181.7   if grd_yr == 2003
replace cpi = 185.2   if grd_yr == 2004
replace cpi = 190.7   if grd_yr == 2005
replace cpi = 198.3   if grd_yr == 2006
replace cpi = 202.4   if grd_yr == 2007
replace cpi = 211.1   if grd_yr == 2008
replace cpi = 211.143 if grd_yr == 2009
replace cpi = 216.687 if grd_yr == 2010
replace cpi = 220.223 if grd_yr == 2011
replace cpi = 226.655 if grd_yr == 2012
replace cpi = 230.280 if grd_yr == 2013
replace cpi = 233.916 if grd_yr == 2014 // everything as of 2014 dollars
replace cpi = 233.707 if grd_yr == 2015
replace cpi = 233.916 if grd_yr == 2016
replace cpi = 242.839 if grd_yr == 2017
replace cpi = 250.089 if grd_yr == 2018 // approximate, fix this!
replace cpi = 254.412 if grd_yr == 2019 // approximate, fix this!

g cpi_index = cpi / 233.916

replace tuition = tuition / cpi_index

drop cpi cpi_index

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

* Total tuition during four years:
bys med_school (grd_yr) : g tuition_bill = ///
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




