
***************
*** GLOBALS ***
***************

* Sets globals such as values, outcomes, FEs, programs, etc

***************
***************
***************


*** GLOBALS ***
  

* BETOS codes for Emiel's total payments variable:
global emiel_betos ///
	AA ///
	EB EC EE EH EI EM EN EO ER EV EX ///
	IC IM IN IS IU IX ///
	NA ///
	PC PE PG PM PO PS PV ///
	RB RD RH RI RR RT RX ///
	TA TC TN TP TX

	
* Restricts CMS panel backwards in time:
global min_grad_year = 1990


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

