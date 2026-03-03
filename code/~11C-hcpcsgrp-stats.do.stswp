******************************************
*** DOCTOR-YEAR-HCPCS GROUP STATISTICS ***
******************************************

* Description of this do-file:

* 	Descriptive statistics of  doctor-year-hcpcsgrp

*****************************************
*****************************************
*****************************************


* average / median number of groups per doctor-year

use "$working_data/cms_aamc_hcpcsgrp_id", clear

collapse (count) hcpcsgroup, by(npi year)

quietly sum hcpcsgroup, d

display "The number of groups per doctor-year: average = `r(mean)', median = `r(p50)'"

* histogram of number of EM groups in each doctor-year

histogram hcpcsgroup, frequency bin(15) title("Number of E/M Groups in Each Doctor-Year")




* average / median number of groups per doctor-year with spread

use "$working_data/cms_aamc_hcpcsgrp_id", clear

drop if med_school == "medical university of south carolina college of medicine" // incorrect tuition data

keep if spread > 1

collapse (count) hcpcsgroup, by(npi year)

quietly sum hcpcsgroup, d

display "The number of groups per doctor-year: average = `r(mean)', median = `r(p50)'"

histogram hcpcsgroup, frequency bin(15) title("Number of E/M Groups in Each Doctor-Year with Spread")
