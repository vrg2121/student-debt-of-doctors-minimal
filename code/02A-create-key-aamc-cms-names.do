
*************************************
*** EXPORT UNIQUE NAMES TO EXCELS ***
*************************************

* Description of this do-file:

* Data sources:

*	AAMC – https://www.aamc.org/data-reports/reporting-tools/report/tuition-and-student-fees-reports
*	IPEDS – https://github.com/huyouare/freebase-ipeds/blob/master/ipeds-2012.csv
* 	Our data – $git/data/original/from-emiel/our-med-schools-2025-02-10.xlsx

*************************************
*************************************
*************************************



*** AAMC ***

* aamc-med-schools.xlsx was made by copying and pasting the names from the three
* tuition reports downloaded from the link above to: $git/data/original/aamc/

import excel "$git/data/original/aamc/excels/modified/aamc-med-schools.xlsx", clear firstrow

keep aamc_med_school

bys aamc_med_school : keep if _n == 1 // aka duplicates drop

replace aamc_med_school = lower(aamc_med_school)

* Checking so names are still unique after conversion to lower-case:
bys aamc_med_school : assert _N == 1

export excel "$git/data/working/unique-names/output-excels/unique-aamc-med-schools.xlsx", replace firstrow(var)


*** IPEDS ***

import delimited "$git/data/original/ipeds/ipeds-2012.csv", clear

* Note – different unitid's within name:
// bys institutionname : assert _N == 1

keep institutionname

bys institutionname : keep if _n == 1 // aka duplicates drop

replace institutionname = lower(institutionname)

* Checking so names are still unique after conversion to lower-case:
// bys institutionname : assert _N == 1 // not true for one by-group!

bys institutionname : keep if _n == 1

export excel "$git/data/working/unique-names/output-excels/unique-ipeds-2012.xlsx", replace firstrow(var)


*** Our data ***

* our-med-schools-2025-02-10.xlsx is backup of Emiel's export of our unique schools

import excel "$git/data/original/from-emiel/our-med-schools-2025-02-10.xlsx", clear firstrow

keep our_med_school our_nr_obs our_rank

bys our_med_school : assert _N == 1 // names already unique

replace our_med_school = lower(our_med_school)

* Checking so names are still unique after conversion to lower-case:
bys our_med_school : assert _N == 1

sort our_rank

export excel "$git/data/working/unique-names/output-excels/unique-our-med-schools.xlsx", replace firstrow(var)
