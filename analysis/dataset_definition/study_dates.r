# Write the study dates as a json file to then be called via the project.yaml

library(jsonlite)
library(here)

# Create an output directory
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
