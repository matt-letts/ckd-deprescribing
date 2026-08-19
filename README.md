# ckd-deprescribing

[View on OpenSAFELY](https://jobs.opensafely.org/repo/https%253A%252F%252Fgithub.com%252Fopensafely%252Fckd-deprescribing)

Details of the purpose and any published outputs from this project can be found at the link above.

The contents of this repository MUST NOT be considered an accurate or valid representation of the study or its purpose. 
This repository may reflect an incomplete or incorrect analysis with no further ongoing work.
The content has ONLY been made public to support the OpenSAFELY [open science and transparency principles](https://www.opensafely.org/about/#contributing-to-best-practice-around-open-science) and to support the sharing of re-usable code for other subsequent users.
No clinical, policy or safety conclusions must be drawn from the contents of this repository.

# About this study

This study analyses prescribing and medication discontinuation patterns in people living with chronic kidney disease (CKD) stage 4–5 who are not on kidney replacement therapy (KRT). Medications are viewed up to a baseline date (1st March 2022) and then tracked over the following 4 years.

# Pipeline overview

The analytical pipeline is defined in `project.yaml` and runs as a series of dependent actions:
See [project_pipeline.md](./project_pipeline.md) for a diagram of the analysis flow.

# Repository structure

```
analysis/
  config/                   # Files containing study-wide parameters
  dataset_analysis/         # Data analysis scripts (R)
  dataset_definition/       # Scripts for data extraction (ehrQL and python)
  dataset_processing/       # Data cleaning and processing scripts (R)
  discontinuation/          # Subfolder for discontinuation analyses
  r_functions/              # R functions sourced by other scripts
codelists/                  # Codelists sourced from https://www.opencodelists.org/
docs/                       # Reference files and pipeline diagram
dummy_tables/               # Tables used for local testing only
local_processing/ 
  generate_dummy_tables/    # Functions to create dummy tables - local testing only
  medication_lookup_tables/ # Scripts and lookups used for medication mapping
  discontinuation/          # Local scripts for outputs used in discontinuation work 
protocols/                  # Study protocol
```

# About the OpenSAFELY framework

The OpenSAFELY framework is a Trusted Research Environment (TRE) for electronic
health records research in the NHS, with a focus on public accountability and
research quality.

Read more at [OpenSAFELY.org](https://opensafely.org).

# Licences
As standard, research projects have a MIT license. 
