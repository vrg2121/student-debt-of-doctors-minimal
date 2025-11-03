global git "/Users/przybyl/Library/CloudStorage/Dropbox/Student Debt of Doctors/Tuition Data/simon/student-debt-of-doctors"

// Key, unitid -- institution name:
import delimited "$git/data/original/ipeds-2012.csv", clear

bys unitid : assert _N == 1

label var institutionname "INSTITUTIONNAME"

save "$git/data/working/dta/ipeds-2012", replace

// Tuition data:
import delimited "$git/data/original/ic_ay_data_stata/ic2023_ay_data_stata.csv", clear
save             "$git/data/working/dta/ic_ay_data_stata/ic2023_ay_data_stata", replace

import delimited "$git/data/original/ic_ay_data_stata/ic2022_ay_data_stata.csv", clear
save             "$git/data/working/dta/ic_ay_data_stata/ic2022_ay_data_stata", replace

use              "$git/data/working/dta/ic_ay_data_stata/ic2023_ay_data_stata", clear
gen year = 2023
label var year "YEAR"

append using      "$git/data/working/dta/ic_ay_data_stata/ic2022_ay_data_stata"
replace year = 2022 if year == .

bys unitid year : assert _N == 1

// Merge on institution name:
merge m:1 unitid using "$git/data/working/dta/ipeds-2012", keepusing(institutionname)
keep if _merge == 3 // temp!
drop _merge

// br unitid institutionname year tuition1

// Investigating institution names:
import delimited "$git/data/original/ipeds-2012.csv", clear

keep institutionname

duplicates drop

export excel "$git/data/working/ipeds-2012-unique-institutionname.xlsx", replace
