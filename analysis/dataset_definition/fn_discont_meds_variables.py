##########################################################################
# Medication of interest (MOI) prescription extraction code for the
# discontinuation analysis. This uses dmd codelists for the various mois
##########################################################################

from ehrql import days
from ehrql.tables.tpp import medications

####################################################################################
# add_moi_prescriptions
# ##################################################################################
# Returns wide-format prescription columns (med_dmd_code_i, med_date_i).
# Returns medications where dmd_code.is_in(dmd_codelist) up to n max_meds
#
# direction="backward": peels the most recent prescriptions pre-index date
# direction="forward": peels the most recent prescriptions post-index date
#
# Same-day prescriptions are ordered lexicographically by dmd_code string
# (not numerically). Rows with identical date and dmd_code are treated as
# duplicates and collapsed to one entry.
####################################################################################

def add_moi_prescriptions(remaining, max_meds, direction="backward"):

    output = {}

    for i in range(1, max_meds + 1):

        current = (
            remaining.last_for_patient() if direction == "backward"
            else remaining.first_for_patient()
        )
        current_date = current.date
        current_code = current.dmd_code

        output[f"med_dmd_code_{i}"] = current_code
        output[f"med_date_{i}"] = current_date

        if direction == "backward":
            remaining = remaining.where(
                medications.date.is_before(current_date) |
                (
                    (medications.date == current_date) &
                    (medications.dmd_code != current_code)
                )
            )
        else:
            remaining = remaining.where(
                medications.date.is_after(current_date) |
                (
                    (medications.date == current_date) &
                    (medications.dmd_code != current_code)
                )
            )

    return output

#############################################################################
# add_moi_prescription_columns
#############################################################################
# adds the columns from add_moi_prescriptions() to the dataset.
# and a single column that is the crude count_for_patient() number of meds 
# this is for latter diagnostics, and will not de-duplicate rows.
#############################################################################

def add_moi_prescription_columns(dataset, remaining, max_meds, direction="backward", count_column_name="med_num_crude_count"):
    
    dataset.add_column(count_column_name, remaining.count_for_patient())

    for name, expr in add_moi_prescriptions(remaining, max_meds, direction=direction).items():
        dataset.add_column(name, expr)

####################################################################################
# add_baseline_moi_prescription_columns
# ##################################################################################
# Pre-index baseline pull: prescriptions matching dmd_codelist between
# days_before_index and index_date, working backwards up to max_meds
# prescriptions.
#
# days_before_index must be >= chronic_med_definitions$base$lookback_days
# in analysis/config/config.r
####################################################################################

def add_baseline_moi_prescription_columns(dataset, index_date, dmd_codelist, max_meds=30, days_before_index=200):
    remaining = medications.where(
        medications.dmd_code.is_in(dmd_codelist) &
        medications.date.is_on_or_before(index_date) &
        medications.date.is_on_or_after(index_date - days(days_before_index))
    ).sort_by(
        medications.date,
        medications.dmd_code,
    )

    add_moi_prescription_columns(dataset, remaining, max_meds, direction="backward", count_column_name="med_num_crude_count_baseline")


####################################################################################
# add_followup_moi_prescription_columns
# ##################################################################################
# Post-index follow-up pull: prescriptions matching dmd_codelist between the
# index date and end_date, working forwards up to max_meds prescriptions, so
# med_dmd_code_1 is the earliest prescription.
####################################################################################

def add_followup_moi_prescription_columns(dataset, index_date, end_date, dmd_codelist, max_meds=100):
    remaining = medications.where(
        medications.dmd_code.is_in(dmd_codelist) &
        medications.date.is_after(index_date) &
        medications.date.is_on_or_before(end_date)
    ).sort_by(
        medications.date,
        medications.dmd_code,
    )

    add_moi_prescription_columns(dataset, remaining, max_meds, direction="forward", count_column_name="med_num_crude_count_followup")
