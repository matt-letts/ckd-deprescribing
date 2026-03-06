### THIS IS PRE-PRODUCITON" - currently not using

build_flow_counts <- function(ds) {
  library(dplyr)

  flow <- list()

  # Step 1: Total
  step1 <- ds
  flow$total <- step1 %>%
    summarise(n = n()) %>%
    collect()

  # Step 2: Alive
  step2 <- step1 %>%
    filter(inex_dem_bin_alive)

  flow$alive <- step2 %>%
    summarise(n = n()) %>%
    collect()

  # Step 3: Age eligible
  step3 <- step2 %>%
    filter(inex_dem_bin_age_include)

  flow$age <- step3 %>%
    summarise(n = n()) %>%
    collect()

  # Step 4: Registered 12m
  step4 <- step3 %>%
    filter(inex_dem_bin_12m_registered)

  flow$registered <- step4 %>%
    summarise(n = n()) %>%
    collect()

  # Step 5: CKD criteria
  step5 <- step4 %>%
    filter(
      inex_ckd_bin_has_two_scr,
      inex_ckd_bin_has_ckd45_code
    )

  flow$ckd <- step5 %>%
    summarise(n = n()) %>%
    collect()

  # Step 6: Exclude KRT
  step6 <- step5 %>%
    filter(!inex_krt_bin_has_combined_krt_code)

  flow$no_krt <- step6 %>%
    summarise(n = n()) %>%
    collect()

  # Step 7: QA completeness
  step7 <- step6 %>%
    filter(
      inex_qa_bin_sex,
      inex_qa_bin_region,
      inex_qa_bin_ethnicity,
      inex_qa_bin_imd
    )

  flow$final <- step7 %>%
    summarise(n = n()) %>%
    collect()

  # Build final table
  flow_table <- data.frame(
    step = c(
      "Total population",
      "Alive",
      "Age eligible",
      "Registered ≥12 months",
      "CKD criteria met",
      "Exclude KRT",
      "Complete QA variables"
    ),
    n = c(
      flow$total$n,
      flow$alive$n,
      flow$age$n,
      flow$registered$n,
      flow$ckd$n,
      flow$no_krt$n,
      flow$final$n
    )
  )

  flow_table$excluded_from_previous <- c(
    NA,
    diff(flow_table$n) * -1
  )

  return(list(
    flow_table = flow_table,
    final_lazy_dataset = step7
  ))
}
