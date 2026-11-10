***************************************************
*** CLEAN DOCTOR CHARACTERSTIC MED SCHOOL NAMES ***
***************************************************

***************************************************
* Make med school names internally consistent
* Standardize med school names with aamc data
***************************************************
replace our_med_school = lower(our_med_school)
replace our_med_school = subinstr(our_med_school, " and ", " & ", .)
replace our_med_school = subinstr(our_med_school, "&", " & ", .)
replace our_med_school = subinstr(our_med_school, ".", "", .)
replace our_med_school = subinstr(our_med_school, ",", "", .)
replace our_med_school = subinstr(our_med_school, "-", " ", .)
replace our_med_school = subinstr(our_med_school, "–", " ", .)
replace our_med_school = itrim(trim(our_med_school))

replace our_med_school = subinstr(our_med_school, "univ of ", "university of ", .)
replace our_med_school = subinstr(our_med_school, "col of ", "college of ", .)
replace our_med_school = subinstr(our_med_school, "un of ", "university of ", .)
replace our_med_school = subinstr(our_med_school, "univeristy ", "university ", .)
replace our_med_school = subinstr(our_med_school, "univ ", "university of ", .)

replace our_med_school = ///
		"california college podiatric medicine" if ///
		inlist(our_med_school, "california school of podiatric medicine")

replace our_med_school = ///
		"michigan state university college of human medicine" if ///
		inlist(our_med_school, "michigan state university college of osteopathic medicine")
		
replace our_med_school = ///
		"des moines university of osteopathic medicine & health sciences" if ///
		inlist(our_med_school, "university of osteopathic medicine & health sciences")
		
replace our_med_school = ///
		"des moines university of osteopathic medicine & health sciences" if ///
		inlist(our_med_school, "university of osteopathic medicine & health sciences")

replace our_med_school = ///
		"lake erie college of osteopathic medicine" if ///
		inlist(our_med_school, "lake erie college of osteopathic medicine erie", "lake erie college of osteo med at seton hill university of", "lake erie college of osteopathic medicine bradenton") // internal consistency

replace our_med_school = ///
		"nova southeastern college of osteo medicine" if ///
		inlist(our_med_school, "southeastern college of osteo medicine")

replace our_med_school = ///
		"uniformed services university of the health sciences f edward hebert school of medicine" if ///
		inlist(our_med_school, "uniformed services university of the health sciences", "uniformed services uhs fe hebert school of med") // internal consistency
		
replace our_med_school = ///
		"university of north texas health science center at fort worth" if ///
		our_med_school == "university of north texas hsc college of osteopathic med" // internal consistency

replace our_med_school = ///
		"kirksville college of osteopathic medicine" if ///
		our_med_school == "at still university of health sciences college of osteo med kirksville" // internal consistency

replace our_med_school = ///
		"case western reserve university school of medicine" if ///
		our_med_school == "clvlnd clinic lerner college of med of case wstn rsv university" // internal consistency
	 
replace our_med_school = ///
	"hahnemann university college of medicine" if ///
	inlist(our_med_school, "medical college of pennsylvania hahnemann university", "hahnemann university college of medicine") // internal consistency
	
replace our_med_school = ///
		"case western reserve university school of medicine" if ///
		our_med_school == "case western university school of dental medicine" & isMD == 1 // internal consistency
	
replace our_med_school = ///
	"university of colorado school of medicine" if ///
	our_med_school == "university of colorado school of medicine denver" // internal consistency

	 
replace our_med_school = ///
	"cleveland clinic lerner college of medicine case western reserve university" if ///
	our_med_school == "clvlnd clinic lerner college of med of case wstn rsv university" & npi == 1003005257 // internal consistency
// cleveland clinic lerner college has no tuition, distinct for case western 

replace our_med_school = ///
	"medical college of wisconsin" if ///
	inlist(our_med_school, "wisconsin college of physicians & surgeons") // internal consistency


// levelsof our_med_school if strpos(our_med_school, "rutgers")
// levelsof our_med_school if strpos(our_med_school, "robert")
replace our_med_school = ///
	"perelman school of medicine at the university of pennsylvania" ///
	if inlist(our_med_school, "perelman school of med at the university of pennsylvania", "university of pennsylvania school of medicine") // matches aamc data, internal consistency

replace our_med_school = ///
	"east tennessee state university james h quillen college of medicine" if ///
	inlist(our_med_school, "east tennessee state university quillen dishner college of medicine", "east tennessee state university quillen college of medicine") // matches aamc data, internal consistency
	
replace our_med_school = ///
	"icahn school of medicine at mount sinai" if ///
	our_med_school == "mount sinai school of medicine of city university of new york" // matches aamc data, internal consistency

	
replace our_med_school = ///
	"university of maryland school of medicine" if /// 
	inlist(our_med_school, "baltimore medical college", ///
		"baltimore university school of medicine", ///
		"maryland medical college") // the baltimore medical college disbanded in 1920; maryland medical college disbanded in 1913

replace our_med_school = ///
	 "at still university, arizona school of dentistry & oral hlth" if ///
	 our_med_school == "a t still un arizona schl of denty & oral hlth" // internal consistency
	 
replace our_med_school = ///
	"baylor college of dentistry/texas a & m university" if ///
	our_med_school == "baylor college of dentistry/texas a & m university" // internal consistency
	
replace our_med_school = ///
	"wake forest university school of medicine" if ///
	our_med_school == "bowman gray school of medicine of wake forest university" // matches aamc

replace our_med_school = /// 
	"the warren alpert medical school of brown university" if ///
	inlist(our_med_school, "warren alpert medical school of brown university", ///
	"brown university program in medicine") // matches aamc, internal consistency
	
replace our_med_school = ///
	"university of cincinnati college of medicine" if ///
	our_med_school ==  "cincinnati college of medicine & surgery" // matches aamc, internal consinstency

// cleveland clinic lerner college of medicine is within case western reserve university, however it covers all tuition it should be treated as a separate program. It is not found in the aamc data


replace our_med_school = ///
	"columbia university vagelos college of physicians & surgeons" if ///
	inlist(our_med_school, "columbia university college of physicians & surgeons", ///
		"columbia school of medicine") // this matches with aamc data 
		
replace our_med_school = ///
	"cooper medical school of rowan university" if ///
	our_med_school == "cooper medical college" // matches aamc, internal consistency
	
replace our_med_school = ///
	"geisel school of medicine at dartmouth" if ///
	our_med_school == "dartmouth medical school" // matches aamc

replace our_med_school = ///
	"brody school of medicine at east carolina university" if ///
	our_med_school == "east carolina university school of medicine" // matches aamc, internal consistency
	
replace our_med_school = ///
	"frank h netter md school of medicine at quinnipiac university" if ///
	our_med_school == "f h netter md school of med at quinnipiac univ" // matches aamc data
	
replace our_med_school = ///
	"george washington university school of medicine & health sciences" if ///
	our_med_school == "george washington university school of medicine" // matches aamc data

replace our_med_school = ///
	"georgetown university school of medicine" if ///
	our_med_school == "georgetown university of medicine" // matches aamc data, internal consistency
	
replace our_med_school = ///
	"hackensack meridian school of medicine" if ///
	our_med_school == "hackensack meridian school of med at seton hall" // matches aamc data
	
replace our_med_school = ///
	"donald & barbara zucker school of medicine at hofstra/northwell" if ///
	our_med_school == "hofstra north shore lij school of medicine" // matches aamc data
	
replace our_med_school = ///
	"university of california irvine school of medicine" if ///
	inlist(our_med_school, "university of california irvine california college of medicine", ///
		"university of california irvine college of medicine", ///
		"irvine california college of medicine") // matches aamc data, internal consistency
		
replace our_med_school = ///
	"marshall university joan c edwards school of medicine" if ///
	inlist(our_med_school,"jc edwards school of medicine marshall university", ///
	"marshall university school medicine") // matches aamc data, internal consistency
	
replace our_med_school = ///
	"sidney kimmel medical college at thomas jefferson university" if ///
	our_med_school == "jefferson medical college of thomas jefferson university" // matches aamc data
	
replace our_med_school = ///
	"weill cornell medicine" if ///
	inlist(our_med_school, "js weill medical college cornell university", ///
	"cornell university medical college") // matches aamc data, internal consistency
	
replace our_med_school = ///
	"university of kentucky college of medicine" if ///
	inlist(our_med_school, "kentucky school of medicine", ///
	"kentucky university medical department") // matches aamc data

replace our_med_school = ///
	"university of louisville school of medicine" if ///
	inlist(our_med_school, "louisville hospital medical college", ///
	"louisville medical college", ///
	"louisville national medical college") // matches aamc data, internal consistency
	
replace our_med_school = ///
	"loyola university chicago stritch school of medicine" if ///
	our_med_school == "loyola university of chicago stritch school of medicine" // matches aamc data
	
replace our_med_school = ///
	"mayo clinic alix school of medicine" if ///
	our_med_school == "mayo medical school" // matches aamc data
	
replace our_med_school = ///
	"medical college of georgia at augusta university" if ///
	inlist(our_med_school, "medical college of georgia", ///
	"medical college of georgia school of medicine") // matches aamc data, internal consistency
	
replace our_med_school = ///
	"the university of toledo college of medicine & life sciences" if ///
	inlist(our_med_school, "toledo medical college", ///
	"university of toledo college of medicine", ///
	"medical college of ohio at toledo") // matches aamc data, internal consistency
	
replace our_med_school = ///
	"virginia commonwealth university school of medicine" if ///
	inlist(our_med_school, "medical college of virginia commonwealth university school of medicine", ///
	"virginia commonwealth university school of medicine") // matches aamc data, internal consistency

replace our_med_school = ///
	"virginia commonwealth university school of medicine" if ///
	inlist(our_med_school, "virginia commonwealth university of school of dentistry") & isMD == 1 // matches aamc data, internal consistency
	
replace our_med_school = ///
	"meharry medical college" if ///
	our_med_school == "meharry medical college school of medicine" // matches aamc data
	
replace our_med_school = ///
	"university of miami leonard m miller school of medicine" if ///
	inlist(our_med_school, ///
	"university of miami school of medicine", ///
	"university of miami lm miller school of medicine") // matches aamc data, internal consistency
	
replace our_med_school = ///
	"university of missouri columbia school of medicine" if ///
	our_med_school == "university of missouri columbia school of medicine" // matches aamc data
	
replace our_med_school = ///
	"university of missouri kansas city school of medicine" if ///
	our_med_school == "university of missouri kansas city school of medicine" // matches aamc data
	
replace our_med_school = ///
	"university of nebraska college of medicine" if ///
	our_med_school == "nebraska college of medicine" // matches aamc data, internal consistency 
	
replace our_med_school = ///
	"university of nevada reno school of medicine" if ///
	our_med_school == "university of nevada school of medicine" // matches aamc data
	
replace our_med_school = ///
	"university of north dakota school of medicine & health sciences" if ///
	our_med_school == "university of north dakota school of medicine" // matches aamc data

replace our_med_school = ///
	"frederick p whiddon college of medicine at the university of south alabama" if ///
	our_med_school == "university of south alabama college of medicine" // matches aamc data
	
replace our_med_school = ///
	"university of south carolina school of medicine columbia" if ///
	inlist(our_med_school, "university of south carolina school of medicine") // matches aamc data
	
replace our_med_school = ///
	"university of south dakota sanford school of medicine" if ///
	inlist(our_med_school, "university of south dakota school of medicine", ///
	"sanford school of medicine of university of south dakota") // matches aamc data, internal consistency
	
replace our_med_school = ///
	"keck school of medicine of the university of southern california" if ///
	inlist(our_med_school, "university of southern california keck school of medicine", ///
	"university of southern california school of medicine") // matches aamc data, internal consistency
	
replace our_med_school = ///
	"university of tennessee health science center college of medicine" if ///
	inlist(our_med_school, "university of tennessee hsc college of medicine", ///
	"university of tennesee college of medicine", "college of physicians & surgeons (tennessee)") // matches aamc data, internal consistency
	
replace our_med_school = ///
	"mcgovern medical school at the university of texas health science center at houston" if ///
	inlist(our_med_school, "university of texas medical school at houston", "mcgovern medical school at uthealth houston") // matches aamc data
	
replace our_med_school = ///
	"university of texas rio grande valley school of medicine" if ///
	our_med_school == "university of texas rio grande valley med school" // matches aamc data
	
replace our_med_school = ///
	"university of texas southwestern medical school" if ///
	inlist(our_med_school, "university of texas southwestern medical school at dallas") // matches aamc data
	
replace our_med_school = ///
	"spencer fox eccles school of medicine at the university of utah" if ///
	our_med_school == "university of utah school of medicine" // matches aamc data
	
replace our_med_school = ///
	"robert larner md college of medicine at the university of vermont" if ///
	our_med_school == "university of vermont college of medicine" // matches aamc data
	
replace our_med_school = ///
	"university of wisconsin school of medicine & public health" if ///
	inlist(our_med_school, "university of wisconsin medical school", ///
	"university of wisconsin school of medicine") // matches aamc data, internal consistency
	
replace our_med_school = ///
	"washington university in st louis school of medicine" if ///
	our_med_school == "washington university school of medicine" // matches aamc data
	
replace our_med_school = ///
	"western michigan university homer stryker md school of medicine" if ///
	our_med_school == "western michigan un homer stryker school of med" // matches aamc data
	
replace our_med_school = ///
	"wright state university boonshoft school of medicine" if ///
	our_med_school == "wright state university school of medicine" // matches aamc data, internal consistency
	
replace our_med_school = ///
	"yale school of medicine" if ///
	our_med_school == "yale university school of medicine" // matches aamc data, internal consistency
	
replace our_med_school = ///
	"albany medical college" if ///
	our_med_school == "albany medical college of union university" // matches aamc data
		
replace our_med_school = ///
	"albert einstein college of medicine" if ///
	our_med_school == "albert einstein college of medicine of yeshiva university" // matches aamc data
	
replace our_med_school = ///
	"boston university aram v chobanian & edward avedisian school of medicine" if ///
	our_med_school == "boston university school of medicine" // matches aamc data
	
replace our_med_school = ///
	"california university of science & medicine-school of medicine" if ///
	our_med_school == "california university of science & medicine" // matches aamc data
	
replace our_med_school = ///
	"central michigan university college of medicine" if ///
	inlist(our_med_school, "central michigan college of medicine", "covenant healthcare college of medicine at central michigan university") // matches aamc data
	
replace our_med_school = ///
	"charles e schmidt college of medicine at florida atlantic university" if ///
	inlist(our_med_school, "florida atlantic university college of medicine", "atlantic medical college") // matches aamc data
	
replace our_med_school = ///
	"chicago medical school at rosalind franklin university of medicine & science" if ///
	inlist(our_med_school, "r franklin university of med & sci/chicago medical school", "university of health sciences/chicago medical school") // matches aamc data
	
replace our_med_school = ///
	"cuny school of medicine" if ///
	our_med_school == "city university of new york school of medicine" // matches aamc data
	
replace our_med_school = ///
	"florida international university herbert wertheim college of medicine" if ///
	our_med_school == "florida international university of college of medicine" // matches aamc data
	
replace our_med_school = ///
	"jacobs school of medicine & biomedical sciences at the university at buffalo" if ///
	our_med_school == "state university of new york at buffalo school of medicine" // matches aamc data
	
replace our_med_school = ///
	"lewis katz school of medicine at temple university" if ///
	our_med_school == "temple university school of medicine" // matches aamc data'

replace our_med_school = ///
	"ohio state university college of medicine" if ///
	our_med_school == "ohio medical university"
	
replace our_med_school = ///
	"northeast ohio medical university" if ///
	inlist(our_med_school, "northeastern ohio universities college of medicine", ///
	"northeastern ohio university college of medicine") // matches aamc data, internal consistency
// the Medical University of Ohio and the University of Toledo merged in 2006
// medical college of ohio, ohio medical university both associated with toledo? Taking a conservative approach and not renaming

replace our_med_school = ///
	"northwestern university the feinberg school of medicine" if ///
	inlist(our_med_school, "northwestern university feinberg medical school", ///
	"northwestern university medical school", "northwestern university womans medical school") // matches aamc data, internal consistency
// northwestern university womans medical school closed in 1902

replace our_med_school = ///
	"nyu grossman school of medicine" if ///
	our_med_school == "new york university school of medicine" // matches aamc data
	
replace our_med_school = ///
	"oakland university william beaumont school of medicine" if ///
	inlist(our_med_school, "oakland university of william beaumont school of medicine", "oakland college of medicine & surgery") // matches aamc data
	
replace our_med_school = ///
	"oregon health & science university school of medicine" if ///
	our_med_school == "oregon health sciences university school of medicine" // matches aamc data	
	
replace our_med_school = ///
	"ponce health sciences university school of medicine" if ///
	our_med_school == "ponce school of medicine" // matches aamc data
	
replace our_med_school = ///
	"renaissance school of medicine at stony brook university" if ///
	our_med_school == "state university of new york at stony brook school of medicine" // matches aamc data
	
replace our_med_school = ///
	"rush medical college of rush university medical center" if ///
	our_med_school == "rush medical college of rush university" // matches aamc data	

replace our_med_school = "rutgers new jersey medical school" if ///
	inlist(our_med_school, "umdnj new jersey medical school", "rutgers new jersey medical school", "umdnj new jersey school of osteo medicine")

replace our_med_school = ///
	"rutgers robert wood johnson medical school" if ///
	inlist(our_med_school, "rutgers r w johnson medical school (cam/new bruns/pisc)", ///
	"rutgers robert woood johnson medical school", "umdnj robert wood johnson medical school") // matches aamc data, internal consistency

replace our_med_school = ///
	"state university of new york upstate medical university alan & marlene norton college of medicine" if ///
	our_med_school == "state university of ny upstate medical university" // matches aamc data
	
replace our_med_school = ///
	"suny downstate health sciences university college of medicine" if ///
	inlist(our_med_school, "state university of new york downstate medical center", "state university of new york health science center of syracuse") // matches aamc data
	
replace our_med_school = ///
	"texas a & m university college of medicine" if ///
	inlist(our_med_school, "texas a & m university school of medicine", "texas a & m university naresh k vashisht college of medicine" "texas a & m university system hsc college of medicine") // matches aamc data
	
replace our_med_school = ///
	"texas tech university health sciences center paul l foster school of medicine" if ///
	inlist(our_med_school, "texas tech university health sciences center school of medicine", "texas tech university health science center school of medicine", ///
	"paul l foster school of medicine texas tech univ", "paul l foster school of medicine texas tech university health sciences center at el paso") // matches aamc data, internal consistency
	
replace our_med_school = ///
	"universidad central del caribe school of medicine" if ///
	inlist(our_med_school, "universidad central del caribe escuela de medicina", ///
	"university central del caribe escuela de medicina") // matches aamc data, internal consistency
	
replace our_med_school = ///
	"university of alabama at birmingham marnix e heersink school of medicine" if ///
	inlist(our_med_school, "birmingham medical college", ///
	"university of alabama school of medicine") // matches aamc data, seems to be referring to the same thing

replace our_med_school = ///
	"university of arkansas for medical sciences college of medicine" if ///
	our_med_school == "university of arkansas college of medicine" // matches aamc data
		
replace our_med_school = ///
	"university of california los angeles david geffen school of medicine" if ///
	inlist(our_med_school, "university of california geffen school of medicine", ///
	"university of california ucla school of medicine") // matches aamc data, internal consistency
				
replace our_med_school = ///
	"university of chicago division of the biological sciences the pritzker school of medicine" if ///
	our_med_school == "university of chicago pritzker school of medicine" // matches aamc data
	
replace our_med_school = ///
	"university of colorado school of medicine" if ///
	inlist(our_med_school, "university of colorado school of medicine aurora", ///
	"university of colorado school of medicine denver") // matches aamc data, seems to be referring to the same thing
	
replace our_med_school = ///
	"university of illinois college of medicine" if ///
	inlist(our_med_school, "university of illinois at chicago health science center", ///
	"university of illinois college of med (chi/peor/rock/chm-urb)", "illinois medical college") // matches aamc data; different locations, same tuition; internal consistency
// unclear which school "illinois medical college" is referring to
	
replace our_med_school = ///
	"university of iowa roy j & lucille a carver college of medicine" if ///
	inlist(our_med_school, "university of iowa college of medicine",  ///
	"university of iowa rj & l carver college of medicine") // matches aamc data, internal consistency

replace our_med_school = ///
	"university of kansas school of medicine" if ///
	our_med_school == "university of kansas school of med (kc/wich/sal)" // matches aamc data, internal consistency
// unclear which schools "kansas medical college" and "university medical college of kansas city" are referring to

replace our_med_school = ///
	"university of massachusetts th chan school of medicine" if ///
	our_med_school == "university of massachusetts medical school" // matches aamc data
	
replace our_med_school = ///
	"university of texas medical branch john sealy school of medicine" if ///
	our_med_school == "university of texas medical branch at galveston" // matches aamc data
	
replace our_med_school = ///
	"usf health morsani college of medicine" if ///
	our_med_school == "university of south florida college of medicine" // matches aamc data
	
replace our_med_school = ///
	"geisinger commonwealth school of medicine" if ///
	our_med_school == "commonwealth medical college" // matches aamc data
	
replace our_med_school = ///
	"kirk kerkorian school of medicine at unlv" if ///
	our_med_school == "university of nevada las vegas school of medicine" // matches aamc data

replace our_med_school = ///
	"the university of texas health science center at san antonio joe r & teresa lozano long school of medicine" if ///
	our_med_school == "university of texas medical school at san antonio"

drop if our_med_school == "medical college of pennsylvania"
drop if our_med_school == "uniformed services university of the health sciences f edward hebert school of medicine"
drop if our_med_school == "university college of medicine"
