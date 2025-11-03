
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
   global dollar_limit = 1.5
// global dollar_limit = 5000

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
	male isMD nPhyInGroup hosAff inMedicare inERX inPQRS inEHR // experYear

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
	
* GOOD:
global lower_year_limit = 2008
global upper_year_limit = 2011

// global lower_year_limit = 2000
// global upper_year_limit = 2010

* Different payment variables:
global payment_vars ///
	all ///
	emiel_betos ///
	fg_hcpcs ///
	fg_sel1 ///
	fg_sel2 ///
	fg_sel3 ///
	fg_sel4 ///
	fg_sel5

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


