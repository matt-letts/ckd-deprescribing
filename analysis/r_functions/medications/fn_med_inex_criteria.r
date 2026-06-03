#######################################################################################
# fn_apply_med_inex_criteria()
#######################################################################################
# Applies inclusion/exclusion criteria to long-format patient data.
#
# Arguments:
#   patient_data : data frame - one row per medication per patient
#   project_stage : string label used for outputs
#   exclude_bnf_chapters : BNF chapter codes to remove.
#                          Default NULL = no chapter filtering.
#   exclude_route_cats : route_cat values to exclude.
#                        Default NULL = no route filtering.
#
# Returns: filtered long-format data frame
#######################################################################################

fn_apply_med_inex_criteria <- function(
  patient_data,
  project_stage,
  exclude_bnf_chapters = NULL,
  exclude_route_cats = NULL
) {
  require(tidyverse)

  message("Running fn_apply_med_inex_criteria")
  message(sprintf(
    "--- Before exclusions: %d medication rows | %d patients",
    nrow(patient_data),
    n_distinct(patient_data$patient_id)
  ))

  # BNF chapter filter -------------------------------------------------------
  if (!is.null(exclude_bnf_chapters)) {
    rows_before <- nrow(patient_data)
    patients_before <- n_distinct(patient_data$patient_id)

    patient_data <- patient_data |>
      filter(!bnf_chapter_code %in% exclude_bnf_chapters)

    rows_removed <- rows_before - nrow(patient_data)
    patients_removed <- patients_before - n_distinct(patient_data$patient_id)

    message(sprintf(
      "--- BNF chapters filtered: %d rows removed | %d patients lost all medications",
      rows_removed,
      patients_removed
    ))
  }

  # Route category filter ----------------------------------------------------
  if (!is.null(exclude_route_cats)) {
    rows_before <- nrow(patient_data)
    patients_before <- n_distinct(patient_data$patient_id)

    patient_data <- patient_data |>
      filter(!route_cat %in% exclude_route_cats)

    rows_removed <- rows_before - nrow(patient_data)
    patients_removed <- patients_before - n_distinct(patient_data$patient_id)

    message(sprintf(
      "--- Routes filtered: %d rows removed | %d patients lost all medications",
      rows_removed,
      patients_removed
    ))
  }

  message(sprintf(
    "--- After exclusions: %d medication rows | %d patients",
    nrow(patient_data),
    n_distinct(patient_data$patient_id)
  ))

  return(patient_data)
}
