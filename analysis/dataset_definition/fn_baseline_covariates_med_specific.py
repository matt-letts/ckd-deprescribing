##########################################################################
# Medicine-specific baseline covariates
#
# add_baseline_covariates_med_specific() adds the baseline covariates 
# that are relevant to a particular target medicine (e.g. GI bleeding 
# history for PPIs) to the dataset. 
# 
# Columns named basecov_{med}_{type}_{name}.
#
# Portability: to add a medicine, add its codelists to codelists.py (prefixed
# with the medicine name) and add a new `if med == "<name>"` section in
# add_medicine_covariates() below. The active medicine is passed in from the
# dataset definition via get_parameter("medicine").
##########################################################################

from codelists import *

from variable_helper_functions import (
    ever_matching_event_clinical_snomed_before,
    ever_matching_event_apcs_icd10_before,
    ever_matching_procedure_apcs_opcs4_before
)


#####################################################################
# ADD MEDICINE-SPECIFIC COVARIATES TO DATASET
#####################################################################

def add_baseline_covariates_med_specific(dataset, medicine, index_date):

    ##################################################################
    # PPI (proton pump inhibitors)
    ##################################################################

    if medicine == "ppi":
        columns = {
            "basecov_ppi_bin_hf": (
                 ever_matching_event_clinical_snomed_before(hf_codes_snomed, index_date).exists_for_patient()
                | ever_matching_event_apcs_icd10_before(hf_codes_icd10, index_date).exists_for_patient()
            ),
        }

    ##################################################################
    # Statins 
    ##################################################################

    elif medicine == "statin":
        columns = {
            "basecov_statin_bin_mi": (
                ever_matching_event_clinical_snomed_before(mi_codes_snomed, index_date).exists_for_patient()
                | ever_matching_event_apcs_icd10_before(mi_codes_icd10, index_date).exists_for_patient()
                | ever_matching_procedure_apcs_opcs4_before(coronary_revasc_codes_opcs4, index_date).exists_for_patient()
            ),
        }

    ##################################################################
    # Add further medicines here, e.g.:
    # elif medicine == "XX":
    #     ...
    ##################################################################

    else:
        raise ValueError(
            f"No medicine-specific covariates defined for medicine type: '{medicine}'. "
            "Add an `if medicine == ...` section in fn_baseline_covariates_med_specific.py."
        )

    for name, expr in columns.items():
        dataset.add_column(name, expr)
