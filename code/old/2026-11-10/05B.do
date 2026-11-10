**********************************************************
*** MATCH DOC CHARACTERISTICS MED SCHOOL NAMES TO AAMC ***
**********************************************************

use "$working_data/temp/doc_characteristics", clear

keep if isMD == 1 & event_time >= 4 // an MD after residency

**# Manually standardize school names within the cms list

replace our_med_school = subinstr(our_med_school, " and ", " & ", .)

replace our_med_school = subinstr(our_med_school, "univ of ", "university of ", .)
replace our_med_school = subinstr(our_med_school, "col of ", "college of ", .)
replace our_med_school = subinstr(our_med_school, "un of ", "university of ", .)
replace our_med_school = subinstr(our_med_school, "univeristy ", "university ", .)
replace our_med_school = subinstr(our_med_school, "univ ", "university of ", .)

rename our_med_school med_school

replace med_school = ///
	"perelman school of medicine at the university of pennsylvania" ///
	if inlist(med_school, "perelman school of med at the university of pennsylvania", "university of pennsylvania school of medicine") // matches aamc data, internal consistency

replace med_school = ///
	"east tennessee state university james h. quillen college of medicine" if ///
	inlist(med_school, "east tennessee state university, quillen-dishner college of medicine", "east tennessee state university quillen college of medicine") // matches aamc data, internal consistency
	
replace our_med_school = ///
	"icahn school of medicine at mount sinai" if ///
	our_med_school == "mount sinai school of medicine of city university of new york" // matches aamc data, internal consistency

	
replace med_school = ///
	"university of maryland school of medicine" if /// 
	inlist(med_school, "baltimore medical college", ///
		"baltimore university school of medicine", ///
		"maryland medical college") // the baltimore medical college disbanded in 1920; maryland medical college disbanded in 1913
// 759 changes

replace med_school = ///
	 "at still university, arizona school of dentistry & oral hlth" if ///
	 med_school == "a t still un, arizona schl of dent.y & oral hlth" // internal consistency
// 151 changes
	 
replace med_school = ///
	"baylor college of dentistry/texas a & m university" if ///
	med_school == "baylor college of dentistry/texas a&m university" // internal consistency
// 4 changes
	
replace med_school = ///
	"wake forest university school of medicine" if ///
	med_school == "bowman gray school of medicine of wake forest university" // matches aamc
// 14,574 changes	

replace med_school = /// 
	"the warren alpert medical school of brown university" if ///
	inlist(med_school, "warren alpert medical school of brown university", ///
	"brown university program in medicine") // matches aamc, internal consistency
// 23,099 changes
	
replace med_school = ///
	"university of cincinnati college of medicine" if ///
	med_school ==  "cincinnati college of medicine & surgery" // matches aamc, internal consinstency

// cleveland clinic lerner college of medicine is within case western reserve university, however it covers all tuition. it should be treated as a separate program. It is not found in the aamc data.

// 1,152 changes

replace med_school = ///
	"columbia university vagelos college of physicians & surgeons" if ///
	inlist(med_school, "columbia university college of physicians & surgeons", ///
		"columbia school of medicine") // this matches with aamc data 
// 48,749 changes
		
replace med_school = ///
	"cooper medical school of rowan university" if ///
	med_school == "cooper medical college" // matches aamc, internal consistency
// 352 changes
	
replace med_school = ///
	"geisel school of medicine at dartmouth" if ///
	med_school == "dartmouth medical school" // matches aamc
// 18,716 changes

replace med_school = ///
	"brody school of medicine at east carolina university" if ///
	med_school == "east carolina university school of medicine" // matches aamc, internal consistency
// 18,576 changes
	
replace med_school = ///
	"east tennessee state university james h. quillen college of medicine" if ///
	inlist(med_school, "east tennessee state university quillen college of medicine", ///
		"east tennessee state university, quillen-dishner college of medicine", "university of tennessee college of medicine") // this matches with aamc data
// 17,002 changes

replace med_school = ///
	"frank h. netter md school of medicine at quinnipiac university" if ///
	med_school == "f h netter, m.d. school of med at quinnipiac univ" // matches aamc data
// 211 changes
	
replace med_school = ///
	"george washington university school of medicine & health sciences" if ///
	med_school == "george washington university school of medicine" // matches aamc data
// 54,021 changes

replace med_school = ///
	"georgetown university school of medicine" if ///
	med_school == "georgetown university of medicine" // matches aamc data, internal consistency
// 58.731 changes
	
replace med_school = ///
	"hackensack meridian school of medicine" if ///
	med_school == "hackensack meridian school of med at seton hall" // matches aamc data
// 24 changes
	
replace med_school = ///
	"donald & barbara zucker school of medicine at hofstra/northwell" if ///
	med_school == "hofstra north shore - lij school of medicine" // matches aamc data
// 335 changes
	
replace med_school = ///
	"university of california, irvine, school of medicine" if ///
	inlist(med_school, "university of california, irvine, california college of medicine", ///
		"university of california, irvine, college of medicine", ///
		"irvine california college of medicine") // matches aamc data, internal consistency
// 27,135 changes
		
replace med_school = ///
	"marshall university joan c. edwards school of medicine" if ///
	inlist(med_school,"jc edwards school of medicine, marshall university", ///
	"marshall university school medicine") // matches aamc data, internal consistency
// 16,171
	
replace med_school = ///
	"sidney kimmel medical college at thomas jefferson university" if ///
	med_school == "jefferson medical college of thomas jefferson university" // matches aamc data
// 74,080 changes
	
replace med_school = ///
	"weill cornell medicine" if ///
	inlist(med_school, "js weill medical college, cornell university", ///
	"cornell university medical college") // matches aamc data, internal consistency
// 27,262 changes
	
replace med_school = ///
	"university of kentucky college of medicine" if ///
	inlist(med_school, "kentucky school of medicine", ///
	"kentucky university medical department") // matches aamc data
// 536 changes

replace med_school = ///
	"university of louisville school of medicine" if ///
	inlist(med_school, "louisville hospital medical college", ///
	"louisville medical college", ///
	"louisville national medical college") // matches aamc data, internal consistency
// 479 changes
	
replace med_school = ///
	"loyola university chicago stritch school of medicine" if ///
	med_school == "loyola university of chicago, stritch school of medicine" // matches aamc data
// 48,834 changes
	
replace med_school = ///
	"mayo clinic alix school of medicine" if ///
	med_school == "mayo medical school" // matches aamc data
// 15,801 changes
	
replace med_school = ///
	"medical college of georgia at augusta university" if ///
	inlist(med_school, "medical college of georgia", ///
	"medical college of georgia school of medicine") // matches aamc data, internal consistency
// 60,048 changes
	
replace med_school = ///
	"the university of toledo college of medicine & life sciences" if ///
	inlist(med_school, "toledo medical college", ///
	"university of toledo college of medicine", ///
	"medical college of ohio at toledo") // matches aamc data, internal consistency
// 22,252 changes
	
replace med_school = ///
	"virginia commonwealth university school of medicine" if ///
	inlist(med_school, "medical college of virginia commonwealth university school of medicine", ///
	"virginia commonwealth university, school of medicine") // matches aamc data, internal consistency
// 40,831 changes
	
replace med_school = ///
	"meharry medical college" if ///
	med_school == "meharry medical college school of medicine" // matches aamc data
// 23,469 changes
	
replace med_school = ///
	"university of miami leonard m. miller school of medicine" if ///
	inlist(med_school, ///
	"university of miami school of medicine", ///
	"university of miami, lm miller school of medicine") // matches aamc data, internal consistency
// 51,533 changes
	
replace med_school = ///
	"university of missouri-columbia school of medicine" if ///
	inlist(med_school, "university of missouri, columbia school of medicine", "medical university of south carolina college of medicine") // matches aamc data
// 31,423 changes
	
replace med_school = ///
	"university of missouri-kansas city school of medicine" if ///
	med_school == "university of missouri, kansas city, school of medicine" // matches aamc data
// 31,110 changes
	
replace med_school = ///
	"university of nebraska college of medicine" if ///
	med_school == "nebraska college of medicine" // matches aamc data, internal consistency 
// 926 changes

	
replace med_school = ///
	"university of nevada, reno school of medicine" if ///
	med_school == "university of nevada school of medicine" // matches aamc data
// 17,099 changes
	
replace med_school = ///
	"university of north dakota school of medicine & health sciences" if ///
	med_school == "university of north dakota school of medicine" // matches aamc data
// 22,926 changes
	
replace med_school = ///
	"perelman school of medicine at the university of pennsylvania" if ///
	med_school == "university of pennsylvania school of medicine" // matches aamc data
// 43,754 changes

replace med_school = ///
	"frederick p. whiddon college of medicine at the university of south alabama" if ///
	med_school == "university of south alabama college of medicine" // matches aamc data
// 19,339 changes
	
replace med_school = ///
	"university of south carolina school of medicine columbia" if ///
	med_school == "university of south carolina school of medicine" // matches aamc data
// 30,351 changes
	
replace med_school = ///
	"university of south carolina school of medicine greenville" if ///
	med_school == "university of south carolina school of medicine, greenville" // matches aamc data
// 407 changes
	
replace med_school = ///
	"university of south dakota, sanford school of medicine" if ///
	inlist(med_school, "university of south dakota school of medicine", ///
	"sanford school of medicine of university of south dakota") // matches aamc data, internal consistency
// 18,280 changes
	
replace med_school = ///
	"keck school of medicine of the university of southern california" if ///
	inlist(med_school, "university of southern california keck school of medicine", ///
	"university of southern california school of medicine") // matches aamc data, internal consistency
// 41,412 changes
	
replace med_school = ///
	"university of tennessee health science center college of medicine" if ///
	inlist(med_school, "university of tennessee, hsc, college of medicine", ///
	"university of tennesee college of medicine", "college of physicians & surgeons (tennessee)") // matches aamc data, internal consistency
// 6,651 changes
	
replace med_school = ///
	"mcgovern medical school at the university of texas health science center at houston" if ///
	med_school == "university of texas medical school at houston" // matches aamc data
// 65,674 changes
	
replace med_school = ///
	"the university of texas health science center at san antonio joe r. & teresa lozano long school of medicine" if ///
	med_school == "university of texas medical school at san antonio" // matches aamc data
// 56,591 changes
	
replace med_school = ///
	"university of texas rio grande valley school of medicine" if ///
	med_school == "university of texas rio grande valley med school" // matches aamc data
// 35 changes
	
replace med_school = ///
	"university of texas southwestern medical school" if ///
	inlist(med_school, "the university of texas health science center at san antonio joe r. & teresa lozano long school of medicine", "university of texas southwestern medical school at dallas") // matches aamc data
// 68,930 changes
	
replace med_school = ///
	"spencer fox eccles school of medicine at the university of utah" if ///
	med_school == "university of utah school of medicine" // matches aamc data
// 36,461 changes
	
replace med_school = ///
	"robert larner, m.d., college of medicine at the university of vermont" if ///
	med_school == "university of vermont college of medicine" // matches aamc data
// 31,156 changes
	
replace med_school = ///
	"university of wisconsin school of medicine & public health" if ///
	inlist(med_school, "university of wisconsin medical school", ///
	"university of wisconsin school of medicine") // matches aamc data, internal consistency
// 58,968 changes
	
replace med_school = ///
	"washington university in st. louis school of medicine" if ///
	med_school == "washington university school of medicine" // matches aamc data
// 38,693 changes 
	
replace med_school = ///
	"western michigan university homer stryker m.d. school of medicine" if ///
	med_school == "western michigan un homer stryker school of med" // matches aamc data
// 282 changes
	
replace med_school = ///
	"wright state university boonshoft school of medicine" if ///
	med_school == "wright state university school of medicine" // matches aamc data, internal consistency
// 24,387 changes
	
replace med_school = ///
	"yale school of medicine" if ///
	med_school == "yale university school of medicine" // matches aamc data, internal consistency
// 33,605 changes
	
replace med_school = ///
	"albany medical college" if ///
	med_school == "albany medical college of union university" // matches aamc data
// 47,766 changes
		
replace med_school = ///
	"albert einstein college of medicine" if ///
	med_school == "albert einstein college of medicine of yeshiva university" // matches aamc data
// 67,030 changes
	
replace med_school = ///
	"boston university aram v. chobanian & edward avedisian school of medicine" if ///
	med_school == "boston university school of medicine" // matches aamc data
// 65,106 changes
	
replace med_school = ///
	"california university of science & medicine-school of medicine" if ///
	med_school == "california university of science & medicine" // matches aamc data
// 134 changes
	
replace med_school = ///
	"central michigan university college of medicine" if ///
	med_school == "central michigan college of medicine" // matches aamc data
// 730 changes
	
replace med_school = ///
	"charles e. schmidt college of medicine at florida atlantic university" if ///
	med_school == "florida atlantic university, college of medicine" // matches aamc data
// 980 changes
	
replace med_school = ///
	"chicago medical school at rosalind franklin university of medicine & science" if ///
	med_school == "r franklin university of med & sci/chicago medical school" // matches aamc data
// 18,997 changes
	
replace med_school = ///
	"cuny school of medicine" if ///
	med_school == "city university of new york school of medicine" // matches aamc data
// 153 changes
	
replace med_school = ///
	"florida international university herbert wertheim college of medicine" if ///
	med_school == "florida international univ, college of medicine" // matches aamc data
// 1,943 changes
	
replace med_school = ///
	"jacobs school of medicine & biomedical sciences at the university at buffalo" if ///
	med_school == "state university of new york at buffalo school of medicine" // matches aamc data
// 52,073 changes
	
replace med_school = ///
	"lewis katz school of medicine at temple university" if ///
	med_school == "temple university school of medicine" // matches aamc data'
// 78,040 changes
	
replace med_school = ///
	"northeast ohio medical university" if ///
	inlist(med_school, "northeastern ohio universities college of medicine", ///
	"northeastern ohio university college of medicine") // matches aamc data, internal consistency
// 42,529 changes
// the Medical University of Ohio and the University of Toledo merged in 2006
// medical college of ohio, ohio medical university both associated with toledo? Taking a conservative approach and not renaming.

replace med_school = ///
	"northwestern university the feinberg school of medicine" if ///
	inlist(med_school, "northwestern university feinberg medical school", ///
	"northwestern university medical school", "northwestern university womans medical school") // matches aamc data, internal consistency
// 64,733 changes
// northwestern university womans medical school closed in 1902

replace med_school = ///
	"nyu grossman school of medicine" if ///
	med_school == "new york university school of medicine" // matches aamc data
// 66,340 changes
	
replace med_school = ///
	"oakland university william beaumont school of medicine" if ///
	med_school == "oakland univ, william beaumont school of medicine" // matches aamc data
// 1,562 changes
	
replace med_school = ///
	"oregon health & science university school of medicine" if ///
	med_school == "oregon health sciences university school of medicine" // matches aamc data
// 41,343 changes
	
replace med_school = ///
	"perelman school of medicine at the university of pennsylvania" if ///
	med_school == "perelman school of med at the university of pennsylvania" // matches aamc data
// 53,687 changes
	
replace med_school = ///
	"ponce health sciences university school of medicine" if ///
	med_school == "ponce school of medicine" // matches aamc data
// 20,196 changes
	
replace med_school = ///
	"renaissance school of medicine at stony brook university" if ///
	med_school == "state university of new york at stony brook, school of medicine" // matches aamc data
// 41,506 changes
	
replace med_school = ///
	"rush medical college of rush university medical center" if ///
	med_school == "rush medical college of rush university" // matches aamc data
// 52,040 changes
	
replace med_school = ///
	"rutgers, robert wood johnson medical school" if ///
	inlist(med_school, "rutgers r w johnson medical school (cam/new bruns/pisc)", ///
	"rutgers, robert woood johnson medical school", "umdnj-robert wood johnson medical school", "umdnj-new jersey medical school", "rutgers new jersey medical school") // matches aamc data, internal consistency
// 37,110 changes

replace med_school = ///
	"state university of new york upstate medical university alan & marlene norton college of medicine" if ///
	med_school == "state university of ny upstate medical university" // matches aamc data
// 42,559 changes
	
replace med_school = ///
	"suny downstate health sciences university college of medicine" if ///
	inlist(med_school, "state university of new york downstate medical center", "state university of new york health science center of syracuse") // matches aamc data
// 54,989 changes
	
replace med_school = ///
	"texas a & m university college of medicine" if ///
	med_school == "texas a & m university system, hsc, college of medicine" // matches aamc data
// 27,359 changes
	
replace med_school = ///
	"texas tech university health sciences center school of medicine" if ///
	inlist(med_school, "texas tech university health science center school of medicine", ///
	"paul l foster school of medicine, texas tech univ") // matches aamc data, internal consistency
// 52,597 changes
	
replace med_school = ///
	"universidad central del caribe school of medicine" if ///
	inlist(med_school, "universidad central del caribe escuela de medicina", ///
	"university central del caribe escuela de medicina") // matches aamc data, internal consistency
// 15,041 changes
	
replace med_school = ///
	"university of alabama at birmingham marnix e. heersink school of medicine" if ///
	inlist(med_school, "birmingham medical college", ///
	"university of alabama school of medicine") // matches aamc data, seems to be referring to the same thing
// 66,841 changes

replace med_school = ///
	"university of arkansas for medical sciences college of medicine" if ///
	med_school == "university of arkansas college of medicine" // matches aamc data
// 56,771 changes
	
replace med_school = ///
	"university of california, davis, school of medicine" if ///
	med_school == "university of california, davis school of medicine" // matches aamc data
// 34,852 changes
	
replace med_school = ///
	"university of california, los angeles david geffen school of medicine" if ///
	inlist(med_school, "university of california, geffen school of medicine", ///
	"university of california, ucla school of medicine") // matches aamc data, internal consistency
// 59,664 changes
	
replace med_school = ///
	"university of california, riverside school of medicine" if ///
	med_school == "university of california, riverside, school of medicine" // matches aamc data
// 394 changes
	
replace med_school = ///
	"university of california, san francisco, school of medicine" if ///
	med_school == "university of california, san francisco school of medicine" // matches aamc data
// 53,387 changes
	
replace med_school = ///
	"university of central florida college of medicine" if ///
	med_school == "university of central florida, college of medicine" // matches aamc data
// 1,290 changes
	
replace med_school = ///
	"university of chicago division of the biological sciences the pritzker school of medicine" if ///
	med_school == "university of chicago, pritzker school of medicine" // matches aamc data
// 41,666 changes
	
replace med_school = ///
	"university of colorado school of medicine" if ///
	inlist(med_school, "university of colorado school of medicine, aurora", ///
	"university of colorado school of medicine, denver") // matches aamc data, seems to be referring to the same thing
// 48,816 changes
	
replace med_school = ///
	"university of hawaii, john a. burns school of medicine" if ///
	med_school == "university of hawaii john a. burns school of medicine" // matches aamc data
// 20,458 changes

replace med_school = ///
	"university of illinois college of medicine" if ///
	inlist(med_school, "university of illinois at chicago health science center", ///
	"university of illinois college of med (chi/peor/rock/chm-urb)") // matches aamc data; different locations, same tuition; internal consistency
// unclear which school "illinois medical college" is referring to
// 95,689 changes
	
replace med_school = ///
	"university of iowa roy j. & lucille a. carver college of medicine" if ///
	inlist(med_school, "university of iowa college of medicine",  ///
	"university of iowa, rj & l carver college of medicine") // matches aamc data, internal consistency
// 68,839 changes

replace med_school = ///
	"university of kansas school of medicine" if ///
	med_school == "university of kansas school of med (kc/wich/sal)" // matches aamc data, internal consistency
// unclear which schools "kansas medical college" and "university medical college of kansas city" are referring to
// 73,581 changes

replace med_school = ///
	"university of massachusetts t.h. chan school of medicine" if ///
	med_school == "university of massachusetts medical school" // matches aamc data
// 41,595 changes
	
replace med_school = ///
	"university of texas medical branch john sealy school of medicine" if ///
	med_school == "university of texas medical branch at galveston" // matches aamc data
// 77,078 changes
	
replace med_school = ///
	"usf health morsani college of medicine" if ///
	med_school == "university of south florida college of medicine" // matches aamc data
// 37,833 changes
	
replace med_school = ///
	"washington state university elson s. floyd college of medicine" if ///
	med_school == "washington state university elson s floyd college of medicine" // matches aamc data
// 70 changes

replace med_school = ///
	"geisinger commonwealth school of medicine" if ///
	med_school == "commonwealth medical college" // matches aamc data
// 474 changes
	
replace med_school = ///
	"kirk kerkorian school of medicine at unlv" if ///
	med_school == "university of nevada, las vegas school of medicine" // matches aamc data
// 95 changes

**# Save Cleaned Data
sort npi year zip5

save "$working_data/temp/clean_doc_characteristics", replace

**# Save CMS School Reference

sort npi year

bys npi (year) : keep if _n == 1

g n = 1

collapse (sum) n, by(med_school)

gsort -n med_school

g cumulative_n = sum(n)

egen total = sum(n)

g perc = 100 * n / total

g cumulative_perc = 100 * cumulative_n / total

drop total

sort med_school

export excel "$working_data/temp/doc_characteristics_schools.xlsx", replace firstrow(var)
save         "$working_data/temp/doc_characteristics_schools"     , replace