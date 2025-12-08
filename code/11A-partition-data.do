/* 

PREAMBLE

Split the identified merged data into smaller portions to use by year.
   
Victoria Garcia 
December, 2025
*/

*** SET DATA LOCATION ***
* dropbox *
/*
global proj_dropbox "C:/dropbox/Phil Research Dropbox/Victoria Garcia/Student Debt of Doctors"

global v_data "$proj_dropbox/Tuition Data/victoria-temp/data"

global working_data "$v_data/raw_temp"
	
global code_repo "$proj_dropbox/Tuition Data/victoria-temp/code/do_files"
	
cd "$code_repo"
*/

* cluster *
global v_data "/home/victoria.garcia/Batch/data"

** disaggregate identified data by hcpcs **
use "$v_data/cms_aamc_merge_indentifier", clear

keep ///
	npi             ///
	year            ///
 	dum*		    ///
 	tuition_bill    ///
 	*med_school     ///
 	grad_year       ///
 	phySpec         ///
 	hrr             ///
	ngroupPAC		///
 	avg_mdcr_pymt_amt*
	
sum year
global min = r(min)
global max = r(max)

forvalues y = $min / $max {
	preserve
	
	keep if year == `y'
	save "$v_data/cms_aamc_id_`y'", replace
	
	restore	
}

clear

forvalues y = $min / $max {
	* directory to hold data *
	confirmdir "$v_data/`y'/" 	
	if _rc == 170 {
		mkdir "$v_data/`y'/"	
	}
	
	use "$v_data/cms_aamc_id_`y'", clear
	
	set seed 123
	gen rannum = uniform()
	egen grp = cut(rannum), group(20)
	
	sort grp
	
	preserve
	forvalues i = 0/19 {
		keep if grp == `i'
		save"$v_data/`y'/cms_aamc_id_`y'_`i'", replace
		restore, preserve
	}
	restore

}