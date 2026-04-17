###########################################################################
# This script does the following:
# 1. Loads medication dataset (dataset_inex_meds.arrow) and preprocesses it
# 2. Separates patients with no medications recorded for later reattachment
# 3. Builds two lookups for medication code conversion and categorisation:
#    - DMD-to-BNF lookup (with optional VTM imputation) with classification
#      of medication routes using regex applied to DMD product names
#    - BNF hierarchy lookup
# 4. Converts DMD to BNF substance codes via join to dmd-to-bnf lookup
# 5. Adds BNF hierarchy names (chapter, section, paragraph, subparagraph)
# 6. Reattaches patients with no medications
# 7. Applies minimal medication exclusion criteria
# 8. Saves processed dataset, flow table, and data descriptions
###########################################################################

# Import libraries and functions -----------------------------------------
message("Import libraries and functions \n")
library(fs)
library(here)
library(arrow)
library(tidyverse)
library(data.table)
library(readxl)
source(here::here("analysis", "r_functions", "fn_preprocess.r"))
source(here::here("analysis", "r_functions", "fn_modify_dummy_data.r"))
source(here::here("analysis", "r_functions", "fn_med_data_conversions.r"))
source(here::here("analysis", "r_functions", "fn_med_inex_criteria.r"))
source(here::here("analysis", "r_functions", "fn_disclosure_control.r"))
source(here::here("analysis", "r_functions", "fn_data_describing.r"))


# Create output folders --------------------------------------------------
message("Create output folders")
dir_create(here::here("output", "data"))
dir_create(here::here("output", "data_descriptions"))
dir_create(here::here("output", "figures"))

# Import dates -----------------------------------------------------------
message("\nImport dates")
source(here::here("analysis", "dataset_definition", "study_dates.r"))
study_dates <- lapply(study_dates, function(x) as.Date(x))

# Load dataset, keeping in arrow format for speed ------------------------
message("\nLoad the dataset")
input_filename = "dataset_inex_meds.arrow"
dataset_process_baseline_meds_1_input <- arrow::open_dataset(
  here::here("output", input_filename),
  format = "ipc"
)

# Preprocess data: transform variables and modify dummy data -------------
dataset_process_baseline_meds_2_preprocessed <- fn_preprocess(
  arrow_data = dataset_process_baseline_meds_1_input,
  project_stage = "baseline_meds", # no modification at present
  index_date = study_dates$index_date,
  collect_and_describe = FALSE
) |>
  # collect the data - required for the next processes
  collect()

# Extract people who have no medications at all for reattachment later ---
dmd_cols <- grep(
  "^med_dmd_code",
  names(dataset_process_baseline_meds_2_preprocessed),
  value = TRUE
)
dataset_process_baseline_meds_2_preprocessed <-
  dataset_process_baseline_meds_2_preprocessed |>
  mutate(.no_meds = if_all(all_of(dmd_cols), is.na)) # no meds flag

patients_no_meds <- dataset_process_baseline_meds_2_preprocessed |>
  filter(.no_meds) |>
  select(patient_id, med_num_count) # those with no medications

dataset_process_baseline_meds_3_remove_no_meds <- dataset_process_baseline_meds_2_preprocessed |>
  filter(!.no_meds) |>
  select(-.no_meds) # those with >=1 medications, for processing

message(sprintf(
  "%d patients with no medicines recorded - separated to rejoin at end",
  nrow(patients_no_meds)
))

# Build medication code conversion lookup tables -------------------------
dmd_lookup <- fn_build_dmd_bnf_lookup(impute_bnf_from_vtm = TRUE)
dmd_lookup <- fn_classify_med_route(
  dmd_lookup = dmd_lookup,
  project_stage = "process_baseline_meds"
)
bnf_hierarchy <- fn_build_bnf_hierarchy()

# Convert dmd_codes to BNF codes for categorisation ----------------------
dataset_process_baseline_meds_4_dmd_converted <- fn_dmd_to_bnf(
  patient_data = dataset_process_baseline_meds_3_remove_no_meds,
  project_stage = "process_baseline_meds",
  dmd_lookup = dmd_lookup,
  output = "long",
  unmapped_action = "drop"
)

# Convert BNF codes to names and categories ------------------------------
dataset_process_baseline_meds_5_bnf_names_added <- fn_add_bnf_names(
  patient_data = dataset_process_baseline_meds_4_dmd_converted,
  bnf_hierarchy = bnf_hierarchy,
  project_stage = "process_baseline_meds",
  unmapped_action = "drop"
)

# Reattach patients who had no medications prescribed --------------------
patients_no_meds <- patients_no_meds |>
  transmute(
    patient_id,
    med_num_count,
    med_index = NA_integer_,
    dmd_code = NA_character_,
    med_date = as.Date(NA),
    bnf_substance_code = NA_character_,
    dmd_name = NA_character_,
    bnf_imputed = NA,
    route_cat = factor(NA),
    route_uncertain = NA,
    bnf_chapter_name = NA_character_,
    bnf_chapter_code = NA_character_,
    bnf_section_name = NA_character_,
    bnf_section_code = NA_character_,
    bnf_paragraph_name = NA_character_,
    bnf_paragraph_code = NA_character_,
    bnf_subparagraph_name = NA_character_,
    bnf_subparagraph_code = NA_character_,
    bnf_substance_name = NA_character_,
  )

# Check transmute() has made patients_no_meds have same columns
# as process_baseline_meds dataset so bind_rows() works properly
if (
  !setequal(
    names(dataset_process_baseline_meds_5_bnf_names_added),
    names(patients_no_meds)
  )
) {
  stop("patients_no_meds columns do not match main dataset after transmute")
}

dataset_process_baseline_meds_6_no_meds_reattached <- bind_rows(
  patients_no_meds,
  dataset_process_baseline_meds_5_bnf_names_added
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
dataset_process_baseline_meds_7_exclusions_applied <- fn_apply_med_inex_criteria(
  patient_data = dataset_process_baseline_meds_6_no_meds_reattached,
  project_stage = "process_baseline_meds",
  exclude_bnf_chapters = c("14", "15", "18", "19", "20", "21", "22", "23"),
  exclude_route_cats = NULL
)

# rename for clarity and consistency
dataset_baseline_meds_processed <- dataset_process_baseline_meds_7_exclusions_applied

# Save output
message("\nWrite/save data_descriptions to output/data_descriptions/")
flow <- fn_describe_and_flow(
  project_stage = "process_baseline_meds"
)

message("\nSave flow table to output/data_descriptions/")
flow$n_rows <- fn_roundmid_any(flow$n_rows, to = 6) # apply SDC
data.table::fwrite(
  flow,
  here::here(
    "output",
    "data_descriptions",
    "process_baseline_meds-data_flow.csv"
  )
)

message("\nSave cleaned dataset to output/data/")
dataset_baseline_meds_processed |>
  arrow::write_feather(
    here::here("output", "data", "dataset_baseline_meds_processed.arrow"),
  )
