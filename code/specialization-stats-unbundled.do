* histogram of top 15 specializations + other

use "$working_data/cms_aamc_cohort_id", clear

egen phySpec_ct = count(phySpec), by(phySpec)
assert phySpec_id != .
drop if phySpec_id == .

g phySpec_pct = (phySpec_ct / _N) * 100

br * if phySpec == "INTERNAL MEDICINE"
br *

g phySpec_top = phySpec if phySpec_pct > 2.0

replace phySpec_top = "OTHER" if phySpec_top == ""

encode phySpec_top, g(phySpec_top_id)

contract phySpec_top_id, freq(count)

graph hbar count, over(phySpec_top_id, sort(1) descending) ytitle("Doctor-Year Observations") 

graph export "$figures/top_specialization_freq_unbundled.png", replace


* number of doctors per specialization *
use "$working_data/cms_aamc_cohort_id", clear

drop if phySpec == "" // 1 doctor

egen tag = tag(npi phySpec)

collapse (sum) tag (count) year (first) phySpec, by(npi)

label variable tag "Unique Doctor-Specialization"

tab tag, collect

collect export "$tables/spec_per_doc.tex", replace

* frequency of specializations appearing in data *
use "$working_data/cms_aamc_cohort_id", clear

drop if phySpec == "" // 1 doctor

egen tag = tag(npi phySpec)

collapse (sum) tag, by(npi phySpec)

bys npi : g spec_tag = _N // doc-specialization level data

bys phySpec : g no_spec = _N

g phySpec_top = phySpec if no_spec > 2700 // top 20 (83.48%) of specializations by no of docs

replace phySpec_top = "OTHER" if phySpec_top == ""

encode phySpec_top, g(phySpec_top_id)

quietly sum npi

local ndocspec "`r(N)'"

contract phySpec_top_id, p(pct)

graph hbar pct, over(phySpec_top_id, sort(1) descending) ytitle("% of Doctor-Specialization Observations") note("Sample of all doctors with CMS payment data." "Number of doctor-specializations in sample: `ndocspec'")

graph export "$figures/top_specialization_docspec_pct_unbundled.png", replace


* number of doctor-years with more than one specialization *

use "$working_data/cms_aamc_cohort_id", clear

drop if phySpec == "" // 1 doctor

egen tag = tag(npi year phySpec) // all of these are unique


* doctors that change careers *

use "$working_data/cms_aamc_cohort_id", clear

drop if phySpec == "" // 1 doctor

egen tag = tag(npi phySpec)

collapse (sum) tag (count) year, by(npi phySpec)

bys npi : egen total_years = sum(year)

duplicates tag npi, g(metatag)
replace metatag = metatag + 1

label variable metatag "Number of Unique Specializations per Doctor"
drop tag

rename metatag No_PhySpec

rename year No_Year_PhySpec

save "$working_data/number_doc_spec", replace

use "$working_data/cms_aamc_cohort_id", clear

drop if phySpec == "" // 1 doctor

merge m:1 npi phySpec using "$working_data/number_doc_spec.dta"

drop _merge

bys No_PhySpec: sum No_Year_PhySpec, d

preserve

keep if No_PhySpec == 2
// some of these switches are from FAMILY PRACTICE to FAMILY MEDICINE in 2019

by npi: gen physpec_change = (phySpec != phySpec[_n-1]) if _n > 1
by npi: replace physpec_change = 1 if _n == 1
by npi: gen physpec_spell = sum(physpec_change)
by npi: egen max_spec_switch = max(physpec_spell)
tab max_spec_switch


* doctors with more than one specialization *

use "$working_data/cms_aamc_cohort_id", clear

drop if phySpec == "" // 1 doctor

egen tag = tag(npi phySpec)

collapse (sum) tag (count) year (first) phySpec, by(npi)

* switching specialization *
use "$working_data/cms_aamc_cohort_id", clear

drop if phySpec == "" // 1 doctor

egen tag = tag(npi phySpec)

collapse (sum) tag (count) year (min) first_year=year, by(npi phySpec)

rename year years_reported

bys npi : g no_spec = _N

keep if no_spec == 2

sort npi first_year

bys npi : g first_career = (_n == 1)

bys first_career : sum years_reported, d

// do certain careers change in 2019? Yes, Family Medicine
g change_2019 = (first_career == 0 & first_year == 2019)

tab phySpec if change_2019 == 1, sort

// creating an npi level dataset
sort npi first_year

bys npi : g first_spec = phySpec[1]

bys npi : g second_spec = phySpec[2]

bys npi : g first_career_year = first_year[1]

bys npi : g second_career_year = first_year[2]

bys npi : g first_career_no_years_reported = years_reported[1]

bys npi : g second_career_no_years_reported = years_reported[2]

collapse (first) first_* second_* no_spec, by(npi)

* are all of the transitions between FP and FM in 2019? *

g fp_to_fm = (first_spec == "FAMILY PRACTICE" & second_spec == "FAMILY MEDICINE")

g fp_to_fm_2019 = (fp_to_fm == 1 & second_career_year == 2019)

tab fp_to_fm_2019 if fp_to_fm == 1 // 100% --> yes, all are in 2019

* What are the most frequent specialty combinations? *
preserve

contract first_spec second_spec, freq(n) percent(pct)

gsort -pct

list in 1/20

restore


* For doctors with multiple specializations, what ar the most common first specialization choices and final specialization choices? *

use "$working_data/cms_aamc_cohort_id", clear

drop if phySpec == "" // 1 doctor

egen tag = tag(npi phySpec)

collapse (sum) tag (count) year (min) first_year=year, by(npi phySpec)

rename year years_reported

bys npi : g no_spec = _N

keep if no_spec > 1

// creating npi level dataset
sort npi first_year

bys npi : g first_spec = phySpec[1]

bys npi : g final_spec = phySpec[_N]

collapse (first) first_* final_* no_spec, by(npi)


bys first_spec : g no_first_spec = _N

bys final_spec : g no_final_spec = _N

tab first_spec, sort

g first_spec_top = first_spec if no_first_spec > 310 // top 10 (88.41%) of first specializations by docs with multiple specs

replace first_spec_top = "OTHER" if first_spec_top == ""

tab final_spec, sort

g final_spec_top = final_spec if no_final_spec > 324 // top 10 (79.51%) of most recent specializations by docs with multiple specs

replace final_spec_top = "OTHER" if final_spec_top == ""

encode final_spec_top, g(final_spec_top_id)

encode first_spec_top, g(first_spec_top_id)

quietly sum npi

local ndocspec "`r(N)'"

graph hbar (percent), over(first_spec_top_id, sort(1) descending) ytitle("% of Doctor Observations, First Reported Specialization") note("Sample of all doctors that report more than one specialization." "Number of doctors in sample: `ndocspec'")

graph export "$figures/first_specialization_pct_unbundled.png", replace


graph hbar (percent), over(final_spec_top_id, sort(1) descending) ytitle("% of Doctor Observations, Last Reported Specialization") note("Sample of all doctors that report more than one specialization." "Number of doctors in sample: `ndocspec'")

graph export "$figures/final_specialization_pct_unbundled.png", replace




