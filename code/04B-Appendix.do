**# Test Cleaning for Grad Year and Med School
use "$working_data/temp/doc_characteristics_standardized", clear


** Make data unique at a doctor-our_med_school-grad_year level for cleaning
sort npi year // chronological order
duplicates drop npi our_med_school grad_year, force 							// 6,850,796 duplicate npi-our_med_school-grad_year

* Identify npi with more than one entry
duplicates tag npi, g(dup_npi) 													// 37.39% of the npi appear more than once
drop if dup_npi == 0															// drop npi that appear multiple times (vary by med school or grad year)
																				// 73,888 unique npi appear with unclear data

* Check to see how many different med schools / grad years each doc reported
egen tag_gy = tag(npi grad_year)
bys npi : egen gy_cnt = total(tag_gy) 											
egen tag_ms = tag(npi our_med_school)
bys npi : egen ms_cnt = total(tag_ms)																		

* Fill in missing grad year when reports are consistent
sort npi year
g filled_gy = grad_year if gy_cnt == 1										
sort npi filled_gy
bys npi (filled_gy) : replace filled_gy = filled_gy[1] if missing(filled_gy)
count if gy_cnt > 1 & filled_gy != . 											// 0 observations with more than one reported gy were filled

* Fill in med school when reports are consistent
bysort npi: egen filled_ms = mode(our_med_school) if ms_cnt == 1, minmode

* Find the doctors with contradictory med schools or grad years
keep if filled_gy == . | filled_ms == ""

rename our_med_school med_school
merge m:1 med_school using "$working_data/temp/full_aamc_schools"
bysort npi: egen aamc_ms = max(_merge == 3)
keep if aamc_ms == 1 // fix doctors with a med_school that appears in the aamc data
drop _merge

save "$working_data/temp/doc_characteristics_contradictory", replace
export delimited "$working_data/temp/doc_characteristics_contradictory.csv", replace

* Doctors with contradictory med schools
use "$working_data/temp/doc_characteristics_contradictory", clear
keep if filled_ms == ""

export delimited "$working_data/temp/doc_characteristics_contradictory_ms.csv", replace

** identify additional med school typos
bys npi: g obs = _n
keep npi year grad_year med_school obs
reshape wide year grad_year med_school, i(npi) j(obs)
rename (med_school1 med_school2 med_school3 med_school4 med_school5) (ms1 ms2 ms3 ms4 ms5)


python :

from sfi import Data
from difflib import SequenceMatcher
import itertools
import pandas as pd
import numpy as np

dataraw = Data.getAsDict()
df = pd.DataFrame(dataraw)

# Compare across med schoool columns
cols = ['ms1', 'ms2', 'ms3', 'ms4', 'ms5']
for c in cols:
	df[c] = df[c].replace(r'^\s*$', np.nan, regex=True)

def similar(a, b):
    if pd.isna(a) | pd.isna(b):
        return None
    return SequenceMatcher(None, a, b).ratio()

# calculate comparisons
for m1, m2 in itertools.combinations(cols, 2):
	ms_comp = f'{m1}_vs_{m2}'
	df[ms_comp] = df.apply(lambda row : similar(row[m1], row[m2]), axis=1)
	Data.addVarFloat(ms_comp)
	Data.store(ms_comp, None, df[ms_comp], None)
	

end

export delimited "$working_data/temp/doc_characteristics_contradictory_ms_wide.csv", replace


**# Med School Selection Methods
use "$working_data/temp/doc_characteristics_contradictory", clear
keep if filled_ms == ""

* First / Last Reported
bys npi : egen max_year = max(year) if med_school != ""
bys npi : egen min_year = min(year) if med_school != ""

g recent_ms = med_school if(year == max_year)
bysort npi (recent_ms): replace recent_ms = recent_ms[_N] if recent_ms == ""

g first_ms = med_school if (year == min_year)
bysort npi (first_ms): replace first_ms = first_ms[_N] if first_ms == ""


* Mode / First Reported
bys npi med_school : g freq = _N
replace freq = 0 if med_school == ""
gsort npi -freq year
bys npi: gen mode_ms = med_school[1]
label variable mode_ms "Mode / First Reported Med School"

drop freq

* First Complete Report
sort npi year
bysort npi: gen complete_ms = (grad_year != . & med_school != "")
bysort npi : gen n_complete_ms = sum(complete_ms)
g first_complete_ms = med_school if n_complete_ms == 1
gsort npi -first_complete_ms
bys npi : replace first_complete_ms = first_complete_ms[1]

preserve
bys npi : keep if _n == 1
drop if npi == 1215918826														// drop this npi when comparing the manual edits!

keep npi
set seed 1234
sample 30, count

g random_npi = 1

save "$working_data/temp/random_npi_ms", replace
restore

merge m:1 npi using "$working_data/temp/random_npi_ms", keep(match)
drop _merge complete_ms n_complete_ms
bys npi : keep if _n == 1
g manual_ms = ""
g source_ms = ""
g why_change_ms = ""

export delimited "$working_data/temp/doc_characteristics_contradictory_ms_manual_1-14.csv" in 1/14, replace
export delimited "$working_data/temp/doc_characteristics_contradictory_ms_manual_15-30.csv" in 15/30, replace


**# Med School Alg Selection
import delimited "$working_data/temp/doc_characteristics_contradictory_ms_manual_edited.csv", clear
drop if npi == 1215918826														

g correct_recent_ms = (recent_ms == manual_ms)
g correct_first_ms = (first_ms == manual_ms)
g correct_mode_ms = (mode_ms == manual_ms)
g correct_firstcomp_ms = (first_complete_ms == manual_ms)



**# Grad School Selection Methods
use "$working_data/temp/doc_characteristics_contradictory", clear
keep if filled_gy == .

* First / Last Reported
bys npi : egen max_year = max(year) if grad_year != .
bys npi : egen min_year = min(year) if grad_year != .

g recent_gy = grad_year if(year == max_year)
gsort npi -recent_gy
bysort npi : replace recent_gy = recent_gy[1] if recent_gy == .

g first_gy = grad_year if (year == min_year)
gsort npi -first_gy
bysort npi (first_gy): replace first_gy = first_gy[1] if first_gy == .


* Mode / First Reported
bys npi grad_year : g freq = _N
replace freq = 0 if grad_year == .
gsort npi -freq year
bys npi: gen mode_gy = grad_year[1]
label variable grad_year "Mode / First Reported Grad Year"

drop freq

* First Complete Report
sort npi year
bysort npi: gen complete = (grad_year != . & med_school != "")
bysort npi : gen n_complete = sum(complete)
g first_complete_gy = grad_year if n_complete == 1
gsort npi -first_complete_gy
bys npi : replace first_complete_gy = first_complete_gy[1]

preserve
bys npi : keep if _n == 1
drop if inlist(npi, 1598763286, 1861461733, 1841266707)


keep npi
set seed 123
sample 30, count

g random_npi = 1

save "$working_data/temp/random_npi_gy", replace
restore

merge m:1 npi using "$working_data/temp/random_npi_gy", keep(match)
drop _merge complete n_complete
bys npi : keep if _n == 1
g manual_gy = ""
g source_gy = ""
g why_change_gy = ""

export delimited "$working_data/temp/doc_characteristics_contradictory_gy_manual_1-14.csv" in 1/14, replace
export delimited "$working_data/temp/doc_characteristics_contradictory_gy_manual_15-30.csv" in 15/30, replace


**# Med School Alg Selection
import delimited "$working_data/temp/doc_characteristics_contradictory_gy_manual_edited.csv", clear
drop if insufficient_information == 1														

g correct_recent_gy = (recent_gy == manual_gy)
g correct_first_gy = (first_gy == manual_gy)
g correct_mode_gy = (mode_gy == manual_gy)
g correct_firstcomp_gy = (first_complete_gy == manual_gy)