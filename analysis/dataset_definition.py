from ehrql import (
    create_dataset,
    codelist_from_csv,
    months
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
    decision_support_values, # Rob was saying that this was only for 1 particular date?
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

from codelists import *

from variable_helper_functions import (
    get_imd,
    get_latest_ethnicity
)

study_start_date = "2022-03-01"
study_end_date = "2026-02-09" # need to come back to this 
#patient_address = addresses.for_patient_on("2022-03-01")
dataset = create_dataset()
dataset.configure_dummy_data(population_size=1000)

# registered >12 months prior to start date, and registered through until end date of study
registrations = (
    practice_registrations.where(
        practice_registrations.start_date.is_on_or_before(study_start_date - months(12))
    )
    .except_where(
        practice_registrations.end_date.is_on_or_before(study_end_date) # decide if having an end date
    )
)


# patient's practice STP
dataset.stp = practice_registrations.for_patient_on(study_start_date).practice_stp

# age
dataset.age = patients.age_on(study_start_date)
dataset.define_population(patients.exists_for_patient())

# death dates/causes from ONS
dataset.date_of_death = ons_deaths.date
dataset.underlying_cause_of_death = ons_deaths.underlying_cause_of_death
dataset.cause_of_death = ons_deaths.cause_of_death_01
dataset.define_population(patients.exists_for_patient())


# eFI
latest_efi_record = (
  decision_support_values
    .electronic_frailty_index()
    .where(decision_support_values.calculation_date.is_on_or_before(study_start_date)) # I added this line in
    .sort_by(decision_support_values.calculation_date)
    .last_for_patient()
)
dataset.latest_efi = latest_efi_record.numeric_value
dataset.latest_efi_date = latest_efi_record.calculation_date