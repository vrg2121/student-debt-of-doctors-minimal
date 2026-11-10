*** clean physician do file ***

replace phySpec = subinstr(phySpec, " & ", "_", .)
replace phySpec = subinstr(phySpec, "-", "_", .)
replace phySpec = subinstr(phySpec, "(", "", .)
replace phySpec = subinstr(phySpec, ")", "", .)
replace phySpec = subinstr(phySpec, "/", "_", .)
replace phySpec = subinstr(phySpec, ",", "", .)
replace phySpec = subinstr(phySpec, " ", "_", .)

replace phySpec = "anesthesiology_assistant" if phySpec == "anesthesiologist_assistants"
replace phySpec = "audiologist" if inlist(phySpec, "audiologist_billing_independently", "qualified_audiologist")
replace phySpec = "cardiology" if phySpec == "cardiovascular_disease_cardiology"
replace phySpec = "crna" if phySpec == "certified_registered_nurse_anesthetist_crna"
replace phySpec = "clinical_cardiac_electrophysiology" if inlist(phySpec, "clinical_cardiatric_electrophysiology", "cardiac_electrophysiology")
replace phySpec = "colorectal_surgery" if inlist(phySpec, "colorectal_surgery_formerly_proctology", "colorectal_surgery_proctology")
replace phySpec = "oral_surgery_dentists_only" if phySpec == "oral_surgery_dentist_only"
replace phySpec = "clinical_psychologist" if phySpec == "psychologist_clinical"
replace phySpec = "" if inlist(phySpec, "undefined_physician_type", "unknown_physician_specialty_code", "unknown_supplier_provider", "unknown_supplier_provider_specialty", "undefined_physician_type_specify")
replace phySpec = "hospice_and_palliative_care" if phySpec == "hospice_palliative_care"
replace phySpec = "hematopoietic_cell_transplantation_and_cellular_therapy" if phySpec == "hematopoietic_cell_transplantation_and_cellular_th"
