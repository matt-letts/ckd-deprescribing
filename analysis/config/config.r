##########################################################################
# config.r
# Defines and stores study-wide parameters and definitions
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

# .json easily called by ehrQL and R scripts
write_json(
  study_dates,
  path = here::here("output", "study_dates.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)

# Chronic medication sensitivity analyses --------------------------------
chronic_med_definitions <- list()
