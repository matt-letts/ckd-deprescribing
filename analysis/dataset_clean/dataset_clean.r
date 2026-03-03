print("Import libraries and functions")
library(fs)
library(here)
library(data.table)
library(arrow)
library(dplyr)
library(lubridate)
source(here::here("analysis", "functions", "fn_transform_variables.r"))
source(here::here("analysis", "functions", "fn_build_flow_counts.r"))


print("Create output folder")
dir_create(here::here("output", "dataset_clean", "data"))
dir_create(here::here("output", "dataset_clean", "data_description"))

print("Import dates")
source(here::here("analysis", "dataset_definition", "study_dates.r"))
study_dates <- lapply(study_dates, function(x) as.Date(x))

print("Process dataset lazily")
input_filename <- "dataset.arrow"
lazy_transformed_dataset <- fn_transform_variables(input_filename)

flow_results <- fn_build_flow_counts(lazy_transformed_dataset)



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

# Function for describing data ----
describe_data <- function(df, name) {
  fs::dir_create(here::here("output/describe/"))
  sink(paste0("output/describe/", name, ".txt"))
  print(skimr::skim(df))
  sink()
  message(paste0("output/describe/", name, ".txt written successfully."))
}

# never sorted out the _cat variables within the dataset - need to do this before the final bit
fn_postcollect_types <- function(dt) {
  dt[, (grep("_cat", names(dt), value = TRUE)) :=
       lapply(.SD, as.factor),
     .SDcols = grep("_cat", names(dt), value = TRUE)]

  return(dt)
}