
* Only fix needed to run this file -- change this to your local Dropbox path:
global dropbox "/Users/przybyl/Library/CloudStorage/Dropbox/Student Debt of Doctors"

cd "$dropbox/Tuition Data/simon/student-debt-of-doctors/data/working/temp"

use "dummy-investigation-file-2025-03-21", clear

forval k = 1(1)4 {
	
	forval i = 1997(1)2011 {
		g  tuition2kincrease`k'`i' = 1 if large_tuition_abs2000_`i' == gradYear - `k'     // Original: one-off error?
// 		g  tuition2kincrease`k'`i' = 1 if large_tuition_abs2000_`i' == gradYear - `k' + 1
// 		g  tuition2kincrease`k'`i' = 1 if large_tuition_abs2000_`i' == grd_yr   - `k'
		g Ntuition2kincrease`k'`i' = 1 if large_tuition_abs2000_`i' == grd_yr   - `k' + 1 // New adjusted: grd_yr and plus one
	}
	
	egen  tuition2kincrease`k' = rowmax( tuition2kincrease`k'*)
	egen Ntuition2kincrease`k' = rowmax(Ntuition2kincrease`k'*)

}

* Examples of where difference comes from, note:
* 	gradYear == grd_yr for both examples
* 	i == 2004 in both examples

* Example where Emiel sets missing (i.e. zero) and SAP sets 1 -- k = 1:
br npi gradYear grd_yr large_tuition_abs2000_2004 ///
	 tuition2kincrease12004 ///
	Ntuition2kincrease12004 ///
	if npi == 1003991449

* Example where Emiel sets 1 and SAP sets missing (i.e. zero) -- k = 4:
br npi gradYear grd_yr large_tuition_abs2000_2004 ///
	 tuition2kincrease42004 ///
	Ntuition2kincrease42004 ///
	if npi == 1003072687
