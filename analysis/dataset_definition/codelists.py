# This script retrieves CSV files from codelists folder and stores them as variables

from ehrql import codelist, codelist_from_csv, combine_codelists

#### CKD CODELISTS ####

# primary care ckd codes
primary_care_ckd45_codes = codelist_from_csv(
    "codelists/user-mletts92-chronic-kidney-disease-stage-4-and-5-but-not-receiving-kidney-replacement-therapy.csv",
    system="snomed",
    column="code"
)

# primary care creatinine values
creatinine_codes = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-cre_cod.csv",
    system="snomed",
    column="code"
)

#### KRT CODELISTS ####
# Same methods as in this paper: https://bmjmedicine.bmj.com/content/3/1/e000807

## primary care codes
# separate primary care ctv3 codelists - dialysis, ktx then all krt

primary_care_dialysis_codes = codelist_from_csv(
    "codelists/opensafely-dialysis.csv",
    system="ctv3",
    column="CTV3ID"
)

primary_care_ktx_codes = codelist_from_csv(
    "codelists/opensafely-kidney-transplant.csv",
    system="ctv3",
    column="CTV3ID"
)

primary_care_krt_codes = codelist_from_csv(
    "codelists/opensafely-renal-replacement-therapy.csv",
    system="ctv3",
    column="CTV3ID"
)

# combine them altogether for full list of primary care codes 

primary_care_krt_codes_all = combine_codelists(
    primary_care_dialysis_codes,
    primary_care_ktx_codes,
    primary_care_krt_codes
)

## secondary care codes
# secondary care icd10 codelists - dialysis, ktx then all krt

secondary_care_dialysis_codes_icd10 = codelist_from_csv(
    "codelists/ukrr-dialysis-icd10.csv",
    system="icd10",
    column="code"
)

secondary_care_ktx_codes_icd10 = codelist(["Z940"], system="icd10")

secondary_care_krt_codes_icd10 = combine_codelists(
    secondary_care_dialysis_codes_icd10,
    secondary_care_ktx_codes_icd10,
    codelist(["T861"], system="icd10") 
    # T861 = "complications of kidney transplant"; may refer to transplant failure hence unknown treatment modality
)

# secondary care opcs4 codelists - dialysis, ktx then all krt

secondary_care_dialysis_codes_opcs4 = codelist_from_csv(
    "codelists/ukrr-dialysis-opcs-4.csv",
    system="opcs4",
    column="code"
)

secondary_care_ktx_codes_opcs4 = codelist_from_csv(
    "codelists/user-viyaasan-kidney-transplant-opcs-4.csv",
    system="opcs4",
    column="code"
)

secondary_care_krt_codes_opcs4 = combine_codelists(
    secondary_care_dialysis_codes_opcs4,
    secondary_care_ktx_codes_opcs4,
    codelist(["M023", "M026", "M027", "X412"], system="opcs4"), 
    # all indicating kidney failure but unknown treatment modality
    # M023 - bilateral nephrectomy; 
    # M026 - excision of rejected transplanted kidney; 
    # M027 - excision of transplanted kidney NEC; 
    # X412 - removal of ambulatory peritoneal dialysis catheter
)

# combine them together to get various combinations of secondary care codelists 

secondary_care_dialysis_codes_all = combine_codelists(
    secondary_care_dialysis_codes_opcs4,
    secondary_care_dialysis_codes_icd10
)

secondary_care_ktx_codes_all = combine_codelists(
    secondary_care_ktx_codes_opcs4,
    secondary_care_ktx_codes_icd10
)

seoncdary_care_krt_codes_all = combine_codelists(
    # this last one contains all of the secondary care krt/dialysis/transplant codes
    secondary_care_krt_codes_opcs4,
    secondary_care_krt_codes_icd10
)
