
************************************************
*** CREATE YEARLY DOCTOR ProPublica OUTCOMES ***
************************************************

* Description of this do-file:

* 	Calculates different yearly ProPublica outcomes

************************************************
************************************************
************************************************



****************************
*** TOTAL AMOUNT DOLLARS ***
****************************

* Key, physician id -- npi:
import delimited ///
	"$dropbox/ProRepublica/20191003-docdollars-physician_npi_crosswalk/P062819-20190912T1756-pid-npi-crosswalk 2.csv", ///
	clear
	
* False in small number of cases:
// bys npi                  : assert _N == 1
// bys physician_profile_id : assert _N == 1
	
bys npi 				 : keep if _n == 1
bys physician_profile_id : keep if _n == 1	

save "$temp/propublica-npi-pid", replace

import delimited "$dropbox/ProRepublica/20180702b-docdollars-payments.csv", clear colrange(32:32)

g double row = _n

save "$temp/propublica-docdollars-total-amount-temp", replace

import delimited "$dropbox/ProRepublica/20180702b-docdollars-payments.csv", clear colrange(59:59)

g double row = _n

save "$temp/propublica-docdollars-year-temp", replace

import delimited "$dropbox/ProRepublica/20180702b-docdollars-payments.csv", clear colrange(7:7)

g double row = _n

merge 1:1 row using "$temp/propublica-docdollars-total-amount-temp"
assert _merge == 3
drop _merge

merge 1:1 row using "$temp/propublica-docdollars-year-temp"
assert _merge == 3
drop _merge

drop row

merge m:1 physician_profile_id using "$temp/propublica-npi-pid"
keep if _merge == 3
drop _merge

drop physician_profile_id

rename program_year year

collapse (sum) total_amount_of_payment_usdollar, by(npi year)

save "$temp/propublica-docdollars-total-amount", replace


**************************************
*** BRAND CLAIMS AND BENEFICIARIES ***
**************************************

cap erase "$temp/propublica-brand-claims-beneficiaries.dta"
forvalues n = 2013/2016 {

	cap import delimited ///
		"$dropbox/ProRepublica/rx-checkup-`n'/DOC_SUM_`n'.csv", ///
		clear
		
	cap import delimited ///
		"$dropbox/ProRepublica/rx-checkup-`n'/PartD_DOC_SUM_`n'.csv", ///
		clear

	cap import delimited ///
		"$dropbox/ProRepublica/PrescriberCheckup2016Data/DOC_SUM_`n'.csv", ///
		clear
	
	confirm variable provider_`n'_id
	
	local keep ///
		provider_`n'_id       ///
		brand_claim_count     /// 2013-2016
		claim_count           /// 2013-2016
		ben_count             /// 2013-2016
		p_brand               /// 2013-2016
		ben_65                /// 2013-2016
		opioid_bene_count     /// 2014-2016
		p_opioid_benes        /// 2014-2016
		antibiotic_bene_count /// 2014-2016
		p_antibiotic_benes    /// 2014-2016
		beers_claims_65       /// 2014-2014
		p_beers_claims        /// 2014-2014
		beers_benes_65        /// 2015-2015
		p_beers_benes         /// 2015-2015
		antipsych_bene_count  /// 2015-2016
		p_antipsych_benes     //  2015-2016
		

	* Create an empty local for existing vars:
	local keeplist

	* Check each candidate var:
	foreach v of local keep {
		
		cap confirm var `v'
		
		if !_rc {
			local keeplist `keeplist' `v'
		}
		
	}

	* Keep only those that exist:
	keep `keeplist'
	
	rename provider_`n'_id npi
	
	g year = `n'
	
	cap append using "$temp/propublica-brand-claims-beneficiaries"
	
	save "$temp/propublica-brand-claims-beneficiaries", replace
	
}
