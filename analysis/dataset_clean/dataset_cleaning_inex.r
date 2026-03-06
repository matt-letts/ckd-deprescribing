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



message("Create output folder")
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


# write all datasets to .txt and flow dataframe
flow <- describe_and_flow(
  project_stage = "cleaning"
)






| Section           | Purpose                                |
| ----------------- | -------------------------------------- |
| Setup             | Load packages                          |
| Import            | Read dataset                           |
| Cleaning          | Fix types, dates, missing values       |
| Flag definitions  | Explicit inclusion/exclusion variables |
| Population flag   | Final analytic cohort                  |
| Flow summary      | Audit trail                            |
| Derived variables | Age bands, stage groups                |
| Export            | Clean dataset + counts                 |



fn_roundmid_any <- function(x, to = 6) {
  stopifnot(is.numeric(x))
  ceiling(x / to) * to - (floor(to / 2) * (x != 0))
}

fn_roundmid_any(df)

df <- read.csv(
  "C:/Users/yv22008/Git/matt-letts/ckd-deprescribing/output/dataset.csv.gz"
)


# Rounding function for redaction ----
roundmid_any <- function(x, to = 6) {
  # centers on (integer) midpoint of the rounding points
  x <- as.numeric(x)
  ceiling(x / to) * to - (floor(to / 2) * (x != 0))
}



# never sorted out the _cat variables within the dataset - need to do this before the final bit
fn_postcollect_types <- function(dt) {
  dt[, (grep("_cat", names(dt), value = TRUE)) :=
       lapply(.SD, as.factor),
     .SDcols = grep("_cat", names(dt), value = TRUE)]

  return(dt)
}