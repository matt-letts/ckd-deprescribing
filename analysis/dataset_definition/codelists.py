# This script retrieves CSV files from codelists folder and stores them as variables

from ehrql import codelist_from_csv

#### CKD CODELISTS ####

# primary care ckd codes
primary_care_ckd45_codes = codelist_from_csv(
    "codelists/user-mletts92-chronic-kidney-disease-stage-4-and-5-but-not-receiving-kidney-replacement-therapy.csv",
    column="code"
)

# primary care creatinine values
creatinine_codes = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-cre_cod.csv",
    column="code"
)

#### KRT CODELISTS ####
# Same methods as in this paper: https://bmjmedicine.bmj.com/content/3/1/e000807

## primary care codes
# separate primary care ctv3 codelists - dialysis, ktx then all krt

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

# combine them altogether for full list of primary care codes 

primary_care_krt_codes_all = (
    list(primary_care_dialysis_codes) +
    list(primary_care_ktx_codes) +
    list(primary_care_krt_codes)
)

## secondary care codes
# secondary care icd10 codelists - dialysis, ktx then all krt

secondary_care_dialysis_codes_icd10 = codelist_from_csv(
    "codelists/ukrr-dialysis-icd10.csv",
    column="code"
)

secondary_care_ktx_codes_icd10 = ["Z940"] # only one code for kidney transplant

secondary_care_krt_codes_icd10 = (
    list(secondary_care_dialysis_codes_icd10) +
    list(secondary_care_ktx_codes_icd10) +
    ["T861"]  # "complications of kidney transplant"; may refer to transplant failure hence unknown treatment modality
)

# secondary care opcs4 codelists - dialysis, ktx then all krt

secondary_care_dialysis_codes_opcs4 = codelist_from_csv(
    "codelists/ukrr-dialysis-opcs-4.csv",
    column="code"
)

secondary_care_ktx_codes_opcs4 = codelist_from_csv(
    "codelists/user-viyaasan-kidney-transplant-opcs-4.csv",
    column="code"
)

secondary_care_krt_codes_opcs4 = (
    list(secondary_care_dialysis_codes_opcs4) +
    list(secondary_care_ktx_codes_opcs4) +
    ["M023", "M026", "M027", "X412"]
)
# all indicating kidney failure but unknown treatment modality
# M023 - bilateral nephrectomy; 
# M026 - excision of rejected transplanted kidney; 
# M027 - excision of transplanted kidney NEC; 
# X412 - removal of ambulatory peritoneal dialysis catheter

# combine them together to get various combinations of secondary care codelists 

secondary_care_dialysis_codes_all = (
    list(secondary_care_dialysis_codes_opcs4) +
    list(secondary_care_dialysis_codes_icd10)
)

secondary_care_ktx_codes_all = (
    list(secondary_care_ktx_codes_opcs4) +
    list(secondary_care_ktx_codes_icd10)
)

seoncdary_care_krt_codes_all = (
    # this last one contains all of the secondary care krt/dialysis/transplant codes
    list(secondary_care_krt_codes_opcs4) +
    list(secondary_care_krt_codes_icd10)
)

#### other codelists ###

ethnicity_snomed = codelist_from_csv(
    "codelists/opensafely-ethnicity-snomed-0removed.csv",
    column="code",
    category_column="Grouping_6"
)
