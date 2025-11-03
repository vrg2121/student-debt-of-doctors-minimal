
*******************
*** SET GLOBALS ***
*******************


*** DIRECTORIES ***

global dropbox ///
	"/Users/simonalmerstromprzybyl/new-dropbox/Dropbox/Student Debt of Doctors"

global fang_gong_replication ///
	"$dropbox/Tuition Data/Fang & Gong (AER 2017) – Replication package/119565-V1"

global git ///
	"$dropbox/Tuition Data/simon/student-debt-of-doctors"
	
global temp ///
	"$git/data/working/temp"
	
cd "$temp"


*** SCHEMES ***

set scheme white_tableau // ssc install schemepack


*** GLOBALS ***

// global dollar_limit = 2000
// global dollar_limit = 3499
   global dollar_limit = 5000

global   med_school_length = 4
global extra_window_length = 2
   
global emiel_betos ///
	AA ///
	EB EC EE EH EI EM EN EO ER EV EX ///
	IC IM IN IS IU IX ///
	NA ///
	PC PE PG PM PO PS PV ///
	RB RD RH RI RR RT RX ///
	TA TC TN TP TX

global min_nr_obs = 10^4

global main_controls ///
	male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR

global FEs ///
	hrr phySpec grd_yr Tuition_quantile groupPAC grd_yrXphyspec

global FEs_list ///
		`" "hrr phySpec" "hrr phySpec grd_yr" "hrr phySpec grd_yr Tuition_quantile" "phySpec grd_yr Tuition_quantile groupPAC" "hrr grd_yrXphyspec" "hrr grd_yrXphyspec Tuition_quantile" "'
	
global specializations ///
	chiro_school ///
	osteo_school ///
	optom_school ///
	podia_school ///
	medic_school
	
* To use more data:
// global lower_year_limit = 1997
// global upper_year_limit = 2024
	
* To replicate Emiel:
global lower_year_limit = 1997
global upper_year_limit = 2011

* Different payment variables:
global payment_vars ///
	all ///
	emiel_betos ///
	fg_hcpcs ///
	fg_sel1 ///
	fg_sel2 ///
	fg_sel3 ///
	fg_sel4

* Selected payment variables:
global sel_payment_vars ///
	fg_sel1 ///
	fg_sel2 ///
	fg_sel3

	
*** PROGRAMS ***

cap program drop runRegressions
program define   runRegressions

	args outcome dummy nCode nCodeEM
	
	local controls $main_controls PublicSchool `nCode' `nCodeEM'
	
	eststo clear
	
	qui: eststo: reghdfe `outcome' `dummy' `controls', ///
		cluster(hrr) a(hrr phySpec)
		
	qui: eststo: reghdfe `outcome' `dummy' `controls', ///
		cluster(hrr) a(hrr phySpec grd_yr)
	
	qui: eststo: reghdfe `outcome' `dummy' `controls', ///
		cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
		
	qui: eststo: reghdfe `outcome' `dummy' `controls', ///
		cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
		
	qui: eststo: reghdfe `outcome' `dummy' `controls', ///
		cluster(hrr) a(hrr grd_yrXphyspec)
		
	qui: eststo: reghdfe `outcome' `dummy' `controls', ///
		cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
		
	esttab est*, keep(`dummy') se star(* 0.10 ** 0.05 *** 0.01)
	
end

cap program drop runRegressionsInteract
program define   runRegressionsInteract

	args outcome dummy interact nCode nCodeEM
	
	local controls $main_controls PublicSchool `nCode' `nCodeEM'
	
	eststo clear
	
	eststo: reghdfe `outcome' `dummy'##`interact' `controls', ///
		cluster(hrr) a(hrr phySpec)
		
	eststo: reghdfe `outcome' `dummy'##`interact' `controls', ///
		cluster(hrr) a(hrr phySpec grd_yr)
	
	eststo: reghdfe `outcome' `dummy'##`interact' `controls', ///
		cluster(hrr) a(hrr phySpec grd_yr Tuition_quantile)
		
	eststo: reghdfe `outcome' `dummy'##`interact' `controls', ///
		cluster(hrr) a(    phySpec grd_yr Tuition_quantile groupPAC)
		
	eststo: reghdfe `outcome' `dummy'##`interact' `controls', ///
		cluster(hrr) a(hrr grd_yrXphyspec)
		
	eststo: reghdfe `outcome' `dummy'##`interact' `controls', ///
		cluster(hrr) a(hrr grd_yrXphyspec Tuition_quantile)
		
	esttab est*, keep(1.`dummy'#1.`interact') se star(* 0.10 ** 0.05 *** 0.01)
	
end


*** INVESTIGATE SCB VARIABLES ***

// net install registream, from("https://registream.com/install/stata")

// autolabel lookup carb random_var yrkarbtyp kaross, domain(scb) lang(swe)

// autolabel variables, domain(scb) lang(swe)

// autolabel values astsni92, domain(scb) lang(swe)


*** TO DO:

*	Discuss inclusion of health insurance with Emiel and Marieke
*	Go over matching in Excel again
* 	Add associations for alternative medicine schools
* 	Match with IPEDS for specializations
*	Create shorter keys?

*	Keep track of changes in cost measures
*	Define total cost as sum during years of study (merge on grd_yr, grd_yr - 1, etc)
*	Need to know the times of different educations:
*		a) key for that, google (and Emiel's mail)?
*		b) info in panel about type of degree, school..?

*	Sanity checks (tuition cost per treatment/control etc)?

*	Ask Emiel and Marieke:

*	How do you want to define treatment?
*		Tuition increase above e.g. P90 in school/doctor panel?
*		Fixed amount, Andres etc..?

* 	From 2002, health insurance starts being included
*
*	Ask Emiel:
*		Panel is identified by (npi, year)?
* 		I added 2000 to year -- correct?
*		grd_yr vs gradYear?
*		Main outcome variable: total_payments?
*
*	Look at the panels together
*
*
*	1) General discussion about:
*		a) definition of treatment group: percent increase vs dollar amount (Andres?)
*		b) main outcome variable from CMS panel
*		c) overall thoughts (my mail etc)

*	2) Questions:
*		Emiel: Panel is identified by (npi, year)?
* 		Emiel: I added 2000 to year -- correct?
*		Emiel: grd_yr vs gradYear?
*		Emiel: Main outcome variable: total_payments?
*		Both: More data?

*	3) Look at the panels together
*	4) Look at the plots together
*	5) To-do for the following week

* Except for max increase, also require minimum dollar amount increase?



* "Delete treatment group 1", maybe?

* Run regression: total payments = treatment_2 + treatment_3 + year_fe + school_fe
* 	Actually, check Emiel's regressions!

* "N" = nr of claims

* IPEDS data seems different before 2000 or 1999?

* https://nces.ed.gov/ipeds/datacenter/DataFiles.aspx?year=2023





* From: https://github.com/sergiocorreia/ivreghdfe

// * Install ftools (remove program if it existed previously)
// cap ado uninstall ftools
// net install ftools, from("https://raw.githubusercontent.com/sergiocorreia/ftools/master/src/")
//
// * Install reghdfe
// cap ado uninstall reghdfe
// net install reghdfe, from("https://raw.githubusercontent.com/sergiocorreia/reghdfe/master/src/")
//
// * Install ivreg2, the core package
// cap ado uninstall ivreg2
// ssc install ivreg2
//
// * Finally, install this package
// cap ado uninstall ivreghdfe
// net install ivreghdfe, from("https://raw.githubusercontent.com/sergiocorreia/ivreghdfe/master/src/")


// levelsof grade,  local(grade_levels)
// foreach level of local grade_levels {
//	
// 	g   grade_`level' = grade == `level'
// 	tab grade_`level'   grade, m
//	
// }


* Meeting 2025-03-25:
*	One-off? Possibly contributes stronger results: excluding low tuition individuals and including high individuals?
*	grd_yr vs gradYear?
* 	Access to other Dropbox folders -- "C:\Users\emiel\Dropbox\research proposals\medical debt and pratisioners claims"

* For next meeting, also remember to mention:
*	"Tuition" vs wider measure -- REMEMBER TO MENTION THIS IN MAIL WITH PLOTS!
*	How did Emiel do the name matching?




