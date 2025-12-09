/* 

PREAMBLE

Initial regressions as specified in the Revamp of Empirical Strategy.
   
Victoria Garcia 
December 2025
*/

clear all
	
*** LOAD IDENTIFIED DATA ***

use "$working_data/cms_aamc_merge_identifier.dta", clear

egen school_id = group(med_school) // this has been added to 01_cms_aamc_merge for future data 12.1.2025
label variable school_id "med school id by med_school"

encode groupPAC, gen(ngroupPAC)


*** SET VARIABLES FOR REGRESSIONS ***

/* Outcome Variable Descriptions
all_total_payments = Total CMS Payments ( I think )
fg_sel3_total_payments = Total CMS Payments, unclear how it differs from all_total_payments, they do differ
fg_sel3_nServ = Total Number of Services ( I think, what is nServ? )
fg_sel5_total_payments = Payments: EM Codes ( What is E/M? Emergency? )
fg_sel5_nServ = Total Number of E/M Services
pp_payment = kickback payments (?)

*/

global outcome "all_total_payments fg_sel3_total_payments fg_sel3_nServ fg_sel5_nServ fg_sel5_total_payments pp_payment"

* fixed effect variables *
global cohort ds dum_* 		// cohort dummy variables
global cohort_dum `cohort'
global fixed_effects "med_school grad_year phySpec hrr groupPAC"
global revamp_fe "ngroupPAC#year hrr phySpec"


*** REGRESSION TABLES: NAIVE ***

/// dev
* naive regressions *
eststo clear
foreach oc of global outcome {
	eststo: reg `oc' tuition_bill $cohort_dum, vce(cluster school_id)
	esttab est*, keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
	

}

esttab


*** REGRESSION TABLES: PREVIOUS FE ***
foreach oc of global outcome {
	eststo clear
	foreach FE of global fixed_effects {
		
			disp ""
			disp "Outcome = `: variable label `oc''"
			disp ""
			eststo : reghdfe `oc' tuition_bill $cohort_dum, a(`FE') vce(cluster school_id)
			
			* Mean:
			sum `oc' if e(sample) == 1
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
	estfe est*, labels( 					///
		med_school "School FE"				///
		grad_year "Graduation Year FE" 		///
		phySpec "Specialization FE"			///
		hrr "HRR FE"						///
		groupPAC "Group FE")
		
	esttab est* using "$tables/fe-regs-`oc'.tex", ///
		keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N unique_drs N_clust /* unique_schools */ mean pct_mean, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef.\ \% of Mean")) ///
		replace
}


*** REGRESSION TABLES: REVAMP FE ***
foreach oc of global outcome {
	
	eststo clear
	
	* baseline regression - no  controls determined after doc leaves school *
	eststo : reghdfe `oc' tuition_bill $cohort_dum, a(school_id#year) vce(cluster school_id)

	* Mean:
	sum `oc' if e(sample) == 1
	estadd r(mean)

	scalar pct_mean = 100 * _b[tuition_bill] / r(mean)
	estadd scalar pct_mean

	* Unique doctors
	unique npi if e(sample) == 1
	estadd scalar unique_drs = r(unique)

	* unique schools
	unique med_school if e(sample) == 1
	estadd scalar unique_schools = r(unique)

	foreach FE of global revamp_fe{
		eststo : reghdfe `oc' tuition_bill $cohort_dum, a(school_id#year `FE') vce(cluster school_id)

		* Mean:
		sum `oc' if e(sample) == 1
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
	estfe . est*, labels(school_id#year "School-Year FE" ngroupPAC#Year "GroupPAC-Year FE" hrr "HRR FE" phySpec "Specialization FE")						
		
	esttab est* using "$tables/revamp-fe-regs-`oc'.tex", ///
		keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
		indicate(`r(indicate_fe)') nomtitles ///
		stats(N unique_drs N_clust /* unique_schools */ mean pct_mean, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef.\ \% of Mean")) ///
		replace
}


