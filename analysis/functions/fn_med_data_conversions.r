#######################################################################################
# fn_build_dmd_bnf_lookup()
#######################################################################################
# Reads the NHSBSA BNF/SNOMED mapping file downloadable from:
# https://www.nhsbsa.nhs.uk/prescription-data/understanding-our-data/bnf-snomed-mapping
# Currently using January 2026 version, but this can be updated by changing file,
# and mapping path below.
#
# Returns a named list with two lookups:
#   dmd_lookup : AMP/VMP --> BNF/VTM mapping, with in_lookup flag
#   vtm_lookup : VTM --> most common BNF substance, for imputation when missing
#######################################################################################

fn_build_dmd_bnf_lookup <- function(
  dmd_bnf_mapping_path = here::here("docs", "bnf_dmd_mapping_20260324.xlsx")
) {
  require(readxl)
  require(tidyverse)

  message("Running fn_build_dmd_bnf_lookup")
  message("--- Reading in NHSBSA BNF/SNOMED mapping file")

  if (!file.exists(dmd_bnf_mapping_path)) {
    stop(sprintf("NHSBSA mapping file not found at: %s", dmd_bnf_mapping_path))
  }

  snomed_bnf_raw <- readxl::read_xlsx(dmd_bnf_mapping_path, sheet = 1)

  # Check expected columns are present and spelled as expected
  expected_cols <- c(
    "SNOMED Code",
    "BNF Code",
    "Presentation / Pack Level",
    "VTM",
    "VTM Name"
  )
  missing_cols <- setdiff(expected_cols, names(snomed_bnf_raw))
  if (length(missing_cols) > 0) {
    stop(sprintf(
      "Expected columns not found in mapping file: %s\nActual columns: %s",
      paste(missing_cols, collapse = ", "),
      paste(names(snomed_bnf_raw), collapse = ", ")
    ))
  }

  # Clean and process the raw mapping file
  # Keep only presentation-level rows (VMP and AMP), excluding pack-level
  # rows (VMPP and AMPP), to reflect codes present within openSAFELY-TPP
  dmd_lookup <- snomed_bnf_raw |>
    rename(
      dmd_code = `SNOMED Code`,
      bnf_code = `BNF Code`,
      pres_pack = `Presentation / Pack Level`,
      vtm_code = `VTM`,
      vtm_name = `VTM Name`
    ) |>
    filter(pres_pack == "Presentation") |>
    mutate(
      dmd_code = as.character(dmd_code),
      vtm_code = as.character(vtm_code),
      bnf_code = as.character(bnf_code),
      vtm_name = as.character(vtm_name),
      # First 9 characters of BNF code = substance
      bnf_substance_code = substr(bnf_code, 1, 9),
      # Flag for identifying dm+d codes in patient data absent from lookup
      in_lookup = TRUE
    ) |>
    distinct(dmd_code, .keep_all = TRUE) |>
    select(
      dmd_code,
      vtm_code,
      bnf_code,
      vtm_name,
      bnf_substance_code,
      in_lookup
    )

  message(sprintf(
    "--- DMD to BNF lookup built: %d dm+d codes | %.1f%% with BNF | %.1f%% with VTM",
    nrow(dmd_lookup),
    100 * mean(!is.na(dmd_lookup$bnf_substance_code)),
    100 * mean(!is.na(dmd_lookup$vtm_code))
  ))

  # Build VTM imputation lookup:
  # For each VTM, find the most common BNF substance mapping across all
  # its associated AMP/VMP codes - used to impute missing BNF substances
  vtm_lookup <- dmd_lookup |>
    filter(!is.na(vtm_code), !is.na(bnf_substance_code)) |>
    count(vtm_code, bnf_substance_code, sort = TRUE) |>
    group_by(vtm_code) |>
    slice_max(n, n = 1, with_ties = FALSE) |>
    ungroup() |>
    select(vtm_code, bnf_substance_imputed = bnf_substance_code)

  message(sprintf(
    "--- VTM imputation lookup built: %d VTM codes with matching BNF substance codes",
    nrow(vtm_lookup)
  ))

  return(list(
    dmd_lookup = dmd_lookup,
    vtm_lookup = vtm_lookup
  ))
}


#######################################################################################
# fn_build_bnf_hierarchy()
#######################################################################################
# Reads the NHSBSA BNF Code Information file, downloadable from:
# https://opendata.nhsbsa.net/dataset/bnf-code-information-current-year
# Returns a clean lookup of BNF substance codes to their readable names,
# plus higher-level hierarchy names (chapter, section, paragraph, subparagraph).
# Using February 2026 version 90.
#######################################################################################

fn_build_bnf_hierarchy <- function(
  bnf_hierarchy_path = here::here("docs", "bnf_hierarchy_v90_202602.csv")
) {
  require(tidyverse)

  message("Running fn_build_bnf_hierarchy")
  message("--- Reading in NHSBSA BNF code information file")

  if (!file.exists(bnf_hierarchy_path)) {
    stop(sprintf(
      "NHSBSA BNF hierarchy file not found at: %s",
      bnf_hierarchy_path
    ))
  }

  bnf_raw <- read_csv(bnf_hierarchy_path, show_col_types = FALSE)

  expected_cols <- c(
    "BNF_CHAPTER",
    "BNF_CHAPTER_CODE",
    "BNF_SECTION",
    "BNF_SECTION_CODE",
    "BNF_PARAGRAPH",
    "BNF_PARAGRAPH_CODE",
    "BNF_SUBPARAGRAPH",
    "BNF_SUBPARAGRAPH_CODE",
    "BNF_CHEMICAL_SUBSTANCE",
    "BNF_CHEMICAL_SUBSTANCE_CODE"
  )
  missing_cols <- setdiff(expected_cols, names(bnf_raw))
  if (length(missing_cols) > 0) {
    stop(sprintf(
      "Expected columns not found in BNF hierarchy file: %s\nActual columns: %s",
      paste(missing_cols, collapse = ", "),
      paste(names(bnf_raw), collapse = ", ")
    ))
  }

  bnf_hierarchy <- bnf_raw |>
    rename(
      bnf_chapter_name = BNF_CHAPTER,
      bnf_chapter_code = BNF_CHAPTER_CODE,
      bnf_section_name = BNF_SECTION,
      bnf_section_code = BNF_SECTION_CODE,
      bnf_paragraph_name = BNF_PARAGRAPH,
      bnf_paragraph_code = BNF_PARAGRAPH_CODE,
      bnf_subparagraph_name = BNF_SUBPARAGRAPH,
      bnf_subparagraph_code = BNF_SUBPARAGRAPH_CODE,
      bnf_substance_name = BNF_CHEMICAL_SUBSTANCE,
      bnf_substance_code = BNF_CHEMICAL_SUBSTANCE_CODE
    ) |>
    mutate(across(everything(), as.character)) |>
    distinct(bnf_substance_code, .keep_all = TRUE) |>
    select(
      bnf_chapter_name,
      bnf_chapter_code,
      bnf_section_name,
      bnf_section_code,
      bnf_paragraph_name,
      bnf_paragraph_code,
      bnf_subparagraph_name,
      bnf_subparagraph_code,
      bnf_substance_name,
      bnf_substance_code
    )

  message(sprintf(
    "--- BNF hierarchy built: %d distinct BNF substance codes",
    nrow(bnf_hierarchy)
  ))

  return(bnf_hierarchy)
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
#   dmd_lookup : $dmd_lookup from fn_build_dmd_bnf_lookup()
#   vtm_lookup : $vtm_lookup from fn_build_dmd_bnf_lookup()
#   impute_bnf_from_vtm : if TRUE, impute missing BNF codes via VTM lookup
#   output : "wide" or "long"
#   unmapped_action : "keep" (retain unmapped) or "drop" (remove)
#######################################################################################

fn_dmd_to_bnf <- function(
  patient_data,
  project_stage,
  dmd_lookup,
  vtm_lookup,
  impute_bnf_from_vtm = TRUE,
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

  has_med_count <- "med_count" %in% names(patient_data)
  patient_level_cols <- c("patient_id", if (has_med_count) "med_count")

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

  patient_bnf <- patient_long |>
    left_join(dmd_lookup, by = "dmd_code") |>
    mutate(bnf_imputed = FALSE)

  # Capture dm+d codes present in patient data but absent from the lookup
  dmd_not_in_lookup <- patient_bnf |>
    filter(is.na(in_lookup)) |>
    count(dmd_code, name = "n_occurrences") |>
    arrange(desc(n_occurrences)) |>
    mutate(
      n_occurrences_midpoint6 = if_else(
        n_occurrences <= 7,
        NA_real_,
        fn_roundmid_any(n_occurrences)
      )
    ) |>
    select(dmd_code, n_occurrences_midpoint6)

  write_csv(
    dmd_not_in_lookup,
    here::here(
      "output",
      "data_descriptions",
      paste0(project_stage, "-dmd_not_in_lookup.csv")
    )
  )

  message(sprintf(
    "--- %d dm+d codes not in NHSBSA lookup; *-dmd_not_in_lookup.csv",
    nrow(dmd_not_in_lookup)
  ))

  # Impute missing BNF via VTM
  if (impute_bnf_from_vtm) {
    before_impute <- sum(is.na(patient_bnf$bnf_substance_code))

    patient_bnf <- patient_bnf |>
      left_join(vtm_lookup, by = "vtm_code") |>
      mutate(
        bnf_imputed = if_else(
          is.na(bnf_substance_code) & !is.na(bnf_substance_imputed),
          TRUE,
          FALSE
        ),
        bnf_substance_code = coalesce(
          bnf_substance_code,
          bnf_substance_imputed
        )
      ) |>
      select(-bnf_substance_imputed)

    after_impute <- sum(is.na(patient_bnf$bnf_substance_code))

    message(sprintf(
      "--- VTM --> BNF Imputation applied: %d --> %d missing BNF codes",
      before_impute,
      after_impute
    ))
  }

  # Capture codes still unmapped to bnf for examination
  dmd_unmapped_to_bnf <- patient_bnf |>
    filter(is.na(bnf_substance_code)) |>
    count(dmd_code, name = "n_occurrences") |>
    arrange(desc(n_occurrences)) |>
    mutate(
      n_occurrences_midpoint6 = if_else(
        n_occurrences <= 7,
        NA_real_,
        fn_roundmid_any(n_occurrences)
      )
    ) |>
    select(dmd_code, n_occurrences_midpoint6)

  write_csv(
    dmd_unmapped_to_bnf,
    here::here(
      "output",
      "data_descriptions",
      paste0(project_stage, "-dmd_unmapped_to_bnf.csv")
    )
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

  # Output
  if (output == "long") {
    message("--- Returning long format")
    return(patient_bnf)
  }

  if (output == "wide") {
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
#   patient_data    : data frame containing a bnf_substance_code column
#   bnf_hierarchy   : lookup from fn_build_bnf_hierarchy()
#   project_stage   : string label used to name diagnostic output files
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
      "--- %d rows (%.1f%%) have a bnf_substance_code in data but absent from hierarchy *-bnf_unmapped_to_hierarchy.csv",
      n_bnf_code_not_matched,
      pct_unmapped
    ))

    bnf_unmapped_to_hierarchy <- unmatched_codes |>
      count(bnf_substance_code, name = "n_occurrences") |>
      arrange(desc(n_occurrences)) |>
      mutate(
        n_occurrences_midpoint6 = if_else(
          n_occurrences <= 7,
          NA_real_,
          fn_roundmid_any(n_occurrences)
        )
      ) |>
      select(bnf_substance_code, n_occurrences_midpoint6)

    write_csv(
      bnf_unmapped_to_hierarchy,
      here::here(
        "output",
        "data_descriptions",
        paste0(project_stage, "-bnf_unmapped_to_hierarchy.csv")
      )
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

  # Convert hierarchy columns to factors
  joined_data <- joined_data |>
    mutate(across(
      c(
        bnf_chapter_code,
        bnf_section_code,
        bnf_paragraph_code,
        bnf_subparagraph_code,
        bnf_substance_code
      ),
      as.factor
    ))

  return(joined_data)
}
