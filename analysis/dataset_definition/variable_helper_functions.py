##########################################################################
# Acknowledgment goes to individuals from Bristol EHR group who wrote 
# these ehrQL helper functions which we're reusing/adapting
# https://github.com/opensafely/post-covid-neurodegenerative/blob/main/
# analysis/dataset_definition/variable_helper_functions.py (for example)
#
# Reusable ehrQL functions used across the study
##########################################################################

from ehrql import when, case, days

from ehrql.tables.tpp import (
    clinical_events,
    ethnicity_from_sus,
    addresses,
    apcs,
    medications,
)


##########################################################################
# Ethnicity
##########################################################################
# Checks clinical_events for ethnicity SNOMED codes; if absent, falls back to
# the ethnicity_from_sus table. 'grouping' returns either a 6 or 16 category
# breakdown.

def get_latest_ethnicity(
        index_date, codelist, grouping=6
    ):
        latest_ethnicity_from_codes_category_num = (
            clinical_events.where(clinical_events.snomedct_code.is_in(codelist))
            .where(clinical_events.date.is_on_or_before(index_date))
            .sort_by(clinical_events.date)
            .last_for_patient()
            .snomedct_code.to_category(codelist)
        )

        if grouping == 6:
            latest_ethnicity_from_codes = case(
                when(latest_ethnicity_from_codes_category_num == "1").then("White"),
                when(latest_ethnicity_from_codes_category_num == "2").then("Mixed"),
                when(latest_ethnicity_from_codes_category_num == "3").then("Asian"), # Asian or Asian British
                when(latest_ethnicity_from_codes_category_num == "4").then("Black"), # Black or Black British
                when(latest_ethnicity_from_codes_category_num == "5").then("Other"), # Chinese or Other Ethnic group
            )

            ethnicity_sus = case(
                when(ethnicity_from_sus.code.is_in(["A", "B", "C"])).then("White"),
                when(ethnicity_from_sus.code.is_in(["D", "E", "F", "G"])).then("Mixed"),
                when(ethnicity_from_sus.code.is_in(["H", "J", "K", "L"])).then("Asian"),
                when(ethnicity_from_sus.code.is_in(["M", "N", "P"])).then("Black"),
                when(ethnicity_from_sus.code.is_in(["R", "S"])).then("Other"),
            )

        elif grouping == 16:
            latest_ethnicity_from_codes = case(
                when(latest_ethnicity_from_codes_category_num == "1").then("White British"),
                when(latest_ethnicity_from_codes_category_num == "2").then("White Irish"),
                when(latest_ethnicity_from_codes_category_num == "3").then("Other White"),
                when(latest_ethnicity_from_codes_category_num == "4").then("White and Caribbean"),
                when(latest_ethnicity_from_codes_category_num == "5").then("White and African"),
                when(latest_ethnicity_from_codes_category_num == "6").then("White and Asian"),
                when(latest_ethnicity_from_codes_category_num == "7").then("Other Mixed"),
                when(latest_ethnicity_from_codes_category_num == "8").then("Indian"),
                when(latest_ethnicity_from_codes_category_num == "9").then("Pakistani"),
                when(latest_ethnicity_from_codes_category_num == "10").then("Bangladeshi"),
                when(latest_ethnicity_from_codes_category_num == "11").then("Other Asian"),
                when(latest_ethnicity_from_codes_category_num == "12").then("Caribbean"),
                when(latest_ethnicity_from_codes_category_num == "13").then("African"),
                when(latest_ethnicity_from_codes_category_num == "14").then("Other Black"),
                when(latest_ethnicity_from_codes_category_num == "15").then("Chinese"),
                when(latest_ethnicity_from_codes_category_num == "16").then("All other ethnic groups"),
            )

            ethnicity_sus = case(
                when(ethnicity_from_sus.code == "A").then("White British"),
                when(ethnicity_from_sus.code == "B").then("White Irish"),
                when(ethnicity_from_sus.code == "C").then("Other White"),
                when(ethnicity_from_sus.code == "D").then("White and Caribbean"),
                when(ethnicity_from_sus.code == "E").then("White and African"),
                when(ethnicity_from_sus.code == "F").then("White and Asian"),
                when(ethnicity_from_sus.code == "G").then("Other Mixed"),
                when(ethnicity_from_sus.code == "H").then("Indian"),
                when(ethnicity_from_sus.code == "J").then("Pakistani"),
                when(ethnicity_from_sus.code == "K").then("Bangladeshi"),
                when(ethnicity_from_sus.code == "L").then("Other Asian"),
                when(ethnicity_from_sus.code == "M").then("Caribbean"),
                when(ethnicity_from_sus.code == "N").then("African"),
                when(ethnicity_from_sus.code == "P").then("Other Black"),
                when(ethnicity_from_sus.code == "R").then("Chinese"),
                when(ethnicity_from_sus.code == "S").then("All other ethnic groups"),
            )

        ethnicity_combined = case(
            when(latest_ethnicity_from_codes.is_not_null()).then(
                latest_ethnicity_from_codes
            ),
            when(
                latest_ethnicity_from_codes.is_null() & ethnicity_sus.is_not_null()
            ).then(ethnicity_sus),
            otherwise="Missing",
        )

        return ethnicity_combined


##########################################################################
# IMD
##########################################################################
# Uses addresses.imd_rounded which maps each LSOA's IMD rank to the nearest
# 100 (values >=0 and <=32800). 1 is most deprived. Categorises IMD into n
# equal-sized groups (groups = n) and returns their ordinal value and a label.

def get_imd(
    index_date, groups=5, max_imd=32844
    ):
    step = max_imd / groups
    whens = []

    imd = addresses.for_patient_on(index_date).imd_rounded

    for i in range(groups):
        lower = int(step * i)
        upper = int(step * (i + 1))

        if i == 0:
            label = "1 (most deprived)"
        elif i == groups - 1:
            label = f"{groups} (least deprived)"
        else:
            label = str(i + 1)

        condition = (imd >= lower) & (imd < upper)
        whens.append(when(condition).then(label))

    imd_grouped=case(
        *whens,
        otherwise= None,
    )

    return imd_grouped


##########################################################################
# Simple pre-index medication counts
##########################################################################
# Count of prescriptions in the days_before_index window up to index_date.
# Warning: duplicate rows (same date + dmd code) are counted twice.
def count_recent_meds(index_date, days_before_index=90):
    wanted_medications = medications.where(
        medications.date.is_on_or_before(index_date) &
        medications.date.is_on_or_after(index_date - days(days_before_index))
    )
    return wanted_medications.count_for_patient()


##########################################################################
# Generic extractors
##########################################################################
# TODO: need to refactor all variable extractions to use these functions
# TODO: decide whether should change .is_on_or_before() to .is_before()

# --- clinical_events, SNOMED -------------------------------------------
def ever_matching_event_clinical_snomed_before(codelist, index_date, where=True):
    return (
        clinical_events
        .where(clinical_events.snomedct_code.is_in(codelist))
        .where(clinical_events.date.is_on_or_before(index_date))
        .where(where)
    )

def last_matching_event_clinical_snomed_before(codelist, index_date, where=True):
    return (
        ever_matching_event_clinical_snomed_before(codelist, index_date, where)
        .sort_by(clinical_events.date)
        .last_for_patient()
    )

# --- clinical_events, ctv3 -------------------------------------------
def ever_matching_event_clinical_ctv3_before(codelist, index_date, where=True):
    return (
        clinical_events
        .where(clinical_events.ctv3_code.is_in(codelist))
        .where(clinical_events.date.is_on_or_before(index_date))
        .where(where)
    )

def last_matching_event_clinical_ctv3_before(codelist, index_date, where=True):
    return (
        ever_matching_event_clinical_ctv3_before(codelist, index_date, where)
        .sort_by(clinical_events.date)
        .last_for_patient()
    )


# --- apcs, ICD-10 diagnoses --------------------------------------------
def ever_matching_event_apcs_icd10_before(
        codelist, index_date, only_prim_diagnoses=False, where=True):
    query = (
        apcs
        .where(apcs.admission_date.is_on_or_before(index_date))
        .where(where)
    )
    if only_prim_diagnoses:
        return query.where(apcs.primary_diagnosis.is_in(codelist)
        )
    else:
        return query.where(apcs.all_diagnoses.contains_any_of(codelist))


def last_matching_event_apcs_icd10_before(
        codelist, index_date, only_prim_diagnoses=False, where=True):
    return (
        ever_matching_event_apcs_icd10_before(
            codelist, index_date, only_prim_diagnoses, where)
        .sort_by(apcs.admission_date)
        .last_for_patient()
    )


# --- apcs, OPCS-4 procedures -------------------------------------------
def ever_matching_procedure_apcs_opcs4_before(codelist, index_date, where=True):
    return (
        apcs
        .where(apcs.all_procedures.contains_any_of(codelist))
        .where(apcs.admission_date.is_on_or_before(index_date))
        .where(where)
    )


# --- medications, dmd --------------------------------------------------
def ever_matching_med_dmd_before(codelist, index_date, where=True):
    return (
        medications
        .where(medications.dmd_code.is_in(codelist))
        .where(medications.date.is_on_or_before(index_date))
        .where(where)
    )

def matching_med_dmd_between(codelist, start_date, end_date, where=True):
    return (
        medications
        .where(medications.dmd_code.is_in(codelist))
        .where(medications.date.is_on_or_between(start_date, end_date))
        .where(where)
    )

def last_matching_med_dmd_between(codelist, start_date, end_date, where=True):
    return(
        medications.where(where)
        .where(medications.dmd_code.is_in(codelist))
        .where(medications.date.is_on_or_between(start_date, end_date))
        .sort_by(medications.date)
        .last_for_patient()
    )

def first_matching_med_dmd_between(codelist, start_date, end_date, where=True):
    return(
        medications.where(where)
        .where(medications.dmd_code.is_in(codelist))
        .where(medications.date.is_on_or_between(start_date, end_date))
        .sort_by(medications.date)
        .first_for_patient()
    )
