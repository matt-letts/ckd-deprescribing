###################################################################################
# This script manually writes config/medication_of_interest.csv
# I've written this separately for portability/clarity
# The resulting .csv is then read by python/R scripts

# Needs to be manually run whenever a medication of interest is added
###################################################################################

# Import libraries ----------------------------------------------------------
library(here)
library(tidyverse)

# Define medications of interest --------------------------------------------
# codelist_file must exist under codelists/

medication_of_interest_list <- c(
  statins = "codelists/bristol-statins-dmd.csv"
)

# Build resulting csv -------------------------------------------------------
result <- tibble(
  name = names(medication_of_interest_list),
  codelist_path = medication_of_interest_list
)

write_csv(
  result,
  here::here("analysis", "config", "medication_of_interest.csv")
)
