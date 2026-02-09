from ehrql import create_dataset, codelist_from_csv, months
from ehrql.tables.core import practice_registrations, ons_deaths, patients, medications, addresses, clinical_events, decision_support_values

study_start_date = "2022-03-01"
study_end_date = "2026-02-09" # need to come back to this 
patient_address = addresses.for_patient_on("2022-03-01")
dataset = create_dataset()

# registered >12 months prior to start date, and registered through until end date of study
registrations = (
    practice_registrations.where(
        practice_registrations.start_date.is_on_or_before(study_start_date - months(12))
    )
    .except_where(
        practice_registrations.end_date.is_on_or_before(study_end_date) # decide if having an end date
    )
)

# ethnicity for patients
ethnicity_codelist = codelist_from_csv(
    "ethnicity_codelist_with_categories",
    column="snomedcode",
    category_column="Grouping_6",
)

dataset.latest_ethnicity_code = (
    clinical_events.where(clinical_events.snomedct_code.is_in(ethnicity_codelist))
    .where(clinical_events.date.is_on_or_before(study_start_date))
    .sort_by(clinical_events.date)
    .last_for_patient()
    .snomedct_code
)

dataset.latest_ethnicity_group = dataset.latest_ethnicity_code.to_category(
    ethnicity_codelist
)

# patient's practice STP
dataset.stp = practice_registrations.for_patient_on(study_start_date).practice_stp

# age
dataset.age = patients.age_on(study_start_date)
dataset.define_population(patients.exists_for_patient())

# death dates/causes from ONS
dataset.date_of_death = ons_deaths.date
dataset.underlying_cause_of_death = ons_deaths.underlying_cause_of_death
dataset.cause_of_death = ons_deaths.cause_of_death_01
dataset.define_population(patients.exists_for_patient())

# IMD quintile
dataset.imd_quintile = patient_address.imd_quintile
dataset.imd_decile = patient_address.imd_decile

# eFI
latest_efi_record = (
  decision_support_values
    .electronic_frailty_index()
    .where(decision_support_values.calculation_date.is_on_or_before(study_start_date)) # I added this line in
    .sort_by(decision_support_values.calculation_date)
    .last_for_patient()
)
dataset.latest_efi = latest_efi_record.numeric_value
dataset.latest_efi_date = latest_efi_record.calculation_date