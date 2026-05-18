###########################################################################
# Test data for dataset_definition_baseline_meds.py
#
# This test checks the performance of add_prescription_columns(), which is
# the main component of dataset_definition_baseline_meds.py 
#
# Note: as dataset_definition_baseline_meds filters to patients in
# dataset_inex_cleaned.arrow, patient IDs here must also appear in that
# dataset - this test can only be performed locally, as will not know
# patient IDs in real data.
#
# opensafely exec ehrql:v1 assure analysis/dataset_definition/test_dataset_definition_baseline_meds.py
###########################################################################

from datetime import date
from dataset_definition_baseline_meds import dataset

test_data = {
    
    1: {    # simple case with only one medication data row 
        "patients": { # one row per patient
            "date_of_birth": date(1910, 1, 1), # always first day of month, never NULL
            },

        "medications": [ # many rows per patient
            { 
                "date": date(2022, 1, 1),
                "dmd_code": "34953211000001105", # Rosuvastatin 10mg tablets (Aristo Pharma Ltd)
            },
        ],

        "expected_in_population": True,
        "expected_columns": {
            "med_dmd_code_1": "34953211000001105",
            "med_date_1": date(2022, 1, 1),
            "med_dmd_code_2": None,
            "med_date_2": None,
            "med_dmd_code_3": None,
            "med_date_3": None,
            "med_dmd_code_4": None,
            "med_date_4": None,
            "med_dmd_code_5": None,
            "med_date_5": None
        },
    },


    2: {    # 2nd medicine prescribed before 90 day window around index date
        
        "patients": { # one row per patient
            "date_of_birth": date(1910, 1, 1), # always first day of month, never NULL
            },

        "medications": [ # many rows per patient
            { 
                "date": date(2022, 1, 1),
                "dmd_code": "34953211000001105", # Rosuvastatin 10mg tablets (Aristo Pharma Ltd)
            },
            {
                "date": date(2021, 6, 1), # too early for function to capture
                "dmd_code": "360711000001100" # Lisinopril 20mg tablets (Zentiva)
            }
        ],

        "expected_in_population": True,
        "expected_columns": {
            "med_dmd_code_1": "34953211000001105",
            "med_date_1": date(2022, 1, 1),
            "med_dmd_code_2": None,
            "med_date_2": None,
            "med_dmd_code_3": None,
            "med_date_3": None,
            "med_dmd_code_4": None,
            "med_date_4": None,
            "med_dmd_code_5": None,
            "med_date_5": None
        },
    },

    5: {    # multiple different prescriptions on the same day 
        
        "patients": { # one row per patient
            "date_of_birth": date(1910, 1, 1), # always first day of month, never NULL
            },

        "medications": [ # many rows per patient
            { 
                "date": date(2022, 1, 1),
                "dmd_code": "34953211000001105", # Rosuvastatin 10mg tablets (Aristo Pharma Ltd)
            },
            {
                "date": date(2022, 1, 1), # same date 
                "dmd_code": "360711000001100" # Lisinopril 20mg tablets (Zentiva)
            }
        ],

        "expected_in_population": True,
        "expected_columns": {
            "med_dmd_code_1": "360711000001100",
            "med_date_1": date(2022, 1, 1),
            "med_dmd_code_2": "34953211000001105",
            "med_date_2": date(2022, 1, 1),
            "med_dmd_code_3": None,
            "med_date_3": None,
            "med_dmd_code_4": None,
            "med_date_4": None,
            "med_dmd_code_5": None,
            "med_date_5": None
        },
    },



    9: {    # duplicated date and code
        
        "patients": { # one row per patient
            "date_of_birth": date(1910, 1, 1), # always first day of month, never NULL
            },

        "medications": [ # many rows per patient
            { 
                "date": date(2022, 1, 1),
                "dmd_code": "34953211000001105", # Rosuvastatin 10mg tablets (Aristo Pharma Ltd)
            },
            {
                "date": date(2022, 1, 1), # same date 
                "dmd_code": "34953211000001105" # Rosuvastatin 10mg tablets (Aristo Pharma Ltd)
            }
        ],

        "expected_in_population": True,
        "expected_columns": {
            "med_dmd_code_1": "34953211000001105",
            "med_date_1": date(2022, 1, 1),
            "med_dmd_code_2": None,
            "med_date_2": None,
            "med_dmd_code_3": None,
            "med_date_3": None,
            "med_dmd_code_4": None,
            "med_date_4": None,
            "med_dmd_code_5": None,
            "med_date_5": None
        },
    },



    10: {   # more realistic patient, shows that function is ordering dm+d codes lexicographically rather than numerically. 
            # ordering doesn't really matter as long as consistent
        
        "patients": { # one row per patient
            "date_of_birth": date(1910, 1, 1), # always first day of month, never NULL
            },

        "medications": [ # many rows per patient
            { 
                "date": date(2022, 1, 1),
                "dmd_code": "34953211000001105", # Rosuvastatin 10mg tablets (Aristo Pharma Ltd)
            },
            {
                "date": date(2022, 1, 1), # same date 
                "dmd_code": "360711000001100" # Lisinopril 20mg tablets (Zentiva)
            },
            {
                "date": date(2022, 1, 1), # same date 
                "dmd_code": "21801411000001101" # Bisoprolol 5mg tablets (Waymade Healthcare Plc)
            },
            {
                "date": date(2022, 1, 1), # same date 
                "dmd_code": "9557111000001102" # Amlodipine 5mg tablets (Zentiva)
            }, 
            
            # same medicines again but a week earlier  
                     
            {
                "date": date(2021, 12, 24), 
                "dmd_code": "34953211000001105" # Rosuvastatin 10mg tablets (Aristo Pharma Ltd)
            },
            {
                "date": date(2021, 12, 24), 
                "dmd_code": "360711000001100" # Lisinopril 20mg tablets (Zentiva)
            },
            {
                "date": date(2021, 12, 24),  
                "dmd_code": "21801411000001101" # Bisoprolol 5mg tablets (Waymade Healthcare Plc)
            },
            {
                "date": date(2021, 12, 24), 
                "dmd_code": "9557111000001102" # Amlodipine 5mg tablets (Zentiva)
            }
        ],

        "expected_in_population": True,
        "expected_columns": {
            "med_dmd_code_1": "9557111000001102",
            "med_date_1": date(2022, 1, 1),
            "med_dmd_code_2": "360711000001100",
            "med_date_2": date(2022, 1, 1),
            "med_dmd_code_3": "34953211000001105",
            "med_date_3": date(2022, 1, 1),
            "med_dmd_code_4": "21801411000001101",
            "med_date_4": date(2022, 1, 1),
            "med_dmd_code_5": "9557111000001102",
            "med_date_5": date(2021, 12, 24)
        },
    },

}