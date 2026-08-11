##########################################################################
# This script does the following:
# 1. Reads study dates from output/study_dates.json
# 2. Defines medication_of_interest parameter which defines the dataset
#    to be pulled in and the dmd_codelist to use
# 3. Filters the population to patients in dataset_{medication}_at_baseline
# 3. Calls add_followup_prescription_columns() 

# To add more medications:
# - build a new dmd codelist and add to codelists/ 
# - use local_processing/build_expanded_moi_codelists.r to add
#   a new row to config/medications_of_interest.csv. This automatically
#     - adds to the python codelist dict being made in codelists.py
#     - adds to build_moi_dataset_at_baseline.r loop
# - add a new output line to build_moi_datasets_at_baseline
# - add a new parameterised generate_dataset_followup_meds_ action to project.yaml
#
# Output: dataset_followup_meds.arrow 
#         (see yaml: generate_dataset_followup_meds_{medication})
# Test: test_dataset_definition_followup_meds.py
##########################################################################

from ehrql import create_dataset, table_from_file, get_parameter
from codelists import medication_of_interest_codelists
from fn_followup_meds_variables import add_followup_prescription_columns
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
    f"output/data/dataset_{medication}_at_baseline.arrow",
    columns={
        "days_before_index_most_recent_prescription": int
        },
)

# initialise new dataset
dataset = create_dataset()
dataset.define_population(dataset_moi_at_baseline.exists_for_patient())

add_followup_prescription_columns(dataset, index_date, end_date, dmd_codelist, max_meds=20)
