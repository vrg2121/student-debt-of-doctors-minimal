/* 

PREAMBLE

HCPCS regressions as specified in the Revamp of Empirical Strategy.

Can be used as a batch job on a cluster environment.
Computer: 16+ CPUs, 200+ GB RAM

Estimated walltime: 2 hours
   
Victoria Garcia 
December 2025
*/

*** DIRECTORIES ***
* dropbox *
/*
global proj_dropbox "C:/dropbox/Phil Research Dropbox/Victoria Garcia/Student Debt of Doctors"

global v_data "$proj_dropbox/Tuition Data/victoria-temp/data"

glboal v_tables "$proj_dropbox/Tuition Data/victoria-temp/tables"
*/

* cluster *
global v_data "/home/victoria.garcia/Batch/data"
global v_tables "/home/victoria.garcia/Batch/tables"

*** LOAD IDENTIFIED HCPCS DATA ***
use "$v_data/hcpcs/cms_aamc_id_hcpcs", clear

label var tuition_bill "Tuition bill"

replace avg_mdcr_pymt_amt = 0 if avg_mdcr_pymt_amt == .

egen school_id = group(med_school) // this has been added to 01_cms_aamc_merge for future data 12.1.2025
label variable school_id "med school id by med_school" // added to 01_cms_aamc_merge 12.3.2025

encode grouppac, gen(ngrouppac)	// added to 01_cms_aamc_merge 12.3.2025

global cohort ds dum_* 		// cohort dummy variables
global cohort_dum `cohort'

global revamp_hcpcs_fe "ngrouppac#year hrr physpec hcpcs"
global hcpcs_fe "med_school grad_year physpec ngrouppac hcpcs"


*** OLD FE METHOD ***
eststo clear

foreach FE of global hcpcs_fe {
	eststo : reghdfe avg_mdcr_pymt_amt tuition_bill $cohort_dum, a(`FE') vce(cluster school_id)
	
	sum avg_mdcr_pymt_amt if e(sample) == 1
	
	estadd r(mean)
	
	scalar pct_mean = 100* _b[tuition_bill] / r(mean)
	
	estadd scalar pct_mean
}

esttab est*, keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label

estfe est*, labels(                 /// ssc install erepost
	med_school "School FE"          ///
	grad_year  "Graduation Year FE" ///
	physpec    "Specialization FE"  ///
	hrr        "HRR FE"             ///
	ngrouppac  "Group FE"           ///
	hcpcs      "HCPCS FE")

esttab est* using "$v_tables/fe-regs-hcpcs-avg_mdcr_pymt_amt.tex", ///
	keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N N_clust mean pct_mean, fmt(%9.0fc %9.0fc 3 1) labels("Observations (dr-yr-hcpcs)" "Clusters" "Mean" "Coef.\ \% of Mean")) ///
	replace
	
*** REVAMP FE METHOD ***
eststo clear
	
* baseline regression - no  controls determined after doc leaves school *
eststo : reghdfe avg_mdcr_pymt_amt tuition_bill $cohort_dum, a(school_id#year) vce(cluster school_id)

* Mean:
sum avg_mdcr_pymt_amt if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[tuition_bill] / r(mean)
estadd scalar pct_mean

* Unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

* unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

foreach FE of global revamp_hcpcs_fe{
	eststo : reghdfe avg_mdcr_pymt_amt tuition_bill $cohort_dum, a(school_id#year `FE') vce(cluster school_id)

	* Mean:
	sum avg_mdcr_pymt_amt if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[tuition_bill] / r(mean)
	estadd scalar pct_mean

	* Unique doctors
	unique npi if e(sample) == 1
	estadd scalar unique_drs = r(unique)

	* unique schools
	unique med_school if e(sample) == 1
	estadd scalar unique_schools = r(unique)
}

esttab est*, keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(school_id#year "School-Year FE" ngrouppac#Year "GroupPAC-Year FE" hrr "HRR FE" physpec "Specialization FE"hcpcs "HCPCS FE")						
	
esttab est* using "$v_tables/revamp-fe-regs-hcpcs-avg_mdcr_pymt_amt.tex", ///
	keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_drs N_clust /* unique_schools */ mean pct_mean, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef.\ \% of Mean")) ///
	replace