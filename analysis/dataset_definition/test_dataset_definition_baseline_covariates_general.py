##########################################################################
# Test data for dataset_definition_baseline_covariates_general.py
# This test checks the performance of add_baseline_covariates_general()
#
# opensafely exec ehrql:v1 assure analysis/dataset_definition/
# test_dataset_definition_baseline_covariates_general.py
##########################################################################

from datetime import date
from dataset_definition_baseline_covariates_general import dataset

# NB: population is defined by dataset_inex_cleaned.exists_for_patient(), so
# every patient ID below must also exist in the local
# output/data/dataset_inex_cleaned.arrow. The 5 pulled-through columns
# (age, sex, egfr_1, date_egfr_1, coded_ckd_stage) come from that arrow file,
# NOT from the backend tables here, so only Block A asserts them (values must
# match the arrow for that ID). All other patients assert new variables only.

test_data = {

    1: { # simply verifies table_from_file() works from dataset_inex_cleaned
        "patients": {
            "date_of_birth": date(1950, 1, 1),
        },
        "addresses": [],
        "clinical_events": [],
        "ethnicity_from_sus": {},
        "practice_registrations": [],
        "apcs": [],
        "medications": [],

        "expected_in_population": True,
        "expected_columns": {
            "basecov_gen_num_age": 102,
            "basecov_gen_cat_sex": "female", 
            "basecov_gen_num_egfr_1": 11.178187869809673,
            "basecov_gen_date_egfr_1": date(2021, 5, 7), 
            "basecov_gen_cat_coded_ckd_stage": None, 
        },
    },


    2: {
        # tests: 
        #    - multiple ethnicity codes in clinical_events table
        #    - current active address with IMD 3000 that is a care home
        #    - missing null BP measurement
        #    - CVD in primary care only

        "patients": {
            "date_of_birth": date(1950, 1, 1),
        },

        "addresses": [
            {
                "start_date": date(2010, 1, 1),
                "end_date": None,
                "imd_rounded": 3000, # between 0 and 32800 - multiple of 100
                "care_home_is_potential_match": True,
            },
        ],

        "clinical_events": [ # ethnicity / sbp / mi / cva / hf / dm / hba1c
            {
                "date": date(2021, 1, 1),
                "snomedct_code": "185988007",       # African caribbean ethnicity - 4 
            },
            {
                "date": date(2020, 1, 1),
                "snomedct_code": "40165009"         # Buriats ethnicity - 3
            },
            {
                "date": date(2023, 1, 1),
                "snomedct_code": "56056003"         # Bulgarian ethnicity - 1 (after index)
            },
            {
                "date": date(2022, 1, 1),
                "snomedct_code": "271649006",       # BP in right date range, but null
                "numeric_value": None
            },
            {
                "date": date(2021, 1, 1),
                "snomedct_code": "100171000000100", # first BP that is not null
                "numeric_value": 158               
            },
            {
                "date": date(1950, 1, 1),
                "snomedct_code": "190368000"        # type 1 diabetes ages ago - should flag
            },
            {
                "date": date(2021, 1, 1),
                "snomedct_code": "22298006"         # myocardial infarction
            }
        ],

        "ethnicity_from_sus": {},

        "practice_registrations": [
            {
                "start_date": date(2010, 1, 1),
                "end_date": None,
                "practice_nuts1_region_name": "North East",
            },
        ],

        "apcs": [
            {
                "admission_date": date(2021, 1, 1),
                "all_diagnoses": "",       # ICD-10 (mi / cva / hf)
                "all_procedures": "",      # OPCS-4 (coronary revasc)
            },
        ],

        "medications": [],

        "expected_in_population": True,
        "expected_columns": {
            # only assert what this patient is built to test; delete the rest
            "basecov_gen_cat_ethnicity": "Black",
            "basecov_gen_cat_imd": "1 (most deprived)",
            "basecov_gen_cat_region": "North East",
            "basecov_gen_bin_care_home": True,
            "basecov_gen_num_sbp": 158,
            "basecov_gen_date_sbp": date(2021, 1, 1),
            "basecov_gen_bin_dm": True,
            "basecov_gen_bin_cvd_history": True,
        },
    },


    5: {
        # tests:
        #   - no snomed ethnicity code - so fall back on ethnicity from sus
        #   - address not spanning index so IMD and care home fail
        #   - BP present but value is impossible
        #   - testing hba1c logic
        #   - CVD history only confirmed through secondary care record

        "patients": {
            "date_of_birth": date(1950, 1, 1),
        },

        "addresses": [
            {
                "start_date": date(2010, 1, 1), 
                "end_date": date(2020, 1, 1), # before index
                "imd_rounded": 3000,
                "care_home_is_potential_match": True,
            },
            {
                "start_date": date(2023, 1, 1), # after index
                "end_date": date(2030, 1, 1),
                "imd_rounded": 3000,
                "care_home_is_potential_match": True,
            },
        ],

        "clinical_events": [ # ethnicity / sbp / mi / cva / hf / dm / hba1c
            {
                "date": date(2020, 1, 1),
                "snomedct_code": "271649006",       # earlier BP very high
                "numeric_value": 180
            },
            {
                "date": date(2021, 1, 1),
                "snomedct_code": "100171000000100", # more recent BP improbable value
                "numeric_value": 10               
            },
            {
                "date": date(2020, 1, 1),
                "snomedct_code": "999791000000106",
                "numeric_value": 48
            }
        ],

        "ethnicity_from_sus": {
            "code": "A"                    
        },

        "practice_registrations": [
            {
                "start_date": date(2010, 1, 1),
                "end_date": date(2030, 1, 1),
                "practice_nuts1_region_name": None,
            },
        ],

        "apcs": [
            {
                "admission_date": date(2021, 1, 1),
                "all_diagnoses": None,       # ICD-10 (mi / cva / hf)
                "all_procedures": "||K47",      # OPCS-4 (coronary revasc)
            },
        ],

        "medications": [],

        "expected_in_population": True,
        "expected_columns": {
            "basecov_gen_cat_ethnicity": "White",
            "basecov_gen_cat_imd": None,
            "basecov_gen_cat_region": None,
            "basecov_gen_bin_care_home": False,
            "basecov_gen_num_sbp": 10,
            "basecov_gen_date_sbp": date(2021, 1, 1),
            "basecov_gen_bin_dm": True,
            "basecov_gen_bin_cvd_history": True,
        },
    },


    9: {
        # tests:
        #   - no snomed or sus ethnicity code - so should null
        #   - two active addresses - how handled? 
        #   - no active registration at index date

        "patients": {
            "date_of_birth": date(1950, 1, 1),
        },

        "addresses": [
            {
                "start_date": date(2010, 1, 1),
                "end_date": date(2030, 1, 1),
                "imd_rounded": 3000,
                "care_home_is_potential_match": True,
            },
            {
                "start_date": date(2012, 1, 1), # OS prefers the most recent one
                "end_date": None,
                "imd_rounded": 30000,
                "care_home_is_potential_match": False,
            },
        ],

        "clinical_events": [ # ethnicity / sbp / mi / cva / hf / dm / hba1c
            {
                "date": date(2023, 1, 1),
                "snomedct_code": "271649006",       # BP after index
                "numeric_value": 150
            },
            {
                "date": date(2022, 1, 1),
                "snomedct_code": "271649006",       # BP in right date range, but null
                "numeric_value": None
            },
        ],
        
        "ethnicity_from_sus": {},

        "practice_registrations": [
            {
                "start_date": date(2010, 1, 1),
                "end_date": date(2020, 1, 1),
                "practice_nuts1_region_name": "East Midlands",
            },
        ],

        "apcs": [],

        "medications": [
            {
                "date": date(2021, 6, 1),
                "dmd_code": "40033011000001107",        
            },
        ],

        "expected_in_population": True,
        "expected_columns": {
            # only assert what this patient is built to test; delete the rest
            "basecov_gen_cat_ethnicity": "Missing",
            "basecov_gen_cat_imd": "5 (least deprived)",
            "basecov_gen_cat_region": None,
            "basecov_gen_bin_care_home": False,
            "basecov_gen_num_sbp": None,
            "basecov_gen_date_sbp": None,
            "basecov_gen_bin_dm": True,
            "basecov_gen_bin_cvd_history": False,
        },
    },

}

