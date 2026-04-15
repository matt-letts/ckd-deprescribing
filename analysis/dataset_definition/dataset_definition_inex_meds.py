# test using test_dataset_definition_prescriptions.py
# This script calls add_prescription_columns() which creates a dataset containing 
# wide-form prescription codes and dates and a count of medicines in the 
# days_before_index up to max_meds

from ehrql import create_dataset, table_from_file
from ehrql.tables.tpp import medications, patients
from variable_helper_functions import add_prescription_columns

# define the project-relevant dates
import json
with open("output/study_dates.json") as f:
    study_dates = json.load(f)
index_date = study_dates["index_date"]

# load dataset_inex_cleaned. columns={NULL} as no columns
# required other than patinet_id which is automatically imported
dataset_inex_cleaned = table_from_file(
    "output/data/dataset_inex_cleaned.arrow",
    columns={}
)

# initialise the dataset
dataset = create_dataset()
dataset.define_population(dataset_inex_cleaned.exists_for_patient())

# 
add_prescription_columns(dataset, index_date, max_meds=15, days_before_index=180)

# opensafely exec ehrql:v1 generate-dataset analysis/dataset_definition/dataset_definition_prescriptions.py --dummy-tables dummy_tables --output output/dataset_1.csv.gz
