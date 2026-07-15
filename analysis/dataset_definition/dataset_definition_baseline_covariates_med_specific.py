##########################################################################
# This script does the following:
# 1. Reads study dates from output/study_dates.json
# 2. Reads the target medicine from the --medicine parameter in .yaml
# 3. Filters the population to patients in dataset_inex_cleaned
# 4. Calls add_baseline_covariates_med_specific() to add covariates
#
# Can be run as multiple .yaml actions by passing different
#     -- --medicine X
#
# Output: output/dataset_baseline_covariates_med_specific_<medicine>.arrow
##########################################################################

from ehrql import create_dataset, table_from_file, get_parameter
from fn_baseline_covariates_med_specific import add_baseline_covariates_med_specific

# define the project-relevant dates
import json
with open("output/study_dates.json") as f:
    study_dates = json.load(f)
index_date = study_dates["index_date"]

# target medicine, passed on the command line as `-- --medicine=ppi`
medicine = get_parameter(name="medicine")

# load dataset_inex_cleaned. Only used to define the population (the whole
# cohort); patient_id is imported automatically, so one column is enough.
# NB: restriction to baseline users of the medicine is a later exposure step.
dataset_inex_cleaned = table_from_file(
    "output/data/dataset_inex_cleaned.arrow",
    columns={}
)

# initialise new dataset
dataset = create_dataset()
dataset.define_population(dataset_inex_cleaned.exists_for_patient())

# add medicine-specific covariates to the dataset
add_baseline_covariates_med_specific(dataset, medicine, index_date)

