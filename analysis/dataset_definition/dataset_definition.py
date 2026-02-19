from ehrql import (
    create_dataset,
    codelist_from_csv,
    months,
)

# listing all the possible tables that are available - can bin ones not being used later
from ehrql.tables.tpp import (
    addresses,
    # apcs, # not sure I need this - secondary care stats
    # apcs_cost, # almost certainly will not need this
    appointments, # likely bin this - need special permission to use it as it's unstable
    clinical_events, # yes: date, snometct_code, ctv3_code
    # clinical_events_ranges, # severe performance penalty assocated with this table - exclude
    # covid_therapeutics, # nah
    decision_support_values, # frailty - is this only for 1 particular date?
    # ec, # emergency care - unlikely to use
    # ec_cost, # emergency care - unlikely to use
    # emergency_care_attendances, # emergency care - unlikely to use
    ethnicity_from_sus, # yes, forms a part of ethnicity function
    # household_memberships_2020, # I think probably not
    medications, # yes: date; dmd_code
    # occupation_on_covid_vaccine_record, # noosh
    ons_deaths, # yes: date, underlying_cause_of_death; cause_of_death_01 (up to 15); place ---> gold standard
    # opa, # probably not
    # opa_cost, # unlikely to use
    # opa_diag, # unlikely to use
    # opa_proc, # unlikely to use
    # open_prompt, # no and requires additional permission
    # parents, # do not think that this will be useful
    patients, # yes: date_of_birth; sex; date_of_death - other bits age_on, is_alive_on, is_dead_on
    practice_registrations, # yes: start_date; end_date; practice_pseudo_id / stp / nuts1_region_name; 
    # practice_systmone_go_live_date; for_patinet_on; exitsts_for_patent_onm; spanning
    # sgss_covid_all_tests, # unlikely to use
    # ukrr, # unliekly to use - needs application/approval at project development stage
    # vaccinations, # no
    # wl_clockstops, # no
    # wl_openpathways, # again no
)

from analysis.dataset_definition.add_variables import (
    add_inex_variables
)

from codelists import *


dataset = create_dataset()

index_date = "2022-03-01"
study_end_date = "2026-02-09" # need to come back to this 

add_inex_variables(dataset, index_date)

dataset.configure_dummy_data(population_size=10000)
dataset.define_population(patients.date_of_birth.is_not_null())



### opensafely exec ehrql:v1 generate-dataset analysis/dataset_definition.py --output \output\dummy_1.csv

#### define new variables
# latest_efi_record = (...)

#### define variables wanted in dataset
# dataset.X = ...

#### define population inex criteria
# dataset.define_population(...)