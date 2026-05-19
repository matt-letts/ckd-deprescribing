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

write_json(
  study_dates,
  path = here::here("output", "study_dates.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)

# Which BNF chapters to exclude ------------------------------------------
# BNF chapter list for reference:
#   01: gastro-intestinal system
#   02: cardiovascular system
#   03: respiratory system
#   04: central nervous system
#   05: infections
#   06: endocrine system
#   07: obstetrics, gynaecology, and urinary-tract disorders
#   08: malignant disease and immunosuppression
#   09: nutrition and blood
#   10: musculoskeletal and joint diseases
#   11: eye
#   12: ear, nose, and oropharynx
#   13: skin
#   14: immunological products and vaccines
#   15: anaesthesia
#   16: [does not exist]
#   17: [does not exist]
#   18: preparations used in diagnosis
#   19: other drugs and preparations
#   20: dressings
#   21: appliances
#   22: incontinence appliances
#   23: stoma appliances
exclude_bnf_chapters <- list(
  base = c("14", "15", "18", "19", "20", "21", "22", "23")
)

# How to define whether a medicine is chronically prescribed -------------
chronic_med_definitions <- list(
  base = list(
    min_prescriptions = 2,
    lookback_days = 180,
    allowable_index_gap = 90,
    prior_fill_gap = 21,
    per_half = FALSE
  )
)
