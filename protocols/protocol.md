# Protocol: Descriptive Analysis of Deprescribing Patterns for People Living with Advanced Chronic Kidney Disease
Matthew Letts<sup>1,2</sup>, Robert Porteous<sup>1</sup>, Rachel
Denholm<sup>1</sup>, Rupert Payne<sup>3</sup>, Jonathan
Sterne<sup>1</sup>, Fergus Caskey<sup>2</sup>
24 June 2026

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

Ninety-eight percent of people living with chronic kidney disease stages
4 and 5 not receiving kidney replacement therapy - CKD 4/5 - live with
multiple long-term conditions (2). Resultantly, polypharmacy is highly
prevalent - this group are prescribed on average 8-9 medicines per day
(and \>100 pills per week) (3). Polypharmacy is well linked to avoidable
harms such as falls and hospitalisations (4) so managing it safely is a
key action area within the World Health Organisation’s active global
patient safety challenge: *Medication Without Harm* (5). For people with
CKD 4/5, the risk of medication-related harm is augmented by
unpredictable drug handling and excretion - 1 in 5 experience a
medication-related harm each year (6), making them a high priority group
to study (7). Added to this, clinical trials that establish the safety
and effectiveness of medicines often exclude people living with CKD 4/5,
and do not reflect their comorbidity and diversity (8).

Deprescribing - the systematic process of stopping or reducing
medicines - is a proposed way of reducing the harms associated with
polypharmacy. Within the recently updated KDIGO (Kidney Disease \|
Improving Global Outcomes) CKD practice guideline there is a new chapter
entitled *Medication management and Drug Stewardship*, however this
includes an acknowledgment that evidence to guide deprescribing is
limited (9). We have shown that a proportion of people with advanced
kidney disease are having medications such as statins discontinued in
their last years of life (10), but wider-scale information is lacking.
Currently there is little guidance for clinicians about what medicines
can be deprescribed and when.

We aim to describe the current patterns of discontinuation of common
medicines in people living with advanced CKD in England, and evaluate
the clinical and sociodemographic factors that lead to variances in
these patterns. In routine healthcare data, deprescribing is largely
observable as medication *discontinuation*, which will therefore be the
primary focus of this study.

# Objectives

1.  To describe patterns of prescribing at a national level for people
    living with advanced CKD
2.  To establish the patterns of discontinuation of medicines in people
    in England living with advanced CKD.
3.  To identify the clinical and sociodemographic factors associated
    with variances in these patterns.

# Methods

## Study design

We will conduct cross-sectional and longitudinal analyses of a
retrospective cohort of individuals living with advanced kidney disease
living in England.

## Data sources

We will analyse the primary care record data of people living in England
that is stored and managed by The Phoenix Partnership (TPP),
specifically through the OpenSAFELY-TPP secure analytical platform. We
will utilise OpenSAFELY-TPP’s established linkages to:

- Office for National Statistics (ONS) data on registered deaths
- NHS Secondary Uses Service data, which includes information regarding
  hospital admissions, and is used to derive each individual’s ethnicity
- Data on Index of Multiple Deprivation (IMD)

## Study population

This retrospective cohort study will analyse the cohort of individuals
living with CKD 4/5 on 01/03/2022 (the **‘index date’**), and then
follow up their prescriptions for the following 4 years.

### Inclusion criteria

Individuals will be included in the cohort if on the index date they
meet all the following criteria:

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
  - A SNOMED code indicating a diagnosis of CKD 4 and 5
    ([OpenCodelists](https://www.opencodelists.org/codelist/user/mletts92/chronic-kidney-disease-stage-4-and-5-but-not-receiving-kidney-replacement-therapy/49c071e2/))
    on any prior date.

### Exclusion criteria

- People in receipt of kidney replacement therapy (KRT). This is defined
  as a
  [code](https://www.opencodelists.org/codelist/opensafely/renal-replacement-therapy/2020-04-14/#full-list)
  indicating dialysis or transplant prior to the index date, or on the
  index date itself. This method has been shown to be sensitive for
  identifying the prevalent KRT population in England (12).

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
- Known year of birth
- (Known IMD
- Known ethnicity
- Known STP) - *I’m not sure about these bottom three - they may well
  exclude people unnecessarily*

## Prescribing

### Prescribing data

In this analysis we will study baseline prescribing on the index date,
and the trends of medication discontinuation over time.

The medication table within OpenSAFELY-TPP contains information for
every medication that is prescribed in primary care. Each prescription
is recorded using its corresponding NHS dictionary of medicines and
devices (dm+d) code and corresponding date. [dm+d
codes](https://digital.nhs.uk/data-and-information/information-standards/governance/latest-activity/standards-and-collections/scci0052-dictionary-of-medicines-and-devices-dm-d/)
are the preferred mechanism through which medicinal product
identification and communication occurs within the NHS. In OpenSAFELY,
each dm+d code corresponds to the name (e.g. atorvastatin), strength
(e.g. 40mg) and formulation (e.g. tablet) of a prescribed drug. Data on
the dosing recommendation (e.g. take 1 tablet once a day), the quantity
of a medication prescribed (e.g. 28 tablets), whether a prescription was
dispensed, or whether the patient adhered to the medication as
prescribed are not available.

### Prescribing data handling

Each dm+d code has one or more official routes of administration and
these will be mapped to the study data using publicly available [NHS
TRUD](https://isd.digital.nhs.uk/trud/users/guest/filters/0/categories/6)
(Technology Reference data Update Distribution) reference files. Each of
the 79 official routes of administration will be mapped according to
author consensus to one of the following categories: oral, topical,
inhaled, eye/ear/nasal, oromucosal, rectal/vaginal, transdermal,
intramuscular, intravenous, subcutaneous and other. If a dm+d code has
multiple licensed routes it will be classified ‘multiple routes’, and if
no licensed routes, ‘unknown’.

Each medication will then have its dm+d code mapped to its corresponding
British National Formulary (BNF) substance code using publicly available
[mapping
data](https://www.nhsbsa.nhs.uk/prescription-data/understanding-our-data/bnf-snomed-mapping).
BNF codes follow a clear hierarchical structure and allow for clinically
meaningful analysis.

### Medication inclusion / exclusion criteria

Medicines will be included / excluded in our analysis by considering
their *scope, uniqueness and timeframe* (13).

#### Scope

We will include medications based on their drug type and route.

- Drug type. We will include medications within BNF chapters 1 to 13.
  BNF chapters 14 to 23 will be excluded as they represent specialist
  products that are unlikely to be common and not targets for
  discontinuation, and medical devices.
- Route. We will include medications that are orally administered. This
  is because oral medications are the most likely to be deprescribed in
  this population.

It will not be possible to distinguish PRN (as required) prescriptions
from regular prescriptions, and so all medications will be assumed
regular.

#### Uniqueness

Combination products have distinct dm+d and BNF substance codes and so
will be counted as a single drug.

#### Timeframe

Conceptually, for a medicine to be discontinued, it must be first in
*chronic* use, i.e. being used on the index date, and regularly prior to
that. There is no consensus regarding how to define a chronic
prescription within electronic health record data. OpenSAFELY-TPP lacks
data to show the clinician-intended duration for each prescription, and
therefore assumptions about the length of each prescription are required
to establish what a person could have been taking on any given date. It
has previously been shown that for five of the commonest medicines, 92%
were prescribed for 28 or 56 days, with the remainder being prescribed
for 7 or 84 days (14).

Considering this variability, we will define a medication as chronic,
and include it in our analyses, if all of the following are true:

- In the 180 days prior to the index date:
  - It is prescribed two or more times (*regular*)
  - There are \>=21 days between the oldest and the most recent
    prescriptions (*sustained*)
- In the 90 days prior to the index date:
  - It is prescribed once or more (*recent*)

## Outcome - Medication Discontinuation

Medications prescribed at baseline will be followed longitudinally for
up to 4 years to examine patterns of discontinuation.

Within OpenSAFELY-TPP the duration of each prescription is unknown. In
line with previous publications (15), discontinuation will be defined as
a gap of a prescription of a chronic medicine of 120 days or more. This
will allow a window of time for re-prescription to occur even if the
prescription was issued for 84 days (the maximum length in usual
practice in England). The date of discontinuation will be defined as the
date of the last prescription.

*This needs discussion - could this be operationalised better? We could
look at dose reduction, or something more complex modelling prior gaps*

## Covariates

Covariates have been chosen for two different reasons:

- It is hypothesised that they will likely have an impact on medication
  discontinuation.
- To promote analytical inclusivity, by exploring variations by
  protected characteristics.

Covariates, which will be defined on the index date, are described in
the table below.

<table style="width:99%;">
<colgroup>
<col style="width: 31%" />
<col style="width: 17%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr>
<th><strong>Covariate</strong></th>
<th><strong>Type</strong></th>
<th><strong>Definition</strong></th>
</tr>
</thead>
<tbody>
<tr>
<td>Age</td>
<td>Continuous</td>
<td><p>Age in years calculated from year of birth Will be modelled using
splines</p>
<p>Strata: 18–49, 50–64, 65–74, 75–84, ≥85</p></td>
</tr>
<tr>
<td>Sex</td>
<td>Categorical</td>
<td>Male or female</td>
</tr>
<tr>
<td>Ethnicity</td>
<td>Categorical</td>
<td><p>Derived from GP record and NHS Secondary Uses Service data, using
the most recent non-missing value. Strata:</p>
<p>White<br />
Mixed / Multiple ethnic<br />
Asian / Asian British<br />
Black / African / Caribbean / Black British<br />
Other ethnic group<br />
Not stated / Not known<br />
</p></td>
</tr>
<tr>
<td>Deprivation</td>
<td>Categorical</td>
<td>Deciles of Index of Multiple Deprivation (IMD) based on address on
index date</td>
</tr>
<tr>
<td>eGFR</td>
<td>Continuous</td>
<td>Estimated glomerular filtration rate on the index date, calculated
from the most recent serum creatinine using the 2009 CKD-EPI
equation.</td>
</tr>
<tr>
<td>Number of chronic prescriptions</td>
<td>Continuous</td>
<td>Count of distinct included chronic medications on the index
date,</td>
</tr>
<tr>
<td>Region</td>
<td>Categorical</td>
<td>East of England<br />
London<br />
Midlands<br />
North East and Yorkshire<br />
North West<br />
South East<br />
South West<br />
</td>
</tr>
<tr>
<td>Frailty</td>
<td>Categorical</td>
<td><p>Characterised using the electronic frailty index (eFI, ideally
eFI2 <span class="citation" data-cites="Best2025">(16)</span>), a widely
used metric for identifying frailty in electronic health records.</p>
<p>Strata: non-frail, mildly frail, moderately frail, severely
frail</p></td>
</tr>
<tr>
<td>Care home status</td>
<td>Binary</td>
<td>Using TPP’s algorithm to determine if a person is a likely care home
resident</td>
</tr>
<tr>
<td>Consultation rate</td>
<td>Continuous</td>
<td>Number of GP consultations 12 months prior to the index date</td>
</tr>
<tr>
<td>Dementia</td>
<td>Binary</td>
<td>1 if diagnosis present; 0 otherwise</td>
</tr>
<tr>
<td>Liver disease</td>
<td>Binary</td>
<td>1 if diagnosis present; 0 otherwise</td>
</tr>
<tr>
<td>Cancer</td>
<td>Categorical</td>
<td>1 if diagnosis present; 0 otherwise</td>
</tr>
<tr>
<td>Diabetes</td>
<td>Binary</td>
<td>1 if diagnosis present; 0 otherwise</td>
</tr>
<tr>
<td>COPD</td>
<td>Binary</td>
<td>1 if diagnosis present; 0 otherwise</td>
</tr>
<tr>
<td>Previous cardiovascular disease</td>
<td>Binary</td>
<td>fill in</td>
</tr>
</tbody>
</table>

### Other covariates

Risk of mortality \| Continuous / \| Estimated 4-year risk of mortality
\|  
                           \| categorical \| using the CKD G4+
prediction tool \|  
                           \| \| (17). This tool is suggested for use
\|  
                           \| \| in the 2024 KDIGO CKD management
guideline \|  
                           \| \| (9). It requires 8 variables:Requires:
age (30–85), \|  
                           \| \| sex, race (black or white), \|  
                           \| \| proteinuria (uPCR or uACR), smoking
\|  
                           \| \| status, diabetes status, history of
\|  
                           \| \| cardiovascular disease, eGFR (15–30),
\|  
                           \| \| systolic BP (90–180). \|  
                           \| \| \|  
                           \| \| Strata: \<25%, 25–49%, 50–74%, ≥75% \|

## Statistical methods

### Sensitivity analysis

In sensitivity analyses, we will explore the effect of including drugs
that are administered through other routes. This effect of varying the
definition of chronic medicines on results will be explored through
sensitivity analyses. , but sensitivity analyses will explore the effect
of using gaps of: ≥30 days, ≥60 days and ≥180 days.

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

<div id="ref-Laville2020" class="csl-entry">

<span class="csl-left-margin">6.
</span><span class="csl-right-inline"><span class="nocase">Laville SM,
Gras-Champel V, Moragny J, Metzger M, Jacquelinet C, Combe C, et
al.</span> Adverse drug reactions in patients with CKD \[Journal
Article\]. Clinical Journal of the American Society of Nephrology.
2020;15(8):1090–102.
doi:[10.2215/cjn.01030120](https://doi.org/10.2215/cjn.01030120)</span>

</div>

<div id="ref-Mohottige2021" class="csl-entry">

<span class="csl-left-margin">7.
</span><span class="csl-right-inline">Mohottige D, Manley HJ, Hall RK.
Less is more: Deprescribing medications in older adults with kidney
disease: A review. Kidney360. 2021;2(9):1510–22.</span>

</div>

<div id="ref-Colombijn2024" class="csl-entry">

<span class="csl-left-margin">8.
</span><span class="csl-right-inline">Colombijn JMT, Idema DL, Van Beem
S, Blokland AM, Van Der Braak K, Handoko ML, et al. Representation of
patients with chronic kidney disease in clinical trials of
cardiovascular disease medications. JAMA Network Open.
2024;7(3):e240427.
doi:[10.1001/jamanetworkopen.2024.0427](https://doi.org/10.1001/jamanetworkopen.2024.0427)</span>

</div>

<div id="ref-Stevens2024" class="csl-entry">

<span class="csl-left-margin">9.
</span><span class="csl-right-inline">Stevens PE, Ahmed SB, Carrero JJ,
Foster B, Francis A, Hall RK, et al. KDIGO 2024 clinical practice
guideline for the evaluation and management of chronic kidney disease.
Kidney International. 2024;105(4):S117–314.
doi:[10.1016/j.kint.2023.10.018](https://doi.org/10.1016/j.kint.2023.10.018)</span>

</div>

<div id="ref-Letts2024" class="csl-entry">

<span class="csl-left-margin">10.
</span><span class="csl-right-inline">Letts M, Chesnaye NC, Pippias M,
Caskey F, Jager KJ, Dekker FW, et al. Prescribing patterns in older
people with advanced chronic kidney disease towards the end of life.
Clinical Kidney Journal. 2024.
doi:[10.1093/ckj/sfae301](https://doi.org/10.1093/ckj/sfae301)</span>

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

<div id="ref-Best2025" class="csl-entry">

<span class="csl-left-margin">16.
</span><span class="csl-right-inline">Best K, Shuweihdi F, Alvarez JCB,
Relton S, Avgerinou C, Nimmons D, et al. Development and external
validation of the electronic frailty index 2 using routine primary care
electronic health record data. Age and Ageing. 2025;54(4).
doi:[10.1093/ageing/afaf077](https://doi.org/10.1093/ageing/afaf077)</span>

</div>

<div id="ref-Grams2018" class="csl-entry">

<span class="csl-left-margin">17.
</span><span class="csl-right-inline"><span class="nocase">Grams ME et
al.</span> Predicting timing of clinical outcomes in patients with
chronic kidney disease and severely decreased glomerular filtration
rate. Kidney International. 2018;93(6):1442–51.</span>

</div>

</div>
