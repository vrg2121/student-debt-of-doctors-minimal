
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
*	victoria.g.4201@gmail.com



*************
*** PATHS ***
*************

*** ONLY PATHS YOU NEED TO CHANGE ***

* Victoria removed the data from the .git for data-mangement and version control purposes

global dropbox ///
	"C:/dropbox/Phil Research Dropbox/Victoria Garcia/Student Debt of Doctors"
//	"/Users/simonalmerstromprzybyl/new-dropbox/Dropbox/Student Debt of Doctors"

global git ///
	"C:/Users/c1vrg01/dev/student-debt-of-doctors-minimal"
	
*** CHANGES AUTOMATICALLY ***
	
global fang_gong_replication ///
	"$dropbox/Tuition Data/replication/Fang & Gong (AER 2017) – Replication package/119565-V1"
	
global working_data ///
	"$dropbox/Tuition Data/simon/student-debt-of-doctors/data/working"
	
global raw_data ///
	"$dropbox/Tuition Data/simon/student-debt-of-doctors/data/original"
	
global do ///
	"$git/code"
	
global tables ///
	"$git/results/tables"
	
global figures ///
	"$git/results/figures"
	
global batch ///
	"$working_data/batch"

	

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

  
* 02 – Create yearly CMS outcomes:
do "$do/02A-create-cms-outcomes.do" // standardize yearly files for CMS outcomes
do "$do/02B-create-cms-outcomes.do" // calculate CMS outcome variables (payments etc)


* 03 – Create yearly ProPublica outcomes:
do "$do/03A-create-propublica-outcomes.do" // calculate ProPublica outcomes


* 04 – Create doctor panel:
do "$do/04A-create-doctor-panel.do" // standardize yearly CMS characteristics files
do "$do/04B-create-doctor-panel.do" // append standardized files to create the doctor panel

* 05 – Create key between AAMC and CMS school names:
do "$do/05A-create-aamc-cms-key.do" // fix name issues in AAMC tuition files
do "$do/05B-create-aamc-cms-key.do" // standardize AAMC and CMS names
// there is no crosswalk file, modifications to the data are made directly in stata

* 06 – Create tuition panel for school:
do "$do/06A-create-school-panel.do" // create school panel
// drops missing data for CA schools

* 07 – Define Large
do "$do/07A-define-cohorts.do" // define a large change in tuition using AAMC data

* 08 – Merge outcomes and tuition into the doctor panel:
do "$do/08A-merge-doctor-panel.do" // standardized AAMC and CMS names applied here
// missing previously imputed as zeros here

* 09 – Merge CMS and AAMC Data
do "$do/09A-cms-aamc-merge.do" // merge AAMC and CMS data based on med school name; analysis of unmatched data 
do "$do/09B-cohort-reshape.do" // reshape cohort, must be done

* 10 – Regressions without HCPCS
do "$do/10A-regressions.do" // outputs regression tables for all outcome variables


* 11 – Regressions by HCPCS Group
do "$do/11A-hcpcsgroup-regressions.do" // creates doctor-year-hcpcsgroup level data-mangement
do "$do/11B-hcpcsgroup-regressions.do" // hcpcsgroup level regressions

* 12 – Regressions by E/M vs Non-E/M Outcomes


* 13 – Summary Statistics / Data Exploration
do "$do/13B-stat-figures.do" 



/*** DO-FILES BELOW DEPRECATED BY MOVE TO ANDREW'S NEW IDENTIFICATION ***


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




