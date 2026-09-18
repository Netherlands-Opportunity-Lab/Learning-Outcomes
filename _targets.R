library(targets)

source("R/validate_public_data.R")
source("R/theme_learning_outcomes.R")

tar_option_set(
  packages = c("jsonlite", "yaml"),
  format = "rds"
)

list(
  tar_target(
    source_register,
    yaml::read_yaml("sources.yml")
  ),
  tar_target(
    public_schema,
    jsonlite::read_json("data-public/schema.json", simplifyVector = FALSE)
  ),
  tar_target(
    public_data_files,
    list.files(
      "data-public",
      pattern = "\\.(csv|parquet|json)$",
      full.names = TRUE
    )
  ),
  tar_target(
    public_validation,
    validate_public_release(public_data_files)
  )
)
