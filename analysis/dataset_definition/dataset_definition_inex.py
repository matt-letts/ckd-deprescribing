from ehrql import create_dataset
from ehrql.tables.tpp import patients
from inex_variables import add_inex_variables
import numpy as np

# define the project-relevant dates
import json
with open("output/study_dates.json") as f:
    study_dates = json.load(f)
index_date = study_dates["index_date"]
end_date = study_dates["end_date"]


# initialise the dataset
np.random.seed(123456)
dataset = create_dataset()
dataset.configure_dummy_data(population_size=1000)
dataset.define_population(patients.date_of_birth.is_not_null())

add_inex_variables(dataset, index_date)

# recent_medication_counts() also hidden from primary dataset definition. Can consider whether to add in at later stage.
# add_prescription_columns(dataset, index_date, max_meds=3) - hidden for now
# ckd = compute_ckd_variables(index_date) - hidden for now

# opensafely exec ehrql:v1 generate-dataset analysis/dataset_definition/dataset_definition_inex.py --dummy-tables dummy_tables --output output/dummy_dataset.arrow
# opensafely exec ehrql:v1 generate-dataset analysis/dataset_definition/dataset_definition_inex.py --output output/dataset.csv.gz