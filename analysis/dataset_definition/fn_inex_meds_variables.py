##########################################################################
# This script writes functions to extract medication-related variables for
# use in dataset_definition_inex_meds.py
##########################################################################

from ehrql import days
from ehrql.tables.tpp import medications
from fn_misc_variables import count_recent_meds

#########################################################################################
# add_recent_prescriptions
# #######################################################################################
# This function returns a dictionary of patient-level columns representing the most recent
# prescriptions in the 'days_before_index' number of days prior to (and including)
# index_date, working backwards in time up to max_meds prescriptions.

# Columns are named med_dmd_code_1, med_date_1, med_dmd_code_2, med_date_2, etc.
# where med_dmd_code_1 is the most recent prescription.

# Same-day prescriptions are ordered lexicographically by dmd_code string
# (not numerically), which is arbitrary but consistent. Rows with identical
# date and dmd_code are treated as duplicates and collapsed to one entry.
##########################################################################################

def add_recent_prescriptions(index_date, max_meds=10, days_before_index=90):

    # restrict to precriptions within days_before_index before (and including) index_date
    base = medications.where(
        medications.date.is_on_or_before(index_date) &
        medications.date.is_on_or_after(index_date - days(days_before_index))
    ).sort_by(
        medications.date,
        medications.dmd_code,
    )

    output = {}

    # Python lists tracking which date+code combinations have already been
    # selected in previous iterations, used to exclude them from remaining.
    prev_dates = []
    prev_codes = []

    for i in range(1, max_meds + 1):

        # start from full base frame and progressively exclude all
        # previously selected date + code combinations
        remaining = base
        for prev_date, prev_code in zip(prev_dates, prev_codes):
            # keep only those that are:
            # - strictly before the previous date OR
            # - on the same date but a different dmd code
            remaining = remaining.where(
                medications.date.is_before(prev_date) |
                (
                    (medications.date == prev_date) &
                    (medications.dmd_code != prev_code)
                )
            )

        current = remaining.last_for_patient() # most recent still remaining

        # store the current dates and codes
        output[f"med_dmd_code_{i}"] = current.dmd_code
        output[f"med_date_{i}"] = current.date

        # update the lists to include the most recently used dates and codes
        prev_dates = prev_dates + [current.date]
        prev_codes = prev_codes + [current.dmd_code]

    return output


#############################################################################
# add_prescription_columns
#############################################################################
# this simply adds the columns defined in add_recent_prescriptions() to the 
# dataset, and also adds a column counting the number of prescriptions in the 
# specified time window (note count_recent_meds does not collapse duplicates)
#############################################################################

def add_prescription_columns(dataset, index_date, max_meds=10, days_before_index=90):

    for name, expr in add_recent_prescriptions(
        index_date,
        max_meds=max_meds,
        days_before_index=days_before_index
        ).items():
        dataset.add_column(name, expr)

    dataset.add_column("med_num_count", count_recent_meds(
        index_date,
        days_before_index=days_before_index)
        )
