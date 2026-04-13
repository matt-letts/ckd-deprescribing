##########################################################################
# This script does the following:
# 1. Loads medication dataset (dataset_inex_meds.arrow) and preprocesses it
# 2. Separates patients with no medications recorded
# 3. Builds DMD-to-BNF lookup and classifies route on the lookup
# 4. Converts DMD codes to BNF substance codes (with VTM imputation)
#    - patient-level route diagnostic written here as route flows from lookup
# 5. Adds BNF hierarchy names (chapter, section, paragraph, subparagraph)
# 6. Reattaches patients with no medications
# 7. Saves processed dataset, flow table, and data descriptions
##########################################################################

# Import libraries and functions -----------------------------------------
message("Import libraries and functions \n")
library(fs)
library(here)
library(arrow)
library(tidyverse)
library(data.table)
source(here::here("analysis", "functions", "fn_preprocess.r"))
source(here::here("analysis", "functions", "fn_modify_dummy_data.r"))
source(here::here("analysis", "functions", "fn_med_data_conversions.r"))
source(here::here("analysis", "functions", "fn_disclosure_control.r"))
source(here::here("analysis", "functions", "fn_data_describing.r"))


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
  dataset = "baseline_meds", # leads to no modification at present
  index_date = study_dates$index_date,
  collect_and_describe = FALSE
) |>
  # collect the data - required for the next processes
  collect()

# Extract people who have no medications at all so don't get lost --------
dmd_cols <- grep(
  "^med_dmd_code",
  names(dataset_process_baseline_meds_2_preprocessed),
  value = TRUE
)
# Compute a no-meds flag once so dmd_cols is only evaluated in one pass
dataset_process_baseline_meds_2_preprocessed <-
  dataset_process_baseline_meds_2_preprocessed |>
  mutate(.no_meds = if_all(all_of(dmd_cols), ~ is.na(.) | . == "" | . == "NA"))

# Those without any medications at all
patients_no_meds <- dataset_process_baseline_meds_2_preprocessed |>
  filter(.no_meds) |>
  select(patient_id, med_count)

# Those with at least one medication - carry forward for processing
dataset_process_baseline_meds_3_remove_no_meds <- dataset_process_baseline_meds_2_preprocessed |>
  filter(!.no_meds) |>
  select(-.no_meds)

message(sprintf(
  "%d patients with no medicines recorded - separated to rejoin at end",
  nrow(patients_no_meds)
))

# Build dmd_to_bnf and bnf_code_hierarchy lookups ------------------------
dmd_to_bnf_lookups <- fn_build_dmd_bnf_lookup()
dmd_to_bnf_lookups$dmd_lookup <- fn_classify_med_route(
  dmd_lookup = dmd_to_bnf_lookups$dmd_lookup,
  project_stage = "process_baseline_meds"
)
bnf_hierarchy <- fn_build_bnf_hierarchy()

# To check the concordance in BNF substance codes between the NHSBSA
# sources:
# bnf_codes_hierarchy <- bnf_hierarchy$bnf_substance_code
# bnf_codes_lookup <- dmd_to_bnf_lookups$dmd_lookup$bnf_substance_code
# missing_in_lookup <- setdiff(bnf_codes_hierarchy, bnf_codes_lookup)
# missing_in_hierarchy <- setdiff(bnf_codes_lookup, bnf_codes_hierarchy)

# All BNF substance codes are present in both apart from:
# 190201000 + 190202000 - 'other individually formulated preparations'
# 0202030Z0 - potassium canrenoate
# 0309010Z0 - gefapixant
# 0801050CZ - Inavolisib
# and all BNF codes that start with a 2, which reflect medical devices etc
# I do not want to analyse these, so not an issue

# Convert dmd_codes to BNF codes for categorisation ----------------------
dataset_process_baseline_meds_4_dmd_converted <- fn_dmd_to_bnf(
  patient_data = dataset_process_baseline_meds_3_remove_no_meds,
  project_stage = "process_baseline_meds",
  dmd_lookup = dmd_to_bnf_lookups$dmd_lookup,
  vtm_lookup = dmd_to_bnf_lookups$vtm_lookup,
  impute_bnf_from_vtm = TRUE,
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

# Apply medication exclusion and inclusion criteria ----------------------
# - what inclusion and exclusion criteria should be applied?

# Reattach patients who had no medications prescribed --------------------
patients_no_meds <- patients_no_meds |>
  transmute(
    patient_id,
    med_count,
    med_index = NA_character_,
    dmd_code = NA_character_,
    med_date = as.Date(NA),
    bnf_substance_code = NA,
    bnf_imputed = NA,
    bnf_chapter_name = NA_character_,
    bnf_chapter_code = NA,
    bnf_section_name = NA_character_,
    bnf_section_code = NA,
    bnf_paragraph_name = NA_character_,
    bnf_paragraph_code = NA,
    bnf_subparagraph_name = NA_character_,
    bnf_subparagraph_code = NA,
    bnf_substance_name = NA_character_,
    dmd_product_desc = NA_character_,
    route_cat = NA_character_,
    route_uncertain = NA
  )

# Ensure transmute() coerces patients_no_meds to have same columns
# as process_baseline_meds dataset so bind_rows() works properly
if (
  !setequal(
    names(dataset_process_baseline_meds_5_bnf_names_added),
    names(patients_no_meds)
  )
) {
  stop("patients_no_meds columns do not match main dataset after transmute")
}

# Reattach and rename for clarity
dataset_baseline_meds_processed <- bind_rows(
  patients_no_meds,
  dataset_process_baseline_meds_5_bnf_names_added
)

# Save output
message("\nWrite/save data_descriptions to output/data_descriptions/")
flow <- fn_describe_and_flow(
  project_stage = "process_baseline_meds"
)

message("\nSave flow table to output/data_descriptions/")
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
