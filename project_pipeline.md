# Project Pipeline

Brief description of the pipeline here if you want one.

## Diagram
```mermaid
---
config:
    look: default
    theme: default
---
flowchart TD
    b("openSAFELY-TPP backend"):::openSAFELY
    a1("generate_dataset_inex"):::ehrql
    d1("dataset_inex.arrow"):::data
    a2("dataset_cleaning_inex"):::R
    o1("cleaning_inex-data_flow.csv"):::output
    o2("cleaning_inex-*.txt"):::output
    d2("dataset_inex_cleaned.arrow"):::data

    b --> a1 --> d1 --> a2 --> o1 & o2 & d2

    classDef openSAFELY color:#FFFFFF, fill:#212121, stroke:#212121
    classDef ehrql color:#000000, fill:#FFD600, stroke:#FFD600
    classDef R color:#FFFFFF, fill:#E65100, stroke:#E65100
    classDef data color:#FFFFFF, fill:#1565C0, stroke:#1565C0
    classDef output color:#FFFFFF, fill:#00C853, stroke:#00C853
```

## Legend

| Colour | Type |
|--------|------|
| ⬛ | OpenSAFELY backend |
| 🟨 | ehrQL action |
| 🟧 | R script |
| 🟦 | Data file |
| 🟩 | Output file |