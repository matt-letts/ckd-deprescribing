##########################################################################
# This script does the following:
# 1. Reads study dates from output/study_dates.json
# 2. Filters the population to patients in dataset_inex_cleaned
# 3. Calls add_prescription_columns() to create wide format prescription
#    columns for up to max_med prescriptions in the days_before_index 
#    window before index date.
#
# Output: dataset_baseline_meds.arrow (see yaml: generate_dataset_baseline_meds)
# Test: test_dataset_definition_baseline_meds.py
##########################################################################

from ehrql import create_dataset, table_from_file
from ehrql.tables.tpp import medications, patients
from fn_baseline_meds_variables import add_prescription_columns

# define the project-relevant dates
import json
with open("output/study_dates.json") as f:
    study_dates = json.load(f)
index_date = study_dates["index_date"]

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
# in the days_before_index window before index date
add_prescription_columns(dataset, index_date, max_meds=90, days_before_index=180)