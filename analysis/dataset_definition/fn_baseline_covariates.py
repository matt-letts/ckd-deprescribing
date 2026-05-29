##########################################################################
# This script defines functions to extract baseline covariates
# add_baseline_covariates() then defines the function to add them to
# dataset (dataset_definition_baseline_covariates.py)

# See protocols/protocol.md for full list of included covariates
##########################################################################

from ehrql import (
    when,
    case,
    days,
)

from ehrql.tables.tpp import (
    clinical_events,
    ethnicity_from_sus,
    addresses,
    apcs,
    medications
)

from codelists import *

import json
with open("output/study_dates.json") as f:
    index_date = json.load(f)["index_date"]

##########################################################################
# Age
##########################################################################
# Defined in dataset_inex_cleaned - pulled through with table_from_file
# Age as integer, in whole elapsed calendar years


##########################################################################
# Sex
##########################################################################
# Defined in dataset_inex_cleaned - pulled through with table_from_file
# male/female only (others excluded in inex stage) as string


##########################################################################
# Ethnicity
##########################################################################
# get_latest_ethnicity() checks clinical_events table for ethnicity 
# snomed codes. If absent then checks for ethnicity codes within 
# ethnicity_from_sus table. 
# 'grouping' returns results as either a 6 or 16 category breakdown

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
                when(latest_ethnicity_from_codes_category_num == "3").then("Asian"),
                when(latest_ethnicity_from_codes_category_num == "4").then("Black"),
                when(latest_ethnicity_from_codes_category_num == "5").then("Other"),
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
            otherwise = None,
        )

        return ethnicity_combined


##########################################################################
# eGFR
##########################################################################
# Defined in dataset_inex_cleaned - pulled through with table_from_file
# most recent eGFR calculated from SCr - float, with corresponding date
# most recent coded ckd stage, string


##########################################################################
# Number of chronic prescriptions
##########################################################################
# Defined in dataset_baseline_meds_analysed - will combine at later stage


##########################################################################
# IMD
##########################################################################
# get_imd() uses addresses.imd_rounded which maps each LSOA's IMD rank
# to the nearest 100 (values >=0 and <=32800). 1 is most deprived.
# Categorises IMD into n equal sized groups (groups = n) and returns 
# their ordinal value and a label

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

#####################################################################   
# Risk of mortality
#####################################################################
# Using the CKD prognosis consortium advanced CKD risk tool
# https://ckdpcrisk.org/lowgfrevents/ 
# 
# Needs 8 variables: 
# - age (int), already imported from dataset_inex_cleaned
# - sex (M/F), already imported from dataset_inex_cleaned
# - race (black/non-black), this distinction is contested, and US  
#   groups may not reflect UK groups. Plan to treat all as non-black 
#   initially with sensitivity analyses exploring alternatives
# - eGFR (int), already imported from dataset_inex_cleaned
# - systolic BP (int)
# - history of cardiovascular disease, 
# - diabetes, 
# - uACR, 
# - smoking history.

# Systolic BP
most_recent_sbp = (
    clinical_events
        .where(clinical_events.snomedct_code.is_in(sbp_codes))
        .where(clinical_events.numeric_value.is_not_null())
        .where(clinical_events.date.is_on_or_before(index_date))
        .sort_by(clinical_events.date)
        .last_for_patient()
    )

# History of CV disease: previous MI, coronary revascularisation, 
# heart failure, stroke 

# previous MI or coronary revascularisation
mi_primary_care = (
    clinical_events
        .where(clinical_events.snomedct_code.is_in(mi_codes_snomed))
        .where(clinical_events.date.is_on_or_before(index_date))
        .exists_for_patient()
    )

mi_secondary_care = (
    apcs
        .where(apcs.all_diagnoses.contains_any_of(mi_codes_icd10))
        .where(apcs.admission_date.is_on_or_before(index_date))
        .exists_for_patient()
    )

coronary_revasc = (
    apcs
        .where(apcs.all_procedures.contains_any_of(coronary_revasc_codes))
        .where(apcs.admission_date.is_on_or_before(index_date))
        .exists_for_patient()
    )

mi_or_coronary_revasc = mi_primary_care | mi_secondary_care | coronary_revasc

# previous stroke
cva_primary_care = (
    clinical_events
        .where(clinical_events.snomedct_code.is_in(cva_codes_snomed))
        .where(clinical_events.date.is_on_or_before(index_date))
        .exists_for_patient()
    )

cva_secondary_care = (
    apcs
        .where(apcs.all_diagnoses.contains_any_of(cva_codes_icd10))
        .where(apcs.admission_date.is_on_or_before(index_date))
        .exists_for_patient()
    )

prior_cva = cva_primary_care | cva_secondary_care

# previous HF diagnosis
hf_primary_care = (
    clinical_events
        .where(clinical_events.snomedct_code.is_in(hf_codes_snomed))
        .where(clinical_events.date.is_on_or_before(index_date))
        .exists_for_patient()
    )

hf_secondary_care = (
    apcs
        .where(apcs.all_diagnoses.contains_any_of(hf_codes_icd10))
        .where(apcs.admission_date.is_on_or_before(index_date))
        .exists_for_patient()
    )

prior_hf = hf_primary_care | hf_secondary_care

# Diabetes Y/N 

# CKD PC defined depending on the cohort as:
# - fasting glucose ≥7.0 mmol/l (126 mg/dl),
# - nonfasting glucose ≥11.1 mmol/l (200 mg/dl),
# - hemoglobin A1c ≥6.5%, 
# - use of glucose-lowering drugs,
# - or self-reported diabetes

# Decided against using OpenSAFELY diabetes-algo action
# as distinction between different types of diabetes not required
# https://actions.opensafely.org/actions/diabetes-algo/v0.0.13/

# Operationalised with snomed/icd10 codes, meds and hba1c:
t1dm_diagnosis = (
    clinical_events
        .where(clinical_events.snomedct_code.is_in(dm1_codes_snomed))
        .where(clinical_events.date.is_on_or_before(index_date))
        .exists_for_patient()
    )

other_dm_diagnosis = (
    clinical_events
        .where(clinical_events.snomedct_code.is_in(dm_not1_codes_snomed))
        .where(clinical_events.date.is_on_or_before(index_date))
        .exists_for_patient()
    )

recent_hba1c = (
    clinical_events
        .where(clinical_events.snomedct_code.is_in(hba1c_codes_snomed))
        .where(clinical_events.date.is_on_or_before(index_date))
        .sort_by(clinical_events.date)
        .last_for_patient()
        .numeric_value
)

diabetes_drugs = (
    medications
        .where(medications.dmd_code.is_in(dm_drug_codes_dmd))
        .where(medications.date.is_on_or_before(index_date))
        .exists_for_patient()
)

diabetes = t1dm_diagnosis | other_dm_diagnosis | (recent_hba1c >= 48) | diabetes_drugs 


# general conversion of uPCR to uACR - dividing by 2.655 for men and 1.7566 for women
# this division conversion applied to mg/g or mg/mmol.


# Frailty (see below)
# Presence or absence of comorbidities
# Clinical events e.g. falls/hospitalisations


#####################################################################
# COMBINE ALL COVARIATE VARIABLES INTO ONE FUNCTION
#####################################################################

def add_baseline_covariates(dataset, dataset_inex_cleaned):

    columns = {
        # rename columns from dataset_inex_cleaned
        "basecov_num_age": dataset_inex_cleaned.inex_dem_num_age,
        "basecov_cat_sex": dataset_inex_cleaned.inex_dem_cat_sex,
        "basecov_num_egfr_1": dataset_inex_cleaned.inex_num_egfr_1,
        "basecov_date_egfr_1": dataset_inex_cleaned.inex_ckd_date_scr_date_1,
        "basecov_cat_coded_ckd_stage": dataset_inex_cleaned.inex_ckd_cat_ckd_code_stage,

        # new columns to be added
        "basecov_cat_ethnicity": get_latest_ethnicity(index_date, ethnicity_codes, grouping=6),
        "basecov_cat_imd": get_imd(index_date, groups=5, max_imd=32844),
        "basecov_num_sbp": most_recent_sbp.numeric_value,
        "basecov_date_sbp": most_recent_sbp.date,
        "basecov_bin_mi_or_revasc": mi_or_coronary_revasc,
        "basecov_bin_cva": prior_cva,
        "basecov_bin_hf": prior_hf,
        "basecov_bin_dm": diabetes
    }

    for name, expr in columns.items():
        dataset.add_column(name, expr)



