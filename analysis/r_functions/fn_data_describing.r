#############################################################################
# fn_describe_data()
# prints a summary using the skim() function and places it into a file called
# name.txt which is in a directory which is created if doesn't already exist:
# output/data_descriptions/
#############################################################################

fn_describe_data <- function(data, name, suffix = "") {
  fs::dir_create(here::here("output", "data_descriptions", name))
  filename <- if (nzchar(suffix)) paste0(suffix, ".txt") else paste0(name, ".txt")
  filepath <- here::here("output", "data_descriptions", name, filename)
  sink(filepath)
  on.exit(sink())
  suppressWarnings({
    # stop annoying warning messages from skim entering log
    print(skimr::skim(data))
  })
  message(filepath, " written successfully.")
}


#############################################################################
# fn_describe_and_flow() - allows flow of patients through the pipeline to be
# tracked without holding all the datasets in memory simultaneously
#
# Takes a project_stage argument (e.g. "cleaning") and searches the global
# environment for all variables matching the pattern:
# "dataset_<project_stage>_<n>_<stage>"

# For each matching variable:
#   1. Collects the Arrow dataset into memory
#   2. Passes it to fn_describe_data() to create:
#      output/data_descriptions/<project_stage>-<stage>.txt
#   3. Records the stage name and row count in a flow dataframe
#   4. Frees the collected data from memory before moving to the next dataset
#############################################################################

fn_describe_and_flow <- function(
  project_stage
) {
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

    fn_describe_data(
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
