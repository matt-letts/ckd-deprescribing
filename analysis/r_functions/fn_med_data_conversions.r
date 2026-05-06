##########################################################################################
# Functions for joining patient medication data to pre-built lookup tables

# Lookup tables and their build functions live in:
# local_processing/medication_lookup_tables/
##########################################################################################

#######################################################################################
# fn_write_unmapped_codes() - diagnostics
#######################################################################################
# Counts unmapped codes, applies midpoint-6 rounding for disclosure
# control, and writes the result to a CSV in output/data_descriptions/
#
# Arguments:
#   data : data frame containing the codes to count (e.g. filtered patient_bnf)
#   code_col : name of the column containing the code to count
#   project_stage : string label used to name the output file
#   file_suffix : suffix for the output filename (e.g. "dmd_not_in_lookup")
#######################################################################################

fn_write_unmapped_codes <- function(
  data,
  code_col,
  project_stage,
  file_suffix
) {
  result <- data |>
    count(.data[[code_col]], name = "n_occurrences") |>
    arrange(desc(n_occurrences)) |>
    mutate(
      n_occurrences_midpoint6 = if_else(
        n_occurrences <= 7,
        NA_real_,
        fn_roundmid_any(n_occurrences)
      )
    ) |>
    select(all_of(c(code_col, "n_occurrences_midpoint6")))

  write_csv(
    result,
    here::here(
      "output",
      "data_descriptions",
      paste0(project_stage, "-", file_suffix, ".csv")
    )
  )

  return(nrow(result))
}


#######################################################################################
# fn_dmd_to_bnf()
#######################################################################################
# Converts wide-format patient medication data with AMP/VMP dm+d codes into
# BNF substance level classifications using the mapping from fn_build_dmd_bnf_lookup()
#
# ENSURE THOSE WITH ZERO MEDICINES RECORDED ARE REMOVED FIRST
#
# Arguments:
#   patient_data : wide-format data frame with med_dmd_code_* and med_date_*
#   project_stage : string label used to name diagnostic output files
#   dmd_lookup : dmd_lookup from fn_build_dmd_bnf_lookup()
#   output : "wide" or "long"
#   unmapped_action : "keep" (retain unmapped) or "drop" (remove)
#######################################################################################

fn_dmd_to_bnf <- function(
  patient_data,
  project_stage,
  dmd_lookup,
  output = c("long", "wide"),
  unmapped_action = c("keep", "drop")
) {
  require(tidyverse)

  message("Running fn_dmd_to_bnf")

  output <- match.arg(output)
  unmapped_action <- match.arg(unmapped_action)

  if (!is.data.frame(patient_data)) {
    stop("patient_data must be a data frame - collect() arrow data first")
  }

  dmd_cols <- grep("^med_dmd_code_\\d+$", names(patient_data), value = TRUE)
  date_cols <- grep("^med_date_\\d+$", names(patient_data), value = TRUE)

  if (length(dmd_cols) == 0) {
    stop("No columns matching `med_dmd_code_*` found in patient data")
  }

  if (length(dmd_cols) != length(date_cols)) {
    stop(sprintf(
      "Number of med_dmd_code_* columns (%d) does not match med_date_* columns (%d)",
      length(dmd_cols),
      length(date_cols)
    ))
  }

  has_med_num_count <- "med_num_count" %in% names(patient_data)
  patient_level_cols <- c("patient_id", if (has_med_num_count) "med_num_count")

  message(sprintf(
    "--- Data valid for conversion: %d rows | %d med_dmd_code_* columns",
    nrow(patient_data),
    length(dmd_cols)
  ))

  # Reshape to long format
  message("--- Reshape data to long format")

  patient_long <- patient_data |>
    pivot_longer(
      cols = matches("^med_dmd_code_|^med_date_"),
      names_to = c(".value", "med_index"),
      names_pattern = "^(med_dmd_code|med_date)_(\\d+)$"
    ) |>
    rename(
      dmd_code = med_dmd_code,
      med_date = med_date
    ) |>
    mutate(med_index = as.integer(med_index)) |>
    filter(!is.na(dmd_code), dmd_code != "", dmd_code != "NA")

  message(sprintf(
    "--- %d patients (with 1+ medicine) | %d medication rows",
    n_distinct(patient_long$patient_id),
    nrow(patient_long)
  ))

  # Join to BNF lookup
  # safety check - should be ok as dmd_lookup build included distinct() filter
  if (any(duplicated(dmd_lookup$dmd_code))) {
    stop("dmd_lookup contains dmd_code duplicates, fn will break")
  }

  # bnf_imputed flag is resolved in fn_build_dmd_bnf_lookup() and joins here automatically
  patient_bnf <- patient_long |>
    left_join(dmd_lookup, by = "dmd_code")

  # Capture dm+d codes present in patient data but absent from the lookup
  n_not_in_lookup <- fn_write_unmapped_codes(
    data = filter(patient_bnf, is.na(in_lookup)),
    code_col = "dmd_code",
    project_stage = project_stage,
    file_suffix = "dmd_not_in_lookup"
  )
  message(sprintf(
    "--- %d dm+d codes not in NHSBSA lookup; *-dmd_not_in_lookup.csv",
    n_not_in_lookup
  ))

  # Capture codes still unmapped to BNF after imputation
  fn_write_unmapped_codes(
    data = filter(patient_bnf, is.na(bnf_substance_code)),
    code_col = "dmd_code",
    project_stage = project_stage,
    file_suffix = "dmd_unmapped_to_bnf"
  )

  # Handle remaining unmapped data
  n_unmapped <- sum(is.na(patient_bnf$bnf_substance_code))
  pct_unmapped <- 100 * n_unmapped / nrow(patient_bnf)

  if (n_unmapped > 0) {
    message(sprintf(
      "--- %d records (%.1f%%) still missing BNF substance after processing *-dmd_unmapped_to_bnf.csv",
      n_unmapped,
      pct_unmapped
    ))

    if (unmapped_action == "drop") {
      patient_bnf <- patient_bnf |> filter(!is.na(bnf_substance_code))
      message("--- Unmapped records dropped")
    } else {
      message("--- Unmapped records retained as NAs")
    }
  }

  # Drop columns not needed in the output
  patient_bnf <- patient_bnf |>
    select(-vtm_code, -vtm_name, -in_lookup, -bnf_code)

  # Patient-level route diagnostic (only if route classification was run on lookup)
  if ("route_cat" %in% names(patient_bnf)) {
    route_summary <- patient_bnf |>
      count(route_cat, route_uncertain) |>
      mutate(n_midpoint6 = if_else(n <= 7, NA_real_, fn_roundmid_any(n))) |>
      select(route_cat, route_uncertain, n_midpoint6)

    write_csv(
      route_summary,
      here::here(
        "output",
        "data_descriptions",
        paste0(project_stage, "-route_classification_patient_summary.csv")
      )
    )
  }

  # Output
  if (output == "long") {
    message("--- Returning long format")
    return(patient_bnf)
  } else {
    message("--- Returning wide format")

    wide <- patient_bnf |>
      select(
        all_of(patient_level_cols),
        med_index,
        dmd_code,
        bnf_substance_code,
        med_date,
        bnf_imputed
      ) |>
      pivot_wider(
        names_from = med_index,
        values_from = c(
          dmd_code,
          bnf_substance_code,
          med_date,
          bnf_imputed
        ),
        names_glue = "med_{.value}_{med_index}"
      )

    return(wide)
  }
}


#######################################################################################
# fn_add_bnf_names()
#######################################################################################
# Joins BNF hierarchy names (chapter, section, paragraph, subparagraph, substance)
# onto a dataset containing a bnf_substance_code column (i.e. the "long" output
# from fn_dmd_to_bnf())
#
# ENSURE THOSE WITH ZERO MEDICINES RECORDED ARE REMOVED FIRST
#
# Arguments:
#   patient_data : data frame containing a bnf_substance_code column
#   bnf_hierarchy : lookup from fn_build_bnf_hierarchy()
#   project_stage : string label used to name diagnostic output files
#   unmapped_action : "keep" (retain NAs) or "drop" (remove NA rows)
#######################################################################################

fn_add_bnf_names <- function(
  patient_data,
  bnf_hierarchy,
  project_stage,
  unmapped_action = c("keep", "drop")
) {
  require(tidyverse)

  unmapped_action <- match.arg(unmapped_action)

  message("Running fn_add_bnf_names")

  if (!"bnf_substance_code" %in% names(patient_data)) {
    stop("patient_data must contain a bnf_substance_code column")
  }

  # safety check - should be ok as bnf_hierarchy build included distinct() filter
  if (any(duplicated(bnf_hierarchy$bnf_substance_code))) {
    stop("bnf_hierarchy contains bnf_substance_code duplicates, fn will break")
  }

  joined_data <- patient_data |>
    left_join(bnf_hierarchy, by = "bnf_substance_code")

  unmatched_codes <- joined_data |>
    filter(
      !is.na(bnf_substance_code),
      is.na(bnf_substance_name)
    )

  n_bnf_code_not_matched <- nrow(unmatched_codes)

  if (n_bnf_code_not_matched > 0) {
    # Handle remaining unmapped data
    pct_unmapped <- 100 * n_bnf_code_not_matched / nrow(joined_data)
    message(sprintf(
      "--- %d rows (%.1f%%) have a bnf_substance_code in data but absent from hierarchy *-bnf_unmapped_to_bnf_hierarchy.csv",
      n_bnf_code_not_matched,
      pct_unmapped
    ))

    fn_write_unmapped_codes(
      data = unmatched_codes,
      code_col = "bnf_substance_code",
      project_stage = project_stage,
      file_suffix = "bnf_unmapped_to_bnf_hierarchy"
    )

    if (unmapped_action == "drop") {
      joined_data <- joined_data |> filter(!is.na(bnf_substance_name))
      message("--- Unmapped records dropped")
    } else {
      message("--- Unmapped records retained as NAs")
    }
  } else {
    message(
      "--- All patient bnf_substance_codes successfully mapped to hierarchy"
    )
  }

  return(joined_data)
}
