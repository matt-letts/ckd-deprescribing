##########################################################################
# This script does the following:
# 1. Reads study dates from output/study_dates.json
# 2. Defines medication_of_interest parameter which defines the dataset
#    to be pulled in and the dmd_codelist to use
# 3. Filters the population to patients in dataset_{medication}_at_baseline
# 3. Calls add_moi_followup_prescription_columns() 
#
# Output: dataset_discont_[medication]_followup.arrow
#         (see yaml: generate_dataset_discont_meds_followup_{medication})
# Test: test_dataset_definition_discont_meds_followup.py
##########################################################################

from ehrql import create_dataset, table_from_file, get_parameter
from codelists import medication_of_interest_codelists
from fn_discont_meds_variables import add_followup_moi_prescription_columns
import json

# define the project-relevant dates
with open("output/study_dates.json") as f:
    study_dates = json.load(f)
index_date = study_dates["index_date"]
end_date = study_dates["end_date"]

# define medication parameter and pull specific codelist from dict
medication = get_parameter(name="medication", type=str, default="")
dmd_codelist = medication_of_interest_codelists[medication]

# load dataset of individuals prescribed medication_of_interest at baseline
dataset_moi_at_baseline = table_from_file(
    f"output/data/dataset_{medication}_at_baseline_processed.arrow",
    columns={
        "days_before_index_most_recent_prescription": int
        },
)

# initialise new dataset
dataset = create_dataset()
dataset.define_population(dataset_moi_at_baseline.exists_for_patient())

dataset.add_column(
    f"med_{medication}_num_days_last_before_index",
    dataset_moi_at_baseline.days_before_index_most_recent_prescription,
)

add_followup_moi_prescription_columns(dataset, index_date, end_date, dmd_codelist, max_meds=90)
