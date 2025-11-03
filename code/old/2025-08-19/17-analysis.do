

************************************
*** FIGURE -- MONOTONIC INCREASE ***
************************************

* Should I run this on school panel or doctor panel? Currently on doctor...

keep if inrange(grade, 1, 4) // cannot put directly into reghdfe

reghdfe tot_tuition ib(4).grade, absorb(med_school)

coefplot, keep(1.grade 2.grade 3.grade 4.grade) ci(95) vertical title("Sample 2 – `var'") /// ssc install coefplot
	yscale(range(0 30000)) ylabel(0(10000)30000, format(%15.0fc))

graph export "$git/plots/05-initial-analysis/sample-2-`var'-coefplot.jpg", replace




