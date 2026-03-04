# this dataset definition is not being used yet, but can be tested using test_dataset_definition_prescriptions.py
# It creates a dataset containing wide-form prescription codes and dates using the add_prescription_columns() function

from ehrql import create_dataset
from ehrql.tables.tpp import (
    addresses,
    clinical_events, # date, snometct_code, ctv3_code
    decision_support_values, # frailty - is this only for 1 particular date?
    ethnicity_from_sus, 
    medications, # date; dmd_code
    ons_deaths, # date, underlying_cause_of_death; cause_of_death_01 (up to 15);
    patients,
    practice_registrations,
)

from variable_helper_functions import add_prescription_columns

# define the project-relevant dates
import json
with open("output/study_dates.json") as f:
    study_dates = json.load(f)
index_date = study_dates["index_date"]
end_date = study_dates["end_date"]

# initialise the dataset
dataset = create_dataset()
dataset.configure_dummy_data(population_size=1000)
dataset.define_population(patients.date_of_birth.is_not_null())

add_prescription_columns(dataset, index_date, max_meds=15)

# opensafely exec ehrql:v1 generate-dataset analysis/dataset_definition/dataset_definition_prescriptions.py --dummy-tables dummy_tables --output output/dataset_1.csv.gz
