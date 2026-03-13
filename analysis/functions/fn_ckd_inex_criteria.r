#########################################################################################
# This script defines three functions used to apply ckd/krt inex rules
# fn_egfr_ckdepi2009(), fn_ckd_inex_criteria(), fn_krt_inex_criteria()
#########################################################################################

#########################################################################################
# fn_egfr_ckdepi2009()
#########################################################################################

# this function calculates the eGFR based on a person's serum creatinine (measured in umol/L),
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

  141 *
    pmin(ratio, 1)^alpha *
    pmax(ratio, 1)^-1.209 *
    (0.993^age) *
    female_multiplier
}

#########################################################################################
# fn_ckd_inex_criteria()
#########################################################################################

# this multi-step function applies CKD inc/exc criteria and creates ckd-relevant variables

# 1. Calculate eGFR within people with 2+ SCr measurements and group into CKD G4, G5, or G4/G5
# --- Calculate the most recent eGFR (num_egfr_1), and
# --- Calculate the second most recent eGFR (num_egfr_2), 90+ days prior to num_egfr_1
# (of note eGFR calculations are made using the age of the individual at the time of the
# creatinine measurement, by calculating their age compared to their age at index_date)

# 2. Join new variables back to the full dataset, and fill with:
# --- bin_has_ckd45_by_scr == FALSE
# --- cat_ckd_stage_by_scr == "not G4/G5"

# 3. Apply the inclusion criteria

# 4. Re-calculate eGFR for all included individuals
# --- Done again post-filtering for efficiency. Needs doing to capture eGFR for those
# --- included via CKD codes who may only have one SCr measurement.

# 5. Count and print totals before filter and excluded by filter

# 6. (optionally) Collect the resulting arrow data into an R data.table for manipulation

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

  # 1. Calculate eGFR and group into CKD stages

  ckd_flags <- arrow_data |>
    filter(inex_ckd_bin_has_two_scr) |>
    mutate(
      num_egfr_1 = fn_egfr_ckdepi2009(
        creat_umol = inex_ckd_num_scr_value_1,
        age = inex_dem_num_age +
          (as.integer(inex_ckd_date_scr_date_1) - as.integer(index_date)) /
            365.25,
        sex = inex_dem_cat_sex
      ),
      num_egfr_2 = fn_egfr_ckdepi2009(
        creat_umol = inex_ckd_num_scr_value_2,
        age = inex_dem_num_age +
          (as.integer(inex_ckd_date_scr_date_2) - as.integer(index_date)) /
            365.25,
        sex = inex_dem_cat_sex
      ),
      cat_ckd_stage_by_scr = case_when(
        (num_egfr_1 < 15) & (num_egfr_2 < 15) ~ "G5",
        (num_egfr_1 >= 15) &
          (num_egfr_1 < 30) &
          (num_egfr_2 >= 15) &
          (num_egfr_2 < 30) ~ "G4",
        (num_egfr_1 >= 15) & (num_egfr_1 < 30) & (num_egfr_2 < 15) ~ "G4/G5",
        (num_egfr_1 < 15) & (num_egfr_2 >= 15) & (num_egfr_2 < 30) ~ "G4/G5",
        TRUE ~ "not G4/G5"
      ),
      # and flag CKD 4/5
      bin_has_ckd45_by_scr = cat_ckd_stage_by_scr != "not G4/G5"
    ) |>
    select(patient_id, bin_has_ckd45_by_scr, cat_ckd_stage_by_scr)

  # 2. Join the new variables back to the full dataset

  arrow_data <- arrow_data |>
    left_join(ckd_flags, by = "patient_id") |>
    mutate(
      bin_has_ckd45_by_scr = ifelse(
        is.na(bin_has_ckd45_by_scr),
        FALSE,
        bin_has_ckd45_by_scr
      ),
      cat_ckd_stage_by_scr = ifelse(
        is.na(cat_ckd_stage_by_scr),
        "not G4/G5",
        cat_ckd_stage_by_scr
      ),
      # change cat_ column from string to dictionary to be in line with others
      # (num_egfr1/2 and bin_has_ckd45_by_scr are correct types already numeric/logical)
      cat_ckd_stage_by_scr = arrow::cast(
        cat_ckd_stage_by_scr,
        arrow::dictionary()
      )
    )

  # 3. Apply the inclusion criteria

  arrow_data_ckd_inex_applied <- arrow_data |>
    filter(inex_ckd_bin_has_ckd45_code | bin_has_ckd45_by_scr) |>

    # 4. Re-calculate eGFR for all included individuals

    mutate(
      num_egfr_1 = fn_egfr_ckdepi2009(
        creat_umol = inex_ckd_num_scr_value_1,
        age = inex_dem_num_age +
          (as.integer(inex_ckd_date_scr_date_1) - as.integer(index_date)) /
            365.25,
        sex = inex_dem_cat_sex
      ),
      num_egfr_2 = fn_egfr_ckdepi2009(
        creat_umol = inex_ckd_num_scr_value_2,
        age = inex_dem_num_age +
          (as.integer(inex_ckd_date_scr_date_2) - as.integer(index_date)) /
            365.25,
        sex = inex_dem_cat_sex
      )
    )

  # 5. Count and print totals before filter and excluded by filter

  n_before <- arrow_data |>
    summarise(n = n()) |>
    collect() |>
    pull(n)

  n_after <- arrow_data_ckd_inex_applied |>
    summarise(n = n()) |>
    collect() |>
    pull(n)

  message("\nCKD 4/5 inclusion criteria (rounded): ")
  message(
    "n before CKD filters: ",
    fn_roundmid_any(n_before, to = rounding_threshold)
  )
  message(
    "No evidence of CKD4/5 via codes/SCrs: ",
    fn_roundmid_any(n_before - n_after, to = rounding_threshold)
  )

  # 6. (optionally) Collect the resulting arrow data into an R data.table for manipulation

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


#########################################################################################
# fn_krt_inex_criteria()
#########################################################################################
# this function excludes individuals who have been in receipt of KRT prior to the index
# date. It passes an argument krt_source which can test the primary care KRT codes or
# the combined (primary and secondary) care KRT codes

fn_krt_inex_criteria <- function(
  arrow_data,
  krt_source = c("primary", "combined"),
  rounding_threshold = 6,
  collect_and_describe = FALSE,
  describe_name = "",
  suffix = ""
) {
  require(arrow)
  require(dplyr)

  krt_source <- match.arg(krt_source) # breaks function if invalid krt_source passed

  # apply krt filter using either primary or combined (primary+secondary) care codes

  arrow_data_krt_inex_applied <- if (krt_source == "primary") {
    arrow_data |> filter(!inex_krt_bin_has_primary_care_krt_code)
  } else {
    arrow_data |> filter(!inex_krt_bin_has_combined_krt_code)
  }

  # count and print totals before and after filter and n excluded

  n_before <- arrow_data |>
    summarise(n = n()) |>
    collect() |>
    pull(n)
  n_after <- arrow_data_krt_inex_applied |>
    summarise(n = n()) |>
    collect() |>
    pull(n)

  message("\nKRT exclusion criteria - code source: ", krt_source, " (rounded):")
  message(
    "n before KRT filter: ",
    fn_roundmid_any(n_before, to = rounding_threshold)
  )
  message(
    "Excluded as evidence of prior KRT: ",
    fn_roundmid_any(n_before - n_after, to = rounding_threshold)
  )

  # optionally collect and describe data

  if (collect_and_describe) {
    arrow_data_krt_inex_applied <- arrow_data_krt_inex_applied |>
      collect() |>
      data.table::as.data.table()

    describe_data(
      data = arrow_data_krt_inex_applied,
      name = describe_name,
      suffix = suffix
    )
  }

  return(arrow_data_krt_inex_applied)
}
