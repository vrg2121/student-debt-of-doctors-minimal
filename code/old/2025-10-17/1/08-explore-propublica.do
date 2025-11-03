
****************************
*** EXPLORING ProPublica ***
****************************

* Key, physician id -- npi:
import delimited ///
	"$propublica/20191003-docdollars-physician_npi_crosswalk/P062819-20190912T1756-pid-npi-crosswalk 2.csv", ///
	clear

* Summary data set, brand variables seem interesting:
import delimited "$propublica/PrescriberCheckup2016Data/DOC_SUM_2016.csv", clear

* Drug level:
import delimited "$propublica/PrescriberCheckup2016Data/DOC_DRUG_SUM_2016.csv", clear

* Type of drugs (opioid/antibiotic/...) etc:
import delimited "$propublica/PrescriberCheckup2016Data/BN_LOOKUP_2016.csv", clear

* Drugs "per state":
import delimited "$propublica/PrescriberCheckup2016Data/GRAND_TOTAL_COMBINED_2016.csv", clear

* Rankings per specialty/state:
import delimited "$propublica/PrescriberCheckup2016Data/STATE_TAXON_RANKS_2016.csv", clear


***************
*** TESTING ***
***************

* Key, physician id -- npi:
import delimited ///
	"$propublica/20191003-docdollars-physician_npi_crosswalk/P062819-20190912T1756-pid-npi-crosswalk 2.csv", ///
	clear
	
* False in small number of cases:
// bys npi                  : assert _N == 1
// bys physician_profile_id : assert _N == 1
	
bys npi 				 : keep if _n == 1
bys physician_profile_id : keep if _n == 1	

save "$temp/npi-pid", replace

* Total costs in 2016:
import delimited "$propublica/PrescriberCheckup2016Data/DOC_SUM_2016.csv", clear

keep provider_2016_id cost_sum* brand_claim_count p_brand

bys provider_2016_id : assert _N == 1

save "$temp/cost-2016-by-pid", replace

* Use our data and merge on:
use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

bys npi : keep if _n == 1

// merge 1:1 npi using "$temp/npi-pid"
// keep if _merge == 3
// drop _merge
//
// rename physician_profile_id provider_2016_id
//
// merge 1:1 provider_2016_id using "$temp/cost-2016-by-pid"

rename npi provider_2016_id

merge 1:1 provider_2016_id using "$temp/cost-2016-by-pid"
keep if _merge == 3

// drop if _merge == 2
// replace cost_sum = 0 if _merge == 1

drop _merge

egen mean_cost_sum = rowmean(cost_sum*)

graph bar (mean) ///
	p_brand, ///
	over(treatment)
		
