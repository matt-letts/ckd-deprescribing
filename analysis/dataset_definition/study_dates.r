###########################################################
# Simple R script to write the study dates as a json file
# which can be called at various stages of project pipeline
###########################################################

library(jsonlite)
library(here)

# Ensure output directory exists
fs::dir_create(here::here("output"))

# list the study dates and then write into json
study_dates <-
  list(
    index_date = "2022-03-01",
    end_date = "2026-02-28"
  )

write_json(
  study_dates,
  path = "output/study_dates.json",
  auto_unbox = TRUE,
  pretty = TRUE
)
