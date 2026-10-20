# Inspect the current public aggregate release; never starts pupil estimation.
# RStudio: source("replication/INSPECT_RELEASE.R", encoding = "UTF-8")
# Optional: options(lo.python = "/path/to/python", lo.release.package = "/path/to/pinned.zip")
(function() {
  if (!requireNamespace("digest", quietly = TRUE)) stop("Install the locked R environment (digest is required).")
  python <- getOption("lo.python", Sys.getenv("LO_PYTHON", ""))
  if (!nzchar(python)) {
    candidates <- unname(Sys.which(c("python3", "python")))
    candidates <- candidates[nzchar(candidates)]
    if (!length(candidates)) stop("Set options(lo.python = '/path/to/Python-3.12-or-newer').")
    python <- candidates[[1L]]
  }
  if (!file.exists(python)) stop("Configured Python executable does not exist.")
  workspace <- tempfile("lo-release-inspect-")
  dir.create(workspace, recursive = FALSE)
  workspace <- normalizePath(workspace, winslash = "/", mustWork = TRUE)
  temp_root <- normalizePath(tempdir(), winslash = "/", mustWork = TRUE)
  if (!startsWith(workspace, paste0(temp_root, "/lo-release-inspect-"))) stop("Unexpected temporary workspace.")
  on.exit(unlink(workspace, recursive = TRUE, force = TRUE), add = TRUE)
  package <- getOption("lo.release.package", "")
  if (!nzchar(package)) {
    package <- file.path(workspace, "replication.zip")
    url <- "https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes/releases/download/v2026.10.20-current47-dashboard.1/learning-outcomes-replication.zip"
    prior_timeout <- getOption("timeout")
    options(timeout = max(300, prior_timeout))
    on.exit(options(timeout = prior_timeout), add = TRUE)
    download.file(url, package, mode = "wb", method = "libcurl", quiet = TRUE)
  }
  expected <- "fe6924fe726a92e2c114ab78b9318d978264c4a51b01d1876e19850cace07158"
  if (!file.exists(package) || !identical(digest::digest(file = package, algo = "sha256"), expected)) {
    stop("Release package does not match the pinned SHA-256; no files were executed.")
  }
  inventory <- unzip(package, list = TRUE)
  if (any(grepl("(^/|^[A-Za-z]:|\\\\|(^|/)\\.\\.(/|$))", inventory$Name))) stop("Unsafe archive member.")
  if (sum(inventory$Length) > 500 * 1024^2) stop("Archive exceeds the verified workspace budget.")
  target <- file.path(workspace, "package")
  dir.create(target)
  unzip(package, exdir = target)
  cat("Verifying 90,829 approved targets; no pupil estimation or deferred countries.\n")
  status <- system2(python, c(shQuote(file.path(target, "REPLICATE.py")), "inspect"))
  if (!identical(status, 0L)) stop("Release inspection failed; see the verification error above.")
  cat("PUBLIC_RELEASE_INSPECTION_PASS; temporary extracted files removed on exit.\n")
})()
