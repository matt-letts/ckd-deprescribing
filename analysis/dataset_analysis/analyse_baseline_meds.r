##########################################################################
# This script does the following:
# 1. Loads the processed prescription-level dataset
# 2. Flags chronically prescribed medications in various ways according to
#    a main definition and then sensitivity analyses
# 3. Produces patient-level oral substance dataset (main analysis)
# 4. Conducts analysis A - medications per patient: counts, summary stats,
#    frequency tables (using main and sensitivity analyses data)
# 5. Conducts analysis B - patients per medication: prevalence by BNF
#    substance/subparagraph/paragraph level (main analysis only)
# 6. Saves outputs
##########################################################################

# Import libraries and functions -----------------------------------------
message("Import libraries and functions")
library(fs)
library(here)
library(arrow)
library(tidyverse)
source(here::here("analysis", "config", "config.r"))
source(here::here(
  "analysis",
  "r_functions",
  "medications",
  "fn_flag_chronic_meds.r"
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
dir_create(here::here("output", "data_descriptions", "analyse_baseline_meds"))

# Import dates -----------------------------------------------------------
message("Import dates")
study_dates <- lapply(study_dates, function(x) as.Date(x))

# Load processed prescription-level dataset ------------------------------
message("Load the dataset")
dataset_analyse_baseline_meds_1_input <- arrow::open_dataset(
  here::here("output", "data", "dataset_baseline_meds_processed.arrow"),
  format = "ipc"
) |>
  collect()

# Build patient denominator ----------------------------------------------
all_patient_ids <- dataset_analyse_baseline_meds_1_input |>
  distinct(patient_id)

# Load BNF hierarchy -----------------------------------------------------
bnf_hierarchy <- readRDS(here::here(
  "local_processing",
  "medication_lookup_tables",
  "bnf_hierarchy.rds"
))

##########################################################################
# Flag chronically prescribed medications
# fn_flag_chronic_meds() collapses prescriptions to the unique
# patient_id / bnf_substance_code level within a given lookback window
##########################################################################

# Main analysis: oral, base definition, BNF imputation included ----------
# (as a reminder - the route_cat filter has to be applied to the dmd_code
# level dataset as otherwise lots of route information gets lost)
message("Flag chronic medications: main analysis")
chronic_flags_oral_base <- fn_flag_chronic_meds(
  data = dataset_analyse_baseline_meds_1_input |>
    filter(route_cat == "oral"),
  config = chronic_med_definitions$base,
  index_date = study_dates$index_date,
  config_name = "base"
)
message(sprintf(
  "--- oral | base definition | imputation included: %d rows",
  nrow(chronic_flags_oral_base)
))

# Sensitivity 1: oral, base, BNF imputation excluded ---------------------
message("Flag chronic medications: sensitivity 1 (imputation excluded)")
chronic_flags_oral_base_no_imputed <- fn_flag_chronic_meds(
  data = dataset_analyse_baseline_meds_1_input |>
    filter(route_cat == "oral", !bnf_imputed),
  config = chronic_med_definitions$base,
  index_date = study_dates$index_date,
  config_name = "base"
)
message(sprintf(
  "--- oral | base definition | imputation excluded: %d rows",
  nrow(chronic_flags_oral_base_no_imputed)
))

# Sensitivity 2: all routes, base, BNF imputation included ---------------
message("Flag chronic medications: sensitivity 2 (all routes)")
chronic_flags_all_route_base <- fn_flag_chronic_meds(
  data = dataset_analyse_baseline_meds_1_input,
  config = chronic_med_definitions$base,
  index_date = study_dates$index_date,
  config_name = "base"
)
message(sprintf(
  "--- all routes | base definition | imputation included: %d rows",
  nrow(chronic_flags_all_route_base)
))

# Sensitivity 3: oral, alternative chronic definition, BNF imputation included
# chronic_med_definitions$[other] needs defining in config.r:
#
# message("Flag chronic medications: sensitivity 3 (alternative definition)")
# chronic_flags_oral_[other] <- fn_flag_chronic_meds(
#   data = dataset_analyse_baseline_meds_1_input |>
#     filter(route_cat == "oral"),
#   config = chronic_med_definitions$[other],
#   index_date = study_dates$index_date,
#   config_name = "[other]"
# )
# message(sprintf(
#   "--- oral | [other] definition | imputation included: %d rows",
#   nrow(chronic_flags_oral_[other])
# ))

##########################################################################
# Main dataset to carry forward for downstream analysis
# One row per (patient_id, bnf_substance_code), chronic medications only.
# med_count gives the total number of chronic oral medications per patient.
##########################################################################

message("Build patient-level oral substance dataset")
dataset_baseline_meds_analysed <- chronic_flags_oral_base |>
  filter(is_chronic_base) |>
  select(
    patient_id,
    bnf_substance_code,
    days_before_index_most_recent_prescription
  ) |>
  add_count(patient_id, name = "med_count")

# Binned frequency table to look at how recent the most recent
# prescriptions were
max_days <- chronic_med_definitions$base$allowable_index_gap
counts_days_before_index <- dataset_baseline_meds_analysed |>
  mutate(
    days_bin_label = case_when(
      days_before_index_most_recent_prescription <= 15 ~ "0-15",
      days_before_index_most_recent_prescription <= 30 ~ "16-30",
      days_before_index_most_recent_prescription <= 45 ~ "31-45",
      days_before_index_most_recent_prescription <= 60 ~ "46-60",
      days_before_index_most_recent_prescription <= 75 ~ "61-75",
      .default = paste0("76-", max_days)
    )
  ) |>
  count(days_bin_label, name = "n_substance_patient_pairs") |>
  mutate(n_substance_patient_pairs = fn_apply_sdc(n_substance_patient_pairs))


##########################################################################
# Analysis A: medications per patient
# How many chronic medications is each patient on at baseline?
##########################################################################

# One left_join per sensitivity analysis.
# Patients with no chronic medications get NA from count(), replaced with 0.
message("Build patient-level chronic medication counts")
dataset_baseline_meds_counts <- all_patient_ids |>
  left_join(
    chronic_flags_oral_base |>
      filter(is_chronic_base) |>
      count(patient_id, name = "n_chronic_oral_base"),
    by = "patient_id"
  ) |>
  mutate(n_chronic_oral_base = replace_na(n_chronic_oral_base, 0L)) |>
  left_join(
    chronic_flags_oral_base_no_imputed |>
      filter(is_chronic_base) |>
      count(patient_id, name = "n_chronic_oral_base_no_imputed"),
    by = "patient_id"
  ) |>
  mutate(
    n_chronic_oral_base_no_imputed = replace_na(
      n_chronic_oral_base_no_imputed,
      0L
    )
  ) |>
  left_join(
    chronic_flags_all_route_base |>
      filter(is_chronic_base) |>
      count(patient_id, name = "n_chronic_all_route_base"),
    by = "patient_id"
  ) |>
  mutate(n_chronic_all_route_base = replace_na(n_chronic_all_route_base, 0L))
# extend: |> left_join(...) |> mutate(n_chronic_[other] = replace_na(..., 0L))

# Pivot to long format — shared input for summary stats and frequency table
counts_long <- dataset_baseline_meds_counts |>
  pivot_longer(
    starts_with("n_chronic"),
    names_to = "analysis",
    values_to = "n_chronic",
    names_prefix = "n_chronic_"
  )

message("Build chronic medication count summary statistics")
chronic_meds_summary_table <- counts_long |>
  group_by(analysis) |>
  summarise(
    mean = round(mean(n_chronic), 2),
    median = median(n_chronic),
    p90 = quantile(n_chronic, 0.90),
    p95 = quantile(n_chronic, 0.95),
    .groups = "drop"
  )

message("Build chronic medication count frequency table")
chronic_meds_frequency_table <- counts_long |>
  count(analysis, n_chronic, name = "n_patients") |>
  mutate(n_patients = fn_apply_sdc(n_patients)) |>
  pivot_wider(
    names_from = analysis,
    values_from = n_patients,
    names_prefix = "n_patients_"
  )
# extend: counts_long picks up new analyses automatically via starts_with("n_chronic")

##########################################################################
# Analysis B: patients per medication
# How many patients are prescribed each medication at baseline?
##########################################################################

# Join BNF hierarchy to get subparagraph and paragraph names for grouping
chronic_oral_substances <- chronic_flags_oral_base |>
  filter(is_chronic_base) |>
  left_join(
    bnf_hierarchy |>
      select(
        bnf_substance_code,
        bnf_substance_name,
        bnf_subparagraph_code,
        bnf_subparagraph_name,
        bnf_paragraph_code,
        bnf_paragraph_name
      ),
    by = "bnf_substance_code"
  )

# BNF substance level
meds_prevalence_substance <- chronic_oral_substances |>
  group_by(bnf_substance_code, bnf_substance_name) |>
  summarise(n_patients = n(), .groups = "drop") |>
  mutate(
    n_patients = fn_apply_sdc(n_patients),
    pct_patients = round(100 * n_patients / nrow(all_patient_ids), 2)
  ) |>
  arrange(desc(n_patients))

# BNF subparagraph level — distinct() prevents double-counting patients
# on multiple substances within the same subparagraph (e.g. multiple statins)
meds_prevalence_subparagraph <- chronic_oral_substances |>
  distinct(patient_id, bnf_subparagraph_code, bnf_subparagraph_name) |>
  group_by(bnf_subparagraph_code, bnf_subparagraph_name) |>
  summarise(n_patients = n(), .groups = "drop") |>
  mutate(
    n_patients = fn_apply_sdc(n_patients),
    pct_patients = round(100 * n_patients / nrow(all_patient_ids), 2)
  ) |>
  arrange(desc(n_patients))

# BNF paragraph level
meds_prevalence_paragraph <- chronic_oral_substances |>
  distinct(patient_id, bnf_paragraph_code, bnf_paragraph_name) |>
  group_by(bnf_paragraph_code, bnf_paragraph_name) |>
  summarise(n_patients = n(), .groups = "drop") |>
  mutate(
    n_patients = fn_apply_sdc(n_patients),
    pct_patients = round(100 * n_patients / nrow(all_patient_ids), 2)
  ) |>
  arrange(desc(n_patients))

# Write data descriptions and flow table ---------------------------------
message(
  "Write data descriptions to output/data_descriptions/analyse_baseline_meds/"
)
flow <- fn_describe_and_flow(project_stage = "analyse_baseline_meds")

# Save outputs -----------------------------------------------------------
message("Save outputs:")

message("--- Flow table")
write_csv(
  flow,
  here::here(
    "output",
    "data_descriptions",
    "analyse_baseline_meds",
    "data_flow.csv"
  )
)

message("--- Main dataset to output/data/")
dataset_baseline_meds_analysed |>
  arrow::write_feather(
    here::here("output", "data", "dataset_baseline_meds_analysed.arrow")
  )

message("--- Binned frequency table for recency of prescriptions")
write_csv(
  counts_days_before_index,
  here::here(
    "output",
    "data_descriptions",
    "analyse_baseline_meds",
    "counts_days_before_index.csv"
  )
)

message("--- Medication count summary statistics (main + sensitivity)")
write_csv(
  chronic_meds_summary_table,
  here::here(
    "output",
    "data_descriptions",
    "analyse_baseline_meds",
    "chronic_meds_summary.csv"
  )
)

message("--- Medication count frequency table (main + sensitivity)")
write_csv(
  chronic_meds_frequency_table,
  here::here(
    "output",
    "data_descriptions",
    "analyse_baseline_meds",
    "chronic_meds_frequency.csv"
  )
)

message("--- Medication prevalence tables")
write_csv(
  meds_prevalence_substance,
  here::here(
    "output",
    "data_descriptions",
    "analyse_baseline_meds",
    "meds_prevalence_substance.csv"
  )
)
write_csv(
  meds_prevalence_subparagraph,
  here::here(
    "output",
    "data_descriptions",
    "analyse_baseline_meds",
    "meds_prevalence_subparagraph.csv"
  )
)
write_csv(
  meds_prevalence_paragraph,
  here::here(
    "output",
    "data_descriptions",
    "analyse_baseline_meds",
    "meds_prevalence_paragraph.csv"
  )
)
