#############################################################################
# fn_preprocess():
# 1. Optionally modifies dummy data if running locally
# 2. Checks for duplicate patient_ids if one-row-per-patient data
# 3. Applies type casting based on variable naming conventions
# 4. Filters out rows with missing patient_id
# 5. Optionally collects to data.table and writes a data description
#
# Arguments:
#   arrow_data : arrow project_stage object
#   project_stage : string label passed to fn_modify_dummy_data()
#   index_date : study index date
#   collect_and_describe : if TRUE, collect() and write description file
#   describe_name / suffix : name the description output file
#   one_row_per_patient : if TRUE (default), warn if duplicate patient_ids
#############################################################################

fn_preprocess <- function(
  arrow_data,
  project_stage,
  index_date,
  collect_and_describe = FALSE,
  describe_name = "",
  suffix = "",
  one_row_per_patient = TRUE
) {
  require(arrow)
  require(dplyr)

  if (Sys.getenv("OPENSAFELY_BACKEND") %in% c("", "expectations")) {
    arrow_data <- fn_modify_dummy_data(
      arrow_data,
      project_stage = project_stage,
      index_date = index_date
    )
  }

  # Check for duplicate patient IDs if expected to be one row per patient
  if (one_row_per_patient) {
    counts <- arrow_data |>
      summarise(n_rows = n(), n_distinct = n_distinct(patient_id)) |>
      collect()
    if (counts$n_rows != counts$n_distinct) {
      warning(sprintf(
        "fn_preprocess: %d duplicate patient_id(s) detected (%d rows, %d distinct patients)",
        counts$n_rows - counts$n_distinct,
        counts$n_rows,
        counts$n_distinct
      ))
    }
  }

  # Apply transformations lazily
  arrow_data_preprocessed <- arrow_data |>
    mutate(
      across(contains("_date_"), ~ as.Date(.)),
      across(contains("_num_"), ~ as.numeric(.)),
      across(contains("_cat_"), ~ as.character(.)), # as.factor() not supported lazily in arrow format
      # apply trimws() and na.if(., "") to the character variables - not necessary
      across(contains("_bin_"), ~ as.logical(.)),
      across(contains("_dmd_code_"), ~ as.character(.)) # dmd_codes as strings, too big as numbers
    ) |>
    filter(!is.na(patient_id))

  # load data as R data.table object if collect_data = TRUE
  if (collect_and_describe) {
    require(data.table)
    arrow_data_preprocessed <- arrow_data_preprocessed %>%
      collect() %>%
      as.data.table()

    fn_describe_data(
      data = arrow_data_preprocessed,
      name = describe_name,
      suffix = suffix
    )
  }

  return(arrow_data_preprocessed)
}
