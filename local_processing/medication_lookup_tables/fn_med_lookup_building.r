##########################################################################################
# These functions run locally (outside the OpenSAFELY pipeline) using source files
# from docs/. Diagnostic CSVs are written to local_processing/outputs/.
#
# Run build_medication_lookup_tables.r to run functions and save outputs.
##########################################################################################

#######################################################################################
# fn_build_dmd_bnf_lookup()
#######################################################################################
# Reads the NHSBSA BNF/SNOMED mapping file downloadable from:
# https://www.nhsbsa.nhs.uk/prescription-data/understanding-our-data/bnf-snomed-mapping
# Currently using January 2026 version, but this can be updated by changing file,
# and mapping path below.
#
# Arguments:
#   dmd_bnf_mapping_path : path to the NHSBSA BNF/SNOMED mapping file
#   impute_bnf_from_vtm : if TRUE, fill missing bnf_substance_codes using the most
#                          common BNF substance code for that product's VTM. Adds an
#                          bnf_imputed flag to dmd_lookup.
#
# Returns dmd_lookup - data frame of AMP/VMP --> BNF substance mappings,
# with in_lookup and optional bnf_imputed flags
#######################################################################################

fn_build_dmd_bnf_lookup <- function(
  dmd_bnf_mapping_path = here::here("docs", "bnf_dmd_mapping_20260324.xlsx"),
  impute_bnf_from_vtm = TRUE
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
    "VTM Name",
    "DM+D: Product Description"
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
      vtm_name = `VTM Name`,
      dmd_name = `DM+D: Product Description`
    ) |>
    filter(pres_pack == "Presentation") |>
    mutate(
      dmd_code = as.character(dmd_code),
      vtm_code = as.character(vtm_code),
      bnf_code = as.character(bnf_code),
      vtm_name = as.character(vtm_name),
      dmd_name = as.character(dmd_name),
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
      dmd_name,
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

  # Apply VTM imputation to the lookup itself so that bnf_substance_code and
  # bnf_imputed are fully resolved before any patient-level joins occur.
  if (impute_bnf_from_vtm) {
    before_impute <- sum(is.na(dmd_lookup$bnf_substance_code))

    dmd_lookup <- dmd_lookup |>
      left_join(vtm_lookup, by = "vtm_code") |>
      mutate(
        bnf_imputed = if_else(
          is.na(bnf_substance_code) & !is.na(bnf_substance_imputed),
          TRUE,
          FALSE
        ),
        bnf_substance_code = coalesce(bnf_substance_code, bnf_substance_imputed)
      ) |>
      select(-bnf_substance_imputed)

    after_impute <- sum(is.na(dmd_lookup$bnf_substance_code))

    message(sprintf(
      "--- VTM imputation applied: %d --> %d products missing BNF substance code",
      before_impute,
      after_impute
    ))
  } else {
    dmd_lookup <- dmd_lookup |>
      mutate(bnf_imputed = FALSE)
    message("--- VTM imputation skipped (impute_bnf_from_vtm = FALSE)")
  }

  return(dmd_lookup)
}

#######################################################################################
# fn_classify_med_route()
#######################################################################################
# Adds route of administration to the dmd_lookup table, using the
# DM+D product description (dmd_name). Categories are checked in priority order
# (most specific first) so that e.g. "eye drops" is classified as
# eye rather than triggering oral "drops" pattern.
#
# route_uncertain is TRUE when no pattern matched
#
# Arguments:
#   dmd_lookup : from fn_build_dmd_bnf_lookup()
#   project_stage : string label used to name the diagnostic output file
#
# Returns:
#   dmd_lookup with route_cat (factor) and route_uncertain (logical) added
#   two diagnostic CSVs are also output to local_processing/outputs/:
#     *route_by_bnf_chapter.csv : route classification by BNF chapter
#     *route_unclassified_detail.csv : details of unclassified products
#######################################################################################

fn_classify_med_route <- function(
  dmd_lookup,
  project_stage
) {
  require(tidyverse)

  message("Running fn_classify_med_route")

  if (!"dmd_name" %in% names(dmd_lookup)) {
    stop("dmd_lookup must contain a dmd_name column")
  }

  route_levels <- c(
    "parenteral",
    "eye_ear_nasal",
    "rectal_vaginal",
    "transdermal",
    "inhaled",
    "oromucosal",
    "topical",
    "oral",
    "other/unclassified"
  )

  # Patterns checked in priority order — most specific first.
  # These regex patterns were created iteratively by sampling unmapped products and
  # refining patterns to capture common terms while avoiding false positives.
  # They are not exhaustive, but cover the most common forms and routes of administration.
  route_patterns <- list(
    parenteral = "\\b(injection|infusion|intravenous|intramuscular|subcutaneous)\\b",
    eye_ear_nasal = "\\b(eye|ear|nasal)\\s+(drops?|spray|ointment|gel)|\\bear/eye/nose\\b|\\beye/ear/nose\\b",
    rectal_vaginal = "\\b(suppositor(y|ies)|enemas?|pessar(y|ies)|rectal|vaginal)\\b",
    transdermal = "\\b(patch(|es)|transdermal)\\b",
    inhaled = "\\b(inhalers?|inhalation|nebulisers?|nebules?|respules?|turbohaler|accuhaler|evohaler|autohaler|clickhaler|twisthaler|diskhaler|aerohaler|aerocaps|rotacaps|cyclocaps|genuair|spincaps|inhalator)\\b|powder for inhalation",
    oromucosal = "\\b(sublingual|buccal|oromucosal|mouthwash)\\b",
    topical = "\\b(creams?|ointments?|gels?|lotions?|shampoos?|scalp|cutaneous|foam|lacquers?|paste|paints?)\\b",
    oral = "\\b(tablets?|capsules?|sachets?|powders?|oral|drops?|syrup|caplets?|lozenges?|pastilles?|granules?|orodispersible|linctus|elixir|chewing gum)\\b"
  )
  # note solution and liquid are ambiguous and not included in regex, most are captured by other patterns

  result <- dmd_lookup |>
    mutate(
      .desc = str_to_lower(dmd_name), # temp column for pattern matching
      route_cat = case_when(
        is.na(.desc) ~ "other/unclassified",
        str_detect(.desc, route_patterns$parenteral) ~ "parenteral",
        str_detect(.desc, route_patterns$eye_ear_nasal) ~ "eye_ear_nasal",
        str_detect(.desc, route_patterns$rectal_vaginal) ~ "rectal_vaginal",
        str_detect(.desc, route_patterns$transdermal) ~ "transdermal",
        str_detect(.desc, route_patterns$inhaled) ~ "inhaled",
        str_detect(.desc, route_patterns$oromucosal) ~ "oromucosal",
        str_detect(.desc, route_patterns$topical) ~ "topical",
        str_detect(.desc, route_patterns$oral) ~ "oral",
        TRUE ~ "other/unclassified"
      ),
      route_uncertain = route_cat == "other/unclassified",
      route_cat = factor(route_cat, levels = route_levels)
    ) |>
    select(-.desc)

  n_uncertain <- sum(result$route_uncertain, na.rm = TRUE)
  message(sprintf(
    "--- Route classification complete: %d dm+d products | %d (%.1f%%) unclassified (most of these are devices)",
    nrow(result),
    n_uncertain,
    100 * n_uncertain / nrow(result)
  ))

  # Route breakdown within each BNF chapter.
  bnf_chapter_route_summary <- result |>
    filter(!is.na(bnf_code)) |>
    mutate(bnf_chapter = substr(bnf_code, 1, 2)) |>
    count(bnf_chapter, route_cat) |>
    arrange(bnf_chapter, route_cat)

  write_csv(
    bnf_chapter_route_summary,
    here::here(
      "local_processing",
      "outputs",
      paste0(project_stage, "-dmd_lookup_route_by_bnf_chapter_summary.csv")
    )
  )

  # Detail of unclassified products, for manual inspection / regex improvement.
  unclassified_detail <- result |>
    filter(route_uncertain, !is.na(bnf_code)) |>
    mutate(bnf_chapter = substr(bnf_code, 1, 2)) |>
    select(bnf_chapter, dmd_name) |>
    arrange(bnf_chapter, dmd_name)

  write_csv(
    unclassified_detail,
    here::here(
      "local_processing",
      "outputs",
      paste0(project_stage, "-dmd_lookup_route_unclassified_detail.csv")
    )
  )

  return(result)
}


#######################################################################################
# fn_build_bnf_hierarchy()
#######################################################################################
# Reads the BNF Code Information file, downloadable from:
# https://opendata.nhsbsa.net/dataset/bnf-code-information-current-year
# Returns a clean lookup of BNF substance codes to their readable names,
# plus higher-level hierarchy names (chapter, section, paragraph, subparagraph).
# Using February 2026 version 90. To update to a newer release: add the new
# file to docs/ and change bnf_hierarchy_path below.
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
