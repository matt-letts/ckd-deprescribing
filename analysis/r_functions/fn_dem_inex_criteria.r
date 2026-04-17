##########################################################################
# This script does the following:
# 1. Defines fn_dem_inex_criteria() which applies demographic inclusion
#    and exclusion criteria
# 2. Excludes patients who are not alive at index date
# 3. Excludes patients outside the eligible age range at index date
# 4. Excludes patients without 12 months of continuous registration
#    prior to index date
# 5. Counts and records exclusions at each step using fn_data_flow()
#    with disclosure control rounding applied via fn_roundmid_any()
#
# Called by dataset_cleaning_inex.r
##########################################################################

fn_dem_inex_criteria <- function(
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
      n_not_alive = sum(!inex_dem_bin_alive, na.rm = TRUE),
      n_age_out_of_range = sum(!inex_dem_bin_age_include, na.rm = TRUE),
      n_not_registered_1yr = sum(!inex_dem_bin_12m_registered, na.rm = TRUE),
    ) |>
    collect()

  # Print exclusion counts rounded for disclosure control
  message("\nDemographic exclusions (rounded):")
  message(
    "n before demographic exclusions: ",
    fn_roundmid_any(counts$n_before, to = rounding_threshold)
  )
  message(
    "Not alive at index date: ",
    fn_roundmid_any(counts$n_not_alive, to = rounding_threshold)
  )
  message(
    "Age out of range: ",
    fn_roundmid_any(counts$n_age_out_of_range, to = rounding_threshold)
  )
  message(
    "Registered <1 yr: ",
    fn_roundmid_any(counts$n_not_registered_1yr, to = rounding_threshold)
  )

  # Apply demographic filters lazily
  arrow_data_dem_inex_applied <- arrow_data %>%
    filter(
      inex_dem_bin_alive,
      inex_dem_bin_age_include,
      inex_dem_bin_12m_registered
    )

  # load dataset as R data.table object if collect_and_describe = TRUE
  if (collect_and_describe) {
    arrow_data_dem_inex_applied <- arrow_data_dem_inex_applied %>%
      collect() %>%
      data.table::as.data.table()

    fn_describe_data(
      data = arrow_data_dem_inex_applied,
      name = describe_name,
      suffix = suffix
    )
  }

  return(arrow_data_dem_inex_applied)
}
