#### THIS SCRIPT NOT CURRENTLY BEING USED ####
##### but is being kept for its useful eGFR equations

from ehrql.tables.tpp import clinical_events, patients
from ehrql import days, minimum_of, maximum_of 
from codelists import creatinine_codes



def compute_ckd_variables(index_date) -> dict:

    # Extract all non-null creatinine_values for patients prior to index date
    creatinine_values = (
        clinical_events # .numeric_value
        .where(clinical_events.snomedct_code.is_in(creatinine_codes))
        .where(clinical_events.numeric_value.is_not_null())
        .where(clinical_events.date < index_date)
    )

    # then filter the most recent creatinine value
    most_recent_creatinine_value = (
        creatinine_values
        .sort_by(clinical_events.date)
        .last_for_patient()
    )

    # then the next most recent, that is >= 90 days prior to the most recent
    ckd_90_day_cutoff = most_recent_creatinine_value.date - days(90)

    second_most_recent_creatinine_value_90plusdays = (
        creatinine_values
        .where(clinical_events.date <= ckd_90_day_cutoff)
        .sort_by(clinical_events.date)
        .last_for_patient()
    )

    # Convert creatinine (µmol/L) → eGFR (2009 CKD-EPI, no race - as recommended by UKKA/NICE)
    # https://www.niddk.nih.gov/research-funding/research-programs/kidney-clinical-research-epidemiology/laboratory/glomerular-filtration-rate-equations/adults/previous
     
    sex = patients.sex
    kappa = sex.map_values({"female": 61.9, "male": 79.6})
    alpha = sex.map_values({"female": -0.329, "male": -0.411})
    female_multiplier = sex.map_values({"female": 1.018, "male": 1.0})

    def egfr_ckdepi2009(creat_umol, age):
        ratio = creat_umol / kappa
        return (
            round(
            141
            * (minimum_of(ratio, 1) ** alpha) 
            * (maximum_of(ratio, 1) ** -1.209)
            * (0.993 ** age)
            * female_multiplier)
        )

    most_recent_egfr = egfr_ckdepi2009(
        most_recent_creatinine_value.numeric_value,
        patients.age_on(most_recent_creatinine_value.date)
    )

    second_most_recent_egfr_90plusdays = egfr_ckdepi2009(
        second_most_recent_creatinine_value_90plusdays.numeric_value,
        patients.age_on(second_most_recent_creatinine_value_90plusdays.date)
    )

    # Require both measurements to actually exist in order to generate a CKD flag
    both_exist = (
        most_recent_creatinine_value.date.is_not_null()
        & second_most_recent_creatinine_value_90plusdays.date.is_not_null()
    )

    # Stage 5 CKD: both eGFR ≤15, ≥90 days apart
    ckd5 = (
        both_exist
        & (most_recent_egfr <= 15)
        & (second_most_recent_egfr_90plusdays <= 15)
    )

    # Stage 4 CKD: both eGFR 16–30, ≥90 days apart
    ckd4 = (
        both_exist
        & (most_recent_egfr >= 16) & (most_recent_egfr <= 30)
        & (second_most_recent_egfr_90plusdays >= 16) & (second_most_recent_egfr_90plusdays <= 30)
    )

    # Edge cases that flipflop over the CKD 4/5 boundary
    ckd_between4and5 = (
        both_exist
        & (
            ((most_recent_egfr >= 16) & (most_recent_egfr <= 30) & (second_most_recent_egfr_90plusdays <= 15))
            |
            ((most_recent_egfr <= 15) & (second_most_recent_egfr_90plusdays >= 16) & (second_most_recent_egfr_90plusdays <= 30))
        )
    )

    return {
        "creatinine_date_1": most_recent_creatinine_value.date,
        "creatinine_value_1": most_recent_creatinine_value.numeric_value,
        "egfr_1": most_recent_egfr,
        "creatinine_date_2": second_most_recent_creatinine_value_90plusdays.date,
        "creatinine_value_2": second_most_recent_creatinine_value_90plusdays.numeric_value,
        "egfr_2": second_most_recent_egfr_90plusdays,
        "ckd4": ckd4,
        "ckd5": ckd5,
        "ckd_between4and5": ckd_between4and5,
        "ckd4or5": ckd5 | ckd4 | ckd_between4and5
    }



def add_ckd_variables(dataset, ckd: dict):
    dataset.creatinine_date_1 = ckd["creatinine_date_1"]
    dataset.creatinine_value_1 = ckd["creatinine_value_1"]
    dataset.egfr_1 = ckd["egfr_1"]
    dataset.creatinine_date_2 = ckd["creatinine_date_2"]
    dataset.creatinine_value_2 = ckd["creatinine_value_2"]
    dataset.egfr_2 = ckd["egfr_2"]
    dataset.ckd4 = ckd["ckd4"]
    dataset.ckd5 = ckd["ckd5"]
    dataset.ckd_between4and5 = ckd["ckd_between4and5"]    