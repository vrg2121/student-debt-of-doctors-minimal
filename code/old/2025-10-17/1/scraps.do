use "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", clear

recode dum_tuition2kincrease (.=0)

collapse (max) dum_tuition2kincrease, by(medSchool gradYear)

decode medSchool, generate(med_school)

replace med_school = lower(med_school)

rename gradYear grd_yr

merge 1:1 med_school grd_yr using "$git/data/original/aamc/modified/aamc-tuition"
keep if _merge == 3
drop _merge

g dummy_increase = max_tuition_increase == grd_yr

tab dummy_increase dum_tuition2kincrease, m


***


use "$dropbox/Brown Bag presentation/PrelimData/phy_time.dta", clear
drop if medSchool==222
drop if gradYear<1997
merge m:1 medSchool using "$dropbox/Brown Bag presentation/PrelimData/tuitionWIDE.dta"
keep if _merge==3
drop _merge

gen Tuition_quantile=.
forval i = 1997(1)2011{
replace Tuition_quantile=quant`i' if gradYear==`i'
}
drop quant*

forval k= 1(1)4{
forval i = 1997(1)2011{
gen tuition2kincrease`k'`i'=1 if large_tuition_abs2000_`i'==gradYear-`k' & doubllarge_tuition_abs2000_`i'!=gradYear-`k'
}
egen tuition2kincrease`k'=rowmax(tuition2kincrease`k'*)
}
*drop tuition2kincrease119* tuition2kincrease120* tuition2kincrease219* tuition2kincrease220*  tuition2kincrease319* tuition2kincrease320* tuition2kincrease419* tuition2kincrease420* 
egen dum_tuition2kincrease=rowmax(tuition2kincrease*)
recode tuition2kincrease* (.=0) if dum_tuition2kincrease==1



*** VERIFYING THIS FILE IS NOT MAGIC:
* "C:\Users\emiel\Dropbox\research proposals\medical debt and pratisioners claims\tuitionWIDE.dta"

cd "$temp"

clear all
import excel "$dropbox/Brown Bag presentation/PrelimData/medical schools.xlsx", firstrow
// save "medschool.dta", replace
merge 1:m MedicalSchoolName using "$dropbox/Brown Bag presentation/PrelimData/tuitionPANEL.dta", nogen keep(match)

*Compute tuition changes
sort MedicalSchoolName year
drop if medSchool==.
by MedicalSchoolName: gen tuitionprev=tuition[_n-1]
recode tuitionprev (0=.) if tuitionprev==0
by MedicalSchoolName: gen tuition_increase_abs=tuition-tuitionprev
by MedicalSchoolName: gen tuition_increase_perc=tuition_increase_abs/tuitionprev
by MedicalSchoolName: egen SD_tuition_perc=sd(tuition_increase_perc)
by MedicalSchoolName: egen average_tuition_perc=mean(tuition_increase_perc)


*replace tuition_increase_perc=. if tuitionprev==0
*replace tuition_increase_abs=. if tuitionprev==0

*sort MedicalSchoolName year
*by MedicalSchoolName: egen Trend_tuition=mean(tuition_increase_abs)

gen large_tuition_rel10_=year if tuition_increase_perc>0.10 & tuition_increase_perc!=.
gen large_tuition_rel15_=year if tuition_increase_perc>0.15 & tuition_increase_perc!=.
gen new_rel15_=year if tuition_increase_perc>0.15 & tuition_increase_perc!=. & tuition_increase_abs>750
replace new_rel15_ =year if tuition_increase_abs>3000 & tuition_increase_perc>0.10 & tuition_increase_perc<0.15 &year>1996

gen large_tuition_abs2000_=year if tuition_increase_abs>3499 & tuition_increase_abs!=.
gen large_tuition_abs2600_=year if tuition_increase_abs>2600 & tuition_increase_abs!=.

egen quant=xtile(tuition), n(4) by(year)

*Identify consecutive years of abnormal increases.
foreach i in large_tuition_rel10_ large_tuition_rel15_ new_rel15_ large_tuition_abs2000_ large_tuition_abs2600_{
gen doubl`i'=year if `i'[_n-1]!=. & `i'[_n+1]!=. & `i'!=.
replace doubl`i'=year if `i'[_n+1]!=. & `i'!=.
replace doubl`i'=year if `i'[_n-1]!=. & `i'!=.
}
drop if year==1996
keep medSchool OwnershipType year large_tuition_abs2000_ large_tuition_abs2600_ new_rel15_ large_tuition_rel10_ large_tuition_rel15_  quant doubllarge_tuition_rel10_ doubllarge_tuition_rel15_ doublnew_rel15_ doubllarge_tuition_abs2000_ doubllarge_tuition_abs2600_
reshape wide large_tuition_abs2000_ large_tuition_abs2600_ large_tuition_rel10_ large_tuition_rel15_ new_rel15_ quant doubllarge_tuition_rel10_ doubllarge_tuition_rel15_ doublnew_rel15_ doubllarge_tuition_abs2000_ doubllarge_tuition_abs2600_,i(medSchool) j(year)
save "tuitionWIDE",replace

clear all
use "$dropbox/Brown Bag presentation/PrelimData/phy_time.dta"
drop if medSchool==222
drop if gradYear<1997
merge m:1 medSchool using "tuitionWIDE.dta"
keep if _merge==3
drop _merge

gen Tuition_quantile=.
forval i = 1997(1)2011{
replace Tuition_quantile=quant`i' if gradYear==`i'
}
drop quant*

forval k= 1(1)4{
forval i = 1997(1)2011{
gen tuition2kincrease`k'`i'=1 if large_tuition_abs2000_`i'==gradYear-`k' & doubllarge_tuition_abs2000_`i'!=gradYear-`k'
}
egen tuition2kincrease`k'=rowmax(tuition2kincrease`k'*)
}
*drop tuition2kincrease119* tuition2kincrease120* tuition2kincrease219* tuition2kincrease220*  tuition2kincrease319* tuition2kincrease320* tuition2kincrease419* tuition2kincrease420* 
egen dum_tuition2kincrease=rowmax(tuition2kincrease*)
recode tuition2kincrease* (.=0) if dum_tuition2kincrease==1

* prep to merge with hrr data
tostring phyZip, replace
gen str5 zip5 = substr(phyZip,1,5) if length(phyZip)==9
replace zip5 = "0"+substr(phyZip,1,4) if length(phyZip)==8
replace zip5 = "00"+substr(phyZip,1,3) if length(phyZip)==7
replace zip5 = phyZip if length(phyZip)==5
replace zip5 = "0"+phyZip if length(phyZip)==4
replace zip5 = "00"+phyZip if length(phyZip)==3

* link to hrr
merge m:1 zip5 using "$dropbox/FullData/zip_hrr.dta", keep(master matched)

gen avservice2012=nServ_2012/nBene_2012
gen avservice2013=nServ_2013/nBene_2013
encode OwnershipType, gen(PublicSchool)
recode PublicSchool (1=0)
recode PublicSchool (2=1)
label define public 0 "Private" 1 "Public"
label values PublicSchool public
gen totPaid  = totPaid_2012 + totPaid_2013

foreach j in  totPaid totPaid_2012 totPaid_2013 {
gen ln`j'=ln(1+`j')
}

drop _merge // ADDED
recode dum_tuition2kincrease (.=0) // ADDED

qui compress
save "regDATASET_yannelis",replace

use "$dropbox/Brown Bag presentation/PrelimData/regDATASET_yannelis", clear

recode dum_tuition2kincrease (.=0)

drop _merge

keep npi dum_tuition2kincrease

rename dum_tuition2kincrease dum_tuition2kincrease_old

merge 1:1 npi using "regDATASET_yannelis"
assert _merge == 3
drop _merge

rename dum_tuition2kincrease dum_tuition2kincrease_new

assert dum_tuition2kincrease_old == dum_tuition2kincrease_new

count

assert r(N) > 0



***

cap log close
log using "$temp/dummies-vs-FEs.smcl", replace

set showbaselevels all

clear
set obs 1000
g id = _n

expand 10

bys id : g year = 2000 + _n

g post = year > 2005

g gender = id <= 250 | 750 <= id

g       ses = 1 if inrange(id,   1,  200)
replace ses = 2 if inrange(id, 201,  500)
replace ses = 3 if inrange(id, 501, 1000)

g       outcome = 10 + runiform() if post == 0
replace outcome = 15 + runiform() if post == 1

reghdfe outcome i.post i.gender i.ses, noabsorb
reghdfe outcome i.post, absorb(gender ses)

cap log close



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






* Note, the following will give -graduation- years with high tuition increase:
// sum gradYear if grade == 1, d

* It is not "out of range": we now look at graduation years instead of start years!


// use  "$git/data/original/aamc/modified/aamc-tuition", clear
//
// * To replicate Emiel:
// keep if inrange(grd_yr, 1997, 2011)
//
// * Simple limit:
// g delta_tuition_dummy = delta_tuition > 3499 & delta_tuition != . // 3499 is Emiel's limit
//
// keep if delta_tuition_dummy == 1
//
// keep delta_tuition_dummy med_school grd_yr
//
// bys med_school grd_yr : assert _N == 1
//
// expand 4 // medical school is four years
//
// // bys med_school grd_yr : replace grd_yr = grd_yr + _n - 1 // will ensure that all cohorts affected by increase get dummy = 1
//   
//    bys med_school grd_yr : g grade_dummy = 4 - _n + 1
//    by  med_school grd_yr : replace grd_yr = grd_yr + _n
//   
// bys med_school grd_yr : keep if _n == 1 // above can have produced duplicates
//
// rename grd_yr gradYear
//
// save "$temp/delta-tuition-dummy", replace


*** OLD ***

// * Mark where panel has no gaps:
// bys med_school (grd_yr) : g        one_year_jump = grd_yr[_n] - 1 == grd_yr[_n - 1] if _n > 1
// bys med_school (grd_yr) : egen min_one_year_jump = min(one_year_jump)
//
// drop if min_one_year_jump == 0 // i.e. if there exists a gap
//
// drop *one_year_jump
//
// * Checking so panel doesn't have any gaps now:
// bys med_school (grd_yr) : assert grd_yr[_n] - 1 == grd_yr[_n - 1] if _n > 1

* Total tuition increase:
// bys med_school (grd_yr) : g tot_tuition_increase = /// percent increase, decimal form
// 	(tot_tuition[_n] - tot_tuition[_n - 1]) / tot_tuition[_n - 1] ///
// 	if _n > 4
//
// * Find large tuition increases (maybe this should be done "within year"?):
// sum tot_tuition_increase, d
//
// g treatment = tot_tuition_increase > `r(p90)' if tot_tuition_increase != .
// g control   = treatment == 0
//
// * Above/below median tuition increase:
// sum tot_tuition_increase, d
// g aboveMed_tot_tuition_increase = tot_tuition_increase > `r(p50)' if tot_tuition_increase != .


**********************************
*** EXPORT OF SCHOOLS TO EMIEL ***
**********************************

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

bys our_med_school : keep if _n == 1

keep our_med_school med_school source

save "$temp/schools_in_sample", replace


*********************************************
*** EXPORT SCHOOLS WITH INCREASE TO EMIEL ***
*********************************************

use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

assert start_yr == (grd_yr - ($med_school_length - 1))

keep if delta_tuition_dummy == 1

bys med_school start_yr grade : keep if _n == 1

keep med_school start_yr grade source

g increase_year = start_yr + (grade - 1)

bys med_school increase_year : keep if _n == 1

keep  med_school increase_year source
order med_school increase_year source

save "$temp/5000_increase_schools_in_sample", replace
