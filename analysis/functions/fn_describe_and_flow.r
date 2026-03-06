############################################################################
# describe_and_flow() - allows flow of patients through the pipeline to be
# tracked without holding all the datasets in memory simultaneously
#
# Takes a project_stage argument (e.g. "cleaning") and searches the global
# environment for all variables matching the pattern:
# "dataset_<project_stage>_<n>_<stage>"

# For each matching variable:
#   1. Collects the Arrow dataset into memory
#   2. Passes it to describe_data() which generates a skimr summary saved to
#      output/describe/<project_stage>-<stage>.txt
#   3. Records the stage name and row count in a flow dataframe
#   4. Frees the collected data from memory before moving to the next dataset
#
# Usage:
#   flow_cleaning <- describe_and_flow("cleaning")
#   flow_modelling <- describe_and_flow("modelling")
#############################################################################

describe_and_flow <- function(project_stage) {
  data_names <- ls(
    pattern = paste0("^dataset_", project_stage, "_"),
    envir = .GlobalEnv
  )
  flow <- data.frame(stage = character(), n_rows = integer())

  for (var_name in data_names) {
    stage_name <- sub(
      paste0("^dataset_", project_stage, "_\\d+_"),
      "",
      var_name
    )
    collected <- collect(get(
      var_name,
      envir = .GlobalEnv
    ))

    describe_data(
      data = collected,
      name = project_stage,
      suffix = stage_name
    )

    flow <- rbind(
      flow,
      data.frame(stage = stage_name, n_rows = nrow(collected))
    )

    rm(collected)
    gc()
  }

  return(flow)
}
