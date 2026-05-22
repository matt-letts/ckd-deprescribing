##########################################################################
# This script does the following:
# 1. Reads study dates from output/study_dates.json
# 2. Filters the population to patients in dataset_inex_cleaned
# 3. Calls add_baseline_covariate_variables() to add covariate columns
#
# Output: output/dataset_baseline_covariates.arrow
#         (see yaml: generate_dataset_baseline_covariates)
# Test: test_dataset_definition_baseline_covariates.py
##########################################################################

from ehrql import create_dataset, table_from_file
from fn_baseline_covariate_variables import add_baseline_covariate_variables

import json
with open("output/study_dates.json") as f:
    study_dates = json.load(f)
index_date = study_dates["index_date"]

dataset_inex_cleaned = table_from_file(
    "output/data/dataset_inex_cleaned.arrow",
    columns={}
)

dataset = create_dataset()
dataset.define_population(dataset_inex_cleaned.exists_for_patient())

add_baseline_covariate_variables(dataset, index_date)
