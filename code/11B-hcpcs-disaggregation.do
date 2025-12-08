/* 

PREAMBLE

This file disaggregates the identified data by hcpcs.

Run as a batch job on a computer with at least 16 CPUs and 60 GB of RAM.

Estimated walltime: 6 hours
   
Victoria Garcia 
December 2025
*/

*** SET DATA LOCATION ***

* dropbox *
/*
global proj_dropbox "C:/dropbox/Phil Research Dropbox/Victoria Garcia/Student Debt of Doctors"

global v_data "$proj_dropbox/Tuition Data/victoria-temp/data"
*/

* cluster *
v_data "/home/victoria.garcia/Batch/data"

*** DISAGGREGATE IDENTIFIED DATA BY HCPCS ***

set processors 7

parallel initialize 14

* find years *
use year using "$v_data/cms_aamc_merge_indentifier", clear

sum year
global min = r(min)
global max = r(max)

clear

forvalues year = $min / $max {
	
	tempfile hcpcs_`year'
	save `hcpcs_`year'', emptyok replace

	forvalues i = 0 / 19 {
		display "Reshaping year `year', section `i'"
		import delimited "$v_data/`year'/cms_aamc_id_`year'_`i'.csv", clear
		
		capture: confirm str variable grouppac
		
		if _rc {
			tostring grouppac, replace
		}
		
		sort npi
		
		parallel, by(npi): reshape long avg_mdcr_pymt_amt, i(npi) j(hcpcs) string
		
		append using `hcpcs_`year''
		save `hcpcs_`year'', replace
		
		display "`year' reshape complete"
		
	}
	save "$v_data/hcpcs/cms_aamc_id_hcpcs_`year'", replace
	
	clear
}

*** APPEND ALL HCPCS DATA ***
clear

tempfile hcpcs_id
save `hcpcs_id', emptyok replace

forvalues i = $min / $max {
	use "$v_data/hcpcs/cms_aamc_id_hcpcs_`i'", clear
	
	append using `hcpcs_id'
	save `hcpcs_id', replace
	
	display "`i' has been appended"
}

save "$v_data/hcpcs/cms_aamc_id_hcpcs", replace