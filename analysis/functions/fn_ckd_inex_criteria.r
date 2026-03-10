kappa <- arrow_data |>
  ifelse(inex_dem_cat_sex=="female", 61.9, 79.6)
alpha <- arrow_data |> 
  ifelse(inex_dem_cat_sex=="female", -0.329, -0.411)
female_multiplier |>
  ifelse(inex_dem_cat_sex=="female", 1.018, 1.0)

egfr_ckdepi2009 <- function(
  creat_umol, age
): {
  ratio = creat_umol / kappa
    return (
      round(
        141
        * (minimum_of(ratio, 1) ** alpha) 
        * (maximum_of(ratio, 1) ** -1.209)
        * (0.993 ** age)
        * female_multiplier)
      )
}


fn_ckd_inex_criteria <- function(
  arrow_data,
  rounding_threshold = 6,
  collect_and_describe = FALSE,
  describe_name = "",
  suffix = ""
) {
  require(arrow)
  require(dplyr)

  # The main steps that this function performs:
  # calculate those with CKD 4/5 based on SCr measurements and include them
  # Identify those with CKD 4/5 based on codes and include them

  #### START HERE NEXT TIME ####


  # Convert creatinine (µmol/L) → eGFR (2009 CKD-EPI, no race - as recommended by UKKA/NICE)
  # https://www.niddk.nih.gov/research-funding/research-programs/kidney-clinical-research-epidemiology/laboratory/glomerular-filtration-rate-equations/adults/previous
     

  ### hmm age in the eGFR equation should actually be the age that the creatinine measurement was taken.
  # I know the age at the index date, and the date of the scr measurement inex_ckd_date_scr_date_1 and 2). How to work this out?
ckd_scr <- arrow_data |>
  filter(inex_ckd_bin_has_two_scr) |> 
  mutate(eGFR1 = egfr_ckdepi2009(
    creat_umol = inex_ckd_num_scr_value_1,
    age = inex_dem_num_age
  ))
  ckd_scr <- arrow_data |>
  mutate(eGFR2 = egfr_ckdepi2009(
    creat_umol = inex_ckd_num_scr_value_2,
    age = inex_dem_num_age
  ))

  # Count the numbers that fail each qa criteria respectively
  counts <- arrow_data |>
    summarise(
      n_has_ckd45_code = sum....
      n_ckd45_by_scr_measurements = sum()
    ) |>
    collect()

  # Print exclusion counts rounded for disclosure control
  message("Demographic exclusions:")
  message(
    "Does not have CKD4/5: ",
    fn_roundmid_any(counts$.... to = rounding_threshold)
  )
 

  # Apply demographic filters lazily
  arrow_data_ckd_inex_applied <- arrow_data %>%
    filter(
      has_ckd45_codes,
      has_ckd45_by_scr_measurements
    )

  # load dataset as R data.table object if collect_and_describe = TRUE
  if (collect_and_describe) {
    arrow_data_ckd_inex_applied <- arrow_data_ckd_inex_applied %>%
      collect() %>%
      data.table::as.data.table()

    describe_data(
      data = arrow_data_ckd_inex_applied,
      name = describe_name,
      suffix = suffix
    )
  }

  return(arrow_data_ckd_inex_applied)
  }



## need to have a think about the next section:
# def include those with ckd 45 code
# then include those with two serum creatinine measurements
# n_no_ckd45_code = sum(!inex_ckd_bin_has_ckd45_code, na.rm = TRUE)
# n_lacking_2_creatinines = sum()
# n_less_than_5_meds = sum()



####### COPIED FROM CLAUDE - IS THIS ACCURATE? #######

# CKD-EPI 2009 eGFR equation (no race coefficient, as recommended by UKKA/NICE)
# Reference: https://www.niddk.nih.gov/research-funding/research-programs/kidney-clinical-research-epidemiology/laboratory/glomerular-filtration-rate-equations/adults/previous
# Creatinine input in µmol/L (converted internally to mg/dL: 1 µmol/L = 0.0113 mg/dL)

egfr_ckdepi2009 <- function(
  creat_umol,
   age, 
   sex
) {
  
  kappa <- ifelse(sex == "female", 61.9, 79.6)
  alpha <- ifelse(sex == "female", -0.329, -0.411)
  female_multiplier <- ifelse(sex == "female", 1.018,  1.0)

  ratio <- creat_umol / kappa

  round(
    141
    * pmin(ratio, 1) ^ alpha
    * pmax(ratio, 1) ^ -1.209
    * (0.993 ^ age)
    * female_multiplier
  )
}


fn_ckd_inex_criteria <- function(
  arrow_data,
  rounding_threshold = 6,
  collect_and_describe = FALSE,
  describe_name = "",
  suffix = ""
) {
  require(arrow)
  require(dplyr)
  require(lubridate)

  # ── Age at SCr measurement ────────────────────────────────────────────────
  # inex_dem_num_age     : age (years) at index date
  # inex_dem_date_index  : index date
  # inex_ckd_date_scr_1 / _2 : dates of the two SCr measurements
  #
  # Age at SCr ≈ age_at_index + (scr_date - index_date) / 365.25
  # This keeps the calculation lazy-compatible with Arrow.

  # ── eGFR calculation for individuals with two valid SCr measurements ──────
  ckd_scr <- arrow_data |>
    filter(inex_ckd_bin_has_two_scr) |>
    mutate(
      # Age (fractional years) at each SCr measurement
      age_at_scr_1 = inex_dem_num_age +
        as.numeric(
          difftime(inex_ckd_date_scr_1, inex_dem_date_index, units = "days")
        ) / 365.25,
      age_at_scr_2 = inex_dem_num_age +
        as.numeric(
          difftime(inex_ckd_date_scr_2, inex_dem_date_index, units = "days")
        ) / 365.25,

      # eGFR at each measurement
      egfr_1 = egfr_ckdepi2009(
        creat_umol = inex_ckd_num_scr_value_1,
        age        = age_at_scr_1,
        sex        = inex_dem_cat_sex
      ),
      egfr_2 = egfr_ckdepi2009(
        creat_umol = inex_ckd_num_scr_value_2,
        age        = age_at_scr_2,
        sex        = inex_dem_cat_sex
      ),

      # CKD 4/5 requires eGFR < 30 on BOTH measurements (confirms chronicity)
      has_ckd45_by_scr = (egfr_1 < 30) & (egfr_2 < 30)
    )

  # ── Join SCr-derived flag back onto the full dataset ──────────────────────
  # Individuals without two SCr measurements get has_ckd45_by_scr = FALSE
  arrow_data <- arrow_data |>
    left_join(
      ckd_scr |> select(patient_id, has_ckd45_by_scr),
      by = "patient_id"
    ) |>
    mutate(
      has_ckd45_by_scr = ifelse(is.na(has_ckd45_by_scr), FALSE, has_ckd45_by_scr)
    )

  # ── Inclusion flag ────────────────────────────────────────────────────────
  arrow_data <- arrow_data |>
    mutate(
      include_ckd45 = inex_ckd_bin_has_ckd45_code | has_ckd45_by_scr
    )

  # ── Counts for disclosure-controlled reporting ────────────────────────────
  counts <- arrow_data |>
    summarise(
      n_total                   = n(),
      n_has_ckd45_code          = sum(inex_ckd_bin_has_ckd45_code, na.rm = TRUE),
      n_ckd45_by_scr            = sum(has_ckd45_by_scr,            na.rm = TRUE),
      n_ckd45_by_either         = sum(include_ckd45,                na.rm = TRUE),
      n_excluded_no_ckd45       = sum(!include_ckd45,               na.rm = TRUE)
    ) |>
    collect()

  # ── Print rounded counts ──────────────────────────────────────────────────
  message("CKD 4/5 inclusion criteria:")
  message(
    "  Total individuals before inclusion filter : ",
    fn_roundmid_any(counts$n_total,             to = rounding_threshold)
  )
  message(
    "  Included via CKD 4/5 code                : ",
    fn_roundmid_any(counts$n_has_ckd45_code,    to = rounding_threshold)
  )
  message(
    "  Included via SCr eGFR < 30 (both values) : ",
    fn_roundmid_any(counts$n_ckd45_by_scr,      to = rounding_threshold)
  )
  message(
    "  Included via either criterion             : ",
    fn_roundmid_any(counts$n_ckd45_by_either,   to = rounding_threshold)
  )
  message(
    "  EXCLUDED (no CKD 4/5 evidence)            : ",
    fn_roundmid_any(counts$n_excluded_no_ckd45, to = rounding_threshold)
  )

  # ── Apply inclusion filter ────────────────────────────────────────────────
  arrow_data_ckd_inex_applied <- arrow_data |>
    filter(include_ckd45)

  # ── Optionally collect and describe ───────────────────────────────────────
  if (collect_and_describe) {
    arrow_data_ckd_inex_applied <- arrow_data_ckd_inex_applied |>
      collect() |>
      data.table::as.data.table()

    describe_data(
      data   = arrow_data_ckd_inex_applied,
      name   = describe_name,
      suffix = suffix
    )
  }

  return(arrow_data_ckd_inex_applied)
}