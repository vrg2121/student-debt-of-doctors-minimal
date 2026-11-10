
*********************************************
*** FIX NAME ISSUES IN AAMC TUITION FILES ***
*********************************************

* 	This file helps preparing to fix some name issues in the AAMC tuition files
*
*	The same school sometimes has two different names, for example:
*		"george washington university school of medicine & health sciences"
*		"george washington university school of medicine and health sciences"
*
*	This needs to be adjusted to a single common name (to be implemented, see below)

*********************************************
*********************************************
*********************************************



*** AAMC ***


* The AAMC Excel we import below is obtained by:

* 	Downloading data from:
*	https://www.aamc.org/data-reports/reporting-tools/report/tuition-and-student-fees-reports

* 	These downloads are in:
*	$git/data/data/original/aamc/excels/original

* 	We then manually get rid of some extra rows etc to create the files with the same names in:
*	$git/data/original/aamc/excels/modified

* 	From those Excels, we put all of their sheets together in one file: the file we read below


* Finding all sheets in the Excel and looping over them (unnecessarily complicated):
import excel using "$raw_data/aamc/excels/modified/data/aamc-tuition-1995-2024", describe
return list
local n_sheets `r(N_worksheet)'

local sheets
forvalues j = 1 / `n_sheets' {
	
    local sheet `r(worksheet_`j')'
	local sheets `sheets' `sheet'
	
	import excel ///
		"$raw_data/aamc/excels/modified/data/aamc-tuition-1995-2024", ///
		clear firstrow sheet("`sheet'")
	
	g aca_year = substr("`sheet'", 1, 4) // if academic year is 2000-2001, we choose 2000 here
	
	assert "`: type aca_year'" == "str4"
	
	* Make aca_year integer:
// 	destring aca_year, replace // loop breaks down with this, why?
		
	save "$working_data/temp/aamc-tuition-`sheet'", replace
		
}

clear
foreach sheet of local sheets {
	
	append using "$working_data/temp/aamc-tuition-`sheet'"

}

rename MedicalSchoolName med_school

do "$do/clean-aamc-medschool-names.do"

sort med_school aca_year

save "$working_data/temp/full-aamc-tuition", replace

keep med_school

duplicates drop

sort med_school
drop if med_school == ""

export excel "$working_data/temp/full-aamc-schools.xlsx", replace firstrow(var)
save "$working_data/temp/full_aamc_schools", replace
