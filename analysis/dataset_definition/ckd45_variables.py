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
most_recent_creatinine_value = creatinine_values.sort_by(clinical_events.date).last_for_patient()

# then the next most recent, that is >= 90 days prior to the most recent
qualifying_cutoff = most_recent_creatinine_value.date - 90

most_recent_creatinine_value_90plus_days_earlier = (
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

most_recent_egfr = calc_egfr(
    most_recent.numeric_value,
    patients.age_on(most_recent.date)
)

second_most_recentegfr_second = calc_egfr(
    second_most_recent.numeric_value,
    patients.age_on(second_most_recent.date)
)


# Convert to mg/dL
creat_mgdl_recent = most_recent.numeric_value / 88.4
creat_mgdl_second = second_most_recent.numeric_value / 88.4

# Age at test
age_recent = patients.age_on(most_recent.date)
age_second = patients.age_on(second_most_recent.date)

sex = patients.sex

# 2021 CKD-EPI constants
kappa_recent = sex.if_else("female", 0.7, 0.9)
alpha_recent = sex.if_else("female", -0.241, -0.302)
female_multiplier = sex.if_else("female", 1.012, 1)

kappa_second = kappa_recent
alpha_second = alpha_recent

# eGFR calculation (2021 equation)
egfr_recent = (
    142
    * (math.minimum(creat_mgdl_recent / kappa_recent, 1) ** alpha_recent)
    * (math.maximum(creat_mgdl_recent / kappa_recent, 1) ** -1.200)
    * (0.9938 ** age_recent)
    * female_multiplier
)

egfr_second = (
    142
    * (math.minimum(creat_mgdl_second / kappa_second, 1) ** alpha_second)
    * (math.maximum(creat_mgdl_second / kappa_second, 1) ** -1.200)
    * (0.9938 ** age_second)
    * female_multiplier
)

# -------------------------------------------------------------------
# Step 4: Require ≥90 days between measurements
# -------------------------------------------------------------------

days_between = most_recent.date - second_most_recent.date

valid_spacing = days_between >= 90


# -------------------------------------------------------------------
# Step 5: Define CKD Stage 4 and 5
# -------------------------------------------------------------------

# Stage 5: both eGFR ≤15 and spaced ≥90 days
ckd5 = (
    valid_spacing
    & (egfr_recent <= 15)
    & (egfr_second <= 15)
)

# Stage 4: both eGFR 16–30 and spaced ≥90 days
ckd4 = (
    valid_spacing
    & (egfr_recent >= 16)
    & (egfr_recent <= 30)
    & (egfr_second >= 16)
    & (egfr_second <= 30)
)


# -------------------------------------------------------------------
# Step 6: Add outputs to dataset
# -------------------------------------------------------------------

dataset.latest_creatinine_value = most_recent.numeric_value
dataset.latest_creatinine_date = most_recent.date
dataset.latest_egfr = egfr_recent

dataset.ckd4 = ckd4
dataset.ckd5 = ckd5