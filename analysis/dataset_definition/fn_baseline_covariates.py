##########################################################################
# This script defines helper functions and the main covariate extraction
# function for dataset_definition_baseline_covariates.py:
# 1. get_latest_ethnicity() - most recent ethnicity (primary care or SUS)
# 2. get_imd() - categorises IMD into quintiles from address-linked data
# 3. add_baseline_covariate_variables() - adds all covariate columns to
#    the dataset (ethnicity, IMD, smoking, diabetes, CVD, BP, proteinuria)
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
)

from codelists import *

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
# get_imd categorises IMD into groups (e.g. quintiles, deciles) 
# based on the distribution of IMD in the dataset
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


#####################################################################
# COMBINE ALL COVARIATE VARIABLES INTO ONE FUNCTION
#####################################################################

def add_baseline_covariates(dataset, index_date):

    columns = {
        "basecov_cat_ethnicity": None,
        "basecov_cat_imd": None,
        "basecov_cat_smoking_status": None,
        "basecov_bin_diabetes": None,
        "basecov_bin_cvd": None,
        "basecov_num_sbp": None,
        "basecov_date_sbp": None,
        "basecov_num_uacr": None,
        "basecov_date_uacr": None,
        "basecov_num_upcr": None,
        "basecov_date_upcr": None,
    }

    for name, expr in columns.items():
        dataset.add_column(name, expr)
