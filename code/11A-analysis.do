
**************
*** TABLES ***
**************

* Description of this do-file:

* 	Creates tables for Overleaf
*	https://www.overleaf.com/project/686ce654c75b2401fd5b530e

**************
**************
**************



* VERY UGLY, FIX! *

*** list-of-schools ***

// import excel "$git/data/original/aamc/excels/modified/aamc-med-schools.xlsx", clear firstrow

// rename aamc_med_school formatted_med_school

use "$temp/full-aamc-tuition", clear

keep formatted_med_school

bys formatted_med_school : keep if _n == 1 // aka duplicates drop

g orig_med_school = lower(formatted_med_school)

save "$temp/aamc-med-schools-lower", replace

import delimited "$git/data/original/ipeds/ipeds-2012.csv", clear

rename institutionname formatted_med_school

keep formatted_med_school unitid

bys formatted_med_school : keep if _n == 1 // aka duplicates drop

rename unitid orig_med_school

tostring orig_med_school, replace

save "$temp/ipeds-med-schools-lower", replace

clear
append using "$temp/aamc-med-schools-lower"
append using "$temp/ipeds-med-schools-lower"

bys       formatted_med_school : assert _N == 1
bys            orig_med_school : assert _N == 1
   
save "$temp/med-schools-lower", replace

use "$temp/cms-panel-with-treatment", clear

merge 1:1 npi year using "$temp/main-sample-npi-year"
keep if _merge == 3
drop    _merge

bys npi (year) : keep if _n == 1

merge m:1 orig_med_school using "$temp/med-schools-lower"
drop if _merge == 2
drop    _merge

tab our_med_school if formatted_med_school == "", m

replace formatted_med_school = "Chicago College of Osteopathic Medicine" ///
	if our_med_school == "midwestern university, chicago college of osteopathic med"

replace formatted_med_school = "National University of Health Sciences" ///
	if our_med_school == "national college of chiropractic"
	
replace formatted_med_school = "A.T. Still University, Kirksville College of Osteopathic Medicine" ///
	if our_med_school == "at still university of health sciences, college of osteo med, kirksville"
	
replace formatted_med_school = "Philadelphia College of Osteopathic Medicine" ///
	if our_med_school == "philadelphia college of osteopathic medicine"
	
replace formatted_med_school = "West Virginia School of Osteopathic Medicine" ///
	if our_med_school == "west virginia school of osteopathic medicine"
	
g n = 1

bys formatted_med_school (source) : assert source[1] == source[_N]

replace formatted_med_school = ///
	subinstr(formatted_med_school, "&","\&", .)

collapse (sum) n (first) source, by(formatted_med_school)

gsort -n formatted_med_school

egen total = total(n)

g perc = 100 * n / total

g cperc = sum(perc)

replace  perc = round( perc, 0.01)
replace cperc = round(cperc, 0.01)

g rank = _n

order rank, first

drop total

replace source = upper(source)

assert _N <= 61 // for start and end below

forvalues n = 1/3 {
	
	if `n' == 1 {
		local start =  1
		local   end = 20
		
	}

	else if `n' == 2 {
		local start = 21
		local   end = 40
	}
	
	else if `n' == 3 {
		local start = 41
		local   end = 61
	}
	
	* Step 1: Create the LaTeX file
	file open myfile using "$git/tables/top-schools-`n'.tex", write replace

	* Step 2: Write the table header (booktabs style)
	file write myfile "\begin{tabular}{r p{0.45\textwidth} l r r r}" _n
	file write myfile "\toprule" _n
	file write myfile "Rank & School & Source & Frequency & Percent & Cumulative \\ \midrule" _n

	* Step 3: Loop through your data and write each row
	forvalues i = `start'/`end' {
		local r      = string(rank[`i'], "%2.0f")  // Rank as integer
		local school = formatted_med_school[`i']   // String
		local source = source[`i']                 // String
		local nval   = string(n[`i'], "%9.0fc")    // Frequency with comma
		local pval   = string(perc[`i'], "%5.2f")  // Percent with 2 decimals
		local cval   = string(cperc[`i'], "%5.2f") // Cumulative percent 2 decimals
		
		file write myfile "`r' & `school' & `source' & `nval' & `pval' & `cval' \\\\" _n
	}

	* Step 4: Close the table
	file write myfile "\bottomrule" _n
	file write myfile "\end{tabular}" _n
	file close myfile
	
}

*** sum-stats-schools ***

use "$temp/all-tuition-shocks", clear

rename aca_year increase_aca_year

merge 1:1 shock_id using "$temp/main-sample-shock_id"
assert       _merge != 2
g in_panel = _merge == 3
drop         _merge

sum increase_aca_year if in_panel == 1
local min = r(min)
local max = r(max)

keep if inrange(increase_aca_year, `min', `max')

global cells_schools = ///
	"mean(fmt(%9.2fc)) sd(fmt(%9.2fc)) p50(fmt(%9.2fc)) min(fmt(%9.2fc)) max(fmt(%9.2fc)) count(fmt(%9.0fc))"

forvalues m = 1/2 {

	preserve

	if (`m' == 2) {
		keep if in_panel == 1
	}
	
	eststo clear

	estpost summarize tuition_bill PublicSchool, d /// nr graduates

	esttab using "$git/tables/sum-stats-schools-`m'.tex", ///
		cells("$cells_schools") ///
		collabels("Mean" "SD" "Median" "Min" "Max" "N") ///
		label noobs nonumber nomtitles replace
		
	restore

}


*** sum-stats-doctors ***

use "$temp/cms-panel", clear

merge 1:1 npi year using "$temp/main-sample-npi-year"
assert       _merge != 2
g in_panel = _merge == 3
drop         _merge

sum grad_year if in_panel == 1
local min = r(min)
local max = r(max)

keep if inrange(grad_year, `min', `max') // think about this!

global cells_doctors = ///
	"mean(fmt(%9.2fc)) sd(fmt(%9.2fc)) p50(fmt(%9.2fc)) min(fmt(%9.2fc)) max(fmt(%9.2fc)) count(fmt(%9.0fc))"

forvalues m = 1/2 {

	preserve

	if (`m' == 2) {
		keep if in_panel == 1
	}
	
	eststo clear

	estpost summarize event_time $iv_outcomes, d // nr of doctors?

	esttab using "$git/tables/sum-stats-doctors-`m'.tex", ///
		cells("$cells_doctors") ///
		collabels("Mean" "SD" "Median" "Min" "Max" "N") ///
		label noobs nonumber nomtitles replace
		
	restore

}


*** iv-regressions ***

use "$temp/cms-panel-with-treatment", clear

label var tuition_bill "Tuition bill"

// tab years_treated delta_tuition_dummy, m

// foreach instrument in years_treated /* delta_tuition_dummy */ {

	foreach outcome of global iv_outcomes {
		
		forvalues drop = 0/0 { // 0/1
		
			preserve
			
			if `drop' == 1 {
				drop if no_pay_ever == 1
			}
				
			keep if sample_`outcome' == 1
			
			count
			if r(N) == 0 {
				restore
				continue
			}

			disp ""
			disp "Outcome = `: variable label `outcome''"
			disp ""

			eststo clear

			foreach FE of global FEs {

				qui : eststo : ivreghdfe ///
					`outcome' ///
					(tuition_bill = $years_treated) $controls, /// controls here?
					cl(orig_med_school) absorb(`FE')
					
				* Mean:
				sum `outcome' if e(sample) == 1
				
				estadd r(mean)
				
				scalar pct_mean = 100 * _b[tuition_bill] / r(mean)
				
				estadd scalar pct_mean
				
				* Unique doctors:
				unique npi if e(sample) == 1
				
				estadd scalar unique_drs = r(unique)
				
				* Unique schools:
// 				unique orig_med_school if e(sample) == 1
//				
// 				estadd scalar unique_schools = r(unique)

			}

// 			disp ""
// 			disp "Drop (yes = 1): `drop'"
// 			disp "Instrument: `instrument'"
// 			disp "Outcome = `: variable label `outcome''"
// 			disp "Explained by = `: variable label tuition_bill'"
			
			esttab est*, ///
				keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
			
			estfe est*, labels(                 /// ssc install erepost
				med_school "School FE"          ///
				grad_year  "Graduation Year FE" ///
				phySpec    "Specialization FE"  ///
				hrr        "HRR FE"             ///
				groupPAC   "Group FE")
				
			esttab est* using "$git/tables/iv-regs-`outcome'-`drop'.tex", ///
				keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
				indicate(`r(indicate_fe)') nomtitles ///
				stats(N unique_drs N_clust /* unique_schools */ mean pct_mean, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef.\ \% of Mean")) ///
				replace
			
			restore

		}
		
	}
	
// }


*** iv-regressions-hcpcs-fe ***

*** THINK ABOUT IF THIS IS IMPLEMENTED CORRECTLY WITH THE HCPCS FEs! ***

* TAKES A LONG TIME TO RUN, THEREFORE COMMENTED OUT!

// use "$temp/cms-panel-with-treatment", clear
//
// keep if sample_fg_sel5_total_payments == 1 // should be ok!
//
// keep ///
// 	npi             ///
// 	year            ///
// 	years_treated*  ///
// 	tuition_bill    ///
// 	*med_school     ///
// 	grad_year       ///
// 	phySpec         ///
// 	hrr             ///
// 	groupPAC        ///
// 	avg_mdcr_pymt_amt*
//	
// sum year
// local min = r(min)
// local max = r(max)
//
// forvalues n = `min'/`max' {
//	
// 	preserve
//	
// 	keep if year == `n'
//	
// 	reshape long avg_mdcr_pymt_amt, i(npi) j(hcpcs) string
//	
// 	tempfile reshape_`n'
// 	save  	`reshape_`n''
//	
// 	restore
//	
// }
//
// clear
// forvalues n = `min'/`max' {
//
// 	append using `reshape_`n''
//	
// }
//
// save "$temp/cms-panel-with-treatment-hcpcs", replace
// use  "$temp/cms-panel-with-treatment-hcpcs", clear
//
// label var tuition_bill "Tuition bill"
//
// replace avg_mdcr_pymt_amt = 0 if avg_mdcr_pymt_amt == .
//
// eststo clear
//
// * Locals:
// local hcpcs_FEs `" $FEs "med_school grad_year phySpec groupPAC hcpcs" "'
// local outcome avg_mdcr_pymt_amt
//
// foreach FE of local hcpcs_FEs {
//
// 	qui : eststo : ivreghdfe ///
// 		`outcome' ///
// 		(tuition_bill = $years_treated) $controls, /// controls here?
// 		cl(orig_med_school) absorb(`FE')
//		
// 	sum `outcome' if e(sample) == 1
//	
// 	estadd r(mean)
//	
// 	scalar pct_mean = 100 * _b[tuition_bill] / r(mean)
//	
// 	estadd scalar pct_mean
//
// }
//
// esttab est*, ///
// 	keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label
//
// estfe est*, labels(                 /// ssc install erepost
// 	med_school "School FE"          ///
// 	grad_year  "Graduation Year FE" ///
// 	phySpec    "Specialization FE"  ///
// 	hrr        "HRR FE"             ///
// 	groupPAC   "Group FE"           ///
// 	hcpcs      "HCPCS FE")
//	
// esttab est* using "$git/tables/iv-regs-hcpcs-`outcome'-0.tex", ///
// 	keep(tuition_bill) se star(* 0.10 ** 0.05 *** 0.01) label ///
// 	indicate(`r(indicate_fe)') nomtitles ///
// 	stats(N N_clust mean pct_mean, fmt(%9.0fc %9.0fc 3 1) labels("Observations (dr-yr-hcpcs)" "Clusters" "Mean" "Coef.\ \% of Mean")) ///
// 	replace


*** top-specializations ***
	
use "$temp/cms-panel-with-treatment", clear

merge 1:1 npi year using "$temp/main-sample-npi-year"
assert  _merge != 2
keep if _merge == 3

g n = 1

collapse (sum) n, by(phySpec)

gsort -n

egen total = total(n)

g perc = 100 * n / total

g cperc = sum(perc)

replace  perc = round( perc, 0.01)
replace cperc = round(cperc, 0.01)

g rank = _n

order rank, first

keep if inrange(rank, 1, 20)

drop total

* ChatGPT:

* Step 1: Create the LaTeX file
file open myfile using "$git/tables/top-specializations.tex", write replace

* Step 2: Write the table header (booktabs style)
file write myfile "\begin{tabular}{l l c c c}" _n
file write myfile "\toprule" _n
file write myfile "Rank & Specialization & Frequency & Percent & Cumulative \\ \midrule" _n

* Step 3: Loop through your data and write each row
forvalues i = 1/`=_N' {
    local r    = string(rank[`i'], "%2.0f")  // Rank as integer
    local spec = phySpec[`i']                // String
    local nval = string(n[`i'], "%9.0fc")    // Frequency with comma
    local pval = string(perc[`i'], "%5.2f")  // Percent with 2 decimals
    local cval = string(cperc[`i'], "%5.2f") // Cumulative percent 2 decimals
    
    file write myfile "`r' & `spec' & `nval' & `pval' & `cval' \\\\" _n
}

* Step 4: Close the table
file write myfile "\bottomrule" _n
file write myfile "\end{tabular}" _n
file close myfile
