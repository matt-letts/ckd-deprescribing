##########################################################################################
# fn_classify_route_from_trud()
#
# Adds route of administration to dmd_lookup using NHS TRUD dm+d XML files.
# Download from: https://isd.digital.nhs.uk/trud/ (free registration required)
# TRUD contain a mapping of all VMP codes to their licensed routes. They also map
# AMPs to VMPs. OpenSAFELY contains AMP and VMP codes only.
#
# Route codes are mapped to project categories via docs/dmd_route_cat_map.csv.
# Where a product maps to multiple route categories it is set to "multiple_routes".
##########################################################################################

fn_classify_route_from_trud <- function(
  dmd_lookup,
  trud_folder_path,
  project_stage,
  route_cat_map_path
) {
  require(xml2)
  require(tidyverse)

  message("Running fn_classify_route_from_trud")

  if (!file.exists(trud_folder_path)) {
    stop(sprintf("TRUD folder not found at: %s", trud_folder_path))
  }

  # Because the file name endings vary depending on date, using grep()
  files_in_folder <- list.files(trud_folder_path)
  vmp_file <- grep("^f_vmp2", files_in_folder, value = TRUE)
  amp_file <- grep("^f_amp2", files_in_folder, value = TRUE)

  if (any(lengths(list(vmp_file, amp_file)) != 1)) {
    stop("Could not uniquely identify f_vmp2, f_amp2 in folder")
  }

  ##### VMP to route code mapping #####

  # The VMP xml file contains a DROUTE node for every VMP with a route
  # DROUTE contains VPID - the VMP code, and ROUTECD - the route code
  message("--- Reading VMP route data from f_vmp2")
  vmp_xml <- read_xml(here::here(trud_folder_path, vmp_file))
  drug_route_nodes <- xml_find_all(vmp_xml, "//DRUG_ROUTE/DROUTE")

  # VMP to route code lookup. VMPs with >1 route will have multiple rows
  vmp_code_to_route <- tibble(
    vpid = xml_text(xml_find_first(drug_route_nodes, "VPID")),
    route_code = xml_text(xml_find_first(drug_route_nodes, "ROUTECD"))
  )

  # VMPs with no DROUTE have no licensed route in dm+d
  # These are almost all devices, saving to a diagnostic csv for transparency
  vmp_nodes <- xml_find_all(vmp_xml, "//VMPS/VMP")
  all_vmps <- tibble(
    vpid = xml_text(xml_find_first(vmp_nodes, "VPID")),
    vmp_name = xml_text(xml_find_first(vmp_nodes, "NM"))
  )

  vmps_no_route <- all_vmps |>
    anti_join(vmp_code_to_route, by = "vpid") |>
    left_join(
      dmd_lookup |> select(dmd_code, bnf_code),
      by = c("vpid" = "dmd_code")
    ) |>
    arrange(bnf_code, vmp_name)

  message(sprintf(
    "--- VMP routes: %d entries across %d VMPs (%d with multiple routes, %d with no route)",
    nrow(vmp_code_to_route),
    n_distinct(vmp_code_to_route$vpid),
    sum(table(vmp_code_to_route$vpid) > 1),
    nrow(vmps_no_route)
  ))

  ##### AMP to route code mapping via VMPs #####
  message("--- Reading AMP -> VMP mapping")
  amp_xml <- read_xml(here::here(trud_folder_path, amp_file))
  amp_nodes <- xml_find_all(amp_xml, "//AMPS/AMP")

  # Every AMP maps to only one VMP, but a VMP can be mapped to multiple AMPs
  # This 2 column tibble is every AMP mapped to it's VMP
  amp_vmp_map <- tibble(
    apid = xml_text(xml_find_first(amp_nodes, "APID")),
    vpid = xml_text(xml_find_first(amp_nodes, "VPID"))
  )
  message(sprintf("--- AMP -> VMP map made: %d AMP codes", nrow(amp_vmp_map)))

  # Build dmd_code -> route_code lookup for VMPs and AMPs
  # Renaming vpid and apid to dmd_code to join with dmd_lookup

  # VMP already mapped to route
  vmp_route_lookup <- vmp_code_to_route |>
    rename(dmd_code = vpid)

  # AMP needs to join to VMP to get route code
  # AMPs mapping to a VMP with no route will get an NA - already captured in vmps_no_route
  amp_route_lookup <- amp_vmp_map |>
    left_join(vmp_code_to_route, by = "vpid", relationship = "many-to-many") |>
    filter(!is.na(route_code)) |>
    rename(dmd_code = apid) |>
    select(-vpid)

  dmd_route_lookup <- bind_rows(vmp_route_lookup, amp_route_lookup) |>
    filter(!is.na(route_code)) |>
    distinct()

  ##### Map TRUD route codes to project categories #####
  route_cat_map <- read_csv(
    route_cat_map_path,
    col_types = cols(route_code = col_character()),
    show_col_types = FALSE
  ) |>
    select(route_code, route_cat)

  route_levels <- c(
    "intravenous",
    "intramuscular",
    "subcutaneous",
    "eye_ear_nasal",
    "rectal_vaginal",
    "transdermal",
    "inhaled",
    "oromucosal",
    "topical",
    "oral",
    "other",
    "multiple_routes",
    "unclassified"
  )

  # Warn if TRUD contains route codes absent from the mapping CSV
  # Should not be an issue - but may be if TRUD changes the SNOMED route codes
  unmatched_routes <- dmd_route_lookup |>
    distinct(route_code) |>
    anti_join(route_cat_map, by = "route_code")

  if (nrow(unmatched_routes) > 0) {
    warning(sprintf(
      "%d route code(s) in TRUD data not found in dmd_route_cat_map.csv",
      nrow(unmatched_routes)
    ))
  }

  # Replace SNOMED route codes with project route categories
  # distinct() collapses multiple SNOMED codes that map to the same project category
  # Even if there were two distinct snomed route codes (e.g. ocular and intraocular),
  # they would map to the same project category so can safely collapse
  dmd_route_cat <- dmd_route_lookup |>
    left_join(route_cat_map, by = "route_code") |>
    mutate(route_cat = if_else(is.na(route_cat), "unclassified", route_cat)) |>
    distinct(dmd_code, route_cat)

  # Products mapping to more than one category are set to multiple_routes
  route_lookup_final <- dmd_route_cat |>
    group_by(dmd_code) |>
    summarise(
      route_cat = if_else(
        n_distinct(route_cat) == 1,
        first(route_cat),
        "multiple_routes"
      ),
      .groups = "drop"
    )

  # More detail about these multiple route products for diagnostic .csv
  # Very few are oral - and those that are are mostly homeopathic products or
  # antibiotics - I think that these will not be relevant
  multiple_route_detail <- dmd_route_cat |>
    semi_join(
      filter(route_lookup_final, route_cat == "multiple_routes"),
      by = "dmd_code"
    ) |>
    left_join(
      dmd_lookup |> select(dmd_code, dmd_name, bnf_code),
      by = "dmd_code"
    ) |>
    arrange(dmd_code, route_cat)

  ##### Join TRUD-derived project route categories to dmd_lookup #####
  result <- dmd_lookup |>
    left_join(route_lookup_final, by = "dmd_code") |>
    mutate(
      route_cat = if_else(is.na(route_cat), "unclassified", route_cat),
      route_cat = factor(route_cat, levels = route_levels)
    )

  # Final message about results
  n_unclassified <- sum(result$route_cat == "unclassified", na.rm = TRUE)
  n_multi <- sum(result$route_cat == "multiple_routes", na.rm = TRUE)
  message(sprintf(
    "--- TRUD route classification complete: %d dm+d products | %d (%.1f%%) unclassified | %d mapping to multiple route categories",
    nrow(result),
    n_unclassified,
    100 * n_unclassified / nrow(result),
    n_multi
  ))

  ##### Diagnostics #####

  # Route breakdown by BNF chapter
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
      paste0(project_stage, "-trud_route_by_bnf_chapter_summary.csv")
    )
  )

  # Route == unclassified medicines that do have BNF codes
  unclassified_detail <- result |>
    filter(route_cat == "unclassified", !is.na(bnf_code)) |>
    mutate(bnf_chapter = substr(bnf_code, 1, 2)) |>
    select(bnf_chapter, dmd_name) |>
    arrange(bnf_chapter, dmd_name)

  write_csv(
    unclassified_detail,
    here::here(
      "local_processing",
      "outputs",
      paste0(project_stage, "-trud_route_unclassified_detail.csv")
    )
  )

  # VMPs with no licensed route in dm+d
  write_csv(
    vmps_no_route,
    here::here(
      "local_processing",
      "outputs",
      paste0(project_stage, "-trud_vmps_no_route.csv")
    )
  )

  # Products mapping to more than one route category
  write_csv(
    multiple_route_detail,
    here::here(
      "local_processing",
      "outputs",
      paste0(project_stage, "-trud_multiple_route_detail.csv")
    )
  )

  return(result)
}
