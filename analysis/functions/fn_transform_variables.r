fn_transform_variables <- function(
  input_filename,
  collect_data = FALSE
) {
  require(arrow)
  require(dplyr)

  # Open lazily
  dataset <- arrow::open_dataset(
    here::here("output", input_filename),
    format = "ipc"
  )

  # Apply transformations lazily
  dataset_preclean <- dataset %>%
    mutate(
      across(contains("_date"), ~ as.Date(.)),
      across(contains("_num"), ~ as.numeric(.)),
      #across(contains("_cat"), ~ as.factor(.)), - cannot be done lazily in arrow format
      across(contains("_bin"), ~ as.logical(.))
    )

  # load dataset as R data.table object if collect_data = TRUE
  if (collect_data) {
    dataset_preclean <- dataset_preclean %>%
      collect() %>%
      data.table::as.data.table()
  }

  return(dataset_preclean)
}

#   # Read feather file
#   dataset_preclean <- arrow::read_feather(
#     here::here("output", input_filename)
#   )

#   # Convert immediately to data.table (efficient for 25M rows)
#   dataset_preclean <- data.table::as.data.table(dataset_preclean)

#   # ---- Fix date columns ----
#   date_cols <- grep("_date$", names(dataset_preclean), value = TRUE)

#   for (col in date_cols) {
#     dataset_preclean[, (col) := as.IDate(get(col))]
#   }

#   # ---- Birth year columns (extract year only) ----
#   birth_cols <- grep("_birth_year$", names(dataset_preclean), value = TRUE)

#   for (col in birth_cols) {
#     dataset_preclean[, (col) := format(as.Date(get(col)), "%Y")]
#   }

#   # ---- Numeric columns ----
#   num_cols <- grep("_num$", names(dataset_preclean), value = TRUE)

#   for (col in num_cols) {
#     dataset_preclean[, (col) := as.numeric(get(col))]
#   }

#   # ---- Categorical columns ----
#   cat_cols <- grep("_cat$", names(dataset_preclean), value = TRUE)

#   for (col in cat_cols) {
#     dataset_preclean[, (col) := as.factor(get(col))]
#   }

#   # ---- Binary columns ----
#   bin_cols <- grep("_bin$", names(dataset_preclean), value = TRUE)

#   for (col in bin_cols) {
#     dataset_preclean[, (col) := as.logical(get(col))]
#   }

#   return(dataset_preclean)
# }
