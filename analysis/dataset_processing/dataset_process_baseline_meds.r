##########################################################################
# This script does the following:
# 1. FILL IN LATER
##########################################################################

# Import libraries and functions -----------------------------------------
message("Import libraries and functions \n")
library(fs)
library(here)
library(arrow)
library(dplyr)
library(lubridate)
library(tidyverse)
source(here::here("analysis", "functions", "fn_preprocess.r"))
source(here::here("analysis", "functions", "fn_modify_dummy_data.r"))
source(here::here("analysis", "functions", "fn_dmd_to_bnf.r"))
source(here::here("analysis", "functions", "fn_disclosure_control.r"))
source(here::here("analysis", "functions", "fn_data_describing.r"))


# Create output folders --------------------------------------------------
message("Create output folders")
dir_create(here::here("output", "data"))
dir_create(here::here("output", "data_descriptions"))
dir.create(here::here("output", "figures"))

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
  # collect the data - required for the next functions
  collect()

# Build dmd_to_bnf and bnf_code_hierarchy lookups ------------------------
dmd_to_bnf_lookups <- fn_build_dmd_bnf_lookup()
bnf_hierarchy <- fn_build_bnf_hierarchy()

# To check the concordance in BNF subparagraph codes between the sources:
# bnf_codes_hierarchy <- bnf_hierarchy$bnf_subparagraph_code
# bnf_codes_lookup <- dmd_to_bnf_lookups$dmd_lookup$bnf_subparagraph
# missing_in_lookup <- setdiff(bnf_codes_hierarchy, bnf_codes_lookup)
# missing_in_hierarchy <- setdiff(bnf_codes_lookup, bnf_codes_hierarchy)

# All BNF subparagraph codes are present in both apart from:
# 1902010 + 1902020 - other individually formulated bought in preparations
# and then all of the BNF codes that start with a 2 match poorly, but
# these reflect slings, bandages, devices etc - I do not want to analyse
# these.

# Convert dmd_codes to BNF codes for categorisation ----------------------
dataset_process_baseline_meds_3_dmd_converted <- fn_dmd_to_bnf(
  patient_data = dataset_process_baseline_meds_2_preprocessed,
  project_stage = "process_baseline_meds",
  dmd_lookup = dmd_to_bnf_lookups$dmd_lookup,
  vtm_lookup = dmd_to_bnf_lookups$vtm_lookup,
  impute_bnf_from_vtm = TRUE,
  output = c("long"),
  unmapped_action = c("keep")
)

# Convert BNF codes to names and categories ------------------------------
dataset_process_baseline_meds_4_bnf_names_added <- fn_add_bnf_names(
  patient_data = dataset_process_baseline_meds_3_dmd_converted,
  bnf_hierarchy = bnf_hierarchy
)

# Apply medication exclusion and inclusion criteria ----------------------
# Things to decide next time:
# - look over fn_add_bnf_names and think more about it, any pitfalls,
# - any data want to extract from it?
# - what level of BNF hierarchy do I want to go down to.
# - what inclusion and exclusion criteria should be appliec?

# Save output
message("\nWrite/save data_descriptions to output/data_descriptions/")
flow <- describe_and_flow(
  project_stage = "process_baseline_meds"
)
