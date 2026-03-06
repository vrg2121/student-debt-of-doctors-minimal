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