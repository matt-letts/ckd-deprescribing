from ehrql import create_dataset, show
from ehrql.tables.core import patients

age = patients.age_on("2022-01-01")

show(age, patients.date_of_birth, label="Age")
dataset = create_dataset()
dataset.define_population(age >= 18)
dataset.age = age
show(dataset)