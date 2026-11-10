************************************************
*** MERGE DOCTOR BILLING AND CHARACTERISTICS ***
************************************************

**# Merge Characteristics and Billing By Year
clear
forvalues n = 13/19 {
			
	use "$working_data/temp/doc_yr_hcpcs_betos_fg_`n'_O", clear
	
	merge m:1 npi year using "$working_data/temp/doc_characteristics_clean_balanced"
	keep if _merge == 3
	drop _merge
	
	save "$working_data/panels/doc_20`n'_characteristics_billing_O", replace
		
	use "$working_data/temp/doc_yr_hcpcs_betos_fg_`n'_F", clear
	
	merge m:1 npi year using "$working_data/temp/doc_characteristics_clean_balanced"
	keep if _merge == 3
	drop _merge
	
	save "$working_data/panels/doc_20`n'_characteristics_billing_F", replace
	
	
}

**# Append Billing-Characteristics Data O and F Data By Year

** Append 2012
use "$working_data/temp/doc_yr_hcpcs_betos_fg_12_O", clear
append using "$working_data/temp/doc_yr_hcpcs_betos_fg_12_F"

save "$working_data/temp/doc_yr_hcpcs_betos_fg_12", replace

** Append 2013-2019 with characteristics
clear

forvalues n = 13/19 {
	use "$working_data/panels/doc_20`n'_characteristics_billing_O", clear
	append using "$working_data/panels/doc_20`n'_characteristics_billing_F"
	
	save "$working_data/panels/doc_20`n'_characteristics_billing", replace
}


** Update 2012 with Time Invariant Characteristics
use "$working_data/temp/doc_yr_hcpcs_betos_fg_12", clear

merge m:1 npi year using "$working_data/temp/doc_characteristics_clean_balanced"
keep if _merge == 3
drop _merge

save "$working_data/panels/doc_2012_characteristics_billing", replace

**# Merge Tuition Data by Year + Med School, HRR by zipcode & Label Variables

clear
forvalues n = 12/19 {
	use "$working_data/panels/doc_20`n'_characteristics_billing", clear
	
	merge m:1 zip5 using "$dropbox/FullData/zip_hrr"
	drop if _merge == 2
	drop    _merge
	
	merge m:1 med_school grad_year using "$working_data/panels/aamc-tuition"    // See 05A for the tuition data
	drop if _merge == 2 // drop additonal tuition data
	drop _merge
	
	save "$working_data/panels/aamc_cms_20`n'", replace
}


**# APPENDIX
/*
**# Check that the missing npi are present since updating
forvalues n = 12/19 {
	use "$working_data/panels/aamc_cms_20`n'", clear
	duplicates drop npi, force
	merge 1:1 npi using "$working_data/temp/2012-npi-missing"
	g tag = (_merge == 3)
	drop if _merge == 2
	drop _merge
	
	quietly sum tag
	local pct = 100*(r(sum) / 5158)
	display "Year 20`n' has `pct'% of Missing NPI"
	
}


**# Pull out the Med School Names
clear
save "$working_data/temp/doc_med_school", replace emptyok

clear
forvalues n = 12/19 {
	use "$working_data/panels/doc_20`n'_characteristics_billing", clear
	duplicates drop npi, force
	keep npi med_school year
	drop if med_school == ""
	rename med_school doc_med_school
	
	tempfile tfile
	save `tfile'
	
	use "$working_data/temp/doc_med_school", clear
	append using `tfile', force
	save "$working_data/temp/doc_med_school", replace
	
}

use "$working_data/temp/doc_med_school", clear
sort npi year
duplicates drop npi, force
drop year
collapse (count) npi, by(doc_med_school)
rename npi npi_count
save "$working_data/temp/doc_med_school", replace
export delimited "$working_data/temp/doc_med_school.csv", replace

**# Check the "Medical College of Ohio"
preserve
keep if inlist(med_school, "medical college of ohio", "university of cincinnati college of medicine", "the university of toledo college of medicine & life sciences")

tab grad_year if strpos(med_school, "toledo")
tab grad_year if strpos(med_school, "ohio")
tab grad_year if strpos(med_school, "cincinnati")

restore

