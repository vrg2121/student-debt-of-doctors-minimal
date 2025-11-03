
**************
*** MASTER ***
**************

* Description of this do-file:

* 	Contact info to RAs
*	Sets paths: You need to change one manually!
*	Runs all scripts and describes them briefly

**************
**************
**************


***********
*** RAs ***
***********

* Worked on project from its start in Feb 2025 until Oct 2025:
* 	Simon Almerström Przybyl, SHoF/SSE in Stockholm (Sweden)
* 	simon.almerstrom.przybyl@gmail.com

* Worked on project from Oct 2025:
* 	Victoria Garcia
*	[mail to Victoria]



*************
*** PATHS ***
*************

*** ONLY PATH YOU NEED TO CHANGE ***

global dropbox ///
	"C:\dropbox\Phil Research Dropbox\Victoria Garcia\Student Debt of Doctors"
//	"/Users/simonalmerstromprzybyl/new-dropbox/Dropbox/Student Debt of Doctors"
	
*** CHANGES AUTOMATICALLY ***
	
global fang_gong_replication ///
	"$dropbox/Tuition Data/replication/Fang & Gong (AER 2017) – Replication package/119565-V1"

global git ///
	"$dropbox/Tuition Data/simon/student-debt-of-doctors"
	
global do ///
	"$git/code/stata"
	
global temp ///
	"$git/data/working/temp"
	
cd "$temp"

* This folder is important, do not erase:
*	$temp/old-important-files

* The following folder is good to save but can be erased if storage is critical
* It contains results for Marieke's 2025-10-20 Jönköping seminar:
*	$temp/old-2025-10-20

* All other files/folders in the $temp folder can be overwritten and erased



***********
*** RUN ***
***********

* 01 – Set globals:
do "$do/01A-globals.do"

* Deprecated:
// * 02 – Create key between AAMC and CMS school names:
// // do: Manual Excel work
//    do "$do/02A-create-key-aamc-cms-names.do" // export Excels for manual work
// // do: Manual Excel work
//    do "$do/02B-create-key-aamc-cms-names.do" // import Excel after manual work and creates key
//
//
// * 03 – Create tuition panel for schools:
// // do: Manual Excel work
//    do "$do/03A-create-school-panel.do" // create tuition panel for schools



* Note --- Two important files from the above sections 02 and 03 are in:

*	Old AAMC-CMS school name key: $temp/old-important-files/key-our-aamc
*	Helps with building IPEDS panel: $temp/old-important-files/aamc-schools-nr-obs
  
* Only places in do-files below where $temp/old-important-files/key-our-aamc is currently used:
*	07B --- not necessary usage
*	09A --- critical usage! Replace with new key once implemented

* The file $temp/old-important-files/aamc-schools-nr-obs is not used in any of the do-files below

  
* 04 – Create yearly CMS outcomes:
do "$do/04A-create-cms-outcomes.do" // standardize yearly files for CMS outcomes
do "$do/04B-create-cms-outcomes.do" // calculate CMS outcome variables (payments etc)


* 05 – Create yearly ProPublica outcomes:
do "$do/05A-create-propublica-outcomes.do" // calculate ProPublica outcomes


* 06 – Create doctor panel:
do "$do/06A-create-doctor-panel.do" // standardize yearly CMS characteristics files
do "$do/06B-create-doctor-panel.do" // append standardized files to create the doctor panel


* 07 – Create key between AAMC and CMS school names:
do "$do/07A-create-aamc-cms-key.do" // TO DO: fix name issues in AAMC tuition files
do "$do/07B-create-aamc-cms-key.do" // TO DO: create key between AAMC and CMS names


* 08 – Create tuition panel for school:
do "$do/08A-create-school-panel.do" // create school panel


* 09 – Merge outcomes and tuition into the doctor panel (REPLACE WITH NEW SCHOOL NAME KEY):
do "$do/09A-merge-doctor-panel.do" // CURRENTLY USES OLD KEY: $temp/old-important-files/key-our-aamc.dta


*** DO-FILES BELOW ARE DEPRECATED IF YOU MOVE TO ANDREW'S NEW IDENTIFICATION ***


* 10 – Create treatment groups:
do "$do/10A-create-treatment-groups.do" // create treatment groups from school panel
do "$do/10B-create-treatment-groups.do" // merge treatment groups into doctor panel


* 11 – Generate tables and figures for Overleaf:
do "$do/11A-analysis.do" // tables
do "$do/11B-analysis.do" // figures


* 12 – Extra exports for other purposes:
do "$do/12A-extras.do" // extras


* 13 – Scrap code:
do "$do/13A-scrap-code.do" // scrap



******************************************
*** SIMON'S COMMENTS ABOUT FILES ABOVE ***
******************************************


* 01 – Set globals:
*	Build upon.


* 02 – Create key between AAMC and CMS school names:
* 	Deprecated.


* 03 – Create tuition panel for schools:
* 	Deprecated.
  
  
* 04 – Create yearly CMS outcomes:
*	Build upon.


* 05 – Create yearly ProPublica outcomes:
*	Improve and build upon.


* 06 – Create doctor panel:
*	Build upon.


* 07 – Create key between AAMC and CMS school names:
*	NEEDS WORK!
*	- FIX AAMC NAME DUPLICATES (MANUAL)
*	- MAKE AAMC-CMS SCHOOL NAME KEY BETTER (MANUAL)


* 08 – Create tuition panel for school:
*	Build upon.


* 09 – Merge outcomes and tuition into the doctor panel (REPLACE WITH NEW SCHOOL NAME KEY):
*	Build upon, but REPLACE WITH NEW SCHOOL NAME KEY.


* 10 – Create treatment groups:
*	Deprecated if you move to Andrew's new identification.
*	POSSIBLY IMPORTANT CONCEPT: Event time concepts still relevant? Line 40 in 10B.


* 11 – Generate tables and figures for Overleaf:
*	Deprecated if you move to Andrew's new identification.


* 12 – Extra exports for other purposes:
*	Deprecated but first plots possibly interesting.


* 13 – Scrap code:
*	Deprecated but some possibly useful IPEDS notes.


