fn_qa <- function(
  arrow_data,
  rounding_threshold = 6,
  collect_and_describe = FALSE,
  describe_name = "",
  suffix = ""
) {
  require(arrow)
  require(dplyr)

  # Count the numbers that fail each qa criteria respectively
  counts <- arrow_data |>
    summarise(
      n_before = n(),
      n_missing_sex = sum(!inex_qa_bin_sex, na.rm = TRUE),
      n_missing_region = sum(!inex_qa_bin_region, na.rm = TRUE),
      n_missing_ethnicity = sum(!inex_qa_bin_ethnicity, na.rm = TRUE),
      n_missing_imd = sum(!inex_qa_bin_imd, na.rm = TRUE)
    ) |>
    collect()

  # Print exclusion counts rounded for disclosure control
  message("QA exclusions:")
  message(
    "Missing sex:",
    fn_roundmid_any(counts$n_missing_sex, to = rounding_threshold)
  )
  message(
    "Missing region:",
    fn_roundmid_any(counts$n_missing_region, to = rounding_threshold)
  )
  message(
    "Missing ethnicity:",
    fn_roundmid_any(counts$n_missing_ethnicity, to = rounding_threshold)
  )
  message(
    "Missing deprivation level:",
    fn_roundmid_any(counts$n_missing_imd, to = rounding_threshold)
  )

  # Apply QA filters lazily
  arrow_data_qa_applied <- arrow_data %>%
    filter(
      inex_qa_bin_sex,
      inex_qa_bin_region,
      inex_qa_bin_ethnicity,
      inex_qa_bin_imd
    )

  # load dataset as R data.table object if collect_and_describe = TRUE
  if (collect_and_describe) {
    arrow_data_qa_applied <- arrow_data_qa_applied %>%
      collect() %>%
      data.table::as.data.table()

    describe_data(
      data = arrow_data_qa_applied,
      name = describe_name,
      suffix = suffix
    )
  }

  return(arrow_data_qa_applied)
}
