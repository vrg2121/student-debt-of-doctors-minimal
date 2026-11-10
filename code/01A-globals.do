
***************
*** GLOBALS ***
***************

* Description of this do-file:

* 	Sets globals such as values, outcomes, FEs, programs, etc

***************
***************
***************


*** SCHEMES ***

// set scheme white_tableau // ssc install schemepack


*** GLOBALS ***
   
* Different specializations (deprecated):
// global specializations ///
// 	chiro_school /// chiropractor
// 	osteo_school /// osteopath
// 	optom_school /// optometry
// 	podia_school /// podiatry
// 	medic_school //  medical school ("ordinary")
   
* Min number of graduates from school (deprecated):
// global min_nr_obs = 10^4

* BETOS codes for Emiel's total payments variable:
global emiel_betos ///
	AA ///
	EB EC EE EH EI EM EN EO ER EV EX ///
	IC IM IN IS IU IX ///
	NA ///
	PC PE PG PM PO PS PV ///
	RB RD RH RI RR RT RX ///
	TA TC TN TP TX

* Different payment variables:
global payment_vars ///
	all ///
	emiel_betos ///
	fg_hcpcs ///
	fg_sel1 ///
	fg_sel2 ///
	fg_sel3 ///
	fg_sel4 ///
	fg_sel5
	
* Restricts CMS panel backwards in time:
global min_grad_year = 1990
	
* Deprecated:
// global lower_year_limit = 1996
// global upper_year_limit = 2024

* Deprecated:
// assert ($lower_year_limit + 1) > $min_grad_year
	
* Large tuition shock limit (USD 1,000):
global dollar_limit = 2
	
* Auxiliary variables when defining treatment groups:
global   med_school_length =  4
global extra_window_length = 20
	
* Outcomes to create sample dummy for:
global outcomes ///
	all_total_payments ///
	fg_sel3_total_payments ///
	fg_sel5_total_payments ///
	fg_sel3_nServ ///
	fg_sel5_nServ ///
	pp_payment ///
	nServ ///
	nCode ///
	fg_sel3_nCode ///
	fg_sel5_nCode

// 	pp_brand_per_ben ///
// 	pp_p_brand ///
// 	pp_p_opioid_benes
		
* Grades of interest (treatment groups):
global treated_grades ///
	grade_2 ///
	grade_3 ///
	grade_4

* Expressed as years treated:
global years_treated ///
	years_treated_1 ///
	years_treated_2 ///
	years_treated_3

* IV outcomes for Overleaf:
global iv_outcomes ///
	all_total_payments ///
	fg_sel3_total_payments ///
	fg_sel5_total_payments ///
	nServ ///
	fg_sel3_nServ ///
	fg_sel5_nServ ///
	pp_payment
	
* FEs in IV regressions:
   global FEs `"      "med_school" "'
   global FEs `" $FEs "med_school grad_year" "'
   global FEs `" $FEs "med_school grad_year phySpec" "'
   global FEs `" $FEs "med_school grad_year phySpec hrr" "'
   global FEs `" $FEs "med_school grad_year phySpec groupPAC" "'
// global FEs `" $FEs "med_schoolXgrad_year" "'

* Controls in IV regressions:
global controls
// male isMD nPhyInGroup hosAff inMedicare inERX inPQRS inEHR // experYear


*** PROGRAMS ***

* Inflation adjustment:
cap program drop inflationAdjust
program define   inflationAdjust

	args var year
	
	* Source for CPI:
	* https://www.bls.gov/cpi/tables/supplemental-files/historical-cpi-u-202507.xlsx
	
	replace `var' = . if !inrange(`year', 1992, 2024)
	
	local base = 233.916 // 2014
	
	replace `var' = `var' * `base' / 138.1   if `year' == 1992
	replace `var' = `var' * `base' / 142.6   if `year' == 1993
	replace `var' = `var' * `base' / 146.2   if `year' == 1994
	replace `var' = `var' * `base' / 150.3   if `year' == 1995
	replace `var' = `var' * `base' / 154.4   if `year' == 1996
	replace `var' = `var' * `base' / 159.1   if `year' == 1997
	replace `var' = `var' * `base' / 161.6   if `year' == 1998
	replace `var' = `var' * `base' / 164.3   if `year' == 1999
	replace `var' = `var' * `base' / 168.8   if `year' == 2000
	replace `var' = `var' * `base' / 175.1   if `year' == 2001
	replace `var' = `var' * `base' / 177.1   if `year' == 2002
	replace `var' = `var' * `base' / 181.7   if `year' == 2003
	replace `var' = `var' * `base' / 185.2   if `year' == 2004
	replace `var' = `var' * `base' / 190.7   if `year' == 2005
	replace `var' = `var' * `base' / 198.3   if `year' == 2006
	replace `var' = `var' * `base' / 202.416 if `year' == 2007
	replace `var' = `var' * `base' / 211.080 if `year' == 2008
	replace `var' = `var' * `base' / 211.143 if `year' == 2009
	replace `var' = `var' * `base' / 216.687 if `year' == 2010
	replace `var' = `var' * `base' / 220.223 if `year' == 2011
	replace `var' = `var' * `base' / 226.655 if `year' == 2012
	replace `var' = `var' * `base' / 230.280 if `year' == 2013
	replace `var' = `var' * `base' / 233.916 if `year' == 2014 // base
	replace `var' = `var' * `base' / 233.707 if `year' == 2015
	replace `var' = `var' * `base' / 236.916 if `year' == 2016
	replace `var' = `var' * `base' / 242.839 if `year' == 2017
	replace `var' = `var' * `base' / 247.867 if `year' == 2018
	replace `var' = `var' * `base' / 251.712 if `year' == 2019
	replace `var' = `var' * `base' / 257.971 if `year' == 2020
	replace `var' = `var' * `base' / 261.582 if `year' == 2021
	replace `var' = `var' * `base' / 281.148 if `year' == 2022
	replace `var' = `var' * `base' / 299.170 if `year' == 2023
	replace `var' = `var' * `base' / 308.417 if `year' == 2024
	
end

global npi_invariant ///
		year phySpec* cred isMD  ///
		gy_cnt ms_cnt mult_grad_year mult_med_school grad_year med_school ///
		mdcr_participant zip5 groupPAC event_time hrr ///
		aca_year tuition PublicSchool source nominal_tuition med_school_chrono ///
		delta_nominal_tuition nominal_tuition_bill delta_tuition tuition_bill Tuition_quantile


*** OLD PROGRAMS ***

// cap program drop runRegressions
// program define   runRegressions
//
// 	args outcome dummy nCode nCodeEM
//	
// 	local controls $main_controls PublicSchool `nCode' `nCodeEM'
//	
// 	eststo clear
//	
// 	qui: eststo: reghdfe `outcome' `dummy' `controls', ///
// 		cluster(hrr) a(hrr phySpec)
//		
// 	qui: eststo: reghdfe `outcome' `dummy' `controls', ///
// 		cluster(hrr) a(hrr phySpec grd_yr)
//	
// 	qui: eststo: reghdfe `outcome' `dummy' `controls', ///
// 		cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
//		
// 	qui: eststo: reghdfe `outcome' `dummy' `controls', ///
// 		cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
//		
// 	qui: eststo: reghdfe `outcome' `dummy' `controls', ///
// 		cluster(hrr) a(hrr grd_yrXphyspec)
//		
// 	qui: eststo: reghdfe `outcome' `dummy' `controls', ///
// 		cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
//		
// 	esttab est*, keep(`dummy') se star(* 0.10 ** 0.05 *** 0.01)
//	
// end

// cap program drop runRegressionsInteract
// program define   runRegressionsInteract
//
// 	args outcome dummy interact nCode nCodeEM
//	
// 	local controls $main_controls PublicSchool `nCode' `nCodeEM'
//	
// 	eststo clear
//	
// 	eststo: reghdfe `outcome' `dummy'##`interact' `controls', ///
// 		cluster(hrr) a(hrr phySpec)
//		
// 	eststo: reghdfe `outcome' `dummy'##`interact' `controls', ///
// 		cluster(hrr) a(hrr phySpec grd_yr)
//	
// 	eststo: reghdfe `outcome' `dummy'##`interact' `controls', ///
// 		cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
//		
// 	eststo: reghdfe `outcome' `dummy'##`interact' `controls', ///
// 		cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
//		
// 	eststo: reghdfe `outcome' `dummy'##`interact' `controls', ///
// 		cluster(hrr) a(hrr grd_yrXphyspec)
//		
// 	eststo: reghdfe `outcome' `dummy'##`interact' `controls', ///
// 		cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
//		
// 	esttab est*, keep(1.`dummy'#1.`interact') se star(* 0.10 ** 0.05 *** 0.01)
//	
// end

