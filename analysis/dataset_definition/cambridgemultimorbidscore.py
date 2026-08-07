######################################################################
# acknowledgments to Bristol team working on OpenSAFELY 
# Neurodegenerative disease burden project who wrote these functions
# https://github.com/opensafely/NeurodegenerativeDiseaseBurden/blob/
# 33c6a297c0e46a49643890363e4aca9191f87ed0/analysis/
# dataset_definition/variable_helper_functions.py
######################################################################

from ehrql import case, when
from ehrql.tables.tpp import patients, clinical_events
from codelists import *

# Function to check dates are valid (i.e., not before or after death)

def check_date_validity(
    date_to_check,
    death_date,
    check_not_before_dob=True,
    check_not_after_death=True
):

    conditions = []

    ## Base requirement: must not be null
    conditions.append(date_to_check.is_not_null())

    ## Check not before DOB
    if check_not_before_dob:
        conditions.append(
            patients.date_of_birth.is_null()
            | (date_to_check >= patients.date_of_birth)
        )

    ## Check not after death
    if check_not_after_death:
        conditions.append(
            death_date.is_null()
            | (date_to_check <= death_date)
        )

    ## Combine all validity conditions
    is_valid = conditions[0]
    for cond in conditions[1:]:
        is_valid = is_valid & cond

    return case(
        when(is_valid).then(date_to_check),
        otherwise=None
    )

# Function to obtain Cambridge multimorbidity score

def get_cms_on_date(date, death_date, return_components=False):

    cms = clinical_events.exists_for_patient().as_int().as_float() * 0
    components = {}

    for name, codelist, weight in [
        ("alcohol", alcohol_codelist, 0.65),
        ("anxiety", anxiety_codelist, 0.50),
        ("af", af_codelist, 1.34),
        ("cancer", cancer_codelist, 1.53),
        ("ckd", ckd_codelist, 0.53),
        ("tissue", tissue_codelist, 0.43),
        ("copd", copd_codelist, 1.46),
        ("chd", chd_codelist, 0.49),
        ("dementia", dementia_codelist, 2.50),
        ("diabetes", diabetes_codelist, 0.75),
        ("epilepsy", epilepsy_codelist, 0.92),
        ("hearing_loss", hearloss_codelist, 0.09),
        ("hf", hf_codelist, 1.18),
        ("bowel", bowel_codelist, 0.21),
        ("psychosis", psychosis_codelist, 0.64),
        ("stroke", stroke_codelist, 0.80),
        ("asthma", asthma_codelist, 0.19),
        ("hypertension", hypertension_codelist, 0.08),
        ("constipation", constipation_codelist, 1.12),
        ("pain", pain_codelist, 0.92),
    ]:

        filtered = clinical_events.where(
            clinical_events.snomedct_code.is_in(codelist)
        ).where(
            clinical_events.date.is_before(date)
        )

        binary = (
            filtered.where(
                check_date_validity(filtered.date, death_date=death_date).is_not_null()
            )
            .exists_for_patient()
            .as_int()
        )

        cms += binary.as_float() * weight

        if return_components:
            components[name] = binary

    if return_components:
        components["cms"] = cms
        return components

    return cms