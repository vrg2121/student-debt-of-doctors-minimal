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

graph export "$figures/top_specialization_freq.png", replace


* number of doctors per specialization *
use "$working_data/cms_aamc_cohort_id", clear

drop if phySpec == "" // 1 doctor

egen tag = tag(npi phySpec)

collapse (sum) tag (count) year, by(npi phySpec)

bys npi : egen total_years = sum(year)

duplicates tag npi, g(metatag)
replace metatag = metatag + 1

label variable metatag "Number of Unique Specializations per Doctor"

tab metatag, collect

collect export "$tables/spec_per_doc.tex", replace

drop if metatag > 1

egen phySpec_ct = count(phySpec), by(phySpec)
assert phySpec != ""

g phySpec_top = phySpec if phySpec_ct > 2500 // top 20 (83.47%) of specializations by no of docs

replace phySpec_top = "OTHER" if phySpec_top == ""

encode phySpec_top, g(phySpec_top_id)

quietly sum npi

local ndoc "`r(N)'"

contract phySpec_top_id, freq(count)

graph hbar count, over(phySpec_top_id, sort(1) descending) ytitle("Doctor Observations") note("Sample of doctors that report the same specialization for all years of CMS data." "Number of doctors in sample: `ndoc'")

graph export "$figures/top_specialization_totdoc_freq.png", replace


