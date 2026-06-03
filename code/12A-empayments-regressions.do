*******************************************************************
*** CREATE YEARLY DOCTOR CMS OUTCOMES FOR E/M AND NON-E/M CODES ***
*******************************************************************

* Description of this do-file:

* 	Calculates total payments for EM codes an non-EM codes
*	Creates doctor-year-isEM level data
* 	Merges on doctor characteristics, school data

*****************************************
*****************************************
*****************************************



*****************************
*** YEARLY TOTAL PAYMENTS ***
*****************************
forvalues n = 12/19 {
	
	import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D`n'_Prov_Svc.csv", clear

	rename rndrng_npi npi
	rename hcpcs_cd   hcpcs
	rename tot_srvcs  amount_services

	cap rename nppes_entity_code   ent_cd
	cap rename rndrng_prvdr_ent_cd ent_cd
	
	confirm var ent_cd
	
	drop if npi == 1
	
	bys npi (ent_cd) : assert ent_cd[1] == ent_cd[_N]
	
	* Drug indicator:
	g isDrug = hcpcs_drug_ind == "Y"
	
	* EM indicator:
	merge m:1 hcpcs using "$working_data/temp/hcpcs-isEM"
	drop if _merge == 2
	drop _merge
	replace isEM = "." if isEM == ""
	destring isEM, replace
	
	* Compute total amount paid per row and adjust scale:
	replace avg_mdcr_pymt_amt = avg_mdcr_pymt_amt / 1000
	
	gen all_total_payments = amount_services * avg_mdcr_pymt_amt

	* Compute total amount paid per HCPCS code and doctor:
	collapse (sum) all_total_payments amount_services (max) isDrug, by(npi isEM)
	
	g year = 2000 + `n'

	
	save "$working_data/temp/all_total_payments-em-grps-20`n'", replace
	
}

* Put files together:
clear
forvalues n = 12/19 {
	
	append using "$working_data/temp/all_total_payments-em-grps-20`n'"
	
}

	
* Inflation adjustment:
inflationAdjust all_total_payments year

* Check if doctor-year has both EM and non-EM payments
replace isEM = 0 if isEM == .
bys npi year: egen minEM = min(isEM)
bys npi year: egen maxEM = max(isEM)
g both = (minEM == 0 & maxEM == 1)

tab both

label variable both "npi-year contains both EM and non-EM payments"

drop minEM maxEM

save "$working_data/temp/all_total_payments-em-grps", replace


***************************************
*** MERGE ON DOCTOR CHARACTERISTICS ***
***************************************

merge m:1 npi year using "$working_data/temp/cms-panel-clean-name"

keep if _merge == 3
drop _merge
// 2,512,900 / 16,629,533 = keep 15% of isEM data

save "$working_data/panels/cms-isEM-panel", replace

**********************************
*** MERGE ON COHORT IDENTIFIER ***
**********************************

use "$working_data/aamc_large_identifier", clear

merge 1:m med_school grad_year using "$working_data/panels/cms-isEM-panel"

keep if _merge == 3
drop _merge

egen id = group(year npi isEM)
label variable id "doctor-year-isEM identifier"

encode groupPAC, gen(ngroupPAC)

g cohort = ""
label variable cohort "Cohort ID"

foreach dum of varlist dum_* {
	replace cohort = "`dum'" if cohort == "" & `dum' == 1
}

encode cohort, g(cohort_id)
label variable cohort_id "Categorical Cohort ID"

drop dum_*

g time_since_grad = year - grad_year

tostring time_since_grad, replace

encode time_since_grad, g(time_since_grad_id)
encode phySpec, g(phySpec_id)

drop cred

assert substr("`: type zip'", 1, 3) == "str"
assert inlist(length(zip), 5, 9)

* Creating zip5:
g str5 zip5 = substr(zip, 1, 5)

* Merge in hrr:
merge m:1 zip5 using "$dropbox/FullData/zip_hrr"
drop if _merge == 2
drop    _merge

* Label variables *
label variable all_total_payments "Total CMS Payments"
label variable amount_services "Number of Services"


save "$working_data/cms_aamc_isEM_id", replace