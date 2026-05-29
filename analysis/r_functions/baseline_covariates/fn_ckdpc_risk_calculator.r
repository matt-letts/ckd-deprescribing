#####################################################################
# Risk of mortality
#####################################################################
# Using the CKD prognosis consortium advanced CKD risk tool
# https://ckdpcrisk.org/lowgfrevents/
#
# Needs 8 variables:
# - age (int), already imported from dataset_inex_cleaned
# - sex (M/F), already imported from dataset_inex_cleaned
# - race (black/non-black), this distinction is contested, and US
#   groups may not reflect UK groups. Plan to treat all as non-black
#   initially with sensitivity analyses exploring alternatives
# - eGFR (int), already imported from dataset_inex_cleaned
# - systolic BP (int)
# - history of cardiovascular disease,
# - diabetes,
# - uACR,
# - smoking history.
