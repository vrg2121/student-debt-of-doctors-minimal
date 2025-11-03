
cap log close
log using "$temp/tabs-specializations.smcl", replace

* Share of schools in each specialization:
use "$git/data/original/aamc/modified/aamc-tuition", clear

collapse (max) $specializations, by(med_school)

foreach spec of global specializations {
	
	tab `spec', m
	
}

* Share of doctors in each specialization:
use "$git/data/working/FullDataCMSPANEL_final_subsample_tuition", clear

collapse (max) $specializations, by(npi)

foreach spec of global specializations {
	
	tab `spec', m
	
}

cap log close
