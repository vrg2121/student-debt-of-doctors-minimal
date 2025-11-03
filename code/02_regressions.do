/* 

PREAMBLE

This file runs the initial regressions as specified in the Revamp of Empirical Strategy.
   
Victoria Garcia 
10.17.2025
*/

clear all

*** DIRECTORIES ***

global proj_dropbox "C:\dropbox\Phil Research Dropbox\Victoria Garcia\Student Debt of Doctors"

global v_data "$proj_dropbox\Tuition Data\victoria-temp\data"
	
global code_repo "$proj_dropbox\Tuition Data\victoria-temp\code\do_files"
	
cd "$code_repo"


*** LOAD IDENTIFIED DATA ***

use "$v_data/cms_aamc_merge_identifier.dta", clear


*** INITIAL REGRESSIONS ***

// regress doctor-year level regression with all_total_payments
reg all_total_payments tuition_bill

// Create the initial list of all possible dummy variables
local dummies ""
foreach letter in a b c d e f g h {
    forvalues i = 1/179 {
        local dummies "`dummies' dum_`i'`letter'"
    }
}

// Check for existence and keep only existing variables
local existing_dummies ""
foreach var of local dummies {
    capture confirm variable `var'
    if !_rc {
        local existing_dummies "`existing_dummies' `var'"
    }
}

local existing_dummies : list clean existing_dummies
global cohort_dummies "`existing_dummies'"

egen school_id = group(med_school)

reghdfe all_total_payments tuition_bill $cohort_dummies, a(i.school_id#i.year)
reghdfe all_total_payments tuition_bill $cohort_dummies, a(i.school_id#i.year groupPAC#year)
reghdfe all_total_payments tuition_bill $cohort_dummies, a(i.school_id#i.year hrr) // what does HRR stand for??

reghdfe all_total_payments tuition_bill $cohort_dummies, a(i.school_id#i.year hcpcs)



// tuition_bill omitted due to collinearity with npi 

