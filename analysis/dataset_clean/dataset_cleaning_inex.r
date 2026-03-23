##### describe this script #####
##### I somehow want to put the original dataset.arrow into the output/data folder
#####

message("Import libraries and functions \n")
library(fs)
library(here)
library(data.table)
library(arrow)
library(dplyr)
library(lubridate)
library(ggplot2)
library(tidyr)
source(here::here("analysis", "functions", "fn_preprocess.r"))
source(here::here("analysis", "functions", "fn_modify_dummy_data.r"))
source(here::here("analysis", "functions", "fn_data_describing.r"))
source(here::here("analysis", "functions", "fn_disclosure_control.r"))
source(here::here("analysis", "functions", "fn_qa.r"))
source(here::here("analysis", "functions", "fn_dem_inex_criteria.r"))
source(here::here("analysis", "functions", "fn_ckd_inex_criteria.r"))

message("Create output folders")
dir_create(here::here("output", "data"))
dir_create(here::here("output", "data_descriptions"))
dir.create(here::here("output", "figures"))

message("Import dates")
source(here::here("analysis", "dataset_definition", "study_dates.r"))
study_dates <- lapply(study_dates, function(x) as.Date(x))

message("Process the dataset lazily")

input_filename = "dataset_inex.arrow"

# Load dataset, keeping in arrow format for speed
dataset_cleaning_inex_1_input <- arrow::open_dataset(
  here::here("output", input_filename),
  format = "ipc"
)

# Preprocess data - including transforming and modifying dummy data
dataset_cleaning_inex_2_preprocessed <- fn_preprocess(
  arrow_data = dataset_cleaning_inex_1_input,
  dataset = "inex",
  index_date = study_dates$index_date,
  collect_and_describe = FALSE
)

# apply qa criteria
dataset_cleaning_inex_3_qa_applied <- fn_qa(
  arrow_data = dataset_cleaning_inex_2_preprocessed,
  rounding_threshold = 6,
  collect_and_describe = FALSE
)

# apply demographic inclusion and exclusion criteria
dataset_cleaning_inex_4_demographic_inex_applied <- fn_dem_inex_criteria(
  arrow_data = dataset_cleaning_inex_3_qa_applied,
  rounding_threshold = 6,
  collect_and_describe = FALSE
)

# apply CKD inclusion criteria
# 4 new variables added to data:
# - inex_num_egfr_1 - numerical value of most recent eGFR
# - inex_num_egfr_2 - numerical value of most recent eGFR 90+ days prior to inex_num_egfr_1
# - inex_bin_has_ckd45_by_scr - boolean TRUE if eGFRs consistent with CKD G4 or G5
# - inex_cat_ckd_stage_by_scr - category of eGFR derived CKD (G4, G5, G4/G5, or no G4/G5)
dataset_cleaning_inex_5_ckd_inex_applied <- fn_ckd_inex_criteria(
  arrow_data = dataset_cleaning_inex_4_demographic_inex_applied,
  rounding_threshold = 6,
  collect_and_describe = FALSE,
  index_date = study_dates$index_date
)

# apply KRT exclusion criteria
dataset_cleaning_inex_6_krt_inex_applied <- fn_krt_inex_criteria(
  arrow_data = dataset_cleaning_inex_5_ckd_inex_applied,
  rounding_threshold = 6,
  collect_and_describe = FALSE,
  krt_source = "primary"
)

## I don't think that there will be any missing data to handle...
## and there are no categorical data to reframe

# write all datasets to .txt and flow dataframe
message("\nWrite data_descriptions to output/data_descriptions/")
flow <- describe_and_flow(
  project_stage = "cleaning_inex"
)

# rename cleaned dataset for clarity
dataset_inex_cleaned <- dataset_cleaning_inex_6_krt_inex_applied

# look at the medication counts
message("\nTabulate the medication counts\n")
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

message("\nGraph the medication counts\n")
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

# save the outputs
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
# need to remember to convert str variables to factors once collected
# data <- dataset_inex_cleaned |> collect() # for local inspection
