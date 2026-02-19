from datetime import date
from dataset_definition import dataset

test_data = {
    # Expected in population with matching medication
    1: {
        "patients": {"date_of_birth": date(1950, 1, 1)},
        "medications": [
            {
                # First matching medication
                "date": date(2010, 1, 1),
                "dmd_code": "39113311000001107",
            },
            {
                # Latest matching medication before index_date
                "date": date(2020, 1, 1),
                "dmd_code": "39113311000001107",
            },
            {
                # Most recent matching medication, but after index_date
                "date": date(2023, 6, 1),
                "dmd_code": "39113311000001107",
            },
        ],
        "expected_in_population": True,
        "expected_columns": {
            "age": 73,
            "has_asthma_med": True,
            "latest_asthma_med_date": date(2020, 1, 1),
        },
    },
    # Expected in population without matching medication
    2: {
        "patients": [{"date_of_birth": date(1950, 1, 1)}],
        "medications": [],
        "expected_in_population": True,
        "expected_columns": {
            "age": 73,
            "has_asthma_med": False,
            "latest_asthma_med_date": None,
        },
    },
    # Not expected in population
    3: {
        "patients": [{"date_of_birth": date(2010, 1, 1)}],
        "medications": [],
        "expected_in_population": False,
    },
}