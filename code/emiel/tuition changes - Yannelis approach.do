*In our empirical strategy we therefore compare outcomes for students who are enrolled in dfferent cohorts at a school that increases its tuition by more than $1,000.
set more off
clear all
cd "C:\Users\emiel\Dropbox\research proposals\medical debt and pratisioners claims\"

*data AAMC tuition per medical school
qui forval i = 2007(1)2011{
import excel "Tution and Student Fees Report, 2007-2008 through 2011-2012.xlsx", sheet("`i'") firstrow
keep if ResidenceStatus=="Resident" & CostType=="Tuition"
keep MedicalSchoolName ShortName OwnershipType ReportedCost
rename ReportedCost tuition1
gen tuition=real(tuition1)
gen year=`i'
save "tuition`i'.dta", replace
clear
}

qui forval i = 2002(1)2006{
import excel "Tution and Student Fees Report, 2002-2003 through 2006-2007.xlsx", sheet("`i'") firstrow
keep if ResidenceStatus=="Resident" & CostType=="Tuition"
keep MedicalSchoolName ShortName OwnershipType ReportedCost
rename ReportedCost tuition1
gen tuition=real(tuition1)
gen year=`i'
save "tuition`i'.dta", replace
clear
}

qui forval i = 1996(1)2001{
import excel "Tution and Student Fees Report, 1996-1997 through 2001-2002.xlsx", sheet("`i'") firstrow
keep if ResidenceStatus=="Resident" & CostType=="Tuition"
keep MedicalSchoolName ShortName OwnershipType ReportedCost
rename ReportedCost tuition1
gen tuition=real(tuition1)
gen year=`i'
save "tuition`i'.dta", replace
clear
}

*merge to make panel of tuitions*
* can career concerns explain negative findings?*
clear
use "tuition1996.dta" 
forval i = 1997(1)2011{
append using tuition`i'.dta
}
destring tuition, replace
save "tuitionPANEL",replace

clear all
import excel "medical schools.xlsx", firstrow
save "medschool.dta", replace
merge 1:m MedicalSchoolName using "tuitionPANEL.dta", nogen keep(match)

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
use "phy_time.dta"
drop if medSchool==222
drop if gradYear<1997
merge m:1 medSchool using "C:\Users\emiel\Dropbox\research proposals\medical debt and pratisioners claims\tuitionWIDE.dta"
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
merge m:1 zip5 using "zip_hrr.dta", keep(master matched)

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
qui compress
save "regDATASET_yannelis",replace

clear all
use "regDATASET_yannelis"
recode dum_tuition2kincrease (.=0)
forval i=1(1)4{
gen tuitionNR`i'=`i' if tuition2kincrease`i'==1
*gen tuition_increaseX`i'=medSchool*tuition2kincrease`i'
}
egen tuitionNR=rowmean(tuitionNR*)
recode  tuitionNR (.=0)
gen dum_tuition2kXnr=dum_tuition2kincrease*tuitionNR

egen impflag0=rowmax(impFlag0_2012 impFlag0_2013)
egen impflag1=rowmax(impFlag1_2012 impFlag1_2013)
egen impflag2=rowmax(impFlag2_2012 impFlag2_2013)

egen max_nBene=rowmax(nBene_2012 nBene_2013)
gen avservice=(nServ_2012+nServ_2013)/(max_nBene)
gen avservice1=(nServ_2012+nServ_2013)/(nBene_2012+nBene_2013)
gen avservice2=((nServ_2012+nServ_2013)/2)/(max_nBene)

egen gradyearXphyspec=group(phySpec gradYear)
egen gradyearXhrr=group(hrr gradYear)
gen lntotHrsPerWk_2012=ln(totHrsPerWk_2012)
gen lntotHrsPerWk_2013=ln(totHrsPerWk_2013) 

recode tuitionNR* (.=0)
gen tuitionNR12=tuitionNR1+tuitionNR2
gen tuitionNR34=tuitionNR3+tuitionNR4

gen dum_tuition2kXNR=dum_tuition2kincrease*tuitionNR34

gen dum_tuition2kXnr1=dum_tuition2kincrease*tuitionNR1
gen dum_tuition2kXnr2=dum_tuition2kincrease*tuitionNR2
gen dum_tuition2kXnr3=dum_tuition2kincrease*tuitionNR3
gen dum_tuition2kXnr4=dum_tuition2kincrease*tuitionNR4
********************************************************************************
******************************MAIN TABLE****************************************
********************************************************************************

*keep if totHrsPerWk_2012>0 | totHrsPerWk_2013>0
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012  nCodeEM_2012  PublicSchool
*totHrsPerWk_2012 totHrsPerWk_2013
foreach j in  totPaid_2012 {
eststo clear
qui: eststo: reghdfe `j' dum_tuition2kincrease  `controls',a(hrr phySpec) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease  `controls',a(hrr phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease  `controls',a(hrr phySpec gradYear Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease  `controls',a(phySpec gradYear groupPAC Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease  `controls',a(hrr gradyearXphyspec) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease  `controls',a(hrr gradyearXphyspec  Tuition_quantile) cluster(hrr)
esttab est*, keep(dum_tuition2kincrease) se star(* 0.10 ** 0.05 *** 0.01)
}

*how much increase in dollar terms? --> X 1000 interpretation!!!

*if 1 doctor in practice: physciance effect stronger (partner)
reghdfe totPaid_2012 dum_tuition2kincrease  male isMD experYear hosAff inMedicare inERX inPQRS inEHR nCode_2012  nCodeEM_2012  PublicSchool if nPhyInGroup==1,a(hrr gradyearXphyspec) cluster(hrr)
*effects stroger, but extremely high (35k-45k)

gen lnNdoc=ln(1+nPhyInGroup)
gen lnNdocXDum=lnNdoc*dum_tuition2kincrease 
gen doc5=1 if nPhyInGroup<4
recode doc5 (.=0)
gen doc5XDum=doc5*dum_tuition2kincrease 

reghdfe totPaid_2012 doc5XDum dum_tuition2kincrease  male isMD experYear hosAff inMedicare inERX inPQRS inEHR nCode_2012 doc5  nCodeEM_2012  PublicSchool,a(hrr phySpec ) cluster(hrr)
reghdfe totPaid_2012 doc5XDum dum_tuition2kincrease  male isMD experYear hosAff inMedicare inERX inPQRS inEHR nCode_2012 doc5 nCodeEM_2012  PublicSchool,a(hrr phySpec gradYear ) cluster(hrr)
reghdfe totPaid_2012 doc5XDum dum_tuition2kincrease  male isMD experYear hosAff inMedicare inERX inPQRS inEHR nCode_2012 doc5 nCodeEM_2012  PublicSchool,a(hrr phySpec gradYear Tuition_quantile) cluster(hrr)


reghdfe totPaid_2012 lnNdocXDum dum_tuition2kincrease  male isMD experYear hosAff inMedicare inERX inPQRS inEHR nCode_2012 lnNdoc  nCodeEM_2012  PublicSchool,a(hrr phySpec ) cluster(hrr)
reghdfe totPaid_2012 lnNdocXDum dum_tuition2kincrease  male isMD experYear hosAff inMedicare inERX inPQRS inEHR nCode_2012 lnNdoc nCodeEM_2012  PublicSchool,a(hrr phySpec gradYear ) cluster(hrr)
reghdfe totPaid_2012 lnNdocXDum dum_tuition2kincrease  male isMD experYear hosAff inMedicare inERX inPQRS inEHR nCode_2012 lnNdoc nCodeEM_2012  PublicSchool,a(hrr phySpec gradYear Tuition_quantile) cluster(hrr)
reghdfe totPaid_2012 lnNdocXDum dum_tuition2kincrease  male isMD experYear hosAff inMedicare inERX inPQRS inEHR nCode_2012 lnNdoc nCodeEM_2012  PublicSchool,a(hrr gradyearXphyspec) cluster(hrr)



********************************************************************************
**********************Interaction TABLE (Exposure)******************************
********************************************************************************

*local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012  nCodeEM_2012  
*PublicSchool 
*totHrsPerWk_2012 totHrsPerWk_2013
preserve
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012  nCodeEM_2012  PublicSchool 
foreach j in  totPaid_2012 {
eststo clear
*qui: eststo: reghdfe `j' dum_tuition2kincrease dum_tuition2kXnr  `controls',a(hrr Tuition_quantile gradYear) cluster(hrr)
*qui: eststo: reghdfe `j' dum_tuition2kincrease dum_tuition2kXnr  `controls',a(phySpec Tuition_quantile gradYear) cluster(hrr)
*qui: eststo: reghdfe `j' dum_tuition2kincrease dum_tuition2kXnr  `controls',a(phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease dum_tuition2kXnr `controls',a(hrr) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease dum_tuition2kXnr `controls',a(medSchool) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease dum_tuition2kXnr `controls',a(hrr phySpec) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease dum_tuition2kXnr `controls',a(hrr phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease dum_tuition2kXnr `controls',a(hrr phySpec gradYear Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease dum_tuition2kXnr `controls',a(hrr gradyearXphyspec) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease dum_tuition2kXnr `controls',a(hrr gradyearXphyspec  Tuition_quantile) cluster(hrr)
esttab est*, keep(dum_tuition2kincrease dum_tuition2kXnr )  star(* 0.10 ** 0.05 *** 0.01)
}
restore

local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012  nCodeEM_2012  PublicSchool
preserve
*keep if dum_tuition2kincrease ==1
foreach j in  totPaid_2012 {
eststo clear
qui: eststo: reghdfe `j'  dum_tuition2kXNR dum_tuition2kincrease   `controls',a(hrr Tuition_quantile gradYear) cluster(hrr)
qui: eststo: reghdfe `j'  dum_tuition2kXNR dum_tuition2kincrease `controls',a(phySpec Tuition_quantile gradYear) cluster(hrr)
qui: eststo: reghdfe `j'   dum_tuition2kXNR dum_tuition2kincrease  `controls',a(phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j'    dum_tuition2kXNR dum_tuition2kincrease  `controls',a(hrr phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j'  dum_tuition2kXNR dum_tuition2kincrease  `controls',a(hrr phySpec gradYear Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j'  dum_tuition2kXNR dum_tuition2kincrease  `controls',a(phySpec gradYear groupPAC Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j'   dum_tuition2kXNR dum_tuition2kincrease  `controls',a(gradyearXphyspec) cluster(hrr)
qui: eststo: reghdfe `j'    dum_tuition2kXNR dum_tuition2kincrease  `controls',a(hrr gradyearXphyspec) cluster(hrr)
qui: eststo: reghdfe `j'    dum_tuition2kXNR dum_tuition2kincrease  `controls',a(hrr gradyearXphyspec  Tuition_quantile) cluster(hrr)
esttab est*, keep( dum_tuition2kXNR dum_tuition2kincrease )  star(* 0.10 ** 0.05 *** 0.01)
}
restore

local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012  nCodeEM_2012  PublicSchool 
preserve
foreach j in  totPaid_2012 {
eststo clear
qui: eststo: reghdfe `j'  dum_tuition2kXNR tuitionNR12 tuitionNR34  `controls',a(hrr Tuition_quantile gradYear) cluster(hrr)
qui: eststo: reghdfe `j'  dum_tuition2kXNR tuitionNR12 tuitionNR34 `controls',a(phySpec Tuition_quantile gradYear) cluster(hrr)
qui: eststo: reghdfe `j'   dum_tuition2kXNR tuitionNR12 tuitionNR34  `controls',a(phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j'    dum_tuition2kXNR tuitionNR12 tuitionNR34  `controls',a(hrr phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j'  dum_tuition2kXNR tuitionNR12 tuitionNR34  `controls',a(hrr phySpec gradYear Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j'  dum_tuition2kXNR tuitionNR12 tuitionNR34  `controls',a(phySpec gradYear groupPAC Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j'   dum_tuition2kXNR tuitionNR12 tuitionNR34  `controls',a(gradyearXphyspec) cluster(hrr)
qui: eststo: reghdfe `j'    dum_tuition2kXNR tuitionNR12 tuitionNR34  `controls',a(hrr gradyearXphyspec) cluster(hrr)
qui: eststo: reghdfe `j'    dum_tuition2kXNR tuitionNR12 tuitionNR34  `controls',a(hrr gradyearXphyspec  Tuition_quantile) cluster(hrr)
esttab est*, keep( dum_tuition2kXNR tuitionNR12 tuitionNR34 )  star(* 0.10 ** 0.05 *** 0.01)
}
restore

preserve
*keep if dum_tuition2kincrease==1
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012  nCodeEM_2012  PublicSchool 
*totHrsPerWk_2012 totHrsPerWk_2013
foreach j in  totPaid_2012 {
eststo clear
qui: eststo: reghdfe `j' dum_tuition2kincrease tuitionNR12 tuitionNR34  `controls',a(hrr phySpec) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease tuitionNR12 tuitionNR34  `controls',a(hrr phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease tuitionNR12 tuitionNR34  `controls',a(hrr phySpec gradYear Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease tuitionNR12 tuitionNR34  `controls',a(phySpec gradYear groupPAC Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease tuitionNR12 tuitionNR34  `controls',a(hrr gradyearXphyspec) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease tuitionNR12 tuitionNR34  `controls',a(hrr gradyearXphyspec  Tuition_quantile) cluster(hrr)
esttab est*, keep(dum_tuition2kincrease tuitionNR*)  star(* 0.10 ** 0.05 *** 0.01)
}
restore


preserve
*keep if dum_tuition2kincrease==1
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012  nCodeEM_2012  PublicSchool 
*totHrsPerWk_2012 totHrsPerWk_2013
foreach j in  totPaid_2012 {
eststo clear
qui: eststo: reghdfe `j' dum_tuition2kincrease tuitionNR1 tuitionNR2 tuitionNR3 tuitionNR4 `controls',a(hrr phySpec) cluster(hrr)
qui: eststo: reghdfe `j'  dum_tuition2kincrease tuitionNR1 tuitionNR2 tuitionNR3 tuitionNR4 `controls',a(hrr phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease tuitionNR1 tuitionNR2 tuitionNR3 tuitionNR4 `controls',a(hrr phySpec gradYear Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease tuitionNR1 tuitionNR2 tuitionNR3 tuitionNR4 `controls',a(phySpec gradYear groupPAC Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j'  dum_tuition2kincrease tuitionNR1 tuitionNR2 tuitionNR3 tuitionNR4  `controls',a(hrr gradyearXphyspec) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease tuitionNR1 tuitionNR2 tuitionNR3 tuitionNR4 `controls',a(hrr gradyearXphyspec  Tuition_quantile) cluster(hrr)
esttab est*, keep(dum_tuition2kincrease tuitionNR*)  star(* 0.10 ** 0.05 *** 0.01)
}
restore

preserve
*keep if tuitionNR34==0
*keep if totHrsPerWk_2012>0 | totHrsPerWk_2013>0
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012  nCodeEM_2012  PublicSchool 
*totHrsPerWk_2012 totHrsPerWk_2013
foreach j in  totPaid_2012 {
eststo clear
qui: eststo: reghdfe `j' tuitionNR12  `controls' ,a(hrr phySpec) cluster(hrr)
qui: eststo: reghdfe `j' tuitionNR12  `controls' ,a(hrr phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j' tuitionNR12  `controls' ,a(hrr phySpec gradYear Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' tuitionNR12  `controls' ,a(phySpec gradYear groupPAC Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' tuitionNR12  `controls' ,a(hrr gradyearXphyspec) cluster(hrr)
qui: eststo: reghdfe `j' tuitionNR12  `controls' ,a(hrr gradyearXphyspec  Tuition_quantile) cluster(hrr)
esttab est*, keep(tuitionNR12)  star(* 0.10 ** 0.05 *** 0.01)
}
restore
preserve
*keep if tuitionNR12==0
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012  nCodeEM_2012  PublicSchool 
foreach j in  totPaid_2012 {
eststo clear
qui: eststo: reghdfe `j' tuitionNR34  `controls',a(hrr phySpec) cluster(hrr)
qui: eststo: reghdfe `j' tuitionNR34  `controls',a(hrr phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j' tuitionNR34  `controls',a(hrr phySpec gradYear Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' tuitionNR34  `controls',a(phySpec gradYear groupPAC Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' tuitionNR34  `controls',a(hrr gradyearXphyspec) cluster(hrr)
qui: eststo: reghdfe `j' tuitionNR34  `controls',a(hrr gradyearXphyspec  Tuition_quantile) cluster(hrr)
esttab est*, keep(tuitionNR34)  star(* 0.10 ** 0.05 *** 0.01)
}
restore


preserve
*keep if totHrsPerWk_2012>0 | totHrsPerWk_2013>0
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012  nCodeEM_2012  PublicSchool 
*totHrsPerWk_2012 totHrsPerWk_2013
keep if dum_tuition2kincrease==1
foreach j in  totPaid_2012 {
eststo clear
qui: eststo: reghdfe `j' tuitionNR12 tuitionNR34 `controls' ,a(hrr phySpec gradYear Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' tuitionNR1 tuitionNR2 tuitionNR3 tuitionNR4 `controls' ,a(hrr phySpec gradYear Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' tuitionNR1 tuitionNR2 tuitionNR3 tuitionNR4 `controls' ,a(medSchool hrr phySpec gradYear Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' tuitionNR1 tuitionNR2 tuitionNR3 tuitionNR4 `controls' ,a(medSchool hrr gradYear) cluster(hrr)
*qui: eststo: reghdfe `j' tuitionNR1 tuitionNR2 tuitionNR3 tuitionNR4 `controls' ,a(hrr phySpec) cluster(hrr)
*qui: eststo: reghdfe `j' tuitionNR1 tuitionNR2 tuitionNR3  tuitionNR4  `controls' ,a(hrr phySpec gradYear) cluster(hrr)
*qui: eststo: reghdfe `j'  tuitionNR1 tuitionNR2 tuitionNR3  tuitionNR4  `controls' ,a(hrr phySpec gradYear Tuition_quantile) cluster(hrr)
*qui: eststo: reghdfe `j' tuitionNR1 tuitionNR2 tuitionNR3  tuitionNR4  `controls' ,a(hrr gradyearXphyspec) cluster(hrr)
*qui: eststo: reghdfe `j' tuitionNR1 tuitionNR2 tuitionNR3  tuitionNR4  `controls' ,a(hrr gradyearXphyspec  Tuition_quantile) cluster(hrr)
esttab est*, keep(tuitionNR*)  star(* 0.10 ** 0.05 *** 0.01)
}
restore

*keep if totHrsPerWk_2012>0 | totHrsPerWk_2013>0
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012  nCodeEM_2012  PublicSchool 
*totHrsPerWk_2012 totHrsPerWk_2013
foreach j in  totPaid_2012 {
eststo clear
qui: eststo: reghdfe `j' dum_tuition2kincrease dum_tuition2kXnr `controls' ,a(hrr) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease dum_tuition2kXnr `controls' ,a(phySpec) cluster(hrr)
qui: eststo: reghdfe `j'  dum_tuition2kincrease dum_tuition2kXnr `controls' ,a(hrr phySpec Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease dum_tuition2kXnr `controls' ,a(hrr phySpec) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease dum_tuition2kXnr `controls'  ,a(hrr phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j'  dum_tuition2kincrease dum_tuition2kXnr `controls' ,a(hrr phySpec gradYear Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease  dum_tuition2kXnr `controls'  ,a(hrr gradyearXphyspec) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease  dum_tuition2kXnr `controls'  ,a(hrr gradyearXphyspec  Tuition_quantile) cluster(hrr)
esttab est*, keep(dum_tuition2kincrease dum_tuition2kXnr)  star(* 0.10 ** 0.05 *** 0.01)
}


*keep if totHrsPerWk_2012>0 | totHrsPerWk_2013>0
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012  nCodeEM_2012  PublicSchool 
*totHrsPerWk_2012 totHrsPerWk_2013
foreach j in  totPaid_2012 {
eststo clear
qui: eststo: reghdfe `j' dum_tuition2kincrease dum_tuition2kXnr `controls' ,a(hrr phySpec) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease dum_tuition2kXnr `controls' ,a(hrr phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j'  dum_tuition2kincrease dum_tuition2kXnr `controls' ,a(hrr phySpec gradYear Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease  dum_tuition2kXnr `controls' ,a(hrr gradyearXphyspec) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kincrease  dum_tuition2kXnr `controls' ,a(hrr gradyearXphyspec  Tuition_quantile) cluster(hrr)
esttab est*, keep(dum_tuition2kincrease dum_tuition2kXnr)  star(* 0.10 ** 0.05 *** 0.01)
}


foreach j in totPaid_2013 {
eststo clear
qui: eststo: reghdfe `j' dum_tuition2kXnr `controls' ,a(hrr medSchool) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kXnr `controls'  ,a(hrr medSchool gradYear) cluster(hrr)
qui: eststo: reghdfe `j' dum_tuition2kXnr `controls'  ,a(hrr medSchool gradYear) cluster(hrr gradYear)
esttab est*, keep(dum_tuition2kXnr)  star(* 0.10 ** 0.05 *** 0.01)
}


*****

foreach j in  totPaid totPaid_2012 totPaid_2013 avservice2012 avservice2013 impFlag0_2012 impFlag0_2013 impflag0 avservice avservice1 avservice2{
eststo clear
qui: eststo: reghdfe `j' tuition2kincrease* `controls' ,a(hrr medSchool) cluster(hrr)
qui: eststo: reghdfe `j' tuition2kincrease* `controls' ,a(hrr medSchool gradYear) cluster(hrr)
qui: eststo: reghdfe `j'  tuition2kincrease* `controls' ,a(hrr medSchool gradYear Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j'  tuition2kincrease* `controls' if dum_tuition2kincrease==1,a(gradyearXhrr) cluster(hrr)
qui: eststo: reghdfe `j'  tuition2kincrease* `controls' if dum_tuition2kincrease==1,a(gradyearXhrr  medSchool) cluster(hrr)
esttab est*, keep(tuition2kincrease*)  star(* 0.10 ** 0.05 *** 0.01)
}



restore













*****************************************************************************************


clear all
use "phy_time.dta"
drop if medSchool==222
drop if gradYear<1997
merge m:1 medSchool using "C:\Users\emiel\Dropbox\research proposals\medical debt and pratisioners claims\tuitionWIDE.dta"
keep if _merge==3
drop _merge

gen Tuition_quantile=.
forval i = 1997(1)2011{
replace Tuition_quantile=quant`i' if gradYear==`i'
}
drop quant*

forval i = 1997(1)2011{
gen tuitionABS2kCHANGE`i'=1 if large_tuition_abs2000_`i'==gradYear-1 | large_tuition_abs2000_`i'==gradYear-2 | large_tuition_abs2000_`i'==gradYear-3
}
egen tuitionABS2kCHANGE=rowmax(tuitionABS2kCHANGE*)
recode tuitionABS2kCHANGE (.=0)

forval i = 1997(1)2011{
gen tuitionABS26kCHANGE`i'=1 if large_tuition_abs2600_`i'==gradYear-1 | large_tuition_abs2600_`i'==gradYear-2 | large_tuition_abs2600_`i'==gradYear-3
}
egen tuitionABS26kCHANGE=rowmax(tuitionABS26kCHANGE*)
recode tuitionABS26kCHANGE (.=0)

forval i = 1997(1)2011{
gen tuitionREL10CHANGE`i'=1 if large_tuition_rel10_`i'==gradYear-1 | large_tuition_rel10_`i'==gradYear-2 | large_tuition_rel10_`i'==gradYear-3
}
egen tuitionREL10CHANGE=rowmax(tuitionREL10CHANGE*)
recode tuitionREL10CHANGE (.=0)

forval i = 1997(1)2011{
gen tuitionREL15CHANGE`i'=1 if large_tuition_rel15_`i'==gradYear-1 | large_tuition_rel15_`i'==gradYear-2 | large_tuition_rel15_`i'==gradYear-3
}
egen tuitionREL15CHANGE=rowmax(tuitionREL15CHANGE*)
recode tuitionREL15CHANGE (.=0)

forval i = 1997(1)2011{
gen new_rel15_CHANGE`i'=1 if new_rel15_`i'==gradYear-1 | new_rel15_`i'==gradYear-2 | new_rel15_`i'==gradYear-3
}
egen new_rel15_CHANGE=rowmax(new_rel15_CHANGE*)
recode new_rel15_CHANGE (.=0)

********************************************************************************
/*
forval i = 1997(1)2011{
drop if doubllarge_tuition_rel10_`i'==gradYear-1 | doubllarge_tuition_rel10_`i'==gradYear-2 | doubllarge_tuition_rel10_`i'==gradYear-3
gen dtuitionREL10CHANGE`i'=tuitionREL10CHANGE`i'
}
egen dtuitionREL10CHANGE=rowmax(dtuitionREL10CHANGE*)
recode dtuitionREL10CHANGE (.=0)
*drop dtuitionABS26kCHANGE19* dtuitionABS26kCHANGE20* tuitionABS2kCHANGE19* tuitionABS2kCHANGE20* tuitionABS26kCHANGE19* tuitionABS26kCHANGE20* tuitionREL10CHANGE19* tuitionREL10CHANGE20* tuitionREL15CHANGE19* tuitionREL15CHANGE20* new_rel15_CHANGE19*  new_rel15_CHANGE20* large_tuition_abs2000_* large_tuition_abs2600_*  large_tuition_rel10_* new_rel15_* large_tuition_rel15_*

forval i = 1997(1)2011{
drop if doubllarge_tuition_abs2600_`i'==gradYear-1 | doubllarge_tuition_abs2600_`i'==gradYear-2 | doubllarge_tuition_abs2600_`i'==gradYear-3
gen dtuitionABS26kCHANGE`i'=tuitionABS26kCHANGE`i'
}
egen dtuitionABS26kCHANGE=rowmax(dtuitionABS26kCHANGE*)
recode dtuitionABS26kCHANGE (.=0)
drop dtuitionABS26kCHANGE19* dtuitionABS26kCHANGE20* tuitionABS2kCHANGE19* tuitionABS2kCHANGE20* tuitionABS26kCHANGE19* tuitionABS26kCHANGE20* tuitionREL10CHANGE19* tuitionREL10CHANGE20* tuitionREL15CHANGE19* tuitionREL15CHANGE20* new_rel15_CHANGE19*  new_rel15_CHANGE20* large_tuition_abs2000_* large_tuition_abs2600_*  large_tuition_rel10_* new_rel15_* large_tuition_rel15_*
*/

forval i = 1997(1)2011{
drop if doubllarge_tuition_abs2000_`i'==gradYear-1 | doubllarge_tuition_abs2000_`i'==gradYear-2 | doubllarge_tuition_abs2000_`i'==gradYear-3
gen dtuitionABS2kCHANGE`i'=tuitionABS2kCHANGE`i'
*replace dtuitionABS2kCHANGE`i'=. if doubllarge_tuition_abs2000_`i'==gradYear-1 | doubllarge_tuition_abs2000_`i'==gradYear-2 | doubllarge_tuition_abs2000_`i'==gradYear-3
}
egen dtuitionABS2kCHANGE=rowmax(dtuitionABS2kCHANGE*)
recode dtuitionABS2kCHANGE (.=0)
drop dtuitionABS2kCHANGE19* dtuitionABS2kCHANGE20* tuitionABS2kCHANGE19* tuitionABS2kCHANGE20* tuitionABS26kCHANGE19* tuitionABS26kCHANGE20* tuitionREL10CHANGE19* tuitionREL10CHANGE20* tuitionREL15CHANGE19* tuitionREL15CHANGE20* new_rel15_CHANGE19*  new_rel15_CHANGE20* large_tuition_abs2000_* large_tuition_abs2600_*  large_tuition_rel10_* new_rel15_* large_tuition_rel15_*

* prep to merge with hrr data
tostring phyZip, replace
gen str5 zip5 = substr(phyZip,1,5) if length(phyZip)==9
replace zip5 = "0"+substr(phyZip,1,4) if length(phyZip)==8
replace zip5 = "00"+substr(phyZip,1,3) if length(phyZip)==7
replace zip5 = phyZip if length(phyZip)==5
replace zip5 = "0"+phyZip if length(phyZip)==4
replace zip5 = "00"+phyZip if length(phyZip)==3

* link to hrr
merge m:1 zip5 using "zip_hrr.dta", keep(master matched)

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

*compress
save "regDATASET_nodoubles",replace

clear all
use "regDATASET_nodoubles"
*gen PublicXdtuitionABS26kCHANGE=PublicSchool*dtuitionABS26kCHANGE

egen impflag0=rowmax(impFlag0_2012 impFlag0_2013)
egen impflag1=rowmax(impFlag1_2012 impFlag1_2013)
egen impflag2=rowmax(impFlag2_2012 impFlag2_2013)

egen max_nBene=rowmax(nBene_2012 nBene_2013)
gen avservice=(nServ_2012+nServ_2013)/(max_nBene)
gen avservice1=(nServ_2012+nServ_2013)/(nBene_2012+nBene_2013)
gen avservice2=((nServ_2012+nServ_2013)/2)/(max_nBene)

keep if totHrsPerWk_2012>0 | totHrsPerWk_2013>0
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012 nCode_2013 nCodeEM_2012 nCodeEM_2013 PublicSchool  totHrsPerWk_2012 totHrsPerWk_2013
foreach k in dtuitionABS2kCHANGE{
foreach j in  totPaid totPaid_2012 totPaid_2013 {
eststo clear
qui: eststo: reghdfe `j' `k'  `controls',a(medSchool Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr medSchool Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr medSchool Tuition_quantile) cluster(hrr  gradYear)
*qui: eststo: reghdfe `j' `k'  `controls',a(groupPAC gradYear) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr phySpec medSchool Tuition_quantile) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr phySpec medSchool Tuition_quantile) cluster(hrr gradYear)
esttab est*, keep(`k') star(* 0.10 ** 0.05 *** 0.01)
}
}

restore

preserve
*keep if totHrsPerWk_2012>0
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012 nCode_2013 nCodeEM_2012 nCodeEM_2013 PublicSchool
foreach k in dtuitionABS2kCHANGE{
foreach j in  avservice2012 avservice2013 impFlag0_2012 impFlag0_2013 impflag0 avservice avservice1 avservice2{
eststo clear
qui: eststo: reg `j' `k', cluster(hrr)
qui: eststo: reg `j' `k'  `controls', cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr gradYear) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr medSchool) cluster(hrr)
*qui: eststo: reghdfe `j' `k'  `controls',a(groupPAC gradYear) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr phySpec gradYear) cluster(hrr gradYear)
esttab est*, keep(`k')
}
}

egen gradyearXphyspec=group(phySpec gradYear)
egen gradyearXhrr=group(hrr gradYear)

preserve 
keep if totHrsPerWk_2012>0 | totHrsPerWk_2013>0
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012  nCodeEM_2012  nCode_2013  nCodeEM_2013 PublicSchool
reghdfe totPaid  dtuitionABS2kCHANGE  `controls',a(hrr) cluster(hrr)
reghdfe totPaid  dtuitionABS2kCHANGE  `controls',a(hrr gradYear) cluster(hrr)
reghdfe totPaid  dtuitionABS2kCHANGE  `controls',a(hrr phySpec gradYear) cluster(hrr)
reghdfe totPaid dtuitionABS2kCHANGE  `controls',a(hrr phySpec gradYear) cluster(hrr gradYear)
reghdfe totPaid  dtuitionABS2kCHANGE  `controls',a(hrr gradyearXphyspec) cluster(hrr)
reghdfe totPaid dtuitionABS2kCHANGE  `controls',a(gradyearXhrr) cluster(hrr)
reghdfe totPaid  dtuitionABS2kCHANGE  `controls',a(hrr gradyearXphyspec) cluster(hrr gradYear)
reghdfe totPaid  dtuitionABS2kCHANGE  `controls',a(gradyearXhrr) cluster(hrr gradYear)
restore

preserve 
keep if totHrsPerWk_2012>0
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012  nCodeEM_2012  PublicSchool totHrsPerWk_2013
reghdfe totPaid_2012 dtuitionABS2kCHANGE  `controls',a(hrr) cluster(hrr)
reghdfe totPaid_2012 dtuitionABS2kCHANGE  `controls',a(hrr gradYear) cluster(hrr)
reghdfe totPaid_2012 dtuitionABS2kCHANGE  `controls',a(hrr phySpec gradYear) cluster(hrr gradYear)
reghdfe totPaid_2012  dtuitionABS2kCHANGE  `controls',a(hrr gradyearXphyspec) cluster(hrr)
reghdfe totPaid_2012  dtuitionABS2kCHANGE  `controls',a(gradyearXhrr) cluster(hrr)
reghdfe totPaid_2012  dtuitionABS2kCHANGE  `controls',a(hrr gradyearXphyspec) cluster(hrr gradYear)
reghdfe totPaid_2012  dtuitionABS2kCHANGE  `controls',a(gradyearXhrr) cluster(hrr gradYear)
restore

preserve 
keep if totHrsPerWk_2013>0
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2013  nCodeEM_2013  PublicSchool totHrsPerWk_2013
reghdfe totPaid_2013 dtuitionABS2kCHANGE  `controls',a(hrr) cluster(hrr)
reghdfe totPaid_2013 dtuitionABS2kCHANGE  `controls',a(hrr gradYear) cluster(hrr)
reghdfe totPaid_2013 dtuitionABS2kCHANGE  `controls',a(hrr phySpec gradYear) cluster(hrr gradYear)
reghdfe totPaid_2013  dtuitionABS2kCHANGE  `controls',a(hrr gradyearXphyspec) cluster(hrr)
reghdfe totPaid_2013  dtuitionABS2kCHANGE  `controls',a(gradyearXhrr) cluster(hrr)
reghdfe totPaid_2013  dtuitionABS2kCHANGE  `controls',a(hrr gradyearXphyspec) cluster(hrr gradYear)
reghdfe totPaid_2013  dtuitionABS2kCHANGE  `controls',a(gradyearXhrr) cluster(hrr gradYear)
restore

*****************************************************************************************
clear all
use "regDATASET_nodoubles"































*******************************************************************************
clear all
use "regDATASET"

*check trends in tuitionrises (expected?)

gen PublicXtuition2kCHANGE=PublicSchool*tuitionABS2kCHANGE
gen PublicXtuition26kCHANGE=PublicSchool*tuitionABS26kCHANGE
gen PublicXtuitionREL10CHANGE=PublicSchool*tuitionREL10CHANGE
gen PublicXtuitionREL15CHANGE=PublicSchool*tuitionREL15CHANGE

egen impflag0=rowmax(impFlag0_2012 impFlag0_2013)
egen impflag1=rowmax(impFlag1_2012 impFlag1_2013)
egen impflag2=rowmax(impFlag2_2012 impFlag2_2013)

egen max_nBene=rowmax(nBene_2012 nBene_2013)
gen avservice=(nServ_2012+nServ_2013)/(max_nBene)
gen avservice1=(nServ_2012+nServ_2013)/(nBene_2012+nBene_2013)
gen avservice2=((nServ_2012+nServ_2013)/2)/(max_nBene)


*15 works best!!
*also flag1 (100 hours+) this is also the main focus of AER article
preserve
gen temp = 1
keep if totHrsPerWk_2012>0 | totHrsPerWk_2013>0
*keep if experYear>2
local controls PublicSchool male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012 nCode_2013 anyEM
foreach k in tuitionREL15CHANGE  {
*tuitionREL10CHANGE
foreach j in  lntotPaid impflag1 avservice2{ 
*lntotPaid_2012 lntotPaid_2013  avservice2012 avservice2013   avservice avservice1
eststo clear
qui: eststo: reghdfe `j' PublicX`k' `k'  `controls',a(temp) cluster(hrr gradYear)
qui: eststo: reghdfe `j' PublicX`k' `k'  `controls',a(hrr) cluster(hrr gradYear)
qui: eststo: reghdfe `j' PublicX`k' `k'  `controls',a(hrr gradYear) cluster(hrr gradYear)
*qui: eststo: reghdfe `j' PublicX`k' `k'  `controls',a(hrr#gradYear) cluster(hrr gradYear)
qui: eststo: reghdfe `j' PublicX`k' `k'  `controls',a(hrr phySpec#gradYear) cluster(hrr gradYear)
qui: eststo: reghdfe `j' PublicX`k' `k'  `controls',a(hrr#gradYear phySpec#gradYear) cluster(hrr gradYear)
*qui: eststo: reghdfe `j' PublicX`k' `k'  `controls',a(hrr#gradYear phySpec#gradYear) cluster(hrr gradYear)
*qui: eststo: reghdfe `j' PublicX`k' `k'  `controls',a(hrr#gradYear phySpec#gradYear quant ) cluster(hrr)
qui: eststo: reghdfe `j' PublicX`k' `k'  `controls',a(hrr#gradYear phySpec#gradYear quant ) cluster(hrr gradYear)
*qui: eststo: reghdfe `j' PublicX`k' `k'  `controls',a(hrr#gradYear phySpec#gradYear quant groupPAC) cluster(hrr gradYear)
esttab est* , keep(PublicX`k' `k' PublicSchool) star(* 0.10 ** 0.05 *** 0.01)
*esttab est* using prelim_results_publicXtuition15.csv, keep(PublicX`k' `k' PublicSchool) star(* 0.10 ** 0.05 *** 0.01) append
*esttab using prelim_results_publicXtuition15.csv,  cells("b(star fmt(3))" se(par))   stats (r2 N)  star(* 0.10 ** 0.05 *** 0.01) replace label
}
}
restore





preserve
keep if totHrsPerWk_2012>0 | totHrsPerWk_2013>0
*keep if experYear>2
*keep if privateSchool==2
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR privateSchool nCode_2012 nCode_2013 anyEM
foreach k in tuitionABS2kCHANGE {

*tuitionABS26kCHANGE new_rel15_CHANGE tuitionREL10CHANGE tuitionREL15CHANGE new_rel15_CHANGE
foreach j in  lntotPaid lntotPaid_2012 lntotPaid_2013 { 
*totPaid_2012 avservice2012 impFlag0_2012 impFlag0_2013 avservice2012 avservice2013 nServ_2012 nServ_2013
eststo clear
*qui: eststo: reg `j' `k', cluster(hrr)
*qui: eststo: reg `j' `k'  `controls', cluster(hrr)
qui: eststo: reghdfe `j'  `k'  `controls',a(hrr) cluster(hrr)
qui: eststo: reghdfe `j'  `k'  `controls',a(gradYear) cluster(gradYear)
qui: eststo: reghdfe `j'  `k'  `controls',a(hrr gradYear) cluster(hrr)
qui: eststo: reghdfe `j'  `k'  `controls',a(hrr#gradYear phySpec#gradYear) cluster(hrr)
qui: eststo: reghdfe `j'  `k'  `controls',a(hrr#gradYear phySpec#gradYear) cluster(hrr gradYear)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr#gradYear phySpec#gradYear quant ) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr#gradYear phySpec#gradYear quant ) cluster(hrr gradYear)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr#gradYear phySpec#gradYear quant groupPAC) cluster(hrr)
esttab est*, keep(`k' )
}
}
restore


*reghdfe  lntotPaid_2013 tuitionABS26kCHANGE `controls', a(gradYear#hrr phySpec#gradYear quant) cluster(hrr)

preserve
keep if totHrsPerWk_2012>0
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012 nCodeEM_2012  privateSchool totHrsPerWk_2012
*totPaid_2013 totPaidEM_2012 totPaidEM_2013 nServ_2013  avservice2013
foreach k in tuitionABS2kCHANGE tuitionABS26kCHANGE tuitionREL10CHANGE tuitionREL15CHANGE{
foreach j in  totPaid_2012   avservice2012{
eststo clear
qui: eststo: reg `j' `k', cluster(hrr)
qui: eststo: reg `j' `k'  `controls', cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr gradYear) cluster(hrr)
*qui: eststo: reghdfe `j' `k'  `controls',a(hrr medSchool) cluster(hrr)
*qui: eststo: reghdfe `j' `k'  `controls',a(groupPAC gradYear) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr phySpec gradYear) cluster(hrr gradYear)
esttab est*, keep(`k')
}
}
restore

preserve
keep if totHrsPerWk_2013>0
keep if anyEM==1
keep if totPaidEM_2013>0
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2013 nCodeEM_2013  privateSchool
*totPaid_2013 totPaidEM_2012 totPaidEM_2013 nServ_2013  avservice2013
foreach k in tuitionABS2kCHANGE tuitionABS26kCHANGE tuitionREL10CHANGE tuitionREL15CHANGE{
foreach j in  totPaidEM_2013  totPaid_2013  avservice2013{
eststo clear
*qui: eststo: reg `j' `k', cluster(hrr)
*qui: eststo: reg `j' `k'  `controls', cluster(hrr)
*qui: eststo: reghdfe `j' `k'  `controls',a(hrr) cluster(hrr)
*qui: eststo: reghdfe `j' `k'  `controls',a(hrr medSchool) cluster(hrr)
*qui: eststo: reghdfe `j' `k'  `controls',a(groupPAC gradYear) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr gradYear) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr gradYear) cluster(hrr gradYear)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr phySpec gradYear) cluster(hrr gradYear)
esttab est*, keep(`k')
}
}
restore

***total costs***
preserve
keep if totHrsPerWk_2012>0 | totHrsPerWk_2013>0
local controls male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012 nCodeEM_2012  privateSchool
foreach k in tuitionABS2kCHANGE tuitionABS26kCHANGE tuitionREL10CHANGE tuitionREL15CHANGE{
foreach j in  totPaid{
eststo clear
qui: eststo: reg `j' `k', cluster(hrr)
qui: eststo: reg `j' `k'  `controls', cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr gradYear) cluster(hrr)
*qui: eststo: reghdfe `j' `k'  `controls',a(hrr medSchool) cluster(hrr)
*qui: eststo: reghdfe `j' `k'  `controls',a(groupPAC gradYear) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr phySpec gradYear) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls',a(hrr phySpec gradYear) cluster(hrr gradYear)
esttab est*, keep(`k')
}
}
restore



local controls2 male isMD experYear nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012 nCode_2013 privateSchool
foreach k in tuitionABS2kCHANGE tuitionABS26kCHANGE tuitionREL10CHANGE tuitionREL15CHANGE{
foreach j in totPaid_2012 totPaid_2013 avservice2012 avservice2013{
eststo clear
qui: eststo: reghdfe `j' `k'  `controls2',a(phySpec gradYear) cluster(hrr)
esttab est*, keep(`k')
}
}
*first check whether this measure is inputed or directly measured. 
*include totHrsPerWk_2012

local controls2012 male isMD  nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2012  nCodeEM_2012  privateSchool
local controls2013 male isMD  nPhyInGroup hosAff inMedicare inERX inPQRS inEHR nCode_2013  nCodeEM_2013  privateSchool

foreach k in tuitionABS2kCHANGE tuitionABS26kCHANGE tuitionREL10CHANGE tuitionREL15CHANGE{
forval j in totPaid_2012 avservice2012{
eststo clear
qui: eststo: reg `j' `k' if totHrsPerWk_2012>0, cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls2012' if totHrsPerWk_2012>0,a(hrr) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls2012' if totHrsPerWk_2012>0,a(hrr gradYear) cluster(hrr)
qui: eststo: reghdfe `j' `k'  `controls2012' if totHrsPerWk_2012>0,a(hrr gradYear) cluster(hrr gradYear)
qui: eststo: reghdfe `j' `k'  `controls2012' if totHrsPerWk_2012>0,a(hrr gradYear phySpec ) cluster(hrr)
esttab est*, keep(`k')
}
}
}

***+++|||tuitionREL15CHANGE|||+++***
*Totpaid (-), especially 2013
*impFlag0_2013 (-)

***+++|||tuitionREL10CHANGE|||+++***
*Totpaid (-)
*impFlag0_2013 (-)

Why negative results?
