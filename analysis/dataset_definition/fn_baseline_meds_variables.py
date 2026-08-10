##########################################################################
# This script writes functions to extract medication-related variables for
# use in dataset_definition_baseline_meds.py
##########################################################################

from ehrql import days
from ehrql.tables.tpp import medications

####################################################################################
# add_recent_prescriptions
# ##################################################################################
# This function returns all the most recent prescriptions between the index date and
# and the days_before_index. Works backwards in time up to max_meds prescriptions.

# Output columns are med_dmd_code_1, med_date_1, med_dmd_code_2, med_date_2, etc.
# med_dmd_code_1 is the most recent prescription.

# Same-day prescriptions are ordered lexicographically by dmd_code string
# (not numerically). Rows with identical date and dmd_code are treated as duplicates 
# and collapsed to one entry.
####################################################################################

def add_recent_prescriptions(index_date, max_meds=90, days_before_index=180):

    # take all precriptions between the index_date and days_before_index
    remaining = medications.where(
        medications.date.is_on_or_before(index_date) &
        medications.date.is_on_or_after(index_date - days(days_before_index))
    ).sort_by(
        medications.date,
        medications.dmd_code,
    )

    output = {}

    for i in range(1, max_meds + 1):

        current = remaining.last_for_patient() # most recent still remaining
        current_date = current.date
        current_code = current.dmd_code

        # store the current dates and codes in the output
        output[f"med_dmd_code_{i}"] = current_code
        output[f"med_date_{i}"] = current_date

        # remaining = remaining prescriptions
        remaining = remaining.where(
            medications.date.is_before(current_date) |
            (
                (medications.date == current_date) &
                (medications.dmd_code != current_code)
            )
        )

    return output


#############################################################################
# add_prescription_columns
#############################################################################
# this simply adds the columns defined in add_recent_prescriptions() to the
# dataset.
#############################################################################

def add_prescription_columns(dataset, index_date, max_meds=10, days_before_index=90):

    for name, expr in add_recent_prescriptions(
        index_date,
        max_meds=max_meds,
        days_before_index=days_before_index
        ).items():
        dataset.add_column(name, expr)

