from datetime import date
from dataset_definition import dataset

test_data = {
    
    1: {    # expected in population, with ckd codes, creatinine values and a kidney transplant

        "patients": { # one row per patient
            "date_of_birth": date(1950, 1, 1), # always first day of month, never NULL
            "sex": "female", # never NULL
            "date_of_death": date(2025, 1, 1)
            },

        "clinical_events": [ # many rows per patient
            { 
                # snomed for creatinine
                "date": date(2022, 1, 1),
                "snomedct_code": "1000731000000107",
                "numeric_value": 150
            },
            { 
                # snomed for creatinine
                "date": date(2021, 1, 1),
                "snomedct_code": "1000731000000107",
                "numeric_value": 160
            },
            { 
                # snomed for ckd
                "date": date(2020, 1, 1),
                "snomedct_code": "46177005",
                "numeric_value": 160
            },
            { 
                # primary care ctv3 for krt
                "date": date(2022, 2, 1),
                "ctv3_code": "7B001"
            },
            { 
                # snomed for ethnicity
                "date": date(2010, 1, 1),
                "snomedct_code": "154216007"
            }
        ],       

        "practice_registrations": [ # many rows per patient. each row corresponds to registration at one practice
            {
                "start_date": date(2015, 1, 1), # never NULL
                "end_date": date(2025, 1, 1),
                "practice_nuts1_region_name": "North East"
            }
        ],       

        "ons_deaths": { # one row per patient
            "date": date(2025, 1, 1)
        },      

        "apcs": [ # many rows per patient, each row an in-hospital spell
            { 
                "apcs_ident": "12345", # never NULL
                "admission_date": date(2021, 6, 1),
                "all_diagnoses": "||Z940",
                "all_procedures": "||M01"
            }
        ],

        "addresses": [
            { # many rows per patient, each row one registration period per patient
                "address_id": "12345",
                "start_date": date(2010, 1, 1),
                "end_date": date(2025, 1, 1),
                "has_postcode": True,
                "imd_rounded": 8000 #always >=0, <= 32800 and a multiple of 100
            }
        ],

        "ethnicity_from_sus": { # one row per patient
            "code": "A" # possible values A through S (excluding I, O, Q)
        },
        
        "expected_in_population": True,
        "expected_columns": {
            "inex_dem_bin_alive": True,                            
            "inex_dem_bin_age_include": True,                         
            "inex_dem_bin_12m_registered": True,                    
            "inex_dem_num_age": 72,
            "inex_dem_cat_sex": "female",                               
            "inex_ckd_bin_has_two_scr": True,                    
            "inex_ckd_num_scr_value_1": 150,                        
            "inex_ckd_date_scr_date_1": date(2022, 1, 1),                       
            "inex_ckd_num_scr_value_2": 160,                       
            "inex_ckd_date_scr_date_2": date(2021, 1, 1),                        
            "inex_ckd_bin_has_ckd45_code": True,                    
            "inex_ckd_date_most_recent_ckd45_code": date(2020, 1, 1),            
            "inex_ckd_cat_ckd_code_stage": "five",                    
            "inex_krt_bin_has_primary_care_krt_code": True,         
            "inex_krt_date_most_recent_primary_care_krt_code": date(2022, 2, 1),
            "inex_krt_cat_primary_care_krt_type": "transplant",              
            "inex_krt_bin_has_combined_krt_code": True,             
            "inex_krt_date_most_recent_combined_krt_code": date(2022, 2, 1),    
            "inex_krt_cat_combined_krt_type": "transplant",                 
            "inex_qa_bin_sex": True,                                 
            "inex_qa_bin_region": True,                             
            "inex_qa_bin_ethnicity": True,                           
            "inex_qa_bin_imd": True   
        },
    },




        
    2: {    # < 90 days between creatinine measurements, test alive
            # test age constraints, test sex qa, test ethnicity function
            # test qa region, no primary or secondary care krt codes,
            # test 12m registered
            
        "patients": { # one row per patient
            "date_of_birth": date(1910, 1, 1), # always first day of month, never NULL
            "sex": "intersex", # never NULL
            "date_of_death": date(2021, 1, 1)
            },

        "clinical_events": [ # many rows per patient
            { 
                # snomed for creatinine
                "date": date(2022, 1, 1),
                "snomedct_code": "1000731000000107",
                "numeric_value": 150
            },
            { 
                # snomed for creatinine - not > 90 days prior
                "date": date(2021, 12, 1),
                "snomedct_code": "1000731000000107",
                "numeric_value": 160
            },
            { 
                # no snomed code for ckd
                # "date": date(2020, 1, 1),
                # "snomedct_code": "46177005"
            },
            { 
                # no primary care ctv3 for krt
                # "date": date(2022, 2, 1),
                # "ctv3_code": "7B001"
            },
            { 
                # no snomed for ethnicity
                # "date": date(2010, 1, 1),
                # "snomedct_code": "154216007"
            }
        ],      

        "practice_registrations": [ # many rows per patient. each row corresponds to registration at one practice
            {
                "start_date": date(2021, 6, 1), # never NULL # <12 months pre index
                "end_date": date(2025, 1, 1),
                # "practice_nuts1_region_name": "North East"
            }
        ],       

        "ons_deaths": { # one row per patient
            "date": date(2025, 1, 1) # test doesn't match with patients table
        },      

        "apcs": [ # many rows per patient, each row an in-hospital spell
            { 
                "apcs_ident": "12345", # never NULL
                "admission_date": date(2021, 6, 1),
                "all_diagnoses": "||E119", # not a krt code
                "all_procedures": "||E851" # not a krt code
            }
        ],

        "addresses": [
            { # many rows per patient, each row one registration period per patient
                "address_id": "12345",
                "start_date": date(2010, 1, 1),
                "end_date": date(2025, 1, 1),
                "has_postcode": True,
                "imd_rounded": 8000 #always >=0, <= 32800 and a multiple of 100
            }
        ],

        "ethnicity_from_sus": { # one row per patient
            "code": "A" # possible values A through S (excluding I, O, Q)
        },
        
        "expected_in_population": True,
        "expected_columns": {
            "inex_dem_bin_alive": False,                            
            "inex_dem_bin_age_include": False,                         
            "inex_dem_bin_12m_registered": False,                    
            "inex_dem_num_age": 112,
            "inex_dem_cat_sex": "intersex",                               
            "inex_ckd_bin_has_two_scr": False,                    
            "inex_ckd_num_scr_value_1": 150,                        
            "inex_ckd_date_scr_date_1": date(2022, 1, 1),                       
            "inex_ckd_num_scr_value_2": None,                       
            "inex_ckd_date_scr_date_2": None,                        
            "inex_ckd_bin_has_ckd45_code": False,                    
            "inex_ckd_date_most_recent_ckd45_code": None,            
            "inex_ckd_cat_ckd_code_stage": None,                    
            "inex_krt_bin_has_primary_care_krt_code": False,         
            "inex_krt_date_most_recent_primary_care_krt_code": None,
            "inex_krt_cat_primary_care_krt_type": None,              
            "inex_krt_bin_has_combined_krt_code": False,             
            "inex_krt_date_most_recent_combined_krt_code": None,    
            "inex_krt_cat_combined_krt_type": None,                 
            "inex_qa_bin_sex": False,                                 
            "inex_qa_bin_region": False,                             
            "inex_qa_bin_ethnicity": True,                           
            "inex_qa_bin_imd": True   
        },
    },


        
    3: {    # expected in population, creatinine measurements on same day,
            # lots of measurements after index date, icd10 and opcs4 clash whether dialysis/transplant

        "patients": { # one row per patient
            "date_of_birth": date(1950, 1, 1), # always first day of month, never NULL
            "sex": "female", # never NULL
            "date_of_death": date(2015, 1, 1) # not alive
            },

        "clinical_events": [ # many rows per patient
            { 
                # snomed for creatinine
                "date": date(2021, 1, 1),
                "snomedct_code": "1000731000000107",
                "numeric_value": 150
            },
            { 
                # snomed for creatinine
                "date": date(2021, 1, 1),
                "snomedct_code": "1000731000000107",
                "numeric_value": 160
            },
            { 
                # snomed for ckd
                "date": date(2023, 1, 1), # after index
                "snomedct_code": "46177005"
            },
            { 
                # primary care ctv3 for krt
                "date": date(2023, 2, 1), # after index
                "ctv3_code": "7A602"
            },
            { 
                # snomed for ethnicity
                "date": date(2023, 1, 1), # after index
                "snomedct_code": "154216007"
            }
        ],      

        "practice_registrations": [ # many rows per patient. each row corresponds to registration at one practice
            {
                "start_date": date(2015, 1, 1), # never NULL
                "end_date": date(2021, 1, 1), # deregistered before index date
                "practice_nuts1_region_name": "North East"
            }
        ],       

        "ons_deaths": { # one row per patient
            "date": date(2025, 1, 1)
        },       

        "apcs": [ # many rows per patient, each row an in-hospital spell
            { 
                "apcs_ident": "12345", # never NULL
                "admission_date": date(2021, 6, 1),
                "all_diagnoses": "||Y841", # edge case, dialysis ICD10, transplant OPCS4
                "all_procedures": "||M01"
            }
        ],

        "addresses": [
            { # many rows per patient, each row one registration period per patient
                "address_id": "12345",
                "start_date": date(2010, 1, 1),
                "end_date": date(2025, 1, 1),
                "has_postcode": False, # doesn't matter whether has postcode it would appear
                "imd_rounded": None #always >=0, <= 32800 and a multiple of 100 # blank hence cannot calculate IMD
            }
        ],

        "ethnicity_from_sus": { # one row per patient
            # BLANK "code": "A" # possible values A through S (excluding I, O, Q)
        },
        
        "expected_in_population": True,
        "expected_columns": {
            "inex_dem_bin_alive": False,                            
            "inex_dem_bin_age_include": True,                         
            "inex_dem_bin_12m_registered": False,                    
            "inex_dem_num_age": 72,
            "inex_dem_cat_sex": "female",                               
            "inex_ckd_bin_has_two_scr": False,                    
            "inex_ckd_num_scr_value_1": 160, # both on the same date, appears to take the latter measurement                        
            "inex_ckd_date_scr_date_1": date(2021, 1, 1),                       
            "inex_ckd_num_scr_value_2": None,                       
            "inex_ckd_date_scr_date_2": None,                        
            "inex_ckd_bin_has_ckd45_code": False,                    
            "inex_ckd_date_most_recent_ckd45_code": None,            
            "inex_ckd_cat_ckd_code_stage": None,                    
            "inex_krt_bin_has_primary_care_krt_code": False,         
            "inex_krt_date_most_recent_primary_care_krt_code": None,
            "inex_krt_cat_primary_care_krt_type": None,              
            "inex_krt_bin_has_combined_krt_code": True,             
            "inex_krt_date_most_recent_combined_krt_code": date(2021, 6, 1),    
            "inex_krt_cat_combined_krt_type": "unknown",                 
            "inex_qa_bin_sex": True,                                 
            "inex_qa_bin_region": False,                             
            "inex_qa_bin_ethnicity": False,                           
            "inex_qa_bin_imd": False   
        },
    },


        
    4: {    # expected in population, with ckd codes, creatinine values and a kidney transplant
        
        "patients": { # one row per patient
            "date_of_birth": date(1950, 1, 1), # always first day of month, never NULL
            "sex": "unknown" # never NULL
            # "date_of_death": date(2025, 1, 1)
            },

        "clinical_events": [ # many rows per patient
            { 
                # snomed for creatinine
                "date": date(2022, 1, 1),
                "snomedct_code": "276401000000108", # colorectal cancer
            },
            { 
                # snomed for creatinine
                "date": date(2021, 1, 1),
                "snomedct_code": "276401000000108", # colorectal cancer
            },
            { 
                # snomed for ckd
                "date": date(1900, 1, 1), # date should not matter
                "snomedct_code": "431857002",
            },
            { 
                # primary care ctv3 for krt
                "date": date(1900, 1, 1), # date should not matter
                "ctv3_code": "7L1A1" # peritoneal dialysis
            },
            {
                # a second ctv3 for krt
                "date": date(1901, 1, 1),
                "ctv3_code": "X30Md" # renal transplant code
            },
            { 
                # snomed for ethnicity
                "date": date(2010, 1, 1),
                "snomedct_code": "276401000000108" # colorectal cancer
            }
        ],      
  
        "practice_registrations": [ # many rows per patient. each row corresponds to registration at one practice
            {
                "start_date": date(2021, 1, 1), # never NULL
                "end_date": date(2022, 1, 1),
                "practice_nuts1_region_name": "North East"
            },
            {
                "start_date": date(2022, 1, 1), # so moved practice prior to index date and not been there >12m
                "practice_nuts1_region_name": "South East"
            }
        ],     
  
        "ons_deaths": { # one row per patient
            "date": date(1900, 1, 1) # what happens if ONS death is present, but not patients.death. And ONS date is before DOB
        },      
  
        "apcs": [ # many rows per patient, each row an in-hospital spell
            { 
                "apcs_ident": "12345", # never NULL
                "admission_date": date(2021, 6, 1),
                "all_procedures": "||X409" # dialysis
            }
        ],

        "addresses": [
            { # many rows per patient, each row one registration period per patient
                "address_id": "12345",
                "start_date": date(2023, 1, 1), # after index date
                "end_date": date(2025, 1, 1),
                "has_postcode": True,
                "imd_rounded": 8000 #always >=0, <= 32800 and a multiple of 100
            }
        ],

        "ethnicity_from_sus": { # one row per patient
            # "code": "A" # possible values A through S (excluding I, O, Q)
        },
        
        "expected_in_population": True,
        "expected_columns": {
            "inex_dem_bin_alive": False,                            
            "inex_dem_bin_age_include": True,                         
            "inex_dem_bin_12m_registered": False,                    
            "inex_dem_num_age": 72,
            "inex_dem_cat_sex": "unknown",                               
            "inex_ckd_bin_has_two_scr": False,                    
            "inex_ckd_num_scr_value_1": None,                        
            "inex_ckd_date_scr_date_1": None,                       
            "inex_ckd_num_scr_value_2": None,                       
            "inex_ckd_date_scr_date_2": None,                        
            "inex_ckd_bin_has_ckd45_code": True,                    
            "inex_ckd_date_most_recent_ckd45_code": date(1900, 1, 1),            
            "inex_ckd_cat_ckd_code_stage": "four",                    
            "inex_krt_bin_has_primary_care_krt_code": True,         
            "inex_krt_date_most_recent_primary_care_krt_code": date(1901, 1, 1),
            "inex_krt_cat_primary_care_krt_type": "transplant",              
            "inex_krt_bin_has_combined_krt_code": True,             
            "inex_krt_date_most_recent_combined_krt_code": date(2021, 6, 1),    
            "inex_krt_cat_combined_krt_type": "dialysis",                 
            "inex_qa_bin_sex": False,                                 
            "inex_qa_bin_region": True,                             
            "inex_qa_bin_ethnicity": False,                           
            "inex_qa_bin_imd": False   
        },
    },
}