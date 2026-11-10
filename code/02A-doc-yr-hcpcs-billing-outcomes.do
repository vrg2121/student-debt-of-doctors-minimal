*****************************************************
*** CREATE DOCTOR-YEAR-HCPCS BILLING CMS OUTCOMES ***
*****************************************************

*****************************************************
* INPUTS: raw CMS Billing Data, Provider Services
	* File Path: "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D`n'_Prov_Svc.csv"
	
* OUTPUTS: doctor-year-hcpcs-place of service level data 
	* Identified HCPCS: betos, fang and gong e&m payments
	* Place of Service: Outpatient (O) and Facility (F)
	* "$working_data/temp/doc_yr_hcpcs_betos_fg_`n'_`x'"
******************************************************


**# Clean and Standardize Raw Data

clear
forvalues n=12/19 {
		
	display "Cleaning Doctor-Year-HCPCS data for 20`n'"
		
	import delimited "$dropbox/FullData/RawData/MUP_PHY_R19_P04_V10_D`n'_Prov_Svc.csv", /*rowrange(3:1001)*/ clear

	rename rndrng_npi npi
	rename tot_srvcs nServ
	cap rename avg_mdcr_pymt_amt avg_pymt
	
	
	gen zipcode_nppes = ""
	gen zipcode_rndrng = ""
	gen zip5 = ""
	gen avg_stdzd_pymt = .
	gen nCode = nServ > 0
	
	cap confirm variable avg_mdcr_stdzd_amt
	if _rc == 0 {
		replace avg_stdzd_pymt = avg_mdcr_stdzd_amt
	}
	
	cap confirm variable nppes_provider_zip
	if _rc == 0 {
		tostring nppes_provider_zip, replace
		replace zipcode_nppes = nppes_provider_zip
		replace zip5 = substr(zipcode_nppes, 1, 5)
	}

	cap confirm variable rndrng_prvdr_zip5
	if _rc == 0 {
		tostring rndrng_prvdr_zip5, replace
		replace zipcode_rndrng = rndrng_prvdr_zip5
		replace zip5 = substr(zipcode_rndrng, 1, 5)
	}

	cap rename nppes_entity_code   ent_cd
	cap rename rndrng_prvdr_ent_cd ent_cd
	cap rename medicare_participation_indicator mdcr_participant
	cap rename rndrng_prvdr_mdcr_prtcptg_ind mdcr_participant
	cap rename nppes_provider_country country
	cap rename rndrng_prvdr_cntry country
	cap rename rndrng_prvdr_type phySpec
	cap rename provider_type phySpec
	
	replace phySpec = strlower(phySpec)
	replace phySpec = subinstr(phySpec, "/ ", "/", .)
	replace phySpec = "family practice" if phySpec == "family medicine"

	confirm var ent_cd

	bys npi (ent_cd) : assert ent_cd[1] == ent_cd[_N] // confirm no duplicates

	* Drug indicator:
	g isDrug = hcpcs_drug_ind == "Y"

	* Compute total amount paid per row and adjust scale:
	gen hcpcs_tot_pymt = nServ * avg_pymt / 1000
	gen hcpcs_tot_stdzd_pymt = nServ * avg_stdzd_pymt / 1000
	
	g year = 2000 + `n'
	
	* Adjust for inflation based on year
	inflationAdjust hcpcs_tot_pymt year
	label variable hcpcs_tot_pymt "HCPCS Total Payment, Inflation Adjusted"
	
	inflationAdjust hcpcs_tot_stdzd_pymt year
	label variable hcpcs_tot_stdzd_pymt "HCPCS Total Payment, Geographically Standardized, Inflation Adjusted"

	
	* Narrow down the sample to relevant doc-year-hcpcs data
	
	keep if ent_cd == "I" // keep only individual doctors
		
	drop if place_of_srvc == ""
	
	* Identify HPPCS Level I (procedures, aka CPT) and Level II (products) codes
	destring hcpcs_cd, generate(hcpcsGroup) force
	rename hcpcs_cd   hcpcs
	
	replace hcpcsGroup = 1 if hcpcsGroup != .
	replace hcpcsGroup = 2 if strpos(hcpcs, "F") == 5
	replace hcpcsGroup = 3 if strpos(hcpcs, "T") == 5
	replace hcpcsGroup = 0 if hcpcsGroup == .
	
	g fg_sel1 = hcpcsGroup == 1
	label variable fg_sel1 "CMS Level 1 Payment or Drug"
	g fg_sel2 = isDrug == 0
	label variable fg_sel2 "CMS Payment any Level not Drug"
	g fg_sel3 = hcpcsGroup == 1 & isDrug == 0
	label variable fg_sel3 "CMS Level 1 Payment and not Drug"
	
	keep npi year hcpcs nServ hcpcs_tot_pymt hcpcs_tot_stdzd_pymt zipcode* zip5 isDrug mdcr_participant hcpcsGroup fg_sel* place_of_srvc country avg_pymt phySpec
	
	foreach x in F O{
		preserve
		
		keep if place_of_srvc == "`x'"
		
		isid npi hcpcs
		
		* merge on subcategories from BETOS, identified by Emiel

		merge m:1 hcpcs using "$dropbox/FullData/RawData/BETOS2", keepusing(rbcs_cat_subcat rbcs_cat_desc rbcs_subcat_desc)
		drop if _merge == 2
		drop    _merge 
		
		g betos_hcpcs_pymt = .
		foreach betos of global emiel_betos {
			replace betos_hcpcs_pymt = hcpcs_tot_pymt if rbcs_cat_subcat == "`betos'"
		} 
		
		* merge on hcpcs codes and groups from Fang & Gong
		merge m:1 hcpcs using "$working_data/temp/fg_selection_appended_hcpcs_code", keepusing(hcpcs)
	
		g fg_sel4 = (_merge == 3) // hcpcs code found in both cms billing and fang and gong selection
		
		drop _merge
		
		* merge on isEM
		merge m:1 hcpcs using "$working_data/temp/hcpcs-isEM"
		drop if _merge == 2
		drop    _merge
		g fg_sel5 = (isEM == "1") // hcpcs code identified as e/m code by fang and gong
		
		drop if npi == .
		
		save "$working_data/temp/doc_yr_hcpcs_betos_fg_`n'_`x'", replace

			
		restore
	}

	
}



**# APPENDIX
/*
**# Check for Uniqueness in Clean CMS Outcomes Data

clear
forvalues n = 12/19 {
	
	use "$working_data/temp/doc_yr_hcpcs_betos_fg_`n'_O", clear
	
	isid npi hcpcs
	
	display "NPI and HCPCS uniquely identify rows for 20`n', O"
	
	use "$working_data/temp/doc_yr_hcpcs_betos_fg_`n'_F", clear
	
	isid npi hcpcs
	
	display "NPI and HCPCS uniquely identify rows for 20`n', F"
	
}

**# How many zipcodes does each doctor have in our billing data? ONLY 1 (interestingly enough...)

clear
forvalues n = 12/19 {
	
	use "$working_data/temp/doc_yr_hcpcs_betos_fg_`n'_O", clear
	
	bys npi zip5: g temp = _n == 1
	bys npi: egen zip5_count = sum(temp)
	drop temp
	
	quietly sum zip5_count
	
	display "The average number of zipcodes per npi for 20`n', O is `r(mean)' "
	
	
	use "$working_data/temp/doc_yr_hcpcs_betos_fg_`n'_F", clear
	
	bys npi zip5: g temp = _n == 1
	bys npi: egen zip5_count = sum(temp)
	drop temp
	
	quietly sum zip5_count
	
	display "The average number of zipcodes per npi for 20`n', F is `r(mean)' "
}

**# NPI-Zipcode-Year Level Data For Testing Merges
clear
tempfile npizip
save `npizip', emptyok
forvalues n = 12/19 {
	
	use "$working_data/temp/doc_yr_hcpcs_betos_fg_`n'_O", clear
	
	keep npi year zip5 place_of_srvc
	
	append using `npizip'
	save `npizip', replace
	
	
	use "$working_data/temp/doc_yr_hcpcs_betos_fg_`n'_F", clear
	
	keep npi year zip5 place_of_srvc
	
	append using `npizip'
	save `npizip', replace
}

use `npizip', clear

duplicates drop npi zip5 place_of_srvc year, force

save "$working_data/temp/unique_doc_zip_location_year", replace

duplicates drop npi zip5 place_of_srvc, force

save "$working_data/temp/unique_doc_zip_location", replace

use "$working_data/temp/unique_doc_zip_location_year", clear

duplicates drop npi zip5 year, force

drop place_of_srvc
g doc_zip_year_inbilling = 1

save "$working_data/temp/unique_doc_zip_year", replace






