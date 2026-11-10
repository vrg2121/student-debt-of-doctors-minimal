******************************************************
*** CLEAN/MEARGE AAMC DATA ON APPS, MATS AND GRADS ***
******************************************************

**# Applicants Data
tempfile applicants

import excel "$dropbox/AAMC Application Graduates/aamc_grad_apps_mats.xlsx", sheet("Applicants") first clear

rename USMDGrantingMedicalSchool med_school

do "$do/clean-aamc-medschool-names"

//assert isid med_school // stops the program if there are duplicate med_school names

reshape long Y, i(med_school) j(year) string
rename Y applicants

split year, parse("_") destring
rename year1 start_aca_year
rename year2 start_grad_year

g grad_year = start_aca_year + 4

drop year

replace applicants = "" if applicants == "-"

save `applicants'

**# Matriculants
import excel "$dropbox/AAMC Application Graduates/aamc_grad_apps_mats.xlsx", sheet("Matriculants") first clear

rename USMDGrantingMedicalSchool med_school

do "$do/clean-aamc-medschool-names"

//assert isid med_school // stops the program if there are duplicate med_school names

reshape long Y, i(med_school) j(year) string
rename Y matriculants

split year, parse("_") destring
rename year1 start_aca_year
rename year2 start_grad_year

g grad_year = start_aca_year + 4

drop year

replace matriculants = "" if matriculants == "-"

merge 1:1 med_school start_aca_year using `applicants' 
drop _merge // keep all data
// "louisiana state university new orleans 3 year accelerated primary care program" and "oral roberts university school of medicine" are only found in applicants data

tempfile app_mat
save `app_mat'

**# Graduates/aamc_grad_apps_mats
import excel "$dropbox/AAMC Application Graduates/aamc_grad_apps_mats.xlsx", sheet("Graduates") first clear

rename MedicalSchool med_school

do "$do/clean-aamc-medschool-names"

tostring AcademicYear, replace
split AcademicYear, parse("-") destring
rename AcademicYear1 aca_year
rename AcademicYear2 grad_year
drop AcademicYear

//assert isid med_school grad_year // stops the program if med_school+grad_year is not a unique id

rename TotalGraduates graduates

merge 1:1 med_school grad_year using `app_mat'
drop _merge

bys med_school : egen missing_grad = min(graduates == .) // never reports graduates data
bys med_school : egen missing_mats = min(matriculants == "") // never reports matriculants data
bys med_school : egen missing_apps = min(applicants == "") // never reports applicants data

destring matriculants, replace
destring applicants, replace

sort med_school grad_year

bys med_school : g grad_minus_mat_4yr = (graduates - matriculants)

label variable grad_minus_mat_4yr "grads - matriculants; (+) implies excess grads, assuming 4 years to graduation"

// bys med_school : g grad_minus_mat_5yr = (graduates[_n-1] - matriculants)
// label variable grad_minus_mat_5yr "grads - matriculants; (+) implies excess grads, assuming 5 years to graduation"


save "$working_data/panels/aamc_grad_apps_mats", replace


**# APPENDIX

** Why inconsistent graduates and matriculants?
/*
use "$working_data/panels/aamc_grad_apps_mats", clear

// graduates align with matriculants for 4 or 5 years earlier

bys med_school : g grad_mat_4 = matriculants
bys med_school : g grad_mat_5 = matriculants[_n + 1]
g more_grad_than_mat_4yr = (graduates > grad_mat_4)
g more_grad_than_mat_5yr = (graduates > grad_mat_5)

bys med_school : g grad_minus_mat_5yr = (graduates[_n-1] - matriculants)

replace more_grad_than_mat_4yr = . if missing_grad == 1
replace more_grad_than_mat_5yr = . if missing_grad == 1
replace more_grad_than_mat_4yr = . if missing_mats == 1
replace more_grad_than_mat_5yr = . if missing_mats == 1


graph bar (sum) more_grad_than_mat_4yr, over(grad_year, label(angle(45))) title("Schools With More Graduates than Matriculants, 4 Year Grad") ytitle("Number of Schools")

graph bar (sum) more_grad_than_mat_5yr, over(grad_year, label(angle(45))) title("Schools With More Graduates than Matriculants, 5 Year Grad") ytitle("Number of Schools")

preserve

keep if more_grad_than_mat_4yr == 1

graph bar (sum) grad_minus_mat_4yr, over(grad_year, label(angle(45))) title("Number of Excess Graduates, 4 Year Grad") ytitle("Number of Graduates")

restore

preserve

keep if more_grad_than_mat_5yr == 1

graph bar (sum) grad_minus_mat_5yr, over(grad_year, label(angle(45))) title("Number of Excess Graduates, 5 Year Grad") ytitle("Number of Graduates")

restore

// it's likely we're seeing graduates of other programs (https://www.aamc.org/media/48526/download?attachment)

*/

