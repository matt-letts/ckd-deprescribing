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
source(here::here("analysis", "functions", "fn_transform_variables.r"))
source(here::here("analysis", "functions", "fn_data_describing.r"))
source(here::here("analysis", "functions", "fn_disclosure_control.r"))
source(here::here("analysis", "functions", "fn_qa.r"))
source(here::here("analysis", "functions", "fn_dem_inex_criteria.r"))
source(here::here("analysis", "functions", "fn_ckd_inex_criteria.r"))

message("Create output folders")
dir_create(here::here("output", "data"))
dir_create(here::here("output", "data_descriptions"))

message("Import dates")
source(here::here("analysis", "dataset_definition", "study_dates.r"))
study_dates <- lapply(study_dates, function(x) as.Date(x))

message("Process the dataset lazily")

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

# apply demographic inclusion and exclusion criteria
dataset_cleaning_4_demographic_inex_applied <- fn_dem_inex_criteria(
  arrow_data = dataset_cleaning_3_qa_applied,
  rounding_threshold = 6,
  collect_and_describe = FALSE
)

# apply CKD inclusion criteria
# 4 new variables added to data:
# - num_egfr_1 - numerical value of most recent eGFR
# - num_egfr_2 - numerical value of most recent eGFR 90+ days prior to num_egfr_1
# - bin_has_ckd45_by_scr - boolean TRUE if eGFRs consistent with CKD G4 or G5
# - cat_ckd_stage_by_scr - category of eGFR derived CKD (G4, G5, G4/G5, or no G4/G5)
dataset_cleaning_5_ckd_inex_applied <- fn_ckd_inex_criteria(
  arrow_data = dataset_cleaning_4_demographic_inex_applied,
  rounding_threshold = 6,
  collect_and_describe = FALSE,
  index_date = study_dates$index_date
)

# apply KRT exclusion criteria
dataset_cleaning_6_krt_inex_applied <- fn_krt_inex_criteria(
  arrow_data = dataset_cleaning_5_ckd_inex_applied,
  rounding_threshold = 6,
  collect_and_describe = FALSE,
  krt_source = "primary"
)

## I don't think that there will be any missing data to handle...
## and there are no categorical data to reframe

# write all datasets to .txt and flow dataframe
flow <- describe_and_flow(
  project_stage = "cleaning"
)

# save the outputs
message("\nSave cleaned dataset and flow")

dataset_cleaning_5_ckd_inex_applied |>
  arrow::write_dataset(
    here::here("output", "data", "dataset_cleaned.arrow"),
    format = "ipc"
  )

data.table::fwrite(flow, here::here("output", "data", "data_cleaning_flow.csv"))
