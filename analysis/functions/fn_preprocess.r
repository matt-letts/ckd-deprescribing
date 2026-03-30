#############################################################################
# This function takes an arrow file and ensures that the data are of the
# correct type. collect_and_describe is an optional argument
# that if true will collect() the data into an R data.table object
# and pass it into describe_data() defined in fn_describe_data.r
# describe_name and suffix determine the name of the file that the data is
# described to: output/data_descriptions/<describe_name>-<suffix>.txt
#############################################################################

fn_preprocess <- function(
  arrow_data,
  dataset,
  index_date,
  collect_and_describe = FALSE,
  describe_name = "",
  suffix = ""
) {
  require(arrow)
  require(dplyr)

  if (Sys.getenv("OPENSAFELY_BACKEND") %in% c("", "expectations")) {
    arrow_data <- fn_modify_dummy_data(
      arrow_data,
      dataset = dataset,
      index_date = index_date
    )
  }

  # Apply transformations lazily
  arrow_data_preprocessed <- arrow_data |>
    mutate(
      across(contains("_date_"), ~ as.Date(.)),
      across(contains("_num_"), ~ as.numeric(.)),
      across(contains("_cat_"), ~ as.character(.)), # as.factor() not supported lazily in arrow format
      across(contains("_bin_"), ~ as.logical(.)),
      across(contains("_dmd_code_"), ~ as.character(.)) # dmd_codes as strings as too big as numbers
    ) |>
    filter(!is.na(patient_id))

  # load dataset as R data.table object if collect_data = TRUE
  if (collect_and_describe) {
    arrow_data_preprocessed <- arrow_data_preprocessed %>%
      collect() %>%
      data.table::as.data.table()

    fn_describe_data(
      data = arrow_data_preprocessed,
      name = describe_name,
      suffix = suffix
    )
  }

  return(arrow_data_preprocessed)
}
