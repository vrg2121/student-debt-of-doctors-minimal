/* 

PREAMBLE

This file merges cms data (doctor characteristics) onto aamc data (school characteristics).
Prepares data for cohort-dummies on Revamp of Empirical Strategy.
   
Victoria Garcia 
10.17.2025
*/


*** DIRECTORIES ***

global proj_dropbox "C:\dropbox\Phil Research Dropbox\Victoria Garcia\Student Debt of Doctors"

global working_data "$proj_dropbox\Tuition Data\simon\student-debt-of-doctors\data\working\temp\old-2025-10-20"

global v_data "$proj_dropbox\Tuition Data\victoria-temp\data"
	
global code_repo "$proj_dropbox\Tuition Data\victoria-temp\code\do_files"
	
cd "$code_repo"

*** LOAD WORKING DATA ***

use "$v_data/aamc_large_identifier", clear

g grad_year = aca_year + 1							 
// Adjusting for grad_year; e.g. 2001 if graduating in academic year 2000-2001

*** Merge school and doctor data ***
merge 1:m med_school grad_year using "$working_data/cms-panel"

by med_school grad_year, sort: gen nschool_yr = _n == 1
count if nschool_yr == 1
// count unique school and year combo = 5,266

by npi grad_year, sort: gen ndoc_yr = _n == 1
count if ndoc_yr == 1
// count unique doctor and year combo = 313,484


/* Merge Reference: 

	Not matched from school data = 1,223
		
	Not matched from doctor data = 575,989
		
	Matched = 1,605,518
		> med school names matched
		> med school data is available for that year
		
	To Check:
		> med schools are not missing exact name matches even though data is available for that year
		
	Notes:
		After cursory exploration, there does not seem to be mismatches in the data, but we can 
		identify additional data to collect using doc_data_missing_school.csv.
*/

*** Explore what parts of the merge are missing ***
* Which schools are not matched?
preserve

keep if _merge==1
count if nschool_yr == 1							  // 1,223 unique school + year dropped
// approx. 24% of school + year data dropped

keep med_school PublicSchool source grad_year
export delimited "$v_data/merge_unmatched/unmatched_schools_year.csv", replace // to check discrepencies in school name + year
by med_school, sort: gen nvals = _n == 1
count if nvals 										  // 152 schools not matched
keep if nvals == 1
export delimited "$v_data/merge_unmatched/unmatched_schools.csv", replace	  // to check discrepencies in school name

restore

* Which doctors are not matched?
preserve

keep if _merge==2
count if ndoc_yr == 1								  // 75,178 unique doc + year dropped
// approx. 24% of doc + year data dropped

keep if ndoc_yr == 1
keep grad_year npi med_school our_med_school
export delimited "$v_data/merge_unmatched/unmatched_doctors.csv", replace

* Which schools do we have doctor data for but no matched school data?
by grad_year med_school, sort: gen ndoc_school_yr = _n == 1
count if ndoc_school_yr == 1 						  // 1,048 school-year data points have doctor data but no school data
keep if ndoc_school_yr == 1
drop ndoc_school_yr
export delimited "$v_data/doc_data_missing_school.csv", replace

restore

keep if _merge==3
save "$v_data/cms_aamc_merge_identifier.dta", replace


