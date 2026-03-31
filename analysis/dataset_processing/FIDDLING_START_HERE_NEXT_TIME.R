  dmd_bnf_mapping_path = here::here("docs", "bnf_dmd_mapping_20260324.xlsx")
  snomed_bnf_raw <- readxl::read_xlsx(dmd_bnf_mapping_path, sheet = 1)

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
      product_desc = `DM+D: Product Description`
    ) |>
    filter(pres_pack == "Presentation") |>
    mutate(
      dmd_code = as.character(dmd_code),
      vtm_code = as.character(vtm_code),
      bnf_code = as.character(bnf_code),
      vtm_name = as.character(vtm_name),
      # First 9 characters of BNF code = substance
      bnf_chapter_code = substr(bnf_code, 1, 2),
      bnf_substance_code = substr(bnf_code, 1, 9),
      # Flag for identifying dm+d codes in patient data absent from lookup
      in_lookup = TRUE
    ) |>
    distinct(dmd_code, .keep_all = TRUE)


  # Define the chapters to exclude
exclude_chapters <- c("14","15","18","19","20","21","22","23")

# Create a BNF chapter reason
dmd_lookup <- dmd_lookup |>
  mutate(
    exclude_bnf = bnf_chapter_code %in% exclude_chapters,
    exclude_reason_bnf = ifelse(exclude_bnf,
                                paste0("BNF chapter ", bnf_chapter_code, " - ",
                                       case_when(
                                         bnf_chapter_code == "14" ~ "Immunological products",
                                         bnf_chapter_code == "15" ~ "Anaesthesia",
                                         bnf_chapter_code == "18" ~ "Preparations used in diagnosis",
                                         bnf_chapter_code == "19" ~ "Other drugs and preparations",
                                         bnf_chapter_code == "20" ~ "Dressings",
                                         bnf_chapter_code == "21" ~ "Appliances",
                                         bnf_chapter_code == "22" ~ "Incontinence appliances",
                                         bnf_chapter_code == "23" ~ "Stoma appliances"
                                       )), 
                                NA_character_)
  )

oral_patterns <- c(
  "\\boral\\b",
  "\\btablet(s)?\\b",
  "\\bcapsule(s)?\\b",
  "\\bcaplet(s)?\\b",
  "\\blozenge(s)?\\b",
  "\\bpastille(s)?\\b",
  "\\borodispersible\\b",
  "\\bbuccal\\b",
  "\\bsyrup\\b",
  "\\bsublingual\\b",
  "\\bgranule(s)?\\b",
  "\\bsachet(s)?\\b",
  "\\boral (solution|suspension|drops|liquid)\\b"
)

non_oral_patterns <- c(
  "\\binjection(s)?\\b",
  "\\bgarment(s)?\\b",
  "\\binfusion(s)?\\b",
  "\\blymphoedema\\b",
  "\\binhalation(s)?\\b",
  "\\bnebule(s)?\\b",
  "\\brespule(s)?\\b",
  "\\bcream(s)?\\b",
  "\\bointment(s)?\\b",
  "\\bgel(s)?\\b",
  "\\blotion(s)?\\b",
  "\\bshampoo(s)?\\b",
  "\\b(eye|ear|nasal) drop(s)?\\b",
  "\\bnasal\\b",
  "\\bspray(s)?\\b",
  "\\bpatch(es)?\\b",
  "\\btransdermal\\b",
  "\\bsuppositor(y|ies)\\b",
  "\\bpessar(y|ies)\\b",
  "\\benema(s)?\\b",
  "\\bimplant(s)?\\b",
  "\\bdevice(s)?\\b",
  "ostomy",
  "\\bdressing(s)?\\b",
  "\\bcatheter(s)?\\b"
)

    dmd_lookup <- dmd_lookup |>
      mutate(
        text = str_to_lower(product_desc),
        oral_match = str_extract(text, paste(oral_patterns, collapse = "|")),
        non_oral_match = str_extract(text, paste(non_oral_patterns, collapse = "|")),
        is_oral = case_when(
          !is.na(oral_match) & is.na(non_oral_match) ~ TRUE,
          is.na(oral_match) & !is.na(non_oral_match) ~ FALSE,
          !is.na(oral_match) & !is.na(non_oral_match) ~ TRUE, # favour oral if both
          TRUE ~ NA
        ),
        route_reason = case_when(
          is_oral == TRUE ~ oral_match,
          is_oral == FALSE ~ non_oral_match, 
          TRUE ~ NA_character_
        )
      ) |> 
      select(-oral_match, -non_oral_match)

dmd_lookup <- dmd_lookup |>
  mutate(
    exclude = exclude_bnf | exclude_oral,
    exclude_reason = coalesce(exclude_reason_bnf, exclude_reason_oral)
  ) |>
  select(-oral_match)  # optional cleanup



Got it! You want to create a streamlined way to flag drugs for inclusion/exclusion in your `dmd_lookup` table based on BNF chapter codes **and** route of administration. You also want to keep the reasoning transparent in a couple of columns. Here’s a structured approach with some suggestions:

---

### **1️⃣ Exclude by BNF chapter code**

This is a good first pass because certain chapters reliably correspond to devices, dressings, anaesthesia, and other non-therapeutic items. Since `bnf_chapter_code` is the first 2 digits of the BNF, you can do something like this:

```r
# Define the chapters to exclude
exclude_chapters <- c("14","15","18","19","20","21","22","23")

# Create a BNF chapter reason
dmd_lookup <- dmd_lookup |>
  mutate(
    exclude_bnf = bnf_chapter_code %in% exclude_chapters,
    exclude_reason_bnf = ifelse(exclude_bnf,
                                paste0("BNF chapter ", bnf_chapter_code, " - ",
                                       case_when(
                                         bnf_chapter_code == "14" ~ "Immunological products",
                                         bnf_chapter_code == "15" ~ "Anaesthesia",
                                         bnf_chapter_code == "18" ~ "Preparations used in diagnosis",
                                         bnf_chapter_code == "19" ~ "Other drugs and preparations",
                                         bnf_chapter_code == "20" ~ "Dressings",
                                         bnf_chapter_code == "21" ~ "Appliances",
                                         bnf_chapter_code == "22" ~ "Incontinence appliances",
                                         bnf_chapter_code == "23" ~ "Stoma appliances"
                                       )), 
                                NA_character_)
  )
```

This gives you:

* `exclude_bnf` → TRUE/FALSE if the chapter is excluded.
* `exclude_reason_bnf` → Human-readable explanation for transparency.

---

### **2️⃣ Exclude non-oral drugs**

Since your goal is to include most oral medications, you can simplify your regex patterns slightly:

* Keep common oral forms: tablets, capsules, syrup, oral solution/suspension, lozenges.
* Anything else you treat as non-oral by default.

```r
# Simplified oral pattern
oral_patterns_simple <- c(
  "\\boral\\b",
  "\\btablet(s)?\\b",
  "\\bcapsule(s)?\\b",
  "\\bcaplet(s)?\\b",
  "\\blozenge(s)?\\b",
  "\\bsyrup\\b",
  "\\bsolution\\b",
  "\\bsuspension\\b"
)

dmd_lookup <- dmd_lookup |>
  mutate(
    text = str_to_lower(product_desc),
    oral_match = str_detect(text, paste(oral_patterns_simple, collapse = "|")),
    exclude_oral = case_when(
      oral_match ~ FALSE,
      TRUE ~ TRUE
    ),
    exclude_reason_oral = ifelse(exclude_oral, "Non-oral formulation", NA_character_)
  )
```

* Here, `oral_match` flags oral forms.
* `exclude_oral` flips that to TRUE for non-oral medications.
* `exclude_reason_oral` keeps the rationale.

---

### **3️⃣ Combine exclusions**

Now you can combine both flags into a single `include`/`exclude` column, while keeping the reason(s):

```r
dmd_lookup <- dmd_lookup |>
  mutate(
    exclude = exclude_bnf | exclude_oral,
    exclude_reason = coalesce(exclude_reason_bnf, exclude_reason_oral)
  ) |>
  select(-oral_match)  # optional cleanup
```

* `exclude` → TRUE if either BNF chapter or non-oral.
* `exclude_reason` → prioritizes chapter reason over oral reason for transparency.

---

### **4️⃣ Feedback & suggestions**

1. **BNF completeness**: You correctly noted that BNF codes are only ~83% complete. Using the chapter code is a good approach because these are broad and usually cover devices/dressings. Regex is better for oral/non-oral classification.
2. **Route detection**: You might still catch a few edge cases (like "buccal tablet" or "oral implant") – so review a small sample to see if the regex needs tweaks.
3. **Future flexibility**: By keeping `exclude_reason` text, you can always audit and refine your rules without altering downstream joins.
4. **Optional**: Add a “confidence” column for incomplete BNF/VTMs – e.g., `bnf_complete = !is.na(bnf_code)` so you know which rows were excluded primarily on regex.

---

If you want, I can draft a **fully combined `dmd_lookup` transformation** with all these flags in one `mutate` pipe that’s clean, auditable, and ready for `left_join` with patient data. It would be more concise than what you have now.

Do you want me to do that?


unknown_tokens <- dmd_lookup |>
  filter(is.na(route_reason)) |>
  select(text) |>
  unnest_tokens(word, text) |>
  count(word, sort = TRUE)
      
write_csv(unknown_tokens, here::here("docs", "unknown_tokens.csv"))
dmd_lookup |>
  summarise(
    pct_oral = mean(is_oral == TRUE, na.rm = TRUE),
    pct_non_oral = mean(is_oral == FALSE, na.rm = TRUE),
    pct_unknown = mean(is.na(is_oral))
  )