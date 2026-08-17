##########################################################################
# This script does the following:
# 1. Reads study dates from output/study_dates.json
# 2. Defines medication_of_interest parameter which defines the dmd_codelist
#    to pull prescriptions for
# 3. Filters the population to patients in dataset_inex_cleaned
# 4. Calls add_baseline_moi_prescription_columns() to create wide format
#    prescription columns for up to max_meds prescriptions in the
#    days_before_index window before index date, restricted to the
#    medication of interest's codelist
#
# To add more medications:
# - build a new dmd codelist and add to codelists/
# - use local_processing/discontinuation/build_medication_of_interest_csv.r to add
#   a new row to config/medications_of_interest.csv. This automatically
#   adds to the python codelist dict being made in codelists.py
# - add a new parameterised generate_dataset_discont_meds_baseline_ action to
#   project.yaml
#
# Output: dataset_discont_[medication]_baseline.arrow
#         (see yaml: generate_dataset_discont_meds_baseline_{medication})
# Test: test_dataset_definition_discont_meds_baseline.py
##########################################################################

from ehrql import create_dataset, table_from_file, get_parameter
from codelists import medication_of_interest_codelists
from fn_discont_meds_variables import add_baseline_moi_prescription_columns
import json

# define the project-relevant dates
with open("output/study_dates.json") as f:
    study_dates = json.load(f)
index_date = study_dates["index_date"]

# define medication parameter and pull specific codelist from dict
medication = get_parameter(name="medication", type=str, default="")
dmd_codelist = medication_of_interest_codelists[medication]

# load dataset_inex_cleaned. columns={NULL} as no columns
# required other than patient_id which is automatically imported
dataset_inex_cleaned = table_from_file(
    "output/data/dataset_inex_cleaned.arrow",
    columns={}
)

# initialise new dataset
dataset = create_dataset()
dataset.define_population(dataset_inex_cleaned.exists_for_patient())

# add wide format prescription columns for up to max_meds prescriptions
# in the days_before_index window before index date, restricted to the
# medication of interest's codelist
add_baseline_moi_prescription_columns(
    dataset, index_date, dmd_codelist, max_meds=30, days_before_index=200
)
