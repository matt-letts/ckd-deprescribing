##########################################################################
# This script does the following:
# 1. Loads medication dataset (dataset_baseline_meds.arrow) and preprocesses it
# 2. Separates patients with no medications recorded for later reattachment
# 3. Loads pre-built dmd_lookup from local_processing/medication_lookup_tables/
# 4. Converts patient DMD codes to BNF substance codes via join to dmd_lookup
# 5. Reattaches patients with no medications
# 6. Applies minimal medication exclusion criteria
# 7. Saves processed dataset, flow table, and data descriptions
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
  "medications",
  "fn_med_data_conversions.r"
))
source(here::here(
  "analysis",
  "r_functions",
  "medications",
  "fn_med_inex_criteria.r"
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
  "utilities",
  "fn_data_describing.r"
))

# Create output folders --------------------------------------------------
message("Create output folders")
dir_create(here::here("output", "data"))
dir_create(here::here("output", "data_descriptions", "process_baseline_meds"))
dir_create(here::here("output", "figures", "process_baseline_meds"))

# Import dates -----------------------------------------------------------
message("Import dates")
study_dates <- lapply(study_dates, function(x) as.Date(x))

# Load dataset -----------------------------------------------------------
message("Load the dataset")
input_filename <- "dataset_baseline_meds.arrow"
dataset_process_baseline_meds_1_input <- arrow::open_dataset(
  here::here("output", input_filename),
  format = "ipc"
)

# Preprocess data: transform variables and modify dummy data -------------
dataset_process_baseline_meds_2_preprocessed <- fn_preprocess(
  arrow_data = dataset_process_baseline_meds_1_input,
  project_stage = "process_baseline_meds",
  index_date = study_dates$index_date
) |>
  collect() # have to collect for the next steps

# Full list of patient IDs for denominator in later summaries
all_patient_ids <- dataset_process_baseline_meds_2_preprocessed |>
  distinct(patient_id)

# Separate patients with no medications ----------------------------------
dmd_cols <- grep(
  "^med_dmd_code",
  names(dataset_process_baseline_meds_2_preprocessed),
  value = TRUE
)
dataset_process_baseline_meds_2_preprocessed <-
  dataset_process_baseline_meds_2_preprocessed |>
  mutate(.no_meds = if_all(all_of(dmd_cols), is.na))

patients_no_meds <- dataset_process_baseline_meds_2_preprocessed |>
  filter(.no_meds) |>
  select(patient_id)

dataset_process_baseline_meds_3_remove_no_meds <- dataset_process_baseline_meds_2_preprocessed |>
  filter(!.no_meds) |>
  select(-.no_meds)

message(sprintf(
  "%d patients with no medicines recorded - separated to rejoin at end",
  nrow(patients_no_meds)
))

# Load pre-built medication lookup table ---------------------------------
dmd_lookup <- readRDS(here::here(
  "local_processing",
  "medication_lookup_tables",
  "dmd_lookup.rds"
))

# Convert dmd_codes to BNF codes for categorisation ----------------------
dataset_process_baseline_meds_4_dmd_converted <- fn_dmd_to_bnf(
  patient_data = dataset_process_baseline_meds_3_remove_no_meds,
  project_stage = "process_baseline_meds",
  dmd_lookup = dmd_lookup,
  output = "long",
  unmapped_action = "drop"
)

# Reattach patients with no medications ----------------------------------
patients_no_meds <- patients_no_meds |>
  transmute(
    patient_id,
    med_index = NA_integer_,
    dmd_code = NA_character_,
    med_date = as.Date(NA),
    bnf_substance_code = NA_character_,
    dmd_name = NA_character_,
    bnf_imputed = NA,
    route_cat = factor(NA)
  )

if (
  !setequal(
    names(dataset_process_baseline_meds_4_dmd_converted),
    names(patients_no_meds)
  )
) {
  stop("patients_no_meds columns do not match main dataset after transmute")
}

dataset_process_baseline_meds_5_no_meds_reattached <- bind_rows(
  patients_no_meds,
  dataset_process_baseline_meds_4_dmd_converted
) |>
  arrange(patient_id, med_index)

# Apply minimal medication exclusion criteria ----------------------------
# Remove BNF chapters that will never be analysed:
#  14: immunological products (immunoglobulins and vaccines)
#  15: anaesthesia
#  18: preparations used in diagnosis
#  19: other drugs and preparations
#  20: dressings
#  21: appliances
#  22: incontinence appliances
#  23: stoma appliances
dataset_process_baseline_meds_6_exclusions_applied <-
  dataset_process_baseline_meds_5_no_meds_reattached |>
  mutate(bnf_chapter_code = substr(bnf_substance_code, 1, 2)) |>
  fn_apply_med_inex_criteria(
    project_stage = "process_baseline_meds",
    exclude_bnf_chapters = c("14", "15", "18", "19", "20", "21", "22", "23"),
    exclude_route_cats = NULL
  ) |>
  select(-bnf_chapter_code)

dataset_baseline_meds_processed <- dataset_process_baseline_meds_6_exclusions_applied

# Write data descriptions and flow table ---------------------------------
message("Write/save outputs:")

message(
  "--- Data_descriptions to output/data_descriptions/process_baseline_meds/"
)
flow <- fn_describe_and_flow(project_stage = "process_baseline_meds")

# BNF imputation summary -------------------------------------------------
message(
  "--- Summary of BNF imputation to output/data_descriptions/process_baseline_meds/"
)
bnf_imputation_summary <- bind_rows(
  # Number and percentage of prescriptions where BNF code imputed
  dataset_baseline_meds_processed |>
    filter(!is.na(bnf_substance_code)) |>
    summarise(
      metric = "prescriptions_with_imputed_bnf_code",
      n = fn_apply_sdc(sum(bnf_imputed, na.rm = TRUE)),
      n_total = n(),
      pct = round(n / n_total * 100, 1)
    ),
  # Number and percentage of patients with at least one prescription where BNF code imputed
  dataset_baseline_meds_processed |>
    filter(!is.na(bnf_substance_code)) |>
    group_by(patient_id) |>
    summarise(any_imputed = any(bnf_imputed), .groups = "drop") |>
    summarise(
      metric = "patients_with_any_imputed_prescription",
      n = fn_apply_sdc(sum(any_imputed)),
      n_total = nrow(all_patient_ids),
      pct = round(n / n_total * 100, 1)
    )
)

write_csv(
  bnf_imputation_summary,
  here::here(
    "output",
    "data_descriptions",
    "process_baseline_meds",
    "bnf_imputation_summary.csv"
  )
)

# Save outputs -----------------------------------------------------------
message("--- Flow table to output/data_descriptions/process_baseline_meds/")
write_csv(
  flow,
  here::here(
    "output",
    "data_descriptions",
    "process_baseline_meds",
    "data_flow.csv"
  )
)

message("--- Processed dataset to output/data/")
dataset_baseline_meds_processed |>
  arrow::write_feather(
    here::here("output", "data", "dataset_baseline_meds_processed.arrow")
  )
