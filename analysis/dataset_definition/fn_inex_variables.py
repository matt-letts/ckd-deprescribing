#####################################################################
# This script defines all inclusion and exclusion variables 
# and pulls them into a function add_inex_variables() that is then 
# called into dataset.definition.py to create initial dataset
#####################################################################

#####################################################################
# IMPORTS
#####################################################################

from ehrql.tables.tpp import (
    patients,
    practice_registrations,
    clinical_events,
    ons_deaths,
    apcs,
    medications
)
from ehrql import (
    months,
    days,
    case,
    when
)
from variable_helper_functions import (
    get_imd,
    get_latest_ethnicity,
    count_recent_meds,
    ever_matching_event_clinical_snomed_before,
    ever_matching_event_clinical_ctv3_before,
)
from codelists import *

#####################################################################
# INCLUSION/EXCLUSION FUNCTIONS
#####################################################################

# DEMOGRAPHIC INCLUSION/EXCLUSION VARIABLES -------------------------
# add_demographic_inex_variables generates booleans for each of the
# demographic inclusion/exclusion criteria, and a column for the age 
# and sex. The latter are needed to compute eGFR

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
        "inex_dem_bin_12m_registered": registered_12m, # what about if someone has no end_date on a previous registration and they have two 'active registrations'
        "inex_dem_num_age": age,
        "inex_dem_cat_sex": patients.sex

    }


# CKD INCLUSION/EXCLUSION VARIABLES - CODES AND CREATININE VALUES ---
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
    creatinine_values = ever_matching_event_clinical_snomed_before(
        creatinine_codes,
        index_date,
        where=clinical_events.numeric_value.is_not_null(),
    )

    # Most recent creatinine per patient
    most_recent_creatinine = (
        creatinine_values
        .sort_by(clinical_events.date)
        .last_for_patient()
    )

    # 90-day cutoff from most recent
    cutoff = most_recent_creatinine.date - days(90)

    # Second creatinine at least 90 days earlier (as needed for CKD definition)
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
    coded_ckd45 = ever_matching_event_clinical_snomed_before(
        primary_care_ckd45_codes, index_date
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


# KRT VARIABLES (FOR EXCLUSION) - PRIMARY AND SECONDARY CARE CODES --
# Primary care codes used for exclusion; secondary care codes kept
# with a sensitivity flag (inex_krt_bin_secondary_care_only)

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
    primary_care_krt_code = ever_matching_event_clinical_ctv3_before(
        primary_care_krt_codes_all, index_date
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
        .where(apcs.admission_date.is_on_or_before(index_date))
    )

    # binary flag if a person has a secondary care krt code
    has_secondary_care_krt_code = secondary_care_krt_code.exists_for_patient()

    # Most recent spell containing a secondary care krt code
 
    most_recent_secondary_care_krt_code = (
        secondary_care_krt_code
        .sort_by(apcs.admission_date)
        .last_for_patient()
    )

    # Importantly any spell can contain both transplant and dialysis codes so need
    # quite complex logic to decide whether to categorise as dialysis or transplant
    secondary_care_krt_type = case(
        # sort edge case first where BOTH dialysis AND transplant in same spell → unknown
        when(
            (
                most_recent_secondary_care_krt_code.all_procedures.contains_any_of(
                    secondary_care_dialysis_codes_opcs4
                )
                | most_recent_secondary_care_krt_code.all_diagnoses.contains_any_of(
                    secondary_care_dialysis_codes_icd10
                )
            )
            &
            (
                most_recent_secondary_care_krt_code.all_procedures.contains_any_of(
                    secondary_care_ktx_codes_opcs4
                )
                | most_recent_secondary_care_krt_code.all_diagnoses.contains_any_of(
                    secondary_care_ktx_codes_icd10
                )
            )
        ).then("unknown"),
        # Dialysis only
        when(
            most_recent_secondary_care_krt_code.all_procedures.contains_any_of(
                secondary_care_dialysis_codes_opcs4
            )
            | most_recent_secondary_care_krt_code.all_diagnoses.contains_any_of(
                secondary_care_dialysis_codes_icd10
            )
        ).then("dialysis"),
        # Transplant only
        when(
            most_recent_secondary_care_krt_code.all_procedures.contains_any_of(
                secondary_care_ktx_codes_opcs4
            )
            | most_recent_secondary_care_krt_code.all_diagnoses.contains_any_of(
                secondary_care_ktx_codes_icd10
            )
        ).then("transplant"),
        # Any other KRT-related spell
        when(
            most_recent_secondary_care_krt_code.apcs_ident.is_not_null()
        ).then("unknown"),

        otherwise=None,
    )
    
    ### Return variables ###

    return {

        # Primary care only
        "inex_krt_bin_has_primary_care_krt_code": has_primary_care_krt_code,
        "inex_krt_cat_primary_care_krt_type": primary_care_krt_type,

        # Secondary care only
        "inex_krt_bin_has_secondary_care_krt_code": has_secondary_care_krt_code,
        "inex_krt_cat_secondary_care_krt_type": secondary_care_krt_type,

        # Sensitivity flag: secondary care evidence without primary care evidence
        "inex_krt_bin_secondary_care_only": (
            has_secondary_care_krt_code & ~has_primary_care_krt_code
        ),

    }


# SIMPLE PRE-INDEX DATE MEDICATION COUNTS -----------------------------
# count_recent_meds() is defined in variable_helper_functions.py

def add_medication_inex_variables(
    index_date
):

    return {
        "inex_med_num_90": (
            count_recent_meds(index_date, days_before_index=90)
        ),

        "inex_med_num_180": (
            count_recent_meds(index_date, days_before_index=180)
        )
    }


# QA VARIABLES -------------------------------------------------------
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
            get_latest_ethnicity(index_date, ethnicity_codes, grouping=6)
            .is_not_null()
        ),

        # known IMD
        "inex_qa_bin_imd": (
            get_imd(index_date, groups=5, max_imd=32844)
            .is_not_null()
        )

    }


#####################################################################
# COMBINE ALL ABOVE VARIABLES INTO ONE FUNCTION TO ADD TO DATASET
#####################################################################

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
        ),
        **add_medication_inex_variables(
            index_date
        )
    }

    for name, expr in columns.items():
        dataset.add_column(name, expr)
        