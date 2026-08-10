##########################################################################
# This script writes functions to extract medication-related variables for
# use in dataset_definition_followup_meds.py
##########################################################################

from ehrql import days
from ehrql.tables.tpp import medications

####################################################################################
# add_future_prescriptions
# ##################################################################################
# This function mirrors add_recent_prescriptions from analysis/dataset_definition/
# fn_baseline_meds_variables.py
# 
# Returns all the prescriptions of medications that have dmd codes within 
# dmd_codelists between the index date and the study end_date. 
# Works forwards in time up to max_meds prescriptions.
# Have to specify a max_meds so have a set number of columns - although I actually
# just want to pull as many columns as there are prescriptions. 100 is realistic max
####################################################################################

def add_followup_prescriptions(index_date, end_date, dmd_codelist, max_meds=100):
    remaining = medications.where(
        medications.dmd_code.is_in(dmd_codelist) &
        medications.date.is_after(index_date) &
        medications.date.is_on_or_before(end_date)
    ).sort_by(
        medications.date,
        medications.dmd_code,
    )

    output = {}

    for i in range(1, max_meds + 1):

        current = remaining.first_for_patient()
        current_date = current.date
        current_code = current.dmd_code

        output[f"med_dmd_code_{i}"] = current_code
        output[f"med_date_{i}"] = current_date

        remaining = remaining.where(
            medications.date.is_after(current_date) |
            (
                (medications.date == current_date) &
                (medications.dmd_code != current_code)
            )
        )
    return output


#############################################################################
# add_prescription_columns
#############################################################################
# this simply adds the columns defined in add_followup_prescriptions() to the
# dataset.
#############################################################################

def add_followup_prescription_columns(dataset, index_date, end_date, dmd_codelist, max_meds=100):
    for name, expr in add_followup_prescriptions(
        index_date, end_date, dmd_codelist, max_meds=max_meds
    ).items():
        dataset.add_column(name, expr)