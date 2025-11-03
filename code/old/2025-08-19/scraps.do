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
