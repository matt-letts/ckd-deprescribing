from ehrql.tables.core import (
    patients
)

from variable_helper_functions import (
    get_imd,
    get_latest_ethnicity
)

index_date = "2022-03-01"

### sex
cov_cat_sex = patients.sex

### ethnicity
cov_cat_ethnicity = get_latest_ethnicity(index_date, ethnicity_snomed, grouping=6)

### deprivation
cov_cat_imd = get_imd(index_date, groups = 10, max_imd=32844)

### care home
# cov_boolean_care_home --> this needs writing 
# addresses.care_home_is_potential_match
# addresses.care_home_requires_nursing
# addresses.care_home_does_not_require_nursing