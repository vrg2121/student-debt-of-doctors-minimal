*******************************************************
*** EXPLORE RAW PSPS DATA FOR HCPCS-BETOS CROSSWALK ***
*******************************************************

** Round 12

global raw "$dropbox/FullData/RawData"

global npi_invariant ///
		year phySpec* cred isMD  ///
		gy_cnt ms_cnt mult_grad_year mult_med_school grad_year med_school ///
		mdcr_participant zip5 groupPAC event_time hrr ///
		aca_year tuition PublicSchool source nominal_tuition med_school_chrono ///
		delta_nominal_tuition nominal_tuition_bill delta_tuition tuition_bill Tuition_quantile

// clemens & gottlieb have betos-hcpcs from 2011

// FROM CLEMENS & GOTTLIEB 2014

import delimited "$raw/PSPS_2011.csv", clear
keep hcpcs_cd betos_cd
replace betos_cd = "" if inlist(betos_cd, "~~~", "~")
duplicates drop hcpcs_cd betos_cd, force
gen year = 2011
rename betos_cd betos
*** Elective Procedures will include Minor Procedures, Ambulatory Procedures, Eye Procedures, Orthopedic Procedures, and Imaging Procedures
gen ElectiveProc = 0
replace ElectiveProc = 1 if betos == "P2A" | betos == "P2C" | betos == "P2D" 
replace ElectiveProc = 1 if betos == "P3B" | betos == "P3C" 
replace ElectiveProc = 1 if betos == "P4B"  
replace ElectiveProc = 1 if betos == "P5A" | betos == "P5B" 
replace ElectiveProc = 1 if betos == "P6A" | betos == "P6B" 
replace ElectiveProc = 1 if betos == "P8A" | betos == "P8B" | betos == "P8C"  | betos == "P8D" | betos == "P8E" | betos == "P8F" | betos == "P8G" | betos == "P8H"
replace ElectiveProc = 1 if betos == "I4A"  

*** Non-Elective Procedures will include all non-elective procedure categories 
*** Note that coupled with the ElectiveProc categories, this is not an exhaustive treatment of the Procedures category.
*** Excluded are the "Other" Orthopedic, Eye, Minor, and Ambulatory procedures, "Lithotripsy" (whatever that is)
*** The "Other" Minor Procedures include both an "Medicare Fee Schedule" and "Non Medicare Fee Schedule" component
*** The category of dialysis services that are "Non Medicare Fee Schedule" are also excluded. 
gen NonElecProcA = 0
replace NonElecProcA = 1 if betos == "P1A" | betos == "P1B" | betos == "P1C"  | betos == "P1D" | betos == "P1E" | betos == "P1F" | betos == "P1G" 
replace NonElecProcA = 1 if betos == "P2B"
replace NonElecProcA = 1 if betos == "P3A" 
replace NonElecProcA = 1 if betos == "P4A" | betos == "P4C" 
replace NonElecProcA = 1 if betos == "P5C" 
replace NonElecProcA = 1 if betos == "P7A" | betos == "P7B" 
replace NonElecProcA = 1 if betos == "P9A" 

gen Other = 0
replace Other = 1 if ElectiveProc == 0 & NonElecProcA == 0

save "$working_data/temp/betos_hcpcs_elective_2011_cw", replace

// I am interested in the hcpcs-betos that are consistent between 2011 and the given year

tempfile elecproc
save `elecproc', emptyok

forvalues n = 12/19 {
	
	// load in betos-hcpcs codes for year 20`n'
	tempfile psps20`n'
	import delimited "$raw/PSPS_20`n'.csv", clear
	keep hcpcs_cd betos_cd
	replace betos_cd = "" if inlist(betos_cd, "~~~", "~")
	duplicates drop hcpcs_cd betos_cd, force
	gen year = 20`n'
	rename betos_cd betos
	save `psps20`n''
	
	// merge with clemens & gottlieb identification from 2011
	use "$working_data/temp/betos_hcpcs_elective_2011_cw"
	merge 1:1 hcpcs_cd betos using `psps20`n''
	
	// use these for stats on how many hcpcs-betos codes are added or removed for that year
	//g new_hcpcs_betos_20`n' = (_merge == 2)
	//g depricated_hcpcs_betos_20`n' = (_merge == 1)
	
	// only keep hcpcs + betos codes consistent between 2011 and 20`n'
	keep if _merge == 3

	drop _merge // this is the crosswalk relevant for year 20`n'
	
	rename hcpcs_cd hcpcs
	rename year year_elective_assigned
	
	drop if betos == "" // drop extraneous hcpcs code is not assigned a betos code
	
	// keep the betos-hcpcs-discretionary_procedures that are consistent for each year to merge onto billing data
	merge 1:m hcpcs using "$working_data/panels/aamc_cms_20`n'"
	gen UnassignedElective = (_merge == 2) // these hcpcs codes are not assigned an elective from the crosswalk
	drop if _merge == 1 // drop hcpcs-betos that don't show up in the billing data
	drop _merge
	
	drop if isDrug == 1
	
	gen elective_tot_pymt = hcpcs_tot_pymt * ElectiveProc
	gen nonelective_tot_pymt = hcpcs_tot_pymt * NonElecProc
	gen other_tot_pymt = hcpcs_tot_pymt * Other
	gen unassigned_elec_tot_pymt = hcpcs_tot_pymt * UnassignedElective

	gen elective_nServ = nServ * ElectiveProc
	gen nonelective_nServ = nServ * NonElecProc 
	gen other_nServ = nServ * Other
	gen unassigned_elec_nServ = nServ * UnassignedElective
	
	collapse (first) $npi_invariant (sum) ElectiveProc NonElecProc Other UnassignedElective elective_* nonelective_* other_* unassigned_*, by(npi)
	
	append using `elecproc'
	save `elecproc', replace

}

use `elecproc'

g ln_elective_pymt = log(elective_tot_pymt)
g ln_elective_srvc = log(elective_nServ)
g ln_elective_price = ln_elective_pymt - ln_elective_srvc

label variable ln_elective_pymt "Elective Procedure Payments (Th$2014)"
label variable ln_elective_srvc "Number of Elective Services"
label variable ln_elective_price "Price per Elective Service"

g ln_nonelective_pymt = log(nonelective_tot_pymt)
g ln_nonelective_srvc = log(nonelective_nServ)
g ln_nonelective_price = ln_nonelective_pymt - ln_nonelective_srvc

label variable ln_nonelective_pymt "Non-elective Procedure Payments (Th$2014)"
label variable ln_nonelective_srvc "Number of Non-Elective Services"
label variable ln_nonelective_price "Avg Price per Non-Elective Service"

do "$do/clean-phySpec.do"

encode phySpec, g(phySpec_ID)

save "$working_data/temp/aamc_cms_electiveproc", replace

**# count npi with unassigned procedures
use "$working_data/temp/aamc_cms_electiveproc", clear

g elective_npi = (ElectiveProc > 0)
g nonelective_npi = (NonElecProc > 0)
g other_proc_npi = (Other > 0)
g unassigned_proc_npi = (UnassignedElective > 0)
g all_unassigned_proc_npi = (UnassignedElective > 0 & elective_npi == 0 & nonelective_npi == 0 & other_proc_npi == 0)


collapse (count) npi (sum) elective_npi nonelective_npi other_proc_npi unassigned_proc_npi all_unassigned_proc_npi *_tot_pymt *_nServ, by(year)

rename npi npi_count
rename elective_npi elective_npi_count
rename nonelective_npi nonelective_npi_count
rename other_proc_npi other_proc_npi_count
rename unassigned_proc_npi unassigned_proc_npi_count
rename all_unassigned_proc_npi all_unassigned_proc_npi_count

label variable npi_count "total unique doc per year"
label variable elective_npi_count "total doc reporting elective procedure (C&G 2014; HCPCS-BETOS 2011 Elective Procedure ID)"
label variable nonelective_npi_count "total doc reporting nonelective procedure (C&G 2014; HCPCS-BETOS 2011 Elective Procedure ID)"
label variable other_proc_npi_count "total doc reporting other procedure (C&G 2014; HCPCS-BETOS 2011 Elective Procedure ID)"
label variable unassigned_proc_npi_count "total doc reporting unassigned procedures"
label variable all_unassigned_proc_npi_count "total doc reporting only unassigned procedures"


export delimited "$tables/elective_procedures_sumstat.csv", replace

**# merge on Cohort_ID with singletons
use "$working_data/temp/aamc_cms_electiveproc", clear

merge m:1 med_school grad_year using "$working_data/panels/aamc_id_2k2k10k_singleton"
keep if _merge == 3
drop _merge

**# analyze all years

label variable ln_elective_price "log(elective price)"
label variable ln_elective_pymt "log(elective payment)"
label variable ln_elective_srvc "log(elective service)"

// table A - Elective Procedures: Volume and Price
foreach oc of varlist ln_elective_* {
		
	eststo clear
	
	* row 1: Cohort#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year) vce(cluster Cohort_ID)
	
	* row 2: Cohort#Year HRR#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year) vce(cluster Cohort_ID)

	
	* row 3: Cohort#Year HRR#Year Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year event_time#year) vce(cluster Cohort_ID)
	
	* row 4: Cohort#Year HRR#Year Career_Time#Year Specialization#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year event_time#year phySpec_ID#year) vce(cluster Cohort_ID)
	
	* row 5: Cohort#Year HRR#Year Specialization#Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_ID#event_time#year) vce(cluster Cohort_ID)

	* format output

	esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(Cohort_ID#year "Cohort-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career-Year FE" phySpec_ID#year "Specialization-Year FE" phySpec_ID#time_since_grad_id#year "Specialization-Career-Year FE")					
		
	esttab est* using "$tables/elective_procedures_`oc'.html", ///
		keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N N_clust, fmt(%9.0fc %9.0fc) labels("Observations (doctor-years)" "Clusters")) ///
		title("Table A: Effect of Tuition on `: variable label `oc''") ///
		addnotes("Standard errors clustered at Cohort level") /// 
		replace
		
}

label variable ln_nonelective_price "log(non-elective price)"
label variable ln_nonelective_pymt "log(non-elective payment)"
label variable ln_nonelective_srvc "log(non-elective service)"

// Table B - Non-Elective Procedures: Volume and Price
foreach oc of varlist ln_nonelective_* {
	
	eststo clear
	
	* row 1: Cohort#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year) vce(cluster Cohort_ID)
	
	* row 2: Cohort#Year HRR#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year) vce(cluster Cohort_ID)

	
	* row 3: Cohort#Year HRR#Year Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year event_time#year) vce(cluster Cohort_ID)
	
	* row 4: Cohort#Year HRR#Year Career_Time#Year Specialization#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year event_time#year phySpec_ID#year) vce(cluster Cohort_ID)
	
	* row 5: Cohort#Year HRR#Year Specialization#Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_ID#event_time#year) vce(cluster Cohort_ID)

	* format output

	esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(Cohort_ID#year "Cohort-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career-Year FE" phySpec_ID#year "Specialization-Year FE" phySpec_ID#time_since_grad_id#year "Specialization-Career-Year FE")					
		
	esttab est* using "$tables/nonelective_procedures_`oc'.html", ///
		keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N N_clust, fmt(%9.0fc %9.0fc) labels("Observations (doctor-years)" "Clusters")) ///
		title("Table B: Effect of Tuition on `: variable label `oc''") ///
		addnotes("Standard errors clustered at Cohort level") /// 
		replace
		
}


**# look at 2012-2018 only; 2019 will diverge the most from C&G identification
keep if year != 2019

// table A - Elective Procedures: Volume and Price
foreach oc of varlist ln_elective_* {
	
	eststo clear
	
	* row 1: Cohort#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year) vce(cluster Cohort_ID)
	
	* row 2: Cohort#Year HRR#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year) vce(cluster Cohort_ID)

	
	* row 3: Cohort#Year HRR#Year Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year event_time#year) vce(cluster Cohort_ID)
	
	* row 4: Cohort#Year HRR#Year Career_Time#Year Specialization#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year event_time#year phySpec_ID#year) vce(cluster Cohort_ID)
	
	* row 5: Cohort#Year HRR#Year Specialization#Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_ID#event_time#year) vce(cluster Cohort_ID)

	* format output

	esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(Cohort_ID#year "Cohort-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career-Year FE" phySpec_ID#year "Specialization-Year FE" phySpec_ID#time_since_grad_id#year "Specialization-Career-Year FE")					
		
	esttab est* using "$tables/elective_procedures_`oc'_no2019.html", ///
		keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N N_clust, fmt(%9.0fc %9.0fc) labels("Observations (doctor-years)" "Clusters")) ///
		title("Table A: Effect of Tuition on `: variable label `oc''") ///
		addnotes("Standard errors clustered at Cohort level." "Excludes 2019, since that year diverges the most from C&G identification.") /// 
		replace
		
}

label variable ln_nonelective_price "log(non-elective price)"
label variable ln_nonelective_pymt "log(non-elective payment)"
label variable ln_nonelective_srvc "log(non-elective service)"

// Table B - Non-Elective Procedures: Volume and Price
foreach oc of varlist ln_nonelective_* {
	
	eststo clear
	
	* row 1: Cohort#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year) vce(cluster Cohort_ID)
	
	* row 2: Cohort#Year HRR#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year) vce(cluster Cohort_ID)

	
	* row 3: Cohort#Year HRR#Year Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year event_time#year) vce(cluster Cohort_ID)
	
	* row 4: Cohort#Year HRR#Year Career_Time#Year Specialization#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year event_time#year phySpec_ID#year) vce(cluster Cohort_ID)
	
	* row 5: Cohort#Year HRR#Year Specialization#Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_ID#event_time#year) vce(cluster Cohort_ID)

	* format output

	esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(Cohort_ID#year "Cohort-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career-Year FE" phySpec_ID#year "Specialization-Year FE" phySpec_ID#time_since_grad_id#year "Specialization-Career-Year FE")					
		
	esttab est* using "$tables/nonelective_procedures_`oc'_no2019.html", ///
		keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N N_clust, fmt(%9.0fc %9.0fc) labels("Observations (doctor-years)" "Clusters")) ///
		title("Table B: Effect of Tuition on `: variable label `oc''") ///
		addnotes("Standard errors clustered at Cohort level." "Excludes 2019, since that year diverges the most from C&G identification.") /// 
		replace
		
}


**# look at 2012 only, most accurate year of C&G categorization
keep if year == 2012

// table A - Elective Procedures: Volume and Price
foreach oc of varlist ln_elective_* {
	
	eststo clear
	
	* row 1: Cohort#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year) vce(cluster Cohort_ID)
	
	* row 2: Cohort#Year HRR#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year) vce(cluster Cohort_ID)

	
	* row 3: Cohort#Year HRR#Year Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year event_time#year) vce(cluster Cohort_ID)
	
	* row 4: Cohort#Year HRR#Year Career_Time#Year Specialization#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year event_time#year phySpec_ID#year) vce(cluster Cohort_ID)
	
	* row 5: Cohort#Year HRR#Year Specialization#Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_ID#event_time#year) vce(cluster Cohort_ID)

	* format output

	esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(Cohort_ID#year "Cohort-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career-Year FE" phySpec_ID#year "Specialization-Year FE" phySpec_ID#time_since_grad_id#year "Specialization-Career-Year FE")					
		
	esttab est* using "$tables/elective_procedures_`oc'_only2012.html", ///
		keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N N_clust, fmt(%9.0fc %9.0fc) labels("Observations (doctor-years)" "Clusters")) ///
		title("Table A: Effect of Tuition on `: variable label `oc''") ///
		addnotes("Standard errors clustered at Cohort level." "Only 2012, since that year is most similar to the C&G identification.") /// 
		replace
		
}

label variable ln_nonelective_price "log(non-elective price)"
label variable ln_nonelective_pymt "log(non-elective payment)"
label variable ln_nonelective_srvc "log(non-elective service)"

// Table B - Non-Elective Procedures: Volume and Price
foreach oc of varlist ln_nonelective_* {
	
	eststo clear
	
	* row 1: Cohort#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year) vce(cluster Cohort_ID)
	
	* row 2: Cohort#Year HRR#Year
	
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year) vce(cluster Cohort_ID)

	
	* row 3: Cohort#Year HRR#Year Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year event_time#year) vce(cluster Cohort_ID)
	
	* row 4: Cohort#Year HRR#Year Career_Time#Year Specialization#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year event_time#year phySpec_ID#year) vce(cluster Cohort_ID)
	
	* row 5: Cohort#Year HRR#Year Specialization#Career_Time#Year 
	eststo : reghdfe `oc' ln_tuition_bill, a(Cohort_ID#year hrr#year phySpec_ID#event_time#year) vce(cluster Cohort_ID)

	* format output

	esttab est*, keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	estfe . est*, labels(Cohort_ID#year "Cohort-Year FE" hrr#year "HRR-Year FE" time_since_grad_id#year "Career-Year FE" phySpec_ID#year "Specialization-Year FE" phySpec_ID#time_since_grad_id#year "Specialization-Career-Year FE")					
		
	esttab est* using "$tables/nonelective_procedures_`oc'_only2012.html", ///
		keep(ln_tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N N_clust, fmt(%9.0fc %9.0fc) labels("Observations (doctor-years)" "Clusters")) ///
		title("Table B: Effect of Tuition on `: variable label `oc''") ///
		addnotes("Standard errors clustered at Cohort level." "Only 2012, since that year is most similar to the C&G identification.") /// 
		replace
		
}

**# Identify which HCPCS codes are categorized

use "$working_data/temp/aamc_cms_electiveproc", clear

merge m:1 med_school grad_year using "$working_data/panels/aamc_id_2k2k10k_singleton"
keep if _merge == 3
drop _merge

tempfile hcpcselecproc
save `hcpcselecproc', emptyok

forvalues n = 12/19 {
		
	// load in betos-hcpcs codes for year 20`n'
	tempfile psps20`n'
	import delimited "$raw/PSPS_20`n'.csv", clear
	keep hcpcs_cd betos_cd
	replace betos_cd = "" if inlist(betos_cd, "~~~", "~")
	duplicates drop hcpcs_cd betos_cd, force
	gen year = 20`n'
	rename betos_cd betos
	save `psps20`n''
	
	// merge with clemens & gottlieb identification from 2011
	use "$working_data/temp/betos_hcpcs_elective_2011_cw"
	merge 1:1 hcpcs_cd betos using `psps20`n''
	
	// use these for stats on how many hcpcs-betos codes are added or removed for that year
	//g new_hcpcs_betos_20`n' = (_merge == 2)
	//g depricated_hcpcs_betos_20`n' = (_merge == 1)
	
	// only keep hcpcs + betos codes consistent between 2011 and 20`n'
	keep if _merge == 3

	drop _merge // this is the crosswalk relevant for year 20`n'
	
	rename hcpcs_cd hcpcs
	rename year year_elective_assigned
	
	drop if betos == "" // drop extraneous hcpcs code is not assigned a betos code
	
	// keep the betos-hcpcs-discretionary_procedures that are consistent for each year to merge onto billing data
	merge 1:m hcpcs using "$working_data/panels/aamc_cms_20`n'"
	gen UnassignedElective = (_merge == 2) // these hcpcs codes are not assigned an elective from the crosswalk
	drop if _merge == 1 // drop hcpcs-betos that don't show up in the billing data
	drop _merge
	
	drop if isDrug == 1
	
	gen elective_tot_pymt = hcpcs_tot_pymt * ElectiveProc
	gen nonelective_tot_pymt = hcpcs_tot_pymt * NonElecProc
	gen other_tot_pymt = hcpcs_tot_pymt * Other
	gen unassigned_elec_tot_pymt = hcpcs_tot_pymt * UnassignedElective

	gen elective_nServ = nServ * ElectiveProc
	gen nonelective_nServ = nServ * NonElecProc 
	gen other_nServ = nServ * Other
	gen unassigned_elec_nServ = nServ * UnassignedElective
	
	collapse (first) betos ElectiveProc NonElecProc Other UnassignedElective rbcs_cat_desc rbcs_cat_subcat rbcs_subcat_desc (sum) hcpcs_tot_pymt nServ elective_* nonelective_* other_* unassigned_*, by(hcpcs)
	
	gen year = 20`n'
	egen annual_tot_pymts = total(hcpcs_tot_pymt)
	egen annual_tot_nServe = total(nServ)
	gen pct_annual_tot_pymt = (hcpcs_tot_pymt / annual_tot_pymts) * 100
	gen pct_annual_nServ = (nServ / annual_tot_nServe) * 100
	
	append using `hcpcselecproc'
	save `hcpcselecproc', replace

}

save "$working_data/temp/hcpcs_electoral_proc", replace

use `hcpcselecproc'

// need to merge on rbcs categories by year
// GOAL: see which HCPCS codes are largest fraction of assigned electives

preserve
keep if UnassignedElective == 1
g hcpcs_cnt = 1
collapse (count) hcpcs_cnt (sum) pct_annual_tot_pymt, by(year)
label variable pct_annual_tot_pymt "Unassigned Payments (% of Tot Payments)"
label variable hcpcs_cnt "Unassigned HCPCS Count"
twoway (bar hcpcs_cnt year, yaxis(2)) (line pct_annual_tot_pymt year, yaxis(1))
restore

