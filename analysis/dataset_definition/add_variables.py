from ehrql.tables.tpp import (patients, practice_registrations, clinical_events, ons_deaths)
from ehrql import months, days
from variable_helper_functions import (
    get_imd,
    get_latest_ethnicity
)
from codelists import *


#### add_demographic_inex_variables() ####

# generates booleans for each of the demographic inclusion/exclusion criteria

def add_demographic_inex_variables(
    index_date
    ):
 
    return {

        # not dead prior to study start
        "inex_bin_alive": (
            ((patients.date_of_death.is_null()) |
             (patients.date_of_death.is_after(index_date))) &
            ((ons_deaths.date.is_null()) |
             (ons_deaths.date.is_after(index_date)))
        ),

        # age 18–110
        "inex_bin_age_include": (
            (patients.age_on(index_date) >= 18) &
            (patients.age_on(index_date) <= 110)
        ),

        # >12 months registered at a practice 
        # what about if someone has a missed end_date on a previous registration and they have two 'active registrations'?
        "inex_bin_12m_registered": (
            practice_registrations.where(
                practice_registrations.start_date.is_on_or_before(index_date - months(12)) &
                (
                    practice_registrations.end_date.is_null() |
                    practice_registrations.end_date.is_after(index_date)
                )
            )
        ).exists_for_patient(),

    }


#### add_creatinine_inex_variables() #### 

# generates 5 variables:
# 1. A per-patient boolean (inex_bin_has_two_scr) indicating whether a patient has:
        # One creatinine before index_date
        # At least one more 90+ days before the first
# 2. The numeric value of the most recent creatinine (inex_num_scr_value_1)
# 3. The date of the most recent creatinine (inex_date_scr_date_1)
# 4. The numeric value of the most recent creatinine, 90+ days prior to first (inex_num_scr_value_2)
# 5. The date of the most recent creatinine, 90+ days prior to first (inex_date_scr_date_2)

def add_creatinine_inex_variables(
    clinical_events, creatinine_codes, index_date
    ):

    # All valid creatinine values before index date
    creatinine_values = (
        clinical_events
        .where(clinical_events.snomedct_code.is_in(creatinine_codes))
        .where(clinical_events.numeric_value.is_not_null())
        .where(clinical_events.date < index_date)
    )

    # Most recent creatinine per patient
    most_recent = (
        creatinine_values
        .sort_by(clinical_events.date)
        .last_for_patient()
    )

    # 90-day cutoff from most recent
    cutoff = most_recent.date - days(90)

    # Second creatinine at least 90 days earlier
    second_recent_90plus = (
        creatinine_values
        .where(clinical_events.date <= cutoff)
        .sort_by(clinical_events.date)
        .last_for_patient()
    )

    # Binary flag: must have both
    has_two = (
        most_recent.exists_for_patient()
        & second_recent_90plus.exists_for_patient()
    )

    return {
        "inex_bin_has_two_scr": has_two,
        "inex_num_scr_value_1": most_recent.numeric_value,
        "inex_date_scr_date_1": most_recent.date,
        "inex_num_scr_value_2": second_recent_90plus.numeric_value,
        "inex_date_scr_date_2": second_recent_90plus.date,
    }

#### WHAT ABOUT CKD CODES ####
#### AND EXCLUDING THOSE ON DIALYSIS ####

#### add_qa_inex_variables() ####

# generates booleans for each of the quality assurance criteria

def add_qa_inex_variables(
    index_date
    ):
    
    return {

        # known sex that is male or female
        "inex_bin_sex": (
            (patients.sex == "male") |
            (patients.sex == "female")
        ),

        # known region
        "inex_bin_region": (
            practice_registrations
            .for_patient_on(index_date)
            .practice_nuts1_region_name
            .is_not_null()
        ),

        # known ethnicity
        "inex_bin_ethnicity": (
            get_latest_ethnicity(index_date, ethnicity_snomed, grouping=6)
            .is_not_null()
        ),

        # known IMD
        "inex_bin_imd": (
            get_imd(index_date, groups=5, max_imd=32844)
            .is_not_null()
        )

    }



#### add_inex_variables() ####

# combines all the inex functions together for simple pass into dataset.definition

def add_inex_variables(
    dataset, index_date
    ):

    columns = {}

    columns.update(add_demographic_inex_variables(
        index_date
        )
    )

    columns.update(
        add_creatinine_inex_variables(
            clinical_events=clinical_events,
            creatinine_codes=creatinine_codes,
            index_date=index_date
        )
    )

    columns.update(add_qa_inex_variables(
        index_date
        )
    )

    for name, expr in columns.items():
        dataset.add_column(name, expr)


# ### sex
# cov_cat_sex = patients.sex

# ### ethnicity
# cov_cat_ethnicity = get_latest_ethnicity(index_date, ethnicity_snomed, grouping=6)

# ### deprivation
# cov_cat_imd = get_imd(index_date, groups = 10, max_imd=32844)

# ### care home
# # cov_boolean_care_home --> this needs writing 
# # addresses.care_home_is_potential_match
# # addresses.care_home_requires_nursing
# # addresses.care_home_does_not_require_nursing

# #patient_address = addresses.for_patient_on("2022-03-01")

# # patient's practice STP
# dataset.stp = practice_registrations.for_patient_on(study_start_date).practice_stp

# from variable_helper_functions import (
#     get_imd,
#     get_latest_ethnicity
# )

# # death dates/causes from ONS
# dataset.date_of_death = ons_deaths.date
# dataset.underlying_cause_of_death = ons_deaths.underlying_cause_of_death
# dataset.cause_of_death = ons_deaths.cause_of_death_01

# # eFI
# latest_efi_record = (
#   decision_support_values
#     .electronic_frailty_index()
#     .where(decision_support_values.calculation_date.is_on_or_before(study_start_date)) # I added this line in
#     .sort_by(decision_support_values.calculation_date)
#     .last_for_patient()
# )
# dataset.latest_efi = latest_efi_record.numeric_value
# dataset.latest_efi_date = latest_efi_record.calculation_date
