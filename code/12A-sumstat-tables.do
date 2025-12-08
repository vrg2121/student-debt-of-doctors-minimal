/* 

PREAMBLE

Non-Regression Tables 
   
Victoria Garcia 
December, 2025
*/

clear all

*** DIRECTORIES ***

global proj_dropbox "C:/dropbox/Phil Research Dropbox/Victoria Garcia/Student Debt of Doctors"

global v_data "$proj_dropbox/Tuition Data/victoria-temp/data"
	
global code_repo "$proj_dropbox/Tuition Data/victoria-temp/code/do_files"

global table_repo "$proj_dropbox/Tuition Data/victoria-temp/tables"
	
cd "$code_repo"

*** LOAD IDENTIFIED DATA ***

use "$v_data/cms_aamc_merge_identifier.dta", clear

egen school_id = group(med_school) // this has been added to 01_cms_aamc_merge for future data 12.1.2025
label variable school_id "med school id by med_school"