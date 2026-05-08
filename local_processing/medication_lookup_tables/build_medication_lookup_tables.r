###################################################################################
# This script creates medication lookup tables
# 1. Builds a dmd_to_bnf lookup with optional VTM imputation
# 2. Classifies medication routes using NHS TRUD data and adds route_cat to lookup
# 3. Builds a BNF hierarchy lookup
# 4. Saves both lookups as .rds files to local_processing/medication_lookup_tables/
#
# This runs outside the OpenSAFELY pipeline using files from NHSBSA and BNF in docs/
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
library(xml2)
library(readxl)
source(here::here(
  "local_processing",
  "medication_lookup_tables",
  "fn_med_lookup_building.r"
))
source(here::here(
  "local_processing",
  "medication_lookup_tables",
  "fn_classify_route_from_trud.r"
))

# Create output folders --------------------------------------------------
dir_create(here::here("output", "local_outputs"))

# Build lookup tables ----------------------------------------------------
dmd_lookup <- fn_build_dmd_bnf_lookup(impute_bnf_from_vtm = TRUE)
dmd_lookup <- fn_classify_route_from_trud(
  dmd_lookup = dmd_lookup,
  trud_folder_path = here::here("docs", "nhsbsa_dmd_3.4.0_20260330000001"),
  project_stage = "building_med_tables",
  route_cat_map_path = here::here("docs", "dmd_route_cat_map.csv")
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
