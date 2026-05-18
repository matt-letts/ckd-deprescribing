##########################################################################
# This script defines and stores study-wide parameters and definitions
##########################################################################

library(jsonlite)
library(here)
library(fs)

# Study dates ------------------------------------------------------------
fs::dir_create(here::here("output"))

study_dates <- list(
  index_date = "2022-03-01",
  end_date = "2026-02-28"
)

# .json to be called by ehrQL and R scripts
write_json(
  study_dates,
  path = here::here("output", "study_dates.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)

# Chronic medication analyses ---------------------------------------------
chronic_med_definitions <- list(
  base = list(
    min_prescriptions = 2,
    lookback_days = 180,
    allowable_index_gap = 90,
    prior_fill_gap = 21,
    per_half = FALSE
  )
)
