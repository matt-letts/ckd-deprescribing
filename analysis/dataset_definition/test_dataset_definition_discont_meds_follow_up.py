###########################################################################
# Test data for dataset_definition_discont_meds_follow_up.py
#
# This test checks the performance of add_followup_moi_prescription_columns()
# / add_moi_prescriptions() from dataset_def
#
# Written against parameter - medication="statins" 
# The extraction logic is identical regardless of medication
#
# opensafely exec ehrql:v1 assure analysis/dataset_definition/test_dataset_definition_discont_meds_follow_up.py -- --medication statins
###########################################################################

from datetime import date
from dataset_definition_discont_meds_follow_up import dataset

test_data = {

    4: {    # in dataset_inex_cleaned but NOT chronically prescribed statins
        "patients": {
            "date_of_birth": date(1990, 1, 1),
            },

        "medications": [],

        "expected_in_population": False,
    },


    9: {    # tests index_date/end_date boundaries (index_date = 2022-03-01,
            # end_date = 2026-02-28) and codelist filtering
        "patients": {
            "date_of_birth": date(1990, 1, 1),
            },

        "medications": [
            {
                "date": date(2022, 2, 28),  # day before index_date - excluded
                "dmd_code": "35039511000001107",
            },
            {
                "date": date(2022, 3, 1),  # index_date itself - excluded (is_after, strict)
                "dmd_code": "41218111000001107",
            },
            {
                "date": date(2022, 3, 2),  # day after index - included
                "dmd_code": "42297211000001100",
            },
            {
                "date": date(2022, 4, 1),  # another qualifying prescription
                "dmd_code": "42297211000001100",
            },
            {
                "date": date(2022, 4, 2),
                "dmd_code": "360711000001100",  # Lisinopril - NOT in statins codelist
            },
            {
                "date": date(2026, 2, 28),  # end_date itself - included
                "dmd_code": "35031911000001104",
            },
            {
                "date": date(2026, 3, 1),  # day after end_date - excluded
                "dmd_code": "34953211000001105",
            },
        ],

        "expected_in_population": True,
        "expected_columns": {
            "med_statins_num_days_last_before_index": 46, # carried through
            # forward direction: earliest qualifying prescription first
            "med_dmd_code_1": "42297211000001100",
            "med_date_1": date(2022, 3, 2),
            "med_dmd_code_2": "42297211000001100",
            "med_date_2": date(2022, 4, 1),
            "med_dmd_code_3": "35031911000001104",
            "med_date_3": date(2026, 2, 28),
            "med_dmd_code_4": None,
            "med_date_4": None,
            "med_dmd_code_5": None,
            "med_date_5": None,
        },
    },


    13: {   # the carried over number this time is 18
            # confirm not a fixed/hardcoded value
            # This time no more meds post index
        "patients": {
            "date_of_birth": date(1990, 1, 1),
            },

        "medications": [
            {
                "date": date(2022, 2, 15),
                "dmd_code": "42297211000001100", # statin
            },
        ],

        "expected_in_population": True,
        "expected_columns": {
            "med_statins_num_days_last_before_index": 18,
            "med_dmd_code_1": None,
            "med_date_1": None
        },
    },
}
