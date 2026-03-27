require(readxl)
require(here)
require(tidyverse)
require(arrow)
source(here::here("analysis", "functions", "fn_preprocess.r"))
source(here::here("analysis", "functions", "fn_modify_dummy_data.r"))


source(here::here("analysis", "dataset_definition", "study_dates.r"))
study_dates <- lapply(study_dates, function(x) as.Date(x))

# Load dataset, keeping in arrow format for speed ------------------------
message("\nLoad the dataset")
input_filename = "dataset_inex_meds.arrow"
dataset_process_baseline_meds_1_input <- arrow::open_dataset(
  here::here("output", input_filename),
  format = "ipc"
)

# Preprocess data: transform variables and modify dummy data -------------
dataset_process_baseline_meds_2_preprocessed <- fn_preprocess(
  arrow_data = dataset_process_baseline_meds_1_input,
  dataset = "baseline_meds", # leads to no modification at present
  index_date = study_dates$index_date,
  collect_and_describe = FALSE
) |>
  collect() # collect before passing into fn_dmd_to_bnf

patient_data <- dataset_process_baseline_meds_2_preprocessed
mapping_path <- here::here("docs", "BNF Snomed Mapping data 20260324.xlsx")
snomed_bnf_raw <- readxl::read_xlsx(mapping_path, sheet = "Sheet1")

# At the top of the function, after data validation
if (!is.data.frame(patient_data)) {
  stop("`patient_data` must be a data frame - collect() arrow data first.")
}

if (!file.exists(mapping_path)) {
  stop(sprintf("NHSBSA mapping file not found at: %s", mapping_path))
}

dmd_cols <- grep("^med_dmd_code_\\d+$", names(patient_data), value = TRUE)
date_cols <- grep("^med_date_\\d+$", names(patient_data), value = TRUE)

# safety checks that will otherwise break the function
if (length(dmd_cols) == 0) {
  stop("No columns matching `med_dmd_code_*` found in patient data.")
}

if (length(dmd_cols) != length(date_cols)) {
  stop(
    "Number of `med_dmd_code_*` columns (%d) does not match `med_date_*` columns (%d).",
    length(dmd_cols),
    length(date_cols)
  )
}

message(sprintf(
  "--- Data valid for conversion: %d rows, %d med_dmd_code_* columns detected.",
  nrow(patient_data),
  length(dmd_cols)
))

has_med_count <- "med_count" %in% names(patient_data)
patient_level_cols <- c("patient_id", if (has_med_count) "med_count")


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

# clean and process the raw mapping file - store it as lookup
lookup <- snomed_bnf_raw |>
  rename(
    dmd_code = `SNOMED Code`,
    bnf_code = `BNF Code`,
    pres_pack = `Presentation / Pack Level`,
    vtm_code = `VTM`,
    vtm_name = `VTM Name`
  ) |>
  # VMP and AMP (presentation-level) rows only - reflecting dmd in TPP
  filter(pres_pack == "Presentation") |>
  mutate(
    dmd_code = as.character(dmd_code),
    vtm_code = as.character(vtm_code),
    bnf_code = as.character(bnf_code),
    vtm_name = as.character(vtm_name),
    # First 7 characters of BNF code = subparagraph
    bnf_subparagraph = substr(bnf_code, 1, 7),
    # in_lookup is a flag for use later to identify if dmd_codes present
    # in the patient data that aren't in the lookup file
    in_lookup = TRUE
  ) |>
  distinct(dmd_code, .keep_all = TRUE) |>
  select(
    dmd_code,
    vtm_code,
    bnf_code,
    vtm_name,
    bnf_subparagraph,
    in_lookup
  )

# print stats about the lookup table compiled;
# significant number lacking VTM mainly represent devices / combinations
message(sprintf(
  "--- Code lookup built: %d dm+d codes | %.1f%% with BNF | %.1f%% with VTM",
  nrow(lookup),
  100 * mean(!is.na(lookup$bnf_subparagraph)),
  100 * mean(!is.na(lookup$vtm_code))
))

vtm_bnf_lookup <- lookup |>
  filter(!is.na(vtm_code), !is.na(bnf_subparagraph)) |>
  # count() creates a table with 3 columns:
  # vtm_code, bnf_subparagraph and n (the number of occurrences of the combination)
  count(vtm_code, bnf_subparagraph, sort = TRUE) |>
  # group_by() within each VTM, decide what the most common bnf_subparagraph is
  group_by(vtm_code) |>
  # slice_max() for each VTM pick the the most common bnf_subparagraph mapping
  slice_max(n, n = 1, with_ties = FALSE) |>
  ungroup() |>
  select(vtm_code, bnf_subparagraph_imputed = bnf_subparagraph)

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

patient_bnf <- patient_long |>
  left_join(lookup, by = "dmd_code") |>
  mutate(bnf_imputed = FALSE)

dmd_not_in_lookup <- patient_bnf |>
  filter(is.na(in_lookup)) |> # NA if dmd_code in dataset but not in lookup
  count(dmd_code, name = "n_occurrences") |>
  arrange(desc(n_occurrences)) |>
  mutate(
    n_occurrences_midpoint6 = if_else(
      n_occurrences <= 7,
      NA,
      fn_roundmid_any(n_occurrences)
    )
  ) |>
  select(dmd_code, n_occurrences_midpoint6)

before_impute <- sum(is.na(patient_bnf$bnf_subparagraph))

patient_bnf <- patient_bnf |>
  left_join(vtm_bnf_lookup, by = "vtm_code") |>
  mutate(
    bnf_imputed = if_else(
      is.na(bnf_subparagraph) & !is.na(bnf_subparagraph_imputed),
      TRUE,
      FALSE
    ),
    bnf_subparagraph = coalesce(bnf_subparagraph, bnf_subparagraph_imputed)
  ) |>
  select(-bnf_subparagraph_imputed)

after_impute <- sum(is.na(patient_bnf$bnf_subparagraph))

message(sprintf(
  "--- Imputation applied: %d --> %d missing BNF codes (%.1f%% reduction)",
  before_impute,
  after_impute,
  100 * (before_impute - after_impute) / before_impute
))

n_unmapped <- sum(is.na(patient_bnf$bnf_subparagraph))
pct_unmapped <- 100 * n_unmapped / nrow(patient_bnf)

message(sprintf(
  "--- %d records (%.1f%%) still missing BNF subparagraph after processing",
  n_unmapped,
  pct_unmapped
))

patient_bnf_wide <- patient_bnf |>
  select(
    patient_id,
    med_count,
    med_index,
    bnf_subparagraph,
    vtm_name,
    med_date,
    bnf_imputed
  ) |>
  pivot_wider(
    names_from = med_index,
    values_from = c(bnf_subparagraph, vtm_name, med_date, bnf_imputed),
    names_glue = "med_{.value}_{med_index}"
  )
