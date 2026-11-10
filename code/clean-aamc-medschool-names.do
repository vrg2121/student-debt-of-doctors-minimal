***********************************
*** CLEAN AAMC MED SCHOOL NAMES ***
***********************************

replace med_school = lower(med_school)

replace med_school = subinstr(med_school, " and ", " & ", .)
replace med_school = subinstr(med_school, "&", " & ", .)
replace med_school = subinstr(med_school, ".", "", .)
replace med_school = subinstr(med_school, ",", "", .)
replace med_school = subinstr(med_school, "-", " ", .)
replace med_school = subinstr(med_school, "–", " ", .)
replace med_school = itrim(trim(med_school))

// from 05A-create-aamc-cms-key.do
replace med_school = "texas a & m university college of medicine" if inlist(med_school, "texas a & m university school of medicine", "texas a & m university naresh k vashisht college of medicine")

replace med_school =  ///
	"eastern virginia medical school" if med_school == ///
	"eastern virginia medical school at old dominion university"
	
replace med_school = ///
	"anne burnett marion school of medicine at tcu" if med_school == ///
	"anne burnett marion school of medicine at texas christian university"
	
replace med_school =  ///
	"uniformed services university of the health sciences f edward hebert school of medicine" if med_school == ///
	"uniformed services university of the health sciences f edward hebert school of medicine3"
	
replace med_school = /// 
	"texas tech university health sciences center paul l foster school of medicine" if med_school == ///
	"paul l foster school of medicine texas tech university health sciences center at el paso"
	
replace med_school = ///
	"the university of texas health science center at san antonio joe r & teresa lozano long school of medicine" if med_school == ///
	"the university of texas at san antonio joe r & teresa lozano long school of medicine"
	
replace med_school = ///
	"mcgovern medical school at the university of texas health science center at houston" if med_school == ///
	"mcgovern medical school at uthealth houston"
	
replace med_school = ///
	"central michigan university college of medicine" if med_school == ///
	"covenant healthcare college of medicine at central michigan university"
	
replace med_school = ///
	"university of texas at austin dell medical school" if med_school == ///
	"dell medical school university of texas at austin"
	
drop if regexm(med_school, "^[\s\t]*(note:|© 2025)")
drop if med_school == "nyu grossman long island school of medicine"
drop if med_school == "kaiser permanente bernard j tyson school of medicine"
drop if med_school == "medical college of pennsylvania"
drop if med_school == "hahnemann university school of medicine"
drop if med_school == "uniformed services university of the health sciences f edward hebert school of medicine"