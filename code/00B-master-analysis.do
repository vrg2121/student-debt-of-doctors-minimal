
*************************
*** MASTER - ANALYSIS ***
*************************

* before running this script
* 	run 00A-master-data
* 	run Claude Work to Identify Cohorts/run.bat
* 	copy cms-aamc-allmedschoolyears-withcohorts.csv into cms-aamc-allmedschoolyears-withcohorts-with-all-cohort-scenarios.xlsx

* 	Contact info to RAs
*	Sets paths: You need to change one manually!
*	Runs analysis scripts

**************
**************
**************


***********
*** RAs ***
***********

* Worked on project from Oct 2025:
* 	Victoria Garcia
*	victoria.g.4201@gmail.com


**************
*** CLAUDE ***
**************

* Claude and Andrew H. wrote task descriptions demarcated by "rounds" and "tasks" within rounds
* r10-T1 corresponds to "round 10, task 1"


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

// merge cohort id onto data
do "$do/08A-singleton-nonsingleton-cohorts.do" // sets up singleton and non-singleton cohorts

// round 10 analysis
do "$do/r10-T1-T3-baseline-regs.do"
do "$do/r10-T4-em-hcpcs-decomposition.do"
do "$do/r10-T5-spec-choice-billing-onset.do"
do "$do/r10-T6-ext-marg-embill.do"
do "$do/r10-T8-within-doc-em-billing.do"
do "$do/r10-T9-T10-billing-mix.do"
do "$do/r11-doc-specialty-change.do"

// round 11 analysis
do "$do/r11-aamc-grad-apps-matric-analysis.do"

// round 12 analysis
do "$do/r12-elective-nonelective.do"

// see old/2026-11-10 for rounds 2-7