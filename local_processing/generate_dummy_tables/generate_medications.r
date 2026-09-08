# This script tries to generate a fairly realistic medications.csv dummy table
# It needs a patients.csv table with a patient_id column in it.
library(dplyr)
library(readr)
library(arrow)
library(tictoc)

source(here::here("analysis", "config", "config.r"))
study_dates <- lapply(study_dates, function(x) as.Date(x))

# A broad set of real DMD VMP/AMP codes covering common drug classes
# Edge cases are:
# Those without BNF mapping
# With BNF but no VTM (e.g. ileostomy bag)
# With neither BNF nor VTM (e.g. hydrocolloid dressing)
# Fake code
# Combination products
# Same drug but different strengths

COMMON_DMD_CODES <- c(
  # Statins
  "4466911000001104",
  "5509611000001104", # lacking BNF map
  "30132511000001101",
  "42382011000001103", # simvastatin and ezetimibe combination
  # ACE inhibitors / ARBs
  "414411000001109",
  "15107811000001101",
  "8346911000001104",
  # Beta blockers
  "8394111000001103",
  "42315911000001105",
  "8668611000001109",
  # Calcium channel blockers
  "7391311000001109",
  "188711000001108",
  "19612111000001102", # lacking BNF map
  # Diuretics
  "42294711000001100", # furosemide
  "42206611000001103", # bendroflumethiazide
  "508011000001102", # spironolactone
  # Antiplatelets
  "39689111000001106",
  "765111000001108",
  "19527211000001106", # lacking BNF map
  # Anticoagulants
  "42217611000001104",
  "42206411000001101",
  "29903211000001100",
  "38968711000001103", # ibuprofen
  # Antidepressants (other)
  "42271511000001101",
  "35901511000001106",
  # Antidiabetics (oral)
  "8524111000001108",
  "37437811000001105", # lacking BNF map
  "19525211000001103",
  # Insulin
  "3283211000001100",
  "30171811000001105",
  "3284911000001106",
  # Proton pump inhibitors
  "5603811000001107", # lacking BNF map
  "29975611000001108",
  "42353711000001101",
  # Thyroid - including two of the same drug as per clinical practice
  "8584011000001100", # levothyroxine 100 solution
  "8584811000001106", # levothyroxine 150 solution
  "8802011000001106", # carbimazole
  # Inhalers (SABA)
  "9207411000001106",
  "45111000001100",
  # Antiepileptics
  "10547411000001107", # missing BNF map
  "39107811000001107",
  # Bone protection (bisphosphonates)
  "18264111000001108",
  # Renal medicines
  "37062311000001101",
  "41988711000001107",
  "805411000001100",
  "41984711000001104",
  # Pain (opioids)
  "36126811000001109",
  # Fake code that is missing altogether
  "33018111000001101",
  # Missing VTM, but having BNF
  "6335211000001106", # ileostomy bag
  # Missing VTM and BNF
  "5628111000001102" # hydrocolloid dressing
)

generate_medications <- function(
  patients,
  restrict_to_patient_ids = NULL,
  dmd_codes = COMMON_DMD_CODES,
  start_date = as.Date("2020-06-01"),
  end_date = as.Date("2026-03-01"),
  mean_meds = 10, # true polypharmacy levels, up from 3 (was kept low for speed)
  sd_meds = 3,
  # 7/14/28/56/84 day gaps, weighted toward 28/56 to match typical UK
  # primary-care repeat-prescribing practice
  issue_intervals = c(7, 14, 28, 28, 56, 56, 84),
  interval_jitter = 8, # a bit more real-world noise than before (was 5)
  patient_interval_prob = 0.8, # 80% of a person's medicines prescribed at the same interval
  stop_prob = 0.03,
  new_med_prob = 0.2,
  seed = NULL
) {
  if (!is.null(seed)) {
    set.seed(seed)
  }

  if (!is.null(restrict_to_patient_ids)) {
    patients <- patients |> filter(patient_id %in% restrict_to_patient_ids)
    message(nrow(patients), " patients after restricting to cleaned dataset")
  }

  # pre-allocate generously: up to 20 meds x ~44 issues over the full
  # study window at these settings
  all_rows <- vector("list", nrow(patients) * 1000)
  row_id <- 1 # start

  for (i in seq_len(nrow(patients))) {
    patient_id <- patients$patient_id[i]

    # How many medicines does this patient take?
    n_meds <- round(rnorm(1, mean = mean_meds, sd = sd_meds))
    n_meds <- max(0, min(20, n_meds)) # a number between 0 and 20
    if (n_meds == 0) {
      next
    }

    # patient-level dispensing pattern (monthly or 3-monthly)
    patient_interval <- sample(issue_intervals, 1)

    intervals <- ifelse(
      runif(n_meds) < patient_interval_prob,
      patient_interval,
      sample(issue_intervals, n_meds, replace = TRUE)
    )

    # Assign medicines and medication intervals
    codes <- sample(dmd_codes, n_meds, replace = FALSE)

    # Medicines start on or shortly after study start (random offset up to 180 days)
    patient_start <- start_date + sample(0:180, 1)
    current_dates <- rep(patient_start, n_meds)
    active <- rep(TRUE, n_meds)

    # Now generate the prescriptions
    while (any(active & current_dates <= end_date)) {
      # Group same-day prescriptions under one consultation
      active_today <- which(active & current_dates <= end_date)

      # Find medicines due today (the earliest date among active medicines)
      next_date <- min(current_dates[active_today])
      due_today <- active_today[current_dates[active_today] == next_date]

      consult_id <- sample(100000:999999, 1) # shared consultation for same-day

      for (j in due_today) {
        all_rows[[row_id]] <- list(
          patient_id = patient_id,
          date = next_date,
          dmd_code = codes[j],
          consultation_id = consult_id
        )
        row_id <- row_id + 1

        # Advance to next issue date with jitter
        jitter <- round(rnorm(1, 0, interval_jitter))
        current_dates[j] <- current_dates[j] + max(1, intervals[j] + jitter)

        # Randomly stop this medicine
        if (runif(1) < stop_prob) {
          active[j] <- FALSE
        }
      }

      # Randomly start a new medicine (checked once per consultation)
      daily_prob <- 1 - (1 - new_med_prob)^(1 / 365)
      if (runif(1) < daily_prob && sum(active) < 20) {
        new_code <- sample(setdiff(dmd_codes, codes), 1)
        new_interval <- ifelse(
          runif(1) < patient_interval_prob,
          patient_interval,
          sample(issue_intervals, 1)
        )
        codes <- c(codes, new_code)
        intervals <- c(intervals, new_interval)
        current_dates <- c(current_dates, next_date)
        active <- c(active, TRUE)
      }
    }
  }

  # Assemble and return
  medications <- bind_rows(all_rows[seq_len(row_id - 1)]) %>%
    arrange(patient_id, date) %>%
    mutate(date = as.Date(date))

  medications
}

# if calling ids from dataset_inex_cleaned
cleaned <- read_feather(here::here(
  "output",
  "data",
  "dataset_inex_cleaned.arrow"
))

# if calling in from dummy table
patients <- read_delim_arrow(
  here::here("dummy_tables", "patients.csv"),
  delim = ","
)

# Restrict generation to the cleaned (post-inex) cohort for speed, but
# inject one patient who exists in the full population and was excluded
# by inex — a check that rich medication data for an excluded patient
# never leaks into cohort-based outputs downstream.
set.seed(123)
excluded_patient_ids <- setdiff(patients$patient_id, cleaned$patient_id)
check_excluded_id <- sample(excluded_patient_ids, 1)
restrict_ids <- c(cleaned$patient_id, check_excluded_id)
message(
  "Injected excluded patient_id ",
  check_excluded_id,
  " as a leakage check — should never appear in downstream cohort outputs"
)

# Spans the whole study follow-up, for testing post-baseline/discontinuation
# logic - always used as medications.csv (no separate short version).
tic()
medications <- generate_medications(
  patients = patients,
  restrict_to_patient_ids = restrict_ids,
  start_date = as.Date("2020-06-01"),
  end_date = study_dates$end_date,
  seed = 123
)
toc()

write.csv(
  medications,
  here::here("dummy_tables", "medications.csv"),
  row.names = FALSE,
  na = ""
)
