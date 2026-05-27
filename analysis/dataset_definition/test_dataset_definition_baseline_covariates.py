##########################################################################
# Test data for dataset_definition_baseline_covariates.py
#
# This test checks the performance of add_baseline_covariate_variables()
#
# opensafely exec ehrql:v1 assure analysis/dataset_definition/test_dataset_definition_baseline_covariates.py
##########################################################################

from datetime import date
from dataset_definition_baseline_covariates import dataset

test_data = {

}

# need to test MI OPCS4 codes that are 4 characters long
# and test the IMD and ethnicity logic