
****************************************************************
*** DEFINE GRADE PER (SCHOOL, GRAD YEAR) FOR TREATED SCHOOLS ***
****************************************************************


* The purpose of this code is the create the mapping:

* 	If a doctor attended a treated school and graduated in a certain year,
*	then what grade was the doctor in when the treatment happened?

* We need to be careful since treatment at school can occur multiple times
* E.g. in both 2000 and 2001, or even more times


use "$git/data/original/aamc/modified/aamc-tuition", clear

* Check so panel is still well-behaved:
bys med_school grd_yr : assert _N == 1

* We want everyone to have graduated before we look at outcomes (maybe not necessary):
keep if inrange(grd_yr, $lower_year_limit, $upper_year_limit)

rename grd_yr gradYear

* Adjusting for gradYear being e.g. 2001 if graduating in academic year 2000-2001:
replace gradYear = gradYear + 1


* Note that the above translation means that for everything below:
* 	For a given academic year x-y, we think of y as being the academic year
*	Previously we have thought of x as being the academic year


* Keep only treated pairs of (school, grad year):
keep if delta_tuition > $dollar_limit & delta_tuition != .

* New, choose max:
bys med_school : egen max_delta_tuition = max(delta_tuition)

keep if delta_tuition == max_delta_tuition

* When necessary:
// bys med_school (gradYear) : keep if _n == 1 // careful here!

bys med_school : assert _N == 1

* Continuing:
keep med_school gradYear


*** The following section expands our selection into a panel and defines grade ***


* Expand into panel, including grades below zero:
expand $med_school_length + $extra_window_length

g increase_year = gradYear // will adjust this later

* Build a timeline:
bys med_school gradYear : replace gradYear = gradYear + _n - 1

* Check so panel is well-behaved:
bys med_school increase_year gradYear : assert _N == 1

* Define grade:
g grade = increase_year - gradYear + $med_school_length

* Adjust to skip zero grade (go from -1 to 1 instead of -1, 0, 1):
replace grade = grade - 1 if grade <= 0

* Expand to grades above 4:
expand $extra_window_length + 1 if grade == $med_school_length

sort med_school increase_year gradYear grade

bys med_school increase_year gradYear grade : replace gradYear = ///
	gradYear - ($extra_window_length + 1 - _n) if grade == $med_school_length

replace grade = increase_year - gradYear + $med_school_length ///
	if grade >= $med_school_length

* In case a pair (school, grad year) has multiple grades, choose the most relevant:
g 		treatment_ranking = .
replace treatment_ranking = grade if inrange(grade, 1, $med_school_length)
replace treatment_ranking = $med_school_length - grade if grade < 0
replace treatment_ranking = grade + $extra_window_length if grade > $med_school_length

bys med_school gradYear (treatment_ranking) : keep if _n == 1

drop /* increase_year */ treatment_ranking

* Define potential dummy here:
g delta_tuition_dummy = grade == 2 if inlist(grade, 2, 4)

replace increase_year = increase_year - 1

save "$temp/delta-tuition-dummy", replace


*********************************************
*** MERGE TUITION PANEL INTO DOCTOR PANEL ***
*********************************************

use "$git/data/working/FullDataCMSPANEL_final_subsample", clear

* EXTRA TEMP:
merge m:1 npi using "$temp/cms-graduation-years", keepusing(grad_year)
drop if _merge == 2
drop    _merge

// tab grd_yr   , m
// tab grad_year, m
//
// tab grd_yr grad_year if ///
// 	inrange(grd_yr   , 2010, 2020) & ///
// 	inrange(grad_year, 2010, 2020), m

drop grd_yr gradYear

g grd_yr   = grad_year
g gradYear = grad_year

* Checking consistency of panel:
bys npi  year  : assert _N == 1
bys npi (year) : g delta_year = year[_n + 1] - year[_n] if _n < _N

expand delta_year

bys npi (year) : replace year = year[_n - 1] + 1 if _n > 1 & delta_year > 1

* We need to know the graduation year:
drop if grad_year == .

keep if inrange(grad_year, $lower_year_limit, $upper_year_limit + 2 + 1)

* Event time:
g event_time = year - grad_year

* Panel should start at graduation year:
drop if event_time <= 0

assert   year != .
bys npi (year) : g min_et = event_time if _n == 1

expand min_et

* CAREFUL ABOUT THIS:
bys npi (year) : replace event_time = _n
bys npi (year) : replace year       = _n + grad_year

drop min_et

* Checking consistency of panel:
bys npi  year  : assert _N == 1
bys npi (year) : assert year[_n] + 1 == year[_n + 1] if _n < _N

cap drop total_payments
cap drop servicesEM

* TEMP:
// 	rename grd_yr temp
// 	rename gradYear grd_yr
// 	rename temp gradYear

* Probably not:
drop grd_yr

rename gradYear grd_yr

* Rename for merge with keys:
rename med_sch our_med_school

* Make school lower-case as in keys:
replace our_med_school = lower(our_med_school)

* Check so var is unique within npi:
foreach var in our_med_school grd_yr {
	
	bys npi (`var') : assert `var'[1] == `var'[_N]
	 
}

* Merge on key:
merge m:1 our_med_school using "$git/data/working/unique-names/keys/key-our-aamc", keepusing(med_school)
drop if _merge == 2
drop _merge

* Merge on tuition:
merge m:1 med_school grd_yr using "$git/data/original/aamc/modified/aamc-tuition"
drop if _merge == 2
drop _merge

* Drop irrelevant doctors (verify!):
// bys npi : egen keep = max(tuition != .)
//
// keep if keep == 1
// drop    keep

* Merge on increase dummy (verify!):

rename grd_yr gradYear

merge m:1 med_school gradYear using "$temp/delta-tuition-dummy"
drop if _merge == 2
drop _merge

rename gradYear grd_yr

* Selection:
   keep if inrange(grade,  2, 5)
// keep if inrange(grade, -1, 5)

* Dummies for grades:
forvalues x = 2/5 {
	g         grade_change_`x' = grade == `x'
	label var grade_change_`x' "Grade in tuition shock"
}

* Merge on ProPublica:
merge 1:1 npi year using "$temp/propublica-docdollars-total-amount"
drop if _merge == 2
drop _merge

merge 1:1 npi year using "$temp/propublica-brand-claims-beneficiaries"
drop if _merge == 2
drop _merge

g start_yr = grd_yr - 3 // medical school is four years, for example:

* 2003-2004 = 4th yr
* 2002-2003 = 3rd yr
* 2001-2002 = 2nd yr
* 2000-2001 = 1st yr

sort  npi year our_med_school grd_yr
order npi year our_med_school grd_yr start_yr, first

* Handle missing values:

assert  pri_spec != "MISSING"
replace pri_spec  = "MISSING" if pri_spec == ""

assert  hrr != 0
replace hrr  = 0 if hrr == .

g pp_quotient = brand_claim_count / ben_count

replace pp_quotient = 0 if brand_claim_count == .

* Create dummy for payment:
g pp_payment = ///
	total_amount_of_payment_usdollar >  0 & ///
	total_amount_of_payment_usdollar != .    // missings purposely become zero

save "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", replace

*** ADDING EXTRA CONTROLS ETC ***

use  "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

* Check so 2013 is min:
// sum year
// assert r(min) == 2013
//
// * Create 2012:
// expand 2 if year == 2013
// bys npi year : replace year = year - 1 if year == 2013 & _n == 1
//
// * Verify panel is identified by (npi, year):
// bys npi year : assert _N == 1

* Should maybe adjust by adding 3 (?) to each year?
// keep if inrange(grd_yr, $lower_year_limit, $upper_year_limit)

* Merge in Simon's nCodes:
merge m:1 npi using "$temp/nCodes"
drop if _merge == 2
drop    _merge

* Simon will think about this later:
forvalues j = 2012/2019 {
	
	replace S_nCode_`j'   = 0 if S_nCode_`j'   == .
	replace S_nCodeEM_`j' = 0 if S_nCodeEM_`j' == .
	
}

* Merge in Simon's new payments variable:
merge 1:1 npi year using "emiel-total_payments-fg-hcpcs-codes"
// keep if _merge == 3
   drop if _merge == 2
   drop    _merge

// drop male isMD

// male         ///
// isMD         ///

* Merge in FG's totPaid outcomes and controls:
merge m:1 npi using "$fang_gong_replication/output/phy_time", ///
	keepusing( ///
		totPaid_2012 /// outcome
		totPaid_2013 /// outcome
		experYear    /// control we keep constant
		nPhyInGroup  /// control we keep constant
		hosAff       /// control we keep constant
		inMedicare   /// control we keep constant
		inERX        /// control we keep constant
		inPQRS       /// control we keep constant
		inEHR        /// control we keep constant
		phySpec      /// control we keep constant
		groupPAC     /// control we keep constant
		nCode_*      /// control which varies by year
		nCodeEM_*)    // control which varies by year

* Keep overlap:
drop if _merge == 2
drop    _merge
		
global const_vars
foreach var in ///
		experYear    /// control we keep constant
		nPhyInGroup  /// control we keep constant
		hosAff       /// control we keep constant
		inMedicare   /// control we keep constant
		inERX        /// control we keep constant
		inPQRS       /// control we keep constant
		inEHR        /// control we keep constant
		phySpec      /// control we keep constant
		groupPAC     /// control we keep constant
		{
			rename `var' `var'_const
			global const_vars $const_vars `var'
		}
		
* Dynamic controls:
merge 1:1 npi year using "$temp/characteristics", ///
	keepusing( ///
		experYear    ///
		nPhyInGroup  ///
		hosAff       ///
		inMedicare   ///
		inERX        ///
		inPQRS       ///
		inEHR        ///
		phySpec      ///
		groupPAC)    //
		
* From here: all of the controls above, except for nCode and nCode EM, will be from FG!

* Keep overlap:
drop if _merge == 2
drop    _merge

egen grd_yrXphyspec = group(phySpec grd_yr)
egen grd_yrXhrr     = group(hrr     grd_yr)

egen grd_yrXphyspec_const = group(phySpec_const grd_yr)
global const_vars $const_vars grd_yrXphyspec

g double S_nCode   = .
g double S_nCodeEM = .
forvalues n = 2012/2019 {
	replace S_nCode   = S_nCode_`n'   if year == `n'
	replace S_nCodeEM = S_nCodeEM_`n' if year == `n'
}

g       ACA_adjusted = 1
replace ACA_adjusted = 0 if ///	
	state_fips ==  4 & year >= 2014 | /// Arizona -- January 1, 2014
	state_fips ==  5 & year >= 2014 | /// Arkansas -- January 1, 2014
	state_fips ==  6 & year >= 2014 | /// California -- January 1, 2014
	state_fips ==  8 & year >= 2014 | /// Colorado -- January 1, 2014
	state_fips ==  9 & year >= 2014 | /// Connecticut -- January 1, 2014
	state_fips == 10 & year >= 2014 | /// Delaware -- January 1, 2014
	state_fips == 11 & year >= 2014 | /// District of Columbia -- January 1, 2014
	state_fips == 15 & year >= 2014 | /// Hawaii -- January 1, 2014
	state_fips == 17 & year >= 2014 | /// Illinois -- January 1, 2014
	state_fips == 19 & year >= 2014 | /// Iowa -- January 1, 2014
	state_fips == 21 & year >= 2014 | /// Kentucky -- January 1, 2014
	state_fips == 24 & year >= 2014 | /// Maryland -- January 1, 2014
	state_fips == 25 & year >= 2014 | /// Massachusetts -- January 1, 2014
	state_fips == 27 & year >= 2014 | /// Minnesota -- January 1, 2014
	state_fips == 32 & year >= 2014 | /// Nevada -- January 1, 2014
	state_fips == 34 & year >= 2014 | /// New Jersey -- January 1, 2014
	state_fips == 35 & year >= 2014 | /// New Mexico -- January 1, 2014
	state_fips == 36 & year >= 2014 | /// New York -- January 1, 2014
	state_fips == 38 & year >= 2014 | /// North Dakota -- January 1, 2014
	state_fips == 39 & year >= 2014 | /// Ohio -- January 1, 2014
	state_fips == 41 & year >= 2014 | /// Oregon -- January 1, 2014
	state_fips == 44 & year >= 2014 | /// Rhode Island -- January 1, 2014
	state_fips == 50 & year >= 2014 | /// Vermont -- January 1, 2014
	state_fips == 53 & year >= 2014 | /// Washington -- January 1, 2014
	state_fips == 54 & year >= 2014 | /// West Virginia -- January 1, 2014
	state_fips == 26 & year >= 2014 | /// Michigan -- April 1, 2014
	state_fips == 33 & year >= 2015 | /// New Hampshire -- August 15, 2014
	state_fips == 42 & year >= 2015 | /// Pennsylvania -- January 1, 2015
	state_fips == 18 & year >= 2015 | /// Indiana -- February 1, 2015
	state_fips ==  2 & year >= 2016 | /// Alaska -- September 1, 2015
	state_fips == 30 & year >= 2016 | /// Montana -- January 1, 2016
	state_fips == 22 & year >= 2016 | /// Louisiana -- July 1, 2016
	state_fips == 51 & year >= 2019 | /// Virginia -- January 1, 2019
	state_fips == 23 & year >= 2019 | /// Maine -- January 10, 2019
	state_fips == 16 & year >= 2020 | /// Idaho -- January 1, 2020
	state_fips == 49 & year >= 2020 | /// Utah -- January 1, 2020
	state_fips == 31 & year >= 2021 | /// Nebraska -- October 1, 2020
	state_fips == 40 & year >= 2021 | /// Oklahoma -- July 1, 2021
	state_fips == 29 & year >= 2022 | /// Missouri -- October 1, 2021
	state_fips == 46 & year >= 2023 | /// South Dakota -- July 1, 2023
	state_fips == 37 & year >= 2024   //  North Carolina -- December 1, 2023

* Label variables:
label variable fg_sel1_total_payments "Tot. Payments: FG Code Selection (USD 1,000)"
label variable fg_sel2_total_payments "Tot. Payments: Excl. Drugs (USD 1,000)"
label variable fg_sel3_total_payments "Tot. Payments: FG Code Selection & Excl. Drugs (USD 1,000)"
label variable fg_sel4_total_payments "Tot. Payments: FG Code Selection & Excl. Drugs v2 (USD 1,000)"
label variable fg_sel5_total_payments "Tot. Payments: EM Codes (USD 1,000)"

g       fg_sel6_total_payments = fg_sel5_total_payments
replace fg_sel6_total_payments = 0 if fg_sel6_total_payments == .

label variable fg_sel6_total_payments "Tot. Payments: EM Codes with Missings Replaced (USD 1,000)"

label variable pp_quotient "PP: % Brand Claim Count (Quotient)"
label variable pp_payment  "PP: Payment (Dummy)"

label variable tuition_bill "Tot. Four-Year Tuition (USD)"

* Inflation adjustment for payments:

* CPI: (source https://www.bls.gov/cpi/tables/supplemental-files/historical-cpi-u-201811.pdf)
g       cpi = .
replace cpi = 138.1   if year == 1992
replace cpi = 142.6   if year == 1993
replace cpi = 146.2   if year == 1994
replace cpi = 150.3   if year == 1995
replace cpi = 154.4   if year == 1996
replace cpi = 159.1   if year == 1997
replace cpi = 161.6   if year == 1998
replace cpi = 164.3   if year == 1999
replace cpi = 168.8   if year == 2000
replace cpi = 175.1   if year == 2001
replace cpi = 177.1   if year == 2002
replace cpi = 181.7   if year == 2003
replace cpi = 185.2   if year == 2004
replace cpi = 190.7   if year == 2005
replace cpi = 198.3   if year == 2006
replace cpi = 202.4   if year == 2007
replace cpi = 211.1   if year == 2008
replace cpi = 211.143 if year == 2009
replace cpi = 216.687 if year == 2010
replace cpi = 220.223 if year == 2011
replace cpi = 226.655 if year == 2012
replace cpi = 230.280 if year == 2013
replace cpi = 233.916 if year == 2014 // everything as of 2014 dollars
replace cpi = 233.707 if year == 2015
replace cpi = 233.916 if year == 2016
replace cpi = 242.839 if year == 2017
replace cpi = 250.089 if year == 2018 // approximate, fix this!
replace cpi = 254.412 if year == 2019 // approximate, fix this!

g cpi_index = cpi / 233.916

foreach var of global payment_vars {
	
	replace `var'_total_payments = `var'_total_payments / cpi_index
	replace `var'_total_payments = 0 if `var'_total_payments == . & year >= 2012
	
}

drop cpi cpi_index

save "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", replace
