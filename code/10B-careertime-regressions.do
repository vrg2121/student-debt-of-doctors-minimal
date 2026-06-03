/*
PREAMBLE

Regressions for effect of tuition bill over career time.
   
Victoria Garcia 
February 2026
*/

/* Reference:
	https://www.stata.com/support/faqs/data-management/creating-dummy-variables/
	https://www.statalist.org/forums/forum/general-stata-discussion/general/1582318-interaction-terms-in-regression
	https://repec.sowi.unibe.ch/stata/coefplot/getting-started.html#h-5
*/


*** BRAINSTORMING ***

** Clean Data **
use "$working_data/cms_aamc_cohort_id", clear

drop if med_school == "medical university of south carolina college of medicine" // incorrect tuition data

bysort cohort_id: egen max_tbill = max(tuition_bill)
bysort cohort_id: egen min_tbill = min(tuition_bill)
g spread = max_tbill - min_tbill
label variable spread "Tuition Bill Spread (Thousands)"

keep if spread > 1 // keep if tuition bill spread > $1000
// 406,610 / 1,549,937 = ~26% of observations deleted 

destring time_since_grad, replace

label variable time_since_grad "Career Length (Years)"

graph bar (count) npi, over(time_since_grad) ytitle("Number of Doctor-Year Observations") 
//title("Distribution of Doctor Observations by Length of Career") 

graph export "$figures/career-time-distribution.png", replace

g early_career = 0
g late_career = 0

quietly sum time_since_grad, d

replace early_career = 1 if time_since_grad < r(p50)
replace late_career = 1 if time_since_grad >= r(p50)


** Interaction with Automatic Dummy Variable **

* CMS Payments *
eststo clear 
eststo: reghdfe fg_sel3_total_payments i.time_since_grad#c.tuition_bill, a(cohort_id#i.year phySpec_id#i.year i.hrr#i.year i.time_since_grad#i.year) vce(cluster school_id)

// graph all of the coefficients and rename
coefplot, vertical drop(_cons) nolabels keep(*.time_since_grad#c.tuition_bill) coeflabel(1.time_since_grad#c.tuition_bill = "1" 2.time_since_grad#c.tuition_bill = "2" 3.time_since_grad#c.tuition_bill = "3" 4.time_since_grad#c.tuition_bill = "4" 5.time_since_grad#c.tuition_bill = "5" 6.time_since_grad#c.tuition_bill = "6" 7.time_since_grad#c.tuition_bill = "7" 8.time_since_grad#c.tuition_bill = "8" 9.time_since_grad#c.tuition_bill = "9" 10.time_since_grad#c.tuition_bill = "10" 11.time_since_grad#c.tuition_bill = "11" 12.time_since_grad#c.tuition_bill = "12" 13.time_since_grad#c.tuition_bill = "13" 14.time_since_grad#c.tuition_bill = "14" 15.time_since_grad#c.tuition_bill = "15" 16.time_since_grad#c.tuition_bill = "16" 17.time_since_grad#c.tuition_bill = "17" 18.time_since_grad#c.tuition_bill = "18" 19.time_since_grad#c.tuition_bill = "19" 20.time_since_grad#c.tuition_bill = "20") ytitle("Regression Coefficients") xtitle("Career Length (Years)") 

graph export "$figures/coef-cms-payments.png", replace

sum fg_sel3_total_payments if e(sample) == 1
estadd r(mean)

* Unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

* unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

esttab est*, se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(cohort_id#year "Cohort-Year FE" phySpec_id#year "Specialization-Year FE" hrr#year "HRR-Year FE" time_since_grad#year "Career Time-Year FE")						
	
esttab est* using "$tables/career-tuition-fe-regs-cms_payments.tex", ///
	se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_drs N_clust /* unique_schools */, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ )) ///
	replace

* E/M Payments *

eststo clear

eststo: reghdfe fg_sel5_total_payments i.time_since_grad#c.tuition_bill, a(cohort_id#i.year phySpec_id#i.year i.hrr#i.year i.time_since_grad#i.year) vce(cluster school_id)


// graph all of the coefficients and rename
coefplot, vertical drop(_cons) nolabels keep(*.time_since_grad#c.tuition_bill) coeflabel(1.time_since_grad#c.tuition_bill = "1" 2.time_since_grad#c.tuition_bill = "2" 3.time_since_grad#c.tuition_bill = "3" 4.time_since_grad#c.tuition_bill = "4" 5.time_since_grad#c.tuition_bill = "5" 6.time_since_grad#c.tuition_bill = "6" 7.time_since_grad#c.tuition_bill = "7" 8.time_since_grad#c.tuition_bill = "8" 9.time_since_grad#c.tuition_bill = "9" 10.time_since_grad#c.tuition_bill = "10" 11.time_since_grad#c.tuition_bill = "11" 12.time_since_grad#c.tuition_bill = "12" 13.time_since_grad#c.tuition_bill = "13" 14.time_since_grad#c.tuition_bill = "14" 15.time_since_grad#c.tuition_bill = "15" 16.time_since_grad#c.tuition_bill = "16" 17.time_since_grad#c.tuition_bill = "17" 18.time_since_grad#c.tuition_bill = "18" 19.time_since_grad#c.tuition_bill = "19" 20.time_since_grad#c.tuition_bill = "20") ytitle("Regression Coefficients") xtitle("Career Length (Years)") 

graph export "$figures/coef-cms-em-payments.png", replace


sum fg_sel5_total_payments if e(sample) == 1
estadd r(mean)

* Unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

* unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

esttab est*, se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(cohort_id#year "Cohort-Year FE" phySpec_id#year "Specialization-Year FE" hrr#year "HRR-Year FE" time_since_grad#year "Career Time-Year FE")						
	
esttab est* using "$tables/career-tuition-fe-regs-cms_em_payments.tex", ///
	se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_drs N_clust /* unique_schools */, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ )) ///
	replace


** CMS PAYMENTS # EARLY CAREER REGRESSION **
eststo clear

eststo: reghdfe fg_sel3_total_payments tuition_bill c.tuition_bill#i.early_career, a(cohort_id#i.year phySpec_id#i.year i.hrr#i.year i.time_since_grad#i.year) vce(cluster school_id)

* Mean:
sum fg_sel3_total_payments if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[tuition_bill] / r(mean)
estadd scalar pct_mean

* Unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

* unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

esttab est*, se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(cohort_id#year "Cohort-Year FE" phySpec_id#year "Specialization-Year FE" hrr#year "HRR-Year FE" time_since_grad#year "Career Time-Year FE")						
	
esttab est* using "$tables/career-fe-regs-cms_payments.tex", ///
	se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_drs N_clust /* unique_schools */ mean pct_mean, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef.\ \% of Mean")) ///
	replace

// coefplot, drop(_cons) title("CMS Payments")


** CMS EM PAYMENTS # EARLY CAREER REGRESSION **
eststo clear

eststo: reghdfe fg_sel5_total_payments tuition_bill c.tuition_bill#i.early_career, a(cohort_id#i.year phySpec_id#i.year i.hrr#i.year i.time_since_grad#i.year) vce(cluster school_id)

* Mean:
sum fg_sel5_total_payments if e(sample) == 1
estadd r(mean)

scalar pct_mean = 100 * _b[tuition_bill] / r(mean)
estadd scalar pct_mean

* Unique doctors
unique npi if e(sample) == 1
estadd scalar unique_drs = r(unique)

* unique schools
unique med_school if e(sample) == 1
estadd scalar unique_schools = r(unique)

esttab est*, se star(* 0.10 ** 0.05 *** 0.01) label
estfe . est*, labels(cohort_id#year "Cohort-Year FE" phySpec_id#year "Specialization-Year FE" hrr#year "HRR-Year FE" time_since_grad#year "Career Time-Year FE")						
	
esttab est* using "$tables/career-fe-regs-cms_em_payments.tex", ///
	se star(* 0.10 ** 0.05 *** 0.01) label ///
	indicate(`r(indicate_fe)') nomtitles ///
	stats(N unique_drs N_clust /* unique_schools */ mean pct_mean, fmt(%9.0fc %9.0fc %9.0fc /* %9.0fc */ 3 1) labels("Observations (doctor-years)" "Doctors" "Clusters" /* "Schools" */ "Mean" "Coef.\ \% of Mean")) ///
	replace

// coefplot, drop(_cons) title("CMS E/M Payments")



