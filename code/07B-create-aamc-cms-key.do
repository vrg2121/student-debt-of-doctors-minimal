
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
	 med_school == "a t still un, arizona schl of dent.y & oral hlth" // internal consistency
	 
replace med_school = ///
	"baylor college of dentistry/texas a & m university" if ///
	med_school == "baylor college of dentistry/texas a&m university" // internal consistency
	
replace med_school = ///
	"wake forest university school of medicine" if ///
	med_school == "bowman gray school of medicine of wake forest university" // matches aamc
	
replace med_school = /// 
	"the warren alpert medical school of brown university" if
	inlist(med_school, "warren alpert medical school of brown university", ///
	"brown university program in medicine") // matches aamc
	
replace med_school = ///
	"university of cincinnati college of medicine" if ///
	med_school ==  "cincinnati college of medicine & surgery" // matches aamc, internal consinstency

// cleveland clinic lerner college of medicine is within case western reserve university, however it covers all tuition. it should be treated as a separate program. It is not found in the aamc data.

replace med_school = ///
	"columbia university vagelos college of physicians & surgeons" if ///
	inlist(med_school, "columbia university college of physicians & surgeons", ///
		"columbia school of medicine") // this matches with aamc data 
	
replace med_school = ///
	"cooper medical school of rowan university" if ///
	med_school == "cooper medical college" // matches aamc, internal consistency
	
replace med_school = ///
	"geisel school of medicine at dartmouth" if ///
	med_school == "dartmouth medical school" // matches aamc

replace med_school = ///
	"brody school of medicine at east carolina university" if ///
	med_school == "east carolina university school of medicine" // matches aamc, internal consistency
	
replace med_school = ///
	"east tennessee state university james h. quillen college of medicine" if ///
	inlist(med_school, "east tennessee state university quillen college of medicine", ///
		"east tennessee state university, quillen-dishner college of medicine") // this matches with aamc data

replace med_school = ///
	"frank h. netter md school of medicine at quinnipiac university" if ///
	med_school == "f h netter, m.d. school of med at quinnipiac univ" // matches aamc data
	
replace med_school = ///
	"george washington university school of medicine & health sciences" if ///
	med_school == "george washington university school of medicine" // matches aamc data

replace med_school = ///
	"georgetown university school of medicine" if ///
	med_school == "georgetown university of medicine" // matches aamc data
	
replace med_school = ///
	"hackensack meridian school of medicine" if ///
	med_school == "hackensack meridian school of med at seton hall" // matches aamc data
	
replace med_school = ///
	"donald & barbara zucker school of medicine at hofstra/northwell" if ///
	med_school == "hofstra north shore - lij school of medicine" // matches aamc data
	
replace med_school = ///
	"university of california, irvine, school of medicine" if ///
	inlist(med_school, "university of california, irvine, california college of medicine", ///
		"university of california, irvine, college of medicine", ///
		"irvine california college of medicine") // matches aamc data, internal consistency
		
replace med_school = ///
	"marshall university joan c. edwards school of medicine" if ///
	inlist(med_school,"jc edwards school of medicine, marshall university", ///
	"marshall university school medicine") // matches aamc data, internal consistency
	
replace med_school = ///
	"sidney kimmel medical college at thomas jefferson university" if ///
	med_school == "jefferson medical college of thomas jefferson university" // matches aamc data
	
replace med_school = ///
	"weill cornell medicine" if ///
	inlist(med_school, "js weill medical college, cornell university", ///
	"cornell university medical college") // matches aamc data
	
replace med_school = ///
	"university of kentucky college of medicine" if ///
	inlist(med_school, "kentucky school of medicine", ///
	"kentucky university medical department") // matches aamc data

replace med_school = ///
	"university of louisville school of medicine" if ///
	inlist(med_school, "louisville hospital medical college", ///
	"louisville medical college", ///
	"louisville national medical college") // matches aamc data, internal consistency
	
replace med_school = ///
	"loyola university chicago stritch school of medicine" if ///
	med_school == "loyola university of chicago, stritch school of medicine" // matches aamc data

replace med_school = ///
	"mayo clinic alix school of medicine" if ///
	med_school == "mayo medical school" // matches aamc data

replace med_school = ///
	"medical college of georgia at augusta university" if ///
	inlist(med_school, "medical college of georgia", ///
	"medical college of georgia school of medicine") // matches aamc data, internal consistency
	
replace med_school = ///
	"the university of toledo college of medicine & life sciences" if ///
	inlist(med_school, "toledo medical college", ///
	"university of toledo college of medicine", ///
	"medical college of ohio at toledo") // matches aamc data, internal consistency

replace med_school = ///
	"virginia commonwealth university school of medicine" if ///
	inlist(med_school, "medical college of virginia commonwealth university school of medicine", ///
	"virginia commonwealth university, school of medicine") // matches aamc data, internal consistency

replace med_school = ///
	"meharry medical college" if ///
	med_school == "meharry medical college school of medicine" // matches aamc data
	
replace med_school = ///
	"university of miami leonard m. miller school of medicine" if ///
	inlist(med_school, ///
	"university of miami school of medicine", ///
	"university of miami, lm miller school of medicine") // matches aamc data, internal consistency
	
replace med_school = ///
	"university of missouri-columbia school of medicine" if ///
	med_school == "university of missouri, columbia school of medicine" // matches aamc data
	
replace med_school = ///
	"university of missouri-kansas city school of medicine" if ///
	med_school == "university of missouri, kansas city, school of medicine" // matches aamc data
	
replace med_school = ///
	"university of nebraska college of medicine" if ///
	med_school == "nebraska college of medicine" // matches aamc data, internal consistency 

replace med_school = ///
	"university of nevada, reno school of medicine" if ///
	med_school == "university of nevada school of medicine" // matches aamc data
	
replace med_school = ///
	"university of north dakota school of medicine & health sciences" if ///
	med_school == "university of north dakota school of medicine" // matches aamc data
	
replace med_school = ///
	"perelman school of medicine at the university of pennsylvania" if ///
	med_school == "university of pennsylvania school of medicine" // matches aamc data
	
replace med_school = ///
	"frederick p. whiddon college of medicine at the university of south alabama" if ///
	med_school == "university of south alabama college of medicine" // matches aamc data
	
replace med_school = ///
	"university of south carolina school of medicine columbia" if ///
	med_school == "university of south carolina school of medicine" // matches aamc data
	
replace med_school = ///
	"university of south carolina school of medicine greenville" if ///
	med_school == "university of south carolina school of medicine, greenville" // matches aamc data
	
replace med_school = ///
	"university of south dakota, sanford school of medicine" if ///
	inlist(med_school, "university of south dakota school of medicine", ///
	"sanford school of medicine of university of south dakota") // matches aamc data, internal consistency

replace med_school = ///
	"keck school of medicine of the university of southern california" if ///
	inlist(med_school, "university of southern california keck school of medicine", ///
	"university of southern california school of medicine") // matches aamc data, internal consistency
	
replace med_school = ///
	"university of tennessee health science center college of medicine" if ///
	inlist(med_school, "university of tennessee, hsc, college of medicine", ///
	"university of tennersee college of medicine") // matches aamc data, internal consistency

replace med_school = ///
	"mcgovern medical school at the university of texas health science center at houston" if ///
	med_school == "university of texas medical school at houston" // matches aamc data
	
replace med_school = ///
	"the university of texas health science center at san antonio joe r. & teresa lozano long school of medicine" if ///
	med_school == "university of texas medical school at san antonio" // matches aamc data
	
replace med_school = ///
	"university of texas rio grande valley school of medicine" if ///
	med_school == "university of texas rio grande valley med school" // matches aamc data
	
replace med_school = ///
	"university of texas southwestern medical school" if ///
	med_school == "university of texas southwestern medical school at dallas" // matches aamc data
	
replace med_school = ///
	"spencer fox eccles school of medicine at the university of utah" if ///
	med_school == "university of utah school of medicine" // matches aamc data
	
replace med_school = ///
	"robert larner, m.d., college of medicine at the university of vermont" if ///
	med_school == "university of vermont college of medicine" // matches aamc data
	
replace med_school = ///
	"university of wisconsin school of medicine & public health" if ///
	inlist(med_school, "university of wisconsin medical school", ///
	"university of wisconsin school of medicine") // matches aamc data, internal consistency

replace med_school = ///
	"washington university in st. louis school of medicine" if ///
	med_school == "washington university school of medicine" // matches aamc data
	
replace med_school = ///
	"western michigan university homer stryker m.d. school of medicine" if ///
	med_school == "western michigan un homer stryker school of med" // matches aamc data
	
replace med_school = ///
	"wright state university boonshoft school of medicine" if ///
	med_school == "wright state university school of medicine" // matches aamc data, internal consistency
	
replace med_school = ///
	"yale school of medicine" if ///
	med_school == "yale university school of medicine" // matches aamc data, internal consistency
	
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

