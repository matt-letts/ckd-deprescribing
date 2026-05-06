#############################################################################
# fn_describe_data()
# Writes a skimr summary of data to filepath.
#############################################################################

fn_describe_data <- function(data, filepath) {
  sink(filepath)
  on.exit(sink())
  suppressWarnings(print(skimr::skim(data)))
  message(filepath, " written successfully.")
}


#############################################################################
# fn_describe_and_flow()
#
# Relies on naming convention: dataset_<project_stage>_<n>_<stage_name>
#
# Produces:
# 1. skimr summaries for all datasets matching the pattern and saves
#    them to output/data_descriptions/<project_stage>/*.txt
# 2. A flow dataframe with rows for each dataset within the project stage,
#    containing the stage name and SDC-suppressed row count
#############################################################################

fn_describe_and_flow <- function(project_stage) {
  # scan the global environment for variables matching the pattern:
  # dataset_<project_stage>_ and stores their names in data_names
  data_names <- ls(
    pattern = paste0("^dataset_", project_stage, "_"),
    envir = .GlobalEnv
  )

  # create output directory and initialize flow dataframe
  fs::dir_create(here::here("output", "data_descriptions", project_stage))
  flow <- data.frame(stage = character(), n_rows = integer())

  # Loop over each name in data_names (i.e. each dataset matching the pattern)
  for (var_name in data_names) {
    # Extract stage name by removing prefix "dataset_<project_stage>_<n>_"
    stage_name <- sub(
      paste0("^dataset_", project_stage, "_\\d+_"),
      "",
      var_name
    )
    # collect the dataset into memory - required for skimr()
    # if produces memory issue on the server can change to a lazy process
    collected <- collect(get(var_name, envir = .GlobalEnv))

    # produce skimr() output for the dataset
    fn_describe_data(
      data = collected,
      filepath = here::here(
        "output",
        "data_descriptions",
        project_stage,
        paste0(stage_name, ".txt")
      )
    )

    # append stage name and SDC-rounded row count to flow dataframe
    flow <- rbind(
      flow,
      data.frame(stage = stage_name, n_rows = fn_apply_sdc(nrow(collected)))
    )

    # clear the RAM before next iteration
    rm(collected)
    gc()
  }

  return(flow)
}
