# test script to check the performance of get_recent_prescriptions() which is called via
# get_prescription_columns() into the dataset_definition_prescriptions.py

from datetime import date
from dataset_definition_prescriptions import dataset

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
            "med_1_code": "34953211000001105",
            "med_1_date": date(2022, 1, 1),
            "med_2_code": None,
            "med_2_date": None,
            "med_3_code": None,
            "med_3_date": None,
            "med_4_code": None,
            "med_4_date": None,
            "med_5_code": None,
            "med_5_date": None
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
            "med_1_code": "34953211000001105",
            "med_1_date": date(2022, 1, 1),
            "med_2_code": None,
            "med_2_date": None,
            "med_3_code": None,
            "med_3_date": None,
            "med_4_code": None,
            "med_4_date": None,
            "med_5_code": None,
            "med_5_date": None
        },
    },

    3: {    # multiple different prescriptions on the same day 
        
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
            "med_1_code": "360711000001100",
            "med_1_date": date(2022, 1, 1),
            "med_2_code": "34953211000001105",
            "med_2_date": date(2022, 1, 1),
            "med_3_code": None,
            "med_3_date": None,
            "med_4_code": None,
            "med_4_date": None,
            "med_5_code": None,
            "med_5_date": None
        },
    },



    4: {    # duplicated date and code
        
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
            "med_1_code": "34953211000001105",
            "med_1_date": date(2022, 1, 1),
            "med_2_code": None,
            "med_2_date": None,
            "med_3_code": None,
            "med_3_date": None,
            "med_4_code": None,
            "med_4_date": None,
            "med_5_code": None,
            "med_5_date": None
        },
    },



    5: {    # more realistic patient, shows that function is ordering dm+d codes lexicographically rather than numerically. 
            # doesn't really matter as long as consistent
        
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
            "med_1_code": "9557111000001102",
            "med_1_date": date(2022, 1, 1),
            "med_2_code": "360711000001100",
            "med_2_date": date(2022, 1, 1),
            "med_3_code": "34953211000001105",
            "med_3_date": date(2022, 1, 1),
            "med_4_code": "21801411000001101",
            "med_4_date": date(2022, 1, 1),
            "med_5_code": "9557111000001102",
            "med_5_date": date(2021, 12, 24)
        },
    },

}