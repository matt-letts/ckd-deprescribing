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
#   vtm_lookup : VTM --> most common BNF subparagraph, for imputation when missing
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
      # First 7 characters of BNF code = subparagraph
      bnf_subparagraph_code = substr(bnf_code, 1, 7),
      # Flag for identifying dm+d codes in patient data absent from lookup
      in_lookup = TRUE
    ) |>
    distinct(dmd_code, .keep_all = TRUE) |>
    select(
      dmd_code,
      vtm_code,
      bnf_code,
      vtm_name,
      bnf_subparagraph_code,
      in_lookup
    )

  message(sprintf(
    "--- DMD to BNF lookup built: %d dm+d codes | %.1f%% with BNF | %.1f%% with VTM",
    nrow(dmd_lookup),
    100 * mean(!is.na(dmd_lookup$bnf_subparagraph_code)),
    100 * mean(!is.na(dmd_lookup$vtm_code))
  ))

  # Build VTM imputation lookup:
  # For each VTM, find the most common BNF subparagraph mapping across all
  # its associated AMP/VMP codes - used to impute missing BNF subparagraphs
  vtm_lookup <- dmd_lookup |>
    filter(!is.na(vtm_code), !is.na(bnf_subparagraph_code)) |>
    count(vtm_code, bnf_subparagraph_code, sort = TRUE) |>
    group_by(vtm_code) |>
    slice_max(n, n = 1, with_ties = FALSE) |>
    ungroup() |>
    select(vtm_code, bnf_subparagraph_imputed = bnf_subparagraph_code)

  message(sprintf(
    "--- VTM imputation lookup built: %d VTM codes with matching BNF subparagraph codes",
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
# Returns a clean lookup of BNF subparagraph codes to their human-readable names,
# plus higher-level hierarchy names (chapter, section, paragraph).
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

  # don't need to see column types as forcing all to character below
  bnf_raw <- read_csv(bnf_hierarchy_path, show_col_types = FALSE)

  # Check expected columns are present and spelled as expected
  expected_cols <- c(
    "BNF_CHAPTER",
    "BNF_CHAPTER_CODE",
    "BNF_SECTION",
    "BNF_SECTION_CODE",
    "BNF_PARAGRAPH",
    "BNF_PARAGRAPH_CODE",
    "BNF_SUBPARAGRAPH",
    "BNF_SUBPARAGRAPH_CODE"
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
      bnf_chapter_name = `BNF_CHAPTER`,
      bnf_chapter_code = `BNF_CHAPTER_CODE`,
      bnf_section_name = `BNF_SECTION`,
      bnf_section_code = `BNF_SECTION_CODE`,
      bnf_paragraph_name = `BNF_PARAGRAPH`,
      bnf_paragraph_code = `BNF_PARAGRAPH_CODE`,
      bnf_subparagraph_name = `BNF_SUBPARAGRAPH`,
      bnf_subparagraph_code = `BNF_SUBPARAGRAPH_CODE`
    ) |>
    mutate(across(everything(), as.character)) |>
    distinct(bnf_subparagraph_code, .keep_all = TRUE) |>
    select(
      bnf_chapter_name,
      bnf_chapter_code,
      bnf_section_name,
      bnf_section_code,
      bnf_paragraph_name,
      bnf_paragraph_code,
      bnf_subparagraph_name,
      bnf_subparagraph_code
    )

  message(sprintf(
    "--- bnf hierarchy build %d distinct BNF subparagraph codes",
    nrow(bnf_hierarchy)
  ))

  return(bnf_hierarchy)
}


#######################################################################################
# fn_dmd_to_bnf()
#######################################################################################
# Converts wide-format patient medication data with AMP/VMP dm+d codes into
# BNF/VTM classifications using the mapping from fn_build_dmd_bnf_lookup()
#
# Arguments:
#   patient_data : wide-format data frame with med_dmd_code_* and med_date_*
#   project_stage : string label used to name diagnostic output files
#   dmd_lookup : $dmd_lookup from fn_build_dmd_bnf_lookup()
#   vtm_lookup : $vtm_lookup from fn_build_dmd_bnf_lookup()
#   impute_bnf_from_vtm : if TRUE, impute missing BNF codes via VTM lookup
#   output : "wide" or "long"
#   unmapped_action : "keep" (retain NAs) or "drop" (remove NA rows)
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

  # 1. Data validation ------------------------------------------------------------------

  if (!is.data.frame(patient_data)) {
    stop("patient_data must be a data frame - collect() arrow data first")
  }

  dmd_cols <- grep("^med_dmd_code_\\d+$", names(patient_data), value = TRUE)
  date_cols <- grep("^med_date_\\d+$", names(patient_data), value = TRUE)

  # Safety checks to ensure function not going to break
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

  # handles the fact that med_count patient_level_column may be in initial data
  has_med_count <- "med_count" %in% names(patient_data)
  patient_level_cols <- c("patient_id", if (has_med_count) "med_count")

  message(sprintf(
    "--- Data valid for conversion: %d rows | %d med_dmd_code_* columns",
    nrow(patient_data),
    length(dmd_cols)
  ))

  # 2. Separate patients with no medicines ----------------------------------------------
  # Store for reattachment at the end - these would otherwise be lost in the pivot
  patients_no_meds_long <- patient_data |>
    filter(if_all(all_of(dmd_cols), ~ is.na(.) | . == "" | . == "NA")) |>
    select(all_of(patient_level_cols)) |>
    mutate(
      med_index = NA_character_,
      dmd_code = NA_character_,
      med_date = as.Date(NA),
      vtm_code = NA_character_,
      vtm_name = NA_character_,
      bnf_subparagraph_code = NA_character_,
      bnf_imputed = NA
    )

  patients_no_meds_wide <- patient_data |>
    filter(if_all(all_of(dmd_cols), ~ is.na(.) | . == "" | . == "NA")) |>
    select(all_of(patient_level_cols))

  message(sprintf(
    "--- %d patients with no medicines - will be reattached at output",
    nrow(patients_no_meds_long)
  ))

  # 3. Reshape to long format -----------------------------------------------------------
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

  # 4. Join to BNF lookup ---------------------------------------------------------------
  patient_bnf <- patient_long |>
    left_join(dmd_lookup, by = "dmd_code") |>
    mutate(bnf_imputed = FALSE)

  # Capture dm+d codes present in patient data but absent from the lookup
  dmd_not_in_lookup <- patient_bnf |>
    filter(is.na(in_lookup)) |> # NA if dmd_code in dataset but not in lookup
    count(dmd_code, name = "n_occurrences") |>
    arrange(desc(n_occurrences)) |>
    mutate(
      # apply SDC principles
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
    "--- %d dm+d codes not in NHSBSA lookup; saved to output/data_descriptions folder",
    nrow(dmd_not_in_lookup)
  ))

  # Remove columns not needed downstream (bnf_code only needed to subparagraph level)
  patient_bnf <- patient_bnf |>
    select(-in_lookup, -bnf_code)

  # 5. Impute missing BNF via VTM -------------------------------------------------------
  if (impute_bnf_from_vtm) {
    before_impute <- sum(is.na(patient_bnf$bnf_subparagraph_code))

    patient_bnf <- patient_bnf |>
      left_join(vtm_lookup, by = "vtm_code") |>
      mutate(
        bnf_imputed = if_else(
          is.na(bnf_subparagraph_code) & !is.na(bnf_subparagraph_imputed),
          TRUE,
          FALSE
        ),
        bnf_subparagraph_code = coalesce(
          bnf_subparagraph_code,
          bnf_subparagraph_imputed
        )
      ) |>
      select(-bnf_subparagraph_imputed)

    after_impute <- sum(is.na(patient_bnf$bnf_subparagraph_code))

    message(sprintf(
      "--- VTM --> BNF Imputation applied: %d --> %d missing BNF codes",
      before_impute,
      after_impute
    ))
  }

  # 6. Capture codes still unmapped -----------------------------------------------------
  # note will vary depending on whether imputation has been performed
  dmd_unmapped_to_bnf <- patient_bnf |>
    filter(is.na(bnf_subparagraph_code)) |>
    count(dmd_code, name = "n_occurrences") |>
    arrange(desc(n_occurrences)) |>
    mutate(
      # apply SDC principles
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

  # 7. Handle remaining unmapped --------------------------------------------------------
  n_unmapped <- sum(is.na(patient_bnf$bnf_subparagraph_code))
  pct_unmapped <- 100 * n_unmapped / nrow(patient_bnf)

  if (n_unmapped > 0) {
    message(sprintf(
      "--- %d records (%.1f%%) still missing BNF subparagraph after processing",
      n_unmapped,
      pct_unmapped
    ))

    if (unmapped_action == "drop") {
      patient_bnf <- patient_bnf |> filter(!is.na(bnf_subparagraph_code))
      message("--- Unmapped records dropped")
    } else {
      message("--- Unmapped records retained as NAs")
    }
  }

  # 8. Output ---------------------------------------------------------------------------
  if (output == "long") {
    message("--- Returning long format")
    return(bind_rows(patient_bnf, patients_no_meds_long))
  }

  if (output == "wide") {
    message("--- Returning wide format")

    wide <- patient_bnf |>
      select(
        all_of(patient_level_cols),
        med_index,
        dmd_code,
        bnf_subparagraph_code,
        vtm_name,
        med_date,
        bnf_imputed
      ) |>
      pivot_wider(
        names_from = med_index,
        values_from = c(
          dmd_code,
          bnf_subparagraph_code,
          vtm_name,
          med_date,
          bnf_imputed
        ),
        names_glue = "med_{.value}_{med_index}"
      )

    return(bind_rows(wide, patients_no_meds_wide))
  }
}


#######################################################################################
# fn_add_bnf_names()
#######################################################################################
# Joins BNF hierarchy names (chapter, section, paragraph, subparagraph) onto a
# dataset containing a bnf_subparagraph_code column (i.e. the "long" output from
# fn_dmd_to_bnf())
#
# Arguments:
#   patient_data : data frame containing a bnf_subparagraph_code column
#   bnf_hierarchy : lookup from fn_build_bnf_hierarchy()
#######################################################################################

fn_add_bnf_names <- function(patient_data, bnf_hierarchy) {
  require(tidyverse)

  message("Running fn_add_bnf_names")

  if (!"bnf_subparagraph_code" %in% names(patient_data)) {
    stop("data must contain a bnf_subparagraph_code column")
  }

  before <- nrow(patient_data)

  result <- patient_data |>
    left_join(bnf_hierarchy, by = "bnf_subparagraph_code")

  after <- nrow(result)

  if (before != after) {
    warning(sprintf(
      "Row count changed after join (%d --> %d). Check for duplicate bnf_subparagraph_code keys in bnf_hierarchy.",
      before,
      after
    ))
  }

  n_unmatched <- sum(
    is.na(result$bnf_subparagraph_name) & !is.na(result$bnf_subparagraph_code)
  )

  if (n_unmatched > 0) {
    message(sprintf(
      "%d rows have a bnf_subparagraph_code with no matching name in hierarchy",
      n_unmatched
    ))
  }

  return(result)
}
