##########################################################################
# This script does the following:
# 1. Loads clinical codelists from the codelists/ directory
# 2. Stores them as variables for use in dataset definitions
#
# Codelists covered currently include:
#   - CKD stage 4 and stage 5 (primary care SNOMED codes)
#   - Serum creatinine (SNOMED)
#   - Kidney replacement therapy: dialysis and transplant (SNOMED)
#   - Ethnicity (6-category)
#   - Medications: statins (DMD)
##########################################################################

from ehrql import codelist_from_csv
import csv

#### codelists to determinine level of kidney function ####

# CKD codes ---------------------------------------------------------------------
primary_care_ckd4_codes = codelist_from_csv(
    "codelists/user-mletts92-chronic-kidney-disease-stage-4.csv",
    column="code"
)
primary_care_ckd5_codes = codelist_from_csv(
    "codelists/user-mletts92-chronic-kidney-disease-stage-5-not-receiving-kidney-replacement-therapy.csv",
    column="code"
)
# kd4 and ckd5 codelists combined
primary_care_ckd45_codes = codelist_from_csv(
    "codelists/user-mletts92-chronic-kidney-disease-stage-4-and-5-but-not-receiving-kidney-replacement-therapy.csv",
    column="code"
)

# creatinine values -------------------------------------------------------------
creatinine_codes = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-cre_cod.csv",
    column="code"
)

# Codelists to determine if someone has received kidney replacement therapy ----- 
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

# ethnicity codelists --------------------------------------------------------------------
ethnicity_snomed = codelist_from_csv(
    "codelists/opensafely-ethnicity-snomed-0removed.csv",
    column="code",
    category_column="Grouping_6"
)

# Medication codelists ------------------------------------------------------------------

# All the paths to medications_of_interest codelists are defined
# in analysis/config/medication_of_interest.csv (this is the central source of truth)
# Below code loops over csv rows and builds a dict with each medicine/codelist in it:

# {
#    "statin": <codelist>
#    "other": <codelist>
# }

with open("analysis/config/medication_of_interest.csv") as f:
    medication_of_interest_codelists = {}
    for row in csv.DictReader(f):
        medication_of_interest_codelists[row["name"]] = codelist_from_csv(
            row["codelist_path"],
            column="code"
        )
