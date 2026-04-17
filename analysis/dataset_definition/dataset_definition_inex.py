##########################################################################
# This script does the following:
# 1. Reads study dates from output/study_dates.json
# 2. Calls add_inex_variables() to attach all demographic, CKD, and KRT
#    variables to the dataset
# 3. Defines the population as patients meeting the broad inclusion criteria
#
# Output: output/dataset_inex.arrow (see yaml: generate_dataset_inex)
# Test: test_dataset_definition_inex.py
##########################################################################

from ehrql import create_dataset
from ehrql.tables.tpp import patients
from fn_inex_variables import add_inex_variables
import numpy as np

# define the project-relevant dates
import json
with open("output/study_dates.json") as f:
    study_dates = json.load(f)
index_date = study_dates["index_date"]

# initialise the dataset
np.random.seed(123456)
dataset = create_dataset()
dataset.configure_dummy_data(population_size=40000)
dataset.define_population(patients.date_of_birth.is_not_null())

# add demographic, CKD/KRT and QA variables to the dataset
add_inex_variables(dataset, index_date)