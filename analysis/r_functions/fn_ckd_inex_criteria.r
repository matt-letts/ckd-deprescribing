##########################################################################
# This script defines three functions used to apply inclusion and
# exclusion criteria related to CKD and KRT
#   fn_egfr_ckdepi2009() - calculates eGFR from serum creatinine
#   fn_ckd_inex_criteria() - applies CKD stage 4/5 inclusion criteria
#   fn_krt_inex_criteria() - applies KRT exclusion criteria
##########################################################################

##########################################################################
# fn_egfr_ckdepi2009()
#
# Calculates eGFR (mL/min/1.73m²) from serum creatinine (umol/L), age,
# and sex using the CKD-EPI 2009 equation without race coefficient, as
# recommended by UKKA/NICE.
#
# Reference:
# https://www.niddk.nih.gov/research-funding/research-programs/
# kidney-clinical-research-epidemiology/laboratory/
# glomerular-filtration-rate-equations/adults/previous
##########################################################################

fn_egfr_ckdepi2009 <- function(
  creat_umol,
  age,
  sex
) {
  kappa <- ifelse(sex == "female", 61.9, 79.6)
  alpha <- ifelse(sex == "female", -0.329, -0.411)
  female_multiplier <- ifelse(sex == "female", 1.018, 1.0)

  ratio <- creat_umol / kappa

  141 *
    pmin(ratio, 1)^alpha *
    pmax(ratio, 1)^-1.209 *
    (0.993^age) *
    female_multiplier
}


##########################################################################
# fn_ckd_inex_criteria()
#
# Applies CKD stage 4/5 inclusion criteria and adds eGFR-derived
# staging variables. Steps:
#
# 1. For patients with 2+ serum creatinine measurements, calculate eGFR
#    at each measurement date and classify into G4, G5, or G4/G5.
#    Age at the time of each measurement is used (not age at index date).
# 2. Join CKD stages back to the full dataset; patients without
#    2 creatinine measurements default to FALSE / "not G4/G5".
# 3. Include patients with either a CKD 4/5 code OR eGFR-derived CKD 4/5.
# 4. Recalculate eGFR for all included patients post-filter (captures
#    those included via CKD code who may only have one SCr value).
# 5. Output counts before and after filtering.
##########################################################################

fn_ckd_inex_criteria <- function(
  arrow_data,
  index_date
) {
  require(arrow)
  require(dplyr)

  # 1. Calculate eGFR and classify CKD stage for patients with 2+ SCr values
  ckd_flags <- arrow_data |>
    filter(inex_ckd_bin_has_two_scr) |>
    mutate(
      inex_num_egfr_1 = fn_egfr_ckdepi2009(
        creat_umol = inex_ckd_num_scr_value_1,
        age = inex_dem_num_age +
          (as.integer(inex_ckd_date_scr_date_1) - as.integer(index_date)) /
            365.25,
        sex = inex_dem_cat_sex
      ),
      inex_num_egfr_2 = fn_egfr_ckdepi2009(
        creat_umol = inex_ckd_num_scr_value_2,
        age = inex_dem_num_age +
          (as.integer(inex_ckd_date_scr_date_2) - as.integer(index_date)) /
            365.25,
        sex = inex_dem_cat_sex
      ),
      inex_cat_ckd_stage_by_scr = case_when(
        (inex_num_egfr_1 < 15) & (inex_num_egfr_2 < 15) ~ "G5",
        (inex_num_egfr_1 >= 15) &
          (inex_num_egfr_1 < 30) &
          (inex_num_egfr_2 >= 15) &
          (inex_num_egfr_2 < 30) ~ "G4",
        (inex_num_egfr_1 >= 15) &
          (inex_num_egfr_1 < 30) &
          (inex_num_egfr_2 < 15) ~ "G4/G5",
        (inex_num_egfr_1 < 15) &
          (inex_num_egfr_2 >= 15) &
          (inex_num_egfr_2 < 30) ~ "G4/G5",
        TRUE ~ "not G4/G5"
      ),
      inex_bin_has_ckd45_by_scr = inex_cat_ckd_stage_by_scr != "not G4/G5"
    ) |>
    select(patient_id, inex_bin_has_ckd45_by_scr, inex_cat_ckd_stage_by_scr)

  # 2. Join CKD flags back to the full dataset, filling NAs for those
  #    without 2 SCr measurements
  arrow_data <- arrow_data |>
    left_join(ckd_flags, by = "patient_id") |>
    mutate(
      inex_bin_has_ckd45_by_scr = ifelse(
        is.na(inex_bin_has_ckd45_by_scr),
        FALSE,
        inex_bin_has_ckd45_by_scr
      ),
      inex_cat_ckd_stage_by_scr = ifelse(
        is.na(inex_cat_ckd_stage_by_scr),
        "not G4/G5",
        inex_cat_ckd_stage_by_scr
      )
    )

  # 3. Include patients with a CKD 4/5 code OR eGFR-derived CKD 4/5
  arrow_data_ckd_inex_applied <- arrow_data |>
    filter(inex_ckd_bin_has_ckd45_code | inex_bin_has_ckd45_by_scr) |>

    # 4. Recalculate eGFR post-filter for all included patients
    mutate(
      inex_num_egfr_1 = fn_egfr_ckdepi2009(
        creat_umol = inex_ckd_num_scr_value_1,
        age = inex_dem_num_age +
          (as.integer(inex_ckd_date_scr_date_1) - as.integer(index_date)) /
            365.25,
        sex = inex_dem_cat_sex
      ),
      inex_num_egfr_2 = fn_egfr_ckdepi2009(
        creat_umol = inex_ckd_num_scr_value_2,
        age = inex_dem_num_age +
          (as.integer(inex_ckd_date_scr_date_2) - as.integer(index_date)) /
            365.25,
        sex = inex_dem_cat_sex
      )
    )

  # 5. Output counts
  n_before <- arrow_data |> summarise(n = n()) |> collect() |> pull(n)
  n_after <- arrow_data_ckd_inex_applied |>
    summarise(n = n()) |>
    collect() |>
    pull(n)

  message("\nCKD 4/5 inclusion criteria:")
  message("Before: ", n_before)
  message("Excluded (no evidence of CKD 4/5): ", n_before - n_after)

  return(arrow_data_ckd_inex_applied)
}


##########################################################################
# fn_krt_inex_criteria()
#
# Excludes patients with evidence of kidney replacement therapy (KRT)
# prior to index date. The krt_source argument controls whether exclusion
# is based on primary care codes only ("primary") or primary and
# secondary care codes combined ("combined").
##########################################################################

fn_krt_inex_criteria <- function(
  arrow_data,
  krt_source = c("primary", "combined")
) {
  require(arrow)
  require(dplyr)

  krt_source <- match.arg(krt_source)

  arrow_data_krt_inex_applied <- if (krt_source == "primary") {
    arrow_data |> filter(!inex_krt_bin_has_primary_care_krt_code)
  } else {
    arrow_data |> filter(!inex_krt_bin_has_combined_krt_code)
  }

  n_before <- arrow_data |> summarise(n = n()) |> collect() |> pull(n)
  n_after <- arrow_data_krt_inex_applied |>
    summarise(n = n()) |>
    collect() |>
    pull(n)

  message("\nKRT exclusion criteria - source: ", krt_source, ":")
  message("Before: ", n_before)
  message("Excluded (prior KRT): ", n_before - n_after)

  return(arrow_data_krt_inex_applied)
}
