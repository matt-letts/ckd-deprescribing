##########################################################################
# fn_flag_chronic_meds()
#
# Gives an 'is_chronic_[def]' flag to each medication if meets criteria to
# be defined as chronically prescribed based on chronic prescription [def]
#
# Groups at patient/bnf_substance_code level. This means that:
#  - combination meds are counted as one
#  - >1 dose of a medicine (e.g. levothyroxine 50mcg+25mcg) is one
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
#   is_chronic (or is_chronic_{config_name}) flag plus intermediate
#   columns (n_scripts, days_before_index_most_recent_prescription,
#   in_window_days_spanning_first_and_last, has_recent_half,
#   has_earlier_half) for inspection.
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

  if (!is.null(config_name)) {
    names(result)[names(result) == "is_chronic"] <- paste0(
      "is_chronic_",
      config_name
    )
  }

  return(result)
}
