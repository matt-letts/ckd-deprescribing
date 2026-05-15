##########################################################################
# This script does the following:
# 1. Loads output/dataset_inex.arrow created by generate_dataset_inex
# 2. Modifies the dummy data if being run locally
# 3. Type formats the variables
# 4. Applies QA criteria and inclusion/exclusion criteria
# 5. Plots and tabulates medication counts 90 + 180 days before index date
# 6. Saves cleaned dataset, plots, data-flow table and description files
##########################################################################

# Import libraries and functions -----------------------------------------
message("Import libraries and functions \n")
library(fs)
library(here)
library(arrow)
library(tidyverse)
source(here::here("analysis", "r_functions", "fn_preprocess.r"))
source(here::here("analysis", "r_functions", "fn_modify_dummy_data.r"))
source(here::here("analysis", "r_functions", "fn_data_describing.r"))
source(here::here("analysis", "r_functions", "fn_disclosure_control.r"))
source(here::here("analysis", "r_functions", "fn_qa.r"))
source(here::here("analysis", "r_functions", "fn_dem_inex_criteria.r"))
source(here::here("analysis", "r_functions", "fn_ckd_inex_criteria.r"))

# Create output folders --------------------------------------------------
message("Create output folders")
dir_create(here::here("output", "data"))
dir_create(here::here("output", "data_descriptions", "cleaning_inex"))
dir_create(here::here("output", "figures", "cleaning_inex"))

# Import dates -----------------------------------------------------------
message("Import dates")
source(here::here("analysis", "config", "config.r"))
study_dates <- lapply(study_dates, function(x) as.Date(x))

# Load dataset, keeping in arrow format for speed ------------------------
message("Load the dataset for lazy processing")
input_filename = "dataset_inex.arrow"
dataset_cleaning_inex_1_input <- arrow::open_dataset(
  here::here("output", input_filename),
  format = "ipc"
)

# Preprocess data: transform variables and modify dummy data -------------
dataset_cleaning_inex_2_preprocessed <- fn_preprocess(
  arrow_data = dataset_cleaning_inex_1_input,
  project_stage = "cleaning_inex",
  index_date = study_dates$index_date,
  one_row_per_patient = TRUE
)

# Apply qa criteria ------------------------------------------------------
dataset_cleaning_inex_3_qa_applied <- fn_qa(
  arrow_data = dataset_cleaning_inex_2_preprocessed
)

# Apply demographic inclusion and exclusion criteria ---------------------
dataset_cleaning_inex_4_demographic_inex_applied <- fn_dem_inex_criteria(
  arrow_data = dataset_cleaning_inex_3_qa_applied
)

# Apply CKD inclusion criteria -------------------------------------------
# 4 new variables added to data:
# 1. inex_num_egfr_1 - numerical value of most recent eGFR
# 2. inex_num_egfr_2 - numerical value of most recent eGFR 90+ days prior
#    to inex_num_egfr_1
# 3. inex_bin_has_ckd45_by_scr - boolean TRUE if eGFRs consistent
#    with CKD G4 or G5
# 4. inex_cat_ckd_stage_by_scr - category of eGFR derived CKD
#    (G4, G5, G4/G5, or no G4/G5)
dataset_cleaning_inex_5_ckd_inex_applied <- fn_ckd_inex_criteria(
  arrow_data = dataset_cleaning_inex_4_demographic_inex_applied,
  index_date = study_dates$index_date
)

# Apply KRT exclusion criteria — split by type for flow chart breakdown --------
# Each step produces one row in data_flow.csv via fn_describe_and_flow().
# inex_krt_bin_secondary_care_only is already present from Python output.
dataset_cleaning_inex_6_krt_dialysis_excluded <- fn_krt_inex_criteria_dialysis(
  arrow_data = dataset_cleaning_inex_5_ckd_inex_applied
)

dataset_cleaning_inex_7_krt_transplant_excluded <- fn_krt_inex_criteria_transplant(
  arrow_data = dataset_cleaning_inex_6_krt_dialysis_excluded
)

n_secondary_care_krt_remain <- dataset_cleaning_inex_7_krt_transplant_excluded |>
  filter(inex_krt_bin_secondary_care_only == TRUE) |>
  summarise(n = n()) |>
  collect() |>
  pull(n)

message(sprintf(
  "\nPatients with secondary care KRT codes remaining after primary care excluded: %d",
  n_secondary_care_krt_remain
))

# Write all datasets to .txt and create flow dataframe -------------------
message(
  "\nWrite/save data_descriptions to output/data_descriptions/cleaning_inex/"
)

flow <- fn_describe_and_flow(
  # function applies SDC rules
  project_stage = "cleaning_inex"
)

# Rename cleaned dataset for clarity -------------------------------------
dataset_inex_cleaned <- dataset_cleaning_inex_7_krt_transplant_excluded

# Examine medication counts in 90 and 180 days prior to index date -------
message("\nTabulate the medication counts")
med_count_summary <- dataset_inex_cleaned |>
  summarise(
    across(
      c(inex_med_num_90, inex_med_num_180),
      list(
        mean = ~ mean(.x, na.rm = TRUE),
        median = ~ median(.x, na.rm = TRUE),
        p90 = ~ quantile(.x, 0.9, na.rm = TRUE),
        p95 = ~ quantile(.x, 0.95, na.rm = TRUE)
      )
    )
  ) |>
  collect()

# Save all  outputs -------------------------------------------------------
message("\nSave outputs:")

message(
  "Save medication count summary to output/data_descriptions/cleaning_inex/"
)
write_csv(
  med_count_summary,
  here::here(
    "output",
    "data_descriptions",
    "cleaning_inex",
    "med_count_summary.csv"
  )
)

message("Save graph of medication counts")
plot_med_count_distribution <-
  dataset_inex_cleaned |>
  select(inex_med_num_90, inex_med_num_180) |>
  collect() |>
  pivot_longer(
    # necessary for ggplot to colour by time window
    cols = everything(),
    names_to = "time_window",
    values_to = "n_prescriptions"
  ) |>
  mutate(
    time_window = case_when(
      time_window == "inex_med_num_90" ~ "90 days",
      time_window == "inex_med_num_180" ~ "180 days"
    )
  ) |>
  ggplot(aes(x = n_prescriptions, colour = time_window, fill = time_window)) +
  geom_freqpoly(binwidth = 1, linewidth = 0.8) +
  labs(
    title = "Distribution of medication counts before index date",
    x = "Number of prescriptions",
    y = "Number of patients",
    colour = "Time window"
  )

ggsave(
  filename = here::here(
    "output",
    "figures",
    "cleaning_inex",
    "plot_med_count_distribution.png"
  ),
  plot = plot_med_count_distribution,
  width = 8,
  height = 6,
  dpi = 300
)

message("Save cleaned dataset to output/data/")
dataset_inex_cleaned |>
  arrow::write_feather(
    here::here("output", "data", "dataset_inex_cleaned.arrow"),
  )

message("Save flow table to to output/data_descriptions/cleaning_inex/")
write_csv(
  flow,
  here::here("output", "data_descriptions", "cleaning_inex", "data_flow.csv")
)
