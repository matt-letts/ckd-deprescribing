##########################################################################
# This script does the following:
# 1. Defines fn_qa() which applies quality assurance exclusion criteria
# 2. Excludes patients with missing sex, region, ethnicity, or IMD
# 3. Counts and records exclusions at each step using fn_data_flow()
#    with disclosure control rounding applied via fn_roundmid_any()
#
# Called by dataset_cleaning_inex.r
##########################################################################

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
  message("\nQA exclusions (rounded):")
  message(
    "n before QA exclusions: ",
    fn_roundmid_any(counts$n_before, to = rounding_threshold)
  )
  message(
    "Missing sex: ",
    fn_roundmid_any(counts$n_missing_sex, to = rounding_threshold)
  )
  message(
    "Missing region: ",
    fn_roundmid_any(counts$n_missing_region, to = rounding_threshold)
  )
  message(
    "Missing ethnicity: ",
    fn_roundmid_any(counts$n_missing_ethnicity, to = rounding_threshold)
  )
  message(
    "Missing deprivation level: ",
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

    fn_describe_data(
      data = arrow_data_qa_applied,
      name = describe_name,
      suffix = suffix
    )
  }

  return(arrow_data_qa_applied)
}
