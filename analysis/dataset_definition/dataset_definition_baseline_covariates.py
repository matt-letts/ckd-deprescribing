##########################################################################
# This script does the following:
# 1. Reads study dates from output/study_dates.json
# 2. Filters the population to patients in dataset_inex_cleaned
# 3. Calls add_baseline_covariates() to add covariate columns
#
# Output: output/dataset_baseline_covariates.arrow
#         (see yaml: generate_dataset_baseline_covariates)
# Test: test_dataset_definition_baseline_covariates.py
##########################################################################

from ehrql import create_dataset, table_from_file
from fn_baseline_covariates import add_baseline_covariates

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

# add baseline covariates to the dataset
add_baseline_covariates(dataset, index_date)
