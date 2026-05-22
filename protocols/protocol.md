# Protocol: Descriptive Analysis of Deprescribing Patterns for People Living with Advanced Chronic Kidney Disease
Matthew Letts<sup>1,2</sup>, Robert Porteous<sup>1</sup>, Rachel
Denholm<sup>1</sup>, Rupert Payne<sup>3</sup>, Jonathan
Sterne<sup>1</sup>, Fergus Caskey<sup>2</sup>
22 May 2026

<sup>1</sup> Electronic Health Records Group, Population Health
Sciences, Bristol Medical School, University of Bristol, Bristol, UK

<sup>2</sup> Bristol Renal, Population Health Sciences, Bristol Medical
School, University of Bristol, Bristol, UK

<sup>3</sup> Exeter Collaboration for Academic Primary Care, University
of Exeter, Exeter, UK

------------------------------------------------------------------------

| Version | Description | Date |
|----|----|----|
| 1.0 | Initial protocol developed and structured according to RECORD-PE (1) | 22/05/2026 |

------------------------------------------------------------------------

# Background

Ninety-eight percent of people living with advanced chronic kidney
disease (CKD) — stages 4 and 5, not receiving kidney replacement therapy
(KRT) — live with multiple long-term conditions (2). Resultantly,
polypharmacy is highly prevalent (3). Polypharmacy is well linked to
avoidable harm (4), hence it is a key action area in the World Health
Organisation’s current Global Patient Safety Challenge: *Medication
Without Harm* (5). For people with reduced kidney function, the risk of
harm is augmented by unpredictable drug handling and excretion and
therefore they are a high priority group to study (6).

Added to this, people with reduced kidney function are systematically
excluded from studies in which the safety and efficacy of drugs is
assessed (7) and so we actually have limited evidence to guide
prescribing in this group.

Deprescribing — the systematic process of stopping or reducing medicines
— is a proposed way of reducing the harms associated with polypharmacy.
However, despite recent KDIGO (Kidney Disease \| Improving Global
Outcomes) CKD practice guidelines containing a new section on
*Medication management and Drug Stewardship*, there is acknowledgment
from the authors that evidence to guide deprescribing is limited (8).

Research has shown that a small number of people with advanced kidney
disease are having medications such as statins and proton pump
inhibitors deprescribed in their last years of life (9), but information
about patterns and predictors of deprescribing at a population level are
lacking.

Other factors that make this an important area to study include:

- Supported by policy - Department of Health and Social Care report on
  reducing overprescribing (10),
- Call for more research into deprescribing - current NIHR call, HDR UK
  Medicines in acute and Chronic disease driver programme
- Importance to patients, prescribers, and health and care services
- James Lind Alliance priority for understanding medicines in older
  life.

# Objectives

1.  To establish the patterns of discontinuation of long-term medicines
    in people in England living with advanced CKD.
2.  To identify the clinical and sociodemographic factors associated
    with variances in these patterns.
3.  To operationalise an appropriate definition of medication
    discontinuation.

In routine healthcare data, deprescribing is largely observable as
medication <u>discontinuation</u>, which will therefore be the primary
focus of this study.

# Methods

## Study design

We will conduct cross-sectional and longitudinal analyses of a
retrospective cohort of individuals living with advanced kidney disease
living in England.

## Data sources

We will analyse the primary care record data of people living in England
that is stored and managed by The Phoenix Partnership (TPP),
specifically through utilisation of the OpenSAFELY-TPP secure analytical
database. We will utilise OpenSAFELY-TPP’s established linkages to:

- Office for National Statistics (ONS) data on registered deaths
- NHS Secondary Uses Service data, which is used to derive ethnicity
  information and to help identify individuals in receipt of KRT

## Study population

This retrospective cohort study will analyse the cohort of individuals
living with advanced kidney disease on 01/03/2022, and then follow up
their prescriptions for the following 4 years.

### Inclusion criteria

Individuals will be included in the cohort if on 01/03/2022 they meet
all the following criteria:

- Alive
- Aged ≥18 and ≤110 years
- Continuous registration at a single GP practice that uses TPP software
  for at least the one year prior.
- Evidence of advanced chronic kidney disease, confirmed by the presence
  of one or both of the following (11):
  - The two most recent serum creatinine measurements that are \>90 days
    apart are consistent with an estimated glomerular filtration rate
    (eGFR) \<30 mls/min/1.73m<sup>2</sup> (calculated using the 2009
    CKD-EPI equation as recommended by the [UK Kidney
    Association](https://www.ukkidney.org/health-professionals/information-resources/uk-eckd-guide/measurement-kidney-function)).
  - SNOMED codes for CKD 4 and 5 as published on
    [OpenCodelists](https://www.opencodelists.org/codelist/user/mletts92/chronic-kidney-disease-stage-4-and-5-but-not-receiving-kidney-replacement-therapy/49c071e2/).

### Exclusion criteria

- People who have been coded to receive kidney replacement therapy (KRT)
  of any sort (dialysis or transplant) prior to the index date, or on
  the index date itself. KRT will be defined using established primary
  and secondary care
  [codes](https://www.opencodelists.org/codelist/opensafely/renal-replacement-therapy/2020-04-14/#full-list)
  that have been shown to be sensitive for identifying the prevalent KRT
  population in England (12).

### Follow up

Study participants will be followed up from the index date until the
earliest of:

- End of maximum follow up period (4 years)
- Death
- Initiation of kidney replacement therapy (dialysis or transplant)
- End of registration with GP practice that uses TPP software

### Data quality assurance criteria

Individuals will only be included if they meet all the following
criteria:

- Known sex that is exactly ‘male’ or ‘female’
- Known date of birth
- Known IMD
- Known ethnicity
- Known STP

## Medication data

In this analysis we will study baseline prescribing on the index date,
and the trends of medication discontinuation over time.

The medication table within OpenSAFELY-TPP contains information for
every medication that is prescribed in primary care. This information is
recorded as ‘date’ of prescription and ‘dictionary of medicines and
devices (dm+d) code’ corresponding to the prescription. Dm+d codes are
the preferred mechanism through which medicinal product identification
and communication occurs within the NHS. In OpenSAFELY, each dm+d code
corresponds to the name (e.g. atorvastatin), strength (e.g. 40mg) and
formulation (e.g. tablet) of a prescribed drug. Data on the dosing
recommendation (e.g. take 1 tablet once a day), the amount of medication
prescribed (e.g. 28 tablets), whether a prescription was issued, or
whether the patient took the medication as prescribed are not available.

### Medication data handling

Each medication will have its dm+d code mapped to its corresponding
British National Formulary (BNF) substance code using publicly available
[mapping
data](https://www.nhsbsa.nhs.uk/prescription-data/understanding-our-data/bnf-snomed-mapping).
BNF codes follow a clear hierarchical structure and allow for clinically
meaningful analysis. Each dm+d code has one or more official routes of
administration, which themselves are coded using unique SNOMED
identifiers. Mapping of these routes will be performed using publicly
available data from [NHS
TRUD](https://isd.digital.nhs.uk/trud/users/guest/filters/0/categories/6)
(Technology Reference data Update Distribution). Each of the 79 official
routes of administration will be mapped to one of the following
categories: oral, topical, inhaled, eye/ear/nasal, oromucosal,
rectal/vaginal, transdermal, intramuscular, intravenous, subcutaneous
and other. Those with multiple licensed routes will be attributed
‘multiple routes’, and those with no licensed routes will be attributed
‘unknown’.

## Baseline medications

When considering which baseline medications to include in our analyses
we have used previously described methods. These suggest categorising
medications for based on their *scope, uniqueness and timeframe* (13).

### Scope

In the primary analysis, drugs within scope will be defined as: - Drug
type - those within BNF chapters 1 to 13. BNF chapters 14 to 23 will be
excluded as they represent specialist medicinal products and medical
devices. - Route - those that are orally administered. This is because
oral medications are the most likely to be deprescribed in this
population.

In sensitivity analyses, we will explore the effect of including drugs
that are administered through other routes. Importantly, it will not be
possible to distinguish PRN (as required) prescriptions from regular
prescriptions, and so all medications will be assumed regular.

### Uniqueness

Combination products have distinct BNF substance codes and so will be
counted as a single drug, which reflects their singular contribution
towards pill count.

### Timeframe

We will analyse medicines that we define as being *chronic*, as these
are more eligible for discontinuation. Chronic prescriptions are those
that a person is prescribed at the study entry and have been prescribed
*regularly* prior to this. There is no consensus regarding how to define
a chronic prescription within electronic health record data.
OpenSAFELY-TPP lacks data to show the clinician-intended duration for
each prescription, however for five common medicines, 92% of
prescriptions appeared to be intended for 28 or 56 days, with the
remainder being for 7 or 84 days (14). In our primary analysis,
considering this variability and to be pragmatic, we will define a
medication as chronic (and include it in our analyses) if it is
prescribed:

- Two or more times within the 180 days prior to study entry, and
- At least once within the most recent 90 days.

Additionally, within those 180 days there must be \>=21 days between the
first and last prescriptions This effect of this definition on results
will be explored through sensitivity analyses.

## Medication discontinuation

Medications prescribed at baseline will be followed longitudinally for
up to 4 years to examine patterns of discontinuation. In line with
previous publications (15), discontinuation will be defined by a gap in
prescribing of a chronic medicine. Initially a gap of ≥90 days will be
used, but sensitivity analyses will explore the effect of using gaps of:
≥30 days, ≥60 days and ≥180 days. The discontinuation date will be
defined as the date after the end of the gap following the last
prescription.

— dose reduction? — — modelling prior gaps? —

## Covariates

The effect of various participant characteristics on prescribing at
study entry and medication discontinuation will be explored. The
characteristics have been chosen for two different reasons:

- It is hypothesised that they will likely have an impact on medication
  discontinuation.
- To promote analytical inclusivity, by exploring variations by
  protected characteristics.

Covariates, which will be defined on the index date are:

- Age
- Sex
- Ethnicity
- eGFR
- Number of chronic prescriptions
- Risk of mortality (see below)
- Frailty (see below)
- Presence or absence of comorbidities

— clinical events? e.g. falls/hospitalisations - probably would need to
be examined longitudinally

### Risk of mortality

The estimated 4-yr risk of mortality at baseline will be estimated using
the mortality prediction tool [CKD
G4+](https://ckdpcrisk.org/lowgfrevents/) (16) referenced in the 2024
KDIGO CKD clinical practice guideline (8). This tool requires the
following clinical and demographic data:

1.  Age (values between 30 and 85)
2.  Sex (male or female)
3.  Race (black or white)
4.  Proteinuria quantification (uPCR or uACR)
5.  Smoking status (current vs never/ex)
6.  Diabetes status (yes or no)
7.  History of cardiovascular disease (yes or no)
8.  eGFR (values between 15 and 30)
9.  Systolic BP (values between 90–180)

Four strata will be viewed: \<25%, 25–49%, 50–74%, ≥75%

### Frailty

Frailty at baseline will be characterised using the electronic frailty
index (eFI — ideally eFI2 (17)) a widely utilised metric for identifying
frailty within electronic health records. Using eFI (or similar) to
identify potentially frail people in primary care in England is a GP
contractual obligation, and those identified as severely frail are
recommended for annual structured medication review according to NHS
England.

Four strata will be viewed: non-frail, mildly frail, moderately frail,
severely frail.

## Statistical methods

## Tables and figures

## Study limitations

# Other information

## Funding

## PPIE

# References

<div id="refs" class="references csl-bib-body">

<div id="ref-Brown2024" class="csl-entry">

<span class="csl-left-margin">1.
</span><span class="csl-right-inline">Brown JP, Hunnicutt JN, Ali MS,
Bhaskaran K, Cole A, Langan SM, et al. Quantifying possible bias in
clinical and epidemiological studies with quantitative bias analysis:
Common approaches and limitations. BMJ. 2024;e076365.
doi:[10.1136/bmj-2023-076365](https://doi.org/10.1136/bmj-2023-076365)</span>

</div>

<div id="ref-Hawthorne2023" class="csl-entry">

<span class="csl-left-margin">2.
</span><span class="csl-right-inline">Hawthorne G, Lightfoot CJ, Smith
AC, Khunti K, Wilkinson TJ. Multimorbidity prevalence and patterns in
chronic kidney disease: Findings from an observational multicentre UK
cohort study. International Urology and Nephrology. 2023;55(8):2047–57.
doi:[10.1007/s11255-023-03516-1](https://doi.org/10.1007/s11255-023-03516-1)</span>

</div>

<div id="ref-vanOosten2021" class="csl-entry">

<span class="csl-left-margin">3.
</span><span class="csl-right-inline">Oosten MJM van, Logtenberg SJJ,
Hemmellder MH, Leegte MJH, Bilo HJG, Jager KJ, et al. Polypharmacy and
medication use in patients with chronic kidney disease with and without
kidney replacement therapy compared to matched controls. Clinical Kidney
Journal. 2021;14(12):2497–523.
doi:[10.1093/ckj/sfab120](https://doi.org/10.1093/ckj/sfab120)</span>

</div>

<div id="ref-Fried2014" class="csl-entry">

<span class="csl-left-margin">4.
</span><span class="csl-right-inline">Fried TR, O’Leary J, Towle V,
Goldstein MK, Trentalange M, Martin DK. Health outcomes associated with
polypharmacy in community-dwelling older adults: A systematic review.
Journal of the American Geriatrics Society. 2014;62(12):2261–72.
doi:[10.1111/jgs.13153](https://doi.org/10.1111/jgs.13153)</span>

</div>

<div id="ref-WHO2023" class="csl-entry">

<span class="csl-left-margin">5.
</span><span class="csl-right-inline">World Health Organization.
Medication without harm: Policy brief. World Health Organization;
2023.</span>

</div>

<div id="ref-Mohottige2021" class="csl-entry">

<span class="csl-left-margin">6.
</span><span class="csl-right-inline">Mohottige D, Manley HJ, Hall RK.
Less is more: Deprescribing medications in older adults with kidney
disease: A review. Kidney360. 2021;2(9):1510–22.</span>

</div>

<div id="ref-Colombijn2024" class="csl-entry">

<span class="csl-left-margin">7.
</span><span class="csl-right-inline">Colombijn JMT, Idema DL, Van Beem
S, Blokland AM, Van Der Braak K, Handoko ML, et al. Representation of
patients with chronic kidney disease in clinical trials of
cardiovascular disease medications. JAMA Network Open.
2024;7(3):e240427.
doi:[10.1001/jamanetworkopen.2024.0427](https://doi.org/10.1001/jamanetworkopen.2024.0427)</span>

</div>

<div id="ref-Stevens2024" class="csl-entry">

<span class="csl-left-margin">8.
</span><span class="csl-right-inline">Stevens PE, Ahmed SB, Carrero JJ,
Foster B, Francis A, Hall RK, et al. KDIGO 2024 clinical practice
guideline for the evaluation and management of chronic kidney disease.
Kidney International. 2024;105(4):S117–314.
doi:[10.1016/j.kint.2023.10.018](https://doi.org/10.1016/j.kint.2023.10.018)</span>

</div>

<div id="ref-Letts2024" class="csl-entry">

<span class="csl-left-margin">9.
</span><span class="csl-right-inline">Letts M, Chesnaye NC, Pippias M,
Caskey F, Jager KJ, Dekker FW, et al. Prescribing patterns in older
people with advanced chronic kidney disease towards the end of life.
Clinical Kidney Journal. 2024.
doi:[10.1093/ckj/sfae301](https://doi.org/10.1093/ckj/sfae301)</span>

</div>

<div id="ref-DHSC2021" class="csl-entry">

<span class="csl-left-margin">10.
</span><span class="csl-right-inline">Health & Social Care UD of. Good
for you, good for us, good for everybody \[Electronic Book\]
\[Internet\]. 2021. Available from:
<https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1019475/good-for-you-good-for-us-good-for-everybody.pdf></span>

</div>

<div id="ref-Sparks2025" class="csl-entry">

<span class="csl-left-margin">11.
</span><span class="csl-right-inline">Sparks C, Steinberg AG, Toussaint
ND. Identifying and characterising a chronic kidney disease
electronic-phenotype using electronic health record-derived data: A
narrative review of strategies and applications. Nephrology.
2025;30(9).</span>

</div>

<div id="ref-Santhakumaran2024" class="csl-entry">

<span class="csl-left-margin">12.
</span><span class="csl-right-inline">Santhakumaran S, Fisher L, Zheng
B, Mahalingasivam V, Plumb L, Parker EPK, et al. Identification of
patients undergoing chronic kidney replacement therapy in primary and
secondary care data: Validation study based on OpenSAFELY and UK renal
registry. BMJ Medicine. 2024;3(1):e000807.
doi:[10.1136/bmjmed-2023-000807](https://doi.org/10.1136/bmjmed-2023-000807)</span>

</div>

<div id="ref-Goedken2016" class="csl-entry">

<span class="csl-left-margin">13.
</span><span class="csl-right-inline">Goedken AM, Lund BC, Cook EA,
Schroeder MC, Brooks JM. Application of a framework for determining
number of drugs. BMC Research Notes. 2016;9(1).
doi:[10.1186/s13104-016-2076-5](https://doi.org/10.1186/s13104-016-2076-5)</span>

</div>

<div id="ref-Mackenna2025" class="csl-entry">

<span class="csl-left-margin">14.
</span><span class="csl-right-inline">Mackenna B, Brown AD, Croker R,
Walker AJ, Goldacre B, Tsiachristas A, et al. Variation in duration of
repeat prescriptions: A primary care cohort study in England. British
Journal of General Practice. 2025;75(756):e448–56.
doi:[10.3399/bjgp.2024.0326](https://doi.org/10.3399/bjgp.2024.0326)</span>

</div>

<div id="ref-Bayliss2025" class="csl-entry">

<span class="csl-left-margin">15.
</span><span class="csl-right-inline">Bayliss EA, Goodrich GK, Barrow
JC, Harding B, Ripley CA, Kraus CR, et al. Discontinuation categories
underlying gaps in dispensing for six medication groups.
Pharmacoepidemiology and Drug Safety. 2025;34(4).
doi:[10.1002/pds.70142](https://doi.org/10.1002/pds.70142)</span>

</div>

<div id="ref-Grams2018" class="csl-entry">

<span class="csl-left-margin">16.
</span><span class="csl-right-inline"><span class="nocase">Grams ME et
al.</span> Predicting timing of clinical outcomes in patients with
chronic kidney disease and severely decreased glomerular filtration
rate. Kidney International. 2018;93(6):1442–51.</span>

</div>

<div id="ref-Best2025" class="csl-entry">

<span class="csl-left-margin">17.
</span><span class="csl-right-inline">Best K, Shuweihdi F, Alvarez JCB,
Relton S, Avgerinou C, Nimmons D, et al. Development and external
validation of the electronic frailty index 2 using routine primary care
electronic health record data. Age and Ageing. 2025;54(4).
doi:[10.1093/ageing/afaf077](https://doi.org/10.1093/ageing/afaf077)</span>

</div>

</div>
