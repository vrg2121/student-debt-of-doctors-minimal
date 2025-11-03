
*********************************************
*** MERGE TUITION PANEL INTO DOCTOR PANEL ***
*********************************************

*** CROSSWALK: zip5-hrr ***

// use "$dropbox/FullData/zip_hrr", clear
//
// bys zip5 : assert _N == 1 // uniqueness
//
// destring zip5, replace
//
// bys zip5 : assert _N == 1 // uniqueness remains
//
// save "$temp/destringed-zip5-hrr", replace


*** CMS ***

// use "$dropbox/FullDataCMSPANEL_final.dta", clear
//
// * VERY UGLY, BUT FOR NOW -- REMOVE THIS TO REPRODUCE EMIEL:
// // 	rename gradYear foo
// // 	rename grd_yr gradYear
// // 	rename foo grd_yr
//
// // assert grd_yr == gradYear // false, why?
//
// * Keep only important variables for now (code becomes slow otherwise):
// keep npi year med_sch grd_yr gradYear total_payments servicesEM pri_spec zip5 state_abrvtn state_fips
//
// // drop if grd_yr   == .
//    drop if gradYear == .
//
// // bys npi : g subsample = runiform() < 0.50 if _n == 1
// //
// // by  npi : replace subsample = subsample[1]
// //
// // keep if subsample == 1
// //
// // drop subsample
//
// * Check so var is unique within npi:
// foreach var in pri_spec { // zip5
//	
// 	bys npi (`var') : assert `var'[1] == `var'[_N]
//	 
// }
//
// * Merge on HRR (code for geographies):
// merge m:1 zip5 using "$temp/destringed-zip5-hrr"
// drop if _merge == 2
// drop _merge
//
// bys npi year : assert _N == 1
//
// replace year = year + 2000
//
// save "$git/data/working/FullDataCMSPANEL_final_subsample", replace


*** PROPUBLICA ***

// * Key, physician id -- npi:
// import delimited ///
// 	"$dropbox/ProRepublica/20191003-docdollars-physician_npi_crosswalk/P062819-20190912T1756-pid-npi-crosswalk 2.csv", ///
// 	clear
//	
// * False in small number of cases:
// // bys npi                  : assert _N == 1
// // bys physician_profile_id : assert _N == 1
//	
// bys npi 				 : keep if _n == 1
// bys physician_profile_id : keep if _n == 1	
//
// save "$temp/propublica-npi-pid", replace
//
// import delimited "$dropbox/ProRepublica/20180702b-docdollars-payments.csv", clear colrange(32:32)
//
// g double row = _n
//
// save "$temp/propublica-docdollars-total-amount-temp", replace
//
// import delimited "$dropbox/ProRepublica/20180702b-docdollars-payments.csv", clear colrange(59:59)
//
// g double row = _n
//
// save "$temp/propublica-docdollars-year-temp", replace
//
// import delimited "$dropbox/ProRepublica/20180702b-docdollars-payments.csv", clear colrange(7:7)
//
// g double row = _n
//
// merge 1:1 row using "$temp/propublica-docdollars-total-amount-temp"
// assert _merge == 3
// drop _merge
//
// merge 1:1 row using "$temp/propublica-docdollars-year-temp"
// assert _merge == 3
// drop _merge
//
// drop row
//
// merge m:1 physician_profile_id using "$temp/propublica-npi-pid"
// keep if _merge == 3
// drop _merge
//
// drop physician_profile_id
//
// rename program_year year
//
// collapse (sum) total_amount_of_payment_usdollar, by(npi year)
//
// save "$temp/propublica-docdollars-total-amount", replace
//
// * Brand claims and beneficiaries:
// forvalues n = 2013/2016 {
//
// 	cap import delimited ///
// 		"$dropbox/ProRepublica/rx-checkup-`n'/DOC_SUM_`n'.csv", ///
// 		clear
//		
// 	cap import delimited ///
// 		"$dropbox/ProRepublica/rx-checkup-`n'/PartD_DOC_SUM_`n'.csv", ///
// 		clear
//
// 	cap import delimited ///
// 		"$dropbox/ProRepublica/PrescriberCheckup2016Data/DOC_SUM_`n'.csv", ///
// 		clear
//	
// 	confirm variable provider_`n'_id
//	
// 	keep provider_`n'_id brand_claim_count ben_count
//	
// 	rename provider_`n'_id npi
//	
// 	g year = `n'
//	
// 	cap append using "$temp/propublica-brand-claims-beneficiaries"
//	
// 	save "$temp/propublica-brand-claims-beneficiaries", replace
//	
// }	


*** COMBINE TUITION DATA/CMS/PROPUBLICA ***

use "$git/data/working/FullDataCMSPANEL_final_subsample", clear

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
bys npi : egen keep = max(tuition != .)

keep if keep == 1
drop    keep

* Merge on increase dummy (verify!):

rename grd_yr gradYear

merge m:1 med_school gradYear using "$temp/delta-tuition-dummy"
drop if _merge == 2
drop _merge

rename gradYear grd_yr

replace delta_tuition_dummy = delta_tuition_dummy == 1

* Merge on ProPublica:
merge 1:1 npi year using "$temp/propublica-docdollars-total-amount"
drop if _merge == 2
drop _merge

merge 1:1 npi year using "$temp/propublica-brand-claims-beneficiaries"
drop if _merge == 2
drop _merge

g start_yr = grd_yr - 3 // medical school is four years:

* 2003-2004 = grd_yr = 4th yr ->
* 2002-2003 = 3rd yr ->
* 2001-2002 = 2nd yr ->
* 2000-2001 = 1st yr

sort  npi year our_med_school grd_yr
order npi year our_med_school grd_yr start_yr, first

* E.g. max_tuition_increase == 2002 and start_yr == 2002 -> increase in 1st yr:
// g 		grade = max_tuition_increase - start_yr + 1 // first, second year etc:
// replace grade = . if !inrange(grade, 1, 4)	        // again: medical school is four years

// drop if grade == .

* Handle missing values:

assert  pri_spec != "MISSING"
replace pri_spec  = "MISSING" if pri_spec == ""

assert  hrr != 0
replace hrr  = 0 if hrr == .

g pp_quotient = brand_claim_count / ben_count

replace pp_quotient = 0 if brand_claim_count == .

* Create dummy for brand_claim_count

g payment_dummy = ///
	total_amount_of_payment_usdollar >  0 & ///
	total_amount_of_payment_usdollar != .

save "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", replace
