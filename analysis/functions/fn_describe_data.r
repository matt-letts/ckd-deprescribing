# this function prints a 'data' summary using the skim() function and places it into
# a file called name.txt which is in a directory which is created if doesn't already exist:
# output/data_descriptions/

describe_data <- function(data, name, suffix = "") {
  fs::dir_create(here::here("output", "data_descriptions"))
  full_name <- paste0(name, if (nzchar(suffix)) paste0("-", suffix) else "")
  sink(paste0(
    "output/data_descriptions/",
    full_name,
    ".txt"
  ))
  on.exit(sink())
  print(skimr::skim(data))
  message(paste0(
    "output/data_descriptions/",
    full_name,
    ".txt written successfully."
  ))
}
