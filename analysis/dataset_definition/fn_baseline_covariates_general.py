###############################################################################
# This script defines baseline covariates that are common to all analyses.
# 
# add_baseline_covariates_general() is then a function to pull all 
# the variables into a list which will then be added to the dataset
# (dataset_definition_baseline_covariates_general.py)

# See protocols/protocol.md for full list of included covariates
###############################################################################

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
    medications,
    practice_registrations
)

from codelists import *

from variable_helper_functions import (
    get_latest_ethnicity,
    get_imd,
    ever_matching_event_clinical_snomed_before,
    last_matching_event_clinical_snomed_before,
    ever_matching_event_apcs_icd10_before,
    ever_matching_procedure_apcs_opcs4_before,
    matching_med_dmd_between,
)

import json
with open("output/study_dates.json") as f:
    index_date = json.load(f)["index_date"]

##############################################################################
# Age
##############################################################################
# Defined in dataset_inex_cleaned - pulled through with table_from_file. Age
# as integer, in whole elapsed calendar years


############################################################################## 
# Sex
##############################################################################
# Defined in dataset_inex_cleaned - pulled through with table_from_file
# male/female only (others excluded in inex stage) as string


##############################################################################
# Ethnicity
##############################################################################
# get_latest_ethnicity() is defined in variable_helper_functions.py: checks
# clinical_events for ethnicity SNOMED codes, falls back to ethnicity_from_sus
# and returns a 6- or 16-category breakdown.


############################################################################## 
# eGFR
##############################################################################
# Defined in dataset_inex_cleaned - pulled through with table_from_file most
# recent eGFR calculated from SCr - float, with corresponding date most recent
# coded ckd stage, string


##############################################################################
# Number of chronic prescriptions
##############################################################################
# Defined in dataset_baseline_meds_analysed - will combine at later stage


##############################################################################
# IMD
##############################################################################
# get_imd() is defined in variable_helper_functions.py: buckets
# addresses.imd_rounded at index_date into n equal-sized groups (1 = most
# deprived) and returns an ordinal label.


##############################################################################
# Region
##############################################################################
# NUTS1 region name of the patient's registered practice at index_date (same
# source as the inex QA region check)
region = (
    practice_registrations
    .for_patient_on(index_date)
    .practice_nuts1_region_name
)

##############################################################################
# Care home residence
##############################################################################
# Derived from the addresses table rather than a codelist. Uses TPP's 
# potential care-home match flag at index_date.
care_home = case(
    when(
        addresses.for_patient_on(index_date).care_home_is_potential_match
    ).then(True),
    otherwise=False,
)

##############################################################################
# Clinical values (most recent on or before index)
##############################################################################
most_recent_sbp = last_matching_event_clinical_snomed_before(
    sbp_codes, index_date, where=clinical_events.numeric_value.is_not_null()
    )

# most_recent_cholesterol = last_matching_event_clinical_snomed_before(
#     cholesterol_codes_snomed, index_date, where=clinical_events.numeric_value.is_not_null()
#     )

##############################################################################
# History of CV disease: previous MI, coronary revascularisation, heart 
# failure, stroke 
##############################################################################
# Previous MI or coronary revascularisation
mi_or_coronary_revasc = (
    ever_matching_event_clinical_snomed_before(mi_codes_snomed, index_date).exists_for_patient()
    | ever_matching_event_apcs_icd10_before(mi_codes_icd10, index_date).exists_for_patient()
    | ever_matching_procedure_apcs_opcs4_before(coronary_revasc_codes_opcs4, index_date).exists_for_patient()
)

# Previous stroke
prior_cva = (
    ever_matching_event_clinical_snomed_before(cva_codes_snomed, index_date).exists_for_patient()
    | ever_matching_event_apcs_icd10_before(cva_codes_icd10, index_date).exists_for_patient()
)

# Previous HF diagnosis
prior_hf = (
    ever_matching_event_clinical_snomed_before(hf_codes_snomed, index_date).exists_for_patient()
    | ever_matching_event_apcs_icd10_before(hf_codes_icd10, index_date).exists_for_patient()
)

cvd_history = mi_or_coronary_revasc | prior_cva | prior_hf

##############################################################################
# Diabetes Y/N 
##############################################################################
# https://www.kidney-international.org/article/S0085-2538(18)30097-8/fulltext
# CKD PC defined diabetes in various ways depending on which cohort used:
# - fasting glucose ≥7.0 mmol/l (126 mg/dl),
# - nonfasting glucose ≥11.1 mmol/l (200 mg/dl),
# - hemoglobin A1c ≥6.5%, 
# - use of glucose-lowering drugs,
# - or self-reported diabetes

# For our study decided against using OpenSAFELY diabetes-algo action as
# distinction between different types of diabetes not required
# https://actions.opensafely.org/actions/diabetes-algo/v0.0.13/

# Operationalised here with snomed/icd10 codes, meds and hba1c:

t1dm_diagnosis = ever_matching_event_clinical_snomed_before(dm1_codes_snomed, index_date).exists_for_patient()

other_dm_diagnosis = ever_matching_event_clinical_snomed_before(dm_not1_codes_snomed, index_date).exists_for_patient()

recent_hba1c = last_matching_event_clinical_snomed_before(
    hba1c_codes_snomed, index_date, where=clinical_events.numeric_value.is_not_null()
).numeric_value

diabetes_drugs = matching_med_dmd_between(dm_drug_codes_dmd, index_date - days(365), index_date).exists_for_patient()

diabetes = case(
    when(
        t1dm_diagnosis | other_dm_diagnosis | diabetes_drugs | (recent_hba1c >= 48)
    ).then(True),
    otherwise=False,
)

# ##############################################################################
# # Urinary protein/albumin excretion
# ##############################################################################
# # Most recent uACR and uPCR values before index. The uPCR->uACR conversion
# # (divide by 2.655 for men and 1.7566 for women, applied to mg/g or mg/mmol)
# #  is sex-dependent and is left to the R processing stage.
# most_recent_uacr = last_matching_event_clinical_snomed_before(uacr_codes_snomed, index_date, where=numeric_only)
# most_recent_upcr = last_matching_event_clinical_snomed_before(upcr_codes_snomed, index_date, where=numeric_only)

# ##############################################################################
# # Smoking status
# ##############################################################################
# # Most recent smoking status before index, mapped to current/former/never.
# # Assumes the codelist's category column uses S (smoker), E (ex-smoker), N
# # (never) - adjust the mapping when the real codelist is added.
# def get_smoking_status(index_date):
#     latest_smoking_category = (
#         last_matching_event_clinical_snomed_before(smoking_codes_snomed, index_date)
#         .snomedct_code.to_category(smoking_codes_snomed)
#     )
#     return case(
#         when(latest_smoking_category == "S").then("current"),
#         when(latest_smoking_category == "E").then("former"),
#         when(latest_smoking_category == "N").then("never"),
#         otherwise=None,
#     )

# ##############################################################################
# # Frailty
# ##############################################################################
# # Electronic Frailty Index (eFI) is a composite of 36 deficit domains and will
# # be built in a separate script; not scaffolded here.

# ##############################################################################
# # Presence or absence of comorbidities
# ##############################################################################
# liver_disease = (
#     ever_matching_event_clinical_snomed_before(liver_disease_codes_snomed, index_date).exists_for_patient()
#     | ever_matching_event_apcs_icd10_before(liver_disease_codes_icd10, index_date).exists_for_patient()
# )
# cancer = (
#     ever_matching_event_clinical_snomed_before(cancer_codes_snomed, index_date).exists_for_patient()
#     | ever_matching_event_apcs_icd10_before(cancer_codes_icd10, index_date).exists_for_patient()
# )
# dementia = (
#     ever_matching_event_clinical_snomed_before(dementia_codes_snomed, index_date).exists_for_patient()
#     | ever_matching_event_apcs_icd10_before(dementia_codes_icd10, index_date).exists_for_patient()
# )
# copd = (
#     ever_matching_event_clinical_snomed_before(copd_codes_snomed, index_date).exists_for_patient()
#     | ever_matching_event_apcs_icd10_before(copd_codes_icd10, index_date).exists_for_patient()
# )

# # Cardiac procedures (join the CV history above)
# pacemaker = (
#     ever_matching_event_clinical_snomed_before(pacemaker_codes_snomed, index_date).exists_for_patient()
#     | ever_matching_procedure_apcs_opcs4_before(pacemaker_codes_opcs4, index_date).exists_for_patient()
# )
# cardiac_ablation = (
#     ever_matching_event_clinical_snomed_before(cardiac_ablation_codes_snomed, index_date).exists_for_patient()
#     | ever_matching_procedure_apcs_opcs4_before(cardiac_ablation_codes_opcs4, index_date).exists_for_patient()
# )

# ##############################################################################
# # Clinical events e.g. falls/hospitalisations
# ##############################################################################
# # Falls in primary (SNOMED) or secondary (ICD-10) care
# prior_falls = (
#     ever_matching_event_clinical_snomed_before(falls_codes_snomed, index_date).exists_for_patient()
#     | ever_matching_event_apcs_icd10_before(falls_codes_icd10, index_date).exists_for_patient()
# )

# # Most recent inpatient discharge date before index. The relevant look-back
# # window is a design choice and is applied later in the R processing stage.
# last_hosp_discharge_date = (
#     apcs
#     .where(apcs.discharge_date.is_on_or_before(index_date))
#     .sort_by(apcs.discharge_date)
#     .last_for_patient()
#     .discharge_date
# )

# # Structured medication review ever before index
# structured_med_review = ever_matching_event_clinical_snomed_before(
#     structured_med_review_codes_snomed, index_date
# ).exists_for_patient()

# # Most recent move to a care facility before index
# care_facility_move_date = last_matching_event_clinical_snomed_before(
#     care_facility_move_codes_snomed, index_date
# ).date

#########################################################################
# COMBINE ALL COVARIATE VARIABLES INTO ONE FUNCTION
#########################################################################

def add_baseline_covariates_general(dataset, dataset_inex_cleaned):

    columns = {
        # pulled through from dataset_inex_cleaned
        "basecov_gen_num_age": dataset_inex_cleaned.inex_dem_num_age,
        "basecov_gen_cat_sex": dataset_inex_cleaned.inex_dem_cat_sex,
        "basecov_gen_num_egfr_1": dataset_inex_cleaned.inex_num_egfr_1,
        "basecov_gen_date_egfr_1": dataset_inex_cleaned.inex_ckd_date_scr_date_1,
        "basecov_gen_cat_coded_ckd_stage": dataset_inex_cleaned.inex_ckd_cat_ckd_code_stage,

        # demographics
        "basecov_gen_cat_ethnicity": get_latest_ethnicity(index_date, ethnicity_codes, grouping=6),
        "basecov_gen_cat_imd": get_imd(index_date, groups=5, max_imd=32844),
        "basecov_gen_cat_region": region,
        "basecov_gen_bin_care_home": care_home,

        # clinical values
        "basecov_gen_num_sbp": most_recent_sbp.numeric_value,
        "basecov_gen_date_sbp": most_recent_sbp.date,
        # "basecov_gen_num_cholesterol": most_recent_cholesterol.numeric_value,
        # "basecov_gen_date_cholesterol": most_recent_cholesterol.date,
        # "basecov_gen_num_uacr": most_recent_uacr.numeric_value,
        # "basecov_gen_date_uacr": most_recent_uacr.date,
        # "basecov_gen_num_upcr": most_recent_upcr.numeric_value,
        # "basecov_gen_date_upcr": most_recent_upcr.date,

        # smoking
        # "basecov_gen_cat_smoking": get_smoking_status(index_date),

        # comorbidities
        "basecov_gen_bin_dm": diabetes,
        "basecov_gen_bin_cvd_history": cvd_history,
        # "basecov_gen_bin_liver_disease": liver_disease,
        # "basecov_gen_bin_cancer": cancer,
        # "basecov_gen_bin_dementia": dementia,
        # "basecov_gen_bin_copd": copd,

        # recent events / healthcare interaction
        # "basecov_gen_bin_falls": prior_falls,
        # "basecov_gen_date_last_hosp_discharge": last_hosp_discharge_date,
        # "basecov_gen_bin_structured_med_review": structured_med_review,
        # "basecov_gen_date_care_facility_move": care_facility_move_date,
    }

    for name, expr in columns.items():
        dataset.add_column(name, expr)



