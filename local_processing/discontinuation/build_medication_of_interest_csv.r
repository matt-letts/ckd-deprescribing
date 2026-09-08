###################################################################################
# This script builds analysis/config/medication_of_interest.csv - the central
# reference of medications of interest and their OpenCodelists dm+d codelists
#
# Runs outside the OpenSAFELY pipeline
###################################################################################

# Import libraries --------------------------------------------------------------
library(here)
library(tidyverse)

# Define medications of interest -----------------------------------------
# codelist_path must exist in codelists/

medication_of_interest_list <- c(
  statins = "codelists/bristol-statins-dmd.csv",
  ppis = "codelists/bristol-proton-pump-inhibitors-dmd.csv"
)

# Build csv that contains central references of medications of interest ----------
result <- tibble(
  name = names(medication_of_interest_list),
  codelist_path = medication_of_interest_list
)

write_csv(
  result,
  here::here("analysis", "config", "medication_of_interest.csv")
)
