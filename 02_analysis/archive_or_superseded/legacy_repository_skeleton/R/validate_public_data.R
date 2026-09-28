required_public_fields <- c(
  "country_iso3", "survey", "cycle", "age_group", "domain", "metric",
  "estimate", "standard_error", "ci_low", "ci_high", "panel_id",
  "analysis_release"
)

forbidden_microdata_fields <- c(
  "student_id", "school_id", "teacher_id", "parent_id", "record_id",
  "cntstuid", "cntschid", "idstud", "idschool"
)

validate_public_frame <- function(data) {
  missing_fields <- setdiff(required_public_fields, names(data))
  forbidden_fields <- intersect(tolower(names(data)), forbidden_microdata_fields)

  if (length(missing_fields) > 0L) {
    stop("Missing public-data fields: ", paste(missing_fields, collapse = ", "))
  }
  if (length(forbidden_fields) > 0L) {
    stop("Potential record-level identifiers found: ", paste(forbidden_fields, collapse = ", "))
  }
  if (any(data$ci_low > data$estimate | data$ci_high < data$estimate, na.rm = TRUE)) {
    stop("At least one confidence interval does not contain its estimate.")
  }
  if (any(data$standard_error < 0, na.rm = TRUE)) {
    stop("Standard errors must be non-negative.")
  }
  invisible(TRUE)
}

validate_public_release <- function(files) {
  if (length(files) == 0L) {
    return(list(status = "empty", files_checked = 0L))
  }
  list(
    status = "files-present-manual-format-routing-required",
    files_checked = length(files),
    files = files
  )
}
