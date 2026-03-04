from ehrql import (
    when,
    case,
    days,
)

from ehrql.tables.tpp import (
    clinical_events,
    ethnicity_from_sus,
    addresses,
    patients,
    medications,
)

#########################################################################################
# this function returns a dictionary of patient-level columns representing the most recent
# prescriptions in the 90 days prior to (and including) index_date, working
# backwards in time up to max_meds prescriptions. 
# Columns are named med_1_code, med_1_date, med_2_code, med_2_date, etc. 
# where med_1 is the most recent prescription. 
# Same-day prescriptions are ordered lexicographically by dmd_code string 
# (not numerically), which is arbitrary but consistent. Rows with identical 
# date and dmd_code are treated as duplicates and collapsed to one entry. 
# Iteratively peels off the most recent row using last_for_patient() on an ascending sort, 
# then excludes that date+code combination from subsequent iterations.
##########################################################################################

def add_recent_prescriptions(index_date, max_meds=10):

    # restrict to precriptions within 90 days before (and including) index_date
    # sort -> last_for_patient() returns the most recent / lexicographically last row
    base = medications.where(
        medications.date.is_on_or_before(index_date) &
        medications.date.is_on_or_after(index_date - days(90))
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
        output[f"med_{i}_code"] = current.dmd_code
        output[f"med_{i}_date"] = current.date

        # update the lists to include the most recently used dates and codes
        prev_dates = prev_dates + [current.date] 
        prev_codes = prev_codes + [current.dmd_code]  

    return output


# calls add_recent_prescriptions() and adds resulting columns to dataset

def add_prescription_columns(dataset, index_date, max_meds=10):
    for name, expr in add_recent_prescriptions(index_date, max_meds).items():
        dataset.add_column(name, expr)


#########################################################################################
# get_latest_ethnicity()
##########################################################################################

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


#########################################################################################
# get_imd categorises IMD into groups (e.g. quintiles, deciles) based on the distribution of IMD in the dataset
##########################################################################################

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