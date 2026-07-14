##########################################################################
# This script does the following:
# 1. Loads clinical codelists from the codelists/ directory
# 2. Stores them as variables for use in dataset definitions
##########################################################################

from ehrql import codelist_from_csv

##########################################################################
# KIDNEY FUNCTION CODELISTS
##########################################################################

#  CKD codes ---------------------------------------------------------------------
primary_care_ckd4_codes = codelist_from_csv(
    "codelists/user-mletts92-chronic-kidney-disease-stage-4.csv",
    column="code"
)
primary_care_ckd5_codes = codelist_from_csv(
    "codelists/user-mletts92-chronic-kidney-disease-stage-5-not-receiving-kidney-replacement-therapy.csv",
    column="code"
)
# ckd4 and ckd5 codelists combined
primary_care_ckd45_codes = codelist_from_csv(
    "codelists/user-mletts92-chronic-kidney-disease-stage-4-and-5-but-not-receiving-kidney-replacement-therapy.csv",
    column="code"
)


# creatinine values -------------------------------------------------------------
creatinine_codes = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-cre_cod.csv",
    column="code"
)

##########################################################################
# KIDNEY REPLACEMENT THERAPY CODELISTS
##########################################################################
# Same methods as in this paper: https://bmjmedicine.bmj.com/content/3/1/e000807

## primary care KRT codes (all CTV3)
# dialysis, ktx (transplant), then all krt
primary_care_dialysis_codes = codelist_from_csv(
    "codelists/opensafely-dialysis.csv",
    column="CTV3ID"
)
primary_care_ktx_codes = codelist_from_csv(
    "codelists/opensafely-kidney-transplant.csv",
    column="CTV3ID"
)
primary_care_krt_codes = codelist_from_csv(
    "codelists/opensafely-renal-replacement-therapy.csv",
    column="CTV3ID"
)
# combine them altogether for full list of primary care CTV3 codes 
primary_care_krt_codes_all = (
    primary_care_dialysis_codes 
    + primary_care_ktx_codes 
    + primary_care_krt_codes
)


## secondary care KRT codes (ICD10 and OPCS-4)
# icd10 - dialysis, ktx then all krt
secondary_care_dialysis_codes_icd10 = codelist_from_csv(
    "codelists/ukrr-dialysis-icd10.csv",
    column="code"
)
secondary_care_ktx_codes_icd10 = ["Z940"] # only one code for kidney transplant
secondary_care_unclear_krt_codes_icd10 = ["T861"] # "complications of kidney transplant"; may refer to transplant failure hence unknown treatment modality
secondary_care_krt_codes_icd10 = (
    secondary_care_dialysis_codes_icd10 
    + secondary_care_ktx_codes_icd10 
    + secondary_care_unclear_krt_codes_icd10
)

# opcs4 - dialysis, ktx then all krt
secondary_care_dialysis_codes_opcs4 = codelist_from_csv(
    "codelists/ukrr-dialysis-opcs-4.csv",
    column="code"
)
secondary_care_ktx_codes_opcs4 = codelist_from_csv(
    "codelists/user-mletts92-kidney-transplant-opcs4.csv",
    column="code"
)
secondary_care_unclear_krt_codes_opcs4 = ["M023", "M026", "M027", "X412"]
# all indicating kidney failure but unknown treatment modality
# M023 - bilateral nephrectomy; 
# M026 - excision of rejected transplanted kidney; 
# M027 - excision of transplanted kidney NEC; 
# X412 - removal of ambulatory peritoneal dialysis catheter
secondary_care_krt_codes_opcs4 = (
    secondary_care_dialysis_codes_opcs4
    + secondary_care_ktx_codes_opcs4 
    + secondary_care_unclear_krt_codes_opcs4  
)


##########################################################################
# COVARIATE CODELISTS
##########################################################################
# TODO: This is a work in progress. Filling in as go. Organise once complete
# Scaffolds the green covariates in docs/deprescribing_factors.drawio.svg

# ethnicity codelist -----------------------------------------------------
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity-snomed-0removed.csv",
    column="code",
    category_column="Grouping_6"
)

# systolic blood pressure codelist
sbp_codes = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-sysbp_cod.csv",
    column="code"
)

# Myocardial infarction codelists 
# Primary + secondary care as MI mainly hospital-based diagnosis
mi_codes_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-mi_cod.csv",
    column="code"
)

mi_codes_icd10 = codelist_from_csv(
    "codelists/reducehf-myocardial-infarction-icd10.csv",
    column="code"
)

# Coronary revascularisation codelist
coronary_revasc_codes_opcs4 = codelist_from_csv(
    "codelists/user-mletts92-coronary-artery-interventions.csv",
    column="code"
)

# Stroke codelists
# Primary + secondary care as CVA mainly hospital-based diagnosis
cva_codes_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-strk_cod.csv",
    column="code"
)
cva_codes_icd10 = codelist_from_csv(
    "codelists/user-mletts92-stroke-secondary-care-codes.csv",
    column="code"
)

# Heart failure codelists
# Primary + secondary care as HF often diagnosed in hospital
hf_codes_snomed = codelist_from_csv(
    "codelists/pincer-hf.csv",
    column="code"
)

hf_codes_icd10 = codelist_from_csv(
    "codelists/reducehf-heart-failure-primary-outcome-icd.csv",
    column="code"
)

# Diabetes codelists
# Primary care dm codes only - diabetes activity coded well in primary care
dm_not1_codes_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-dmnontype1_cod.csv",
    column="code"
)

dm1_codes_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-dmtype1_cod.csv",
    column="code"
)

# hba1c codes, just the IFCC standardised units code 
hba1c_codes_snomed = codelist_from_csv(
    "codelists/opensafely-glycated-haemoglobin-hba1c-tests-numerical-value.csv",
    column="code"
)

# diabetes drugs
dm_drug_codes_dmd = codelist_from_csv(
    "codelists/user-mletts92-definite-diabetes-drugs-dmd.csv",
    column="code"
)

# # Clinical values (most-recent numeric before index) ---------------------
# # Total cholesterol
# cholesterol_codes_snomed = codelist_from_csv(
#     #"codelists/user-mletts92-total-cholesterol.csv",
#     column="code"
# )
# # Urinary albumin:creatinine ratio (uACR)
# uacr_codes_snomed = codelist_from_csv(
#     #"codelists/user-mletts92-urinary-albumin-creatinine-ratio.csv",
#     column="code"
# )
# # Urinary protein:creatinine ratio (uPCR)
# upcr_codes_snomed = codelist_from_csv(
#     #"codelists/user-mletts92-urinary-protein-creatinine-ratio.csv",
#     column="code"
# )


# # Smoking status --------------------------------------------------------
# smoking_codes_snomed = codelist_from_csv(
#     #"codelists/user-mletts92-smoking-status.csv",
#     column="code",
#     #category_column="category"
# )

# # Comorbidities ---------------------------------------------------------
# liver_disease_codes_snomed = codelist_from_csv(
#     #"codelists/user-mletts92-liver-disease.csv",
#     column="code"
# )
# liver_disease_codes_icd10 = codelist_from_csv(
#     #"codelists/user-mletts92-liver-disease-icd10.csv",
#     column="code"
# )
# cancer_codes_snomed = codelist_from_csv(
#     #"codelists/user-mletts92-cancer.csv",
#     column="code"
# )
# cancer_codes_icd10 = codelist_from_csv(
#     #"codelists/user-mletts92-cancer-icd10.csv",
#     column="code"
# )
# dementia_codes_snomed = codelist_from_csv(
#     #"codelists/user-mletts92-dementia.csv",
#     column="code"
# )
# dementia_codes_icd10 = codelist_from_csv(
#     #"codelists/user-mletts92-dementia-icd10.csv",
#     column="code"
# )
# copd_codes_snomed = codelist_from_csv(
#     #"codelists/user-mletts92-copd.csv",
#     column="code"
# )
# copd_codes_icd10 = codelist_from_csv(
#     #"codelists/user-mletts92-copd-icd10.csv",
#     column="code"
# )


# # Recent events (primary care SNOMED) ------------------------------------
# structured_med_review_codes_snomed = codelist_from_csv(
#     #"codelists/user-mletts92-structured-medication-review.csv",
#     column="code"
# )
# care_facility_move_codes_snomed = codelist_from_csv(
#     #"codelists/user-mletts92-care-home-admission.csv",
#     column="code"
# )
# falls_codes_snomed = codelist_from_csv(
#     #"codelists/user-mletts92-falls.csv",
#     column="code"
# )
# falls_codes_icd10 = codelist_from_csv(
#     #"codelists/user-mletts92-falls-icd10.csv",
#     column="code"
# )

# # GI bleeding:
# gi_bleed_codes_snomed = codelist_from_csv(
#     #"codelists/user-mletts92-gi-bleeding.csv",
#     column="code"
# )
# gi_bleed_codes_icd10 = codelist_from_csv(
#     #"codelists/user-mletts92-gi-bleeding-icd10.csv",
#     column="code"
# )
# # AKI / electrolyte disturbance (hyponatraemia, hypomagnesaemia)
# electrolyte_codes_snomed = codelist_from_csv(
#     #"codelists/user-mletts92-aki-electrolyte-disturbance.csv",
#     column="code"
# )
# electrolyte_codes_icd10 = codelist_from_csv(
#     #"codelists/user-mletts92-aki-electrolyte-disturbance-icd10.csv",
#     column="code"
# )
