from ehrql.tables.tpp import (
    patients,
    practice_registrations,
    clinical_events,
    ons_deaths
)

from ehrql import months

from variable_helper_functions import (
    get_imd,
    get_latest_ethnicity
)

from codelists import *

### population inclusion/exclusion criteria ###
def add_inex_variables(dataset, index_date):

    # not dead prior to study start date
    inex_bin_alive = (
        ((patients.date_of_death.is_null()) | (patients.date_of_death.is_after(index_date))) &
        ((ons_deaths.date.is_null()) | (ons_deaths.date.is_after(index_date)))
    )

    # age >=18 and <=110 on study start date
    inex_bin_age_include = (
        (patients.age_on(index_date) <= 110) &
        (patients.age_on(index_date) >= 18)
    )

    # registered for at least 12 months prior to study start date
    inex_bin_12m_registered = (
        practice_registrations.where(
            practice_registrations.start_date.is_on_or_before(index_date - months(12)) &
            (
                practice_registrations.end_date.is_null() | 
                practice_registrations.end_date.is_after(index_date)
            )
        )).exists_for_patient()

    # known sex
    inex_bin_sex = (
        (patients.sex == "male") |
        (patients.sex == "female")
    )

    # known region
    inex_bin_region = (
        practice_registrations
        .for_patient_on(index_date)
        .practice_nuts1_region_name
        .is_not_null()
    )
    

    inex_vars = {
        name: value
        for name, value in locals().items() 
        if name.startswith("inex_")
    }

    for name, expr in inex_vars.items():
        dataset.add_column(name, expr)


### sex
cov_cat_sex = patients.sex

### ethnicity
cov_cat_ethnicity = get_latest_ethnicity(index_date, ethnicity_snomed, grouping=6)

### deprivation
cov_cat_imd = get_imd(index_date, groups = 10, max_imd=32844)

### care home
# cov_boolean_care_home --> this needs writing 
# addresses.care_home_is_potential_match
# addresses.care_home_requires_nursing
# addresses.care_home_does_not_require_nursing

#patient_address = addresses.for_patient_on("2022-03-01")

# patient's practice STP
dataset.stp = practice_registrations.for_patient_on(study_start_date).practice_stp

from variable_helper_functions import (
    get_imd,
    get_latest_ethnicity
)

# death dates/causes from ONS
dataset.date_of_death = ons_deaths.date
dataset.underlying_cause_of_death = ons_deaths.underlying_cause_of_death
dataset.cause_of_death = ons_deaths.cause_of_death_01



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
