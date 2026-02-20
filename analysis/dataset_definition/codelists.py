# This script retrieves CSV files from codelists folder and stores them as variables

from ehrql import codelist_from_csv

# Shalini (https://bmjmedicine.bmj.com/content/3/1/e000807):
# Defined KRT using existing primary care codelists, and developed secondary care codelists.
# split into a different modalities and 'kidney replacement therapy' for when unclear

# will copy their coding structure which is in their supplement

### primary care coding for KRT pre-baseline
# opensafely/kidney-transplant/21865860 
# opensafely/dialysis/3ce108ac #
# opensafely/renal-replacement-therapy/5b5ed963 # full list of KRT codes

### secondary care coding for KRT pre-baseline
# ukrr/dialysis-opcs-4/505bef04 # dialysis
# ukrr/dialysis-icd10/2a5cf9a2/ # dialysis
# ICD10 Z940 - kidney transplant status # transplant
# user/viyaasan/kidney-transplant-opcs-4/18d788ae/ # transplant
# Other codes for 'KRT' needed 
# ICD10: 
# T861 - kidney transplant failure and rejection
# OPCS4: 
# M023 - bilateral nephrectomy; 
# M026 - excision of rejected transplanted kidney; 
# M027 - excision of transplanted kidney NEC; 
# X412 - removal of ambulatory peritoneal dialysis catheter

# Viyassan used this codelist to generate creatinine values
#user/bangzheng/creatinine-value/7d319079

# primary care CTV3 codes - initially all KRT, then dialysis then Ktx
primary_care_krt_codes = codelist_from_csv(
    "codelists/opensafely-renal-replacement-therapy.csv",
    system="ctv3",
    column="CTV3ID"
)
primary_care_dialysis_codes = codelist_from_csv(
    "codelists/opensafely-dialysis.csv",
    system="ctv3",
    column="CTV3ID"
)
primary_care_kidney_transplant_codes = codelist_from_csv(
    "codelists/opensafely-kidney-transplant.csv",
    system="ctv3",
    column="CTV3ID"
)
