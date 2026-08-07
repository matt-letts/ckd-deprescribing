##########################################################################
# This script contains two functions, used to analyse the meds prior to
# the index date
#
# fn_flag_chronic_meds() - gives an 'is_chronic_[def]' flag to each
#   medication if it meets criteria to be chronically prescribed, based on
#   a chronic prescription [def] from config.r.
#
# fn_estimate_med_intervals() - estimates the typical prescribing interval
#   (7/14/28/56/84 days) per patient/substance.
##########################################################################

##########################################################################
# fn_flag_chronic_meds()
#
# Groups at patient/bnf_substance_code level. This means that:
#  - combination meds are counted separately
#  - >1 dose of a medicine (e.g. levothyroxine 50mcg+25mcg) counts once
#
# Arguments:
#   data : one row per prescription. Must contain
#     patient_id, bnf_substance_code, med_date.
#   config : list with named elements:
#      min_prescriptions  — minimum number of prescriptions required
#      lookback_days — window in days before index
#      allowable_index_gap — max days between last prescription and index
#      prior_fill_gap — min days between first and last prescription
#      per_half — if TRUE, requires >=1 prescription in each half of the
#                 lookback window
#   index_date : index_date
#   config_name : optional string; if provided, the is_chronic flag is
#                 renamed to is_chronic_{config_name} in the output
#
# Returns:
#   Tibble with one row per (patient_id, bnf_substance_code). Contains
#   is_chronic_[def] flag plus intermediate columns for inspection
##########################################################################

fn_flag_chronic_meds <- function(
  data,
  config,
  index_date,
  config_name = NULL
) {
  window_start <- index_date - config$lookback_days
  halfway_point <- index_date - (config$lookback_days / 2)

  result <- data |>
    filter(
      med_date >= window_start,
      med_date <= index_date
    ) |>
    group_by(patient_id, bnf_substance_code) |>
    summarise(
      n_scripts = n(),
      days_before_index_most_recent_prescription = as.integer(
        index_date - max(med_date)
      ),
      in_window_days_spanning_first_and_last = as.integer(
        max(med_date) - min(med_date)
      ),
      has_recent_half = any(med_date >= halfway_point),
      has_earlier_half = any(med_date < halfway_point),
      .groups = "drop"
    ) |>
    mutate(
      is_chronic = n_scripts >= config$min_prescriptions &
        days_before_index_most_recent_prescription <=
          config$allowable_index_gap &
        in_window_days_spanning_first_and_last >= config$prior_fill_gap &
        (!config$per_half | (has_recent_half & has_earlier_half))
    )

  # rename is_chronic to flag which definition used
  if (!is.null(config_name)) {
    names(result)[names(result) == "is_chronic"] <- paste0(
      "is_chronic_",
      config_name
    )
  }

  return(result)
}

##########################################################################
# fn_estimate_med_intervals()
#
# Arguments:
#   data : one row per prescription. Must contain
#     patient_id, bnf_substance_code, med_date.
#   index_date : index_date
#
# Returns:
#   Tibble with one row per (patient_id, bnf_substance_code). Contains:
#   - estimated_gap_days — mean gap between consecutive prescriptions
#     (span between first and last prescription / (n - 1)); NA when only
#     one prescription of that substance is present, since no gap is
#     observable.
#   - estimated_gap_bucket — estimated_gap_days snapped to the nearest of
#     7/14/28/56/84. NA when estimated_gap_days is NA.
##########################################################################

fn_estimate_med_intervals <- function(
  data,
  index_date
) {
  result <- data |>
    filter(med_date <= index_date) |>
    group_by(patient_id, bnf_substance_code) |>
    summarise(
      n_scripts = n(),
      days_spanning_first_and_last = as.integer(max(med_date) - min(med_date)),
      .groups = "drop"
    ) |>
    mutate(
      estimated_gap_days = if_else(
        n_scripts >= 2,
        days_spanning_first_and_last / (n_scripts - 1),
        NA_real_
      ),
      estimated_gap_bucket = case_when(
        is.na(estimated_gap_days) ~ NA_real_,
        estimated_gap_days <= 10.5 ~ 7,
        estimated_gap_days <= 21 ~ 14,
        estimated_gap_days <= 42 ~ 28,
        estimated_gap_days <= 70 ~ 56,
        .default = 84
      )
    )

  return(result)
}
