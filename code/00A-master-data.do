
***************************
*** MASTER - CLEAN DATA ***
***************************

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



***********
*** RUN ***
***********

* 01 – Set globals:
do "$do/01A-globals.do"

  
* 02 – Create Year-HCPCS-Doctor Level Outcomes:
do "$do/02A-doc-yr-hcpcs-billing-outcomes.do"


* 03 – Create yearly ProPublica outcomes: (unused)
//do "$do/03A-create-propublica-outcomes.do" // calculate ProPublica outcomes


* 04 – Create Annual Doctor Characteristics:
do "$do/04A-annual-doc-characteristics.do" // extract relevant characteristics
do "$do/04B-annual-doc-characteristics.do" // standardize, clean and balance doc characteristics panel

* 05 – Clean School Names in AAMC Files
do "$do/05A-annual-school-tuition.do" // standardize school names in AAMC files

* 06 – Create tuition panel for school
do "$do/06A-annual-school-tution.do" // derives tuition variables
do "$do/06b-aamc-grad-apps-matric.do" // merges tuition onto graduates, applicants and matriculants data

* 07 – Create Year-HCPCS-Doctor-Characteristics Outcomes:
do "$do/07A-merge-doc-hcpcs-billing-characteristics.do" // doctor characteristics and disaggregated billing outcomes
do "$do/07B-annual-doc-billing-characteristics.do" // aggregate billing to doctor-year level
do "$do/07C-medschool-yr-for-cohortid.do" //

*** STOP HERE AND MANUALLY DO THE FOLLOWING ***
* 	run Claude Work to Identify Cohorts/run.bat
* 	copy cms-aamc-allmedschoolyears-withcohorts.csv into cms-aamc-allmedschoolyears-withcohorts-with-all-cohort-scenarios.xlsx


