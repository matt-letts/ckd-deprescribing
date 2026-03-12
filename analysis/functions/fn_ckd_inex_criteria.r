#########################################################################################
# CKD helper functions - egfr_ckdepi2009() and fn_ckd_inex_criteria()
#########################################################################################

##### fn_egfr_ckdepi2009 #####
# this function calculates the eGFR based on a person's serum creatinine (measured in umol/L)
# their age and their sex. It uses the CKD-EPI 2009 eGFR equation, with no race coefficient,
# as recommended by UKKA/NICE), see below for formula:
# https://www.niddk.nih.gov/research-funding/research-programs/kidney-clinical-research-epidemiology/laboratory/glomerular-filtration-rate-equations/adults/previous

fn_egfr_ckdepi2009 <- function(
  creat_umol,
  age,
  sex
) {
  # define the sex specific constants
  kappa <- ifelse(sex == "female", 61.9, 79.6)
  alpha <- ifelse(sex == "female", -0.329, -0.411)
  female_multiplier <- ifelse(sex == "female", 1.018, 1.0)

  # ratio used for the piecewise formula
  ratio <- creat_umol / kappa

  round(
    141 *
      pmin(ratio, 1)^alpha *
      pmax(ratio, 1)^-1.209 *
      (0.993^age) *
      female_multiplier
  )
}


##### fn_ckd_inex_criteria #####

# this 7 step custom function applies CKD inc/exc criteria.

# 1. Calculate eGFR for just those with 2+ SCr measurements
# --- Calculate the most recent eGFR (egfr_1), and
# --- Calculate the second most recent eGFR (egfr_2), 90+ days prior to egfr_1
# (of note eGFR calculations are made using the age of the individual at the time of the
# creatinine measurement, by calculating their age compared to their age at index_date)

# 2. Define those with CKD 4/5 based on eGFR
# --- store as boolean variable 'has_ckd45_by_scr'

# 3. Join the new variables back to the full dataset
# --- has_ckd45_by_scr == FALSE added to all rows where has_ckd45_by_scr != TRUE

# 4. Flag those with either CKD4/5 codes or CKD4/5 eGFRs

# 5. Count and print rounded totals for people included/excluded by CKD criteria

# 6. Apply the inclusion criteria

# 7. (optionally) Collect the resulting arrow data into an R data.table for manipulation

fn_ckd_inex_criteria <- function(
  arrow_data,
  rounding_threshold = 6,
  collect_and_describe = FALSE,
  index_date,
  describe_name = "",
  suffix = ""
) {
  require(arrow)
  require(dplyr)
  require(lubridate)

  # 1. Calculate eGFR

  ckd_scr <- arrow_data |>
    filter(inex_ckd_bin_has_two_scr) |>
    mutate(
      # Age at each SCr measurement
      age_at_scr_1 = inex_dem_num_age +
        (as.integer(inex_ckd_date_scr_date_1) - as.integer(index_date)) /
          365.25,
      age_at_scr_2 = inex_dem_num_age +
        (as.integer(inex_ckd_date_scr_date_2) - as.integer(index_date)) /
          365.25,

      # eGFR at each measurement
      egfr_1 = fn_egfr_ckdepi2009(
        creat_umol = inex_ckd_num_scr_value_1,
        age = age_at_scr_1,
        sex = inex_dem_cat_sex
      ),
      egfr_2 = fn_egfr_ckdepi2009(
        creat_umol = inex_ckd_num_scr_value_2,
        age = age_at_scr_2,
        sex = inex_dem_cat_sex
      ),

      # 2. Define those with CKD 4/5 based on eGFR
      # THIS ? NEEDS IMPROVEMENT AND ADDING IN EXTRA COLUMNS FOR CKD 4 AND CKD 5

      has_ckd45_by_scr = (egfr_1 < 30) & (egfr_2 < 30)
    )

  # 3. Join the new variables back to the full dataset

  arrow_data <- arrow_data |>
    left_join(
      ckd_scr |> select(patient_id, has_ckd45_by_scr, egfr_1, egfr_2),
      by = "patient_id"
    ) |>
    mutate(
      has_ckd45_by_scr = ifelse(
        is.na(has_ckd45_by_scr), # FALSE flag added to all those who were not in the filtered set for 1.
        FALSE,
        has_ckd45_by_scr
      )
    )

  # 4. Flag those with either CKD4/5 codes or CKD4/5 eGFRs

  arrow_data <- arrow_data |>
    mutate(
      include_ckd45 = inex_ckd_bin_has_ckd45_code | has_ckd45_by_scr
    )

  # 5. Count and print rounded totals for people included/excluded by CKD criteria

  counts <- arrow_data |>
    summarise(
      n_before = n(),
      n_has_ckd45_code = sum(inex_ckd_bin_has_ckd45_code, na.rm = TRUE),
      n_ckd45_by_scr = sum(has_ckd45_by_scr, na.rm = TRUE),
      n_ckd45_by_either = sum(include_ckd45, na.rm = TRUE),
      n_excluded_no_ckd45 = sum(!include_ckd45, na.rm = TRUE)
    ) |>
    collect()

  message("\nCKD 4/5 inclusion criteria:")
  message(
    "n before CKD filters: ",
    fn_roundmid_any(counts$n_before, to = rounding_threshold)
  )
  message(
    "Included via CKD 4/5 code: ",
    fn_roundmid_any(counts$n_has_ckd45_code, to = rounding_threshold)
  )
  message(
    "Included via SCr eGFR < 30 (both values): ",
    fn_roundmid_any(counts$n_ckd45_by_scr, to = rounding_threshold)
  )
  message(
    "Included via either criterion: ",
    fn_roundmid_any(counts$n_ckd45_by_either, to = rounding_threshold)
  )
  message(
    "EXCLUDED (no CKD 4/5 evidence): ",
    fn_roundmid_any(counts$n_excluded_no_ckd45, to = rounding_threshold)
  )

  # 6. Apply the inclusion criteria

  arrow_data_ckd_inex_applied <- arrow_data |>
    filter(include_ckd45)

  # 7. (optionally) Collect the resulting arrow data into an R data.table for manipulation

  if (collect_and_describe) {
    arrow_data_ckd_inex_applied <- arrow_data_ckd_inex_applied |>
      collect() |>
      data.table::as.data.table()

    describe_data(
      data = arrow_data_ckd_inex_applied,
      name = describe_name,
      suffix = suffix
    )
  }

  return(arrow_data_ckd_inex_applied)
}
