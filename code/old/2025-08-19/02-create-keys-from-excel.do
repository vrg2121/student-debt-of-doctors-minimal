
****************************************************
*** CREATE KEYS BETWEEN OUR NAMES AND AAMC/IPEDS ***
****************************************************


* After exporting the unique name files in the previous do-file,
* we put the exports in sheets in $git/data/working/unique-names/matching-names.xlsx
* and match our names with AAMC/IPEDS names

* This matching was done both exactly (vlookup) and manually:
* 	– If no match found for our name, search manually in AAMC/IPEDS sheet and put result in cell
*	– Use Google to find if colleges have changed names etc to find potential matches etc
*	- ADDED: Use IPEDS online tool to search for institutions

* Question: an LLM could maybe do this manual matching faster and better?

* We now use matching-names.xlsx to produce nice keys between our names and AAMC/IPEDS:


*** AAMC & IPEDS ***

import excel "$git/data/working/unique-names/matching-names.xlsx", ///
	clear firstrow sheet(our_med_schools)
	
keep if ///
	exact_aamc  == 1 | manual_aamc  != "" | /// AAMC  matches
	exact_ipeds == 1 | manual_ipeds != .     // IPEDS matches

g aamc  = 1 if exact_aamc  == 1 | manual_aamc  != ""
g ipeds = 1 if exact_ipeds == 1 | manual_ipeds != .

assert !(aamc == 1 & ipeds == 1) // never both
assert   aamc == 1 | ipeds == 1  // always one

g       source = "aamc"  if aamc  == 1
replace source = "ipeds" if ipeds == 1

* Specializations:
g chiro_school = regexm(our_med_school, "chiro") // Chiropractic
g osteo_school = regexm(our_med_school, "osteo") // Osteopathic
g optom_school = regexm(our_med_school, "optom") // Optometry
g podia_school = regexm(our_med_school, "podia") // Podiatry

* Temp, fix this:
replace optom_school = 0 if our_med_school == "pennsylvania college of optometry"

* Generally: Think about specializations and med_school vs our_med_school?

g medic_school = 1

replace medic_school =  0 if ///
		chiro_school == 1 |  ///
		osteo_school == 1 |  ///
		optom_school == 1 |  ///
		podia_school == 1

keep our_med_school matched_name our_nr_obs source $specializations

rename matched_name med_school

* Key is unique in our school name:
bys our_med_school : assert _N == 1

* But not necessarily in med_school – several of our names can match to the same med_school name:
// bys med_school : assert _N == 1 // false!

order med_school our_med_school source our_nr_obs

save "$git/data/working/unique-names/keys/key-our-aamc", replace
use  "$git/data/working/unique-names/keys/key-our-aamc", clear

* Check so var is unique within med_school:
foreach var in source $specializations {
	
	bys med_school (`var') : assert `var'[1] == `var'[_N]
	 
}

* Good to have file with uniqueness of variables in med_school:
collapse (sum) our_nr_obs (first) source $specializations, by(med_school)

save "$git/data/working/unique-names/keys/aamc-schools-nr-obs", replace // change file name
