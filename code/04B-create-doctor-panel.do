
***************************
*** CREATE DOCTOR PANEL ***
***************************

* Description of this do-file:

* 	Appends the files from the last do-file to create a panel
* 	Drops doctors with strange data
* 	Fills in gaps etc in the panel

***************************
***************************
***************************



*** PUT THE FILES TOGETHER ***

clear
forvalues n = 2013/2025 { // 2011/2025

	append using "$working_data/temp/minimal-chars-`n'"
	
}

label var grad_year "Calendar Graduation Year (e.g. graduating in 2000-2001 -> grad_year = 2001)"
label var our_med_school "Graduated from School (our name)"


*** DEFINE isMD ***

* Define further characteristics:
replace cred = subinstr(cred, " ", "", .)
replace cred = subinstr(cred, ".", "", .)
replace cred = subinstr(cred, ",", "", .) if strpos(cred, ",") == length(cred)

g isMD_year = strpos(cred, "MD") > 0

bys npi : egen isMD = max(isMD_year)

drop isMD_year

bys npi year (grad_year) : assert grad_year[1] == grad_year[_N]
bys npi year             : keep if _n == _N // CAREFUL -- BECOMES RANDOM -- ASK EMIEL.
	// 15,496,345 observations deleted on the basis of what??
	// keeps only the last observation for each npi-year group, so only one npi per year
		// could there be helpful data lost here?

* Med school and MD behavior:
// br if npi == 1003103771

* 69,291 contradictions in 2,106,293 by-groups:
// bys npi (year) : assert grad_year[1] == grad_year[_N]


*** DROP IF our_med_school OR grad_year IS ALWAYS MISSING ***

foreach var in our_med_school grad_year {

	* Drop if var is always missing:
	bys npi (`var') : g drop = missing(`var'[1]) & missing(`var'[_N])
		// our_med_school drops 31 incomplete observations from 2025
		// grad_year drops 2,302 incomplete observations
	
	drop  if drop == 1
	drop     drop

	if ("`var'" == "our_med_school") {
		
		* Use last updated var:
		bys npi (year) : egen last_updated = max(year) if !(missing(`var') | `var' == "OTHER")
			// 7,583,258 observations are missing last_updated
		
		* Drop if last_updated is always missing:
		bys npi (last_updated) : g drop = missing(last_updated[1]) & missing(last_updated[_N])
		
		drop  if drop == 1
			// 7,179,381 observations dropped
		drop     drop
		
		replace `var' = "" if year != last_updated
		
		* Print this var across the npi:
		bys npi (`var') : replace `var' = `var'[_N] // NOTE: _N
			// standardizes school names for doctor based on the last year reported. how do we know that's the most correct year?
		
	}
	
	if ("`var'" == "grad_year") {
		
		* Use last updated var:
		bys npi (year) : egen last_updated = max(year) if !missing(`var')
			// 14,975 missing values generated (i.e. missing grad_year)
		
		replace `var' = .  if year != last_updated
		
		* Print this var across the npi:
		bys npi (`var') : replace `var' = `var'[1] // NOTE: 1
			// standardizes grad year based on last year reported
		
	}

	drop last_updated

}


*** MINOR THINGS ***

* Make school lower-case:
replace our_med_school = lower(our_med_school)
	
* Drop doctors graduating too long ago:
drop if grad_year < $min_grad_year


*** FILL IN GAPS ETC = MAKE PANEL WELL-BEHAVED ***

* Check consistency of panel:
bys npi  year  : assert _N == 1 // (npi, year) idenitifies observations
bys npi (year) : g delta_year = year[_n + 1] - year[_n] if _n < _N // checking gaps

* Filling in gaps:
expand delta_year

bys npi (year) : replace year = year[_n - 1] + 1 if _n > 1 & delta_year > 1

drop delta_year

* Verifying filling in the gaps went well:
bys npi (year) : assert year[_n] + 1 == year[_n + 1] if _n < _N

* Event time:
g event_time = year - grad_year

label var event_time "Years Since Graduation"

* Panel should start the year after the graduation year:
drop if event_time <= 0
		// when the graduation year is < 0, it's a data error
		// this drops 2,149 observations / 3,147,607

/* CHECK ACCURACY OF CMS DATA
	******************************************************
/*

CHECK CORRECTNESS OF THE DOCTOR DATA (VG, JAN 2026)

*/

keep if isMD == 1

count if event_time < 5
	// 54,027 observations have event_time < 5
	// does not make sense with 4 year average residency
	
// how many doctors are there?
egen tag = tag(npi) 	// tag first doctor npi
tab tag					// there are 333,506 unique npi

// how many doctors may have incorrect grad_year based on event_time
g sus_doc = 1 if event_time < 5 & tag == 1		
tab sus_doc 			// 39,394 doctors have a suspicious event_time

// take random sample of 30 outside of the suspicious doctors
preserve

drop if tag == 0

drop if event_time < 5

drop sus_doc 

sample 30, count

export delimited "$dropbox/Tuition Data/cms_sample.csv", replace
// see $dropbox/Tuition Data/cms_sample_checked for resutls; 1/30 was incorrect

restore


drop sus_doc
drop tag
*/

drop if event_time <= 5
		// eliminates graduation dates occuring before residency (avg of 4 years)


	*******************************************************

assert   year != .
bys npi (year) : g min_et = event_time if _n == 1

expand min_et

* Careful about this, but should be OK:
bys npi (year) : replace event_time = _n
bys npi (year) : replace year       = _n + grad_year

drop min_et

* Check consistency of panel:
bys npi  year  : assert _N == 1
bys npi (year) : assert year[_n] + 1 == year[_n + 1] if _n < _N

save "$working_data/temp/cms-panel-raw", replace
