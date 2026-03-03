*******************************************
*** CREATE DOCTOR-YEAR-HCPCS GROUP DATA ***
*******************************************

* Description of this do-file:

* 	Creates HCPCS Group Level Data
		** HCPCS_Group Outcome variables (total em payments, avg mdcr payment amts, number of services)
* 	Merges on Doctor characteristics
* 	Merges on Cohort identifier

*****************************************
*****************************************
*****************************************


********************************************************************
*** YEARLY AVERAGE PAYMENTS PER HCPCS GROUP – ONLY FOR E/M CODES ***
********************************************************************

* Only for E/M codes currently 
forvalues n = 12/19 {
	
	import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D`n'_Prov_Svc.csv", ///
		clear

	rename rndrng_npi npi
	rename hcpcs_cd   hcpcs
	rename tot_srvcs  nsrvcs

	* Merging on isEM:
	merge m:1 hcpcs using "$working_data/temp/hcpcs-isEM"
	drop if _merge == 2
	drop    _merge

	keep if isEM == 1
	
	assert hcpcs != ""
	
	replace avg_mdcr_pymt_amt = avg_mdcr_pymt_amt / 1000
	
	g tot_em_pymt = avg_mdcr_pymt_amt * nsrvcs
	
	collapse (sum) tot_em_pymt nsrvcs, by(npi hcpcsgroup)
	
	g avg_mdcr_pymt_amt = tot_em_pymt / nsrvcs
	
	g year = 2000 + `n'
		
	
	save "$working_data/temp/em-hcpcsgrp-payments-`n'", replace
	
}

* Put files together:
clear
forvalues n = 12/19 {
	
	append using "$working_data/temp/em-hcpcsgrp-payments-`n'"
	
}

ds avg_mdcr_pymt_amt tot_em_pymt
foreach var in `r(varlist)' {
	
	* Inflation adjustment:
	inflationAdjust `var' year
	
}

save "$working_data/temp/em-hcpcsgrp-payments", replace


***************************************
*** MERGE ON DOCTOR CHARACTERISTICS ***
***************************************

merge m:1 npi year using "$working_data/temp/cms-panel-clean-name"

keep if _merge == 3
drop _merge
// 3,392,397 / 13,049,142 = keep 26% of em-hcpcsgrp data

save "$working_data/panels/cms-hcpcsgrp-panel", replace

**********************************
*** MERGE ON COHORT IDENTIFIER ***
**********************************

use "$working_data/aamc_large_identifier", clear

merge 1:m med_school grad_year using "$working_data/panels/cms-hcpcsgrp-panel"

keep if _merge == 3
drop _merge

egen id = group(year npi hcpcsgroup)
label variable id "doctor-year-hcpcsgrp identifier"

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
label variable tot_em_pymt "Total E/M Payments"
label variable avg_mdcr_pymt_amt "Average E/M Payment"
label variable nsrvcs "Number of E/M Services"


save "$working_data/cms_aamc_hcpcsgrp_id", replace
