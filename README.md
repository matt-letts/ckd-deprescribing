# ckd-deprescribing

[View on OpenSAFELY](https://jobs.opensafely.org/repo/https%253A%252F%252Fgithub.com%252Fopensafely%252Fckd-deprescribing)

Details of the purpose and any published outputs from this project can be found at the link above.

The contents of this repository MUST NOT be considered an accurate or valid representation of the study or its purpose. 
This repository may reflect an incomplete or incorrect analysis with no further ongoing work.
The content has ONLY been made public to support the OpenSAFELY [open science and transparency principles](https://www.opensafely.org/about/#contributing-to-best-practice-around-open-science) and to support the sharing of re-usable code for other subsequent users.
No clinical, policy or safety conclusions must be drawn from the contents of this repository.

# About this study

This study analyses medication deprescribing in patients with chronic kidney disease (CKD) stage 4–5 who are not on kidney replacement therapy (KRT), using NHS electronic health records via the OpenSAFELY-TPP backend.

The study index date is 1 March 2022 and the study end date is 28 February 2026.

# Pipeline overview

The analysis pipeline is defined in `project.yaml` and runs as a series of dependent actions:

| Action | Script | Description |
|--------|--------|-------------|
| `study_dates` | `analysis/dataset_definition/study_dates.r` | Writes index and end dates to `output/study_dates.json` |
| `generate_dataset_inex` | `analysis/dataset_definition/dataset_definition_inex.py` | Extracts patient cohort with demographic, CKD, and KRT variables from TPP |
| `dataset_cleaning_inex` | `analysis/dataset_processing/dataset_cleaning_inex.r` | Applies QA and inclusion/exclusion criteria; produces cleaned cohort |
| `generate_dataset_inex_meds` | `analysis/dataset_definition/dataset_definition_inex_meds.py` | Extracts baseline medication prescriptions for the cleaned cohort |
| `dataset_process_baseline_meds` | `analysis/dataset_processing/dataset_process_baseline_meds.r` | Converts DMD codes to BNF, applies medication exclusion criteria, produces processed medication dataset |

See [project_pipeline.md](./project_pipeline.md) for a full diagram of the analysis flow.

# Repository structure

```
analysis/
  dataset_definition/   # ehrQL scripts for data extraction (Python)
  dataset_processing/   # Cleaning and processing scripts (R)
  functions/            # Reusable R functions sourced by processing scripts
codelists/              # Clinical codelists (CSV) referenced in codelists.json
docs/                   # Reference files including BNF-DMD mapping and hierarchy
protocols/              # Study protocols
```

All patient-level data files (`.arrow`) are highly sensitive and never committed to the repository.

# How to run

**Full pipeline:**
```bash
opensafely run run_all -f
```

**Single action:**
```bash
opensafely run <action_name> -f
# e.g. opensafely run dataset_cleaning_inex -f
```

The `-f` flag forces re-execution even if outputs are already up to date. Individual R scripts can also be run directly in R for development, provided the upstream `.arrow` files exist in `output/`.

# How to navigate this repo

- See [project_pipeline.md](./project_pipeline.md) for a full diagram of the analysis flow.

- The study protocols can be found in the [`protocols`](./protocols/) folder

- The [`codelists`](./codelists/) folder contains [`codelists/codelists.txt`](./codelists/codelists.txt) a list of all codelists used in this project.

# About the OpenSAFELY framework

The OpenSAFELY framework is a Trusted Research Environment (TRE) for electronic
health records research in the NHS, with a focus on public accountability and
research quality.

Read more at [OpenSAFELY.org](https://opensafely.org).

# Licences
As standard, research projects have a MIT license. 
