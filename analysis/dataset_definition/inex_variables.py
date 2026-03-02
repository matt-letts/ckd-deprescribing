#####################################################################
# THIS FILE 
#####################################################################

#####################################################################
# IMPORTS
#####################################################################
from ehrql.tables.tpp import (
    patients, 
    practice_registrations, 
    clinical_events, 
    ons_deaths, 
    apcs
)
from ehrql import (
    months, 
    days, 
    case, 
    when
)
from variable_helper_functions import (
    get_imd,
    get_latest_ethnicity
)
from codelists import *


#####################################################################
# ADD DEMOGRAPHIC INCLUSION/EXCLUSION VARIABLES 
#####################################################################

# this function generates booleans for each of the demographic inclusion/exclusion criteria, and a column for the age and sex
# The latter are needed to compute eGFR through CKDEPI equation

def add_demographic_inex_variables(
    index_date
):

    age = patients.age_on(index_date)

    alive = (
        ((patients.date_of_death.is_null()) |
             (patients.date_of_death.is_after(index_date))) &
            ((ons_deaths.date.is_null()) |
             (ons_deaths.date.is_after(index_date)))
    )

    registered_12m = (
            practice_registrations
            .where(
                practice_registrations.start_date.is_on_or_before(index_date - months(12)) &
                (
                    practice_registrations.end_date.is_null() |
                    practice_registrations.end_date.is_after(index_date)
                )
            )
        ).exists_for_patient(
    )
    
    return {

        "inex_dem_bin_alive": alive,
        "inex_dem_bin_age_include": (age >= 18) & (age <= 110),
        "inex_dem_bin_12m_registered": registered_12m, # what about if someone has a missed end_date on a previous registration and they have two 'active registrations'
        "inex_dem_num_age": age,
        "inex_dem_cat_sex": patients.sex

    }


#####################################################################
# ADD CKD INCLUSION/EXCLUSION VARIABLES - CODES AND CREATININE VALUES
#####################################################################
# generates variables based on creatinine values/dates and CKD codes:

def add_ckd_inex_variables(
    clinical_events, 
    creatinine_codes, 
    primary_care_ckd45_codes,
    primary_care_ckd4_codes, 
    primary_care_ckd5_codes, 
    index_date
):

    ### creatinine variables ###

    # All non-null creatinine values before index date
    creatinine_values = (
        clinical_events
        .where(clinical_events.snomedct_code.is_in(creatinine_codes))
        .where(clinical_events.numeric_value.is_not_null())
        .where(clinical_events.date < index_date)
    )

    # Most recent creatinine per patient
    most_recent_creatinine = (
        creatinine_values
        .sort_by(clinical_events.date)
        .last_for_patient()
    )

    # 90-day cutoff from most recent
    cutoff = most_recent_creatinine.date - days(90)

    # Second creatinine at least 90 days earlier
    second_recent_90plus = (
        creatinine_values
        .where(clinical_events.date <= cutoff)
        .sort_by(clinical_events.date)
        .last_for_patient()
    )

    # Binary flag for whether 2 appropriate creatinine values exist
    has_two_creatinines = (
        most_recent_creatinine.exists_for_patient()
        & second_recent_90plus.exists_for_patient()
    )

    ### CKD codes ###

    # CKD stage 4/5 codes before index date
    coded_ckd45 = (
        clinical_events
        .where(clinical_events.snomedct_code.is_in(primary_care_ckd45_codes))
        .where(clinical_events.date < index_date)
    )

    # binary flag if a person has a CKD 4/5 code
    has_coded_ckd45 = coded_ckd45.exists_for_patient()

    # Most recent CKD 4/5 code
    most_recent_coded_ckd45 = (
        coded_ckd45
        .sort_by(clinical_events.date)
        .last_for_patient()
    )

    # and then whether this is a ckd stage 4 code, or a ckd stage 5 code
    ckd_code_stage = case(
        when(most_recent_coded_ckd45.snomedct_code.is_in(primary_care_ckd5_codes)).then("five"),
        when(most_recent_coded_ckd45.snomedct_code.is_in(primary_care_ckd4_codes)).then("four"),
        # do I need a third line here for "unknown?"
        otherwise=None
    )

    return {

        # Creatinine variables
        "inex_ckd_bin_has_two_scr": has_two_creatinines,
        "inex_ckd_num_scr_value_1": most_recent_creatinine.numeric_value,
        "inex_ckd_date_scr_date_1": most_recent_creatinine.date,
        "inex_ckd_num_scr_value_2": second_recent_90plus.numeric_value,
        "inex_ckd_date_scr_date_2": second_recent_90plus.date,

        # CKD stage 4/5 code variables
        "inex_ckd_bin_has_ckd45_code": has_coded_ckd45,
        "inex_ckd_date_most_recent_ckd45_code": most_recent_coded_ckd45.date,
        "inex_ckd_cat_ckd_code_stage": ckd_code_stage,

    }

#####################################################################
# ADD KRT VARIABLES (FOR EXCLUSION) - PRIMARY AND SECONDARY
#####################################################################

# Plan to look just using primary care codes, then primary and secondary combined and see the numbers

def add_krt_inex_variables(
    clinical_events,
    apcs,
    primary_care_krt_codes_all,
    primary_care_dialysis_codes,
    primary_care_ktx_codes,
    secondary_care_krt_codes_opcs4,
    secondary_care_dialysis_codes_opcs4,
    secondary_care_ktx_codes_opcs4,
    secondary_care_krt_codes_icd10,
    secondary_care_dialysis_codes_icd10,
    secondary_care_ktx_codes_icd10,
    index_date,
):
   
    ### Primary care codes - all CTV3 ###
   
    # CTV3 krt code before index date
    primary_care_krt_code = (
        clinical_events
        .where(clinical_events.ctv3_code.is_in(primary_care_krt_codes_all))
        .where(clinical_events.date < index_date)
    )

    # binary flag if a person has a secondary care krt code prior to index date
    has_primary_care_krt_code = primary_care_krt_code.exists_for_patient()

    # most recent primary care krt event
    most_recent_primary_care_krt_code = (
        primary_care_krt_code
        .sort_by(clinical_events.date)
        .last_for_patient()
    )

    # type of most recent krt code (dialysis/transplant/unknown)
    primary_care_krt_type = case(
        when(
            most_recent_primary_care_krt_code.ctv3_code.is_in(primary_care_dialysis_codes)
        ).then("dialysis"),
        when(
             most_recent_primary_care_krt_code.ctv3_code.is_in(primary_care_ktx_codes)
        ).then("transplant"),
        when(
            most_recent_primary_care_krt_code.ctv3_code.is_not_null()
        ).then("unknown"),
        otherwise=None,
    )

    
    ### Secondary care codes - ICD10 and OPCS4 ###
       
    # OPCS4 or ICD10 code before index date
    secondary_care_krt_code = (
        apcs
        .where(
            apcs.all_diagnoses.contains_any_of(secondary_care_krt_codes_icd10)
            | apcs.all_procedures.contains_any_of(secondary_care_krt_codes_opcs4)
        )
        .where(apcs.admission_date < index_date)
    )

    # binary flag if a person has a secondary care krt code
    has_secondary_care_krt_code = secondary_care_krt_code.exists_for_patient()

    # Most recent secondary care krt code
    most_recent_secondary_care_krt_code = (
        secondary_care_krt_code
        .sort_by(apcs.admission_date)
        .last_for_patient()
    )

    # and then whether this is a dialysis or transplant code
    secondary_care_krt_type = case(
        when(
            most_recent_secondary_care_krt_code.all_procedures.contains_any_of(
                secondary_care_dialysis_codes_opcs4
            )
            | most_recent_secondary_care_krt_code.all_diagnoses.contains_any_of(
                secondary_care_dialysis_codes_icd10
            )
        ).then("dialysis"),
        when(
            most_recent_secondary_care_krt_code.all_procedures.contains_any_of(
                secondary_care_ktx_codes_opcs4
            )
            | most_recent_secondary_care_krt_code.all_diagnoses.contains_any_of(
                secondary_care_ktx_codes_icd10
            )
        ).then("transplant"),
        when(most_recent_secondary_care_krt_code.apcs_ident.is_not_null()
        ).then("unknown"),
        otherwise=None,
    )

    
    ### Combined primary and secondary KRT codes ###
    
    # capture both boolean
    has_krt_code_either = (
        has_primary_care_krt_code
        | has_secondary_care_krt_code
    )

    # present in primary and secondary care boolean
    has_krt_code_both = (
        has_primary_care_krt_code
        & has_secondary_care_krt_code
    )

    # the date of the most recent krt code, slightly complex given the various potential options
    combined_most_recent_date = case(
        # only primary exists
        when(
            has_primary_care_krt_code
            & ~has_secondary_care_krt_code
        ).then(most_recent_primary_care_krt_code.date),

        # only secondary exists
        when(
            ~has_primary_care_krt_code
            & has_secondary_care_krt_code
        ).then(most_recent_secondary_care_krt_code.admission_date),

        # both exist and primary is later or equal
        when(
            has_krt_code_both
            & (
                most_recent_primary_care_krt_code.date
                >= most_recent_secondary_care_krt_code.admission_date
            )
        ).then(most_recent_primary_care_krt_code.date),

        # both exist and secondary is later
        when(
            has_krt_code_both
        ).then(most_recent_secondary_care_krt_code.admission_date),

        otherwise=None,
    )

    # the type of the most recent krt code, again slightly complex given potential options
    combined_krt_type = case(
        # only primary exists
        when(
            has_primary_care_krt_code
            & ~has_secondary_care_krt_code
        ).then(primary_care_krt_type),

        # only secondary exists
        when(
            ~has_primary_care_krt_code
            & has_secondary_care_krt_code
        ).then(secondary_care_krt_type),

        # both exist and primary is later or equal
        when(
            has_krt_code_both
            & (
                most_recent_primary_care_krt_code.date
                >= most_recent_secondary_care_krt_code.admission_date
            )
        ).then(primary_care_krt_type),

        # both exist and secondary is later
        when(
            has_krt_code_both
        ).then(secondary_care_krt_type),

        otherwise=None,
    )

    ### Return variables ###

    return {

        # Primary care only
        "inex_krt_bin_has_primary_care_krt_code": has_primary_care_krt_code,
        "inex_krt_date_most_recent_primary_care_krt_code": most_recent_primary_care_krt_code.date,
        "inex_krt_cat_primary_care_krt_type": primary_care_krt_type,

        # Combined primary + secondary
        "inex_krt_bin_has_combined_krt_code": has_krt_code_either,
        "inex_krt_date_most_recent_combined_krt_code": combined_most_recent_date,
        "inex_krt_cat_combined_krt_type": combined_krt_type

    }



#####################################################################
# ADD QA VARIABLES
#####################################################################
# generates booleans for each of the quality assurance criteria

def add_qa_inex_variables(
    index_date
):
    
    return {

        # known sex that is male or female
        "inex_qa_bin_sex": (
            (patients.sex == "male") |
            (patients.sex == "female")
        ),

        # known region
        "inex_qa_bin_region": (
            practice_registrations
            .for_patient_on(index_date)
            .practice_nuts1_region_name
            .is_not_null()
        ),

        # known ethnicity
        "inex_qa_bin_ethnicity": (
            get_latest_ethnicity(index_date, ethnicity_snomed, grouping=6)
            .is_not_null()
        ),

        # known IMD
        "inex_qa_bin_imd": (
            get_imd(index_date, groups=5, max_imd=32844)
            .is_not_null()
        )

    }



#### add_inex_variables() ####

def add_inex_variables(dataset, index_date):

    columns = {
        **add_demographic_inex_variables(
            index_date
        ),
        **add_ckd_inex_variables(
            clinical_events=clinical_events,
            creatinine_codes=creatinine_codes,
            primary_care_ckd45_codes=primary_care_ckd45_codes,
            primary_care_ckd4_codes=primary_care_ckd4_codes,
            primary_care_ckd5_codes=primary_care_ckd5_codes,
            index_date=index_date,
        ),
        **add_krt_inex_variables(
            clinical_events=clinical_events,
            apcs=apcs,
            primary_care_krt_codes_all=primary_care_krt_codes_all,
            primary_care_dialysis_codes=primary_care_dialysis_codes,
            primary_care_ktx_codes=primary_care_ktx_codes,
            secondary_care_krt_codes_opcs4=secondary_care_krt_codes_opcs4,
            secondary_care_dialysis_codes_opcs4=secondary_care_dialysis_codes_opcs4,
            secondary_care_ktx_codes_opcs4=secondary_care_ktx_codes_opcs4,
            secondary_care_krt_codes_icd10=secondary_care_krt_codes_icd10,
            secondary_care_dialysis_codes_icd10=secondary_care_dialysis_codes_icd10,
            secondary_care_ktx_codes_icd10=secondary_care_ktx_codes_icd10,
            index_date=index_date,
        ),
        **add_qa_inex_variables(
            index_date
        )
    }

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
