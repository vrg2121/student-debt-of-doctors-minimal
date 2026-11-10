
**************************************************
*** CREATE YEARLY DOCTOR CHARACTERISTICS FILES ***
**************************************************

* Description of this do-file:

* 	Translates Emiel's and FG's characteristics files to the same form as those we have downloaded
* 	Uses the translated and downloaded characterics files to create smaller standardized characteristics files
*	The final files will be the building blocks for our doctor panel

**************************************************
**************************************************
**************************************************



*************************************************
*** TRANSLATING EMIEL's CHARACTERISTICS FILES ***
*************************************************

* We will let this be the 2011-2012 files, which might not be correct

* Emiel's final characteristics file:
use "$dropbox/FullData/RawData/characteristics_suplemented", clear

replace grd_yr = gradYear if grd_yr == .

export delimited ///
	"$raw_data/cms-characteristics/extracted/raw-characteristics-2011.csv", ///
	replace

* Emiel's DAC file:
import delimited ///
	"$dropbox/FullData/RawData/DAC_Physician_Characteristics.csv", ///
	clear varnames(1)
	
export delimited ///
	"$raw_data/cms-characteristics/extracted/raw-characteristics-2012.csv", ///
	replace


*********************************************
*** TRANSLATING FG's CHARACTERISTICS FILE ***
*********************************************

* We will let this be the 2013 file.
* This might not be entirely correct,
* but also not completely unreasonable given when FG downloaded their files
* (in 2014 according to their documentation).

foreach section in A-G H-N O-Z {
	
	import delimited ///
		"$fang_gong_replication/input/National_physician_`section'.csv", ///
		clear varnames(1) stringcols(_all)
		
	save "$working_data/temp/fg-characteristics-`section'", replace
	
}

clear
foreach section in A-G H-N O-Z {
	
	append using "$working_data/temp/fg-characteristics-`section'"
	
}

export delimited ///
	"$raw_data/cms-characteristics/extracted/raw-characteristics-2013.csv", ///
	replace


***************************************************
*** STANDARDIZE 2013-2025 CHARACTERISTICS FILES ***
***************************************************

* Extract relevant characteristics:
forvalues n = 2013/2025 {

	import delimited ///
		"$raw_data/cms-characteristics/extracted/raw-characteristics-`n'.csv", ///
		clear varnames(1) stringcols(_all) // rowrange(1:2)
	
	* Checks for npi:
	confirm var   npi
	assert        npi != ""
	assert substr(npi, 1, 1) != "0"
	assert length(npi) == 10
	destring      npi, replace
	format        npi %10.0f
	
	g year = `n'
	
	local keep
	
	* Graduation year:
	cap rename graduationyear grad_year // 2014-2017
	cap rename grd_yr         grad_year // 2018-2025
	confirm var				  grad_year
	local keep `keep'		  grad_year
	destring                  grad_year, replace
	
	* School:
	cap rename medicalschoolname our_med_school // 2014-2017
	cap rename med_sch           our_med_school // 2018-2025
	confirm var				     our_med_school
	local keep `keep'		     our_med_school
	
	* Credentials:
	cap rename credential cred // 2014-2017
							   // 2018-2025, no renaming necessary
	confirm var			  cred
	local keep `keep'	  cred
	
	* Specialization:
	cap rename primaryspecialty phySpec // 2014-2017
	cap rename pri_spec         phySpec // 2018-2025
	confirm var 				phySpec
	local keep `keep'	  		phySpec
	
	* Group Practice ID:
	cap rename grouppracticepacid groupPAC // 2014-2017
	cap rename org_pac_id         groupPAC // 2018-2025
	confirm var					  groupPAC
	local keep `keep'	  		  groupPAC
// 	tostring                      groupPAC, replace // error later otherwise
//	tostring not needed since we do stringcols(_all) in import delimited
	
	* ZIP code:
	cap rename zipcode zip // 2014-2017
						   // 2018-2025, no renaming necessary
	confirm var		   zip
	local keep `keep'  zip
// 	tostring           zip, replace // error later otherwise
//	tostring not needed since we do stringcols(_all) in import delimited
	
	* Ordering:
	order year          , after(npi)
	order our_med_school, after(grad_year)
	
	keep npi year `keep'
	
	save "$working_data/temp/minimal-chars-`n'", replace

}
