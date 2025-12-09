
*****************************************
*** MERGE IN OUTCOMES TO DOCTOR PANEL ***
*****************************************

* Description of this do-file:

* 	Merges in outcomes from CMS and ProPublica

* 	Merges in AAMC school name using the CMS-AAMC school name key, and then school-level variables
*		NOTE --- CURRENTLY USES OLD KEY!

* 	Labels variables and makes final selection of calendar years and doctor population (MDs)

*****************************************
*****************************************
*****************************************


* Read panel:
use "$working_data/temp/cms-panel-raw", clear


*** MERGE IN CMS PAYMENTS ***

* Merge in payments variable (already inflation adjusted):
merge 1:1 npi year using "$working_data/temp/emiel-total_payments-fg-hcpcs-codes"

* Doctors who never receive a payment:
bys npi (_merge) : g no_pay_ever = _merge[1] == 1 & _merge[_N] == 1

* Cleaning up:
drop if _merge == 2
drop    _merge

* Checking so our payment data is not for organisations:
assert ent_cd != "O"

* Replace missings with zeros based on payment data limits:
foreach var of global payment_vars {
	
	replace `var'_total_payments =  0 ///
		 if `var'_total_payments == . & inrange(year, 2012, 2019)
	
}

* Average evaluation and management codes (E/M) payments:
merge 1:1 npi year using "$working_data/temp/em-average-payments"
drop if _merge == 2
drop    _merge


*** MERGE IN CMS TOTAL NUMBER OF SERVICES AND UNIQUE SERVICES ***

merge 1:1 npi year using "$working_data/temp/nCodes-new"
drop if _merge == 2
drop    _merge

ds *nServ *nCode
foreach var in `r(varlist)' {
	replace `var' = 0 if `var' == . & inrange(year, 2012, 2019) // added!
}


*** MERGE IN ProPublica AND MODIFY SOME VARIABLES ***

merge 1:1 npi year using "$working_data/temp/propublica-docdollars-total-amount"
drop if _merge == 2
drop _merge

* Dummy for receiving kickback:
g       pp_payment =      total_amount_of_payment_usdollar >  0 if inrange(year, 2013, 2016)
replace pp_payment = 0 if total_amount_of_payment_usdollar == . &  inrange(year, 2013, 2016)

merge 1:1 npi year using "$working_data/temp/propublica-brand-claims-beneficiaries"
drop if _merge == 2
drop _merge

* Recall:
// 	brand_claim_count     /// 2013-2016
// 	claim_count           /// 2013-2016
// 	ben_count             /// 2013-2016
// 	p_brand               /// 2013-2016
// 	ben_65                /// 2013-2016
// 	opioid_bene_count     /// 2014-2016
// 	p_opioid_benes        /// 2014-2016
// 	antibiotic_bene_count /// 2014-2016
// 	p_antibiotic_benes    /// 2014-2016
// 	beers_claims_65       /// 2014-2014
// 	p_beers_claims        /// 2014-2014
// 	beers_benes_65        /// 2015-2015
// 	p_beers_benes         /// 2015-2015
// 	antipsych_bene_count  /// 2015-2016
// 	p_antipsych_benes     //  2015-2016

* Share of count that is from brand name drugs:
g       pp_brand_per_ben =      brand_claim_count / ben_count if inrange(year, 2013, 2016)
replace pp_brand_per_ben = 0 if brand_claim_count == . &         inrange(year, 2013, 2016)

rename p_brand     		  pp_p_brand
rename p_opioid_benes     pp_p_opioid_benes
rename p_antibiotic_benes pp_p_antibiotic_benes
rename p_antipsych_benes  pp_p_antipsych_benes
rename p_beers_claims	  pp_p_beers_claims
rename p_beers_benes 	  pp_p_beers_benes

   assert  pp_p_brand            == 0 if brand_claim_count     == 0
   replace pp_p_opioid_benes     =  0 if opioid_bene_count     == 0
   replace pp_p_antibiotic_benes =  0 if antibiotic_bene_count == 0
// replace pp_p_antipsych_benes  =  0 if antipsych_bene_count  == 0 // antipsych_bene_count?
   replace pp_p_beers_claims     =  0 if beers_claims_65       == 0
   replace pp_p_beers_benes      =  0 if beers_benes_65        == 0


*** MERGE IN HRR, AAMC SCHOOL NAME, AND SCHOOL-LEVEL INFO ***

* Checking behavior of zip:
assert substr("`: type zip'", 1, 3) == "str"
assert inlist(length(zip), 5, 9)

* Creating zip5:
g str5 zip5 = substr(zip, 1, 5)

* Merge in hrr:
merge m:1 zip5 using "$dropbox/FullData/zip_hrr"
drop if _merge == 2
drop    _merge

* REPLACE BELOW WITH NEW KEY WHEN FIXED!

* Merge in AAMC school name using the CMS-AAMC school name key:
merge m:1 our_med_school using "$working_data/temp/old-important-files/key-our-aamc", keepusing(med_school) // REPLACE!
drop if _merge == 2
drop _merge

* Merge in tuition etc:
g aca_year = grad_year - 1 // graduation year 2001 corresponds to academic year 2000-2001

merge m:1 med_school aca_year using "$working_data/temp/aamc-tuition", ///
	keepusing(PublicSchool *tuition_bill *_school source)
drop if _merge == 2
drop _merge

rename aca_year aca_grad_year


*** LABEL VARIABLES ***

label var fg_sel1_total_payments "Payments: FG Code Selection (USD 1,000)"
label var fg_sel2_total_payments "Payments: Excl. Drugs (USD 1,000)"
label var fg_sel3_total_payments "Payments (USD 1,000)" // FG Code Selection & Excl. Drugs, main outcome!
label var fg_sel4_total_payments "Payments: FG Code Selection & Excl. Drugs v2 (USD 1,000)"
label var fg_sel5_total_payments "Payments: EM Codes (USD 1,000)"

label var nServ         "Total Number of Services (NO SELECTION)"
label var fg_sel3_nServ "Total Number of Services" // FG Code Selection & Excl. Drugs, main outcome!
label var fg_sel5_nServ "Total Number of E/M Services"

label var nCode         "Number of Unique Codes (NO SELECTION)"
label var fg_sel3_nCode "Number of Unique Codes" // FG Code Selection & Excl. Drugs, main outcome!
label var fg_sel5_nCode "Number of Unique E/M Codes"

label var pp_payment            "PP: Kickback Payment (Dummy)"
label var pp_brand_per_ben      "PP: Brand Claims per Patient (#)"
label var pp_p_brand			"PP: Share of Claims: Brand Name Drugs"
label var pp_p_opioid_benes		"PP: Share of Patients: At Least One Opioid Prescription"
label var pp_p_antibiotic_benes "PP: Share of Patients: At Least One Antibiotic Prescription"
label var pp_p_antipsych_benes  "PP: Share of Patients: At Least One Antipsychotics Prescription"
label var pp_p_beers_claims		"PP: SOMETHING 65+ -- VERIFY!"
label var pp_p_beers_benes		"PP: Share of 65+ Patients: At Least One Risky Drug"

// label var event_time "Years Since Graduation"


*** FINAL SELECTIONS ***

* Wider range if outcome variables during longer time (both CMS and ProPublica outcomes belong to this window currently):
keep if inrange(year, 2012, 2019)

* Only keep MDs (should guarantee four years of medical school):
keep if isMD == 1

sort npi year

save "$working_data/panels/cms-panel", replace
