##########################################################################
# This script does the following:
# 1. Loads dataset_baseline_meds_analysed.arrow
# 2. Loads analysis/config/medication_of_interest.csv names + filepaths#
# 3. Loops through each medication of interest and builds matching
#    bnf_substance_codes from the bnf_code column
# 4. Writes one one-row-per-patient dataset per medication of interest,
#    that has two columns:
#     - patient_id of person prescribed the medication at baseline
#     - days_before_index_most_recent_prescription (the most-recent
#    value across matched substances, for a medication of interest that
#    maps to more than one bnf_substance_code)
##########################################################################

# Import libraries ------------------------------------------------------------
message("Import libraries")
library(here)
library(arrow)
library(tidyverse)

# Create output folders -------------------------------------------------------
message("Create output folders")
dir_create(here::here("output", "data"))

# Load dataset ----------------------------------------------------------------
message("Load dataset_baseline_meds_analysed.arrow")
dataset_baseline_meds_analysed <- read_feather(here::here(
  "output",
  "data",
  "dataset_baseline_meds_analysed.arrow"
))

# Load medication-of-interest manifest ----------------------------------------
medications_of_interest <- read_csv(
  here::here("analysis", "config", "medication_of_interest.csv"),
  show_col_types = FALSE
)

# Build and save one dataset per medication of interest -----------------------
message("Build medication-of-interest at baseline datasets")
for (i in seq_len(nrow(medications_of_interest))) {
  name <- medications_of_interest$name[i]
  codelist <- read_csv(
    medications_of_interest$codelist_path[i],
    col_types = cols(.default = "c") # force all codes to strings
  )

  # list of unique BNF substance codes per codelist
  substance_codes <- codelist |>
    mutate(bnf_substance_code = substr(bnf_code, 1, 9)) |>
    distinct(bnf_substance_code) |>
    pull(bnf_substance_code)

  patients_on_medication_of_interest <- dataset_baseline_meds_analysed |>
    filter(bnf_substance_code %in% substance_codes) |>
    group_by(patient_id) |>
    summarise(
      # in the case of multiple hits take most recent one
      days_before_index_most_recent_prescription = min(
        days_before_index_most_recent_prescription
      ),
      .groups = "drop"
    )

  message(sprintf(
    "--- %s: %d patients",
    name,
    nrow(patients_on_medication_of_interest)
  ))

  write_feather(
    patients_on_medication_of_interest,
    here::here("output", "data", paste0("dataset_", name, "_at_baseline.arrow"))
  )
}
