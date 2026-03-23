message("Import libraries and functions \n")
library(fs)
library(here)
library(data.table)
library(arrow)
library(dplyr)
library(lubridate)

cleaned_data <- read_feather(here::here(
  "output",
  "data",
  "dataset_inex_cleaned.arrow"
))
with_meds <- read_feather(here::here("output", "dataset_inex_meds.arrow"))
big_meds_table <- read_delim_arrow(
  here::here("dummy_tables", "medications.csv"),
  delim = ","
)
