from ehrql.tables.tpp import clinical_events, patients
import ehrql.math as math
from study_dates import index_date
from codelists import creatinine_codes

# Extract all non-null creatinine_values for patients prior to index date
creatinine_values = (
    clinical_events
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
qualifying_cutoff = most_recent_creatinine_value.date - 90

second_most_recent_creatinine_value_90plusdays = (
    creatinine_values
    .where(clinical_events.date <= qualifying_cutoff)
    .sort_by(clinical_events.date)
    .last_for_patient()
)


# Convert creatinine (µmol/L) → eGFR (2009 CKD-EPI, no race)

# 2009 CKD-EPI constants using SI units
# https://www.niddk.nih.gov/research-funding/research-programs/kidney-clinical-research-epidemiology/laboratory/glomerular-filtration-rate-equations/adults/previous 
# kappa: 61.9 (female), 79.6 (male)
# alpha: -0.329 (female), -0.411 (male)
# Female multiplier: 1.018
# No race multiplier in this version

sex = patients.sex
kappa = sex.if_else("female", 61.9, 79.6)
alpha = sex.if_else("female", -0.329, -0.411)
female_multiplier = sex.if_else("female", 1.018, 1.0)

def egfr_ckdepi2009(creat_umol, age):
    ratio = creat_umol / kappa
    return (
        141
        * (math.minimum(ratio, 1) ** alpha) # not sure again
        * (math.maximum(ratio, 1) ** -1.209) # not sure if need this
        * (0.993 ** age)
        * female_multiplier
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

## classify into CKD stages
# Stage 5 CKD both eGFR ≤15, ≥90 days apart
ckd5 = (
    both_exist
    & (most_recent_egfr <= 15)
    & (second_most_recent_egfr_90plusdays <= 15)
)

# Stage 4 CKD both eGFR 16–30, ≥90 days apart
ckd4 = (
    both_exist
    & (most_recent_egfr >= 16) & (most_recent_egfr <= 30)
    & (second_most_recent_egfr_90plusdays >= 16) & (second_most_recent_egfr_90plusdays <= 30)
)

### what to do about someone with first eGFR 16 then second eGFR 15 - need to think about this edge case

## add all the relevant CKD related variables to the dataset
dataset.creatinine_date_1 = most_recent_creatinine_value.date
dataset.creatinine_value_1 = most_recent_creatinine_value.numeric_value
dataset.egfr_1 = most_recent_egfr

dataset.creatinine_date_2 = second_most_recent_creatinine_value_90plusdays.date
dataset.creatinine_value_2 = second_most_recent_creatinine_value_90plusdays.numeric_value
dataset.egfr_2 = second_most_recent_egfr_90plusdays

dataset.ckd4 = ckd4
dataset.ckd5 = ckd5