
********************************************
*** MATCH SCHOOL NAMES FROM AAMC AND CMS ***
********************************************

* Description of this do-file:

* 	Find all unique school names from AAMC (school tuition panel) and CMS (doctor panel)
*	Find overlap between AAMC and CMS names
*	For remaining unmatched CMS names, manually try to find match in AAMC
* 	Investigate if the final match is good enough, and if not: Add IPEDS as a source to the data?

********************************************
********************************************
********************************************



*** AAMC SCHOOLS ***
	
use "$temp/full-aamc-tuition", clear

keep our_med_school

duplicates drop

export excel "$temp/aamc-schools.xlsx", replace firstrow(var)
save         "$temp/aamc-schools"     , replace


*** CMS SCHOOLS ***

use "$temp/cms-panel-raw", clear

keep if isMD == 1 // should imply four years of medical school

* Manually standardize school names within the cms list

replace our_med_school = subinstr(our_med_school, " and ", " & ", .)

replace our_med_school = subinstr(our_med_school, "univ of ", "university of ", .)
replace our_med_school = subinstr(our_med_school, "col of ", "college of ", .)
replace our_med_school = subinstr(our_med_school, "un of ", "university of ", .)
replace our_med_school = subinstr(our_med_school, "univeristy ", "university ", .)
replace our_med_school = subinstr(our_med_school, "univ ", "university of ", .)

replace med_school = ///
	"university of maryland school of medicine" if /// 
	inlist(med_school, "baltimore medical college", ///
		"baltimore university school of medicine", ///
		"maryland medical college") // the baltimore medical college disbanded in 1920; maryland medical college disbanded in 1913

replace med_school = ///
	 "at still university, arizona school of dentistry & oral hlth" if ///
	 med_school == "a t still un, arizona schl of dent.y & oral hlth"
	 
replace med_school = ///
	"baylor college of dentistry/texas a & m university" if ///
	med_school == "baylor college of dentistry/texas a&m university"
	
replace med_school = ///
	"wake forest university school of medicine" if ///
	med_school == "bowman gray school of medicine of wake forest university"
	
replace med_school = ///
	"warren alpert medical school of brown university" if ///
	med_school == "brown university program in medicine"
	
replace med_school = ///
	"cincinnati college of medicine & surgery" if ///
	med_school == "university of cincinnati college of medicine" 

// cleveland clinic lerner college of medicine is within case western reserve university, however it covers all tuition. it should be treated as a separate program. It is not found in the aamc data.

replace med_school = ///
	"columbia university vagelos college of physicians & surgeons" if ///
	inlist(med_school, "columbia university college of physicians & surgeons", ///
		"columbia school of medicine") // this matches with aamc data 
	
replace med_school = ///
	"cooper medical school of rowan university" if ///
	med_school == "cooper medical college"
	
replace med_school = ///
	"weill cornell medicine" if ///
	med_school == "cornell university medical college"
	
replace med_school = ///
	"geisel school of medicine at dartmouth" if ///
	med_school == "dartmouth medical school"

replace med_school = ///
	"brody school of medicine at east carolina university" if ///
	med_school == "east carolina university school of medicine"
	
replace med_school = ///
	"east tennessee state university james h. quillen college of medicine" if ///
	inlist(med_school, "east tennessee state university quillen college of medicine", ///
		"east tennessee state university, quillen-dishner college of medicine") // this matches with aamc data

	
bys npi (year) : keep if _n == 1

g n = 1

collapse (sum) n, by(our_med_school)

gsort -n our_med_school

g cumulative_n = sum(n)

egen total = sum(n)

g perc = 100 * n / total

g cumulative_perc = 100 * cumulative_n / total

drop total

sort our_med_school

export excel "$temp/cms-schools.xlsx", replace firstrow(var)
save         "$temp/cms-schools"     , replace


*** MERGE CMS NAMES WITH AAMC NAMES ***

use "$temp/cms-schools", clear

rename our_med_school med_school

merge 1:1 med_school using "$temp/aamc-schools"

keep if _merge == 1 // & cumulative_perc <= 90 // TRUNCATE IF OK!
drop    _merge

rename med_school our_med_school

keep our_med_school

bys our_med_school : assert _N == 1

export excel "$temp/remaining-cms-schools.xlsx", replace firstrow(var)
save         "$temp/remaining-cms-schools"     , replace


*** INTERMEDIATE MANUAL STEP ***

* For each school in "$temp/remaining-cms-schools.xlsx",
* manually try to find a match in "$temp/aamc-schools.xlsx"

* Call the resulting Excel:
*	"$temp/aamc-matched-remaining-schools.xlsx"

* The Excel should have two columns:
*	our_med_school
*	med_school

* TEMP 1:
*	Simon created "$temp/aamc-matched-remaining-schools.xlsx" matching only one school

* TEMP 2:
*	We can use the old key as help/inspiration to build the new key:

	* For completeness, this is the old deprecated Excel which builds the old key used below:
	
	* 	"$git/data/working/unique-names/output-excels/final/matching-names.xlsx"
	
	use "$temp/old-important-files/key-our-aamc", clear // old key

	keep if source == "aamc"

	keep *med_school

	drop if med_school == our_med_school // already matches perfectly
	
	order our_med_school med_school
	
	export excel "$temp/old-key-inspiration.xlsx", replace firstrow(var) // old key


*** CREATE KEY ***
	
import excel "$temp/aamc-matched-remaining-schools.xlsx", clear firstrow
save         "$temp/aamc-matched-remaining-schools"     , replace
	
use our_med_school using "$temp/cms-schools", clear

rename our_med_school med_school

merge 1:1 med_school using "$temp/aamc-schools"
keep if _merge == 3
drop    _merge

g our_med_school = med_school // since this is the matched schools

append using "$temp/aamc-matched-remaining-schools"

drop if med_school == ""

bys our_med_school : assert _N == 1

order our_med_school med_school

save "aamc-cms-school-name-key", replace


*** INVESTIGATE NAME MATCHING ***

use "$temp/cms-schools", clear

merge 1:1 our_med_school using "aamc-cms-school-name-key"
assert _merge != 2

drop med_school // we only care about _merge

gsort -n

* Visually:
// br

* Quantitatively:
collapse (sum) perc, by(_merge)
// br

* Good enough or does IPEDS need to be added?

