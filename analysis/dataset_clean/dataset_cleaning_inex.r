##### describe this script #####

message("Import libraries and functions")
library(fs)
library(here)
library(data.table)
library(arrow)
library(dplyr)
library(lubridate)
source(here::here("analysis", "functions", "fn_transform_variables.r"))
source(here::here("analysis", "functions", "fn_build_flow_counts.r"))
source(here::here("analysis", "functions", "fn_describe_data.r"))
source(here::here("analysis", "functions", "fn_describe_and_flow.r"))
source(here::here("analysis", "functions", "fn_disclosure_control.r"))
source(here::here("analysis", "functions", "fn_qa.r"))
source(here::here("analysis", "functions", "fn_dem_inex_criteria.r"))
source(here::here("analysis", "functions", "fn_ckd_inex_criteria.r"))


message("Create output folder")
dir_create(here::here("output", "data"))
dir_create(here::here("output", "data_descriptions"))

message("Import dates")
source(here::here("analysis", "dataset_definition", "study_dates.r"))
study_dates <- lapply(study_dates, function(x) as.Date(x))


message("Process the dataset lazily \n")

input_filename = "dataset.arrow"

# Load dataset, keeping in arrow format for speed
dataset_cleaning_1_input <- arrow::open_dataset(
  here::here("output", input_filename),
  format = "ipc"
)

# transform variables into desired classes
dataset_cleaning_2_transformed <- fn_transform_variables(
  arrow_data = dataset_cleaning_1_input,
  collect_and_describe = FALSE
)

# apply qa criteria
dataset_cleaning_3_qa_applied <- fn_qa(
  arrow_data = dataset_cleaning_2_transformed,
  rounding_threshold = 6,
  collect_and_describe = FALSE
)

message("") # blank line to make console output easier to read

# apply demographic inclusion and exclusion criteria
dataset_cleaning_4_demographic_inex_applied <- fn_dem_inex_criteria(
  arrow_data = dataset_cleaning_3_qa_applied,
  rounding_threshold = 6,
  collect_and_describe = FALSE
)

message("") # blank line to make console output easier to read

# apply CKD inclusion criteria

dataset_cleaning_5_ckd_inex_applied <- fn_ckd_inex_criteria(
  arrow_data = dataset_cleaning_4_demographic_inex_applied,
  rounding_threshold = 6,
  collect_and_describe = FALSE,
  index_date = study_dates$index_date
)

# write all datasets to .txt and flow dataframe

flow <- describe_and_flow(
  project_stage = "cleaning"
)

# save the outputs
message("Save cleaned dataset and flow")

dataset_cleaning_5_ckd_inex_applied |>
  arrow::write_dataset(
    here::here("output", "data", "dataset_cleaned.arrow"),
    format = "ipc"
  )

data.table::fwrite(flow, here::here("output", "data", "data_cleaning_flow.csv"))
