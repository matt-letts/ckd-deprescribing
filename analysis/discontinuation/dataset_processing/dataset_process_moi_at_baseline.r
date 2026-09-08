##########################################################################
# This script does the following:
# 1. Passes the name of each medication within
#    analysis/config/medication_of_interest.csv into a processing loop
# 2. This loop loads the wide format output of dataset_definition_discont_
#    meds_baseline (dataset_discont_meds_baseline_[medication].arrow)
# 3. The data is reshaped and 'oral' and 'chronic' prescriptions are kept
# 4. Outputs dataset_[medication]_at_baseline_processed.arrow which contains
#    only two columns - patient id, and the number of days before the index
#    that the last prescriptions was recorded
##########################################################################

# Import libraries and functions -----------------------------------------
message("Import libraries and functions")
library(fs)
library(here)
library(arrow)
library(tidyverse)
source(here::here("analysis", "config", "config.r"))
source(here::here("analysis", "r_functions", "utilities", "fn_preprocess.r"))
source(here::here(
  "analysis",
  "r_functions",
  "utilities",
  "fn_modify_dummy_data.r"
))
source(here::here(
  "analysis",
  "r_functions",
  "utilities",
  "fn_data_describing.r"
))
source(here::here(
  "analysis",
  "r_functions",
  "utilities",
  "fn_disclosure_control.r"
))
source(here::here(
  "analysis",
  "r_functions",
  "medications",
  "fn_summarise_chronic_meds.r"
))

# Create output folders ----------------------------------------------------
message("Create output folders")
dir_create(here::here("output", "data"))

# Import dates --------------------------------------------------------------
message("Import dates")
study_dates <- lapply(study_dates, function(x) as.Date(x))

# Load pre-built medication lookup table -----------------------------------
message("Load dmd_lookup")
dmd_lookup <- readRDS(here::here(
  "local_processing",
  "medication_lookup_tables",
  "dmd_lookup.rds"
)) |>
  select(dmd_code, route_cat)

# Load medication-of-interest reference csv --------------------------------
medications_of_interest <- read_csv(
  here::here("analysis", "config", "medication_of_interest.csv"),
  show_col_types = FALSE
)

# Main loop ----------------------------------------------------------------

# Loops over the reference csv to build/save a dataset for each medication
# that contains people who were chronically prescribed that med at baseline.

message("Medication of interest loop running")
for (i in seq_len(nrow(medications_of_interest))) {
  # setup phase - create labels, print message, make an output directory
  stage <- "process_moi_at_baseline"
  dir_create(here::here("output", "data_descriptions", stage))
  name <- medications_of_interest$name[i]
  stage_specific <- paste0(stage, "_", name)
  message(sprintf("--- Processing %s", name))

  # Load the wide-format dataset for this medication
  input_filename <- sprintf("dataset_discont_meds_baseline_%s.arrow", name)
  dataset_process_moi_at_baseline_1_input <- arrow::open_dataset(
    here::here("output", input_filename),
    format = "ipc"
  )

  dataset_process_moi_at_baseline_2_preprocessed <- fn_preprocess(
    arrow_data = dataset_process_moi_at_baseline_1_input,
    project_stage = stage,
    index_date = study_dates$index_date,
    one_row_per_patient = TRUE
  ) |>
    collect()

  # Separate and remove patients with no prescriptions of this medication
  # - every med_dmd_code_* column = NA
  dmd_cols <- grep(
    "^med_dmd_code",
    names(dataset_process_moi_at_baseline_2_preprocessed),
    value = TRUE
  )

  not_prescribed <- dataset_process_moi_at_baseline_2_preprocessed |>
    filter(if_all(all_of(dmd_cols), is.na))

  message(sprintf(
    "--- %d patients with no %s prescribed",
    nrow(not_prescribed),
    name
  ))

  dataset_process_moi_at_baseline_3_remove_no_meds <- dataset_process_moi_at_baseline_2_preprocessed |>
    filter(!if_all(all_of(dmd_cols), is.na))

  # Reshape to long format and join dmd_lookup for route categorisation
  dataset_process_moi_at_baseline_4_long <-
    dataset_process_moi_at_baseline_3_remove_no_meds |>
    pivot_longer(
      cols = matches("^med_dmd_code_|^med_date_"),
      names_to = c(".value", "med_index"),
      names_pattern = "^(med_dmd_code|med_date)_(\\d+)$"
    ) |>
    rename(dmd_code = med_dmd_code) |>
    filter(!is.na(dmd_code), dmd_code != "", dmd_code != "NA") |>
    left_join(
      dmd_lookup,
      by = "dmd_code"
    )

  # There are some dmd_codes in the OpenCodelists that are not in the dmd_lookup
  # These seem to represent old/superseded codes. As dmd_lookup$route_cat is
  # complete, all non-mapped codes will have route_cat == NA. Diagnostics:
  not_mapped_n_px <- dataset_process_moi_at_baseline_4_long |>
    filter(is.na(route_cat))
  not_mapped_n_pt <- not_mapped_n_px |>
    distinct(patient_id)
  not_mapped_n_codes <- not_mapped_n_px |>
    distinct(dmd_code)

  message(sprintf(
    "--- %d %s prescriptions with dmd_codes present in codelist but not dmd_lookup",
    nrow(not_mapped_n_px),
    name
  ))

  message(sprintf(
    "--- %d patients with 1+ %s dmd_codes present in codelist but not dmd_lookup",
    nrow(not_mapped_n_pt),
    name
  ))

  message(sprintf(
    "--- %d unique %s dmd_codes present in codelist but not dmd_lookup",
    nrow(not_mapped_n_codes),
    name
  ))

  # Filter just oral medicines and give each row a bnf_substance_code label
  # e.g. statins - this is to ensure fn_flag_chronic_meds works, and that
  # all medications are treated as being part of the same substance class
  dataset_process_moi_at_baseline_5_oral <- dataset_process_moi_at_baseline_4_long |>
    filter(route_cat == "oral") |>
    mutate(bnf_substance_code = name)

  dataset_process_moi_at_baseline_6_chronic <- fn_flag_chronic_meds(
    data = dataset_process_moi_at_baseline_5_oral,
    config = chronic_med_definitions$base,
    index_date = study_dates$index_date,
    config_name = "base"
  ) |>
    filter(is_chronic_base) |>
    select(patient_id, days_before_index_most_recent_prescription)

  # Outputs

  # Main dataset
  write_feather(
    dataset_process_moi_at_baseline_6_chronic,
    here::here(
      "output",
      "data",
      paste0("dataset_", name, "_at_baseline_processed.arrow")
    )
  )

  # Describe and flow
  flow <- fn_describe_and_flow(
    project_stage = stage
  )

  flow <- flow |>
    mutate(
      n_rows = case_when(
        stage == "long" ~ fn_apply_sdc(n_distinct(
          dataset_process_moi_at_baseline_4_long$patient_id
        )),
        stage == "oral" ~ fn_apply_sdc(n_distinct(
          dataset_process_moi_at_baseline_5_oral$patient_id
        )),
        TRUE ~ n_rows
      )
    )

  write_csv(
    flow,
    here::here(
      "output",
      "data_descriptions",
      stage,
      "data_flow.csv"
    )
  )

  # Now relocate all outputs into a medication specific directory
  # and delete the stage directory ready to start the loop again.
  dir_copy(
    here::here("output", "data_descriptions", stage),
    here::here("output", "data_descriptions", stage_specific),
    overwrite = TRUE
  )
  dir_delete(here::here("output", "data_descriptions", stage))
}
