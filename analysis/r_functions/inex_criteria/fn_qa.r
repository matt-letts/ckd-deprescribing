##########################################################################
# This script Defines fn_qa() which applies quality assurance
# exclusion criteria to the dataset:
# 1. Excludes patients with missing sex, region, ethnicity, or IMD
# 2. Counts and records exclusions at each step
##########################################################################

fn_qa <- function(
  arrow_data
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

  # Print exclusion counts
  message("\nQA exclusions:")
  message("n before QA exclusions: ", counts$n_before)
  message("Missing sex: ", counts$n_missing_sex)
  message("Missing region: ", counts$n_missing_region)
  message("Missing ethnicity: ", counts$n_missing_ethnicity)
  message("Missing deprivation level: ", counts$n_missing_imd)

  # Apply QA filters lazily
  arrow_data_qa_applied <- arrow_data |>
    filter(
      inex_qa_bin_sex,
      inex_qa_bin_region,
      inex_qa_bin_ethnicity,
      inex_qa_bin_imd
    )

  return(arrow_data_qa_applied)
}
