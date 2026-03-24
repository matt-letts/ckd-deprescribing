##########################################################################
# This script does the following:
# 1. FILL IN LATER
##########################################################################

# Import libraries and functions -----------------------------------------
message("Import libraries and functions \n")
library(fs)
library(here)
library(arrow)
library(dplyr)
library(lubridate)
source(here::here("analysis", "functions", "fn_preprocess.r"))
source(here::here("analysis", "functions", "fn_modify_dummy_data.r"))


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
message("Load the dataset")
input_filename = "dataset_inex_meds.arrow"
dataset_process_baseline_meds_1_input <- arrow::open_dataset(
  here::here("output", input_filename),
  format = "ipc"
)

# Preprocess data: transform variables and modify dummy data
dataset_process_baseline_meds_2_preprocessed <- fn_preprocess(
  arrow_data = dataset_process_baseline_meds_1_input,
  dataset = "baseline_meds",
  index_date = study_dates$index_date,
  collect_and_describe = FALSE
)


cleaned_data <- dataset_process_baseline_meds_1_input |> collect()
# with_meds <- read_feather(here::here("output", "dataset_inex_meds.arrow"))
# big_meds_table <- read_delim_arrow(
#   here::here("dummy_tables", "medications.csv"),
#   delim = ","
# )
