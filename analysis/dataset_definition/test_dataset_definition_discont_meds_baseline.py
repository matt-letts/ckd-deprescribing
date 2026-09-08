###########################################################################
# Test data for dataset_definition_discont_meds_baseline.py
#
# This test checks the performance of add_baseline_moi_prescription_columns()
# / add_moi_prescriptions() which are the main part of this dataset_def
#
# Written using parameter medication="statins". 
# The extraction logic is identical regardless of medication
#
# opensafely exec ehrql:v1 assure analysis/dataset_definition/test_dataset_definition_discont_meds_baseline.py -- --medication statins
###########################################################################

from datetime import date
from dataset_definition_discont_meds_baseline import dataset

test_data = {

    1: {    # NOT in dataset_inex_cleaned - should not be in population
        "patients": {
            "date_of_birth": date(1990, 1, 1),
            },

        "medications": [],

        "expected_in_population": False,
    },


    4: {    # only a non-statin medication
        "patients": {
            "date_of_birth": date(1990, 1, 1),
            },

        "medications": [
            {
                "date": date(2022, 1, 15),
                "dmd_code": "360711000001100",  # Lisinopril - NOT in statins codelist
            },
        ],

        "expected_in_population": True,
        "expected_columns": {
            "med_dmd_code_1": None,
            "med_date_1": None,
        },
    },

    
    6: {    # tests days_before_index=200 and
            # index_date window boundaries (index_date = 2022-03-01)
        "patients": {
            "date_of_birth": date(1990, 1, 1),
            },

        "medications": [
            {
                "date": date(2021, 8, 13),  # exactly 200 days before index - included
                "dmd_code": "35031911000001104",
            },
            {
                "date": date(2021, 8, 12),  # 201 days before index - excluded
                "dmd_code": "35034411000001109",
            },
            {
                "date": date(2022, 3, 1),  # index_date itself - included
                "dmd_code": "35039511000001107",
            },
            {
                "date": date(2022, 3, 2),  # day after index_date - excluded
                "dmd_code": "41218111000001107",
            },
            {
                "date": date(2021, 12, 1), # couple more for good luck
                "dmd_code": "41218111000001107",
            },
            {
                "date": date(2021, 11, 1),
                "dmd_code": "41218111000001107",
            },
        ],

        "expected_in_population": True,
        "expected_columns": {
            # backward direction: most recent qualifying prescription first
            "med_dmd_code_1": "35039511000001107",
            "med_date_1": date(2022, 3, 1),
            "med_dmd_code_2": "41218111000001107",
            "med_date_2": date(2021, 12, 1),
            "med_dmd_code_3": "41218111000001107",
            "med_date_3": date(2021, 11, 1),
            "med_dmd_code_4": "35031911000001104",
            "med_date_4": date(2021, 8, 13),
            "med_dmd_code_5": None,
            "med_date_5": None,
        },
    },


    9: {    # in dataset_inex_cleaned - one statin and one non-statin in window
        "patients": {
            "date_of_birth": date(1990, 1, 1),
            },

        "medications": [
            {
                "date": date(2022, 1, 1),
                "dmd_code": "42297211000001100",  # Rosuvastatin 10mg tablets (VMP) - in statins codelist
            },
            {
                "date": date(2022, 1, 15),
                "dmd_code": "360711000001100",  # Lisinopril 20mg tablets - NOT in statins codelist
            },
        ],

        "expected_in_population": True,
        "expected_columns": {
            # non-statin medication should be filtered out entirely
            "med_dmd_code_1": "42297211000001100",
            "med_date_1": date(2022, 1, 1),
            "med_dmd_code_2": None,
            "med_date_2": None,
        },
    },
}
