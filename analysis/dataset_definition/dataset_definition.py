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
from study_dates import *
from ckd_variables import (
    compute_ckd_variables,
    add_ckd_variables
)

dataset = create_dataset()

ckd = compute_ckd_variables(index_date)
add_inex_variables(dataset, index_date, ckd)
add_ckd_variables(dataset, ckd)

dataset.configure_dummy_data(population_size=10000)
dataset.define_population(patients.date_of_birth.is_not_null())


### opensafely exec ehrql:v1 generate-dataset analysis/dataset_definition.py --output \output\dummy_1.csv

#### define new variables
# latest_efi_record = (...)

#### define variables wanted in dataset
# dataset.X = ...

#### define population inex criteria
# dataset.define_population(...)