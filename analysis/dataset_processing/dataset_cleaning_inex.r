##########################################################################
# This script does the following:
# 1. Load output/dataset_inex.arrow created by generate_dataset_inex
# 2. Modifies the dummy data if being run locally
# 3. Type formats the variables
# 4. Applies QA criteria and inclusion/exclusion criteria
# 5. Plots and tabulates the medication counts within 90/180 days of index
# 6. Saves cleaned dataset, plot, data-flow table and description files
##########################################################################

# Import libraries and functions -----------------------------------------
message("Import libraries and functions \n")
library(fs)
library(here)
library(data.table)
library(arrow)
library(dplyr)
library(lubridate)
library(ggplot2)
library(tidyr)
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
dir_create(here::here("output", "data_descriptions"))
dir.create(here::here("output", "figures"))

# Import dates -----------------------------------------------------------
message("Import dates")
source(here::here("analysis", "dataset_definition", "study_dates.r"))
study_dates <- lapply(study_dates, function(x) as.Date(x))

# Load dataset, keeping in arrow format for speed ------------------------
message("Load the dataset for lazy processing")
input_filename = "dataset_inex.arrow"
dataset_cleaning_inex_1_input <- arrow::open_dataset(
  here::here("output", input_filename),
  format = "ipc"
)

# Preprocess data: transform variables and modify dummy data -------------
# do I need to convert str variables to factors once collected?
dataset_cleaning_inex_2_preprocessed <- fn_preprocess(
  arrow_data = dataset_cleaning_inex_1_input,
  dataset = "inex",
  index_date = study_dates$index_date,
  collect_and_describe = FALSE
)

# Apply qa criteria ------------------------------------------------------
dataset_cleaning_inex_3_qa_applied <- fn_qa(
  arrow_data = dataset_cleaning_inex_2_preprocessed,
  rounding_threshold = 6,
  collect_and_describe = FALSE
)

# Apply demographic inclusion and exclusion criteria ---------------------
dataset_cleaning_inex_4_demographic_inex_applied <- fn_dem_inex_criteria(
  arrow_data = dataset_cleaning_inex_3_qa_applied,
  rounding_threshold = 6,
  collect_and_describe = FALSE
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
  rounding_threshold = 6,
  collect_and_describe = FALSE,
  index_date = study_dates$index_date
)

# Apply KRT exclusion criteria -------------------------------------------
dataset_cleaning_inex_6_krt_inex_applied <- fn_krt_inex_criteria(
  arrow_data = dataset_cleaning_inex_5_ckd_inex_applied,
  rounding_threshold = 6,
  collect_and_describe = FALSE,
  krt_source = "primary"
)

# I don't think that there will be any missing data to handle.
# and no categorical data to reframe

# Write all datasets to .txt and create flow dataframe -------------------
message("\nWrite/save data_descriptions to output/data_descriptions/")
flow <- fn_describe_and_flow(
  project_stage = "cleaning_inex"
)

# Rename cleaned dataset for clarity -------------------------------------
dataset_inex_cleaned <- dataset_cleaning_inex_6_krt_inex_applied

# Examine medication counts in 90 and 180 days prior to index date -------
message("\nTabulate the medication counts")
dataset_inex_cleaned |>
  summarise(
    across(
      c(inex_med_num_90, inex_med_num_180),
      list(
        mean = ~ mean(.x, na.rm = TRUE),
        median = ~ median(.x, na.rm = TRUE),
        p90 = ~ quantile(.x, 0.9, na.rm = TRUE),
        p95 = ~ quantile(.x, 0.95, na.rm = TRUE),
        max = ~ max(.x, na.rm = TRUE)
      )
    )
  ) |>
  collect() |>
  t() |>
  print()

message("\nGraph the medication counts")
plot_med_count_distribution <-
  dataset_inex_cleaned |>
  select(inex_med_num_90, inex_med_num_180) |>
  collect() |>
  pivot_longer(
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
    title = "Distribution of prescription counts before index date",
    x = "Number of prescriptions",
    y = "Number of patients",
    colour = "Window"
  )

# Save the outputs -------------------------------------------------------
message("\nSave cleaned dataset to output/data/")
dataset_inex_cleaned |>
  arrow::write_feather(
    here::here("output", "data", "dataset_inex_cleaned.arrow"),
  )

message("\nSave flow table to to output/data_descriptions/")
data.table::fwrite(
  flow,
  here::here("output", "data_descriptions", "cleaning_inex-data_flow.csv")
)

message("\nSave plot of medication count distributions")
ggsave(
  filename = here::here("output", "figures", "plot_med_count_distribution.png"),
  plot = plot_med_count_distribution,
  width = 8,
  height = 6,
  dpi = 300
)

# data <- dataset_inex_cleaned |> collect() # for local inspection
