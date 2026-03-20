#############################################################################
# This function takes an arrow file (specified by input_filename
# taken from 'output' directory) and ensures that the data are in the
# correct class (date ~ as.Date etc). collect_and_describe is an additional argument
# that when true will 'collect' the arrow data file as an R data.table object
# and then pass it through the describe_data() function defined in fn_describe_data.r
# describe_name and suffix will give the name of the file that the data is
# described to in the output/data_descriptions directory
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
      across(contains("_bin_"), ~ as.logical(.))
    ) |>
    filter(!is.na(patient_id))

  # load dataset as R data.table object if collect_data = TRUE
  if (collect_and_describe) {
    arrow_data_preprocessed <- arrow_data_preprocessed %>%
      collect() %>%
      data.table::as.data.table()

    describe_data(
      data = arrow_data_preprocessed,
      name = describe_name,
      suffix = suffix
    )
  }

  return(arrow_data_preprocessed)
}
