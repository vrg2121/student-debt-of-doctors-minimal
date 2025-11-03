
**********************************************
*** MERGE IN TREATMENT GROUPS TO CMS PANEL ***
**********************************************

* Description of this do-file:

* 	Merges in grade (aka treatment group) to the doctor panel
* 	Create variables for which observations should be included in IV regressions for each outcome
* 	Creates the main sample (aka the sample of analysis)

**********************************************
**********************************************
**********************************************



*********************************
*** MERGE IN TREATMENT GROUPS ***
*********************************

use "$temp/cms-panel", clear

merge m:1 med_school grad_year using "$temp/treatment-data"
keep if _merge == 3
drop _merge

* Nice behavior:
assert increase_aca_year + years_treated == grad_year

* Fixing school FE:
g orig_med_school = med_school // copy

assert grade != .
replace med_school = med_school + " CONTROL" if ///
	grade < 2 | 5 < grade

*** TO PUT INCREASE YEARS TOGETHER ***

* IMPORTANT --- Defining sample variables for CMS:
foreach outcome of global outcomes {
	if substr("`outcome'", 1, 2) != "pp" {
		g sample_`outcome' = ///
			increase_aca_year + 3 + event_time <= 2019 & ///
			increase_aca_year + 0 + event_time >= 2012
	}
}

* Defining sample variables for ProPublica (varying time availability etc):
sum increase_aca_year
local start_yr = r(min)
local end_yr   = r(max)

foreach outcome of global outcomes {
	if substr("`outcome'", 1, 2) == "pp" {
		disp "Variable: `outcome'"
		g sample_`outcome' = 0
		forvalues n = `start_yr'/`end_yr' { // increase_aca_year
			disp "Academic increase year: `n'"
			forvalues et = `=2012-`n''/`=2019-`n'-3' { // event_time
				forvalues yt = 0(3)3 { // years_treated
					count if ///
						`outcome'         != .    & ///
						increase_aca_year == `n'  & ///
						event_time        == `et' & ///
						years_treated     == `yt'
					local c_`yt' = r(N)
				}
				if (`c_0' > 0 & `c_3' > 0) {
					replace sample_`outcome' = 1 if ///
						increase_aca_year == `n'  & ///
						event_time        == `et'
						
				}
			}
		}
	}
}

sort npi year

label var years_treated "Years Treated"

label define years_treated_label ///
	0 "Control Group" ///
	1 "1 Year Treated" ///
	2 "2 Years Treated" ///
	3 "3 Years Treated"
	
label values years_treated years_treated_label

sum grade
forvalues n = 0/`r(max)' {
	g grade_`n' = grade == `n'
}

sum years_treated
forvalues n = 0/`r(max)' {
	
	g years_treated_`n' = years_treated == `n'
	
	label var years_treated_`n' "`n' Years Treated"

	label define years_treated_label_`n' ///
		1 "`n' Year Treated"
		
	label values years_treated_`n' years_treated_label_`n'
	
}


save "$temp/cms-panel-with-treatment", replace


******************************************
*** MAIN SAMPLE aka SAMPLE OF ANALYSIS ***
******************************************

use "$temp/cms-panel-with-treatment", clear

// tab years_treated, m
//
// * Example of bad behavior:
// tab event_time years_treated if ///
// 	increase_aca_year == 2011 & ///
// 	inrange(years_treated, -1, 4), m
//
// * Example of good behavior:
// tab event_time years_treated if ///
// 	increase_aca_year == 2011 & ///
// 	inrange(years_treated, -1, 4) & ///
// 	sample_fg_sel3_total_payments == 1, m

keep if sample_fg_sel3_total_payments == 1

* Scaling both has no effect:
// replace fg_sel3_total_payments = 1000 * fg_sel3_total_payments
// replace tuition_bill           = 1000 * tuition_bill

ivreghdfe ///
	fg_sel3_total_payments ///
	(tuition_bill = $years_treated) $controls, /// controls here?
	cl(orig_med_school) absorb(med_school grad_year phySpec groupPAC)

keep if e(sample) == 1

preserve

keep npi year

bys npi year : assert _N == 1

save "$temp/main-sample-npi-year", replace

restore

preserve

keep shock_id

duplicates drop

save "$temp/main-sample-shock_id", replace

restore
