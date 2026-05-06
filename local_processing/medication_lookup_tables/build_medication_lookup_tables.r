###################################################################################
# This script creates the medication lookup tables
# 1. Builds DMD-to-BNF lookup with optional VTM imputation
# 2. Classifies medication routes using regex applied to DMD product names
# 3. Builds BNF hierarchy lookup
# 4. Saves both lookups as .rds files to local_processing/medication_lookup_tables/
#
# This runs outside the OpenSAFELY pipeline using:
# - the source files from NHSBSA and BNF in docs/
# - build functions: local_processing/medication_lookup_tables/fn_med_lookup_building.r
#
# The resulting .rds files are used in:
# 1. analysis/dataset_processing/dataset_process_baseline_meds.r
#
# Diagnostic CSVs are written to output/local_outputs/
##################################################################################

# Import libraries and functions -----------------------------------------
library(fs)
library(here)
library(tidyverse)
library(readxl)
source(here::here(
  "local_processing",
  "medication_lookup_tables",
  "fn_med_lookup_building.r"
))

# Create output folders --------------------------------------------------
dir_create(here::here("output", "local_outputs"))

# Build lookup tables ----------------------------------------------------
dmd_lookup <- fn_build_dmd_bnf_lookup(impute_bnf_from_vtm = TRUE)
dmd_lookup <- fn_classify_med_route(
  dmd_lookup = dmd_lookup,
  project_stage = "building_med_tables"
)
bnf_hierarchy <- fn_build_bnf_hierarchy()

# Save lookup tables -----------------------------------------------------
saveRDS(
  dmd_lookup,
  here::here("local_processing", "medication_lookup_tables", "dmd_lookup.rds")
)
saveRDS(
  bnf_hierarchy,
  here::here(
    "local_processing",
    "medication_lookup_tables",
    "bnf_hierarchy.rds"
  )
)
