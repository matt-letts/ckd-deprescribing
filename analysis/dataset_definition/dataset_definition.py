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

from add_variables import (add_inex_variables)
from codelists import *
# from ckd_variables import (
#     compute_ckd_variables,
#     add_ckd_variables,
# )

# define the project-relevant dates
import json
with open("output/study_dates.json") as f:
    study_dates = json.load(f)
index_date = study_dates["index_date"]
end_date = study_dates["end_date"]

# initialise the dataset
dataset = create_dataset()
dataset.configure_dummy_data(population_size=10000)
dataset.define_population(patients.date_of_birth.is_not_null())

# ckd = compute_ckd_variables(index_date) - hidden for now
add_inex_variables(dataset, index_date)

# add_ckd_variables(dataset, ckd) - hidden for now

## start from here tomorrow ## - this basic script works. I have  generated a 5 column dataset with boolean values from inex criteria like Rob has done.




### opensafely exec ehrql:v1 generate-dataset analysis/dataset_definition/dataset_definition.py --dummy-tables dummy_tables --output output/dummy_dataset.arrow

#### define new variables
# latest_efi_record = (...)

#### define variables wanted in dataset
# dataset.X = ...

#### define population inex criteria
# dataset.define_population(...)