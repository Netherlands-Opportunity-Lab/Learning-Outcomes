# =============================================================================
# PISA / PIRLS MASTER PIPELINE
# Version 1.3.5-FAST-SCHEMA-ORDER-FIX — 20 September 2026
# =============================================================================
#
# AUTOPILOT REVISION
# ------------------
# v1.3.5 keeps all prior locks and fixes schema-v2 initialization order/source-code output:
#   * selective reconstruction of horizontally merged OECD Excel headers;
#   * automatic rejection of trend/change/SE/CI columns when level estimates
#     are requested;
#   * auditable automatic resolution only when a candidate is unique or when
#     duplicate candidate columns are numerically identical;
#   * complete header-selection audit and readable failure diagnostics;
#   * stronger PISA schema/year checks before Netherlands sanity validation;
#   * cached-XLSX integrity checks and automatic redownload/retry;
#   * an R-level error handler that writes a diagnostic bundle on failure.
#
# IMPORTANT: dashboard production export is intentionally disabled here.
# The tightened 19 September 2026 dashboard schema must first be implemented
# and reviewed as a trial delivery before any full production export.
#
# PURPOSE
# -------
# One reproducible R script that can rebuild the PISA/PIRLS project from raw
# public-use files and official OECD/IEA tables, starting from scratch.
#
# The script integrates the work done so far:
#   * PIRLS 2001/2006/2011/2016/2021 file discovery and exact main-file locking
#   * student-side social-background audit
#   * Home Questionnaire / non-response audit
#   * books-at-home harmonisation
#   * five-PV + PIRLS JK2-full estimation
#   * Q1/Q4 bridge based on the books-at-home rank, with deterministic
#     fractional boundary allocation under every replicate weight
#   * substantive five books-at-home categories as an additional output
#   * fixed MAIN-13 PIRLS panel, ROBUST-16 panel, and maximum-available audit
#   * Netherlands ranks within one fixed country panel
#   * wave-specific bottom/middle/top country terciles formed *within* that
#     fixed panel
#   * PISA 2025 official OECD StatLink workbook download/extraction
#   * PISA 2022 overlap/revision audit before any 2012–2025 splice
#   * fixed-32 PISA reading panel, ranks and wave-specific terciles
#   * hooks for international ESCS, school segregation, gender×SES,
#     migration×SES/language, tracks and quality indicators
#   * PISA microdata audit hooks for future books-at-home / UNICEF 20-20 checks
#   * TIMSS Grade 4 discovery hook for the later mathematics/science extension
#   * project caveat register, figure register and reproducible vector export
#
# IMPORTANT SCIENTIFIC RULES
# --------------------------
# 1. PISA and PIRLS are NEVER put on one common score scale.
# 2. PISA and PIRLS proficiency thresholds are age/instrument specific.
# 3. Longitudinal rankings use exactly the same underlying country panel.
# 4. Bottom/middle/top country terciles are re-formed in each wave, but only
#    within that same fixed underlying country panel.
# 5. Gaps are never interpreted without the underlying group levels.
# 6. P90-P10 is overall performance dispersion, not a SES gap.
# 7. PISA 2012 is never silently spliced onto the 2015–2025 release: overlapping
#    estimates are audited first because historical OECD estimates were revised.
# 8. PIRLS 2021 must use regular R5 main-study files, NEVER A5 bridge files.
# 9. Parent/Home Questionnaire complete cases are not the sole PIRLS main SES
#    measure because response is low and achievement-selective in the Netherlands.
# 10. The slide/figure style guide governs FORMATTING only, not methodology.
#
# VISUAL STANDARD
# ---------------
# The project styling below follows the uploaded PISA/PIRLS slide/figure guide:
# warm off-white background, Netherlands in policy blue, ordinal social-
# background scale yellow-gold -> green -> teal -> blue -> purple, direct
# labels, vector-first output, one analytical task per figure.
#
# HOW TO USE
# ----------
# A. Put all raw ZIP files in Downloads (subfolders are fine).
# B. Set DOWNLOADS_OVERRIDE only if needed.
# C. Set RUN_* switches below.
# D. Source this entire script.
# E. The complete output is written to:
#      Downloads/PISA_PIRLS_MASTER_PIPELINE/
#
# The default configuration is validation-first and fail-fast. It will not
# silently continue after an input-selection or comparability failure.
# =============================================================================


# =============================================================================
# 0. CONFIGURATION
# =============================================================================

DOWNLOADS_OVERRIDE <- ""

# Reproducibility / safety
AUTO_INSTALL_PACKAGES <- TRUE
AUTO_DOWNLOAD_OECD <- TRUE
STRICT_VALIDATION <- TRUE
REUSE_CACHED_DOWNLOADS <- TRUE
FORCE_REDOWNLOAD_OECD <- FALSE
REUSE_LOCAL_OECD_ANYWHERE_IN_DOWNLOADS <- TRUE
WRITE_DOWNLOAD_CACHE_AUDIT <- TRUE
CLEAN_PIRLS_EXTRACT_EACH_RUN <- FALSE
REUSE_DERIVED_PIRLS_OUTPUTS <- TRUE
REUSE_OECD_EXTRACT_CACHE <- TRUE
OECD_EXTRACT_CACHE_VERSION <- "oecd_extract_20260919_crosswalk6_header_v2"
MASTER_RDS_COMPRESSION <- "gzip"  # faster development runs; use "xz" for final archival release
EMBED_SOURCES_IN_PDF_IF_POSSIBLE <- TRUE

# Autopilot diagnostics / safe repair
AUTOPILOT_MODE <- TRUE
AUTOPILOT_MAX_DOWNLOAD_ATTEMPTS <- 3L
AUTOPILOT_WRITE_DIAGNOSTICS <- TRUE
AUTOPILOT_ALLOW_IDENTICAL_DUPLICATE_COLUMNS <- TRUE
AUTOPILOT_RECONSTRUCT_MERGED_HEADERS <- TRUE
options(timeout=max(600, getOption("timeout")))

# Main modules
RUN_PIRLS_AUDITS <- TRUE
RUN_PIRLS_VALIDATION <- TRUE
RUN_PIRLS_MAIN_PRODUCTION <- TRUE
RUN_PIRLS_PARENT_ROBUSTNESS_PREP <- TRUE

RUN_PISA_OFFICIAL_DOWNLOAD <- TRUE
RUN_PISA_OFFICIAL_EXTRACT <- TRUE
RUN_PISA_CORE_READING <- TRUE
RUN_PISA_OVERLAP_AUDIT_2022_2025 <- TRUE
RUN_PISA_EQUITY_RAW_EXTRACTS <- TRUE
RUN_PISA_MICRODATA_AUDIT <- FALSE   # activate when needed; can be slow
RUN_PISA_FIGURES <- TRUE

RUN_TIMSS_DISCOVERY <- TRUE         # future mathematics/science module
RUN_PIRLS_FIGURES <- TRUE

# Dashboard export layer
# HOLD: full production export is deliberately OFF until the revised dashboard
# trial schema requested on 19 September 2026 has been reviewed.
RUN_DASHBOARD_EXPORT <- FALSE
RUN_DASHBOARD_JSON <- FALSE
RUN_DASHBOARD_PIRLS_ALL_AVAILABLE <- TRUE
STRICT_COUNTRY_CROSSWALK <- TRUE
DASHBOARD_RELEASE_ID <- paste0("dashboard_v1_1_", format(Sys.Date(), "%Y%m%d"))

# Methodological locks
PIRLS_MIN_PROF <- 475
PIRLS_HIGH <- 550
PIRLS_ADVANCED <- 625
PIRLS_PV_M <- 5L
PIRLS_QTAIL <- 0.25

# Strict five-wave main panel: normal 2021 timing / main Grade-4 study
PIRLS_MAIN13 <- c("BGR","FRA","DEU","HKG","ITA","NLD","NZL",
                  "NOR","RUS","SGP","SVK","SVN","SWE")

# Robustness panel adding Group-3 systems (one year later, but again Grade 4)
PIRLS_ROBUST16 <- c(PIRLS_MAIN13, "ENG","IRN","ISR")

# Group-2 delayed testing (students ~half-year older) excluded from the main set
PIRLS_2021_GROUP2 <- c("HUN","LTU","MAR","USA")

# PISA fixed panel already established for the main reading analysis
PISA_FIXED32_NAMES <- c(
  "Australia","Belgium","Brazil","Canada","Czechia","Denmark","Finland",
  "France","Germany","Greece","Hong Kong (China)","Hungary","Iceland",
  "Indonesia","Ireland","Italy","Japan","Korea","Latvia","Macao (China)",
  "Mexico","Netherlands","New Zealand","Norway","Poland","Portugal",
  "Slovak Republic","Sweden","Switzerland","Thailand","Türkiye","Uruguay"
)

# Never splice 2012 automatically. First create and inspect overlap audit.
ALLOW_PISA_2012_SPLICE <- FALSE

# Validation targets: rounded official PIRLS 2021 main-study means.
# Tolerance is deliberately wider than rounding error but narrow enough to catch
# A5/R5 or wrong-population selection.
PIRLS_2021_VALIDATION_MEANS <- c(
  NLD = 527, DEU = 524, SWE = 544, ITA = 537, SGP = 587
)
PIRLS_VALIDATION_TOLERANCE <- 2.0

# PISA Netherlands sanity checks derived from the official 2025 release.
PISA_NL_SANITY <- list(
  mean_read_2003 = 513.1,
  mean_read_2025 = 441.3,
  prof_2003 = 88.5,
  prof_2025 = 61.5,
  q1_prof_2015 = 71.8,
  q4_prof_2015 = 92.7,
  q1_prof_2025 = 46.3,
  q4_prof_2025 = 80.2
)

# =============================================================================
# 1. PACKAGES
# =============================================================================

needed_packages <- c("haven","readxl","ggplot2","svglite","jsonlite","openssl")
optional_packages <- c("scales")

install_if_needed <- function(pkgs) {
  miss <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(miss) && AUTO_INSTALL_PACKAGES) {
    install.packages(miss, repos = "https://cloud.r-project.org")
  }
  miss2 <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(miss2)) {
    stop("Required R package(s) missing: ", paste(miss2, collapse = ", "),
         ". Install them and rerun.")
  }
}
install_if_needed(needed_packages)


# =============================================================================
# 2. PATHS, LOGGING, VERSIONING
# =============================================================================

if (nzchar(DOWNLOADS_OVERRIDE)) {
  downloads <- DOWNLOADS_OVERRIDE
} else {
  downloads <- file.path(Sys.getenv("USERPROFILE"), "Downloads")
}
downloads <- normalizePath(downloads, winslash = "/", mustWork = FALSE)

root <- file.path(downloads, "PISA_PIRLS_MASTER_PIPELINE")
dirs <- list(
  root = root,
  logs = file.path(root, "00_logs"),
  registers = file.path(root, "01_registers"),
  raw_oecd = file.path(root, "02_raw_oecd"),
  pirls_extract = file.path(root, "03_pirls_extract"),
  pirls_audit = file.path(root, "04_pirls_audit"),
  pirls_results = file.path(root, "05_pirls_results"),
  pisa_extract = file.path(root, "06_pisa_extract"),
  pisa_results = file.path(root, "07_pisa_results"),
  figures = file.path(root, "08_figures"),
  timss = file.path(root, "09_timss_future"),
  bundles = file.path(root, "10_bundles")
)
invisible(lapply(dirs, dir.create, recursive = TRUE, showWarnings = FALSE))

timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
logfile <- file.path(dirs$logs, paste0("pipeline_", timestamp, ".log"))

log_msg <- function(...) {
  z <- paste0(..., collapse = "")
  cat(z, "\n")
  cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "  ", z, "\n",
      file = logfile, append = TRUE, sep = "")
}

log_msg("PISA/PIRLS master pipeline started.")
log_msg("Downloads: ", downloads)
log_msg("Project root: ", root)

AUTOPILOT_DIAG_DIR <- file.path(
  dirs$logs, paste0("autopilot_diagnostics_", timestamp)
)
dir.create(AUTOPILOT_DIAG_DIR, recursive=TRUE, showWarnings=FALSE)

AUTOPILOT_PREVIOUS_ERROR_OPTION <- getOption("error")

autopilot_write_failure <- function(message=geterrmessage()) {
  if(!isTRUE(AUTOPILOT_WRITE_DIAGNOSTICS)) return(invisible(NULL))
  dir.create(AUTOPILOT_DIAG_DIR, recursive=TRUE, showWarnings=FALSE)

  calls <- try(utils::capture.output(sys.calls()), silent=TRUE)
  if(inherits(calls,"try-error")) calls <- "Could not capture call stack."

  warn <- try(utils::capture.output(warnings()), silent=TRUE)
  if(inherits(warn,"try-error")) warn <- "Could not capture warnings."

  writeLines(c(
    "PISA/PIRLS AUTOPILOT FAILURE REPORT",
    paste("Time:", Sys.time()),
    paste("R:", R.version.string),
    "",
    "ERROR",
    as.character(message),
    "",
    "CALL STACK",
    calls,
    "",
    "WARNINGS",
    warn,
    "",
    paste("Main log:", logfile),
    paste("Diagnostics:", AUTOPILOT_DIAG_DIR)
  ), file.path(AUTOPILOT_DIAG_DIR, "AUTOPILOT_LAST_ERROR.txt"))

  try(writeLines(utils::capture.output(sessionInfo()),
                 file.path(AUTOPILOT_DIAG_DIR, "sessionInfo.txt")),
      silent=TRUE)
  try(dump.frames(dumpto=file.path(AUTOPILOT_DIAG_DIR,
                                   "autopilot_dump_frames"),
                  to.file=TRUE),
      silent=TRUE)

  candidates <- c(
    file.path(dirs$pisa_extract,"PISA_header_selection_audit.csv"),
    file.path(dirs$pisa_extract,"PISA_header_unresolved.csv"),
    file.path(dirs$pisa_extract,"PISA_core_header_diagnostics.rds"),
    file.path(dirs$pisa_extract,"OECD_extraction_failures.txt"),
    file.path(dirs$pisa_extract,"unmapped_country_labels.csv"),
    file.path(dirs$pisa_results,"PISA_NL_sanity_checks.csv"),
    file.path(dirs$pisa_results,"PISA_internal_consistency_checks.csv"),
    file.path(dirs$pisa_results,"PISA_fixed32_failure.txt")
  )
  for(f in candidates[file.exists(candidates)]) {
    try(file.copy(f, AUTOPILOT_DIAG_DIR, overwrite=TRUE), silent=TRUE)
  }

  cat("\n============================================================\n")
  cat("AUTOPILOT STOPPED SAFELY\n")
  cat("A diagnostic folder was written to:\n", AUTOPILOT_DIAG_DIR, "\n", sep="")
  cat("No unresolved parser ambiguity was silently guessed.\n")
  cat("============================================================\n")
  invisible(NULL)
}

autopilot_error_handler <- function() {
  options(error=AUTOPILOT_PREVIOUS_ERROR_OPTION)
  try(autopilot_write_failure(geterrmessage()), silent=TRUE)
}

if(isTRUE(AUTOPILOT_MODE)) options(error=autopilot_error_handler)

writeLines(c(
  "Legacy dashboard export remains off; schema-v2.1 export is controlled separately in v1.3.",
  "Reason: revised 19 September 2026 dashboard specification must first be",
  "implemented and reviewed as a trial delivery before production export.",
  "Scientific PISA/PIRLS analysis modules continue to run."
), file.path(root, "DASHBOARD_PRODUCTION_EXPORT_HELD.txt"))


writeLines(c(
  "OECD CACHE POLICY — v1.2.1",
  "1. A valid canonical cached workbook is never downloaded again.",
  "2. If it is missing, exact-name valid local copies under Downloads are",
  "   reused before any network request.",
  "3. Network download is last resort only.",
  "4. FORCE_REDOWNLOAD_OECD=TRUE is the only normal way to force redownload.",
  "5. Cache decisions are logged in 01_registers/OECD_download_cache_audit.csv."
), file.path(root,"OECD_CACHE_POLICY.txt"))


# =============================================================================
# 3. PROJECT REGISTERS
# =============================================================================

caveats <- data.frame(
  id = c(
    "C01","C02","C03","C04","C05","C06","C07","C08","C09","C10","C11",
    "C12","C13","C14","C15","C16","C17","C18","C19","C20","C21","C22"
  ),
  issue = c(
    "PIRLS and PISA use different achievement scales",
    "PIRLS benchmark and PISA Level 2 are not the same latent threshold",
    "SES measurement changes over time",
    "National SES groups are relative within country/wave",
    "PIRLS Home Questionnaire non-response is substantial and selective",
    "PISA ESCS missingness varies across country/wave",
    "PISA school/student non-response affects sampling quality",
    "PISA exclusions/population coverage vary",
    "PIRLS 2021 COVID timing/mode differs across systems",
    "Plausible values and replicate weights are required",
    "PISA score linking adds link uncertainty",
    "Country ranks are statistically imprecise",
    "Balanced panels cost countries",
    "Country tercile membership changes by wave",
    "A smaller SES gap can reflect levelling down",
    "Percentage versus percentage-point difference",
    "P90-P10 is not a SES gap",
    "Assessment mode/framework/adaptive design change",
    "Geography/population definition can change",
    "PIRLS 2021 A5 bridge files must not replace R5 main files",
    "Books-at-home is a social-background proxy, not income or pure SES",
    "Historical OECD PISA releases can revise overlapping estimates"
  ),
  treatment = c(
    "Never join PIRLS and PISA scores into one continuous scale",
    "Interpret proficiency percentages within instrument/age; no literal cross-scale equality",
    "Use official harmonised indices where available and stable proxy sensitivities",
    "Label explicitly; add international ESCS analyses for absolute-position checks",
    "Use student books-at-home for long main PIRLS bridge; parent SES as robustness with response audit",
    "Plot non-missing rates and flag high-missing cells",
    "Keep school/student response in quality appendix and visible caveats for NL 2022/2025",
    "Plot exclusions/coverage and retain country-wave flags",
    "Main PIRLS panel uses comparable timing; Group-3 robustness separately",
    "All own estimates use full PV/replicate procedure",
    "Keep linking uncertainty separate from sampling uncertainty",
    "Show value + rank/N; where possible identify statistically indistinguishable systems",
    "Main = balanced; robustness = maximal available",
    "Reform terciles each wave within the same fixed underlying country panel and say so on slides",
    "Always show Q1/Q4 levels next to gap",
    "Report Q4-Q1 proficiency difference in percentage points",
    "Keep overall dispersion conceptually separate from SES inequality",
    "Annotate relevant design breaks; no causal attribution to the break without evidence",
    "Adjudicate country-wave inclusion before fixed-panel use",
    "Hard-lock R1/R2/R3/R4/R5 by wave; fail on A5 for 2021 main study",
    "Label transparently as books-at-home/social-background proxy; also show five substantive categories",
    "Audit 2015/2018/2022 overlap before any 2012–2025 splice"
  ),
  stringsAsFactors = FALSE
)
write.csv(caveats, file.path(dirs$registers, "caveat_register.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

figure_registry <- data.frame(
  figure_id = character(), title = character(), script = character(),
  data = character(), sample = character(), variables = character(),
  uncertainty = character(), output = character(), status = character(),
  change_reason = character(), stringsAsFactors = FALSE
)

register_figure <- function(id, title, data, sample, variables, uncertainty,
                            output, status = "concept", change_reason = "") {
  row <- data.frame(
    figure_id=id, title=title,
    script="PISA_PIRLS_MASTER_PIPELINE_v1_2_3_AUTOPILOT_HEADERFIX.R",
    data=data, sample=sample, variables=variables,
    uncertainty=uncertainty, output=output,
    status=status, change_reason=change_reason,
    stringsAsFactors = FALSE
  )
  figure_registry <<- rbind(figure_registry, row)
  write.csv(figure_registry, file.path(dirs$registers, "figure_registry.csv"),
            row.names = FALSE, fileEncoding = "UTF-8")
}


# =============================================================================
# 4. GENERIC HELPERS
# =============================================================================

clean_label <- function(x) {
  if (is.null(x) || length(x) == 0 || is.na(x[1])) return("")
  as.character(x)[1]
}

value_labels_string <- function(x) {
  labs <- attr(x, "labels", exact = TRUE)
  if (is.null(labs) || !length(labs)) return("")
  paste0(names(labs), "=", unname(labs), collapse = " | ")
}

valid_mask <- function(x) {
  z <- !is.na(x)
  labs <- attr(x, "labels", exact = TRUE)
  if (!is.null(labs) && length(labs)) {
    bad <- grepl(
      "OMIT|MISSING|NOT ADMIN|NOT APPLIC|LOGICALLY|INVALID|NO RESPONSE|NOT REACHED",
      toupper(names(labs))
    )
    if (any(bad)) z <- z & !(as.numeric(x) %in% unname(labs[bad]))
  }
  z
}

wmean <- function(y, w) {
  ok <- !is.na(y) & is.finite(y) & !is.na(w) & is.finite(w) & w > 0
  if (!any(ok)) return(NA_real_)
  sum(y[ok] * w[ok]) / sum(w[ok])
}

wmean01 <- function(ind, w) {
  wmean(as.numeric(ind), w)
}

wquantile_step <- function(y, w, p) {
  ok <- !is.na(y) & is.finite(y) & !is.na(w) & is.finite(w) & w > 0
  if (!any(ok)) return(NA_real_)
  yy <- y[ok]; ww <- w[ok]
  o <- order(yy)
  yy <- yy[o]; ww <- ww[o]
  cw <- cumsum(ww) / sum(ww)
  yy[which(cw >= p)[1]]
}

weighted_group <- function(y, w, probs = seq(0,1,0.1)) {
  # deterministic weighted quantile grouping for descriptive diagnostics
  cuts <- vapply(probs[-c(1,length(probs))], function(p) wquantile_step(y,w,p),
                 numeric(1))
  cut(y, breaks=c(-Inf,cuts,Inf), include.lowest=TRUE, labels=FALSE)
}

find_zip <- function(base, patterns) {
  zz <- list.files(base, pattern="\\.zip$", recursive=TRUE,
                   full.names=TRUE, ignore.case=TRUE)
  bn <- basename(zz)
  hit <- rep(FALSE, length(zz))
  for (p in patterns) hit <- hit | grepl(p, bn, ignore.case=TRUE)
  zz[hit]
}

is_valid_ooxml_workbook <- function(path) {
  if(!file.exists(path) || is.na(file.info(path)$size) || file.info(path)$size < 1000)
    return(FALSE)
  sig <- try(readBin(path, what="raw", n=2), silent=TRUE)
  if(inherits(sig,"try-error") || length(sig)<2 ||
     !identical(as.integer(sig), c(80L,75L))) return(FALSE)  # "PK"
  zz <- try(utils::unzip(path, list=TRUE), silent=TRUE)
  if(inherits(zz,"try-error") || !nrow(zz)) return(FALSE)
  any(grepl("\\[Content_Types\\]\\.xml$", zz$Name)) &&
    any(grepl("^xl/", zz$Name))
}

DOWNLOAD_CACHE_AUDIT <- data.frame(
  time=character(), source_url=character(), canonical_file=character(),
  action=character(), source_file=character(), bytes=double(),
  md5=character(), stringsAsFactors=FALSE
)

record_download_cache <- function(url,dest,action,source_file=dest) {
  fi <- if(file.exists(dest)) file.info(dest) else NULL
  md5 <- if(file.exists(dest)) unname(tools::md5sum(dest)) else NA_character_
  DOWNLOAD_CACHE_AUDIT <<- rbind(
    DOWNLOAD_CACHE_AUDIT,
    data.frame(
      time=as.character(Sys.time()),
      source_url=as.character(url),
      canonical_file=normalizePath(dest,winslash="/",mustWork=FALSE),
      action=as.character(action),
      source_file=normalizePath(source_file,winslash="/",mustWork=FALSE),
      bytes=if(is.null(fi)) NA_real_ else as.numeric(fi$size),
      md5=as.character(md5),
      stringsAsFactors=FALSE
    )
  )
  if(isTRUE(WRITE_DOWNLOAD_CACHE_AUDIT)) {
    write.csv(
      DOWNLOAD_CACHE_AUDIT,
      file.path(dirs$registers,"OECD_download_cache_audit.csv"),
      row.names=FALSE,fileEncoding="UTF-8"
    )
  }
  invisible(dest)
}

find_existing_local_oecd_copy <- function(dest) {
  if(!isTRUE(REUSE_LOCAL_OECD_ANYWHERE_IN_DOWNLOADS)) return(character())
  target_name <- basename(dest)

  # Exact filename only: do not guess that a differently named workbook is the
  # same source. This keeps cache reuse conservative and auditable.
  cand <- try(
    list.files(
      downloads,
      pattern=paste0("^",gsub("([][{}()+*^$|\\\\?.])","\\\\\\1",target_name),"$"),
      recursive=TRUE,full.names=TRUE,ignore.case=TRUE
    ),
    silent=TRUE
  )
  if(inherits(cand,"try-error") || !length(cand)) return(character())

  dest_norm <- normalizePath(dest,winslash="/",mustWork=FALSE)
  cand <- cand[
    normalizePath(cand,winslash="/",mustWork=FALSE) != dest_norm
  ]
  cand[vapply(cand,is_valid_ooxml_workbook,logical(1))]
}

safe_download <- function(url, dest) {
  dir.create(dirname(dest),recursive=TRUE,showWarnings=FALSE)

  # 1. Canonical cache always wins. A valid file is NEVER downloaded again
  #    unless FORCE_REDOWNLOAD_OECD is explicitly set to TRUE.
  if(file.exists(dest) && isTRUE(REUSE_CACHED_DOWNLOADS) &&
     !isTRUE(FORCE_REDOWNLOAD_OECD)) {
    if(is_valid_ooxml_workbook(dest)) {
      log_msg("cache hit — no network: ", basename(dest))
      record_download_cache(url,dest,"reused_canonical_cache",dest)
      return(dest)
    }
    log_msg("canonical cache exists but is invalid: ", basename(dest))
  }

  # 2. If the canonical cache is absent/invalid, first look for an exact-name
  #    valid copy anywhere under Downloads (including earlier pipeline folders).
  if(!isTRUE(FORCE_REDOWNLOAD_OECD)) {
    local <- find_existing_local_oecd_copy(dest)
    if(length(local)) {
      # Prefer the largest valid exact-name candidate; this is deterministic.
      sizes <- file.info(local)$size
      src <- local[order(sizes,decreasing=TRUE)][1]
      tmp <- paste0(dest,".localcopy")
      if(file.exists(tmp)) unlink(tmp,force=TRUE)
      ok <- file.copy(src,tmp,overwrite=TRUE,copy.mode=TRUE,copy.date=TRUE)
      if(isTRUE(ok) && is_valid_ooxml_workbook(tmp)) {
        if(file.exists(dest)) {
          backup <- paste0(dest,".invalid_",format(Sys.time(),"%Y%m%d_%H%M%S"))
          file.rename(dest,backup)
          log_msg("kept invalid old cache as: ",basename(backup))
        }
        if(!file.rename(tmp,dest)) {
          file.copy(tmp,dest,overwrite=TRUE)
          unlink(tmp,force=TRUE)
        }
        log_msg("local cache recovered — no network: ", basename(dest),
                " <- ", src)
        record_download_cache(url,dest,"reused_local_downloads_copy",src)
        return(dest)
      }
      if(file.exists(tmp)) unlink(tmp,force=TRUE)
    }
  }

  # 3. Network is the last resort only.
  methods <- c("libcurl","auto")
  attempts <- max(1L,as.integer(AUTOPILOT_MAX_DOWNLOAD_ATTEMPTS))
  last_error <- NULL

  for(attempt in seq_len(attempts)) {
    method <- methods[min(attempt,length(methods))]
    tmp <- paste0(dest,".part")
    if(file.exists(tmp)) unlink(tmp,force=TRUE)

    log_msg("NETWORK download attempt ",attempt,"/",attempts,
            " [",method,"]: ",url)
    ok <- try(
      utils::download.file(
        url,destfile=tmp,mode="wb",quiet=FALSE,method=method
      ),
      silent=TRUE
    )

    if(!inherits(ok,"try-error") && is_valid_ooxml_workbook(tmp)) {
      if(file.exists(dest)) {
        backup <- paste0(dest,".invalid_",format(Sys.time(),"%Y%m%d_%H%M%S"))
        file.rename(dest,backup)
      }
      if(!file.rename(tmp,dest)) {
        file.copy(tmp,dest,overwrite=TRUE)
        unlink(tmp,force=TRUE)
      }
      log_msg("validated network download: ",basename(dest),
              " (",file.info(dest)$size," bytes)")
      record_download_cache(url,dest,"downloaded_from_network",dest)
      return(dest)
    }

    last_error <- if(inherits(ok,"try-error")) as.character(ok) else
      "downloaded file was not a valid OOXML workbook"
    if(file.exists(tmp)) unlink(tmp,force=TRUE)
    Sys.sleep(min(2*attempt,5))
  }

  stop(
    "Download failed after ",attempts," attempts: ",url,
    "\nLast problem: ",last_error,
    "\nThe script first checked the canonical cache and exact-name local ",
    "copies under Downloads; network was used only because no valid local ",
    "copy was available."
  )
}

numify <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  x <- gsub("\\u00a0", " ", as.character(x), fixed=TRUE)
  x <- gsub("[(),*†‡a-zA-Z]", "", x)
  x <- gsub(" ", "", x, fixed=TRUE)
  x <- gsub(",", ".", x, fixed=TRUE)
  suppressWarnings(as.numeric(x))
}

norm_text <- function(x) {
  z <- toupper(trimws(as.character(x)))
  z <- gsub("[[:space:]]+", " ", z)
  z <- gsub("[–—−]", "-", z)
  z
}

country_name_standard <- function(x) {
  z <- trimws(as.character(x))
  map <- c(
    "Czech Republic"="Czechia",
    "Turkey"="Türkiye",
    "Republic of Korea"="Korea",
    "Korea, Republic of"="Korea",
    "Hong Kong-China"="Hong Kong (China)",
    "Hong Kong, China"="Hong Kong (China)",
    "Macao-China"="Macao (China)",
    "Macao, China"="Macao (China)",
    "Slovak Republic"="Slovak Republic",
    "Netherlands*"="Netherlands",
    "New Zealand*"="New Zealand",
    "Türkiye*"="Türkiye",
    "United States*"="United States",
    "United Kingdom*"="United Kingdom"
  )
  ii <- z %in% names(map)
  z[ii] <- unname(map[z[ii]])
  z <- sub("\\*$", "", z)
  z
}


# =============================================================================
# 5. VISUAL THEME / VECTOR EXPORT  (FORMATTING ONLY)
# =============================================================================

COL <- list(
  background = "#F7F5F0",
  text = "#17242D",
  muted = "#59636A",
  NL = "#315D8A",
  ses_fill = c("#EBC45A","#82A85B","#5EA6A7","#4C77A8","#6B5A8E"),
  ses_line = c("#9A6D00","#587A32","#2C807F","#4C77A8","#6A4C93"),
  context = "#C3C7C9",
  context_dark = "#8B9298",
  grid = "#D8D8D3",
  warning = "#984F3F"
)

project_font <- if ("Aptos" %in% names(grDevices::pdfFonts())) "Aptos" else "Arial"

theme_kansen <- function(base_size=16) {
  ggplot2::theme_minimal(base_size=base_size, base_family=project_font) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill=COL$background, colour=NA),
      panel.background = ggplot2::element_rect(fill=COL$background, colour=NA),
      plot.title = ggplot2::element_text(colour=COL$text, face="bold",
                                         size=20, hjust=0),
      plot.subtitle = ggplot2::element_text(colour=COL$muted, size=13, hjust=0),
      plot.caption = ggplot2::element_text(colour=COL$muted, size=9, hjust=0),
      axis.title = ggplot2::element_text(colour=COL$text, size=12),
      axis.text = ggplot2::element_text(colour=COL$text, size=11),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(colour=COL$grid, linewidth=.35),
      legend.position = "none",
      plot.margin = ggplot2::margin(12,18,12,12)
    )
}

export_vector <- function(plot, stem, width=11.2, height=6.3, data_files=NULL,
                          note=NULL) {
  svg <- paste0(stem, ".svg")
  pdf <- paste0(stem, ".pdf")
  ggplot2::ggsave(svg, plot=plot, width=width, height=height, units="in",
                  device=svglite::svglite, bg=COL$background)
  ggplot2::ggsave(pdf, plot=plot, width=width, height=height, units="in",
                  device=grDevices::cairo_pdf, bg=COL$background)

  # Best-effort embedding of source files into the PDF via Python/PyMuPDF.
  if (EMBED_SOURCES_IN_PDF_IF_POSSIBLE && length(data_files)) {
    py <- Sys.which(c("python","python3"))
    py <- py[nzchar(py)][1]
    if (!is.na(py) && nzchar(py)) {
      attach_py <- file.path(dirs$logs, "embed_pdf_sources.py")
      writeLines(c(
        "import sys, pathlib",
        "try:",
        " import fitz",
        "except Exception:",
        " sys.exit(2)",
        "pdf=pathlib.Path(sys.argv[1])",
        "files=[pathlib.Path(x) for x in sys.argv[2:]]",
        "doc=fitz.open(pdf)",
        "for p in files:",
        " if p.exists():",
        "  doc.embfile_add(p.name,p.read_bytes(),filename=p.name,ufilename=p.name,desc='Source file')",
        "tmp=pdf.with_name(pdf.stem+'_embedded.pdf')",
        "doc.save(tmp,garbage=4,deflate=True); doc.close(); tmp.replace(pdf)"
      ), attach_py)
      system2(py, c(shQuote(attach_py), shQuote(pdf),
                    vapply(data_files, shQuote, character(1))),
              stdout=FALSE, stderr=FALSE)
    }
  }
  if (!is.null(note)) writeLines(note, paste0(stem, "_note.txt"))
  invisible(c(svg=svg,pdf=pdf))
}


# =============================================================================
# 6. PIRLS RAW FILE DISCOVERY AND EXACT MAIN-FILE EXTRACTION
# =============================================================================

PIRLS_SUFFIX <- c(`2001`="R1",`2006`="R2",`2011`="R3",`2016`="R4",`2021`="R5")

discover_pirls_zips <- function() {
  z <- list(
    `2001` = find_zip(downloads, c("PIRLS2001.*SPSS")),
    `2006` = find_zip(downloads, c("PIRLS2006.*SPSS","P06.*SPSS")),
    `2011` = find_zip(downloads, c("PIRLS2011.*SPSS","P11_SPSSData_pt1","P11_SPSSData_pt2")),
    `2016` = find_zip(downloads, c("P16_SPSSData_pt1","P16_SPSSData_pt2","PIRLS2016.*SPSS")),
    `2021` = find_zip(downloads, c("PIRLS2021.*SPSS"))
  )
  miss <- names(z)[vapply(z,length,integer(1))==0]
  if (length(miss)) stop("Missing PIRLS ZIP(s): ", paste(miss,collapse=", "))
  z
}

extract_pirls_main_files <- function(zip_map, prefix="ASG") {
  prefix <- toupper(prefix)
  work <- file.path(dirs$pirls_extract, prefix)
  if (CLEAN_PIRLS_EXTRACT_EACH_RUN && dir.exists(work))
    unlink(work, recursive=TRUE, force=TRUE)
  dir.create(work, recursive=TRUE, showWarnings=FALSE)

  out <- list(); ii <- 1L
  for (yr in names(zip_map)) {
    suffix <- PIRLS_SUFFIX[[yr]]
    ydir <- file.path(work, yr)
    dir.create(ydir, recursive=TRUE, showWarnings=FALSE)

    for (zp in zip_map[[yr]]) {
      zl <- utils::unzip(zp, list=TRUE)
      bb <- toupper(basename(zl$Name))
      pat <- paste0("^",prefix,"[A-Z0-9]{3}",suffix,"\\.SAV$")
      keep <- grepl(pat, bb)
      members <- zl$Name[keep]
      if (!length(members)) next
      # Cache-first extraction: reuse exact existing SAVs when their
      # uncompressed byte size matches the zip member. This avoids rewriting
      # hundreds of unchanged PIRLS files on every Source().
      member_rows <- match(members,zl$Name)
      target_paths <- file.path(ydir,basename(members))
      expected_bytes <- zl$Length[member_rows]
      valid_existing <- file.exists(target_paths) &
        is.finite(expected_bytes) &
        (file.info(target_paths)$size == expected_bytes)
      to_extract <- members[!valid_existing]
      if(length(to_extract)) {
        utils::unzip(zp,files=to_extract,exdir=ydir,
                     junkpaths=TRUE,overwrite=TRUE)
      }
      if(any(valid_existing))
        log_msg("PIRLS ",prefix," cache: reused ",sum(valid_existing),
                " file(s) for ",yr)
      if(length(to_extract))
        log_msg("PIRLS ",prefix," extract: wrote ",length(to_extract),
                " file(s) for ",yr)
      for (m in members) {
        b <- toupper(basename(m))
        out[[ii]] <- data.frame(
          year=as.integer(yr),
          file_type=prefix,
          country_code3=substr(b,4,6),
          expected_suffix=suffix,
          selected_suffix=substr(tools::file_path_sans_ext(b),7,8),
          basename=basename(m), zip=zp,
          local_path=file.path(ydir,basename(m)),
          stringsAsFactors=FALSE
        )
        ii <- ii+1L
      }
    }
  }
  if (!length(out)) stop("No PIRLS ",prefix," main files extracted.")
  m <- do.call(rbind,out)
  key <- paste(m$year,m$country_code3,sep="_")
  dup <- unique(key[duplicated(key) | duplicated(key,fromLast=TRUE)])
  if (length(dup)) {
    write.csv(m[key %in% dup,], file.path(dirs$logs,paste0(prefix,"_duplicates.csv")),
              row.names=FALSE)
    stop("Duplicate PIRLS ",prefix," main files. See log.")
  }
  exp_suffix <- PIRLS_SUFFIX[as.character(m$year)]
  if (any(m$selected_suffix != unname(exp_suffix)))
    stop("Wrong PIRLS cycle suffix selected in ",prefix," manifest.")
  if (any(m$year==2021 & m$selected_suffix!="R5"))
    stop("FATAL: PIRLS 2021 main analysis selected non-R5 ",prefix," file.")
  m <- m[order(m$year,m$country_code3),]
  write.csv(m, file.path(dirs$pirls_audit,paste0(prefix,"_main_manifest.csv")),
            row.names=FALSE)
  m
}


# =============================================================================
# 7. PIRLS STUDENT-SIDE SOCIAL-BACKGROUND + HOME RESPONSE AUDITS
# =============================================================================

classify_student_resource <- function(var,label) {
  s <- toupper(paste(var,label))
  if (grepl("(AMOUNT|NUMBER|HOW MANY).*BOOK.*HOME|BOOKS AT HOME|BOOKS IN (THE )?HOME",s))
    return("books_home")
  if (grepl("CHILD.*BOOK|BOOKS FOR CHILD|OWN BOOKS",s)) return("child_own_books")
  if (grepl("STUDY DESK|DESK.*STUDY|DESK AT HOME",s)) return("study_desk")
  if (grepl("OWN ROOM|ROOM OF .* OWN",s)) return("own_room")
  if (grepl("INTERNET",s) && grepl("HOME|HAVE|ACCESS",s)) return("internet_home")
  if (grepl("COMPUTER|LAPTOP|TABLET|DIGITAL DEVICE",s) &&
      grepl("HOME|HAVE|ACCESS",s)) return("computer_device_home")
  if (grepl("HOME RESOURCE|RESOURCES FOR LEARNING|HOME POSSESSION",s))
    return("resource_index_or_item")
  NA_character_
}

find_books_var <- function(d) {
  preferred <- intersect(c("ASBGBOOK","ASBG04"),names(d))
  if (length(preferred)) return(preferred[1])
  labs <- vapply(d,function(x) clean_label(attr(x,"label",exact=TRUE)),character(1))
  hit <- grepl("BOOKS AT HOME|BOOKS IN (THE )?HOME|HOW MANY BOOKS",toupper(labs))
  cand <- names(d)[hit]
  cand <- cand[!grepl("CHILD|OWN BOOK",toupper(labs[cand]))]
  if (length(cand)!=1)
    stop("Could not identify exactly one books-at-home student variable. Candidates: ",
         paste(cand,collapse=", "))
  cand
}

recode_books_1to5 <- function(x,varname="") {
  num <- as.numeric(x)
  num[!valid_mask(x)] <- NA_real_
  labs <- attr(x,"labels",exact=TRUE)
  map <- NULL
  if (!is.null(labs) && length(labs)) {
    txt <- toupper(names(labs)); txt <- gsub("[–—−]","-",txt)
    val <- as.numeric(unname(labs)); rank <- rep(NA_integer_,length(val))
    rank[grepl("0[ -]*10|NONE OR VERY FEW|0 TO 10",txt)] <- 1L
    rank[grepl("11[ -]*25|11 TO 25",txt)] <- 2L
    rank[grepl("26[ -]*100|26 TO 100",txt)] <- 3L
    rank[grepl("101[ -]*200|101 TO 200",txt)] <- 4L
    rank[grepl("MORE THAN 200|OVER 200|> *200|201 OR MORE",txt)] <- 5L
    good <- !is.na(rank)
    if (sum(good)==5 && length(unique(rank[good]))==5)
      map <- setNames(rank[good],as.character(val[good]))
  }
  out <- rep(NA_real_,length(num))
  if (!is.null(map)) {
    ii <- !is.na(num) & as.character(num) %in% names(map)
    out[ii] <- as.numeric(map[as.character(num[ii])])
  } else {
    vals <- sort(unique(num[!is.na(num)]))
    if (length(vals)!=5)
      stop("Books variable ",varname," does not have five substantive categories.")
    out[!is.na(num)] <- match(num[!is.na(num)],vals)
  }
  if (length(unique(out[!is.na(out)]))!=5)
    stop("Failed harmonising ",varname," to five ordered categories.")
  out
}


cache_files_newer_than_inputs <- function(outputs,inputs) {
  outputs <- outputs[file.exists(outputs)]
  inputs <- inputs[file.exists(inputs)]
  if(!length(outputs) || !length(inputs)) return(FALSE)
  if(length(outputs) < 1L) return(FALSE)
  min(file.info(outputs)$mtime,na.rm=TRUE) >=
    max(file.info(inputs)$mtime,na.rm=TRUE)
}

read_csv_quiet <- function(path) {
  utils::read.csv(path,stringsAsFactors=FALSE,check.names=FALSE)
}

pirls_student_resource_audit <- function(asg_manifest) {
  dict_path <- file.path(dirs$pirls_audit,"student_resource_dictionary.csv")
  avail_path <- file.path(dirs$pirls_audit,"student_resource_availability.csv")
  if(isTRUE(REUSE_DERIVED_PIRLS_OUTPUTS) &&
     file.exists(dict_path) && file.exists(avail_path) &&
     cache_files_newer_than_inputs(c(dict_path,avail_path),asg_manifest$local_path)) {
    dict <- read_csv_quiet(dict_path)
    avail <- read_csv_quiet(avail_path)
    need_dict <- c("year","country_code3","variable","concept")
    need_avail <- c("year","country_code3","variable","concept")
    if(all(need_dict %in% names(dict)) && all(need_avail %in% names(avail))) {
      log_msg("PIRLS audit cache hit: student-resource audit")
      return(list(dictionary=dict,availability=avail))
    }
  }

  dict <- list(); di <- 1L
  avail <- list(); ai <- 1L

  for (i in seq_len(nrow(asg_manifest))) {
    f <- asg_manifest$local_path[i]
    d2 <- haven::read_sav(f,n_max=2)
    labs <- vapply(d2,function(x) clean_label(attr(x,"label",exact=TRUE)),
                   character(1))
    concepts <- mapply(classify_student_resource,names(d2),labs,USE.NAMES=FALSE)
    cand <- names(d2)[!is.na(concepts)]
    for (nm in cand) {
      dict[[di]] <- data.frame(
        year=asg_manifest$year[i],
        country_code3=asg_manifest$country_code3[i],
        variable=nm,label=labs[[nm]],
        concept=classify_student_resource(nm,labs[[nm]]),
        value_labels=value_labels_string(d2[[nm]]),
        stringsAsFactors=FALSE
      ); di <- di+1L
    }

    d <- haven::read_sav(f)
    w <- if ("TOTWGT" %in% names(d)) as.numeric(d$TOTWGT) else rep(1,nrow(d))
    for (nm in intersect(cand,names(d))) {
      vm <- valid_mask(d[[nm]])
      avail[[ai]] <- data.frame(
        year=asg_manifest$year[i],country_code3=asg_manifest$country_code3[i],
        variable=nm,label=clean_label(attr(d[[nm]],"label",exact=TRUE)),
        concept=classify_student_resource(
          nm,clean_label(attr(d[[nm]],"label",exact=TRUE))),
        n=nrow(d),nonmissing_unweighted=mean(vm),
        nonmissing_weighted=wmean01(vm,w),
        stringsAsFactors=FALSE
      ); ai <- ai+1L
    }
  }
  dict <- if(length(dict)) do.call(rbind,dict) else data.frame()
  avail <- if(length(avail)) do.call(rbind,avail) else data.frame()
  write.csv(dict,file.path(dirs$pirls_audit,"student_resource_dictionary.csv"),
            row.names=FALSE)
  write.csv(avail,file.path(dirs$pirls_audit,"student_resource_availability.csv"),
            row.names=FALSE)
  list(dictionary=dict,availability=avail)
}

home_substantive_response <- function(h) {
  # Raw Home Questionnaire items begin ASBH; derived variables commonly ASDH.
  cand <- grep("^ASBH",names(h),value=TRUE)
  cand <- setdiff(cand,c("ASBHID","ASBHWT"))
  if (!length(cand)) return(rep(NA,length.out=nrow(h)))
  mat <- sapply(cand,function(nm) valid_mask(h[[nm]]))
  if (is.vector(mat)) mat <- matrix(mat,ncol=1)
  rowSums(mat,na.rm=TRUE)>0
}

pirls_home_response_audit <- function(asg_manifest,ash_manifest) {
  resp_path <- file.path(dirs$pirls_audit,"home_response_country_year.csv")
  dec_path <- file.path(dirs$pirls_audit,"NL_home_response_by_achievement_decile.csv")
  all_inputs <- c(asg_manifest$local_path,ash_manifest$local_path)
  if(isTRUE(REUSE_DERIVED_PIRLS_OUTPUTS) &&
     file.exists(resp_path) && file.exists(dec_path) &&
     cache_files_newer_than_inputs(c(resp_path,dec_path),all_inputs)) {
    response <- read_csv_quiet(resp_path)
    nl_dec <- read_csv_quiet(dec_path)
    if(all(c("year","country_code3","response_weighted") %in% names(response))) {
      log_msg("PIRLS audit cache hit: home-response audit")
      return(list(response=response,nl_deciles=nl_dec))
    }
  }

  keys <- merge(
    asg_manifest[,c("year","country_code3","local_path")],
    ash_manifest[,c("year","country_code3","local_path")],
    by=c("year","country_code3"),suffixes=c("_asg","_ash")
  )
  rows <- list(); ri <- 1L
  decrows <- list(); dri <- 1L

  for (i in seq_len(nrow(keys))) {
    s <- haven::read_sav(keys$local_path_asg[i])
    h <- haven::read_sav(keys$local_path_ash[i])
    key <- intersect(c("IDSTUD","IDSTUDS"),intersect(names(s),names(h)))
    if (!length(key)) next
    key <- key[1]
    h$HOME_SUBSTANTIVE_RESPONSE <- home_substantive_response(h)
    hh <- h[,c(key,"HOME_SUBSTANTIVE_RESPONSE")]
    mm <- merge(s,hh,by=key,all.x=TRUE)
    mm$HOME_SUBSTANTIVE_RESPONSE[is.na(mm$HOME_SUBSTANTIVE_RESPONSE)] <- FALSE
    w <- as.numeric(mm$TOTWGT)
    rows[[ri]] <- data.frame(
      year=keys$year[i],country_code3=keys$country_code3[i],
      response_unweighted=mean(mm$HOME_SUBSTANTIVE_RESPONSE),
      response_weighted=wmean01(mm$HOME_SUBSTANTIVE_RESPONSE,w),
      n=nrow(mm),stringsAsFactors=FALSE
    ); ri <- ri+1L

    if (keys$country_code3[i]=="NLD") {
      pvs <- grep("^ASRREA0[1-5]$",names(mm),value=TRUE)
      if (length(pvs)==5) {
        ach <- rowMeans(as.data.frame(lapply(mm[pvs],as.numeric)),na.rm=TRUE)
        dec <- weighted_group(ach,w,seq(0,1,.1))
        for (dd in sort(unique(dec[!is.na(dec)]))) {
          use <- dec==dd
          decrows[[dri]] <- data.frame(
            year=keys$year[i],decile=dd,
            response_weighted=wmean01(mm$HOME_SUBSTANTIVE_RESPONSE[use],w[use]),
            n=sum(use,na.rm=TRUE),stringsAsFactors=FALSE
          ); dri <- dri+1L
        }
      }
    }
  }
  response <- if(length(rows)) do.call(rbind,rows) else data.frame()
  nl_dec <- if(length(decrows)) do.call(rbind,decrows) else data.frame()
  write.csv(response,file.path(dirs$pirls_audit,"home_response_country_year.csv"),
            row.names=FALSE)
  write.csv(nl_dec,file.path(dirs$pirls_audit,"NL_home_response_by_achievement_decile.csv"),
            row.names=FALSE)
  list(response=response,nl_deciles=nl_dec)
}


# =============================================================================
# 8. PIRLS Q1/Q4 FRACTIONAL TAILS + FIVE-CATEGORY ESTIMATOR
# =============================================================================

make_tail_shares <- function(book_rank,w,target=.25) {
  ok <- !is.na(book_rank) & book_rank %in% 1:5 &
        !is.na(w) & is.finite(w) & w>0
  q1 <- q4 <- rep(0,length(book_rank))
  if (!any(ok)) return(list(q1=q1,q4=q4,q1_cat=NA,q4_cat=NA,
                            q1_fraction=NA,q4_fraction=NA,
                            overlap_category=FALSE,valid_weight=0,
                            category_weight_share=rep(NA,5)))
  W <- tapply(w[ok],book_rank[ok],sum)
  cats <- 1:5; wc <- setNames(rep(0,5),cats); wc[names(W)] <- W
  total <- sum(wc); need <- target*total
  q1frac <- q4frac <- setNames(rep(0,5),cats)

  rem <- need
  for (cc in cats) {
    if (rem<=0) break
    ww <- wc[as.character(cc)]
    if (ww<=rem+1e-12) {
      q1frac[as.character(cc)] <- if(ww>0) 1 else 0; rem <- rem-ww
    } else if (ww>0) {
      q1frac[as.character(cc)] <- rem/ww; rem <- 0
    }
  }
  rem <- need
  for (cc in rev(cats)) {
    if (rem<=0) break
    ww <- wc[as.character(cc)]
    if (ww<=rem+1e-12) {
      q4frac[as.character(cc)] <- if(ww>0) 1 else 0; rem <- rem-ww
    } else if (ww>0) {
      q4frac[as.character(cc)] <- rem/ww; rem <- 0
    }
  }
  q1[ok] <- q1frac[as.character(book_rank[ok])]
  q4[ok] <- q4frac[as.character(book_rank[ok])]
  q1bc <- suppressWarnings(max(as.numeric(names(q1frac)[q1frac>0]),na.rm=TRUE))
  q4bc <- suppressWarnings(min(as.numeric(names(q4frac)[q4frac>0]),na.rm=TRUE))
  if(!is.finite(q1bc)) q1bc <- NA
  if(!is.finite(q4bc)) q4bc <- NA
  q1share <- sum(w*q1,na.rm=TRUE)/total
  q4share <- sum(w*q4,na.rm=TRUE)/total
  if(abs(q1share-target)>1e-8 || abs(q4share-target)>1e-8)
    stop("Fractional quartile construction failed.")
  list(
    q1=q1,q4=q4,q1_cat=q1bc,q4_cat=q4bc,
    q1_fraction=if(!is.na(q1bc)) q1frac[as.character(q1bc)] else NA,
    q4_fraction=if(!is.na(q4bc)) q4frac[as.character(q4bc)] else NA,
    overlap_category=any(q1frac>0 & q4frac>0),
    valid_weight=total,category_weight_share=wc/total
  )
}

pirls_stat_vector <- function(y,books,w) {
  tails <- make_tail_shares(books,w,PIRLS_QTAIL)
  q1w <- w*tails$q1; q4w <- w*tails$q4

  out <- c(
    mean_reading=wmean(y,w),
    prof_ge475=wmean(as.numeric(y>=PIRLS_MIN_PROF),w),
    high_ge550=wmean(as.numeric(y>=PIRLS_HIGH),w),
    advanced_ge625=wmean(as.numeric(y>=PIRLS_ADVANCED),w),
    p10=wquantile_step(y,w,.10),
    p50=wquantile_step(y,w,.50),
    p90=wquantile_step(y,w,.90),
    q1_mean_reading=wmean(y,q1w),
    q4_mean_reading=wmean(y,q4w),
    q1_prof_ge475=wmean(as.numeric(y>=PIRLS_MIN_PROF),q1w),
    q4_prof_ge475=wmean(as.numeric(y>=PIRLS_MIN_PROF),q4w),
    q1_high_ge550=wmean(as.numeric(y>=PIRLS_HIGH),q1w),
    q4_high_ge550=wmean(as.numeric(y>=PIRLS_HIGH),q4w)
  )

  # Five substantive books-at-home categories remain available as an additional
  # descriptive / robustness output. They are not called quintiles.
  for (k in 1:5) {
    wk <- w*as.numeric(books==k)
    out[paste0("books",k,"_mean_reading")] <- wmean(y,wk)
    out[paste0("books",k,"_prof_ge475")] <- wmean(as.numeric(y>=PIRLS_MIN_PROF),wk)
  }

  c(out,
    p90_p10_scoregap=unname(out["p90"]-out["p10"]),
    q4_q1_scoregap=unname(out["q4_mean_reading"]-out["q1_mean_reading"]),
    q4_q1_profgap=unname(out["q4_prof_ge475"]-out["q1_prof_ge475"]))
}

pirls_pv_jk2_estimate <- function(d,country_code,year) {
  pv_names <- grep("^ASRREA0[1-5]$",names(d),value=TRUE)
  if(length(pv_names)!=5)
    stop(country_code," ",year,": expected 5 overall-reading plausible values.")
  if(!all(c("TOTWGT","JKZONE","JKREP") %in% names(d)))
    stop(country_code," ",year,": missing TOTWGT/JKZONE/JKREP.")
  books_name <- find_books_var(d)
  books <- recode_books_1to5(d[[books_name]],books_name)

  w0 <- as.numeric(d$TOTWGT)
  zone <- as.numeric(d$JKZONE); repc <- as.numeric(d$JKREP)
  base_ok <- !is.na(w0)&is.finite(w0)&w0>0&!is.na(zone)&!is.na(repc)
  zones <- sort(unique(zone[base_ok]))
  if(!length(zones)) stop(country_code," ",year,": no JKZONE values.")

  tail0 <- make_tail_shares(books,w0,PIRLS_QTAIL)
  theta_m <- list(); rep_failures <- integer(5)

  for(m in seq_along(pv_names)) {
    y <- as.numeric(d[[pv_names[m]]])
    theta0 <- pirls_stat_vector(y,books,w0)
    sq <- setNames(rep(0,length(theta0)),names(theta0))
    nfail <- 0L
    for(h in zones) {
      in_h <- base_ok & zone==h
      for(keep in c(0,1)) {
        wr <- w0
        wr[in_h & repc==keep] <- 2*w0[in_h & repc==keep]
        wr[in_h & repc!=keep] <- 0
        tr <- try(pirls_stat_vector(y,books,wr),silent=TRUE)
        if(inherits(tr,"try-error")) { nfail <- nfail+1L; next }
        dif <- tr-theta0; ok <- is.finite(dif)
        sq[ok] <- sq[ok]+dif[ok]^2
      }
    }
    attr(theta0,"sampling_var") <- .5*sq
    theta_m[[m]] <- theta0
    rep_failures[m] <- nfail
  }

  theta_mat <- do.call(rbind,theta_m)
  rows <- vector("list",ncol(theta_mat))
  for(s in seq_len(ncol(theta_mat))) {
    nm <- colnames(theta_mat)[s]
    vals <- theta_mat[,nm]
    U <- mean(vapply(theta_m,function(z) attr(z,"sampling_var")[[nm]],numeric(1)),
              na.rm=TRUE)
    B <- if(sum(is.finite(vals))>=2) stats::var(vals,na.rm=TRUE) else NA_real_
    theta <- mean(vals,na.rm=TRUE)
    imp <- (1+1/PIRLS_PV_M)*B
    tot <- U+imp; se <- sqrt(tot)
    rows[[s]] <- data.frame(
      year=as.integer(year),country_code3=country_code,statistic=nm,
      estimate=theta,sampling_variance=U,pv_imputation_variance=imp,
      total_variance=tot,se=se,ci_low=theta-1.96*se,ci_high=theta+1.96*se,
      stringsAsFactors=FALSE
    )
  }

  valid_books <- !is.na(books)&!is.na(w0)&w0>0
  diag <- data.frame(
    year=as.integer(year),country_code3=country_code,n_students=nrow(d),
    n_jkzones=length(zones),books_variable=books_name,
    books_nonmissing_unweighted=mean(!is.na(books)),
    books_nonmissing_weighted=sum(w0[valid_books])/sum(w0[w0>0],na.rm=TRUE),
    q1_boundary_category=tail0$q1_cat,q1_boundary_fraction=tail0$q1_fraction,
    q4_boundary_category=tail0$q4_cat,q4_boundary_fraction=tail0$q4_fraction,
    q1_q4_same_category_flag=tail0$overlap_category,
    replicate_stat_failures=sum(rep_failures),
    stringsAsFactors=FALSE
  )
  for(k in 1:5) diag[[paste0("books_cat",k,"_share")]] <-
    tail0$category_weight_share[[as.character(k)]]

  list(estimates=do.call(rbind,rows),diagnostics=diag,pv_full=theta_mat)
}


# =============================================================================
# 9. PIRLS VALIDATION, MAIN-13, ROBUST-16, RANKS AND DYNAMIC TERCILES
# =============================================================================

valid_cached_pirls_panel <- function(est,dg,expected) {
  need_est <- c(
    "year","country_code3","statistic","estimate","sampling_variance",
    "pv_imputation_variance","total_variance","se","ci_low","ci_high"
  )
  need_dg <- c("year","country_code3","n_students","n_jkzones")
  if(!all(need_est %in% names(est)) || !all(need_dg %in% names(dg)))
    return(FALSE)

  ek <- sort(unique(paste(expected$year,expected$country_code3,sep="_")))
  ak <- sort(unique(paste(est$year,est$country_code3,sep="_")))
  dk <- sort(unique(paste(dg$year,dg$country_code3,sep="_")))
  if(!identical(ek,ak) || !identical(ek,dk)) return(FALSE)
  if(anyDuplicated(paste(dg$year,dg$country_code3,sep="_"))) return(FALSE)

  ss <- split(as.character(est$statistic),
              paste(est$year,est$country_code3,sep="_"))
  stat_sets <- lapply(ss,function(x) sort(unique(x)))
  if(!length(stat_sets) || any(vapply(stat_sets,length,integer(1))==0L))
    return(FALSE)
  ref <- stat_sets[[1]]
  if(!all(vapply(stat_sets,function(x) identical(x,ref),logical(1))))
    return(FALSE)

  TRUE
}

run_pirls_panel <- function(asg_manifest,codes,label) {
  use <- asg_manifest[asg_manifest$country_code3 %in% codes,]
  expected <- expand.grid(year=as.integer(names(PIRLS_SUFFIX)),
                          country_code3=codes,stringsAsFactors=FALSE)
  missing <- expected[
    !paste(expected$year,expected$country_code3,sep="_") %in%
      paste(use$year,use$country_code3,sep="_"),]
  if(nrow(missing)) {
    write.csv(missing,file.path(dirs$pirls_results,paste0(label,"_missing_cells.csv")),
              row.names=FALSE)
    stop(label,": missing PIRLS country-wave cells.")
  }

  est_path <- file.path(dirs$pirls_results,paste0(label,"_estimates_long.csv"))
  dg_path <- file.path(dirs$pirls_results,paste0(label,"_diagnostics.csv"))

  if(isTRUE(REUSE_DERIVED_PIRLS_OUTPUTS) &&
     file.exists(est_path) && file.exists(dg_path) &&
     cache_files_newer_than_inputs(c(est_path,dg_path),use$local_path)) {
    est0 <- read_csv_quiet(est_path)
    dg0 <- read_csv_quiet(dg_path)
    if(valid_cached_pirls_panel(est0,dg0,expected)) {
      log_msg("PIRLS ",label,
              ": verified result-cache hit — no replicate-weight recomputation")
      return(list(estimates=est0,diagnostics=dg0,cache_status="reused_verified"))
    }
    log_msg("PIRLS ",label,
            ": existing result cache failed structural validation; rebuilding")
  }

  est <- list(); dg <- list(); ei <- di <- 1L
  for(i in seq_len(nrow(use))) {
    log_msg("PIRLS ",label,": ",use$year[i]," ",use$country_code3[i])
    d <- haven::read_sav(use$local_path[i])
    z <- pirls_pv_jk2_estimate(d,use$country_code3[i],use$year[i])
    est[[ei]] <- z$estimates; ei <- ei+1L
    dg[[di]] <- z$diagnostics; di <- di+1L
  }
  est <- do.call(rbind,est); dg <- do.call(rbind,dg)
  write.csv(est,est_path,row.names=FALSE)
  write.csv(dg,dg_path,row.names=FALSE)

  if(!valid_cached_pirls_panel(est,dg,expected))
    stop(label,": newly computed PIRLS panel failed structural cache validation.")

  list(estimates=est,diagnostics=dg,cache_status="rebuilt")
}

validate_pirls_2021 <- function(est) {
  m <- est[est$year==2021 & est$statistic=="mean_reading" &
             est$country_code3 %in% names(PIRLS_2021_VALIDATION_MEANS),]
  m$official_rounded <- PIRLS_2021_VALIDATION_MEANS[m$country_code3]
  m$abs_diff <- abs(m$estimate-m$official_rounded)
  m$pass <- m$abs_diff <= PIRLS_VALIDATION_TOLERANCE
  write.csv(m,file.path(dirs$pirls_results,"validation_2021_main_means.csv"),
            row.names=FALSE)
  if(STRICT_VALIDATION && (nrow(m)!=length(PIRLS_2021_VALIDATION_MEANS) ||
                           any(!m$pass))) {
    stop("PIRLS 2021 validation failed. Do not continue to Main-13. See validation CSV.")
  }
  m
}

rank_and_terciles <- function(wide,country_col="country_code3",
                              year_col="year",metric,direction=c("high","low")) {
  direction <- match.arg(direction)
  rows <- list(); tr <- list(); ri <- ti <- 1L
  for(yr in sort(unique(wide[[year_col]]))) {
    g <- wide[wide[[year_col]]==yr & is.finite(wide[[metric]]),]
    g <- g[order(g[[metric]],g[[country_col]]),]
    n <- nrow(g)
    if(direction=="high") {
      g$rank <- rank(-g[[metric]],ties.method="min")
      raw_order <- order(g[[metric]],g[[country_col]])
    } else {
      g$rank <- rank(g[[metric]],ties.method="min")
      raw_order <- order(g[[metric]],g[[country_col]])
    }
    rows[[ri]] <- g; ri <- ri+1L

    # Terciles are always lower/middle/upper by the raw metric itself.
    # Interpretation (good/bad) is stated separately in figures.
    gg <- g[raw_order,]
    p <- (seq_len(n)-.5)/n
    gg$tercile <- ifelse(p<=1/3,"Onderste derde",
                         ifelse(p<=2/3,"Middelste derde","Bovenste derde"))
    tr[[ti]] <- gg; ti <- ti+1L
  }
  list(ranks=do.call(rbind,rows),assignments=do.call(rbind,tr))
}

pirls_estimates_wide <- function(est) {
  keys <- unique(est[,c("year","country_code3")])
  for(stat in unique(est$statistic)) {
    x <- est[est$statistic==stat,c("year","country_code3","estimate","se")]
    names(x)[3:4] <- c(stat,paste0(stat,"_se"))
    keys <- merge(keys,x,by=c("year","country_code3"),all.x=TRUE)
  }
  keys
}


# =============================================================================
# 10. PIRLS PARENT-SES ROBUSTNESS PREPARATION (NO SILENT COMPLETE-CASE CLAIM)
# =============================================================================

detect_parent_ses_vars <- function(h) {
  labs <- vapply(h,function(x) clean_label(attr(x,"label",exact=TRUE)),character(1))
  nm <- names(h)
  data.frame(
    variable=nm,label=labs,
    concept=ifelse(
      nm %in% c("ASDHEDUP") | grepl("HIGHEST.*EDUCATION|PARENT.*EDUCATION",toupper(labs)),
      "parent_education",
      ifelse(
        nm %in% c("ASDHOCCP") | grepl("HIGHEST.*OCCUP|PARENT.*OCCUP",toupper(labs)),
        "parent_occupation",
        ifelse(grepl("HOME SOCIO.*ECON|HOME SES",toupper(labs)),"official_home_ses",
          ifelse(grepl("HOME RESOURCES",toupper(labs)),"official_home_resources",NA_character_)
        )
      )
    ),
    stringsAsFactors=FALSE
  )
}

prepare_parent_ses_robustness <- function(ash_manifest) {
  cache_path <- file.path(dirs$pirls_audit,"parent_SES_variable_dictionary.csv")
  if(isTRUE(REUSE_DERIVED_PIRLS_OUTPUTS) && file.exists(cache_path) &&
     cache_files_newer_than_inputs(cache_path,ash_manifest$local_path)) {
    z <- read_csv_quiet(cache_path)
    if(all(c("year","country_code3","variable","concept") %in% names(z))) {
      log_msg("PIRLS audit cache hit: parent-SES variable dictionary")
      return(z)
    }
  }

  out <- list(); oi <- 1L
  for(i in seq_len(nrow(ash_manifest))) {
    h2 <- haven::read_sav(ash_manifest$local_path[i],n_max=2)
    d <- detect_parent_ses_vars(h2)
    d <- d[!is.na(d$concept),]
    if(nrow(d)) {
      d$year <- ash_manifest$year[i]
      d$country_code3 <- ash_manifest$country_code3[i]
      out[[oi]] <- d; oi <- oi+1L
    }
  }
  z <- if(length(out)) do.call(rbind,out) else data.frame()
  write.csv(z,file.path(dirs$pirls_audit,"parent_SES_variable_dictionary.csv"),
            row.names=FALSE)
  # No adjusted parent-SES result is estimated here: the response model must
  # remain explicit and separately audited.
  z
}


# =============================================================================
# 11. OECD PISA OFFICIAL WORKBOOKS — DOWNLOAD AND RAW EXTRACTION
# =============================================================================

OECD_URLS <- c(
  pisa2025_performance = "https://stat.link/mrq53f",
  pisa2025_ses = "https://stat.link/k68msa",
  pisa2025_gender = "https://stat.link/68stqn",
  pisa2025_immigrant = "https://stat.link/6gtbnx",
  pisa2025_school_life = "https://stat.link/xmra2f",
  pisa2025_samples = "https://stat.link/pe3lsg",
  pisa2022_trends = "https://stat.link/wh9d4z",
  pisa2022_equity = "https://stat.link/3mudz9",
  pisa2022_samples = "https://stat.link/hpg9nd",
  pisa2018_samples = "https://doi.org/10.1787/888934028862"
)

download_oecd_workbooks <- function() {
  paths <- setNames(file.path(dirs$raw_oecd,paste0(names(OECD_URLS),".xlsx")),
                    names(OECD_URLS))
  if(RUN_PISA_OFFICIAL_DOWNLOAD && AUTO_DOWNLOAD_OECD) {
    for(nm in names(paths)) {
      # 2018 DOI sometimes downloads via a redirect; download.file usually follows.
      try(safe_download(OECD_URLS[[nm]],paths[[nm]]),silent=FALSE)
    }
  }
  paths
}

find_sheet_for_table <- function(xlsx,table_id) {
  sh <- readxl::excel_sheets(xlsx)
  hit <- which(grepl(gsub("\\.","\\\\.",table_id),sh,ignore.case=TRUE))
  if(length(hit)==1) return(sh[hit])
  # Fallback: scan the first six rows of every sheet.
  for(s in sh) {
    x <- try(readxl::read_excel(xlsx,sheet=s,col_names=FALSE,n_max=6),
             silent=TRUE)
    if(inherits(x,"try-error")) next
    txt <- paste(unlist(x),collapse=" ")
    if(grepl(table_id,txt,fixed=TRUE)) return(s)
  }
  NA_character_
}


# Selectively reconstruct horizontally merged OECD header cells. readxl keeps
# the label only in the top-left cell of a merge. We propagate only rows that
# contain multiple structural group labels; single-cell title/source rows are
# never propagated.
oecd_reconstruct_header_matrix <- function(raw, hdr_rows) {
  m <- matrix("", nrow=length(hdr_rows), ncol=ncol(raw))
  structural_pattern <- paste(c(
    "PISA",
    "20(00|03|06|09|12|15|18|22|25)",
    "CHANGE","DIFFERENCE","PERCENTILE","PROFICIENCY","LEVEL",
    "QUARTER","Q1","Q4","DISADVANTAGED","ADVANTAGED","ESCS",
    "GIRL","BOY","GENDER","IMMIGR","LANGUAGE","BETWEEN","WITHIN"
  ), collapse="|")

  for(ii in seq_along(hdr_rows)) {
    z <- trimws(as.character(unlist(raw[hdr_rows[ii],,drop=FALSE])))
    z[is.na(z) | z=="NA"] <- ""
    m[ii,] <- z

    nz <- which(nzchar(z))
    if(length(nz) < 2L || !isTRUE(AUTOPILOT_RECONSTRUCT_MERGED_HEADERS))
      next
    if(!any(grepl(structural_pattern,norm_text(z[nz]),perl=TRUE)))
      next

    # Fill each merged group up to (but not including) the next explicit label.
    for(k in seq_len(length(nz)-1L)) {
      from <- nz[k] + 1L
      to <- nz[k+1L] - 1L
      if(from <= to) m[ii,from:to] <- z[nz[k]]
    }

    # Extend a final structural group to the end of the table when appropriate.
    last_label <- norm_text(z[nz[length(nz)]])
    if(grepl(structural_pattern,last_label,perl=TRUE) &&
       nz[length(nz)] < ncol(raw)) {
      m[ii,(nz[length(nz)]+1L):ncol(raw)] <- z[nz[length(nz)]]
    }
  }
  m
}

oecd_compose_headers <- function(raw, hdr_rows) {
  raw_m <- matrix("", nrow=length(hdr_rows), ncol=ncol(raw))
  for(ii in seq_along(hdr_rows)) {
    z <- trimws(as.character(unlist(raw[hdr_rows[ii],,drop=FALSE])))
    z[is.na(z) | z=="NA"] <- ""
    raw_m[ii,] <- z
  }
  rec_m <- oecd_reconstruct_header_matrix(raw,hdr_rows)

  compose <- function(v) {
    v <- trimws(as.character(v))
    v <- v[nzchar(v) & v!="NA"]
    paste(unique(v),collapse=" | ")
  }

  list(
    raw=vapply(seq_len(ncol(raw)),
               function(j) compose(raw_m[,j]),character(1)),
    reconstructed=vapply(seq_len(ncol(raw)),
               function(j) compose(c(raw_m[,j],rec_m[,j])),character(1))
  )
}

extract_oecd_table_long <- function(xlsx,table_id,country_reference=NULL) {
  sheet <- find_sheet_for_table(xlsx,table_id)
  if(is.na(sheet)) stop("OECD sheet not found: ",table_id," in ",basename(xlsx))
  raw <- readxl::read_excel(xlsx,sheet=sheet,col_names=FALSE,.name_repair="minimal")
  raw <- as.data.frame(raw,stringsAsFactors=FALSE)

  if(is.null(country_reference)) {
    country_reference <- unique(c(
      PISA_FIXED32_NAMES,"Austria","Chile","Colombia","Estonia","Israel",
      "Lithuania","Luxembourg","Slovenia","Spain","United Kingdom","United States",
      "OECD average","OECD average-35","OECD average-23"
    ))
  }

  # Country column = column containing the greatest number of recognised labels.
  counts <- vapply(raw,function(col) {
    z <- country_name_standard(col)
    sum(z %in% country_reference,na.rm=TRUE)
  },numeric(1))
  ccol <- which.max(counts)
  if(!length(ccol) || counts[ccol]<3)
    stop("Could not identify country column in ",table_id)

  countries <- country_name_standard(raw[[ccol]])
  data_rows <- which(countries %in% country_reference)
  if(!length(data_rows)) stop("No country rows detected in ",table_id)
  first_data <- min(data_rows)

  hdr_rows <- seq_len(first_data-1)
  hh <- oecd_compose_headers(raw,hdr_rows)
  headers_raw <- hh$raw
  headers <- hh$reconstructed

  keep_rows <- data_rows
  res <- list(); ri <- 1L
  for(j in seq_along(raw)) {
    if(j==ccol) next
    vals <- numify(raw[keep_rows,j])
    if(all(is.na(vals))) next
    res[[ri]] <- data.frame(
      table_id=table_id,sheet=sheet,
      country=countries[keep_rows],
      column_index=j,header_raw=headers_raw[j],header=headers[j],
      value=vals,stringsAsFactors=FALSE
    ); ri <- ri+1L
  }
  if(!length(res)) stop("No numeric country cells extracted from ",table_id)
  do.call(rbind,res)
}


oecd_workbook_signature <- function(paths) {
  pp <- unique(unname(paths[file.exists(paths)]))
  pp <- sort(normalizePath(pp,winslash="/",mustWork=TRUE))
  if(!length(pp)) return(data.frame())
  info <- file.info(pp)
  data.frame(
    path=pp,
    bytes=as.numeric(info$size),
    mtime=as.numeric(info$mtime),
    md5=unname(tools::md5sum(pp)),
    stringsAsFactors=FALSE
  )
}

same_oecd_signature <- function(a,b) {
  if(!is.data.frame(a) || !is.data.frame(b)) return(FALSE)
  cols <- c("path","bytes","md5")
  if(!all(cols %in% names(a)) || !all(cols %in% names(b))) return(FALSE)
  aa <- a[order(a$path),cols,drop=FALSE]
  bb <- b[order(b$path),cols,drop=FALSE]
  identical(aa,bb)
}

archive_previous_diagnostic <- function(path) {
  if(!file.exists(path)) return(invisible(FALSE))
  stem <- tools::file_path_sans_ext(basename(path))
  ext <- tools::file_ext(path)
  archived <- file.path(
    dirname(path),
    paste0(stem,"_previous_",format(Sys.time(),"%Y%m%d_%H%M%S"),
           if(nzchar(ext)) paste0(".",ext) else "")
  )
  ok <- file.rename(path,archived)
  invisible(ok)
}

extract_oecd_targets <- function(paths) {
  registry <- list(
    # 2025 performance/proficiency
    "I.B1.2a.33"="pisa2025_performance",
    "I.B1.2a.34"="pisa2025_performance",
    "I.B1.2a.35"="pisa2025_performance",
    "I.B1.2a.36"="pisa2025_performance",
    "I.B1.2a.37"="pisa2025_performance",
    "I.B1.2a.38"="pisa2025_performance",
    "I.B1.2a.39"="pisa2025_performance",
    "I.B1.2a.40"="pisa2025_performance",
    "I.B1.2a.41"="pisa2025_performance",
    "I.B1.2a.42"="pisa2025_performance",
    "I.B1.2a.43"="pisa2025_performance",
    "I.B1.2a.44"="pisa2025_performance",

    # 2025 SES/equity
    "I.B1.2b.6"="pisa2025_ses",
    "I.B1.2b.7"="pisa2025_ses",
    "I.B1.2b.8"="pisa2025_ses",
    "I.B1.2b.9"="pisa2025_ses",
    "I.B1.2b.10"="pisa2025_ses",
    "I.B1.2b.11"="pisa2025_ses",
    "I.B1.2b.12"="pisa2025_ses",
    "I.B1.2b.13"="pisa2025_ses",
    "I.B1.2b.17"="pisa2025_ses",
    "I.B1.2b.18"="pisa2025_ses",
    "I.B1.2b.23"="pisa2025_ses",
    "I.B1.2b.24"="pisa2025_ses",
    "I.B1.2b.26"="pisa2025_ses",
    "I.B1.2b.27"="pisa2025_ses",
    "I.B1.2b.29"="pisa2025_ses",
    "I.B1.2b.30"="pisa2025_ses",
    "I.B1.2b.32"="pisa2025_ses",
    "I.B1.2b.33"="pisa2025_ses",
    "I.B1.2b.34"="pisa2025_ses",

    # 2025 intersectional equity
    "I.B1.2c.18"="pisa2025_gender",
    "I.B1.2c.21"="pisa2025_gender",
    "I.B1.2c.26"="pisa2025_gender",
    "I.B1.2c.27"="pisa2025_gender",
    "I.B1.2c.28"="pisa2025_gender",
    "I.B1.2d.3"="pisa2025_immigrant",
    "I.B1.2d.6"="pisa2025_immigrant",
    "I.B1.2d.8"="pisa2025_immigrant",
    "I.B1.2d.11"="pisa2025_immigrant",
    "I.B1.2d.14"="pisa2025_immigrant",

    # 2022 overlap/revision audit
    "I.B1.5.20"="pisa2022_trends",
    "I.B1.5.23"="pisa2022_trends",
    "I.B1.5.26"="pisa2022_trends",
    "I.B1.5.28"="pisa2022_trends",
    "I.B1.4.12"="pisa2022_equity",
    "I.B1.4.35"="pisa2022_equity",
    "I.B1.4.38"="pisa2022_equity",
    "I.B1.4.40"="pisa2022_equity"
  )

  out <- list(); oi <- 1L
  failures <- list()
  for(tid in names(registry)) {
    wb <- paths[[registry[[tid]]]]
    if(is.null(wb) || !file.exists(wb)) next
    x <- try(extract_oecd_table_long(wb,tid),silent=TRUE)
    if(inherits(x,"try-error")) {
      failures[[tid]] <- as.character(x)
    } else {
      out[[oi]] <- x; oi <- oi+1L
    }
  }
  z <- if(length(out)) do.call(rbind,out) else data.frame()
  saveRDS(list(cells=z,failures=failures,registry=registry),
          file.path(dirs$pisa_extract,"OECD_official_target_cells.rds"),
          compress="xz")
  if(nrow(z)) write.csv(z,file.path(dirs$pisa_extract,"OECD_official_target_cells.csv"),
                        row.names=FALSE)
  if(length(failures))
    writeLines(unlist(lapply(names(failures),function(nm)
      paste(nm,failures[[nm]],sep=": "))),
      file.path(dirs$pisa_extract,"OECD_extraction_failures.txt"))
  result
}


# =============================================================================
# 12. PISA CORE READING STANDARDISATION FROM OFFICIAL TABLE CELLS
# =============================================================================
#
# OECD StatLink workbooks have multi-row headers. We retain the full concatenated
# header string per column, then identify the required estimate columns with
# conservative regular expressions. Ambiguity causes a diagnostic failure;
# nothing is silently guessed.
# =============================================================================

PISA_HEADER_SELECTION_AUDIT <- data.frame(
  table_id=character(),year=integer(),concept=character(),
  selection_method=character(),selected_column=integer(),
  selected_header_raw=character(),selected_header=character(),
  reconstructed_header=logical(),candidate_columns=character(),
  stringsAsFactors=FALSE
)

append_pisa_header_audit <- function(tbl,year,concept,method,
                                     selected=NA_integer_,candidates=integer()) {
  tid <- if("table_id"%in%names(tbl) && nrow(tbl))
    as.character(tbl$table_id[1]) else NA_character_
  hdr <- if(length(selected)==1L && is.finite(selected)) {
    u <- unique(tbl$header[tbl$column_index==selected])
    if(length(u)) u[1] else NA_character_
  } else NA_character_
  hdr_raw <- if(length(selected)==1L && is.finite(selected) &&
                "header_raw"%in%names(tbl)) {
    u <- unique(tbl$header_raw[tbl$column_index==selected])
    if(length(u)) u[1] else NA_character_
  } else NA_character_

  PISA_HEADER_SELECTION_AUDIT <<- rbind(
    PISA_HEADER_SELECTION_AUDIT,
    data.frame(
      table_id=tid,year=as.integer(year),concept=as.character(concept),
      selection_method=as.character(method),
      selected_column=if(length(selected)==1L && is.finite(selected))
        as.integer(selected) else NA_integer_,
      selected_header_raw=hdr_raw,
      selected_header=hdr,
      reconstructed_header=!is.na(hdr_raw) && !is.na(hdr) &&
        !identical(hdr_raw,hdr),
      candidate_columns=paste(sort(unique(candidates)),collapse=";"),
      stringsAsFactors=FALSE
    )
  )
}

candidate_columns_numerically_identical <- function(tbl,cols,tol=1e-12) {
  if(length(cols)<2L) return(TRUE)
  base <- tbl[tbl$column_index==cols[1],c("country","value"),drop=FALSE]
  names(base)[2] <- "v0"
  for(k in seq_along(cols)[-1]) {
    z <- tbl[tbl$column_index==cols[k],c("country","value"),drop=FALSE]
    names(z)[2] <- "vk"
    m <- merge(base,z,by="country",all=TRUE)
    both_na <- is.na(m$v0) & is.na(m$vk)
    same <- both_na | (is.finite(m$v0) & is.finite(m$vk) &
                         abs(m$v0-m$vk)<=tol)
    if(!all(same)) return(FALSE)
  }
  TRUE
}

pick_oecd_column <- function(tbl,year,include,exclude=NULL,quarter=NULL,
                             concept=NULL) {
  if(is.null(concept))
    concept <- paste(include,if(is.null(quarter)) "" else quarter,sep=" | ")
  h <- norm_text(tbl$header)

  generic_exclude <- paste(c(
    "S\\.E\\.","STANDARD ERROR","STD\\.? ERROR",
    "CHANGE","DIFFERENCE","DIFF\\.",
    "TREND","DECENNIAL","COEF\\.?","COEFFICIENT",
    "CONFIDENCE INTERVAL","95% CI","SIGNIFICAN",
    "P-VALUE","P VALUE"
  ),collapse="|")

  ex <- generic_exclude
  if(!is.null(exclude) && nzchar(exclude))
    ex <- paste(ex,exclude,sep="|")

  base <- grepl(as.character(year),h,fixed=TRUE) &
          grepl(include,h,perl=TRUE)
  if(!is.null(quarter))
    base <- base & grepl(quarter,h,perl=TRUE)

  ok <- base & !grepl(ex,h,perl=TRUE)
  cols <- sort(unique(tbl$column_index[ok]))

  if(length(cols)==1L) {
    append_pisa_header_audit(tbl,year,concept,"unique_after_safe_filters",
                             selected=cols,candidates=cols)
    x <- tbl[tbl$column_index==cols,c("country","value")]
    names(x)[2] <- "value"
    return(list(ok=TRUE,data=x,column=cols,
                selection_method="unique_after_safe_filters"))
  }

  if(length(cols)>1L &&
     isTRUE(AUTOPILOT_ALLOW_IDENTICAL_DUPLICATE_COLUMNS) &&
     candidate_columns_numerically_identical(tbl,cols)) {
    chosen <- min(cols)
    append_pisa_header_audit(tbl,year,concept,"identical_duplicate_columns",
                             selected=chosen,candidates=cols)
    x <- tbl[tbl$column_index==chosen,c("country","value")]
    names(x)[2] <- "value"
    return(list(ok=TRUE,data=x,column=chosen,
                selection_method="identical_duplicate_columns",
                duplicate_columns=cols))
  }

  append_pisa_header_audit(tbl,year,concept,"unresolved",
                           selected=NA_integer_,candidates=cols)
  diag_cols <- intersect(c("column_index","header_raw","header"),names(tbl))
  diag <- unique(tbl[,diag_cols,drop=FALSE])
  list(ok=FALSE,columns=cols,diagnostic=diag,
       selection_method="unresolved")
}

pisa_table <- function(cells,id) cells[cells$table_id==id,]

flatten_pisa_parser_failures <- function(failures,ses_failures) {
  rows <- list(); ri <- 1L

  add_one <- function(scope,yr,concept,z) {
    cols <- z$columns
    if(is.null(cols)) cols <- integer()

    if(!length(cols)) {
      rows[[ri]] <<- data.frame(
        scope=scope,year=as.integer(yr),concept=concept,
        column_index=NA_integer_,header_raw=NA_character_,header=NA_character_,
        reason="no_candidate_after_safe_filters",stringsAsFactors=FALSE
      )
      ri <<- ri+1L
      return(invisible(NULL))
    }

    d <- z$diagnostic[z$diagnostic$column_index %in% cols,,drop=FALSE]
    if(!nrow(d)) {
      for(cc in cols) {
        rows[[ri]] <<- data.frame(
          scope=scope,year=as.integer(yr),concept=concept,
          column_index=as.integer(cc),header_raw=NA_character_,header=NA_character_,
          reason="multiple_nonidentical_candidates",stringsAsFactors=FALSE
        )
        ri <<- ri+1L
      }
      return(invisible(NULL))
    }

    for(j in seq_len(nrow(d))) {
      rows[[ri]] <<- data.frame(
        scope=scope,year=as.integer(yr),concept=concept,
        column_index=as.integer(d$column_index[j]),
        header_raw=if("header_raw"%in%names(d))
          as.character(d$header_raw[j]) else NA_character_,
        header=if("header"%in%names(d))
          as.character(d$header[j]) else NA_character_,
        reason="multiple_nonidentical_candidates",stringsAsFactors=FALSE
      )
      ri <<- ri+1L
    }
    invisible(NULL)
  }

  for(yr in names(failures))
    for(nm in names(failures[[yr]]))
      if(!isTRUE(failures[[yr]][[nm]]$ok))
        add_one("long",yr,nm,failures[[yr]][[nm]])

  for(yr in names(ses_failures))
    for(nm in names(ses_failures[[yr]]))
      if(!isTRUE(ses_failures[[yr]][[nm]]$ok))
        add_one("ses",yr,nm,ses_failures[[yr]][[nm]])

  if(length(rows)) do.call(rbind,rows) else data.frame()
}

pisa_build_core_reading <- function(cells) {
  years <- c(2003,2006,2009,2012,2015,2018,2022,2025)
  sesyears <- c(2015,2018,2022,2025)

  PISA_HEADER_SELECTION_AUDIT <<- PISA_HEADER_SELECTION_AUDIT[0,,drop=FALSE]

  mean_t <- pisa_table(cells,"I.B1.2a.37")
  low_t  <- pisa_table(cells,"I.B1.2a.34")
  dist_t <- pisa_table(cells,"I.B1.2a.40")
  ses_t  <- pisa_table(cells,"I.B1.2b.29")

  missing_tables <- c(
    if(!nrow(mean_t)) "I.B1.2a.37",
    if(!nrow(low_t)) "I.B1.2a.34",
    if(!nrow(dist_t)) "I.B1.2a.40",
    if(!nrow(ses_t)) "I.B1.2b.29"
  )
  if(length(missing_tables))
    stop("Missing core PISA official table(s) after extraction: ",
         paste(missing_tables,collapse=", "),
         ". Check OECD_extraction_failures.txt.")

  long <- list(); li <- 1L; failures <- list()

  for(yr in years) {
    a <- pick_oecd_column(mean_t,yr,
      include="MEAN SCORE|AVERAGE SCORE|AVERAGE READING SCORE",
      exclude="S\\.E\\.|STANDARD ERROR|CHANGE|DIFFERENCE|TREND|DECENNIAL|COEF\\.?|COEFFICIENT",
      concept="mean_read")
    b <- pick_oecd_column(low_t,yr,
      include="BELOW LEVEL 2|LOW PERFORM",
      exclude="S\\.E\\.|STANDARD ERROR|TOP",
      concept="below_level2")
    p10 <- pick_oecd_column(dist_t,yr,
      include="10TH|P10|10 PERCENT",
      exclude="S\\.E\\.|STANDARD ERROR|TREND|DECENNIAL|COEF\\.?|COEFFICIENT",
      concept="p10")
    p50 <- pick_oecd_column(dist_t,yr,
      include="50TH|P50|MEDIAN|50 PERCENT",
      exclude="S\\.E\\.|STANDARD ERROR|TREND|DECENNIAL|COEF\\.?|COEFFICIENT",
      concept="p50")
    p90 <- pick_oecd_column(dist_t,yr,
      include="90TH|P90|90 PERCENT",
      exclude="S\\.E\\.|STANDARD ERROR|TREND|DECENNIAL|COEF\\.?|COEFFICIENT",
      concept="p90")

    zz <- list(mean=a,low=b,p10=p10,p50=p50,p90=p90)
    if(!all(vapply(zz,function(z) isTRUE(z$ok),logical(1)))) {
      failures[[as.character(yr)]] <- zz
      next
    }

    z <- Reduce(function(x,y) merge(x,y,by="country",all=TRUE),
      list(
        setNames(a$data,c("country","mean_read")),
        setNames(b$data,c("country","low")),
        setNames(p10$data,c("country","p10")),
        setNames(p50$data,c("country","p50")),
        setNames(p90$data,c("country","p90"))
      ))
    z$year <- as.integer(yr)
    z$prof <- 100-z$low
    z$p90_p10 <- z$p90-z$p10
    long[[li]] <- z
    li <- li+1L
  }

  long <- if(length(long)) do.call(rbind,long) else data.frame()

  ses <- list(); si <- 1L; ses_failures <- list()
  for(yr in sesyears) {
    q1 <- pick_oecd_column(ses_t,yr,
      include="BELOW LEVEL 2|LOW PERFORM",
      exclude="S\\.E\\.|STANDARD ERROR",
      quarter="FIRST QUARTER|BOTTOM QUARTER|QUARTER 1|Q1|\\bDISADVANTAGED\\b",
      concept="q1_below_level2")
    q4 <- pick_oecd_column(ses_t,yr,
      include="BELOW LEVEL 2|LOW PERFORM",
      exclude="S\\.E\\.|STANDARD ERROR",
      quarter="FOURTH QUARTER|TOP QUARTER|QUARTER 4|Q4|\\bADVANTAGED\\b",
      concept="q4_below_level2")

    if(!isTRUE(q1$ok) || !isTRUE(q4$ok)) {
      ses_failures[[as.character(yr)]] <- list(q1=q1,q4=q4)
      next
    }

    z <- merge(setNames(q1$data,c("country","q1_low")),
               setNames(q4$data,c("country","q4_low")),
               by="country",all=TRUE)
    z$year <- as.integer(yr)
    z$q1_prof <- 100-z$q1_low
    z$q4_prof <- 100-z$q4_low
    z$gap <- z$q4_prof-z$q1_prof
    ses[[si]] <- z
    si <- si+1L
  }
  ses <- if(length(ses)) do.call(rbind,ses) else data.frame()

  write.csv(PISA_HEADER_SELECTION_AUDIT,
            file.path(dirs$pisa_extract,"PISA_header_selection_audit.csv"),
            row.names=FALSE,fileEncoding="UTF-8")

  unresolved <- flatten_pisa_parser_failures(failures,ses_failures)
  if(nrow(unresolved)) {
    write.csv(unresolved,
              file.path(dirs$pisa_extract,"PISA_header_unresolved.csv"),
              row.names=FALSE,fileEncoding="UTF-8")
    saveRDS(list(long=failures,ses=ses_failures),
            file.path(dirs$pisa_extract,"PISA_core_header_diagnostics.rds"),
            compress="xz")
  }

  long_years <- if(nrow(long) && "year"%in%names(long))
    sort(unique(as.integer(long$year))) else integer()
  ses_years_found <- if(nrow(ses) && "year"%in%names(ses))
    sort(unique(as.integer(ses$year))) else integer()

  missing_long <- setdiff(years,long_years)
  missing_ses <- setdiff(sesyears,ses_years_found)

  if(length(missing_long) || length(missing_ses) || nrow(unresolved)) {
    stop(
      "AUTOPILOT could not resolve all PISA core headers without guessing.",
      "\nMissing long years: ",
      if(length(missing_long)) paste(missing_long,collapse=", ") else "none",
      "\nMissing SES years: ",
      if(length(missing_ses)) paste(missing_ses,collapse=", ") else "none",
      "\nSee: ",
      file.path(dirs$pisa_extract,"PISA_header_unresolved.csv"),
      "\nHeader audit: ",
      file.path(dirs$pisa_extract,"PISA_header_selection_audit.csv")
    )
  }


  # Semantic audit of selected source headers. This is deliberately stricter
  # than the regex selector: if a future OECD workbook changes layout, fail
  # rather than silently treating a trend/coefficient as a level estimate.
  selected_audit <- PISA_HEADER_SELECTION_AUDIT[
    PISA_HEADER_SELECTION_AUDIT$selection_method!="unresolved" &
      is.finite(PISA_HEADER_SELECTION_AUDIT$selected_column),
    ,drop=FALSE
  ]
  forbidden_level_terms <- "TREND|DECENNIAL|COEF\\.?|COEFFICIENT|CHANGE|DIFFERENCE"
  bad_level <- grepl(
    forbidden_level_terms,
    norm_text(selected_audit$selected_header),
    perl=TRUE
  )
  if(any(bad_level)) {
    bad <- selected_audit[bad_level,,drop=FALSE]
    write.csv(
      bad,
      file.path(dirs$pisa_extract,"PISA_header_semantic_safety_failure.csv"),
      row.names=FALSE,fileEncoding="UTF-8"
    )
    stop(
      "PISA semantic header audit rejected a trend/change/coefficient column. ",
      "See PISA_header_semantic_safety_failure.csv."
    )
  }

  q4_rows <- selected_audit$concept=="q4_below_level2"
  if(any(q4_rows)) {
    q4h <- norm_text(selected_audit$selected_header[q4_rows])
    bad_q4 <- grepl("\\bDISADVANTAGED\\b|BOTTOM QUARTER|FIRST QUARTER",q4h,perl=TRUE)
    if(any(bad_q4)) {
      bad <- selected_audit[q4_rows,,drop=FALSE][bad_q4,,drop=FALSE]
      write.csv(
        bad,
        file.path(dirs$pisa_extract,"PISA_q4_semantic_safety_failure.csv"),
        row.names=FALSE,fileEncoding="UTF-8"
      )
      stop(
        "PISA Q4 selector resolved to a disadvantaged/bottom-quarter header. ",
        "See PISA_q4_semantic_safety_failure.csv."
      )
    }
  }

  required_long <- c("country","year","mean_read","low","prof","p10","p50","p90","p90_p10")
  required_ses <- c("country","year","q1_low","q4_low","q1_prof","q4_prof","gap")
  if(!all(required_long %in% names(long)))
    stop("PISA long output schema incomplete: missing ",
         paste(setdiff(required_long,names(long)),collapse=", "))
  if(!all(required_ses %in% names(ses)))
    stop("PISA SES output schema incomplete: missing ",
         paste(setdiff(required_ses,names(ses)),collapse=", "))

  # Successful resolution: preserve old failure diagnostics with timestamps,
  # but remove them from the "current" filenames.
  for(stale in c(
    file.path(dirs$pisa_extract,"PISA_header_unresolved.csv"),
    file.path(dirs$pisa_extract,"PISA_core_header_diagnostics.rds"),
    file.path(dirs$pisa_extract,"PISA_header_semantic_safety_failure.csv"),
    file.path(dirs$pisa_extract,"PISA_q4_semantic_safety_failure.csv")
  )) {
    if(file.exists(stale)) {
      archived <- file.path(
        dirname(stale),
        paste0(
          tools::file_path_sans_ext(basename(stale)),
          "_resolved_previous_",
          format(Sys.time(),"%Y%m%d_%H%M%S"),
          if(nzchar(tools::file_ext(stale)))
            paste0(".",tools::file_ext(stale)) else ""
        )
      )
      try(file.rename(stale,archived),silent=TRUE)
    }
  }

  list(long=long,ses=ses,failures=failures,ses_failures=ses_failures,
       header_audit=PISA_HEADER_SELECTION_AUDIT)
}

validate_pisa_internal_consistency <- function(long,ses) {
  problems <- character()

  bad_order <- which(
    is.finite(long$p10) & is.finite(long$p50) & is.finite(long$p90) &
    !(long$p10 <= long$p50 & long$p50 <= long$p90)
  )
  if(length(bad_order))
    problems <- c(problems,paste0("percentile_order_violations=",length(bad_order)))

  bad_prof <- which(is.finite(long$prof) & (long$prof<0 | long$prof>100))
  if(length(bad_prof))
    problems <- c(problems,paste0("long_proficiency_out_of_range=",length(bad_prof)))

  bad_ses <- which(
    (is.finite(ses$q1_prof) & (ses$q1_prof<0 | ses$q1_prof>100)) |
    (is.finite(ses$q4_prof) & (ses$q4_prof<0 | ses$q4_prof>100))
  )
  if(length(bad_ses))
    problems <- c(problems,paste0("ses_proficiency_out_of_range=",length(bad_ses)))

  dup_long <- duplicated(long[,c("country","year")])
  dup_ses <- duplicated(ses[,c("country","year")])
  if(any(dup_long))
    problems <- c(problems,paste0("duplicate_long_country_year=",sum(dup_long)))
  if(any(dup_ses))
    problems <- c(problems,paste0("duplicate_ses_country_year=",sum(dup_ses)))

  report <- data.frame(
    check=c("percentile_order","long_proficiency_range","ses_proficiency_range",
            "unique_long_country_year","unique_ses_country_year"),
    pass=c(!length(bad_order),!length(bad_prof),!length(bad_ses),
           !any(dup_long),!any(dup_ses)),
    n_problem=c(length(bad_order),length(bad_prof),length(bad_ses),
                sum(dup_long),sum(dup_ses)),
    stringsAsFactors=FALSE
  )
  write.csv(report,
            file.path(dirs$pisa_results,"PISA_internal_consistency_checks.csv"),
            row.names=FALSE)

  if(length(problems))
    stop("PISA internal consistency validation failed: ",
         paste(problems,collapse="; "),
         ". See PISA_internal_consistency_checks.csv.")
  report
}

validate_pisa_nl <- function(long,ses) {
  required_long <- c("country","year","mean_read","prof")
  required_ses <- c("country","year","q1_prof","q4_prof")

  miss_l <- setdiff(required_long,names(long))
  miss_s <- setdiff(required_ses,names(ses))
  if(length(miss_l) || length(miss_s)) {
    stop("PISA validation received incomplete data.",
         "\nMissing long columns: ",paste(miss_l,collapse=", "),
         "\nMissing SES columns: ",paste(miss_s,collapse=", "))
  }

  getv <- function(df,yr,var) {
    x <- df[df$country=="Netherlands" & as.integer(df$year)==as.integer(yr),
            var,drop=TRUE]
    x <- x[is.finite(x)]
    if(length(x)!=1L) return(NA_real_)
    as.numeric(x)
  }

  checks <- data.frame(
    check=c("mean_read_2003","mean_read_2025","prof_2003","prof_2025",
            "q1_prof_2015","q4_prof_2015","q1_prof_2025","q4_prof_2025"),
    estimate=c(
      getv(long,2003,"mean_read"),
      getv(long,2025,"mean_read"),
      getv(long,2003,"prof"),
      getv(long,2025,"prof"),
      getv(ses,2015,"q1_prof"),
      getv(ses,2015,"q4_prof"),
      getv(ses,2025,"q1_prof"),
      getv(ses,2025,"q4_prof")
    ),
    target=c(
      PISA_NL_SANITY$mean_read_2003,
      PISA_NL_SANITY$mean_read_2025,
      PISA_NL_SANITY$prof_2003,
      PISA_NL_SANITY$prof_2025,
      PISA_NL_SANITY$q1_prof_2015,
      PISA_NL_SANITY$q4_prof_2015,
      PISA_NL_SANITY$q1_prof_2025,
      PISA_NL_SANITY$q4_prof_2025
    ),
    stringsAsFactors=FALSE
  )
  checks$abs_diff <- abs(checks$estimate-checks$target)
  checks$pass <- is.finite(checks$estimate) & checks$abs_diff<=2

  write.csv(checks,file.path(dirs$pisa_results,"PISA_NL_sanity_checks.csv"),
            row.names=FALSE)

  if(any(!is.finite(checks$estimate))) {
    bad <- checks$check[!is.finite(checks$estimate)]
    stop("PISA parser produced missing Netherlands validation estimate(s): ",
         paste(bad,collapse=", "),
         ". See PISA_NL_sanity_checks.csv.")
  }
  if(STRICT_VALIDATION && any(!checks$pass)) {
    bad <- checks$check[!checks$pass]
    stop("PISA official-table parser failed Netherlands sanity checks: ",
         paste(bad,collapse=", "),
         ". See PISA_NL_sanity_checks.csv.")
  }
  checks
}

make_fixed_panel <- function(df,panel,years,required_vars) {
  x <- df[df$country %in% panel & df$year %in% years,]
  for(v in required_vars) x <- x[is.finite(x[[v]]),]
  tab <- table(x$country,x$year)
  good <- rownames(tab)[rowSums(tab>0)==length(years)]
  x <- x[x$country %in% good,]
  list(data=x,members=good)
}

pisa_fixed32_products <- function(core) {
  lp <- make_fixed_panel(core$long,PISA_FIXED32_NAMES,
                         c(2003,2006,2009,2012,2015,2018,2022,2025),
                         c("mean_read","prof","p90_p10"))
  sp <- make_fixed_panel(core$ses,PISA_FIXED32_NAMES,
                         c(2015,2018,2022,2025),
                         c("q1_prof","q4_prof","gap"))

  if(STRICT_VALIDATION &&
     (!setequal(lp$members,PISA_FIXED32_NAMES) ||
      !setequal(sp$members,PISA_FIXED32_NAMES))) {
    writeLines(c("Long missing:",setdiff(PISA_FIXED32_NAMES,lp$members),
                 "SES missing:",setdiff(PISA_FIXED32_NAMES,sp$members)),
               file.path(dirs$pisa_results,"PISA_fixed32_failure.txt"))
    stop("Could not reproduce the locked fixed-32 PISA panel.")
  }

  long <- lp$data; ses <- sp$data
  write.csv(long,file.path(dirs$pisa_results,"PISA_fixed32_long_country_year.csv"),
            row.names=FALSE)
  write.csv(ses,file.path(dirs$pisa_results,"PISA_fixed32_SES_country_year.csv"),
            row.names=FALSE)
  write.csv(data.frame(country=PISA_FIXED32_NAMES),
            file.path(dirs$pisa_results,"PISA_fixed32_panel_members.csv"),
            row.names=FALSE)

  # Ranks of Netherlands: rank 1 highest for levels/proficiency, smallest for gaps/spread.
  ranks_long <- do.call(rbind,lapply(sort(unique(long$year)),function(yr) {
    g <- long[long$year==yr,]
    data.frame(
      year=yr,
      rank_mean=rank(-g$mean_read,ties.method="min")[g$country=="Netherlands"],
      rank_prof=rank(-g$prof,ties.method="min")[g$country=="Netherlands"],
      rank_spread=rank(g$p90_p10,ties.method="min")[g$country=="Netherlands"]
    )
  }))
  ranks_ses <- do.call(rbind,lapply(sort(unique(ses$year)),function(yr) {
    g <- ses[ses$year==yr,]
    data.frame(
      year=yr,
      rank_q1=rank(-g$q1_prof,ties.method="min")[g$country=="Netherlands"],
      rank_q4=rank(-g$q4_prof,ties.method="min")[g$country=="Netherlands"],
      rank_gap=rank(g$gap,ties.method="min")[g$country=="Netherlands"]
    )
  }))
  write.csv(ranks_long,file.path(dirs$pisa_results,"PISA_NL_ranks_long.csv"),
            row.names=FALSE)
  write.csv(ranks_ses,file.path(dirs$pisa_results,"PISA_NL_ranks_SES.csv"),
            row.names=FALSE)

  list(long=long,ses=ses,ranks_long=ranks_long,ranks_ses=ranks_ses)
}


# =============================================================================
# 13. PISA 2022-vs-2025 OVERLAP / REVISION AUDIT
# =============================================================================

pisa_overlap_audit <- function(cells2025) {
  # Raw cells are retained even if the automatic standardisation of the 2022
  # release cannot safely infer every header. This function creates a searchable
  # audit extract and NEVER splices 2012 automatically.
  oldids <- c("I.B1.5.20","I.B1.5.23","I.B1.5.26","I.B1.5.28")
  newids <- c("I.B1.2b.23","I.B1.2b.26","I.B1.2b.29","I.B1.2b.32")
  old <- cells2025[cells2025$table_id %in% oldids,]
  new <- cells2025[cells2025$table_id %in% newids,]
  saveRDS(list(old_release_cells=old,new_release_cells=new,
               rule="Do not splice 2012 until overlapping 2015/2018/2022 cells are reconciled."),
          file.path(dirs$pisa_results,"PISA_2022_2025_overlap_audit_raw.rds"),
          compress="xz")
  invisible(list(old=old,new=new))
}


# =============================================================================
# 14. PISA MICRODATA AUDIT HOOK (OPTIONAL)
# =============================================================================

discover_pisa_student_zips <- function() {
  list(
    `2018`=find_zip(downloads,c("^SPSS_STU_QQQ","PISA2018.*STU")),
    `2022`=find_zip(downloads,c("^STU_QQQ_SPSS","PISA2022.*STU")),
    `2025`=find_zip(downloads,c("CY09_MS_STU_PUF","PISA2025.*STU"))
  )
}

pisa_microdata_dictionary_audit <- function() {
  zz <- discover_pisa_student_zips()
  rows <- list(); ri <- 1L
  for(yr in names(zz)) {
    if(!length(zz[[yr]])) next
    zp <- zz[[yr]][1]
    zl <- utils::unzip(zp,list=TRUE)
    bb <- basename(zl$Name)
    hit <- grepl("\\.SAV$",toupper(bb)) &
      grepl("STU",toupper(bb))
    if(!any(hit)) next
    member <- zl$Name[which(hit)[1]]
    tmp <- file.path(dirs$pisa_extract,"microdata_audit",yr)
    dir.create(tmp,recursive=TRUE,showWarnings=FALSE)
    utils::unzip(zp,files=member,exdir=tmp,junkpaths=TRUE,overwrite=TRUE)
    f <- file.path(tmp,basename(member))
    d <- haven::read_sav(f,n_max=2)
    labs <- vapply(d,function(x) clean_label(attr(x,"label",exact=TRUE)),character(1))
    nm <- names(d)
    keep <- grepl(
      "ESCS|PARED|HISEI|BOOKS|BOOK.*HOME|HOMEPOS|PARENT.*EDUC|PARENT.*OCCUP|W_FSTUWT|PV[0-9]+READ",
      toupper(paste(nm,labs))
    )
    if(any(keep)) {
      rows[[ri]] <- data.frame(year=as.integer(yr),variable=nm[keep],
                               label=labs[keep],stringsAsFactors=FALSE)
      ri <- ri+1L
    }
  }
  z <- if(length(rows)) do.call(rbind,rows) else data.frame()
  write.csv(z,file.path(dirs$pisa_extract,"PISA_microdata_equity_dictionary.csv"),
            row.names=FALSE)
  z
}


# =============================================================================
# 15. TIMSS GRADE-4 FUTURE DISCOVERY HOOK
# =============================================================================

timss_discovery <- function() {
  z <- list.files(downloads,pattern="TIMSS.*\\.zip$|T[0-9]{2}.*\\.zip$",
                  recursive=TRUE,full.names=TRUE,ignore.case=TRUE)
  m <- data.frame(file=basename(z),path=z,stringsAsFactors=FALSE)
  write.csv(m,file.path(dirs$timss,"TIMSS_zip_discovery_manifest.csv"),
            row.names=FALSE)
  writeLines(c(
    "Future module: TIMSS Grade 4 mathematics/science.",
    "Do not place TIMSS and PISA/PIRLS raw score points on a common scale.",
    "Planned outputs: mean, minimum benchmark, distribution, social-background tails, ranks and fixed-panel terciles.",
    "Student books-at-home/home resources should be audited for a cross-instrument social-background sensitivity."
  ),file.path(dirs$timss,"TIMSS_FUTURE_MODULE_README.txt"))
  m
}


# =============================================================================
# 16. STANDARD FIGURES
# =============================================================================

dynamic_tercile_means <- function(df,metric,country="country",year="year") {
  assign <- list(); ai <- 1L
  means <- list(); mi <- 1L
  for(yr in sort(unique(df[[year]]))) {
    g <- df[df[[year]]==yr & is.finite(df[[metric]]),c(country,year,metric)]
    g <- g[order(g[[metric]],g[[country]]),]
    n <- nrow(g)
    p <- (seq_len(n)-.5)/n
    g$tercile <- ifelse(p<=1/3,"Onderste derde",
                        ifelse(p<=2/3,"Middelste derde","Bovenste derde"))
    assign[[ai]] <- g; ai <- ai+1L
    a <- aggregate(g[[metric]],by=list(year=g[[year]],tercile=g$tercile),mean)
    names(a)[3] <- metric
    a$n <- as.integer(table(g$tercile)[a$tercile])
    means[[mi]] <- a; mi <- mi+1L
  }
  list(assignments=do.call(rbind,assign),means=do.call(rbind,means))
}

plot_nl_vs_dynamic_terciles <- function(df,metric,title,subtitle,ylabel,
                                        source_note,stem) {
  tc <- dynamic_tercile_means(df,metric)
  nl <- df[df$country=="Netherlands",]
  p <- ggplot2::ggplot() +
    ggplot2::geom_line(data=tc$means,
      ggplot2::aes(x=year,y=.data[[metric]],group=tercile,colour=tercile),
      linewidth=.75) +
    ggplot2::geom_point(data=tc$means,
      ggplot2::aes(x=year,y=.data[[metric]],colour=tercile),size=2) +
    ggplot2::geom_line(data=nl,
      ggplot2::aes(x=year,y=.data[[metric]]),colour=COL$NL,linewidth=1.0) +
    ggplot2::geom_point(data=nl,
      ggplot2::aes(x=year,y=.data[[metric]]),colour=COL$NL,size=2.4) +
    ggplot2::scale_colour_manual(values=c(
      "Onderste derde"=COL$ses_line[1],
      "Middelste derde"=COL$ses_line[3],
      "Bovenste derde"=COL$ses_line[5])) +
    ggplot2::labs(title=title,subtitle=subtitle,y=ylabel,x=NULL,
      caption=paste0(
        source_note,
        "\nVaste onderliggende landenpopulatie; tercielen per wave opnieuw bepaald binnen diezelfde groep."
      )) +
    theme_kansen()
  stemfull <- file.path(dirs$figures,stem)
  export_vector(p,stemfull)
  write.csv(tc$assignments,paste0(stemfull,"_assignments.csv"),row.names=FALSE)
  write.csv(tc$means,paste0(stemfull,"_means.csv"),row.names=FALSE)
  invisible(p)
}

make_pisa_figures <- function(p) {
  if(!nrow(p$long)) return(invisible(NULL))

  # Long reading: NL vs dynamic terciles in fixed 32
  plot_nl_vs_dynamic_terciles(
    p$long,"mean_read",
    "Nederland verloor internationaal terrein in lezen",
    "PISA lezen · gemiddelde score · 15-jarigen · vaste 32 onderwijsstelsels",
    "Gemiddelde leesscore",
    "Bron: OECD PISA 2025, tabel I.B1.2a.37; eigen aggregatie van officiële schattingen.",
    "PISA_reading_mean_dynamic_terciles"
  )
  plot_nl_vs_dynamic_terciles(
    p$long,"prof",
    "Steeds minder Nederlandse 15-jarigen halen het basisniveau lezen",
    "PISA lezen · minimaal Level 2 · vaste 32 onderwijsstelsels",
    "Aandeel minimaal Level 2 (%)",
    "Bron: OECD PISA 2025, tabel I.B1.2a.34.",
    "PISA_reading_proficiency_dynamic_terciles"
  )
  plot_nl_vs_dynamic_terciles(
    p$long,"p90_p10",
    "De Nederlandse leesverdeling werd veel breder",
    "PISA lezen · P90-P10 · vaste 32 onderwijsstelsels",
    "P90 - P10 (scorepunten)",
    "Bron: OECD PISA 2025, tabel I.B1.2a.40.",
    "PISA_reading_P90P10_dynamic_terciles"
  )

  if(nrow(p$ses)) {
    plot_nl_vs_dynamic_terciles(
      p$ses,"q1_prof",
      "Lage-SES leerlingen in Nederland verloren internationaal terrein",
      "PISA lezen · onderste nationale ESCS-kwartiel · minimaal Level 2",
      "Aandeel minimaal Level 2 (%)",
      "Bron: OECD PISA 2025, tabel I.B1.2b.29.",
      "PISA_reading_Q1_proficiency_dynamic_terciles"
    )
    plot_nl_vs_dynamic_terciles(
      p$ses,"q4_prof",
      "Ook de hoge-SES groep daalde, maar minder sterk",
      "PISA lezen · hoogste nationale ESCS-kwartiel · minimaal Level 2",
      "Aandeel minimaal Level 2 (%)",
      "Bron: OECD PISA 2025, tabel I.B1.2b.29.",
      "PISA_reading_Q4_proficiency_dynamic_terciles"
    )
    plot_nl_vs_dynamic_terciles(
      p$ses,"gap",
      "De Nederlandse SES-kloof in basisvaardigheid werd groter",
      "PISA lezen · Q4 minus Q1 · nationale ESCS-kwartielen",
      "Kloof (procentpunt)",
      "Bron: OECD PISA 2025, tabel I.B1.2b.29.",
      "PISA_reading_SES_gap_dynamic_terciles"
    )
  }
}

make_pirls_figures <- function(main_wide) {
  # country names are codes in the PIRLS stage; NL remains NLD.
  if(!nrow(main_wide)) return(invisible(NULL))
  z <- main_wide
  names(z)[names(z)=="country_code3"] <- "country"
  z$country[z$country=="NLD"] <- "Netherlands"

  plot_nl_vs_dynamic_terciles(
    z,"mean_reading",
    "Nederlandse leesprestaties rond groep 6 door de tijd",
    "PIRLS lezen · Grade 4 / ongeveer 10 jaar · vaste MAIN-13",
    "Gemiddelde PIRLS-leesscore",
    "Bron: IEA PIRLS 2001–2021; eigen berekeningen met alle plausible values en JK2.",
    "PIRLS_reading_mean_dynamic_terciles"
  )
  plot_nl_vs_dynamic_terciles(
    z,"prof_ge475",
    "Aandeel dat de PIRLS Intermediate Benchmark haalt",
    "PIRLS lezen · ≥475 · vaste MAIN-13",
    "Aandeel ≥475",
    "Bron: IEA PIRLS 2001–2021; eigen berekeningen.",
    "PIRLS_reading_proficiency_dynamic_terciles"
  )
  plot_nl_vs_dynamic_terciles(
    z,"p90_p10_scoregap",
    "Algemene prestatiespreiding rond groep 6",
    "PIRLS lezen · P90-P10 · vaste MAIN-13",
    "P90 - P10 (PIRLS-punten)",
    "Bron: IEA PIRLS 2001–2021; eigen berekeningen.",
    "PIRLS_reading_P90P10_dynamic_terciles"
  )
}


# =============================================================================
# 16A. DASHBOARD EXPORT LAYER — COUNTRY CROSSWALK, ALL-COUNTRY DATA, METADATA
# =============================================================================

# This layer is deliberately separated from slide text. It exports data and
# structural codes; titles/conclusions are generated by the frontend.

dashboard_dir <- file.path(root, "11_dashboard_bundle")
dir.create(dashboard_dir, recursive=TRUE, showWarnings=FALSE)

DASH_COUNTRY_MATRIX <- rbind(
  c("iso3:ALB","Albanië","Albania","ALB","ALB","sovereign_country","Albania"),
  c("iso3:DZA","Algerije","Algeria","DZA","DZA","sovereign_country","Algeria"),
  c("iso3:ARG","Argentinië","Argentina","ARG","ARG","sovereign_country","Argentina"),
  c("iso3:AUS","Australië","Australia","AUS","AUS","sovereign_country","Australia"),
  c("iso3:AUT","Oostenrijk","Austria","AUT","AUT","sovereign_country","Austria"),
  c("iso3:AZE","Azerbeidzjan","Azerbaijan","AZE","AZE","sovereign_country","Azerbaijan"),
  c("edu:BAK","Baku (Azerbeidzjan)","Baku (Azerbaijan)","","BAK","subnational_system","Baku (Azerbaijan);Baku"),
  c("iso3:BLR","Belarus","Belarus","BLR","BLR","sovereign_country","Belarus"),
  c("iso3:BEL","België","Belgium","BEL","BEL","sovereign_country","Belgium"),
  c("iso3:BIH","Bosnië en Herzegovina","Bosnia and Herzegovina","BIH","BIH","sovereign_country","Bosnia and Herzegovina"),
  c("iso3:BRA","Brazilië","Brazil","BRA","BRA","sovereign_country","Brazil"),
  c("iso3:BRN","Brunei","Brunei Darussalam","BRN","BRN","sovereign_country","Brunei Darussalam;Brunei"),
  c("iso3:BGR","Bulgarije","Bulgaria","BGR","BGR","sovereign_country","Bulgaria"),
  c("iso3:KHM","Cambodja","Cambodia","KHM","KHM","sovereign_country","Cambodia"),
  c("iso3:CAN","Canada","Canada","CAN","CAN","sovereign_country","Canada"),
  c("iso3:CHL","Chili","Chile","CHL","CHL","sovereign_country","Chile"),
  c("iso3:COL","Colombia","Colombia","COL","COL","sovereign_country","Colombia"),
  c("iso3:CRI","Costa Rica","Costa Rica","CRI","CRI","sovereign_country","Costa Rica"),
  c("iso3:HRV","Kroatië","Croatia","HRV","HRV","sovereign_country","Croatia"),
  c("iso3:CYP","Cyprus","Cyprus","CYP","CYP","sovereign_country","Cyprus"),
  c("iso3:CZE","Tsjechië","Czechia","CZE","CZE","sovereign_country","Czechia;Czech Republic"),
  c("iso3:DNK","Denemarken","Denmark","DNK","DNK","sovereign_country","Denmark"),
  c("iso3:DOM","Dominicaanse Republiek","Dominican Republic","DOM","DOM","sovereign_country","Dominican Republic"),
  c("iso3:SLV","El Salvador","El Salvador","SLV","SLV","sovereign_country","El Salvador"),
  c("iso3:EST","Estland","Estonia","EST","EST","sovereign_country","Estonia"),
  c("iso3:FIN","Finland","Finland","FIN","FIN","sovereign_country","Finland"),
  c("iso3:FRA","Frankrijk","France","FRA","FRA","sovereign_country","France"),
  c("iso3:GEO","Georgië","Georgia","GEO","GEO","sovereign_country","Georgia"),
  c("iso3:DEU","Duitsland","Germany","DEU","DEU","sovereign_country","Germany"),
  c("iso3:GRC","Griekenland","Greece","GRC","GRC","sovereign_country","Greece"),
  c("iso3:GTM","Guatemala","Guatemala","GTM","GTM","sovereign_country","Guatemala"),
  c("iso3:HKG","Hongkong","Hong Kong (China)","HKG","HKG","economy","Hong Kong (China);Hong Kong-China;Hong Kong SAR;Hong Kong"),
  c("iso3:HUN","Hongarije","Hungary","HUN","HUN","sovereign_country","Hungary"),
  c("iso3:ISL","IJsland","Iceland","ISL","ISL","sovereign_country","Iceland"),
  c("iso3:IDN","Indonesië","Indonesia","IDN","IDN","sovereign_country","Indonesia"),
  c("iso3:IRN","Iran","Iran","IRN","IRN","sovereign_country","Iran;Iran, Islamic Rep."),
  c("iso3:IRL","Ierland","Ireland","IRL","IRL","sovereign_country","Ireland"),
  c("iso3:ISR","Israël","Israel","ISR","ISR","sovereign_country","Israel"),
  c("iso3:ITA","Italië","Italy","ITA","ITA","sovereign_country","Italy"),
  c("iso3:JAM","Jamaica","Jamaica","JAM","JAM","sovereign_country","Jamaica"),
  c("iso3:JPN","Japan","Japan","JPN","JPN","sovereign_country","Japan"),
  c("iso3:JOR","Jordanië","Jordan","JOR","JOR","sovereign_country","Jordan"),
  c("iso3:KAZ","Kazachstan","Kazakhstan","KAZ","KAZ","sovereign_country","Kazakhstan"),
  c("iso3:KEN","Kenia","Kenya","KEN","KEN","sovereign_country","Kenya"),
  c("iso3:KOR","Zuid-Korea","Korea","KOR","KOR","sovereign_country","Korea;Republic of Korea;Korea, Republic of"),
  c("edu:XKX","Kosovo","Kosovo","XKX","XKX","education_system","Kosovo"),
  c("iso3:LVA","Letland","Latvia","LVA","LVA","sovereign_country","Latvia"),
  c("iso3:LTU","Litouwen","Lithuania","LTU","LTU","sovereign_country","Lithuania"),
  c("iso3:LUX","Luxemburg","Luxembourg","LUX","LUX","sovereign_country","Luxembourg"),
  c("iso3:MAC","Macau","Macao (China)","MAC","MAC","economy","Macao (China);Macao-China;Macao;Macau"),
  c("iso3:MYS","Maleisië","Malaysia","MYS","MYS","sovereign_country","Malaysia"),
  c("iso3:MLT","Malta","Malta","MLT","MLT","sovereign_country","Malta"),
  c("iso3:MEX","Mexico","Mexico","MEX","MEX","sovereign_country","Mexico"),
  c("iso3:MDA","Moldavië","Moldova","MDA","MDA","sovereign_country","Moldova;Republic of Moldova"),
  c("iso3:MNG","Mongolië","Mongolia","MNG","MNG","sovereign_country","Mongolia"),
  c("iso3:MNE","Montenegro","Montenegro","MNE","MNE","sovereign_country","Montenegro"),
  c("iso3:MAR","Marokko","Morocco","MAR","MAR","sovereign_country","Morocco"),
  c("iso3:NLD","Nederland","Netherlands","NLD","NLD","sovereign_country","Netherlands;Netherlands*"),
  c("iso3:NZL","Nieuw-Zeeland","New Zealand","NZL","NZL","sovereign_country","New Zealand;New Zealand*"),
  c("iso3:MKD","Noord-Macedonië","North Macedonia","MKD","MKD","sovereign_country","North Macedonia;Macedonia"),
  c("iso3:NOR","Noorwegen","Norway","NOR","NOR","sovereign_country","Norway"),
  c("iso3:PAN","Panama","Panama","PAN","PAN","sovereign_country","Panama"),
  c("iso3:PRY","Paraguay","Paraguay","PRY","PRY","sovereign_country","Paraguay"),
  c("iso3:PER","Peru","Peru","PER","PER","sovereign_country","Peru"),
  c("iso3:PHL","Filipijnen","Philippines","PHL","PHL","sovereign_country","Philippines"),
  c("iso3:POL","Polen","Poland","POL","POL","sovereign_country","Poland"),
  c("iso3:PRT","Portugal","Portugal","PRT","PRT","sovereign_country","Portugal"),
  c("iso3:QAT","Qatar","Qatar","QAT","QAT","sovereign_country","Qatar"),
  c("iso3:ROU","Roemenië","Romania","ROU","ROU","sovereign_country","Romania"),
  c("iso3:RUS","Rusland","Russian Federation","RUS","RUS","sovereign_country","Russian Federation;Russia"),
  c("iso3:RWA","Rwanda","Rwanda","RWA","RWA","sovereign_country","Rwanda"),
  c("iso3:SAU","Saoedi-Arabië","Saudi Arabia","SAU","SAU","sovereign_country","Saudi Arabia"),
  c("iso3:SRB","Servië","Serbia","SRB","SRB","sovereign_country","Serbia"),
  c("iso3:SGP","Singapore","Singapore","SGP","SGP","sovereign_country","Singapore"),
  c("iso3:SVK","Slowakije","Slovak Republic","SVK","SVK","sovereign_country","Slovak Republic;Slovakia"),
  c("iso3:SVN","Slovenië","Slovenia","SVN","SVN","sovereign_country","Slovenia"),
  c("iso3:ESP","Spanje","Spain","ESP","ESP","sovereign_country","Spain"),
  c("iso3:SWE","Zweden","Sweden","SWE","SWE","sovereign_country","Sweden"),
  c("iso3:CHE","Zwitserland","Switzerland","CHE","CHE","sovereign_country","Switzerland"),
  c("iso3:TWN","Chinees Taipei","Chinese Taipei","TWN","TWN","economy","Chinese Taipei;Chinese-Taipei"),
  c("iso3:THA","Thailand","Thailand","THA","THA","sovereign_country","Thailand"),
  c("iso3:TUR","Turkije","Türkiye","TUR","TUR","sovereign_country","Türkiye;Turkey;Türkiye*"),
  c("iso3:UKR","Oekraïne","Ukraine","UKR","UKR","sovereign_country","Ukraine"),
  c("iso3:ARE","Verenigde Arabische Emiraten","United Arab Emirates","ARE","ARE","sovereign_country","United Arab Emirates"),
  c("iso3:GBR","Verenigd Koninkrijk","United Kingdom","GBR","GBR","sovereign_country","United Kingdom;United Kingdom*"),
  c("iso3:USA","Verenigde Staten","United States","USA","USA","sovereign_country","United States;United States*"),
  c("iso3:URY","Uruguay","Uruguay","URY","URY","sovereign_country","Uruguay"),
  c("iso3:UZB","Oezbekistan","Uzbekistan","UZB","UZB","sovereign_country","Uzbekistan"),
  c("iso3:VNM","Vietnam","Viet Nam","VNM","VNM","sovereign_country","Viet Nam;Vietnam"),
  c("iso3:ZMB","Zambia","Zambia","ZMB","ZMB","sovereign_country","Zambia"),
  c("edu:ENG","Engeland","England","","ENG","subnational_system","England"),
  c("edu:NIR","Noord-Ierland","Northern Ireland","","NIR","subnational_system","Northern Ireland"),
  c("edu:CQU","Québec","Quebec","","CQU","subnational_system","Quebec;Québec"),
  c("edu:ONT","Ontario","Ontario","","ONT","subnational_system","Ontario"),
  c("edu:PAL","Palestijnse Autoriteit","Palestinian Authority","","PAL","education_system","Palestinian Authority;Palestine"),
  c("edu:BSJZ","B-S-J-Z (China)","B-S-J-Z (China)","","BSJ","education_system","B-S-J-Z (China);B-S-J-G (China)"),
  c("iso3:ARM","Armenië","Armenia","ARM","ARM","sovereign_country","Armenia"),
  c("iso3:BHR","Bahrein","Bahrain","BHR","BHR","sovereign_country","Bahrain"),
  c("iso3:BWA","Botswana","Botswana","BWA","BWA","sovereign_country","Botswana"),
  c("iso3:EGY","Egypte","Egypt","EGY","EGY","sovereign_country","Egypt"),
  c("iso3:KWT","Koeweit","Kuwait","KWT","KWT","sovereign_country","Kuwait"),
  c("iso3:LBN","Libanon","Lebanon","LBN","LBN","sovereign_country","Lebanon"),
  c("iso3:OMN","Oman","Oman","OMN","OMN","sovereign_country","Oman"),
  c("iso3:ZAF","Zuid-Afrika","South Africa","ZAF","ZAF","sovereign_country","South Africa"),
  c("iso3:TTO","Trinidad en Tobago","Trinidad and Tobago","TTO","TTO","sovereign_country","Trinidad and Tobago"),
  c("iso3:TUN","Tunesië","Tunisia","TUN","TUN","sovereign_country","Tunisia"),
  c("iso3:KSV","Kosovo","Kosovo","","KSV","education_system","Kosovo")
)
colnames(DASH_COUNTRY_MATRIX) <- c(
  "country_id","country_name_nl","country_name_en","iso3",
  "source_country_code","geography_type","aliases"
)
DASH_COUNTRIES <- as.data.frame(DASH_COUNTRY_MATRIX, stringsAsFactors=FALSE)
DASH_COUNTRIES <- rbind(DASH_COUNTRIES, data.frame(
  country_id=c("edu:BFL","edu:BFR","edu:DUB","edu:ABU","edu:UKR18"),
  country_name_nl=c("Vlaamse Gemeenschap (België)","Franse Gemeenschap (België)","Dubai","Abu Dhabi","Oekraïense regio's (18 van 27)"),
  country_name_en=c("Flemish Community of Belgium","French Community of Belgium","Dubai","Abu Dhabi","Ukrainian regions (18 of 27)"),
  iso3=c("BEL","BEL","ARE","ARE",""),
  source_country_code=c("BFL","BFR","DUB","ABU","UKR18"),
  geography_type=c("subnational_system","subnational_system","subnational_system","subnational_system","partial_country_sample"),
  aliases=c("Flemish Community of Belgium;Belgium (Flemish);Flemish Belgium","French Community of Belgium;Belgium (French);French Belgium","Dubai (UAE);Dubai","Abu Dhabi (UAE);Abu Dhabi","Ukrainian regions (18 of 27);Ukraine (18 of 27 regions)"),
  stringsAsFactors=FALSE
))

# PISA 2025 participants observed in the official OECD workbooks but absent
# from the legacy controlled crosswalk. Sovereign countries receive ISO3 ids;
# subnational/partial systems remain distinct and are never collapsed into the
# corresponding sovereign country.
DASH_COUNTRIES <- rbind(DASH_COUNTRIES, data.frame(
  country_id=c(
    "iso3:ECU","iso3:KGZ","iso3:MUS",
    "system:DUSHANBE_TJK","system:KRI_IRQ","system:UKR17"
  ),
  country_name_nl=c(
    "Ecuador","Kirgizië","Mauritius",
    "Doesjanbe (Tadzjikistan)","Koerdische Regio (Irak)",
    "Oekraïense regio's (17 van 27)"
  ),
  country_name_en=c(
    "Ecuador","Kyrgyzstan","Mauritius",
    "Dushanbe (Tajikistan)","Kurdistan Region (Iraq)",
    "Ukrainian regions (17 of 27)"
  ),
  iso3=c("ECU","KGZ","MUS","","",""),
  source_country_code=c("ECU","KGZ","MUS","","",""),
  geography_type=c(
    "sovereign_country","sovereign_country","sovereign_country",
    "subnational_system","subnational_system","partial_country_sample"
  ),
  aliases=c(
    "Ecuador",
    "Kyrgyzstan;Kyrgyz Republic",
    "Mauritius",
    "Dushanbe (Tajikistan);Dushanbe",
    "Kurdistan Region (Iraq);Kurdistan Region",
    "Ukrainian regions (17 of 27);Ukraine (17 of 27 regions)"
  ),
  stringsAsFactors=FALSE
))


# ---------------------------------------------------------------------------
# Controlled ISO3 fallback registry
# ---------------------------------------------------------------------------
# This registry is used only when a three-letter source code is a valid ISO3
# code and is not already handled by the explicit education-system crosswalk.
# Explicit rows above therefore take precedence (e.g. HKG/MAC/ENG handling).
ISO3_FALLBACK <- data.frame(
  iso3=c("ABW","AFG","AGO","AIA","ALA","ALB","AND","ARE","ARG","ARM","ASM","ATA","ATF","ATG","AUS","AUT","AZE","BDI","BEL","BEN","BES","BFA","BGD","BGR","BHR","BHS","BIH","BLM","BLR","BLZ","BMU","BOL","BRA","BRB","BRN","BTN","BVT","BWA","CAF","CAN","CCK","CHE","CHL","CHN","CIV","CMR","COD","COG","COK","COL","COM","CPV","CRI","CUB","CUW","CXR","CYM","CYP","CZE","DEU","DJI","DMA","DNK","DOM","DZA","ECU","EGY","ERI","ESH","ESP","EST","ETH","FIN","FJI","FLK","FRA","FRO","FSM","GAB","GBR","GEO","GGY","GHA","GIB","GIN","GLP","GMB","GNB","GNQ","GRC","GRD","GRL","GTM","GUF","GUM","GUY","HKG","HMD","HND","HRV","HTI","HUN","IDN","IMN","IND","IOT","IRL","IRN","IRQ","ISL","ISR","ITA","JAM","JEY","JOR","JPN","KAZ","KEN","KGZ","KHM","KIR","KNA","KOR","KWT","LAO","LBN","LBR","LBY","LCA","LIE","LKA","LSO","LTU","LUX","LVA","MAC","MAF","MAR","MCO","MDA","MDG","MDV","MEX","MHL","MKD","MLI","MLT","MMR","MNE","MNG","MNP","MOZ","MRT","MSR","MTQ","MUS","MWI","MYS","MYT","NAM","NCL","NER","NFK","NGA","NIC","NIU","NLD","NOR","NPL","NRU","NZL","OMN","PAK","PAN","PCN","PER","PHL","PLW","PNG","POL","PRI","PRK","PRT","PRY","PSE","PYF","QAT","REU","ROU","RUS","RWA","SAU","SDN","SEN","SGP","SGS","SHN","SJM","SLB","SLE","SLV","SMR","SOM","SPM","SRB","SSD","STP","SUR","SVK","SVN","SWE","SWZ","SXM","SYC","SYR","TCA","TCD","TGO","THA","TJK","TKL","TKM","TLS","TON","TTO","TUN","TUR","TUV","TWN","TZA","UGA","UKR","UMI","URY","USA","UZB","VAT","VCT","VEN","VGB","VIR","VNM","VUT","WLF","WSM","YEM","ZAF","ZMB","ZWE"),
  country_name_nl=c("Aruba","Afghanistan","Angola","Anguilla","Åland","Albanië","Andorra","Verenigde Arabische Emiraten","Argentinië","Armenië","Amerikaans-Samoa","Antarctica","Franse Gebieden in de zuidelijke Indische Oceaan","Antigua en Barbuda","Australië","Oostenrijk","Azerbeidzjan","Burundi","België","Benin","Caribisch Nederland","Burkina Faso","Bangladesh","Bulgarije","Bahrein","Bahama’s","Bosnië en Herzegovina","Saint-Barthélemy","Belarus","Belize","Bermuda","Bolivia","Brazilië","Barbados","Brunei","Bhutan","Bouveteiland","Botswana","Centraal-Afrikaanse Republiek","Canada","Cocoseilanden","Zwitserland","Chili","China","Ivoorkust","Kameroen","Congo-Kinshasa","Congo-Brazzaville","Cookeilanden","Colombia","Comoren","Kaapverdië","Costa Rica","Cuba","Curaçao","Christmaseiland","Kaaimaneilanden","Cyprus","Tsjechië","Duitsland","Djibouti","Dominica","Denemarken","Dominicaanse Republiek","Algerije","Ecuador","Egypte","Eritrea","Westelijke Sahara","Spanje","Estland","Ethiopië","Finland","Fiji","Falklandeilanden","Frankrijk","Faeröer","Micronesia","Gabon","Verenigd Koninkrijk","Georgië","Guernsey","Ghana","Gibraltar","Guinee","Guadeloupe","Gambia","Guinee-Bissau","Equatoriaal-Guinea","Griekenland","Grenada","Groenland","Guatemala","Frans-Guyana","Guam","Guyana","Hongkong SAR van China","Heard en McDonaldeilanden","Honduras","Kroatië","Haïti","Hongarije","Indonesië","Isle of Man","India","Brits Indische Oceaanterritorium","Ierland","Iran","Irak","IJsland","Israël","Italië","Jamaica","Jersey","Jordanië","Japan","Kazachstan","Kenia","Kirgizië","Cambodja","Kiribati","Saint Kitts en Nevis","Zuid-Korea","Koeweit","Laos","Libanon","Liberia","Libië","Saint Lucia","Liechtenstein","Sri Lanka","Lesotho","Litouwen","Luxemburg","Letland","Macau SAR van China","Saint-Martin","Marokko","Monaco","Moldavië","Madagaskar","Maldiven","Mexico","Marshalleilanden","Noord-Macedonië","Mali","Malta","Myanmar (Birma)","Montenegro","Mongolië","Noordelijke Marianen","Mozambique","Mauritanië","Montserrat","Martinique","Mauritius","Malawi","Maleisië","Mayotte","Namibië","Nieuw-Caledonië","Niger","Norfolk","Nigeria","Nicaragua","Niue","Nederland","Noorwegen","Nepal","Nauru","Nieuw-Zeeland","Oman","Pakistan","Panama","Pitcairneilanden","Peru","Filipijnen","Palau","Papoea-Nieuw-Guinea","Polen","Puerto Rico","Noord-Korea","Portugal","Paraguay","Palestijnse gebieden","Frans-Polynesië","Qatar","Réunion","Roemenië","Rusland","Rwanda","Saoedi-Arabië","Soedan","Senegal","Singapore","Zuid-Georgia en Zuidelijke Sandwicheilanden","Sint-Helena","Spitsbergen en Jan Mayen","Salomonseilanden","Sierra Leone","El Salvador","San Marino","Somalië","Saint-Pierre en Miquelon","Servië","Zuid-Soedan","Sao Tomé en Principe","Suriname","Slowakije","Slovenië","Zweden","Eswatini","Sint-Maarten","Seychellen","Syrië","Turks- en Caicoseilanden","Tsjaad","Togo","Thailand","Tadzjikistan","Tokelau","Turkmenistan","Oost-Timor","Tonga","Trinidad en Tobago","Tunesië","Turkije","Tuvalu","Taiwan","Tanzania","Oeganda","Oekraïne","Kleine afgelegen eilanden van de Verenigde Staten","Uruguay","Verenigde Staten","Oezbekistan","Vaticaanstad","Saint Vincent en de Grenadines","Venezuela","Britse Maagdeneilanden","Amerikaanse Maagdeneilanden","Vietnam","Vanuatu","Wallis en Futuna","Samoa","Jemen","Zuid-Afrika","Zambia","Zimbabwe"),
  country_name_en=c("Aruba","Afghanistan","Angola","Anguilla","Åland Islands","Albania","Andorra","United Arab Emirates","Argentina","Armenia","American Samoa","Antarctica","French Southern Territories","Antigua & Barbuda","Australia","Austria","Azerbaijan","Burundi","Belgium","Benin","Caribbean Netherlands","Burkina Faso","Bangladesh","Bulgaria","Bahrain","Bahamas","Bosnia & Herzegovina","St. Barthélemy","Belarus","Belize","Bermuda","Bolivia","Brazil","Barbados","Brunei","Bhutan","Bouvet Island","Botswana","Central African Republic","Canada","Cocos (Keeling) Islands","Switzerland","Chile","China","Côte d’Ivoire","Cameroon","Congo - Kinshasa","Congo - Brazzaville","Cook Islands","Colombia","Comoros","Cape Verde","Costa Rica","Cuba","Curaçao","Christmas Island","Cayman Islands","Cyprus","Czechia","Germany","Djibouti","Dominica","Denmark","Dominican Republic","Algeria","Ecuador","Egypt","Eritrea","Western Sahara","Spain","Estonia","Ethiopia","Finland","Fiji","Falkland Islands","France","Faroe Islands","Micronesia","Gabon","United Kingdom","Georgia","Guernsey","Ghana","Gibraltar","Guinea","Guadeloupe","Gambia","Guinea-Bissau","Equatorial Guinea","Greece","Grenada","Greenland","Guatemala","French Guiana","Guam","Guyana","Hong Kong SAR China","Heard & McDonald Islands","Honduras","Croatia","Haiti","Hungary","Indonesia","Isle of Man","India","British Indian Ocean Territory","Ireland","Iran","Iraq","Iceland","Israel","Italy","Jamaica","Jersey","Jordan","Japan","Kazakhstan","Kenya","Kyrgyzstan","Cambodia","Kiribati","St. Kitts & Nevis","South Korea","Kuwait","Laos","Lebanon","Liberia","Libya","St. Lucia","Liechtenstein","Sri Lanka","Lesotho","Lithuania","Luxembourg","Latvia","Macao SAR China","St. Martin","Morocco","Monaco","Moldova","Madagascar","Maldives","Mexico","Marshall Islands","North Macedonia","Mali","Malta","Myanmar (Burma)","Montenegro","Mongolia","Northern Mariana Islands","Mozambique","Mauritania","Montserrat","Martinique","Mauritius","Malawi","Malaysia","Mayotte","Namibia","New Caledonia","Niger","Norfolk Island","Nigeria","Nicaragua","Niue","Netherlands","Norway","Nepal","Nauru","New Zealand","Oman","Pakistan","Panama","Pitcairn Islands","Peru","Philippines","Palau","Papua New Guinea","Poland","Puerto Rico","North Korea","Portugal","Paraguay","Palestinian Territories","French Polynesia","Qatar","Réunion","Romania","Russia","Rwanda","Saudi Arabia","Sudan","Senegal","Singapore","South Georgia & South Sandwich Islands","St. Helena","Svalbard & Jan Mayen","Solomon Islands","Sierra Leone","El Salvador","San Marino","Somalia","St. Pierre & Miquelon","Serbia","South Sudan","São Tomé & Príncipe","Suriname","Slovakia","Slovenia","Sweden","Eswatini","Sint Maarten","Seychelles","Syria","Turks & Caicos Islands","Chad","Togo","Thailand","Tajikistan","Tokelau","Turkmenistan","Timor-Leste","Tonga","Trinidad & Tobago","Tunisia","Türkiye","Tuvalu","Taiwan","Tanzania","Uganda","Ukraine","U.S. Outlying Islands","Uruguay","United States","Uzbekistan","Vatican City","St. Vincent & Grenadines","Venezuela","British Virgin Islands","U.S. Virgin Islands","Vietnam","Vanuatu","Wallis & Futuna","Samoa","Yemen","South Africa","Zambia","Zimbabwe"),
  stringsAsFactors=FALSE
)

augment_dash_countries_from_iso <- function() {
  existing_codes <- toupper(trimws(as.character(DASH_COUNTRIES$source_country_code)))
  add <- ISO3_FALLBACK[!ISO3_FALLBACK$iso3 %in% existing_codes,,drop=FALSE]
  if(!nrow(add)) return(invisible(NULL))

  DASH_COUNTRIES <<- rbind(
    DASH_COUNTRIES,
    data.frame(
      country_id=paste0("iso3:",add$iso3),
      country_name_nl=add$country_name_nl,
      country_name_en=add$country_name_en,
      iso3=add$iso3,
      source_country_code=add$iso3,
      geography_type="sovereign_or_iso_country_entity",
      aliases=paste(add$country_name_en,add$country_name_nl,sep=";"),
      stringsAsFactors=FALSE
    )
  )
  invisible(NULL)
}
augment_dash_countries_from_iso()


# ---------------------------------------------------------------------------
# PIRLS-specific non-ISO / benchmarking source-code registry
# ---------------------------------------------------------------------------
PIRLS_SPECIAL_SOURCE_MAP <- data.frame(
  source_country_code=c("AAD","ABA","ADU","CAB","CBC","CNL","CNS","COT","CQU","EAN","EMA","RMO","SCO","ROM","XKX","DN3","IS5","MA6","MLN","NO4","NO5","SE3","ZA5","ZA6"),
  country_id=c("system:ABU","system:ARG_BUENOS_AIRES","system:DUB","system:CAN_ALBERTA","system:CAN_BRITISH_COLUMBIA","system:CAN_NEWFOUNDLAND_LABRADOR","system:CAN_NOVA_SCOTIA","system:ONT","system:CQU","system:ESP_ANDALUSIA","system:ESP_MADRID","system:RUS_MOSCOW","system:GBR_SCOTLAND","iso3:ROU","system:XKX","system:DNK_G3","system:ISL_G5","system:MAR_G6","system:MLT_MALTESE","system:NOR_G4","system:NOR_G5","system:SWE_G3","system:ZAF_G5_LANG","system:ZAF_G6"),
  country_name_nl=c("Abu Dhabi","Buenos Aires","Dubai","Alberta","Brits-Columbia","Newfoundland en Labrador","Nova Scotia","Ontario","Québec","Andalusië","Madrid","Moskou","Schotland","Roemenië","Kosovo","Denemarken (leerjaar 3)","IJsland (leerjaar 5)","Marokko (leerjaar 6)","Malta – Maltese steekproef","Noorwegen (leerjaar 4)","Noorwegen (leerjaar 5)","Zweden (leerjaar 3)","Zuid-Afrika (leerjaar 5; Engels/Afrikaans/Zoeloe)","Zuid-Afrika (leerjaar 6)"),
  country_name_en=c("Abu Dhabi, UAE","Buenos Aires, Argentina","Dubai, UAE","Alberta, Canada","British Columbia, Canada","Newfoundland & Labrador, Canada","Nova Scotia, Canada","Ontario, Canada","Quebec, Canada","Andalusia, Spain","Madrid, Spain","Moscow City, Russian Federation","Scotland","Romania","Kosovo","Denmark (Grade 3)","Iceland (Grade 5)","Morocco (Grade 6)","Maltese - Malta","Norway (Grade 4)","Norway (Grade 5)","Sweden (Grade 3)","Eng Afr Zulu RSA (Grade 5)","South Africa (Grade 6)"),
  geography_type=c("subnational_system","subnational_system","subnational_system","subnational_system","subnational_system","subnational_system","subnational_system","subnational_system","subnational_system","subnational_system","subnational_system","subnational_system","subnational_system","sovereign_country","education_system","supplementary_grade_sample","supplementary_grade_sample","supplementary_grade_sample","language_subsample","supplementary_grade_sample","supplementary_grade_sample","supplementary_grade_sample","supplementary_grade_sample","supplementary_grade_sample"),
  dashboard_target_status=c("include","include","include","include","include","include","include","include","include","include","include","include","include","include","include","exclude","exclude","exclude","exclude","exclude","exclude","exclude","exclude","exclude"),
  mapping_note_en=c("PIRLS benchmarking entity; same stable system as PISA source code ABU.","PIRLS benchmarking entity.","PIRLS benchmarking entity; same stable system as PISA source code DUB.","PIRLS benchmarking entity.","PIRLS benchmarking entity.","PIRLS benchmarking entity.","PIRLS benchmarking entity.","PIRLS source alias for the same stable Ontario system.","PIRLS source alias for the same stable Quebec system.","PIRLS benchmarking entity.","PIRLS benchmarking entity.","PIRLS benchmarking entity.","PIRLS education system.","Legacy PIRLS alpha code; stable country identity is ISO3 ROU.","PIRLS source code alias for the existing Kosovo education-system stable ID system:XKX.","Supplementary grade variant; ordinary DNK remains the dashboard country series.","Supplementary grade variant; ordinary ISL remains separate.","Supplementary grade variant.","Language-specific supplementary sample; ordinary MLT is the country series.","Supplementary grade-specific variant; validated long-run country series uses NOR.","Supplementary grade-specific variant; validated long-run country series uses NOR.","Supplementary grade variant; ordinary SWE is the country series.","Supplementary Grade-5 sample.","Supplementary Grade-6 sample."),
  stringsAsFactors=FALSE
)

augment_dash_countries_from_pirls_registry <- function() {
  add <- PIRLS_SPECIAL_SOURCE_MAP
  DASH_COUNTRIES <<- rbind(
    DASH_COUNTRIES,
    data.frame(
      country_id=add$country_id,
      country_name_nl=add$country_name_nl,
      country_name_en=add$country_name_en,
      iso3=ifelse(grepl("^iso3:",add$country_id),sub("^iso3:","",add$country_id),""),
      source_country_code=add$source_country_code,
      geography_type=add$geography_type,
      aliases=paste(add$country_name_en,add$country_name_nl,sep=";"),
      stringsAsFactors=FALSE
    )
  )
  invisible(NULL)
}
augment_dash_countries_from_pirls_registry()

# v1.3.4 regression lock: XKX/Kosovo must have exactly one stable dashboard ID.
# The legacy base crosswalk contains edu:XKX; v2 normalization turns that into
# system:XKX. The PIRLS special registry must resolve to the same stable ID.
xkx_ids_regression <- as.character(
  DASH_COUNTRIES$country_id[
    toupper(trimws(as.character(DASH_COUNTRIES$source_country_code)))=="XKX"
  ]
)
# Keep this early regression independent of the later schema-v2 helper.
xkx_ids_regression <- sub("^edu:","system:",xkx_ids_regression)
xkx_ids_regression[xkx_ids_regression=="iso3:HKG"] <- "system:HKG"
xkx_ids_regression[xkx_ids_regression=="iso3:MAC"] <- "system:MAC"
xkx_ids_regression <- sort(unique(
  xkx_ids_regression[!is.na(xkx_ids_regression)&nzchar(xkx_ids_regression)]
))
if(!identical(xkx_ids_regression,"system:XKX"))
  stop("XKX stable-ID regression failure: expected exactly system:XKX, got ",
       paste(xkx_ids_regression,collapse=", "))


# PIRLS 2011 explicitly treated these ordinary-looking codes as sixth-grade
# countries; exclude them from the grade4_approx10 dashboard output.
PIRLS_YEAR_SOURCE_EXCLUSIONS <- data.frame(
  year=c(2011L,2011L,2011L),
  source_country_code=c("BWA","HND","KWT"),
  exclusion_reason=c(
    "PIRLS 2011 sixth-grade country",
    "PIRLS 2011 sixth-grade country",
    "PIRLS 2011 sixth-grade country"
  ),
  stringsAsFactors=FALSE
)



normalize_country_source_label <- function(x) {
  z <- trimws(as.character(x))
  z <- gsub("\\u00a0", " ", z, fixed=TRUE)
  z <- gsub("[[:space:]]+", " ", z)
  z <- gsub("\\*+$", "", z)
  z <- gsub("^[[:space:]]*OECD[[:space:]]+", "", z, ignore.case=TRUE)
  z <- trimws(z)
  z
}

build_country_alias_long <- function(cw=DASH_COUNTRIES) {
  out <- list(); oi <- 1L
  for(i in seq_len(nrow(cw))) {
    aa <- unique(c(cw$country_name_en[i],cw$country_name_nl[i],
                   cw$source_country_code[i],strsplit(cw$aliases[i],";",fixed=TRUE)[[1]]))
    aa <- aa[nzchar(aa)]
    for(a in aa) {
      out[[oi]] <- data.frame(
        alias_norm=toupper(normalize_country_source_label(a)),
        country_id=cw$country_id[i], stringsAsFactors=FALSE
      ); oi <- oi+1L
    }
  }
  unique(do.call(rbind,out))
}
DASH_COUNTRY_ALIASES <- build_country_alias_long()

country_id_from_label <- function(x) {
  key <- toupper(normalize_country_source_label(x))
  m <- match(key,DASH_COUNTRY_ALIASES$alias_norm)
  DASH_COUNTRY_ALIASES$country_id[m]
}

country_id_from_code <- function(x) {
  key <- toupper(trimws(as.character(x)))
  m <- match(key,toupper(DASH_COUNTRIES$source_country_code))
  DASH_COUNTRIES$country_id[m]
}

country_row <- function(country_id) {
  DASH_COUNTRIES[DASH_COUNTRIES$country_id %in% country_id,,drop=FALSE]
}

is_aggregate_label <- function(x) {
  z <- toupper(normalize_country_source_label(x))
  grepl("OECD|AVERAGE|TOTAL|DIFFERENCE|PARTNER|ALL COUNTRIES|EU |EUROPEAN UNION|SIGNIFICANT",z)
}

# Override the v1.0 OECD extractor: country recognition now uses a controlled
# crosswalk and explicitly reports any country-like row that is unmapped.
extract_oecd_table_long <- function(xlsx,table_id,country_reference=NULL) {
  sheet <- find_sheet_for_table(xlsx,table_id)
  if(is.na(sheet)) stop("OECD sheet not found: ",table_id," in ",basename(xlsx))
  raw <- readxl::read_excel(xlsx,sheet=sheet,col_names=FALSE,.name_repair="minimal")
  raw <- as.data.frame(raw,stringsAsFactors=FALSE)

  map_counts <- vapply(raw,function(col) {
    ids <- country_id_from_label(col)
    sum(!is.na(ids))
  },numeric(1))
  ccol <- which.max(map_counts)
  if(!length(ccol) || map_counts[ccol]<3)
    stop("Controlled crosswalk could not identify country column in ",table_id)

  src_labels <- normalize_country_source_label(raw[[ccol]])
  ids <- country_id_from_label(src_labels)
  mapped_rows <- which(!is.na(ids))
  if(!length(mapped_rows)) stop("No controlled country rows detected in ",table_id)

  # Find likely unmapped country/system labels inside the contiguous data block.
  lo <- min(mapped_rows); hi <- max(mapped_rows)
  nr_numeric <- vapply(seq_len(nrow(raw)),function(i) {
    sum(is.finite(vapply(raw[i,,drop=FALSE],function(v) numify(v)[1],numeric(1))),na.rm=TRUE)
  },numeric(1))
  cand <- seq.int(lo,hi)
  unmapped <- cand[is.na(ids[cand]) & nzchar(src_labels[cand]) &
                     !is_aggregate_label(src_labels[cand]) & nr_numeric[cand]>=2]
  if(length(unmapped)) {
    u <- unique(data.frame(table_id=table_id,sheet=sheet,
      source_country_label=src_labels[unmapped],stringsAsFactors=FALSE))
    p <- file.path(dirs$pisa_extract,"unmapped_country_labels.csv")
    if(file.exists(p)) u <- unique(rbind(read.csv(p,stringsAsFactors=FALSE),u))
    write.csv(u,p,row.names=FALSE,fileEncoding="UTF-8")
    if(STRICT_COUNTRY_CROSSWALK)
      stop("Unmapped country/system labels found in ",table_id,
           ". Extend the controlled crosswalk; see ",p)
  }

  first_data <- min(mapped_rows)
  hdr_rows <- seq_len(first_data-1)
  hh <- oecd_compose_headers(raw,hdr_rows)
  headers_raw <- hh$raw
  headers <- hh$reconstructed

  res <- list(); ri <- 1L
  for(j in seq_along(raw)) {
    if(j==ccol) next
    vals <- numify(raw[mapped_rows,j])
    if(all(is.na(vals))) next
    res[[ri]] <- data.frame(
      table_id=table_id,sheet=sheet,country_id=ids[mapped_rows],
      country=DASH_COUNTRIES$country_name_en[match(ids[mapped_rows],DASH_COUNTRIES$country_id)],source_country_label=src_labels[mapped_rows],
      column_index=j,header_raw=headers_raw[j],header=headers[j],value=vals,stringsAsFactors=FALSE
    ); ri <- ri+1L
  }
  if(!length(res)) stop("No numeric country cells extracted from ",table_id)
  do.call(rbind,res)
}

# Expanded OECD registry. Table labels are taken from the PISA 2025 Annex B1
# table inventory. Modules that cannot be safely standardised remain
# not_validated rather than being guessed.
extract_oecd_targets <- function(paths) {
  registry <- list(
    # Performance and proficiency
    "I.B1.2a.27"="pisa2025_performance",
    "I.B1.2a.28"="pisa2025_performance",
    "I.B1.2a.33"="pisa2025_performance",
    "I.B1.2a.34"="pisa2025_performance",
    "I.B1.2a.35"="pisa2025_performance",
    "I.B1.2a.36"="pisa2025_performance",
    "I.B1.2a.37"="pisa2025_performance",
    "I.B1.2a.38"="pisa2025_performance",
    "I.B1.2a.39"="pisa2025_performance",
    "I.B1.2a.40"="pisa2025_performance",
    "I.B1.2a.41"="pisa2025_performance",
    "I.B1.2a.42"="pisa2025_performance",
    "I.B1.2a.43"="pisa2025_performance",
    "I.B1.2a.44"="pisa2025_performance",

    # Socio-economic status, absolute SES and school sorting
    "I.B1.2b.1"="pisa2025_ses",
    "I.B1.2b.2"="pisa2025_ses",
    "I.B1.2b.3"="pisa2025_ses",
    "I.B1.2b.4"="pisa2025_ses",
    "I.B1.2b.6"="pisa2025_ses",
    "I.B1.2b.7"="pisa2025_ses",
    "I.B1.2b.8"="pisa2025_ses",
    "I.B1.2b.9"="pisa2025_ses",
    "I.B1.2b.10"="pisa2025_ses",
    "I.B1.2b.11"="pisa2025_ses",
    "I.B1.2b.12"="pisa2025_ses",
    "I.B1.2b.13"="pisa2025_ses",
    "I.B1.2b.14"="pisa2025_ses",
    "I.B1.2b.15"="pisa2025_ses",
    "I.B1.2b.16"="pisa2025_ses",
    "I.B1.2b.17"="pisa2025_ses",
    "I.B1.2b.18"="pisa2025_ses",
    "I.B1.2b.19"="pisa2025_ses",
    "I.B1.2b.20"="pisa2025_ses",
    "I.B1.2b.21"="pisa2025_ses",
    "I.B1.2b.22"="pisa2025_ses",
    "I.B1.2b.23"="pisa2025_ses",
    "I.B1.2b.24"="pisa2025_ses",
    "I.B1.2b.25"="pisa2025_ses",
    "I.B1.2b.26"="pisa2025_ses",
    "I.B1.2b.27"="pisa2025_ses",
    "I.B1.2b.28"="pisa2025_ses",
    "I.B1.2b.29"="pisa2025_ses",
    "I.B1.2b.30"="pisa2025_ses",
    "I.B1.2b.31"="pisa2025_ses",
    "I.B1.2b.32"="pisa2025_ses",
    "I.B1.2b.33"="pisa2025_ses",
    "I.B1.2b.34"="pisa2025_ses",
    "I.B1.2b.35"="pisa2025_ses",
    "I.B1.2b.36"="pisa2025_ses",
    "I.B1.2b.37"="pisa2025_ses",
    "I.B1.2b.38"="pisa2025_ses",

    # Gender, including gender x SES and long trends
    "I.B1.2c.2"="pisa2025_gender",
    "I.B1.2c.15"="pisa2025_gender",
    "I.B1.2c.18"="pisa2025_gender",
    "I.B1.2c.21"="pisa2025_gender",
    "I.B1.2c.26"="pisa2025_gender",
    "I.B1.2c.27"="pisa2025_gender",
    "I.B1.2c.28"="pisa2025_gender",
    "I.B1.2c.34"="pisa2025_gender",
    "I.B1.2c.35"="pisa2025_gender",

    # Immigration and language at home
    "I.B1.2d.1"="pisa2025_immigrant",
    "I.B1.2d.2"="pisa2025_immigrant",
    "I.B1.2d.3"="pisa2025_immigrant",
    "I.B1.2d.4"="pisa2025_immigrant",
    "I.B1.2d.5"="pisa2025_immigrant",
    "I.B1.2d.6"="pisa2025_immigrant",
    "I.B1.2d.8"="pisa2025_immigrant",
    "I.B1.2d.11"="pisa2025_immigrant",
    "I.B1.2d.14"="pisa2025_immigrant",

    # Sample/population quality where the release contains a table
    "I.A2.1"="pisa2025_samples",

    # 2022 overlap/revisions and quality
    "I.B1.5.20"="pisa2022_trends",
    "I.B1.5.23"="pisa2022_trends",
    "I.B1.5.26"="pisa2022_trends",
    "I.B1.5.28"="pisa2022_trends",
    "I.B1.4.12"="pisa2022_equity",
    "I.B1.4.35"="pisa2022_equity",
    "I.B1.4.38"="pisa2022_equity",
    "I.B1.4.40"="pisa2022_equity",
    "I.A2.1__2022"="pisa2022_samples",
    "I.A2.6__2022"="pisa2022_samples",
    "I.A2.1__2018"="pisa2018_samples",
    "I.A2.6__2018"="pisa2018_samples"
  )

  cache_file <- file.path(dirs$pisa_extract,"OECD_official_target_cells.rds")
  cache_meta <- file.path(dirs$pisa_extract,"OECD_official_target_cells_cache_meta.rds")
  current_signature <- oecd_workbook_signature(paths)

  if(isTRUE(REUSE_OECD_EXTRACT_CACHE) &&
     file.exists(cache_file) && file.exists(cache_meta)) {
    meta <- try(readRDS(cache_meta),silent=TRUE)
    cached <- try(readRDS(cache_file),silent=TRUE)
    if(!inherits(meta,"try-error") && !inherits(cached,"try-error") &&
       identical(meta$cache_version,OECD_EXTRACT_CACHE_VERSION) &&
       same_oecd_signature(meta$workbooks,current_signature) &&
       is.list(cached) && all(c("cells","failures","registry") %in% names(cached)) &&
       is.data.frame(cached$cells) && nrow(cached$cells)) {
      log_msg("OECD extraction cache hit — ",nrow(cached$cells),
              " cells; no Excel sheets reparsed")
      return(cached)
    }
  }

  # Preserve old diagnostics but never let a previous run's file masquerade as
  # a current-run failure.
  archive_previous_diagnostic(
    file.path(dirs$pisa_extract,"unmapped_country_labels.csv")
  )
  archive_previous_diagnostic(
    file.path(dirs$pisa_extract,"OECD_extraction_failures.txt")
  )

  out <- list(); oi <- 1L; failures <- list()
  for(key in names(registry)) {
    wb <- paths[[registry[[key]]]]
    if(is.null(wb) || !file.exists(wb)) next
    tid <- sub("__(2022|2018)$","",key)
    x <- try(extract_oecd_table_long(wb,tid),silent=TRUE)
    if(inherits(x,"try-error")) {
      failures[[key]] <- as.character(x)
    } else {
      x$release_key <- registry[[key]]
      x$requested_table_key <- key
      out[[oi]] <- x; oi <- oi+1L
    }
  }
  z <- if(length(out)) do.call(rbind,out) else data.frame()
  result <- list(cells=z,failures=failures,registry=registry)
  saveRDS(result,cache_file,compress="gzip")
  saveRDS(
    list(
      cache_version=OECD_EXTRACT_CACHE_VERSION,
      workbooks=current_signature,
      created_at=as.character(Sys.time()),
      n_cells=nrow(z),
      n_failures=length(failures)
    ),
    cache_meta,compress="gzip"
  )
  if(nrow(z)) write.csv(z,file.path(dirs$pisa_extract,"OECD_official_target_cells.csv"),row.names=FALSE)
  if(length(failures)) writeLines(unlist(lapply(names(failures),function(nm)
    paste(nm,failures[[nm]],sep=": "))),
    file.path(dirs$pisa_extract,"OECD_extraction_failures.txt"))
  list(cells=z,failures=failures,registry=registry)
}

# ---------- dashboard metadata ------------------------------------------------

indicator_catalog <- function() {
  data.frame(
    indicator_id=c(
      "mean_score","proficiency_baseline","proficiency_high","proficiency_advanced",
      "p10","p50","p90","p90_p10","social_score_gap","social_proficiency_gap",
      "top_performer_share","group_share","immigrant_share","home_language_share",
      "escs_missing_share","gender_score_difference","gender_proficiency_difference",
      "immigrant_score_difference_raw","immigrant_score_difference_adjusted",
      "school_social_inclusion","school_academic_inclusion","population_coverage",
      "school_response_before","school_response_after","student_response","exclusion_rate",
      "mean_score_math","mean_score_science","timss_mean_score"
    ),
    label_nl_short=c(
      "Gemiddelde score","Basisniveau gehaald","Hoog benchmarkniveau","Geavanceerd benchmarkniveau",
      "P10","Mediaan","P90","P90-P10","Sociale scorekloof","Sociale kloof basisvaardigheid",
      "Aandeel toppresteerders","Aandeel in groep","Aandeel met migratieachtergrond","Aandeel naar thuistaal",
      "Ontbrekende ESCS","Verschil meisjes-jongens","Verschil basisvaardigheid meisjes-jongens",
      "Migratiekloof, ruw","Migratiekloof, gecorrigeerd","Sociale inclusie scholen",
      "Academische inclusie scholen","Populatiedekking","Schoolrespons vóór vervanging",
      "Schoolrespons na vervanging","Leerlingrespons","Uitsluitingspercentage",
      "Gemiddelde wiskundescore","Gemiddelde natuurwetenschappenscore","TIMSS gemiddelde score"
    ),
    label_nl_long=c(
      "Gemiddelde score op de instrumentspecifieke prestatieschaal",
      "Aandeel dat het instrumentspecifieke basisniveau haalt",
      "Aandeel dat een hogere internationale benchmark haalt",
      "Aandeel dat de geavanceerde internationale benchmark haalt",
      "10e percentiel van de prestatiescore","50e percentiel van de prestatiescore",
      "90e percentiel van de prestatiescore","Verschil tussen 90e en 10e percentiel van de prestatiescore",
      "Verschil in gemiddelde score tussen hoge en lage sociale groep",
      "Verschil in basisvaardigheid tussen hoge en lage sociale groep",
      "Aandeel op het instrumentspecifieke topniveau","Aandeel leerlingen in de betreffende groep",
      "Aandeel leerlingen met de betreffende migratieachtergrond","Aandeel leerlingen in de betreffende thuistaalgroep",
      "Aandeel leerlingen zonder geldige PISA-ESCS","Verschil in gemiddelde score tussen meisjes en jongens",
      "Verschil in aandeel dat het basisniveau haalt tussen meisjes en jongens",
      "Ruw prestatieverschil naar migratieachtergrond","Prestatieverschil naar migratieachtergrond na statistische correctie voor SES en thuistaal",
      "Index van sociale inclusie binnen scholen","Index van academische inclusie binnen scholen",
      "Dekking van de relevante doelpopulatie","Gewogen schoolrespons vóór vervangingsscholen",
      "Gewogen schoolrespons na vervangingsscholen","Gewogen leerlingrespons","Overall uitsluitingspercentage",
      "Gemiddelde PISA-wiskundescore (toekomstige gevalideerde module)",
      "Gemiddelde PISA-natuurwetenschappenscore (toekomstige gevalideerde module)",
      "Gemiddelde TIMSS Grade-4 score (toekomstige gevalideerde module)"
    ),
    label_en_short=c(
      "Mean score","Baseline proficiency","High benchmark","Advanced benchmark",
      "P10","Median","P90","P90-P10","Social score gap","Social proficiency gap",
      "Top performer share","Group share","Immigrant-background share","Home-language share",
      "Missing ESCS","Girls-boys score difference","Girls-boys proficiency difference",
      "Immigrant score gap, raw","Immigrant score gap, adjusted","School social inclusion",
      "School academic inclusion","Population coverage","School response before replacement",
      "School response after replacement","Student response","Exclusion rate",
      "Mean mathematics score","Mean science score","TIMSS mean score"
    ),
    label_en_long=c(
      "Mean score on the instrument-specific performance scale","Share reaching the instrument-specific baseline proficiency threshold",
      "Share reaching a higher international benchmark","Share reaching the advanced international benchmark",
      "10th percentile of performance","50th percentile of performance","90th percentile of performance",
      "90th minus 10th percentile of performance","Mean-score difference between high and low social-background groups",
      "Proficiency difference between high and low social-background groups","Share of top performers",
      "Share of students in the specified group","Share of students with the specified immigrant background",
      "Share of students in the specified home-language group","Share of students with missing PISA ESCS",
      "Girls' mean score minus boys' mean score","Girls' baseline-proficiency share minus boys' share",
      "Raw performance difference by immigrant background","Performance difference by immigrant background after statistical adjustment for SES and language spoken at home",
      "Index of social inclusion within schools","Index of academic inclusion within schools",
      "Coverage of the relevant target population","Weighted school response before replacement schools",
      "Weighted school response after replacement schools","Weighted student response","Overall exclusion rate",
      "Mean PISA mathematics score (future validated module)","Mean PISA science score (future validated module)",
      "Mean TIMSS Grade-4 score (future validated module)"
    ),
    definition=c(
      "Weighted mean achievement score.","Share meeting the instrument-specific baseline threshold.",
      "Share meeting a higher international benchmark.","Share meeting the advanced international benchmark.",
      "10th percentile.","Median/50th percentile.","90th percentile.",
      "P90 minus P10; overall performance dispersion, not a social-background gap.",
      "High social group minus low social group in score points.",
      "High social group minus low social group in percentage points.","Share of top performers.",
      "Share of students in an explicitly defined group.","Share by immigrant-background category.",
      "Share by language spoken at home category.","Missing PISA ESCS share.",
      "Girls minus boys in score points.","Girls minus boys in percentage points of baseline proficiency.",
      "Raw immigrant/non-immigrant score difference with direction documented in group_id.",
      "Statistically adjusted immigrant-background difference after SES and home language; not causal.",
      "OECD school social-inclusion index; higher means more SES variation within rather than between schools.",
      "OECD school academic-inclusion index; higher means more achievement variation within rather than between schools.",
      "Population coverage percentage.","School response before replacement.","School response after replacement.",
      "Student response rate.","Overall exclusion rate.","Future PISA mathematics module.",
      "Future PISA science module.","Future TIMSS Grade-4 module."
    ),
    unit=c("score_points","percent","percent","percent","score_points","score_points","score_points",
           "score_points","score_points","percentage_points","percent","percent","percent","percent",
           "percent","score_points","percentage_points","score_points","score_points","percent","percent",
           "percent","percent","percent","percent","percent","score_points","score_points","score_points"),
    rounding=c(0,1,1,1,0,0,0,0,0,1,1,1,1,1,1,0,1,0,0,1,1,1,1,1,1,1,0,0,0),
    higher_is_better=c(TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,FALSE,FALSE,FALSE,TRUE,NA,NA,NA,FALSE,NA,NA,NA,NA,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,FALSE,TRUE,TRUE,TRUE),
    default_visual=c("line","line","line","line","line","line","line","line","two_panel","two_panel",
                     "line","stacked_or_dot","line","line","quality_line","dumbbell","dumbbell","dumbbell","dumbbell",
                     "dotplot","dotplot","quality_line","quality_line","quality_line","quality_line","quality_line",
                     "line","line","line"),
    source_note=c(rep("OECD PISA / IEA PIRLS, depending on survey",26),
                  "OECD PISA, future validated module","OECD PISA, future validated module","IEA TIMSS, not yet validated"),
    caveat_ids=c(
      "C01;C10;C11","C02;C10","C02;C10","C02;C10","C10;C11","C10;C11","C10;C11",
      "C17;C10;C11","C03;C04;C15","C03;C04;C15;C16","C10","C04","C19","C19","C06",
      "C10","C10","C19","C19","C19","C19","C08","C07","C07","C07","C08",
      "C01;C10;C11","C01;C10;C11","C01;C10"
    ),stringsAsFactors=FALSE
  )
}

panel_catalog <- function() {
  data.frame(
    panel_id=c("PISA_READ_LONG_32","PISA_SES_32","PIRLS_READ_MAIN13","PIRLS_READ_ROBUST16"),
    survey=c("PISA","PISA","PIRLS","PIRLS"),
    age_group=c("age15","age15","grade4_approx10","grade4_approx10"),
    domain=c("reading","reading","reading","reading"),
    years=c("2003;2006;2009;2012;2015;2018;2022;2025","2015;2018;2022;2025",
            "2001;2006;2011;2016;2021","2001;2006;2011;2016;2021"),
    selection_basis=c(
      "Locked balanced panel with valid reading data in all eight cycles and SES data in 2015-2025.",
      "Same locked 32 systems; official national ESCS-quarter reading series in every 2015-2025 wave.",
      "Strict five-wave PIRLS panel with comparable 2021 main-study timing (Group 1).",
      "Robustness only: MAIN-13 plus England, Iran and Israel (Group 3 timing)."
    ),
    panel_size=c(32,32,13,16),
    default_display=c(TRUE,TRUE,TRUE,FALSE),stringsAsFactors=FALSE
  )
}

map_panel_members <- function() {
  p32 <- country_id_from_label(PISA_FIXED32_NAMES)
  p13 <- country_id_from_code(PIRLS_MAIN13)
  p16 <- country_id_from_code(PIRLS_ROBUST16)
  if(any(is.na(c(p32,p13,p16)))) stop("Panel member missing from country crosswalk.")
  rbind(
    data.frame(panel_id="PISA_READ_LONG_32",country_id=p32),
    data.frame(panel_id="PISA_SES_32",country_id=p32),
    data.frame(panel_id="PIRLS_READ_MAIN13",country_id=p13),
    data.frame(panel_id="PIRLS_READ_ROBUST16",country_id=p16)
  )
}

# ---------- observation constructors -----------------------------------------

empty_observations <- function() data.frame(
  release_id=character(),survey=character(),source_table=character(),
  age_group=character(),domain=character(),year=integer(),country_id=character(),
  indicator_id=character(),group_dimension=character(),group_id=character(),
  estimate=numeric(),unit=character(),se=numeric(),ci_low=numeric(),ci_high=numeric(),
  scale_id=character(),threshold_id=character(),sample_id=character(),sample_definition=character(),
  quality_status=character(),caveat_ids=character(),change_direction=character(),change_reference_year=integer(),
  significant_change=logical(),stringsAsFactors=FALSE
)

obs_row <- function(survey,source_table,age_group,domain,year,country_id,indicator_id,
                    group_dimension="total",group_id="total",estimate=NA_real_,unit,
                    se=NA_real_,ci_low=NA_real_,ci_high=NA_real_,scale_id,
                    threshold_id="",sample_id="",sample_definition="",quality_status="validated",
                    caveat_ids="") {
  data.frame(release_id=DASHBOARD_RELEASE_ID,survey=survey,source_table=source_table,
    age_group=age_group,domain=domain,year=as.integer(year),country_id=country_id,
    indicator_id=indicator_id,group_dimension=group_dimension,group_id=group_id,
    estimate=as.numeric(estimate),unit=unit,se=as.numeric(se),
    ci_low=as.numeric(ci_low),ci_high=as.numeric(ci_high),scale_id=scale_id,
    threshold_id=threshold_id,sample_id=sample_id,
    sample_definition=if(nzchar(sample_definition))sample_definition else if(survey=="PISA")"15-year-old students in the PISA defined target population" else if(survey=="PIRLS")"Students in the fourth year of formal schooling / Grade 4 target population" else "",
    quality_status=quality_status,
    caveat_ids=caveat_ids,change_direction=NA_character_,change_reference_year=NA_integer_,significant_change=NA,
    stringsAsFactors=FALSE)
}

add_change_codes <- function(obs) {
  key <- paste(obs$survey,obs$domain,obs$country_id,obs$indicator_id,
               obs$group_dimension,obs$group_id,sep="|")
  obs$change_direction <- "not_applicable"
  obs$change_reference_year <- NA_integer_
  for(k in unique(key)) {
    ii <- which(key==k & is.finite(obs$estimate))
    if(length(ii)<2) next
    ii <- ii[order(obs$year[ii])]
    d <- c(NA,diff(obs$estimate[ii]))
    obs$change_direction[ii] <- ifelse(is.na(d),"not_applicable",
      ifelse(d>0,"higher",ifelse(d<0,"lower","unchanged")))
    if(length(ii)>1) obs$change_reference_year[ii[-1]] <- obs$year[ii[-length(ii)]]
  }
  obs
}

# PIRLS all-country cross-sectional estimates. Longitudinal comparisons remain
# restricted to fixed panels below.
run_pirls_all_available_dashboard <- function(asg_manifest) {
  est <- list(); dg <- list(); ei <- di <- 1L
  for(i in seq_len(nrow(asg_manifest))) {
    cc <- asg_manifest$country_code3[i]
    cid <- country_id_from_code(cc)
    if(is.na(cid)) {
      p <- file.path(dashboard_dir,"unmapped_pirls_codes.csv")
      u <- data.frame(year=asg_manifest$year[i],source_country_code=cc,stringsAsFactors=FALSE)
      if(file.exists(p)) u <- unique(rbind(read.csv(p,stringsAsFactors=FALSE),u))
      write.csv(u,p,row.names=FALSE)
      if(STRICT_COUNTRY_CROSSWALK) stop("Unmapped PIRLS source code: ",cc)
      next
    }
    log_msg("PIRLS dashboard all-available: ",asg_manifest$year[i]," ",cc)
    d <- haven::read_sav(asg_manifest$local_path[i])
    z <- try(pirls_pv_jk2_estimate(d,cc,asg_manifest$year[i]),silent=TRUE)
    if(inherits(z,"try-error")) {
      dg[[di]] <- data.frame(year=asg_manifest$year[i],country_code3=cc,country_id=cid,
        status="not_validated",reason=as.character(z),stringsAsFactors=FALSE); di <- di+1L
      next
    }
    z$estimates$country_id <- cid
    z$diagnostics$country_id <- cid
    est[[ei]] <- z$estimates; ei <- ei+1L
    dg[[di]] <- cbind(z$diagnostics,status="validated",reason=""); di <- di+1L
  }
  list(estimates=if(length(est))do.call(rbind,est) else data.frame(),
       diagnostics=if(length(dg))do.call(rbind,dg) else data.frame())
}

pirls_to_dashboard_observations <- function(pest,pdiag) {
  if(!nrow(pest)) return(empty_observations())
  out <- list(); oi <- 1L
  conv <- function(stat) {
    if(stat %in% c("prof_ge475","high_ge550","advanced_ge625",
                  "q1_prof_ge475","q4_prof_ge475","q1_high_ge550","q4_high_ge550") ||
       grepl("books[1-5]_prof_ge475",stat)) 100 else 1
  }
  for(i in seq_len(nrow(pest))) {
    r <- pest[i,]; stat <- r$statistic; mult <- conv(stat)
    indicator <- group_dim <- group_id <- threshold <- unit <- ""
    if(stat=="mean_reading") {indicator="mean_score";group_dim="total";group_id="total";unit="score_points"}
    else if(stat=="prof_ge475") {indicator="proficiency_baseline";group_dim="total";group_id="total";unit="percent";threshold="pirls_intermediate_475"}
    else if(stat=="high_ge550") {indicator="proficiency_high";group_dim="total";group_id="total";unit="percent";threshold="pirls_high_550"}
    else if(stat=="advanced_ge625") {indicator="proficiency_advanced";group_dim="total";group_id="total";unit="percent";threshold="pirls_advanced_625"}
    else if(stat %in% c("p10","p50","p90","p90_p10_scoregap")) {
      indicator=ifelse(stat=="p90_p10_scoregap","p90_p10",stat); group_dim="total";group_id="total";unit="score_points"
    } else if(stat %in% c("q1_mean_reading","q4_mean_reading")) {
      indicator="mean_score";group_dim="books_at_home_quartile_bridge";group_id=ifelse(grepl("q1",stat),"q1","q4");unit="score_points"
    } else if(stat %in% c("q1_prof_ge475","q4_prof_ge475")) {
      indicator="proficiency_baseline";group_dim="books_at_home_quartile_bridge";group_id=ifelse(grepl("q1",stat),"q1","q4");unit="percent";threshold="pirls_intermediate_475"
    } else if(stat=="q4_q1_scoregap") {
      indicator="social_score_gap";group_dim="books_at_home_quartile_bridge";group_id="q4_minus_q1";unit="score_points"
    } else if(stat=="q4_q1_profgap") {
      indicator="social_proficiency_gap";group_dim="books_at_home_quartile_bridge";group_id="q4_minus_q1";unit="percentage_points";mult=100
    } else if(grepl("^books[1-5]_mean_reading$",stat)) {
      k=as.integer(sub("books([1-5]).*","\\1",stat)); labels=c("books_0_10","books_11_25","books_26_100","books_101_200","books_gt_200")
      indicator="mean_score";group_dim="books_at_home_category";group_id=labels[k];unit="score_points"
    } else if(grepl("^books[1-5]_prof_ge475$",stat)) {
      k=as.integer(sub("books([1-5]).*","\\1",stat)); labels=c("books_0_10","books_11_25","books_26_100","books_101_200","books_gt_200")
      indicator="proficiency_baseline";group_dim="books_at_home_category";group_id=labels[k];unit="percent";threshold="pirls_intermediate_475"
    } else next
    cave <- "C01;C02;C10"
    if(group_dim!="total") cave <- paste(cave,"C21",sep=";")
    if(r$year==2021 && r$country_code3 %in% c(PIRLS_2021_GROUP2,"ENG","IRN","ISR")) cave <- paste(cave,"C09",sep=";")
    quality <- if(r$year==2021 && r$country_code3 %in% PIRLS_2021_GROUP2) "validated_with_timing_warning" else "validated"
    out[[oi]] <- obs_row("PIRLS","IEA PIRLS public-use microdata","grade4_approx10","reading",r$year,r$country_id,
      indicator,group_dim,group_id,r$estimate*mult,unit,r$se*mult,r$ci_low*mult,r$ci_high*mult,
      "pirls_reading_scale",threshold,paste0("PIRLS_",r$year,"_main_",PIRLS_SUFFIX[as.character(r$year)]),quality,cave); oi <- oi+1L
  }
  add_change_codes(do.call(rbind,out))
}

# PISA official core observations for every mapped system present in the tables.
pisa_core_to_dashboard <- function(core,cells) {
  out <- list(); oi <- 1L
  getcid <- function(nm) country_id_from_label(nm)
  for(i in seq_len(nrow(core$long))) {
    r <- core$long[i,]; cid <- getcid(r$country); if(is.na(cid)) next
    vals <- list(mean_score=c(r$mean_read,"score_points"),
                 proficiency_baseline=c(r$prof,"percent"),p10=c(r$p10,"score_points"),
                 p50=c(r$p50,"score_points"),p90=c(r$p90,"score_points"),
                 p90_p10=c(r$p90_p10,"score_points"))
    for(id in names(vals)) {
      v <- vals[[id]]; out[[oi]] <- obs_row("PISA",
        if(id=="mean_score")"I.B1.2a.37" else if(id=="proficiency_baseline")"I.B1.2a.34" else "I.B1.2a.40",
        "age15","reading",r$year,cid,id,"total","total",as.numeric(v[1]),v[2],
        scale_id="pisa_reading_scale",threshold_id=if(id=="proficiency_baseline")"pisa_level2_reading" else "",
        sample_id=paste0("PISA_",r$year),quality_status="validated_official_estimate",
        caveat_ids=if(id=="p90_p10")"C17;C11" else "C11"); oi <- oi+1L
    }
  }
  for(i in seq_len(nrow(core$ses))) {
    r <- core$ses[i,]; cid <- getcid(r$country); if(is.na(cid)) next
    for(g in c("q1","q4")) {
      out[[oi]] <- obs_row("PISA","I.B1.2b.29","age15","reading",r$year,cid,
        "proficiency_baseline","national_escs_quartile",g,r[[paste0(g,"_prof")]],"percent",
        scale_id="pisa_reading_scale",threshold_id="pisa_level2_reading",sample_id=paste0("PISA_",r$year),
        quality_status="validated_official_estimate",caveat_ids="C03;C04"); oi <- oi+1L
    }
    out[[oi]] <- obs_row("PISA","I.B1.2b.29","age15","reading",r$year,cid,
      "social_proficiency_gap","national_escs_quartile","q4_minus_q1",r$gap,"percentage_points",
      scale_id="pisa_reading_scale",threshold_id="pisa_level2_reading",sample_id=paste0("PISA_",r$year),
      quality_status="validated_official_estimate",caveat_ids="C03;C04;C15;C16"); oi <- oi+1L
  }
  add_change_codes(if(length(out))do.call(rbind,out) else empty_observations())
}

# Additional national-SES levels and top-performance tails from official tables.
standardize_pisa_national_ses_extra <- function(cells) {
  out <- list(); oi <- 1L
  for(tid in c("I.B1.2b.23","I.B1.2b.32")) {
    t <- cells[cells$table_id==tid,]; if(!nrow(t)) next
    for(j in unique(t$column_index)) {
      x <- t[t$column_index==j,]; h <- toupper(x$header[1])
      if(grepl("S\\.E\\.|STANDARD ERROR",h)) next
      year <- extract_year_from_header(h,2025)
      gid <- if(grepl("FIRST QUARTER|BOTTOM QUARTER|QUARTER 1|Q1|DISADVANTAGED",h))"q1" else
        if(grepl("FOURTH QUARTER|TOP QUARTER|QUARTER 4|Q4|ADVANTAGED",h))"q4" else NA_character_
      if(is.na(gid)) next
      iid <- if(tid=="I.B1.2b.23")"mean_score" else "top_performer_share"
      unit <- if(iid=="mean_score")"score_points" else "percent"
      for(k in seq_len(nrow(x))) {
        out[[oi]] <- obs_row("PISA",tid,"age15","reading",year,x$country_id[k],iid,
          "national_escs_quartile",gid,x$value[k],unit,
          scale_id=if(iid=="mean_score")"pisa_reading_scale" else "share_scale",
          threshold_id=if(iid=="top_performer_share")"pisa_level5plus_reading" else "",
          sample_id=paste0("PISA_",year),quality_status="validated_official_estimate_no_se",
          caveat_ids="C03;C04"); oi<-oi+1L
      }
    }
  }
  z <- if(length(out)) unique(do.call(rbind,out)) else empty_observations()
  # Derive Q4-Q1 score gap only when both levels exist; no covariance-based SE is invented.
  add <- list(); ai <- 1L
  x <- z[z$indicator_id=="mean_score",]
  if(nrow(x)) {
    keys <- unique(x[,c("year","country_id")])
    for(i in seq_len(nrow(keys))) {
      y <- x[x$year==keys$year[i] & x$country_id==keys$country_id[i],]
      q1 <- y$estimate[y$group_id=="q1"][1]; q4 <- y$estimate[y$group_id=="q4"][1]
      if(!is.finite(q1)||!is.finite(q4)) next
      add[[ai]] <- obs_row("PISA","derived_from_I.B1.2b.23","age15","reading",keys$year[i],keys$country_id[i],
        "social_score_gap","national_escs_quartile","q4_minus_q1",q4-q1,"score_points",
        scale_id="pisa_reading_scale",sample_id=paste0("PISA_",keys$year[i]),
        quality_status="validated_derived_no_covariance_se",caveat_ids="C03;C04;C15");ai<-ai+1L
    }
  }
  if(length(add)) unique(rbind(z,do.call(rbind,add))) else z
}

# Generic header parser for gender/migration tables. It only publishes a row
# when the group and statistic are explicitly recognisable; otherwise the module
# is logged as not_validated.
extract_year_from_header <- function(h,default=2025L) {
  m <- regmatches(h,gregexpr("20(0[0-9]|1[0-9]|2[0-9])",h))[[1]]
  if(length(m) && m[1]!="") as.integer(tail(m,1)) else as.integer(default)
}

standardize_gender_migration <- function(cells) {
  out <- list(); oi <- 1L
  ids <- unique(cells$table_id)
  target <- ids[grepl("I\\.B1\\.2[cd]\\.",ids)]
  for(tid in target) {
    t <- cells[cells$table_id==tid,]
    if(!nrow(t)) next
    for(j in unique(t$column_index)) {
      x <- t[t$column_index==j,]; h <- toupper(x$header[1]); year <- extract_year_from_header(h,2025)
      is_se <- grepl("S\\.E\\.|STANDARD ERROR",h)
      if(is_se) next

      # -------- gender -------------------------------------------------------
      if(grepl("I\\.B1\\.2C\\.",toupper(tid))) {
        gender <- if(tid=="I.B1.2c.26") "female" else if(tid=="I.B1.2c.27") "male" else
          if(grepl("GIRL|FEMALE",h)) "female" else if(grepl("BOY|MALE",h)) "male" else NA_character_
        ses <- if(grepl("DISADVANTAGED|BOTTOM|FIRST QUARTER|Q1",h)) "q1" else
          if(grepl("ADVANTAGED|TOP QUARTER|FOURTH QUARTER|Q4",h)) "q4" else NA_character_
        indicator <- if(tid=="I.B1.2c.34" || grepl("LOW PERFORM|BELOW LEVEL 2",h)) "proficiency_baseline" else
          if(tid=="I.B1.2c.35" || grepl("TOP PERFORM|LEVEL 5",h)) "top_performer_share" else
          if(tid %in% c("I.B1.2c.2","I.B1.2c.18","I.B1.2c.26","I.B1.2c.27") || grepl("READING PERFORMANCE|MEAN SCORE",h)) "mean_score" else NA_character_
        if(!is.na(gender) && !is.na(indicator)) {
          gd <- if(!is.na(ses)) "gender_x_national_escs_quartile" else "gender"
          gid <- if(!is.na(ses)) paste(gender,ses,sep="_") else gender
          est <- x$value
          # Low-performer tables are converted to baseline proficiency.
          if(indicator=="proficiency_baseline") est <- 100-est
          for(k in seq_len(nrow(x))) {
            out[[oi]] <- obs_row("PISA",tid,"age15","reading",year,x$country_id[k],indicator,gd,gid,est[k],
              if(indicator=="mean_score")"score_points" else "percent",scale_id="pisa_reading_scale",
              threshold_id=if(indicator=="proficiency_baseline")"pisa_level2_reading" else "",
              sample_id=paste0("PISA_",year),quality_status="validated_official_estimate_no_se",
              caveat_ids="C03;C10"); oi <- oi+1L
          }
        }
      }

      # -------- immigrant background and language ---------------------------
      if(grepl("I\\.B1\\.2D\\.",toupper(tid))) {
        mig <- if(grepl("NON[- ]IMMIGRANT|NON IMMIGRANT",h)) "non_immigrant" else
          if(grepl("FIRST[- ]GENERATION",h)) "first_generation" else
          if(grepl("SECOND[- ]GENERATION",h)) "second_generation" else
          if(grepl("IMMIGRANT",h)) "immigrant" else NA_character_
        lang <- if(grepl("LANGUAGE.*HOME|HOME LANGUAGE",h) && grepl("DIFFERENT|OTHER",h)) "different_from_assessment_language" else
          if(grepl("LANGUAGE.*HOME|HOME LANGUAGE",h) && grepl("SAME|ASSESSMENT",h)) "same_as_assessment_language" else NA_character_

        # Direct adjusted-difference table: keep separate from raw levels.
        if(tid=="I.B1.2d.11") {
          if(grepl("DIFFERENCE|AFTER ACCOUNTING|ADJUST",h) || !grepl("PERCENT|SHARE",h)) {
            for(k in seq_len(nrow(x))) {
              out[[oi]] <- obs_row("PISA",tid,"age15","reading",year,x$country_id[k],
                "immigrant_score_difference_adjusted","immigrant_comparison","immigrant_minus_non_immigrant_adjusted",
                x$value[k],"score_points",scale_id="pisa_reading_scale",sample_id=paste0("PISA_",year),
                quality_status="validated_official_estimate_no_se",caveat_ids="C19"); oi <- oi+1L
            }
          }
          next
        }

        indicator <- if(tid=="I.B1.2d.1" && grepl("PERCENT|SHARE|IMMIGRANT",h)) "immigrant_share" else
          if(tid=="I.B1.2d.6" && (!is.na(lang) || grepl("LANGUAGE",h))) "home_language_share" else
          if(tid=="I.B1.2d.14" || grepl("LOW PERFORM|BELOW LEVEL 2",h)) "proficiency_baseline" else
          if(tid=="I.B1.2d.8" || grepl("READING PERFORMANCE|MEAN SCORE",h)) "mean_score" else NA_character_
        gid <- if(!is.na(lang) && !is.na(mig)) paste(lang,mig,sep="__") else if(!is.na(lang)) lang else mig
        gd <- if(!is.na(lang) && !is.na(mig)) "home_language_x_immigrant_background" else if(!is.na(lang)) "home_language" else "immigrant_background"
        if(!is.na(gid) && !is.na(indicator)) {
          est <- x$value
          if(indicator=="proficiency_baseline") est <- 100-est
          for(k in seq_len(nrow(x))) {
            out[[oi]] <- obs_row("PISA",tid,"age15","reading",year,x$country_id[k],indicator,gd,gid,est[k],
              if(indicator=="mean_score")"score_points" else "percent",scale_id="pisa_reading_scale",
              threshold_id=if(indicator=="proficiency_baseline")"pisa_level2_reading" else "",
              sample_id=paste0("PISA_",year),quality_status="validated_official_estimate_no_se",caveat_ids="C19"); oi <- oi+1L
          }
        }
      }
    }
  }
  z <- if(length(out)) unique(do.call(rbind,out)) else empty_observations()
  z <- derive_dashboard_group_differences(z)
  add_change_codes(z)
}

derive_dashboard_group_differences <- function(obs) {
  add <- list(); ai <- 1L
  # Gender values must remain present; differences are added, never substituted.
  for(ind in c("mean_score","proficiency_baseline")) {
    x <- obs[obs$survey=="PISA" & obs$group_dimension=="gender" & obs$indicator_id==ind,]
    if(!nrow(x)) next
    keys <- unique(x[,c("year","country_id")])
    for(i in seq_len(nrow(keys))) {
      y <- x[x$year==keys$year[i] & x$country_id==keys$country_id[i],]
      f <- y$estimate[y$group_id=="female"][1]; m <- y$estimate[y$group_id=="male"][1]
      if(!is.finite(f) || !is.finite(m)) next
      iid <- if(ind=="mean_score")"gender_score_difference" else "gender_proficiency_difference"
      unit <- if(ind=="mean_score")"score_points" else "percentage_points"
      add[[ai]] <- obs_row("PISA","derived_from_gender_levels","age15","reading",keys$year[i],keys$country_id[i],
        iid,"gender_comparison","female_minus_male",f-m,unit,scale_id="pisa_reading_scale",
        threshold_id=if(ind=="proficiency_baseline")"pisa_level2_reading" else "",sample_id=paste0("PISA_",keys$year[i]),
        quality_status="validated_derived_no_covariance_se",caveat_ids="C10"); ai <- ai+1L
    }
  }
  # Raw immigrant difference is derived only if both aggregate immigrant and non-immigrant levels exist.
  x <- obs[obs$survey=="PISA" & obs$group_dimension=="immigrant_background" & obs$indicator_id=="mean_score",]
  if(nrow(x)) {
    keys <- unique(x[,c("year","country_id")])
    for(i in seq_len(nrow(keys))) {
      y <- x[x$year==keys$year[i] & x$country_id==keys$country_id[i],]
      im <- y$estimate[y$group_id=="immigrant"][1]; ni <- y$estimate[y$group_id=="non_immigrant"][1]
      if(!is.finite(im) || !is.finite(ni)) next
      add[[ai]] <- obs_row("PISA","derived_from_I.B1.2d.8","age15","reading",keys$year[i],keys$country_id[i],
        "immigrant_score_difference_raw","immigrant_comparison","immigrant_minus_non_immigrant",im-ni,"score_points",
        scale_id="pisa_reading_scale",sample_id=paste0("PISA_",keys$year[i]),quality_status="validated_derived_no_covariance_se",caveat_ids="C19"); ai<-ai+1L
    }
  }
  if(length(add)) unique(rbind(obs,do.call(rbind,add))) else obs
}

# Supplementary absolute-SES and school-sorting modules. They are cross-sectional
# 2025 unless a validated trend table is explicitly available.
standardize_absolute_ses_and_sorting <- function(cells) {
  out <- list(); oi <- 1L
  for(tid in c("I.B1.2b.7","I.B1.2b.12","I.B1.2b.17","I.B1.2a.27")) {
    t <- cells[cells$table_id==tid,]; if(!nrow(t)) next
    for(j in unique(t$column_index)) {
      x <- t[t$column_index==j,]; h <- toupper(x$header[1])
      if(grepl("S\\.E\\.|STANDARD ERROR",h)) next
      if(tid %in% c("I.B1.2b.7","I.B1.2b.12")) {
        gid <- if(grepl("FIRST|Q1|BOTTOM",h))"q1" else if(grepl("SECOND|Q2",h))"q2" else if(grepl("THIRD|Q3",h))"q3" else if(grepl("FOURTH|Q4|TOP",h))"q4" else NA_character_
        if(is.na(gid)) next
        iid <- if(tid=="I.B1.2b.7")"group_share" else "mean_score"
        unit <- if(iid=="group_share")"percent" else "score_points"
        for(k in seq_len(nrow(x))) {out[[oi]]<-obs_row("PISA",tid,"age15","reading",2025,x$country_id[k],iid,"international_escs_quartile",gid,x$value[k],unit,
          scale_id=if(iid=="mean_score")"pisa_reading_scale" else "share_scale",sample_id="PISA_2025",quality_status="validated_official_estimate_no_se",caveat_ids="C04");oi<-oi+1L}
      } else {
        # Only publish the explicit inclusion index, not raw variance components.
        if(!grepl("INDEX.*INCLUSION|INCLUSION.*INDEX",h)) next
        iid <- if(tid=="I.B1.2b.17")"school_social_inclusion" else "school_academic_inclusion"
        for(k in seq_len(nrow(x))) {out[[oi]]<-obs_row("PISA",tid,"age15","reading",2025,x$country_id[k],iid,"total","total",x$value[k],"percent",
          scale_id="index_percent",sample_id="PISA_2025_modal_ISCED",quality_status="validated_official_estimate_no_se",caveat_ids="C19");oi<-oi+1L}
      }
    }
  }
  if(length(out)) unique(do.call(rbind,out)) else empty_observations()
}

# Corresponding standard errors: conservative nearest-SE matching. If the OECD
# workbook layout does not produce a unique match, SE remains NA and no rank
# uncertainty claim is allowed.

# v1.3.1 regression lock:
# Any scalar if() inside an observation-row loop must index row-varying columns
# with [i]. Do not use `if(obs$column == ...)` on a full vector.
attach_oecd_standard_errors <- function(obs,cells) {
  if(!nrow(obs) || !nrow(cells)) return(obs)

  # Pre-index once by table x country. The old implementation re-scanned the
  # complete OECD cell table for every observation row, which is both slow and
  # error-prone. This keeps exactly the same conservative nearest-SE logic.
  cell_key <- paste(cells$table_id,cells$country_id,sep="\034")
  cell_index <- split(seq_len(nrow(cells)),cell_key)

  for(i in seq_len(nrow(obs))) {
    key <- paste(obs$source_table[i],obs$country_id[i],sep="\034")
    ii <- cell_index[[key]]
    if(is.null(ii) || !length(ii)) next

    t <- cells[ii,,drop=FALSE]
    h <- toupper(as.character(t$header))
    yr <- as.character(obs$year[i])

    # 2025 tables sometimes express the current wave without repeating the year
    # on every leaf header; preserve the existing conservative treatment.
    yrmatch <- grepl(yr,h,fixed=TRUE) | as.integer(obs$year[i])==2025L
    secols <- unique(t$column_index[
      yrmatch & grepl("S\\.E\\.|STANDARD ERROR",h)
    ])
    if(!length(secols)) next

    # Identify the estimate column by numerical value. For PISA baseline
    # proficiency the official source column is "below Level 2", while the
    # dashboard displays 100 - below-Level-2.
    target <- as.numeric(obs$estimate[i])
    candidate_value <- as.numeric(t$value)

    if(identical(as.character(obs$indicator_id[i]),"proficiency_baseline") &&
       identical(as.character(obs$unit[i]),"percent")) {
      candidate_value <- 100-candidate_value
    }

    eok <- yrmatch &
      !grepl("S\\.E\\.|STANDARD ERROR",h) &
      is.finite(candidate_value) &
      abs(candidate_value-target)<1e-5

    ecols <- unique(t$column_index[eok])
    if(length(ecols)!=1L) next

    d <- abs(secols-ecols)
    nearest <- secols[d==min(d)]
    if(length(nearest)!=1L) next

    seval <- t$value[t$column_index==nearest]
    seval <- seval[is.finite(seval)][1]
    if(!is.finite(seval)) next

    obs$se[i] <- as.numeric(seval)
    obs$ci_low[i] <- target-1.96*as.numeric(seval)
    obs$ci_high[i] <- target+1.96*as.numeric(seval)

    # Keep legacy status cleanup for the old observation object. v2 later
    # remaps status semantics explicitly.
    obs$quality_status[i] <- sub("_no_se$","",obs$quality_status[i])
  }

  obs
}

# ---------- quality tables ---------------------------------------------------

standardize_sample_quality <- function(cells) {
  out <- list(); oi <- 1L
  t <- cells[grepl("^I\\.A2\\.[16]$",cells$table_id),]
  if(!nrow(t)) return(empty_observations())
  for(jj in unique(paste(t$requested_table_key,t$column_index,sep="|"))) {
    z <- t[paste(t$requested_table_key,t$column_index,sep="|")==jj,]; h <- toupper(z$header[1]); rel <- z$release_key[1]
    year <- if(grepl("2018",rel))2018L else if(grepl("2022",rel))2022L else 2025L
    if(grepl("S\\.E\\.|STANDARD ERROR",h)) next
    iid <- if(grepl("OVERALL EXCLUSION RATE",h))"exclusion_rate" else
      if(grepl("COVERAGE INDEX 3|COVERAGE OF 15-YEAR-OLD POPULATION",h))"population_coverage" else
      if(grepl("SCHOOL RESPONSE.*BEFORE|BEFORE REPLACEMENT",h))"school_response_before" else
      if(grepl("SCHOOL RESPONSE.*AFTER|AFTER REPLACEMENT",h))"school_response_after" else
      if(grepl("STUDENT RESPONSE",h))"student_response" else NA_character_
    if(is.na(iid)) next
    est <- z$value; if(iid=="population_coverage") est[is.finite(est)&est<=1.5] <- 100*est[is.finite(est)&est<=1.5]
    for(k in seq_len(nrow(z))) {out[[oi]]<-obs_row("PISA",z$table_id[k],"age15","quality",year,z$country_id[k],iid,"total","total",est[k],"percent",
      scale_id="quality_percent",sample_id=paste0("PISA_",year),quality_status="validated_official_estimate_no_se",caveat_ids=if(iid=="exclusion_rate")"C08" else "C07;C08");oi<-oi+1L}
  }
  if(length(out))unique(do.call(rbind,out)) else empty_observations()
}

# ---------- panels, comparisons, availability --------------------------------

make_dashboard_comparisons <- function(obs,panels,panel_members) {
  out <- list(); oi <- 1L
  meta <- indicator_catalog()
  panel_metrics <- list(
    PISA_READ_LONG_32=c("mean_score","proficiency_baseline","p10","p50","p90","p90_p10"),
    PISA_SES_32=c("mean_score","proficiency_baseline","top_performer_share","social_score_gap","social_proficiency_gap"),
    PIRLS_READ_MAIN13=c("mean_score","proficiency_baseline","proficiency_high","proficiency_advanced","p10","p50","p90","p90_p10","social_score_gap","social_proficiency_gap"),
    PIRLS_READ_ROBUST16=c("mean_score","proficiency_baseline","proficiency_high","proficiency_advanced","p10","p50","p90","p90_p10","social_score_gap","social_proficiency_gap")
  )
  allcountries <- unique(obs$country_id)
  for(p in panels$panel_id) {
    pp <- panels[panels$panel_id==p,]; yrs <- as.integer(strsplit(pp$years,";",fixed=TRUE)[[1]])
    memb <- panel_members$country_id[panel_members$panel_id==p]
    metrics <- panel_metrics[[p]]
    for(ind in metrics) for(yr in yrs) {
      # For SES panels, group-specific levels receive their own comparisons.
      sub <- obs[obs$survey==pp$survey & obs$domain==pp$domain & obs$year==yr & obs$indicator_id==ind,]
      if(!nrow(sub)) next
      groups <- unique(paste(sub$group_dimension,sub$group_id,sep="|"))
      for(gr in groups) {
        ss <- sub[paste(sub$group_dimension,sub$group_id,sep="|")==gr,]
        pm <- ss[ss$country_id %in% memb & is.finite(ss$estimate),]
        if(!nrow(pm)) next
        if(length(unique(pm$country_id))!=length(memb)) {
          # Fixed panel must remain complete for a longitudinal panel comparison.
          reason <- setdiff(memb,pm$country_id)
          if(STRICT_VALIDATION) stop("Incomplete fixed panel ",p," for ",ind," ",yr," group ",gr,". Missing: ",paste(reason,collapse=","))
        }
        hib <- meta$higher_is_better[match(ind,meta$indicator_id)]
        rank_direction <- if(isFALSE(hib)) "ascending_smallest_is_1" else "descending_highest_is_1"
        rr <- if(isFALSE(hib)) rank(pm$estimate,ties.method="min") else rank(-pm$estimate,ties.method="min")
        ord <- order(pm$estimate,pm$country_id); pos <- (seq_along(ord)-.5)/length(ord)
        terc <- rep(NA_character_,length(ord)); terc[ord] <- ifelse(pos<=1/3,"bottom",ifelse(pos<=2/3,"middle","top"))
        bench <- mean(pm$estimate)
        for(cid in unique(c(allcountries,memb))) {
          k <- match(cid,pm$country_id); eligible <- cid %in% memb
          out[[oi]] <- data.frame(
            release_id=DASHBOARD_RELEASE_ID,panel_id=p,country_id=cid,year=yr,indicator_id=ind,
            group_dimension=strsplit(gr,"|",fixed=TRUE)[[1]][1],group_id=strsplit(gr,"|",fixed=TRUE)[[1]][2],
            rank=if(eligible && !is.na(k))rr[k] else NA_real_,rank_n=if(eligible)length(memb) else length(memb),
            rank_direction=rank_direction,tercile=if(eligible && !is.na(k))terc[k] else NA_character_,
            benchmark_id="panel_unweighted_mean",benchmark_value=bench,
            benchmark_includes_selected_country=eligible,
            benchmark_relation=if(eligible && !is.na(k))ifelse(pm$estimate[k]>bench,"above",ifelse(pm$estimate[k]<bench,"below","equal")) else NA_character_,
            rank_ci_low=NA_real_,rank_ci_high=NA_real_,eligible=eligible,
            unavailability_reason=if(!eligible)"not_panel_member" else if(is.na(k))"missing_indicator_year" else "",
            stringsAsFactors=FALSE); oi <- oi+1L
        }
      }
    }
  }
  if(length(out)) unique(do.call(rbind,out)) else data.frame()
}

build_availability <- function(obs,countries,indicators,panels) {
  out <- list(); oi <- 1L
  actual <- unique(obs[,c("country_id","age_group","domain","indicator_id","year","quality_status")])
  if(nrow(actual)) for(i in seq_len(nrow(actual))) {
    # content question is indicator-based and independent of frontend wording.
    iid <- actual$indicator_id[i]
    od <- obs[obs$country_id==actual$country_id[i] & obs$year==actual$year[i] & obs$indicator_id==iid,,drop=FALSE]
    gd <- unique(od$group_dimension)[1]
    q <- if(grepl("escs|books_at_home",gd))"social_background" else if(grepl("gender",gd) || grepl("gender",iid))"gender" else if(grepl("immigrant|language",gd) || grepl("immigrant|language",iid))"migration_language" else if(iid %in% c("p10","p50","p90","p90_p10"))"distribution" else if(iid %in% c("social_score_gap","social_proficiency_gap"))"social_background" else if(grepl("school_",iid))"school_sorting" else if(grepl("response|coverage|exclusion|missing",iid))"quality" else "performance_level"
    out[[oi]] <- data.frame(country_id=actual$country_id[i],age_group=actual$age_group[i],domain=actual$domain[i],content_question=q,
      indicator_id=iid,year=actual$year[i],available=TRUE,status=actual$quality_status[i],reason_code="",stringsAsFactors=FALSE);oi<-oi+1L
  }

  # Explicit expected calendars for the validated reading modules. Missing cells are visible, never imputed.
  calendars <- list(
    PISA_reading=list(age="age15",domain="reading",years=c(2003,2006,2009,2012,2015,2018,2022,2025),inds=c("mean_score","proficiency_baseline","p10","p50","p90","p90_p10")),
    PISA_ses=list(age="age15",domain="reading",years=c(2015,2018,2022,2025),inds=c("social_proficiency_gap")),
    PIRLS_reading=list(age="grade4_approx10",domain="reading",years=c(2001,2006,2011,2016,2021),inds=c("mean_score","proficiency_baseline","p10","p50","p90","p90_p10","social_score_gap","social_proficiency_gap")),
    PISA_gender=list(age="age15",domain="reading",years=c(2015,2018,2022,2025),inds=c("mean_score","proficiency_baseline","gender_score_difference","gender_proficiency_difference")),
    PISA_migration=list(age="age15",domain="reading",years=c(2015,2018,2022,2025),inds=c("mean_score","proficiency_baseline","immigrant_score_difference_raw","immigrant_score_difference_adjusted")),
    PISA_absolute_SES=list(age="age15",domain="reading",years=c(2025),inds=c("mean_score","group_share")),
    PISA_school_sorting=list(age="age15",domain="reading",years=c(2025),inds=c("school_social_inclusion","school_academic_inclusion"))
  )
  for(nm in names(calendars)) {
    cal <- calendars[[nm]]; survey <- if(grepl("^PISA",nm))"PISA" else "PIRLS"
    cc <- unique(obs$country_id[obs$survey==survey])
    for(cid in cc) for(iid in cal$inds) for(yr in cal$years) {
      exists <- nrow(obs[obs$country_id==cid & obs$survey==survey & obs$domain==cal$domain & obs$indicator_id==iid & obs$year==yr,])>0
      if(exists) next
      q <- if(grepl("gender",nm,ignore.case=TRUE))"gender" else if(grepl("migration",nm,ignore.case=TRUE))"migration_language" else if(grepl("absolute_SES|ses",nm,ignore.case=TRUE))"social_background" else if(grepl("sorting",nm,ignore.case=TRUE))"school_sorting" else if(iid %in% c("p10","p50","p90","p90_p10"))"distribution" else if(grepl("social_",iid))"social_background" else "performance_level"
      out[[oi]] <- data.frame(country_id=cid,age_group=cal$age,domain=cal$domain,content_question=q,indicator_id=iid,year=yr,
        available=FALSE,status="not_available",reason_code="no_validated_observation_for_country_year",stringsAsFactors=FALSE);oi<-oi+1L
    }
  }
  # Future modules explicitly hidden.
  pisa_c <- unique(obs$country_id[obs$survey=="PISA"]); pirls_c <- unique(obs$country_id[obs$survey=="PIRLS"])
  for(cid in pisa_c) for(dom in c("mathematics","science")) {iid<-if(dom=="mathematics")"mean_score_math" else "mean_score_science";out[[oi]]<-data.frame(country_id=cid,age_group="age15",domain=dom,content_question="performance_level",indicator_id=iid,year=NA_integer_,available=FALSE,status="not_validated",reason_code="domain_panel_not_validated",stringsAsFactors=FALSE);oi<-oi+1L}
  for(cid in pirls_c) {out[[oi]]<-data.frame(country_id=cid,age_group="grade4_approx10",domain="mathematics_science",content_question="performance_level",indicator_id="timss_mean_score",year=NA_integer_,available=FALSE,status="not_validated",reason_code="timss_recalculation_module_not_built",stringsAsFactors=FALSE);oi<-oi+1L}
  unique(do.call(rbind,out))
}

# ---------- validation --------------------------------------------------------

validation_check <- function(id,pass,details="",severity="error") {
  data.frame(check_id=id,pass=isTRUE(pass),severity=severity,details=as.character(details),stringsAsFactors=FALSE)
}

validate_dashboard_bundle <- function(countries,obs,comparisons,indicators,panels,panel_members,availability) {
  ck <- list(); ci <- 1L
  obs_key <- paste(obs$release_id,obs$survey,obs$source_table,obs$age_group,obs$domain,obs$year,obs$country_id,obs$indicator_id,obs$group_dimension,obs$group_id,sep="|")
  ck[[ci]] <- validation_check("observations_unique_key",!anyDuplicated(obs_key),paste(sum(duplicated(obs_key)),"duplicates")); ci<-ci+1L
  cmp_key <- if(nrow(comparisons)) paste(comparisons$release_id,comparisons$panel_id,comparisons$country_id,comparisons$year,comparisons$indicator_id,comparisons$group_dimension,comparisons$group_id,sep="|") else character()
  ck[[ci]] <- validation_check("comparisons_unique_key",!anyDuplicated(cmp_key),paste(sum(duplicated(cmp_key)),"duplicates")); ci<-ci+1L
  ck[[ci]] <- validation_check("country_ids_known",all(obs$country_id %in% countries$country_id),"All observations map to controlled country crosswalk"); ci<-ci+1L
  ck[[ci]] <- validation_check("indicator_ids_known",all(obs$indicator_id %in% indicators$indicator_id),paste(setdiff(unique(obs$indicator_id),indicators$indicator_id),collapse=",")); ci<-ci+1L
  ck[[ci]] <- validation_check("rank_range",all(is.na(comparisons$rank) | (comparisons$rank>=1 & comparisons$rank<=comparisons$rank_n)),"Ranks within 1..rank_n"); ci<-ci+1L
  # panel member counts
  pc <- aggregate(panel_members$country_id,by=list(panel_id=panel_members$panel_id),FUN=function(x)length(unique(x)))
  names(pc)[2] <- "n"; mm <- merge(panels[,c("panel_id","panel_size")],pc,by="panel_id",all.x=TRUE)
  ck[[ci]] <- validation_check("panel_member_counts",all(mm$panel_size==mm$n),paste(apply(mm,1,paste,collapse=":"),collapse="; ")); ci<-ci+1L
  if(nrow(comparisons)) {
    ec <- aggregate(comparisons$eligible,by=list(panel_id=comparisons$panel_id,year=comparisons$year,indicator_id=comparisons$indicator_id,group_dimension=comparisons$group_dimension,group_id=comparisons$group_id),FUN=sum)
    expsz <- panels$panel_size[match(ec$panel_id,panels$panel_id)]
    ck[[ci]] <- validation_check("fixed_panel_same_n_each_year",all(ec$x==expsz),paste(sum(ec$x!=expsz),"incomplete panel-years"));ci<-ci+1L
  }
  # units/ranges
  pct <- obs$unit=="percent" & is.finite(obs$estimate)
  ck[[ci]] <- validation_check("percent_range",all(obs$estimate[pct]>=0 & obs$estimate[pct]<=100),"Percent estimates between 0 and 100"); ci<-ci+1L
  pp <- obs$unit=="percentage_points" & is.finite(obs$estimate)
  ck[[ci]] <- validation_check("percentage_point_range",all(obs$estimate[pp]>=-100 & obs$estimate[pp]<=100),"Percentage-point gaps plausible"); ci<-ci+1L
  # scales never mixed within survey/domain indicator
  sm <- aggregate(obs$scale_id,by=list(survey=obs$survey,domain=obs$domain,indicator=obs$indicator_id),FUN=function(x)length(unique(x[nzchar(x)])))
  ck[[ci]] <- validation_check("no_scale_mixing",all(sm$x<=1),"At most one non-empty scale_id per survey/domain/indicator"); ci<-ci+1L
  # gap underlying groups
  gaps <- obs[obs$indicator_id %in% c("social_score_gap","social_proficiency_gap"),]
  gap_ok <- TRUE; missing_gap <- character()
  if(nrow(gaps)) for(i in seq_len(nrow(gaps))) {
    g <- gaps[i,]; baseind <- if(g$indicator_id=="social_score_gap")"mean_score" else "proficiency_baseline"
    x <- obs[obs$survey==g$survey & obs$country_id==g$country_id & obs$year==g$year & obs$indicator_id==baseind & obs$group_dimension==g$group_dimension,]
    if(!all(c("q1","q4") %in% x$group_id)) {gap_ok<-FALSE;missing_gap<-c(missing_gap,paste(g$survey,g$country_id,g$year,g$group_dimension))}
  }
  ck[[ci]] <- validation_check("gaps_have_levels",gap_ok,paste(unique(missing_gap),collapse="; ")); ci<-ci+1L
  # Netherlands sanity from existing validated targets where present
  getobs <- function(yr,id,group="total",dim="total") obs$estimate[obs$survey=="PISA" & obs$country_id=="iso3:NLD" & obs$year==yr & obs$indicator_id==id & obs$group_id==group & obs$group_dimension==dim][1]
  sanity <- c(abs(getobs(2003,"mean_score")-PISA_NL_SANITY$mean_read_2003)<=2,
              abs(getobs(2025,"mean_score")-PISA_NL_SANITY$mean_read_2025)<=2,
              abs(getobs(2003,"proficiency_baseline")-PISA_NL_SANITY$prof_2003)<=2,
              abs(getobs(2025,"proficiency_baseline")-PISA_NL_SANITY$prof_2025)<=2)
  sanity[is.na(sanity)] <- FALSE
  ck[[ci]] <- validation_check("netherlands_pisa_sanity",all(sanity),paste(sanity,collapse=",")); ci<-ci+1L
  # Non-NL regression tests from previously validated fixed-32 output
  au <- obs$estimate[obs$survey=="PISA" & obs$country_id=="iso3:AUS" & obs$year==2003 & obs$indicator_id=="mean_score" & obs$group_id=="total"][1]
  de <- obs$estimate[obs$survey=="PISA" & obs$country_id=="iso3:DEU" & obs$year==2025 & obs$indicator_id=="mean_score" & obs$group_id=="total"][1]
  se <- obs$estimate[obs$survey=="PISA" & obs$country_id=="iso3:SWE" & obs$year==2025 & obs$indicator_id=="mean_score" & obs$group_id=="total"][1]
  reg <- c(abs(au-525.42701)<=2,abs(de-465.28206)<=2,abs(se-466.43629)<=2); reg[is.na(reg)]<-FALSE
  ck[[ci]] <- validation_check("non_nl_regression_tests",all(reg),paste(reg,collapse=",")); ci<-ci+1L
  # no publication of not_validated in observations
  ck[[ci]] <- validation_check("no_not_validated_observations",!any(obs$quality_status=="not_validated"),"Unvalidated modules belong only in availability/module status"); ci<-ci+1L
  do.call(rbind,ck)
}

write_deterministic_json <- function(df,path,sort_cols=NULL) {
  if(!is.null(sort_cols) && nrow(df)) {
    sort_cols <- intersect(sort_cols,names(df)); if(length(sort_cols)) {
      ord <- do.call(order,c(lapply(sort_cols,function(nm)df[[nm]]),list(na.last=TRUE)))
      df <- df[ord,,drop=FALSE]
    }
  }
  jsonlite::write_json(df,path,dataframe="rows",pretty=FALSE,na="null",auto_unbox=TRUE,digits=NA)
}

file_sha256 <- function(path) {
  raw <- readBin(path,what="raw",n=file.info(path)$size)
  as.character(openssl::sha256(raw))
}

scale_catalog <- function() data.frame(
  scale_id=c("pisa_reading_scale","pirls_reading_scale","index_percent","share_scale","quality_percent"),
  label_nl=c("PISA-leesschaal","PIRLS-leesschaal","Index in procenten","Aandeel","Kwaliteitspercentage"),
  label_en=c("PISA reading scale","PIRLS reading scale","Percent index","Share","Quality percentage"),
  directly_comparable_across_surveys=c(FALSE,FALSE,FALSE,FALSE,FALSE),stringsAsFactors=FALSE)

threshold_catalog <- function() data.frame(
  threshold_id=c("pisa_level2_reading","pisa_level5plus_reading","pirls_intermediate_475","pirls_high_550","pirls_advanced_625"),
  label_nl=c("PISA lezen Level 2","PISA lezen Level 5 of hoger","PIRLS Intermediate 475","PIRLS High 550","PIRLS Advanced 625"),
  label_en=c("PISA reading Level 2","PISA reading Level 5+","PIRLS Intermediate 475","PIRLS High 550","PIRLS Advanced 625"),
  instrument=c("PISA","PISA","PIRLS","PIRLS","PIRLS"),
  domain="reading",stringsAsFactors=FALSE)

sample_catalog_from_observations <- function(obs) {
  x <- unique(obs[,c("sample_id","survey","age_group","year","sample_definition")])
  x[nzchar(x$sample_id),,drop=FALSE]
}

write_dashboard_bundle <- function(master,asg=NULL,oecd=NULL,pisa_core=NULL) {
  log_msg("=== DASHBOARD: reproducible all-country export ===")
  indicators <- indicator_catalog(); panels <- panel_catalog(); pm <- map_panel_members()

  obs_list <- list(); oi <- 1L
  # PISA official
  if(!is.null(pisa_core)) {
    pc <- pisa_core_to_dashboard(pisa_core,if(!is.null(oecd))oecd$cells else data.frame())
    if(!is.null(oecd) && nrow(oecd$cells)) pc <- attach_oecd_standard_errors(pc,oecd$cells)
    obs_list[[oi]] <- pc; oi<-oi+1L
  }
  if(!is.null(oecd) && nrow(oecd$cells)) {
    sx <- standardize_pisa_national_ses_extra(oecd$cells)
    sx <- attach_oecd_standard_errors(sx,oecd$cells)
    obs_list[[oi]] <- sx; oi<-oi+1L
    gm <- standardize_gender_migration(oecd$cells)
    gm <- attach_oecd_standard_errors(gm,oecd$cells)
    obs_list[[oi]] <- gm; oi<-oi+1L
    ae <- standardize_absolute_ses_and_sorting(oecd$cells)
    ae <- attach_oecd_standard_errors(ae,oecd$cells)
    obs_list[[oi]] <- ae; oi<-oi+1L
    qq <- standardize_sample_quality(oecd$cells)
    obs_list[[oi]] <- qq; oi<-oi+1L
  }
  # PIRLS all source countries/systems, not only panel members.
  if(RUN_DASHBOARD_PIRLS_ALL_AVAILABLE && !is.null(asg)) {
    pa <- run_pirls_all_available_dashboard(asg)
    saveRDS(pa,file.path(dashboard_dir,"pirls_all_available_internal.rds"),compress="xz")
    obs_list[[oi]] <- pirls_to_dashboard_observations(pa$estimates,pa$diagnostics); oi<-oi+1L
  } else if(!is.null(master$pirls_main13)) {
    tmp <- master$pirls_main13$estimates; tmp$country_id <- country_id_from_code(tmp$country_code3)
    obs_list[[oi]] <- pirls_to_dashboard_observations(tmp,master$pirls_main13$diagnostics); oi<-oi+1L
  }
  observations <- if(length(obs_list)) unique(do.call(rbind,obs_list)) else empty_observations()
  observations <- observations[observations$quality_status!="not_validated",,drop=FALSE]
  observations <- add_change_codes(observations)

  observed_ids <- unique(c(observations$country_id,pm$country_id))
  countries <- DASH_COUNTRIES[DASH_COUNTRIES$country_id %in% observed_ids,
    c("country_id","country_name_nl","country_name_en","iso3","source_country_code","geography_type","aliases"),drop=FALSE]
  countries <- countries[order(countries$country_name_en),]

  comparisons <- make_dashboard_comparisons(observations,panels,pm)
  availability <- build_availability(observations,countries,indicators,panels)

  # Module status: future domains and modules stay explicit and hidden.
  scales <- scale_catalog(); thresholds <- threshold_catalog(); samples <- sample_catalog_from_observations(observations)

  modules <- data.frame(
    module_id=c("pisa_reading_core","pisa_gender","pisa_migration_language","pisa_absolute_ses",
                "pisa_school_sorting","pisa_home_language_performance","pisa_math","pisa_science","pirls_reading",
                "pirls_parent_ses_robustness","timss_grade4_math_science","pisa_2025_full_response_table"),
    status=c("validated","validated_if_parser_passes","validated_if_parser_passes","validated_if_parser_passes",
             "validated_if_parser_passes","not_validated","not_validated","not_validated","validated",
             "not_validated","not_validated","not_available"),
    reason=c("Official OECD reading series and fixed-panel sanity checks.",
             "Official tables standardised only when header/group parsing is unambiguous.",
             "Migration and home-language dimensions remain separate; adjusted result has separate indicator.",
             "International ESCS groups are separate from national relative SES.",
             "Modal-ISCED official inclusion measures; robustness unrestricted tables retained raw.",
             "Official release has language composition by immigrant background, but a separate validated reading-by-home-language module requires microdata.",
             "Domain-specific fixed longitudinal panel not yet validated.",
             "Domain-specific fixed longitudinal panel not yet validated.",
             "Five-PV JK2 estimator validated against official IEA 2021 results.",
             "Response correction method not yet locked.",
             "Discovery hook only; no validated estimator yet.",
             "Full uniform 2025 country response table awaits Technical Report; existing country warnings remain caveats."),stringsAsFactors=FALSE
  )

  # data dictionary
  dict_rows <- list(); di <- 1L
  add_dict <- function(file,df,desc) {
    for(nm in names(df)) {
      dict_rows[[di]] <<- data.frame(file=file,field=nm,r_type=class(df[[nm]])[1],description=desc[[nm]] %||% "",stringsAsFactors=FALSE); di<<-di+1L
    }
  }
  `%||%` <- function(x,y) if(is.null(x)) y else x
  desc_obs <- as.list(setNames(rep("",length(names(observations))),names(observations)))
  desc_obs$estimate <- "Point estimate in the unit named by unit."; desc_obs$se <- "Standard error where available; blank otherwise."
  desc_obs$quality_status <- "Validation/publication status; not_validated rows are not published here."
  desc_cmp <- as.list(setNames(rep("",length(names(comparisons))),names(comparisons)))
  desc_cmp$rank <- "Rank within the fixed panel for this indicator/year/group."; desc_cmp$benchmark_value <- "Unweighted mean across fixed panel members."
  add_dict("countries.csv",countries,as.list(setNames(rep("",ncol(countries)),names(countries))))
  add_dict("observations.csv",observations,desc_obs); add_dict("comparisons.csv",comparisons,desc_cmp)
  add_dict("indicators.csv",indicators,as.list(setNames(rep("",ncol(indicators)),names(indicators))))
  add_dict("panels.csv",panels,as.list(setNames(rep("",ncol(panels)),names(panels))))
  add_dict("panel_members.csv",pm,as.list(setNames(rep("",ncol(pm)),names(pm))))
  add_dict("availability.csv",availability,as.list(setNames(rep("",ncol(availability)),names(availability))))
  add_dict("caveats.csv",caveats,as.list(setNames(rep("",ncol(caveats)),names(caveats))))
  add_dict("module_status.csv",modules,as.list(setNames(rep("",ncol(modules)),names(modules))))
  add_dict("scales.csv",scales,as.list(setNames(rep("",ncol(scales)),names(scales))))
  add_dict("thresholds.csv",thresholds,as.list(setNames(rep("",ncol(thresholds)),names(thresholds))))
  add_dict("samples.csv",samples,as.list(setNames(rep("",ncol(samples)),names(samples))))
  data_dictionary <- do.call(rbind,dict_rows)

  # write CSVs first
  files <- list(countries=countries,observations=observations,comparisons=comparisons,indicators=indicators,
                panels=panels,panel_members=pm,availability=availability,caveats=caveats,
                module_status=modules,scales=scales,thresholds=thresholds,samples=samples,data_dictionary=data_dictionary)
  for(nm in names(files)) write.csv(files[[nm]],file.path(dashboard_dir,paste0(nm,".csv")),row.names=FALSE,fileEncoding="UTF-8",na="")

  # deterministic JSON mirrors
  if(RUN_DASHBOARD_JSON) {
    sortmap <- list(countries=c("country_id"),observations=c("survey","domain","country_id","indicator_id","group_dimension","group_id","year"),
      comparisons=c("panel_id","indicator_id","group_dimension","group_id","year","country_id"),indicators=c("indicator_id"),
      panels=c("panel_id"),panel_members=c("panel_id","country_id"),availability=c("country_id","domain","indicator_id","year"),
      caveats=c("id"),module_status=c("module_id"),scales=c("scale_id"),thresholds=c("threshold_id"),samples=c("sample_id"),data_dictionary=c("file","field"))
    for(nm in names(files)) write_deterministic_json(files[[nm]],file.path(dashboard_dir,paste0(nm,".json")),sortmap[[nm]])
  }

  checks <- validate_dashboard_bundle(countries,observations,comparisons,indicators,panels,pm,availability)
  write.csv(checks,file.path(dashboard_dir,"validation_checks.csv"),row.names=FALSE)
  report <- c(
    "# Dashboard validation report","",paste("Release:",DASHBOARD_RELEASE_ID),paste("Created:",Sys.time()),"",
    paste("Checks passed:",sum(checks$pass),"/",nrow(checks)),"",
    apply(checks,1,function(r)paste0("- ",ifelse(r[["pass"]],"PASS","FAIL")," — ",r[["check_id"]],": ",r[["details"]])),
    "","A completed script is not itself substantive validation. Any failed error-level check blocks release."
  )
  writeLines(report,file.path(dashboard_dir,"validation_report.md"))
  if(STRICT_VALIDATION && any(!checks$pass & checks$severity=="error")) stop("Dashboard validation failed. See validation_report.md")

  unavailable <- modules[modules$status %in% c("not_validated","not_available","pending_pipeline_run"),]
  write.csv(unavailable,file.path(dashboard_dir,"not_yet_produced.csv"),row.names=FALSE)
  writeLines(c("# Nog niet geproduceerde / niet gevalideerde onderdelen","",
    apply(unavailable,1,function(r)paste0("- **",r[["module_id"]],"** — `",r[["status"]],"`: ",r[["reason"]]))),
    file.path(dashboard_dir,"not_yet_produced.md"))

  readme <- c(
    "# PISA/PIRLS dashboard data bundle","",
    paste("Release:",DASHBOARD_RELEASE_ID),
    "Default frontend country: iso3:NLD. Netherlands is not treated specially in the data model.","",
    "## Principles",
    "- observations.csv contains only results that are not marked not_validated.",
    "- longitudinal ranks exist only for countries eligible for the named fixed panel.",
    "- country terciles are re-formed each wave inside the same fixed panel.",
    "- panel means are unweighted across education systems; benchmark_includes_selected_country states whether the selected country contributes.",
    "- PISA, PIRLS and future TIMSS scales are never mixed.",
    "- P90-P10 is general performance dispersion, not a social-background gap.",
    "- rank confidence intervals remain blank unless a defensible rank-uncertainty procedure is implemented.",
    "- frontend text should use structural fields/codes; no Netherlands-specific conclusions are generated in R.","",
    "## Files",
    "countries, observations, comparisons, indicators, panels, panel_members, availability, caveats, module_status, scales, thresholds, samples, data_dictionary, validation_checks, manifest.","",
    "JSON files mirror the CSV content deterministically."
  )
  writeLines(readme,file.path(dashboard_dir,"README.md"))

  # Five example rows per dashboard table, stored in one human-readable file.
  ex <- c("# Five example rows per dashboard file","")
  for(nm in c("countries","observations","comparisons","indicators","panels","panel_members","availability","caveats","module_status","scales","thresholds","samples","data_dictionary")) {
    df <- files[[nm]]; ex <- c(ex,paste0("## ",nm,".csv"),capture.output(utils::write.table(utils::head(df,5),sep=" | ",row.names=FALSE,quote=FALSE)),"")
  }
  writeLines(ex,file.path(dashboard_dir,"example_rows.md"))

  # Manifest with checksum after all other files have been written.
  ff <- list.files(dashboard_dir,full.names=TRUE,recursive=FALSE)
  ff <- ff[basename(ff)!="manifest.csv"]
  mani <- data.frame(file=basename(ff),bytes=file.info(ff)$size,checksum=vapply(ff,file_sha256,character(1)),
                     checksum_algorithm=if(requireNamespace("openssl",quietly=TRUE))"sha256" else "md5_fallback",
                     stringsAsFactors=FALSE)
  write.csv(mani,file.path(dashboard_dir,"manifest.csv"),row.names=FALSE)
  if(RUN_DASHBOARD_JSON) write_deterministic_json(mani,file.path(dashboard_dir,"manifest.json"),c("file"))

  list(countries=countries,observations=observations,comparisons=comparisons,indicators=indicators,
       panels=panels,panel_members=pm,availability=availability,validation=checks,module_status=modules,scales=scales,thresholds=thresholds,samples=samples)
}




V2_INDICATORS <- data.frame(
  indicator_id=c("mean_score","proficiency_baseline","proficiency_high","proficiency_advanced","p10","p50","p90","p90_p10","social_score_gap","social_proficiency_gap","gender_score_difference","gender_proficiency_difference","immigrant_score_difference_raw","immigrant_score_difference_adjusted","top_performer_share","group_share","school_social_inclusion","school_academic_inclusion","mean_score_math","mean_score_science","timss_mean_score"),
  label_nl_short=c("Gemiddelde score","Basisniveau gehaald","Hoog benchmarkniveau","Geavanceerd benchmarkniveau","P10","Mediaan","P90","P90–P10","Sociale scorekloof","Sociale kloof basisniveau","Verschil meisjes–jongens","Verschil basisniveau meisjes–jongens","Migratiekloof, ruw","Migratiekloof, gecorrigeerd","Aandeel toppresteerders","Aandeel in groep","Sociale inclusie scholen","Academische inclusie scholen","Gemiddelde wiskundescore","Gemiddelde natuurwetenschappenscore","TIMSS gemiddelde score"),
  label_en_short=c("Mean score","Baseline proficiency","High benchmark","Advanced benchmark","P10","Median","P90","P90–P10","Social score gap","Social proficiency gap","Girls–boys difference","Girls–boys proficiency difference","Immigrant score gap, raw","Immigrant score gap, adjusted","Top performer share","Group share","School social inclusion","School academic inclusion","Mean mathematics score","Mean science score","TIMSS mean score"),
  label_nl_long=c("Gemiddelde score op de instrumentspecifieke prestatieschaal","Aandeel leerlingen dat het instrumentspecifieke basisniveau haalt","Aandeel leerlingen dat een hoger internationaal benchmarkniveau haalt","Aandeel leerlingen dat het geavanceerde internationale benchmarkniveau haalt","10e percentiel van de prestatiescore","50e percentiel van de prestatiescore","90e percentiel van de prestatiescore","Spreiding tussen het 90e en 10e percentiel","Verschil in gemiddelde score tussen hoge en lage sociale groep","Verschil in basisvaardigheid tussen hoge en lage sociale groep","Verschil in gemiddelde score tussen meisjes en jongens","Verschil in aandeel op basisniveau tussen meisjes en jongens","Ruw prestatieverschil naar migratieachtergrond","Statistisch gecorrigeerd prestatieverschil naar migratieachtergrond","Aandeel leerlingen op het instrumentspecifieke topniveau","Aandeel leerlingen in een expliciet gedefinieerde groep","Index van sociale inclusie binnen scholen","Index van academische inclusie binnen scholen","Gemiddelde PISA-wiskundescore","Gemiddelde PISA-natuurwetenschappenscore","Gemiddelde TIMSS Grade-4 score"),
  label_en_long=c("Mean score on the instrument-specific achievement scale","Share of students reaching the instrument-specific baseline proficiency level","Share of students reaching a higher international benchmark","Share of students reaching the advanced international benchmark","10th percentile of achievement","50th percentile of achievement","90th percentile of achievement","Dispersion between the 90th and 10th percentiles","Mean-score difference between high and low social-background groups","Difference in baseline proficiency between high and low social-background groups","Difference in mean score between girls and boys","Difference in baseline-proficiency share between girls and boys","Raw achievement difference by immigrant background","Statistically adjusted achievement difference by immigrant background","Share of students at the instrument-specific top level","Share of students in an explicitly defined group","Index of social inclusion within schools","Index of academic inclusion within schools","Mean PISA mathematics score","Mean PISA science score","Mean TIMSS Grade-4 score"),
  definition_nl=c("Gewogen gemiddelde toetsscore op de schaal van het betreffende instrument en domein.","Aandeel leerlingen op of boven de vooraf gedefinieerde instrumentspecifieke basisdrempel.","Aandeel leerlingen op of boven het instrumentspecifieke hoge benchmarkniveau.","Aandeel leerlingen op of boven het instrumentspecifieke geavanceerde benchmarkniveau.","Score waaronder ongeveer 10% van de leerlingen valt.","Mediaan van de prestatiescore.","Score waaronder ongeveer 90% van de leerlingen valt.","P90 minus P10; algemene prestatiespreiding en geen sociaal-economische kloof.","Gemiddelde score in de hoge sociale groep minus die in de lage sociale groep.","Aandeel in de hoge sociale groep minus aandeel in de lage sociale groep, in procentpunten.","Meisjes minus jongens in scorepunten; module nog niet gevalideerd.","Meisjes minus jongens in procentpunten; module nog niet gevalideerd.","Beschrijvend scoreverschil naar migratieachtergrond; module nog niet gevalideerd.","Niet-causaal gecorrigeerd verschil; module nog niet gevalideerd.","Toekomstige gevalideerde SES-/genderuitkomst.","Compositiemaat, geen prestatie-uitkomst.","OECD-maat voor de mate waarin ESCS-variatie binnen in plaats van tussen scholen ligt; nog niet gevalideerd.","OECD-maat voor de mate waarin prestatievariatie binnen in plaats van tussen scholen ligt; nog niet gevalideerd.","Toekomstige gevalideerde PISA-module voor wiskunde.","Toekomstige gevalideerde PISA-module voor natuurwetenschappen.","Toekomstige gevalideerde TIMSS Grade-4-module."),
  definition_en=c("Weighted mean achievement score on the scale of the relevant instrument and domain.","Share of students at or above the predefined instrument-specific baseline threshold.","Share of students at or above the instrument-specific high benchmark.","Share of students at or above the instrument-specific advanced benchmark.","Score below which approximately 10% of students fall.","Median achievement score.","Score below which approximately 90% of students fall.","P90 minus P10; overall performance dispersion, not a socio-economic gap.","Mean score in the high social-background group minus that in the low group.","Share in the high social-background group minus the share in the low group, in percentage points.","Girls minus boys in score points; module not yet validated.","Girls minus boys in percentage points; module not yet validated.","Descriptive score difference by immigrant background; module not yet validated.","Non-causal adjusted difference; module not yet validated.","Future validated SES/gender outcome.","Composition measure, not an achievement outcome.","OECD measure of how much ESCS variation lies within rather than between schools; not yet validated.","OECD measure of how much achievement variation lies within rather than between schools; not yet validated.","Future validated PISA mathematics module.","Future validated PISA science module.","Future validated TIMSS Grade-4 module."),
  unit=c("score_points","percent","percent","percent","score_points","score_points","score_points","score_points","score_points","percentage_points","score_points","percentage_points","score_points","score_points","percent","percent","index_points","index_points","score_points","score_points","score_points"),
  rounding=c(0L,1L,1L,1L,0L,0L,0L,0L,0L,1L,0L,1L,0L,0L,1L,1L,1L,1L,0L,0L,0L),
  rank_direction_default=c("descending_highest_is_1","descending_highest_is_1","descending_highest_is_1","descending_highest_is_1","descending_highest_is_1","descending_highest_is_1","descending_highest_is_1","ascending_smallest_is_1","ascending_smallest_is_1","ascending_smallest_is_1","","","","","descending_highest_is_1","","descending_highest_is_1","descending_highest_is_1","descending_highest_is_1","descending_highest_is_1","descending_highest_is_1"),
  default_visual=c("line","line","line","line","line","line","line","line","two_panel","two_panel","dumbbell","dumbbell","dumbbell","dumbbell","line","stacked_or_dot","dotplot","dotplot","line","line","line"),
  caveat_ids=c("C01","C02","C02","C02","","","","C17","C15;C16","C15;C16","","","","","","","","","C01","C01","C01"),
  stringsAsFactors=FALSE
)

V2_GROUPS <- data.frame(
  group_dimension=c("total","national_escs_quartile","national_escs_quartile","national_escs_quartile","international_escs_quartile","international_escs_quartile","international_escs_quartile","international_escs_quartile","pirls_books_at_home","pirls_books_at_home","pirls_books_at_home","pirls_books_at_home","pirls_books_at_home","pirls_books_at_home_quartile_bridge","pirls_books_at_home_quartile_bridge","pirls_books_at_home_quartile_bridge","gender","gender","gender","migration_background","migration_background","migration_background","home_language","home_language","gender_x_national_escs","gender_x_national_escs","gender_x_national_escs","gender_x_national_escs"),
  group_id=c("total","q1","q4","q4_minus_q1","int_q1","int_q2","int_q3","int_q4","books_0_10","books_11_25","books_26_100","books_101_200","books_gt_200","q1","q4","q4_minus_q1","girls","boys","girls_minus_boys","native","first_generation","second_generation","test_language","other_language","q1_girls","q1_boys","q4_girls","q4_boys"),
  label_nl=c("Totaal","Laagste nationale ESCS-kwartiel","Hoogste nationale ESCS-kwartiel","Q4 minus Q1","Laagste internationale ESCS-kwartiel","Internationaal ESCS-kwartiel 2","Internationaal ESCS-kwartiel 3","Hoogste internationale ESCS-kwartiel","0–10 boeken","11–25 boeken","26–100 boeken","101–200 boeken",">200 boeken","Laagste kwartiel boeken-thuis-rang","Hoogste kwartiel boeken-thuis-rang","Q4 minus Q1","Meisjes","Jongens","Meisjes minus jongens","Zonder migratieachtergrond","Eerste generatie","Tweede generatie","Thuistaal = toetstaal","Andere thuistaal","Q1 meisjes","Q1 jongens","Q4 meisjes","Q4 jongens"),
  label_en=c("Total","Lowest national ESCS quarter","Highest national ESCS quarter","Q4 minus Q1","Lowest international ESCS quarter","International ESCS quarter 2","International ESCS quarter 3","Highest international ESCS quarter","0–10 books","11–25 books","26–100 books","101–200 books",">200 books","Lowest books-at-home rank quartile","Highest books-at-home rank quartile","Q4 minus Q1","Girls","Boys","Girls minus boys","Non-immigrant","First generation","Second generation","Home language = test language","Other home language","Q1 girls","Q1 boys","Q4 girls","Q4 boys"),
  definition_nl=c("Alle leerlingen in de relevante steekproef.","Onderste 25% van de nationale ESCS-verdeling binnen land en meetjaar.","Bovenste 25% van de nationale ESCS-verdeling binnen land en meetjaar.","Afgeleid contrast; geen afzonderlijke leerlinggroep.","Internationaal gedefinieerde absolute ESCS-groep; nog niet gevalideerd.","Internationaal gedefinieerde absolute ESCS-groep; nog niet gevalideerd.","Internationaal gedefinieerde absolute ESCS-groep; nog niet gevalideerd.","Internationaal gedefinieerde absolute ESCS-groep; nog niet gevalideerd.","PIRLS studentrapportage van het aantal boeken thuis.","PIRLS studentrapportage van het aantal boeken thuis.","PIRLS studentrapportage van het aantal boeken thuis.","PIRLS studentrapportage van het aantal boeken thuis.","PIRLS studentrapportage van het aantal boeken thuis.","Deterministische ranggebaseerde Q1-brug binnen land/meetjaar; geen van de vijf inhoudelijke boekencategorieën.","Deterministische ranggebaseerde Q4-brug binnen land/meetjaar; geen van de vijf inhoudelijke boekencategorieën.","Afgeleid contrast van de ranggebaseerde brug.","Meisjes volgens de surveycodering.","Jongens volgens de surveycodering.","Afgeleid contrast; geen afzonderlijke leerlinggroep.","Referentiecategorie volgens de betreffende surveydefinitie.","Migratieachtergrond volgens de betreffende surveydefinitie.","Migratieachtergrond volgens de betreffende surveydefinitie.","Leerling spreekt thuis doorgaans de toetstaal.","Leerling spreekt thuis doorgaans een andere taal dan de toetstaal.","Interactie tussen laagste nationale ESCS-kwartiel en meisjes; nog niet gevalideerd.","Interactie tussen laagste nationale ESCS-kwartiel en jongens; nog niet gevalideerd.","Interactie tussen hoogste nationale ESCS-kwartiel en meisjes; nog niet gevalideerd.","Interactie tussen hoogste nationale ESCS-kwartiel en jongens; nog niet gevalideerd."),
  definition_en=c("All students in the relevant sample.","Bottom 25% of the national ESCS distribution within country and wave.","Top 25% of the national ESCS distribution within country and wave.","Derived contrast; not a separate student group.","Internationally defined absolute ESCS group; not yet validated.","Internationally defined absolute ESCS group; not yet validated.","Internationally defined absolute ESCS group; not yet validated.","Internationally defined absolute ESCS group; not yet validated.","PIRLS student-reported number of books at home.","PIRLS student-reported number of books at home.","PIRLS student-reported number of books at home.","PIRLS student-reported number of books at home.","PIRLS student-reported number of books at home.","Deterministic rank-based Q1 bridge within country/wave; not one of the five substantive book categories.","Deterministic rank-based Q4 bridge within country/wave; not one of the five substantive book categories.","Derived contrast from the rank-based bridge.","Girls according to the survey coding.","Boys according to the survey coding.","Derived contrast; not a separate student group.","Reference category under the relevant survey definition.","Immigrant background under the relevant survey definition.","Immigrant background under the relevant survey definition.","Student usually speaks the test language at home.","Student usually speaks a language other than the test language at home.","Interaction of lowest national ESCS quarter and girls; not yet validated.","Interaction of lowest national ESCS quarter and boys; not yet validated.","Interaction of highest national ESCS quarter and girls; not yet validated.","Interaction of highest national ESCS quarter and boys; not yet validated."),
  display_order=c(1L,1L,4L,5L,1L,2L,3L,4L,1L,2L,3L,4L,5L,1L,4L,5L,1L,2L,3L,1L,2L,3L,1L,2L,1L,2L,3L,4L),
  colour_role=c("neutral_total","social_low","social_high","difference","social_low","social_mid_low","social_mid_high","social_high","social_low","social_mid_low","social_mid","social_mid_high","social_high","social_low","social_high","difference","gender_female","gender_male","difference","migration_reference","migration_comparison","migration_comparison","language_reference","language_comparison","interaction_low","interaction_low","interaction_high","interaction_high"),
  stringsAsFactors=FALSE
)

V2_CONTENT_QUESTIONS <- data.frame(
  content_question=c("performance_level","distribution","group_differences_social","group_differences_gender","group_differences_migration_language"),
  label_nl=c("Prestatieniveau","Verdeling","Verschillen naar sociale achtergrond","Verschillen naar geslacht","Verschillen naar migratieachtergrond en thuistaal"),
  label_en=c("Performance level","Distribution","Differences by social background","Differences by gender","Differences by immigrant background and home language"),
  description_nl=c("Gemiddelde prestaties en aandelen die een benchmark halen.","Percentielen en spreiding van prestaties.","Niveaus en verschillen naar gevalideerde maten van sociale achtergrond.","Niveaus en verschillen naar geslacht; nog niet gevalideerd voor publicatie.","Niveaus en verschillen naar migratieachtergrond en thuistaal; nog niet gevalideerd voor publicatie."),
  description_en=c("Mean achievement and shares reaching a benchmark.","Achievement percentiles and dispersion.","Levels and differences by validated social-background measures.","Levels and differences by gender; not yet validated for publication.","Levels and differences by immigrant background and home language; not yet validated for publication."),
  display_order=c(1L,2L,3L,4L,5L),
  stringsAsFactors=FALSE
)

V2_PANELS <- data.frame(
  panel_id=c("PISA_READ_LONG_32","PISA_SES_32","PIRLS_READ_MAIN13","PIRLS_READ_ROBUST16","PIRLS_READ_MAX_AVAILABLE_AUDIT"),
  survey=c("PISA","PISA","PIRLS","PIRLS","PIRLS"),
  age_group=c("age15","age15","grade4_approx10","grade4_approx10","grade4_approx10"),
  domain=c("reading","reading","reading","reading","reading"),
  years=c("2003;2006;2009;2012;2015;2018;2022;2025","2015;2018;2022;2025","2001;2006;2011;2016;2021","2001;2006;2011;2016;2021","2001;2006;2011;2016;2021"),
  panel_size=c(32L,32L,13L,16L,NA_integer_),
  panel_type=c("fixed_longitudinal","fixed_longitudinal","fixed_longitudinal","robustness_fixed_longitudinal","maximum_available_audit"),
  default_display=c(TRUE,TRUE,TRUE,FALSE,FALSE),
  publication_status=c("dashboard_public","dashboard_public","dashboard_public","dashboard_public","research_only"),
  definition_nl=c("Vaste PISA-leespanel voor lange trends.","Vaste PISA-SES-panel voor nationale ESCS-kwartielen.","Hoofdpaneel PIRLS lezen over vijf waves.","Robuustheidspaneel PIRLS lezen.","Maximum-beschikbare PIRLS-auditset per wave."),
  definition_en=c("Fixed PISA reading panel for long-run trends.","Fixed PISA SES panel for national ESCS quarters.","Main PIRLS reading panel across five waves.","PIRLS reading robustness panel.","Maximum-available PIRLS audit set by wave."),
  selection_basis_nl=c("Vaste 32 onderwijssystemen met valide leesdata in alle acht cycli; dezelfde kernset wordt voor de SES-reeks gebruikt.","Dezelfde vaste 32 systemen als PISA_READ_LONG_32 met officiële nationale ESCS-kwartieluitkomsten in 2015–2025.","Strikte vijf-wave-set met vergelijkbare 2021-hoofdtesttiming; vertraagde 2021-systemen zijn uitgesloten.","MAIN-13 plus Engeland, Iran en Israël.","Onderzoeksdiagnostiek met wisselende landensamenstelling; niet gebruiken voor longitudinale rangschikking."),
  selection_basis_en=c("Fixed set of 32 education systems with valid reading data in all eight cycles; the same core set is used for the SES series.","The same fixed 32 systems as PISA_READ_LONG_32 with official national-ESCS-quarter outcomes in 2015–2025.","Strict five-wave set with comparable 2021 main-study timing; delayed-2021 systems are excluded.","MAIN-13 plus England, Iran and Israel.","Research diagnostic with changing country composition; not for longitudinal ranking."),
  stringsAsFactors=FALSE
)

V2_MODULE_STATUS <- data.frame(
  module_id=c("pisa_reading_core","pirls_reading","pisa_gender","pisa_migration_language","pisa_absolute_ses","pisa_school_sorting","pisa_math","pisa_science","timss_grade4_math_science","pirls_parent_ses_robustness"),
  module_present=c(TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE),
  data_extracted=c(TRUE,TRUE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,TRUE),
  methodologically_validated=c(TRUE,TRUE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE),
  dashboard_publishable=c(TRUE,TRUE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE),
  status=c("validated","validated","not_validated","not_validated","not_validated","not_validated","not_validated","not_validated","not_validated","not_validated"),
  reason_nl=c("Officiële OECD-leesreeksen, unieke headerselectie, Nederlandse sanity checks en fixed-32-controles zijn geslaagd.","De vijf-PV JK2-estimator met R1–R5-hoofdtestbestanden is gevalideerd tegen officiële PIRLS-2021-resultaten.","Gestandaardiseerde extractie/berekening en methodologische validatie zijn nog niet afgerond.","Migratieachtergrond en thuistaal moeten gescheiden en gevalideerd worden; de publicatiemodule is nog niet gereed.","Internationale absolute ESCS-groepen zijn inhoudelijk geselecteerd, maar gestandaardiseerde extractie en validatie zijn nog niet afgerond.","Sociale en academische inclusiematen moeten nog volledig worden geëxtraheerd, berekend en gevalideerd.","Domeinspecifiek vast longitudinaal panel en validatie ontbreken nog.","Domeinspecifiek vast longitudinaal panel en validatie ontbreken nog.","Alleen discovery/roadmap; nog geen gevalideerde Grade-4-productiemodule.","Oudervariabelen zijn geaudit, maar sterke selectieve non-respons vereist een nog niet gelockte correctiemethode."),
  reason_en=c("Official OECD reading series, unique header selection, Netherlands sanity checks and fixed-32 checks passed.","The five-PV JK2 estimator using R1–R5 main-study files was validated against official PIRLS 2021 results.","Standardised extraction/computation and methodological validation are not yet complete.","Immigrant background and home language must be separated and validated; the publication module is not ready.","International absolute ESCS groups have been selected conceptually, but standardised extraction and validation are not yet complete.","Social and academic inclusion measures still require complete extraction, computation and validation.","A domain-specific fixed longitudinal panel and validation are still missing.","A domain-specific fixed longitudinal panel and validation are still missing.","Discovery/roadmap only; no validated Grade-4 production module yet.","Parent variables have been audited, but strong selective non-response requires a correction method that has not yet been locked."),
  stringsAsFactors=FALSE
)

V2_SCALES <- data.frame(
  scale_id=c("pisa_reading_scale","pirls_reading_scale","share_scale","percentage_point_scale","index_scale_generic"),
  label_nl=c("PISA-leesschaal","PIRLS-leesschaal","Aandeel","Procentpunten","Survey-specifieke index"),
  label_en=c("PISA reading scale","PIRLS reading scale","Share","Percentage points","Survey-specific index"),
  comparability_scope=c("within_survey_domain_across_valid_waves","within_survey_domain_across_valid_waves","display_unit_only","display_unit_only","not_cross_survey_comparable"),
  definition_nl=c("Prestatieschaal voor PISA lezen; vergelijkbaar binnen geldige PISA-leeswaves onder de vastgelegde trendcaveats.","Prestatieschaal voor PIRLS lezen; niet numeriek combineren met PISA.","Waarden in procenten; inhoudelijke vergelijkbaarheid hangt af van de gekoppelde achievementschaal en drempel.","Verschillen tussen aandelen, uitgedrukt in procentpunten.","Survey-specifieke indexmaat; alleen gebruiken binnen de expliciet gedefinieerde module."),
  definition_en=c("Achievement scale for PISA reading; comparable across valid PISA reading waves subject to the documented trend caveats.","Achievement scale for PIRLS reading; not to be numerically combined with PISA.","Values in percent; substantive comparability depends on the linked achievement scale and threshold.","Differences between shares, expressed in percentage points.","Survey-specific index measure; use only within the explicitly defined module."),
  stringsAsFactors=FALSE
)

V2_THRESHOLDS <- data.frame(
  threshold_id=c("pisa_level2_reading","pisa_level5plus_reading","pirls_intermediate_475","pirls_high_550","pirls_advanced_625"),
  label_nl=c("PISA lezen Level 2","PISA lezen Level 5 of hoger","PIRLS Intermediate 475","PIRLS High 550","PIRLS Advanced 625"),
  label_en=c("PISA reading Level 2","PISA reading Level 5+","PIRLS Intermediate 475","PIRLS High 550","PIRLS Advanced 625"),
  survey=c("PISA","PISA","PIRLS","PIRLS","PIRLS"),
  domain=c("reading","reading","reading","reading","reading"),
  achievement_scale_id=c("pisa_reading_scale","pisa_reading_scale","pirls_reading_scale","pirls_reading_scale","pirls_reading_scale"),
  definition_nl=c("Instrumentspecifieke PISA-drempel voor minimaal Level 2 lezen.","PISA-drempel voor toppresteerders op Level 5 of 6.","PIRLS Intermediate International Benchmark op 475 schaalpunten.","PIRLS High International Benchmark op 550 schaalpunten.","PIRLS Advanced International Benchmark op 625 schaalpunten."),
  definition_en=c("Instrument-specific PISA threshold for at least Level 2 reading.","PISA threshold for top performers at Level 5 or 6.","PIRLS Intermediate International Benchmark at 475 scale points.","PIRLS High International Benchmark at 550 scale points.","PIRLS Advanced International Benchmark at 625 scale points."),
  stringsAsFactors=FALSE
)

V2_SOURCES <- data.frame(
  source_id=c("src_pisa_read_mean","src_pisa_read_low","src_pisa_read_distribution","src_pisa_read_ses","src_pirls_2001_idb","src_pirls_2006_idb","src_pirls_2011_idb","src_pirls_2016_idb","src_pirls_2021_idb"),
  survey=c("PISA","PISA","PISA","PISA","PIRLS","PIRLS","PIRLS","PIRLS","PIRLS"),
  source_table=c("I.B1.2a.37","I.B1.2a.34","I.B1.2a.40","I.B1.2b.29","PIRLS 2001 International Database main-study student files","PIRLS 2006 International Database main-study student files","PIRLS 2011 International Database main-study student files","PIRLS 2016 International Database main-study student files","PIRLS 2021 International Database main-study student files"),
  citation_nl=c("OECD PISA 2025 Results, tabel I.B1.2a.37: gemiddelde leesprestatie 2000–2025.","OECD PISA 2025 Results, tabel I.B1.2a.34: lage en toppresteerders lezen 2000–2025.","OECD PISA 2025 Results, tabel I.B1.2a.40: verdeling van leesscores 2000–2025.","OECD PISA 2025 Results, tabel I.B1.2b.29: leesuitkomsten naar nationale ESCS-kwartielen.","IEA PIRLS 2001 International Database, hoofdonderzoekbestanden.","IEA PIRLS 2006 International Database, hoofdonderzoekbestanden.","IEA PIRLS 2011 International Database, hoofdonderzoekbestanden.","IEA PIRLS 2016 International Database, hoofdonderzoekbestanden.","IEA PIRLS 2021 International Database, hoofdonderzoekbestanden."),
  citation_en=c("OECD PISA 2025 Results, Table I.B1.2a.37: mean reading performance 2000–2025.","OECD PISA 2025 Results, Table I.B1.2a.34: low and top performers in reading 2000–2025.","OECD PISA 2025 Results, Table I.B1.2a.40: distribution of reading scores 2000–2025.","OECD PISA 2025 Results, Table I.B1.2b.29: reading outcomes by national ESCS quarter.","IEA PIRLS 2001 International Database, main-study files.","IEA PIRLS 2006 International Database, main-study files.","IEA PIRLS 2011 International Database, main-study files.","IEA PIRLS 2016 International Database, main-study files.","IEA PIRLS 2021 International Database, main-study files."),
  source_url=c("https://stat.link/mrq53f","https://stat.link/mrq53f","https://stat.link/mrq53f","https://stat.link/k68msa","https://www.iea.nl/data-tools/repository/pirls","https://www.iea.nl/data-tools/repository/pirls","https://www.iea.nl/data-tools/repository/pirls","https://www.iea.nl/data-tools/repository/pirls","https://www.iea.nl/data-tools/repository/pirls"),
  release_date=c("","","","","","","","",""),
  stringsAsFactors=FALSE
)

V2_CAVEATS <- data.frame(
  caveat_id=c("C01","C02","C03","C04","C05","C06","C07","C08","C09","C10","C11","C12","C13","C14","C15","C16","C17","C18","C19","C20","C21","C22","C23"),
  issue_nl=c("PISA en PIRLS gebruiken verschillende prestatieschalen.","PIRLS-benchmarks en PISA Level 2 zijn niet dezelfde latente drempel.","SES-meting kan door de tijd veranderen.","Nationale SES-groepen zijn relatief binnen land en meetjaar.","PIRLS-ouderrespons is substantieel en selectief onvolledig.","PISA ESCS-missingness varieert naar land en meetjaar.","PISA school- en leerlingrespons beïnvloedt steekproefkwaliteit.","Uitsluitingen en populatiedekking variëren.","PIRLS 2021 timing en afnamemodus verschillen tussen systemen.","Plausible values en replicate weights zijn vereist voor eigen schattingen.","PISA-scorelinking voegt linkingonzekerheid toe.","Landenrangen zijn statistisch onzeker.","Gebalanceerde panels kosten landen.","Landentercielen veranderen per wave.","Een kleinere SES-kloof kan door levelling down ontstaan.","Een groepsverschil vereist covariantie voor de juiste onzekerheid.","P90–P10 is geen SES-kloof.","Ontwerp-, modus-, framework- en adaptiviteitswijzigingen kunnen trends beïnvloeden.","Geografie of populatiedefinitie kan veranderen.","PIRLS 2021 A5-bridgebestanden zijn niet de R5-hoofdtestbestanden.","Books-at-home is een proxy voor sociale achtergrond, geen inkomen of zuivere SES.","Historische OECD PISA-releases kunnen overlappende schattingen reviseren.","De huidige pipeline heeft nog geen gevalideerde cross-wave veranderingsvariantie inclusief relevante linking error."),
  issue_en=c("PISA and PIRLS use different achievement scales.","PIRLS benchmarks and PISA Level 2 are not the same latent threshold.","SES measurement can change over time.","National SES groups are relative within country and wave.","PIRLS parent response is substantially and selectively incomplete.","PISA ESCS missingness varies across country and wave.","PISA school and student response affect sampling quality.","Exclusions and population coverage vary.","PIRLS 2021 timing and administration mode differ across systems.","Plausible values and replicate weights are required for own estimates.","PISA score linking adds linking uncertainty.","Country ranks are statistically imprecise.","Balanced panels exclude countries.","Country tercile membership changes by wave.","A smaller SES gap can arise from levelling down.","A group difference requires covariance for correct uncertainty.","P90–P10 is not an SES gap.","Design, mode, framework and adaptive-testing changes can affect trends.","Geography or population definition can change.","PIRLS 2021 A5 bridge files are not the R5 main-study files.","Books at home is a social-background proxy, not income or pure SES.","Historical OECD PISA releases can revise overlapping estimates.","The current pipeline does not yet have validated cross-wave change variance including relevant linking error."),
  treatment_nl=c("Combineer ruwe PISA- en PIRLS-scorepunten nooit op één gemeenschappelijke schaal.","Interpreteer benchmarkpercentages binnen instrument en leeftijd; geen letterlijke gelijkstelling over instrumenten.","Gebruik geharmoniseerde officiële maten waar mogelijk en documenteer gevoeligheidsanalyses.","Label expliciet en behandel internationale absolute ESCS-groepen als afzonderlijke analyse.","Books-at-home is de lange hoofdbrug; ouder-SES pas als robustness na respons-correctieaudit.","Toon non-missing rates en markeer problematische cellen.","Behoud responsinformatie en relevante land-meetjaarwaarschuwingen in kwaliteitsmetadata.","Audit dekking/uitsluitingen en behoud land-meetjaarflags.","Gebruik MAIN-13 voor de primaire trend en afzonderlijke robustness waar timing afwijkt.","Eigen PIRLS-schattingen gebruiken de volledige vijf-PV/JK2-procedure; publiceer geen naïeve SE's.","Houd linkingonzekerheid apart van steekproefonzekerheid en neem haar mee in geldige trendinferentie.","Toon waarde plus rang/N en vermijd schijnprecisie in rangverschillen.","Gebruik vaste panels voor longitudinale rang/terciel en toon cross-sectionele waarden daarbuiten apart.","Vorm tercielen iedere wave opnieuw binnen exact hetzelfde vaste landenpanel.","Toon altijd groepsniveaus naast de kloof.","Geen gap-SE/significantie zonder correct berekende covariantie.","Behandel P90–P10 als algemene prestatiespreiding.","Annotateer relevante breuken en vermijd causale attributie zonder identificatie.","Beoordeel land-meetjaarcombinaties voordat zij in een vast panel komen.","Lock R1/R2/R3/R4/R5 per wave en faal hard op A5 voor de hoofdschatting.","Label transparant en toon naast de rangbrug ook de vijf inhoudelijke categorieën.","Audit overlapjaren vóór het aan elkaar zetten van reeksen uit verschillende releases.","Laat change-SE, BI en significantie leeg totdat de methode is gevalideerd."),
  treatment_en=c("Never combine raw PISA and PIRLS score points on a single common scale.","Interpret benchmark percentages within instrument and age; no literal equality across instruments.","Use harmonised official measures where possible and document sensitivity analyses.","Label explicitly and treat international absolute ESCS groups as a separate analysis.","Books at home is the long-run main bridge; parent SES only as robustness after response-correction audit.","Show non-missing rates and flag problematic cells.","Retain response information and relevant country-wave warnings in quality metadata.","Audit coverage/exclusions and retain country-wave flags.","Use MAIN-13 for the primary trend and separate robustness where timing differs.","Own PIRLS estimates use the full five-PV/JK2 procedure; do not publish naive SEs.","Keep linking uncertainty separate from sampling uncertainty and include it in valid trend inference.","Show value plus rank/N and avoid false precision in rank differences.","Use fixed panels for longitudinal rank/tercile and show cross-sectional values outside them separately.","Re-form terciles each wave within exactly the same fixed country panel.","Always show group levels alongside the gap.","No gap SE/significance without correctly calculated covariance.","Treat P90–P10 as overall achievement dispersion.","Annotate relevant breaks and avoid causal attribution without identification.","Adjudicate country-wave combinations before fixed-panel inclusion.","Lock R1/R2/R3/R4/R5 by wave and fail hard on A5 for the main estimate.","Label transparently and show the five substantive categories alongside the rank bridge.","Audit overlapping years before splicing series from different releases.","Keep change SE, CI and significance blank until the method is validated."),
  stringsAsFactors=FALSE
)


V2_CAVEATS <- rbind(V2_CAVEATS,data.frame(
  caveat_id="C24",
  issue_nl="PIRLS-bestanden bevatten ook benchmarking entities en aanvullende leerjaar-/taalsteekproeven.",
  issue_en="PIRLS files also contain benchmarking entities and supplementary grade/language samples.",
  treatment_nl="Map benchmarking entities als afzonderlijke systems; sluit expliciete aanvullende grade/language samples en bekende niet-doelpopulaties uit van grade4_approx10-dashboarduitkomsten.",
  treatment_en="Map benchmarking entities as separate systems; exclude explicit supplementary grade/language samples and known non-target populations from grade4_approx10 dashboard outcomes.",
  stringsAsFactors=FALSE
))


V2_METHODS <- data.frame(
  method_id=c("oecd_official_table_level","derived_p90_minus_p10","derived_q4_minus_q1","pirls_5pv_jk2","difference_of_level_estimates_no_validated_trend_se","fixed_panel_descriptive_comparison"),
  label_nl=c("Officiële OECD-tabelwaarde","P90 minus P10","Q4 minus Q1","PIRLS vijf-PV JK2","Verschil tussen niveaus zonder gevalideerde trend-SE","Descriptieve vaste-panelvergelijking"),
  label_en=c("Official OECD table level","P90 minus P10","Q4 minus Q1","PIRLS five-PV JK2","Difference of levels without validated trend SE","Descriptive fixed-panel comparison"),
  definition_nl=c("Directe puntenschatting uit een gecontroleerd geëxtraheerde officiële OECD-tabelkolom.","Deterministisch verschil tussen P90 en P10 binnen dezelfde land-meetjaarcel.","Deterministisch puntverschil tussen Q4 en Q1; inferentiële onzekerheid vereist covariantie.","PIRLS-schatting met vijf plausible values en de volledige JK2-replicate-weightprocedure.","Eindniveau minus beginniveau; veranderings-SE/significantie bewust niet ingevuld.","Rang, waardetertiel en ongewogen panelgemiddelde binnen een vooraf vastgelegd landenpanel."),
  definition_en=c("Direct point estimate from a controlled extraction of an official OECD table column.","Deterministic difference between P90 and P10 within the same country-wave cell.","Deterministic point difference between Q4 and Q1; inferential uncertainty requires covariance.","PIRLS estimate using five plausible values and the full JK2 replicate-weight procedure.","End level minus start level; change SE/significance intentionally not populated.","Rank, raw-value tercile and unweighted panel mean within a pre-specified country panel."),
  stringsAsFactors=FALSE
)

V2_BENCHMARKS <- data.frame(
  benchmark_id=c("panel_unweighted_mean"),
  label_nl=c("Ongewogen gemiddelde vast panel"),
  label_en=c("Unweighted fixed-panel mean"),
  definition_nl=c("Rekenkundig gemiddelde van de puntenschattingen van alle leden van het vaste panel in hetzelfde meetjaar/indicator/groep."),
  definition_en=c("Arithmetic mean of the point estimates for all fixed-panel members in the same wave/indicator/group."),
  stringsAsFactors=FALSE
)

V2_STATUS_DEFINITIONS <- data.frame(
  status_family=c("quality_status","quality_status","quality_status","quality_status","quality_status","module_status","module_status","availability_status","availability_status"),
  status_value=c("official_source_extracted","validated_against_official_source","validated_computed_estimate","not_validated","suppressed_quality_issue","validated","not_validated","available","not_validated"),
  label_nl=c("Officiële bron geëxtraheerd","Gevalideerd tegen officiële bron","Gevalideerde berekende schatting","Niet gevalideerd","Onderdrukt wegens kwaliteitsprobleem","Gevalideerd","Niet gevalideerd","Beschikbaar","Niet gevalideerd"),
  label_en=c("Official source extracted","Validated against official source","Validated computed estimate","Not validated","Suppressed for quality issue","Validated","Not validated","Available","Not validated"),
  definition_nl=c("Directe officiële schatting succesvol geëxtraheerd; geen claim van onafhankelijke celvalidatie.","Deze schatting of reeks is daadwerkelijk tegen een officiële gepubliceerde waarde/tabel gecontroleerd.","Berekend met een gevalideerde methode uit geïdentificeerde inputs; niet iedere inputcel hoeft onafhankelijk te zijn geverifieerd.","Nog niet methodologisch vrijgegeven voor dashboardpublicatie.","Niet gepubliceerd omdat een bekend kwaliteitsprobleem de publicatie blokkeert.","Module is methodologisch gevalideerd; publiceerbaarheid wordt daarnaast door dashboard_publishable vastgelegd.","Module bestaat maar is nog niet methodologisch vrijgegeven.","Deze land/jaar/indicator/groepcombinatie mag als dashboardkeuze worden aangeboden.","Combinatie behoort tot een nog niet gevalideerde module en mag niet als dashboardkeuze verschijnen."),
  definition_en=c("Direct official estimate successfully extracted; no claim of independent cell-by-cell validation.","This estimate or series was actually checked against an official published value/table.","Computed with a validated method from identified inputs; not every input cell need have been independently verified.","Not yet methodologically cleared for dashboard publication.","Not published because a known quality issue blocks publication.","Module is methodologically validated; dashboard_publishable separately records publication suitability.","Module exists but is not yet methodologically cleared.","This country/year/indicator/group combination may be offered as a dashboard choice.","Combination belongs to a module that is not yet validated and must not appear as a dashboard choice."),
  stringsAsFactors=FALSE
)


# =============================================================================
# 17A. V1.3 FAST CHECKPOINT + DASHBOARD SCHEMA V2.1
# =============================================================================

RUN_MODE <- "fast"  # "fast" reuses validated master; "release" rebuilds science.
FAST_REUSE_VALIDATED_MASTER <- TRUE
FORCE_SCIENTIFIC_REBUILD <- FALSE
RUN_SCHEMA_V2_EXPORT <- TRUE
DASHBOARD_V2_PIRLS_SCOPE <- "all_available"  # "all_available" or "fixed_panels"
DASHBOARD_V2_WRITE_JSON <- FALSE
DASHBOARD_V2_RELEASE_ID <- paste0("review_v1_3_",format(Sys.Date(),"%Y%m%d"))
PIRLS_ALL_AVAILABLE_CACHE_VERSION <- "pirls_5pv_jk2_v1_20260919"
dashboard_v2_dir <- file.path(root,"11_dashboard_bundle_v2")
dir.create(dashboard_v2_dir,recursive=TRUE,showWarnings=FALSE)

V13_TIMINGS <- data.frame(stage=character(),seconds=numeric(),status=character(),
                          stringsAsFactors=FALSE)
v13_tic <- function() proc.time()[["elapsed"]]
v13_toc <- function(stage,t0,status="done") {
  sec <- proc.time()[["elapsed"]]-t0
  V13_TIMINGS <<- rbind(V13_TIMINGS,
    data.frame(stage=stage,seconds=sec,status=status,stringsAsFactors=FALSE))
  log_msg("TIMING ",stage,": ",sprintf("%.2f",sec)," s [",status,"]")
  invisible(sec)
}

v2_stable_country_id <- function(x) {
  x <- as.character(x)

  # All legacy education-system IDs become system:* in schema v2.1.
  x <- sub("^edu:","system:",x)

  # Hong Kong and Macao are represented as education systems in the dashboard
  # even though ISO alpha-3 codes exist for the territories.
  map <- c(
    "iso3:HKG"="system:HKG",
    "iso3:MAC"="system:MAC"
  )
  hit <- x %in% names(map)
  x[hit] <- unname(map[x[hit]])
  x
}

v2_checkpoint_valid <- function(m) {
  tryCatch({
    stopifnot(is.list(m))
    stopifnot(is.data.frame(m$pisa_core$long),nrow(m$pisa_core$long)>0)
    stopifnot(is.data.frame(m$pisa_core$ses),nrow(m$pisa_core$ses)>0)
    stopifnot(is.data.frame(m$pisa_sanity),all(m$pisa_sanity$pass))
    stopifnot(is.data.frame(m$pisa_internal_consistency),
              all(m$pisa_internal_consistency$pass))
    stopifnot(length(unique(m$pisa_fixed32$long$country))==32L)
    stopifnot(length(unique(m$pisa_fixed32$ses$country))==32L)
    stopifnot(is.data.frame(m$pirls_validation_check),
              all(m$pirls_validation_check$pass))
    stopifnot(!is.null(m$pirls_main13$estimates),!is.null(m$pirls_robust16$estimates))
    TRUE
  },error=function(e) FALSE)
}

v2_pirls_cache_fingerprint <- function(path) {
  fi <- file.info(path)
  list(
    path=normalizePath(path,winslash="/",mustWork=TRUE),
    bytes=as.numeric(fi$size),
    mtime=as.numeric(fi$mtime),
    estimator_version=PIRLS_ALL_AVAILABLE_CACHE_VERSION
  )
}

v2_same_fingerprint <- function(a,b) {
  is.list(a)&&is.list(b)&&
    identical(a$path,b$path)&&
    identical(a$bytes,b$bytes)&&
    identical(a$mtime,b$mtime)&&
    identical(a$estimator_version,b$estimator_version)
}


v2_preflight_pirls_source_codes <- function(asg_manifest) {
  codes <- sort(unique(toupper(trimws(as.character(asg_manifest$country_code3)))))
  resolved <- lapply(codes,function(cc) {
    hit <- DASH_COUNTRIES[
      toupper(trimws(as.character(DASH_COUNTRIES$source_country_code)))==cc,
      ,drop=FALSE
    ]
    ids <- unique(v2_stable_country_id(hit$country_id))
    ids <- ids[!is.na(ids)&nzchar(ids)]
    data.frame(
      source_country_code=cc,
      country_id=if(length(ids)==1L)ids else NA_character_,
      mapping_count=length(ids),
      source_name=if(nrow(hit))as.character(hit$country_name_en[1])else"",
      stringsAsFactors=FALSE
    )
  })
  z <- do.call(rbind,resolved)
  z$mapping_status <- ifelse(
    z$mapping_count==1L & !is.na(z$country_id),
    "mapped_unique",
    ifelse(z$mapping_count==0L,"unmapped","mapping_not_unique")
  )
  special_status <- PIRLS_SPECIAL_SOURCE_MAP$dashboard_target_status[
    match(z$source_country_code,PIRLS_SPECIAL_SOURCE_MAP$source_country_code)
  ]
  z$special_target_status <- ifelse(is.na(special_status),"standard_or_benchmark",special_status)

  write.csv(z,file.path(dirs$pirls_audit,"PIRLS_source_code_preflight.csv"),
            row.names=FALSE,fileEncoding="UTF-8",na="")
  write.csv(PIRLS_SPECIAL_SOURCE_MAP,
            file.path(dirs$pirls_audit,"PIRLS_special_source_code_registry.csv"),
            row.names=FALSE,fileEncoding="UTF-8",na="")

  bad <- z$mapping_status!="mapped_unique"
  if(any(bad)) {
    write.csv(z[bad,,drop=FALSE],
      file.path(dirs$pirls_audit,"PIRLS_unmapped_or_ambiguous_source_codes.csv"),
      row.names=FALSE,fileEncoding="UTF-8",na="")
    stop("PIRLS source-code preflight found ",sum(bad),
         " genuinely unmapped or non-unique code(s): ",
         paste(z$source_country_code[bad],collapse=", "),
         ". Full list written to ",
         file.path(dirs$pirls_audit,"PIRLS_unmapped_or_ambiguous_source_codes.csv"))
  }
  log_msg("PIRLS source-code preflight: ",nrow(z),
          " unique source code(s), all mapped exactly once.")
  z
}

v2_filter_pirls_dashboard_manifest <- function(asg_manifest) {
  z <- asg_manifest
  z$source_country_code <- toupper(trimws(as.character(z$country_code3)))
  z$exclude_dashboard <- FALSE
  z$exclusion_reason <- ""

  mi <- match(z$source_country_code,PIRLS_SPECIAL_SOURCE_MAP$source_country_code)
  special_exclude <- !is.na(mi) &
    PIRLS_SPECIAL_SOURCE_MAP$dashboard_target_status[mi]=="exclude"
  z$exclude_dashboard[special_exclude] <- TRUE
  z$exclusion_reason[special_exclude] <-
    PIRLS_SPECIAL_SOURCE_MAP$mapping_note_en[mi[special_exclude]]

  for(i in seq_len(nrow(PIRLS_YEAR_SOURCE_EXCLUSIONS))) {
    hit <- as.integer(z$year)==PIRLS_YEAR_SOURCE_EXCLUSIONS$year[i] &
      z$source_country_code==PIRLS_YEAR_SOURCE_EXCLUSIONS$source_country_code[i]
    z$exclude_dashboard[hit] <- TRUE
    z$exclusion_reason[hit] <- PIRLS_YEAR_SOURCE_EXCLUSIONS$exclusion_reason[i]
  }

  audit <- z[,c("year","source_country_code","local_path",
                "exclude_dashboard","exclusion_reason"),drop=FALSE]
  write.csv(audit,
    file.path(dirs$pirls_audit,"PIRLS_dashboard_target_population_audit.csv"),
    row.names=FALSE,fileEncoding="UTF-8",na="")
  excluded <- audit[audit$exclude_dashboard,,drop=FALSE]
  if(nrow(excluded))
    write.csv(excluded,
      file.path(dirs$pirls_audit,"PIRLS_dashboard_excluded_source_files.csv"),
      row.names=FALSE,fileEncoding="UTF-8",na="")

  keep <- z[!z$exclude_dashboard,,drop=FALSE]
  log_msg("PIRLS dashboard population filter: kept ",nrow(keep),
          " country-wave file(s); excluded ",sum(z$exclude_dashboard),
          " supplementary/non-target file(s).")
  keep
}

v2_run_pirls_all_available_cached <- function(asg_manifest) {
  preflight <- v2_preflight_pirls_source_codes(asg_manifest)
  asg_manifest <- v2_filter_pirls_dashboard_manifest(asg_manifest)
  cache_dir <- file.path(dirs$pirls_results,"all_available_cell_cache_v1")
  dir.create(cache_dir,recursive=TRUE,showWarnings=FALSE)
  est <- list(); dg <- list(); ei <- di <- 1L
  reused <- rebuilt <- 0L

  key <- paste(asg_manifest$year,asg_manifest$country_code3,sep="|")
  if(anyDuplicated(key))
    stop("PIRLS ASG manifest has duplicate country-wave cells; refuse all-available export.")

  for(i in seq_len(nrow(asg_manifest))) {
    yr <- as.integer(asg_manifest$year[i]); cc <- as.character(asg_manifest$country_code3[i])
    cid <- v2_stable_country_id(country_id_from_code(cc))
    if(is.na(cid)||!nzchar(cid)) stop("Unmapped PIRLS source code: ",cc)
    src <- asg_manifest$local_path[i]
    fp <- v2_pirls_cache_fingerprint(src)
    cf <- file.path(cache_dir,paste0("PIRLS_",yr,"_",gsub("[^A-Za-z0-9]","_",cc),".rds"))
    z <- NULL

    if(file.exists(cf)) {
      q <- try(readRDS(cf),silent=TRUE)
      if(!inherits(q,"try-error")&&v2_same_fingerprint(q$fingerprint,fp)&&
         !is.null(q$result$estimates)&&!is.null(q$result$diagnostics)) {
        z <- q$result; reused <- reused+1L
      }
    }

    if(is.null(z)) {
      log_msg("PIRLS all-available compute: ",yr," ",cc)
      d <- haven::read_sav(src)
      zz <- try(pirls_pv_jk2_estimate(d,cc,yr),silent=TRUE)
      if(inherits(zz,"try-error")) {
        dg[[di]] <- data.frame(year=yr,country_code3=cc,country_id=cid,
          status="not_validated",reason=as.character(zz),stringsAsFactors=FALSE)
        di <- di+1L
        next
      }
      z <- zz
      saveRDS(list(fingerprint=fp,result=z),cf,compress="gzip")
      rebuilt <- rebuilt+1L
    }

    z$estimates$country_id <- cid
    z$diagnostics$country_id <- cid
    est[[ei]] <- z$estimates; ei <- ei+1L
    dg[[di]] <- cbind(z$diagnostics,status="validated",reason=""); di <- di+1L
  }

  log_msg("PIRLS all-available cell cache: reused ",reused,", rebuilt ",rebuilt)
  out <- list(
    estimates=if(length(est))do.call(rbind,est)else data.frame(),
    diagnostics=if(length(dg))do.call(rbind,dg)else data.frame(),
    cache_reused=reused,cache_rebuilt=rebuilt
  )
  saveRDS(out,file.path(dirs$pirls_results,"PIRLS_all_available_v2.rds"),
          compress="gzip")
  out
}

v2_source_id <- function(survey,source_table,year) {
  if(survey=="PIRLS") return(paste0("src_pirls_",as.integer(year),"_idb"))
  if(source_table=="I.B1.2a.37") return("src_pisa_read_mean")
  if(source_table=="I.B1.2a.34") return("src_pisa_read_low")
  if(source_table=="I.B1.2a.40") return("src_pisa_read_distribution")
  if(source_table=="I.B1.2b.29") return("src_pisa_read_ses")
  NA_character_
}

v2_value_scale <- function(unit,survey) {
  if(unit=="percent") return("share_scale")
  if(unit=="percentage_points") return("percentage_point_scale")
  if(unit=="index_points") return("index_scale_generic")
  if(survey=="PISA") "pisa_reading_scale" else "pirls_reading_scale"
}

v2_achievement_scale <- function(survey,domain) {
  if(domain!="reading") return(NA_character_)
  if(survey=="PISA") "pisa_reading_scale" else "pirls_reading_scale"
}

v2_transform_old_obs <- function(x) {
  if(!nrow(x)) return(data.frame())
  x <- x[is.finite(x$estimate),,drop=FALSE]
  x$country_id <- v2_stable_country_id(x$country_id)

  # Normalise PIRLS group dimensions without conflating substantive categories
  # and the deterministic rank-based Q1/Q4 bridge.
  x$group_dimension[x$group_dimension=="books_at_home_category"] <- "pirls_books_at_home"
  x$group_dimension[x$group_dimension=="books_at_home_quartile_bridge"] <-
    "pirls_books_at_home_quartile_bridge"

  derived <- x$indicator_id %in% c("p90_p10","social_score_gap","social_proficiency_gap")
  method <- ifelse(x$survey=="PIRLS","pirls_5pv_jk2",
            ifelse(x$indicator_id=="p90_p10","derived_p90_minus_p10",
            ifelse(x$indicator_id %in% c("social_score_gap","social_proficiency_gap"),
                   "derived_q4_minus_q1","oecd_official_table_level")))

  nl_checked <- x$survey=="PISA" & x$country_id=="iso3:NLD" & (
    (x$indicator_id=="mean_score" & x$year %in% c(2003,2025)) |
    (x$indicator_id=="proficiency_baseline" & x$group_dimension=="total" &
       x$group_id=="total" & x$year %in% c(2003,2025)) |
    (x$indicator_id=="proficiency_baseline" &
       x$group_dimension=="national_escs_quartile" &
       x$group_id %in% c("q1","q4") & x$year %in% c(2015,2025))
  )

  quality <- ifelse(x$survey=="PIRLS","validated_computed_estimate",
             ifelse(derived,"validated_computed_estimate",
             ifelse(nl_checked,"validated_against_official_source",
                    "official_source_extracted")))

  data.frame(
    release_id=DASHBOARD_V2_RELEASE_ID,
    survey=x$survey,
    source_id=mapply(v2_source_id,x$survey,x$source_table,x$year,USE.NAMES=FALSE),
    age_group=x$age_group,
    domain=x$domain,
    year=as.integer(x$year),
    country_id=x$country_id,
    indicator_id=x$indicator_id,
    group_dimension=x$group_dimension,
    group_id=x$group_id,
    estimate_type="unadjusted",
    method_id=method,
    estimate=as.numeric(x$estimate),
    unit=x$unit,
    se=as.numeric(x$se),
    ci_low=as.numeric(x$ci_low),
    ci_high=as.numeric(x$ci_high),
    value_scale_id=mapply(v2_value_scale,x$unit,x$survey,USE.NAMES=FALSE),
    achievement_scale_id=mapply(v2_achievement_scale,x$survey,x$domain,USE.NAMES=FALSE),
    threshold_id=x$threshold_id,
    sample_id=paste0(x$survey,"_",as.integer(x$year)),
    quality_status=quality,
    caveat_ids=x$caveat_ids,
    stringsAsFactors=FALSE
  )
}

v2_build_observations <- function(master,asg,oecd,pisa_core) {
  out <- list(); oi <- 1L

  # Validated PISA reading core only.
  po <- pisa_core_to_dashboard(pisa_core,if(!is.null(oecd))oecd$cells else data.frame())
  if(!is.null(oecd)&&nrow(oecd$cells))
    po <- attach_oecd_standard_errors(po,oecd$cells)
  out[[oi]] <- v2_transform_old_obs(po); oi <- oi+1L

  # Validated PIRLS reading only. Cross-sectional all-country values are allowed;
  # longitudinal ranking remains restricted to fixed panels.
  if(DASHBOARD_V2_PIRLS_SCOPE=="all_available") {
    pa <- v2_run_pirls_all_available_cached(asg)
    oldp <- pirls_to_dashboard_observations(pa$estimates,pa$diagnostics)
  } else {
    pe <- unique(rbind(master$pirls_main13$estimates,master$pirls_robust16$estimates))
    pe$country_id <- v2_stable_country_id(country_id_from_code(pe$country_code3))
    pd <- unique(rbind(master$pirls_main13$diagnostics,master$pirls_robust16$diagnostics))
    oldp <- pirls_to_dashboard_observations(pe,pd)
  }
  pirls_v2 <- v2_transform_old_obs(oldp)
  if(nrow(pirls_v2)) {
    pirls_v2$caveat_ids <- vapply(pirls_v2$caveat_ids,function(x) {
      q <- unique(c(strsplit(ifelse(is.na(x),"",x),";",fixed=TRUE)[[1]],"C24"))
      paste(q[nzchar(q)],collapse=";")
    },character(1))
  }
  out[[oi]] <- pirls_v2

  z <- do.call(rbind,out)
  z <- z[is.finite(z$estimate),,drop=FALSE]
  # Dashboard observations are publishable modules only by construction.
  unique(z)
}

v2_panel_members <- function() {
  p <- map_panel_members()
  p$country_id <- v2_stable_country_id(p$country_id)
  unique(p[,c("panel_id","country_id")])
}

v2_countries <- function(ids) {
  d <- DASH_COUNTRIES
  d$stable_id <- v2_stable_country_id(d$country_id)
  d <- d[d$stable_id %in% unique(ids),,drop=FALSE]
  d$country_id <- d$stable_id
  d$iso3[grepl("^system:",d$country_id)] <- ""
  d$geography_type[d$country_id %in% c("system:HKG","system:MAC")] <- "education_system"
  d$geography_type[d$country_id=="system:ENG"] <- "subnational_system"
  d$geography_type[grepl("^system:",d$country_id) &
                     !d$country_id %in% c("system:HKG","system:MAC","system:ENG")] <-
    ifelse(grepl("UKR|DUSHANBE|KRI",d$country_id),
           "partial_or_subnational_system","education_system")
  special_ids <- unique(PIRLS_SPECIAL_SOURCE_MAP$country_id)
  rows <- list(); ri <- 1L
  for(cid in unique(d$country_id)) {
    q <- d[d$country_id==cid,,drop=FALSE]
    if(cid %in% special_ids) {
      sp <- PIRLS_SPECIAL_SOURCE_MAP[PIRLS_SPECIAL_SOURCE_MAP$country_id==cid,,drop=FALSE]
      if(nrow(sp)) {
        q$country_name_nl[1] <- sp$country_name_nl[1]
        q$country_name_en[1] <- sp$country_name_en[1]
        q$geography_type[1] <- sp$geography_type[1]
        if(!grepl("^iso3:",cid)) q$iso3[1] <- ""
      }
    }
    rows[[ri]] <- q[1,c("country_id","country_name_nl","country_name_en","iso3","geography_type"),drop=FALSE]
    ri <- ri+1L
  }
  d <- do.call(rbind,rows); rownames(d)<-NULL
  d[order(d$country_name_en),]
}

v2_country_source_codes <- function(obs,oecd,asg,countries) {
  rows <- list(); ri <- 1L
  ctryname <- setNames(countries$country_name_en,countries$country_id)

  # PISA mappings for observed systems.
  pids <- unique(obs$country_id[obs$survey=="PISA"])
  dd <- DASH_COUNTRIES
  dd$stable_id <- v2_stable_country_id(dd$country_id)
  for(cid in pids) {
    q <- dd[dd$stable_id==cid,,drop=FALSE]
    if(!nrow(q)) stop("No PISA country crosswalk row for ",cid)
    code <- q$source_country_code[1]
    srcname <- q$country_name_en[1]
    if(!is.null(oecd)&&nrow(oecd$cells)&&
       all(c("country_id","source_country_label")%in%names(oecd$cells))) {
      oo <- oecd$cells
      oo$stable_id <- v2_stable_country_id(oo$country_id)
      nm <- unique(oo$source_country_label[oo$stable_id==cid & nzchar(oo$source_country_label)])
      if(length(nm)) srcname <- nm[1]
    }
    if(is.na(code)||!nzchar(code)) code <- srcname
    yy <- obs$year[obs$survey=="PISA"&obs$country_id==cid]
    rows[[ri]] <- data.frame(survey="PISA",source_country_code=code,
      country_id=cid,source_country_name=srcname,
      valid_from=min(yy),valid_to=max(yy),stringsAsFactors=FALSE); ri <- ri+1L
  }

  # PIRLS source codes come directly from the main-file manifest.
  if(!is.null(asg)&&nrow(asg)) {
    for(i in seq_len(nrow(asg))) {
      sc <- toupper(trimws(as.character(asg$country_code3[i])))
      cid <- v2_stable_country_id(country_id_from_code(sc))
      if(is.na(cid)||!cid %in% unique(obs$country_id[obs$survey=="PIRLS"])) next

      spn <- PIRLS_SPECIAL_SOURCE_MAP$country_name_en[
        match(sc,PIRLS_SPECIAL_SOURCE_MAP$source_country_code)
      ]
      srcnm <- if(!is.na(spn)&&nzchar(spn)) spn else
        if(cid %in% names(ctryname)) unname(ctryname[cid]) else cid

      rows[[ri]] <- data.frame(
        survey="PIRLS",
        source_country_code=sc,
        country_id=cid,
        source_country_name=srcnm,
        valid_from=as.integer(asg$year[i]),
        valid_to=as.integer(asg$year[i]),
        stringsAsFactors=FALSE
      )
      ri <- ri+1L
    }
  }
  z <- do.call(rbind,rows)
  # Collapse repeated survey/code/id rows to observed validity envelope.
  key <- paste(z$survey,z$source_country_code,z$country_id,sep="|")
  out <- lapply(split(seq_len(nrow(z)),key),function(ii) {
    r <- z[ii[1],,drop=FALSE]
    r$valid_from <- min(z$valid_from[ii]); r$valid_to <- max(z$valid_to[ii]); r
  })
  z <- do.call(rbind,out); rownames(z)<-NULL
  z[order(z$survey,z$source_country_code),]
}

v2_samples <- function(obs) {
  x <- unique(obs[,c("survey","age_group","year")])
  x <- x[order(x$survey,x$year),]
  data.frame(
    sample_id=paste0(x$survey,"_",x$year),
    survey=x$survey,age_group=x$age_group,year=as.integer(x$year),
    definition_nl=ifelse(x$survey=="PISA",
      "15-jarige leerlingen in de door PISA gedefinieerde doelpopulatie.",
      "Leerlingen in de PIRLS-doelpopulatie van leerjaar 4 / ongeveer 10 jaar; gevalideerde hoofdtestbestanden per wave."),
    definition_en=ifelse(x$survey=="PISA",
      "15-year-old students in the PISA-defined target population.",
      "Students in the PIRLS Grade-4 / approximately age-10 target population; validated main-study files by wave."),
    stringsAsFactors=FALSE
  )
}

v2_indicator_rounding <- function(indicator_id) {
  x <- V2_INDICATORS$rounding[match(indicator_id,V2_INDICATORS$indicator_id)]
  ifelse(is.na(x),0L,as.integer(x))
}

v2_point_relation <- function(value,benchmark,digits) {
  if(!is.finite(value)||!is.finite(benchmark)) return(NA_character_)
  if(round(value,digits)==round(benchmark,digits)) return("equal_within_rounding")
  if(value>benchmark) "above" else "below"
}

v2_make_comparisons <- function(obs,panels,panel_members) {
  panel_metrics <- list(
    PISA_READ_LONG_32=c("mean_score","proficiency_baseline","p10","p50","p90","p90_p10"),
    PISA_SES_32=c("proficiency_baseline","social_proficiency_gap"),
    PIRLS_READ_MAIN13=c("mean_score","proficiency_baseline","proficiency_high",
      "proficiency_advanced","p10","p50","p90","p90_p10",
      "social_score_gap","social_proficiency_gap"),
    PIRLS_READ_ROBUST16=c("mean_score","proficiency_baseline","proficiency_high",
      "proficiency_advanced","p10","p50","p90","p90_p10",
      "social_score_gap","social_proficiency_gap")
  )
  out <- list(); oi <- 1L

  for(pid in names(panel_metrics)) {
    pp <- panels[panels$panel_id==pid,,drop=FALSE]
    memb <- panel_members$country_id[panel_members$panel_id==pid]
    yrs <- as.integer(strsplit(pp$years,";",fixed=TRUE)[[1]])

    for(ind in panel_metrics[[pid]]) for(yr in yrs) {
      sub <- obs[obs$survey==pp$survey & obs$domain==pp$domain &
                   obs$year==yr & obs$indicator_id==ind,,drop=FALSE]
      if(!nrow(sub)) next
      grs <- unique(paste(sub$group_dimension,sub$group_id,sep="|"))

      for(gr in grs) {
        ss <- sub[paste(sub$group_dimension,sub$group_id,sep="|")==gr &
                    is.finite(sub$estimate),,drop=FALSE]
        pm <- ss[ss$country_id %in% memb,,drop=FALSE]
        if(length(unique(pm$country_id))!=length(memb)) {
          miss <- setdiff(memb,pm$country_id)
          stop("Incomplete fixed panel ",pid," / ",ind," / ",yr," / ",gr,
               ". Missing: ",paste(miss,collapse=","))
        }

        rdir <- V2_INDICATORS$rank_direction_default[
          match(ind,V2_INDICATORS$indicator_id)]
        if(is.na(rdir)||!nzchar(rdir))
          stop("No rank_direction_default for fixed-panel indicator ",ind)
        rr <- if(rdir=="ascending_smallest_is_1")
          rank(pm$estimate,ties.method="min") else rank(-pm$estimate,ties.method="min")

        ord <- order(pm$estimate,pm$country_id)
        pos <- (seq_along(ord)-.5)/length(ord)
        tv <- rep(NA_character_,length(ord))
        tv[ord] <- ifelse(pos<=1/3,"low_value",
                   ifelse(pos<=2/3,"middle_value","high_value"))
        bench <- mean(pm$estimate)
        digits <- v2_indicator_rounding(ind)

        # All same-year comparable observed systems receive point comparison.
        for(i in seq_len(nrow(ss))) {
          cid <- ss$country_id[i]; eligible <- cid %in% memb
          k <- match(cid,pm$country_id)
          spl <- strsplit(gr,"|",fixed=TRUE)[[1]]
          out[[oi]] <- data.frame(
            release_id=DASHBOARD_V2_RELEASE_ID,panel_id=pid,country_id=cid,
            year=as.integer(yr),indicator_id=ind,
            group_dimension=spl[1],group_id=spl[2],
            estimate_type=ss$estimate_type[i],
            method_id="fixed_panel_descriptive_comparison",
            rank=if(eligible)as.integer(rr[k])else NA_integer_,
            rank_n=as.integer(length(memb)),
            rank_direction=rdir,
            tercile=if(eligible)tv[k]else NA_character_,
            benchmark_id="panel_unweighted_mean",
            benchmark_value=bench,
            benchmark_includes_selected_country=eligible,
            point_relation=v2_point_relation(ss$estimate[i],bench,digits),
            difference_from_benchmark=ss$estimate[i]-bench,
            difference_se=NA_real_,difference_ci_low=NA_real_,
            difference_ci_high=NA_real_,significant_difference=NA,
            eligible=eligible,
            unavailability_reason=if(eligible)""else"not_panel_member",
            stringsAsFactors=FALSE
          ); oi <- oi+1L
        }
      }
    }
  }
  unique(do.call(rbind,out))
}

v2_make_changes <- function(obs) {
  key <- paste(obs$survey,obs$age_group,obs$domain,obs$country_id,
               obs$indicator_id,obs$group_dimension,obs$group_id,
               obs$estimate_type,sep="|")
  out <- list(); oi <- 1L

  for(k in unique(key)) {
    x <- obs[key==k & is.finite(obs$estimate),,drop=FALSE]
    x <- x[order(x$year),]
    if(nrow(x)<2) next
    for(i in 2:nrow(x)) {
      ch <- x$estimate[i]-x$estimate[i-1]
      dig <- v2_indicator_rounding(x$indicator_id[i])
      dir <- if(round(ch,dig)==0)"no_change_within_rounding"
             else if(ch>0)"increase" else "decrease"
      cav <- unique(c(unlist(strsplit(paste(x$caveat_ids[i-1],x$caveat_ids[i],sep=";"),";",fixed=TRUE)),"C23"))
      cav <- cav[nzchar(cav)]
      out[[oi]] <- data.frame(
        release_id=DASHBOARD_V2_RELEASE_ID,country_id=x$country_id[i],
        survey=x$survey[i],age_group=x$age_group[i],domain=x$domain[i],
        indicator_id=x$indicator_id[i],group_dimension=x$group_dimension[i],
        group_id=x$group_id[i],estimate_type=x$estimate_type[i],
        start_year=as.integer(x$year[i-1]),end_year=as.integer(x$year[i]),
        change=ch,change_unit=if(x$unit[i]=="percent")"percentage_points"else x$unit[i],
        change_se=NA_real_,ci_low=NA_real_,ci_high=NA_real_,
        change_direction=dir,significant_change=NA,
        method_id="difference_of_level_estimates_no_validated_trend_se",
        source_id=x$source_id[i],quality_status="validated_computed_estimate",
        caveat_ids=paste(cav,collapse=";"),stringsAsFactors=FALSE
      ); oi <- oi+1L
    }
  }
  if(length(out))do.call(rbind,out)else data.frame()
}

v2_content_question <- function(ind,gd) {
  if(gd %in% c("national_escs_quartile","pirls_books_at_home",
               "pirls_books_at_home_quartile_bridge","international_escs_quartile",
               "gender_x_national_escs") ||
     ind %in% c("social_score_gap","social_proficiency_gap"))
    return("group_differences_social")
  if(grepl("gender",gd)||grepl("gender",ind)) return("group_differences_gender")
  if(grepl("migration|language",gd)||grepl("immigrant|language",ind))
    return("group_differences_migration_language")
  if(ind %in% c("p10","p50","p90","p90_p10")) return("distribution")
  "performance_level"
}

v2_module_for_obs <- function(survey,domain) {
  if(survey=="PISA"&&domain=="reading") return("pisa_reading_core")
  if(survey=="PIRLS"&&domain=="reading") return("pirls_reading")
  NA_character_
}

v2_make_availability <- function(obs,countries) {
  a <- unique(obs[,c("survey","country_id","age_group","domain","indicator_id",
                     "group_dimension","group_id","year")])
  rows <- list(); ri <- 1L
  for(i in seq_len(nrow(a))) {
    rows[[ri]] <- data.frame(
      survey=a$survey[i],module_id=v2_module_for_obs(a$survey[i],a$domain[i]),
      country_id=a$country_id[i],age_group=a$age_group[i],domain=a$domain[i],
      content_question=v2_content_question(a$indicator_id[i],a$group_dimension[i]),
      indicator_id=a$indicator_id[i],group_dimension=a$group_dimension[i],
      group_id=a$group_id[i],year=as.integer(a$year[i]),
      available=TRUE,status="available",reason_code="",
      reason_nl="",reason_en="",stringsAsFactors=FALSE
    ); ri <- ri+1L
  }

  # Explicit non-publishable PISA modules at the latest wave. These rows are
  # negative availability metadata only; no unvalidated observation is exported.
  pids <- unique(obs$country_id[obs$survey=="PISA"])
  future <- list(
    c("pisa_gender","reading","group_differences_gender","gender_score_difference","gender","girls_minus_boys"),
    c("pisa_migration_language","reading","group_differences_migration_language","immigrant_score_difference_raw","migration_background","first_generation"),
    c("pisa_absolute_ses","reading","group_differences_social","mean_score","international_escs_quartile","int_q1"),
    c("pisa_school_sorting","reading","group_differences_social","school_social_inclusion","total","total"),
    c("pisa_math","mathematics","performance_level","mean_score_math","total","total"),
    c("pisa_science","science","performance_level","mean_score_science","total","total")
  )
  for(cid in pids) for(f in future) {
    rows[[ri]] <- data.frame(
      survey="PISA",module_id=f[1],country_id=cid,age_group="age15",domain=f[2],
      content_question=f[3],indicator_id=f[4],group_dimension=f[5],group_id=f[6],
      year=2025L,available=FALSE,status="not_validated",
      reason_code="module_not_validated",
      reason_nl="Deze module is nog niet methodologisch gevalideerd voor dashboardpublicatie.",
      reason_en="This module has not yet been methodologically validated for dashboard publication.",
      stringsAsFactors=FALSE
    ); ri <- ri+1L
  }
  # Explicit TIMSS Grade-4 nonavailability record for the default country.
  if("iso3:NLD" %in% countries$country_id) {
    rows[[ri]] <- data.frame(
      survey="TIMSS",module_id="timss_grade4_math_science",country_id="iso3:NLD",
      age_group="grade4_approx10",domain="mathematics",
      content_question="performance_level",indicator_id="timss_mean_score",
      group_dimension="total",group_id="total",year=2023L,
      available=FALSE,status="not_validated",reason_code="module_not_validated",
      reason_nl="TIMSS Grade-4 is nog niet als gevalideerde dashboardmodule gebouwd.",
      reason_en="TIMSS Grade 4 has not yet been built as a validated dashboard module.",
      stringsAsFactors=FALSE
    )
  }
  unique(do.call(rbind,rows))
}

v2_country_table_from_used_ids <- function(obs,pm) {
  v2_countries(unique(c(obs$country_id,pm$country_id)))
}

v2_schema_keys <- function() {
  c(
    countries="country_id",
    country_source_codes="survey + source_country_code + valid_from",
    observations="release_id + survey + age_group + domain + year + country_id + indicator_id + group_dimension + group_id + estimate_type + method_id",
    comparisons="release_id + panel_id + country_id + year + indicator_id + group_dimension + group_id + estimate_type + method_id + benchmark_id",
    changes="release_id + country_id + survey + age_group + domain + indicator_id + group_dimension + group_id + estimate_type + method_id + start_year + end_year",
    indicators="indicator_id",
    groups="group_dimension + group_id",
    content_questions="content_question",
    sources="source_id",
    panels="panel_id",
    panel_members="panel_id + country_id",
    availability="survey + module_id + country_id + age_group + domain + content_question + indicator_id + group_dimension + group_id + year",
    module_status="module_id",
    scales="scale_id",
    thresholds="threshold_id",
    samples="sample_id",
    caveats="caveat_id",
    data_dictionary="file + field",
    validation_checks="check_id"
  )
}

v2_semantic_type <- function(field) {
  integer <- c("year","start_year","end_year","rank","rank_n","rounding",
               "display_order","panel_size","valid_from","valid_to")
  number <- c("estimate","se","ci_low","ci_high","benchmark_value",
              "difference_from_benchmark","difference_se","difference_ci_low",
              "difference_ci_high","change","change_se")
  boolean <- c("benchmark_includes_selected_country","significant_difference",
               "eligible","significant_change","default_display","available",
               "module_present","data_extracted","methodologically_validated",
               "dashboard_publishable","pass")
  enum <- c("geography_type","survey","age_group","domain","estimate_type","unit",
            "quality_status","rank_direction","tercile","point_relation",
            "unavailability_reason","change_unit","change_direction","default_visual",
            "content_question","panel_type","publication_status","status",
            "comparability_scope","semantic_type","severity","rank_direction_default")
  if(field %in% integer)"integer" else if(field %in% number)"number"
  else if(field %in% boolean)"boolean" else if(field %in% enum)"enum" else "string"
}

v2_field_description <- function(field,lang=c("nl","en")) {
  lang <- match.arg(lang)
  nl <- c(
    country_id="Stabiele dashboard-ID voor land of onderwijssysteem.",
    source_id="Verwijzing naar sources.csv.",
    year="Meetjaar als integer.",estimate="Puntenschatting.",
    value_scale_id="Schaal waarop de getoonde waarde staat.",
    achievement_scale_id="Onderliggende prestatieschaal waarop benchmark of prestatiemaat is gedefinieerd.",
    quality_status="Extractie-/validatiestatus van deze schatting.",
    method_id="Verwijzing naar de gecontroleerde berekenings-/extractiemethode.",
    point_relation="Puur descriptieve verhouding tussen puntenschattingen; geen significantietoets.",
    significant_difference="Alleen ingevuld wanneer de juiste verschilvariantie is berekend.",
    significant_change="Alleen ingevuld wanneer de juiste veranderingsvariantie is berekend.",
    available="Of deze combinatie als dashboardkeuze aangeboden mag worden.",
    module_id="Stabiele module-ID.",
    survey="Meetprogramma of instrument.",
    group_dimension="Dimensie waarbinnen de groep is gedefinieerd.",
    group_id="Groep of afgeleid contrast binnen group_dimension."
  )
  en <- c(
    country_id="Stable dashboard identifier for a country or education system.",
    source_id="Reference to sources.csv.",year="Assessment year as an integer.",
    estimate="Point estimate.",value_scale_id="Scale on which the displayed value is expressed.",
    achievement_scale_id="Underlying achievement scale on which the benchmark or achievement measure is defined.",
    quality_status="Extraction/validation status of this estimate.",
    method_id="Reference to the controlled computation/extraction method.",
    point_relation="Purely descriptive relation between point estimates; not a significance test.",
    significant_difference="Populated only when the correct difference variance has been calculated.",
    significant_change="Populated only when the correct change variance has been calculated.",
    available="Whether this combination may be offered as a dashboard choice.",
    module_id="Stable module identifier.",survey="Assessment programme or instrument.",
    group_dimension="Dimension within which the group is defined.",
    group_id="Group or derived contrast within group_dimension."
  )
  d <- if(lang=="nl")nl else en
  if(field %in% names(d)) unname(d[[field]]) else
    if(lang=="nl")paste("Veld",field,"in het dashboarddataschema.") else
      paste("Field",field,"in the dashboard data schema.")
}

v2_nullable <- function(file,field) {
  nullable <- list(
    countries=c("iso3"),
    sources=c("release_date"),
    observations=c("se","ci_low","ci_high","threshold_id","caveat_ids"),
    comparisons=c("rank","tercile","point_relation","difference_from_benchmark",
                  "difference_se","difference_ci_low","difference_ci_high",
                  "significant_difference","unavailability_reason"),
    changes=c("change_se","ci_low","ci_high","significant_change","caveat_ids"),
    indicators=c("rank_direction_default","caveat_ids"),
    panels=c("panel_size"),
    availability=c("reason_code","reason_nl","reason_en")
  )
  vals <- nullable[[file]]
  if(is.null(vals)) vals <- character()
  field %in% vals
}

v2_enum_name <- function(file,field) {
  m <- c(
    geography_type="geography_type",survey="survey",age_group="age_group",
    domain="domain",estimate_type="estimate_type",unit="unit",
    quality_status="quality_status",rank_direction="rank_direction",
    rank_direction_default="rank_direction",tercile="tercile",
    point_relation="point_relation",unavailability_reason="unavailability_reason",
    change_unit="unit",change_direction="change_direction",
    default_visual="default_visual",content_question="content_question",
    panel_type="panel_type",publication_status="publication_status",
    comparability_scope="comparability_scope",semantic_type="semantic_type",
    severity="severity"
  )
  if(field=="status") {
    if(file=="module_status") return("module_status")
    if(file=="availability") return("availability_status")
  }
  if(field %in% names(m)) unname(m[[field]]) else ""
}

v2_make_dictionary <- function(files) {
  out <- list(); oi <- 1L
  for(nm in names(files)) {
    for(f in names(files[[nm]])) {
      out[[oi]] <- data.frame(
        file=paste0(nm,".csv"),field=f,semantic_type=v2_semantic_type(f),
        nullable=v2_nullable(nm,f),enum_name=v2_enum_name(nm,f),
        description_nl=v2_field_description(f,"nl"),
        description_en=v2_field_description(f,"en"),stringsAsFactors=FALSE
      ); oi <- oi+1L
    }
  }
  do.call(rbind,out)
}

v2_split_key <- function(expr) trimws(strsplit(expr,"+",fixed=TRUE)[[1]])

v2_validation_check <- function(id,pass,file,details_nl,details_en,severity="error") {
  data.frame(check_id=id,pass=isTRUE(pass),severity=severity,file=file,
    details_nl=details_nl,details_en=details_en,stringsAsFactors=FALSE)
}

v2_validate_bundle <- function(files,methods,benchmarks) {
  ck <- list(); ci <- 1L; keys <- v2_schema_keys()
  for(nm in names(files)) {
    k <- v2_split_key(keys[[nm]])
    d <- files[[nm]]
    kk <- if(nrow(d))do.call(paste,c(d[k],sep="\034"))else character()
    dup <- sum(duplicated(kk))
    ck[[ci]] <- v2_validation_check(paste0("unique_key__",nm),dup==0,
      paste0(nm,".csv"),paste(dup,"dubbele sleutels."),
      paste(dup,"duplicate keys.")); ci<-ci+1L
  }

  obs <- files$observations; cmp <- files$comparisons; ch <- files$changes
  countries <- files$countries; pm <- files$panel_members; panels <- files$panels
  av <- files$availability; mods <- files$module_status

  known <- countries$country_id
  refs <- unique(c(obs$country_id,cmp$country_id,ch$country_id,pm$country_id,av$country_id))
  bad <- setdiff(refs,known)
  ck[[ci]] <- v2_validation_check("country_foreign_keys",!length(bad),
    "multiple",paste("Onbekende country_id's:",paste(bad,collapse=",")),
    paste("Unknown country_id values:",paste(bad,collapse=",")));ci<-ci+1L

  sysbad <- countries$country_id[grepl("^system:",countries$country_id)&nzchar(countries$iso3)]
  ck[[ci]] <- v2_validation_check("system_iso3_blank",!length(sysbad),
    "countries.csv",paste("System-ID's met ISO3:",paste(sysbad,collapse=",")),
    paste("System IDs with ISO3:",paste(sysbad,collapse=",")));ci<-ci+1L

  cs <- files$country_source_codes
  blank_code <- is.na(cs$source_country_code)|!nzchar(cs$source_country_code)
  mapkey <- paste(cs$survey,cs$source_country_code,sep="|")
  mapn <- tapply(cs$country_id,mapkey,function(x)length(unique(x)))
  badmap <- names(mapn)[mapn!=1]
  ck[[ci]] <- v2_validation_check("source_codes_nonblank",!any(blank_code),
    "country_source_codes.csv",paste(sum(blank_code),"lege broncodes."),
    paste(sum(blank_code),"blank source codes."));ci<-ci+1L
  ck[[ci]] <- v2_validation_check("source_code_maps_to_one_country",!length(badmap),
    "country_source_codes.csv",paste("Niet-eenduidige mappings:",paste(badmap,collapse=",")),
    paste("Ambiguous mappings:",paste(badmap,collapse=",")));ci<-ci+1L

  pc <- table(pm$panel_id)
  pfix <- panels[is.finite(panels$panel_size),]
  gotpc <- as.integer(pc[pfix$panel_id])
  okpc <- length(gotpc)==nrow(pfix) && all(!is.na(gotpc)) && all(gotpc==pfix$panel_size)
  ck[[ci]] <- v2_validation_check("fixed_panel_member_counts",okpc,
    "panel_members.csv","Vaste panelgroottes komen overeen met panels.csv.",
    "Fixed panel sizes match panels.csv.");ci<-ci+1L

  srcbad <- setdiff(unique(obs$source_id),files$sources$source_id)
  sampbad <- setdiff(unique(obs$sample_id),files$samples$sample_id)
  thbad <- setdiff(unique(obs$threshold_id[nzchar(obs$threshold_id)]),files$thresholds$threshold_id)
  grkey <- paste(files$groups$group_dimension,files$groups$group_id,sep="|")
  obgr <- unique(paste(obs$group_dimension,obs$group_id,sep="|"))
  grbad <- setdiff(obgr,grkey)
  cavrefs <- unique(unlist(strsplit(paste(c(obs$caveat_ids,ch$caveat_ids),collapse=";"),";",fixed=TRUE)))
  cavrefs <- cavrefs[nzchar(cavrefs)]
  cavbad <- setdiff(cavrefs,files$caveats$caveat_id)
  ck[[ci]] <- v2_validation_check("observation_source_ids_known",!length(srcbad),
    "observations.csv",paste("Onbekende source_id's:",paste(srcbad,collapse=",")),
    paste("Unknown source_id values:",paste(srcbad,collapse=",")));ci<-ci+1L
  ck[[ci]] <- v2_validation_check("observation_sample_ids_known",!length(sampbad),
    "observations.csv",paste("Onbekende sample_id's:",paste(sampbad,collapse=",")),
    paste("Unknown sample_id values:",paste(sampbad,collapse=",")));ci<-ci+1L
  ck[[ci]] <- v2_validation_check("observation_threshold_ids_known",!length(thbad),
    "observations.csv",paste("Onbekende threshold_id's:",paste(thbad,collapse=",")),
    paste("Unknown threshold_id values:",paste(thbad,collapse=",")));ci<-ci+1L
  ck[[ci]] <- v2_validation_check("observation_groups_known",!length(grbad),
    "observations.csv",paste("Onbekende groepen:",paste(grbad,collapse=",")),
    paste("Unknown groups:",paste(grbad,collapse=",")));ci<-ci+1L
  ck[[ci]] <- v2_validation_check("caveat_ids_known",!length(cavbad),
    "multiple",paste("Onbekende caveat_id's:",paste(cavbad,collapse=",")),
    paste("Unknown caveat_id values:",paste(cavbad,collapse=",")));ci<-ci+1L

  pct <- obs$unit=="percent"
  okpct <- all(!pct | (!is.na(obs$estimate)&obs$estimate>=0&obs$estimate<=100))
  ck[[ci]] <- v2_validation_check("percent_range",okpct,"observations.csv",
    "Alle percentages liggen tussen 0 en 100.","All percentages lie between 0 and 100.");ci<-ci+1L

  badscale <- (obs$unit=="percent"&obs$value_scale_id!="share_scale") |
              (obs$unit=="percentage_points"&obs$value_scale_id!="percentage_point_scale") |
              (obs$unit=="score_points"&obs$value_scale_id!=obs$achievement_scale_id)
  ck[[ci]] <- v2_validation_check("value_achievement_scale_logic",!any(badscale),
    "observations.csv",paste(sum(badscale),"inconsistente schaalcombinaties."),
    paste(sum(badscale),"inconsistent scale combinations."));ci<-ci+1L

  badin <- !cmp$eligible & (!is.na(cmp$rank)|!is.na(cmp$tercile))
  ck[[ci]] <- v2_validation_check("outside_panel_no_rank_or_tercile",!any(badin),
    "comparisons.csv",paste(sum(badin),"outside-panelrijen met rang/terciel."),
    paste(sum(badin),"outside-panel rows with rank/tercile."));ci<-ci+1L

  badchg <- is.na(ch$change_se)&!is.na(ch$significant_change)
  ck[[ci]] <- v2_validation_check("change_significance_requires_se",!any(badchg),
    "changes.csv","Geen significantie zonder change_se.","No significance without change_se.");ci<-ci+1L

  badcmp <- is.na(cmp$difference_se)&!is.na(cmp$significant_difference)
  ck[[ci]] <- v2_validation_check("comparison_significance_requires_se",!any(badcmp),
    "comparisons.csv","Geen significantie zonder difference_se.","No significance without difference_se.");ci<-ci+1L

  mm <- setNames(mods$dashboard_publishable,mods$module_id)
  mmv <- mm[av$module_id]
  badav <- av$available & (is.na(mmv)|!mmv)
  unknown_mod <- unique(av$module_id[is.na(mmv)])
  ck[[ci]] <- v2_validation_check("availability_module_ids_known",!length(unknown_mod),
    "availability.csv",paste("Onbekende module_id's:",paste(unknown_mod,collapse=",")),
    paste("Unknown module_id values:",paste(unknown_mod,collapse=",")));ci<-ci+1L
  ck[[ci]] <- v2_validation_check("availability_respects_module_status",!any(badav),
    "availability.csv",paste(sum(badav),"beschikbare rijen uit niet-publiceerbare modules."),
    paste(sum(badav),"available rows from non-publishable modules."));ci<-ci+1L

  methbad <- setdiff(unique(c(obs$method_id,cmp$method_id,ch$method_id)),methods$method_id)
  ck[[ci]] <- v2_validation_check("method_ids_known",!length(methbad),"multiple",
    paste("Onbekende method_id's:",paste(methbad,collapse=",")),
    paste("Unknown method_ids:",paste(methbad,collapse=",")));ci<-ci+1L

  bbad <- setdiff(unique(cmp$benchmark_id),benchmarks$benchmark_id)
  ck[[ci]] <- v2_validation_check("benchmark_ids_known",!length(bbad),"comparisons.csv",
    paste("Onbekende benchmark_id's:",paste(bbad,collapse=",")),
    paste("Unknown benchmark_ids:",paste(bbad,collapse=",")));ci<-ci+1L

  do.call(rbind,ck)
}

v2_write_schema_keys_enums <- function(path) {
  keys <- v2_schema_keys()
  enums <- list(
    quality_status=c("official_source_extracted","validated_against_official_source",
      "validated_computed_estimate","not_validated","suppressed_quality_issue"),
    rank_direction=c("descending_highest_is_1","ascending_smallest_is_1"),
    tercile=c("low_value","middle_value","high_value"),
    point_relation=c("above","below","equal_within_rounding"),
    change_direction=c("increase","decrease","no_change_within_rounding"),
    comparability_scope=c("within_survey_domain_across_valid_waves",
      "display_unit_only","not_cross_survey_comparable"),
    semantic_type=c("string","integer","number","boolean","enum")
  )
  rows <- list(); ri <- 1L
  for(nm in names(keys)) {
    rows[[ri]] <- data.frame(file=paste0(nm,".csv"),unique_key=keys[[nm]],
      field="",allowed_values="",notes_nl="Unieke sleutel van dit bestand.",
      notes_en="Unique key for this file.",stringsAsFactors=FALSE);ri<-ri+1L
  }
  for(en in names(enums)) {
    rows[[ri]] <- data.frame(file="ALL",unique_key="",field=en,
      allowed_values=paste(enums[[en]],collapse=";"),
      notes_nl=paste("Toegestane waarden voor enum",en),
      notes_en=paste("Allowed values for enum",en),stringsAsFactors=FALSE);ri<-ri+1L
  }
  write.csv(do.call(rbind,rows),path,row.names=FALSE,fileEncoding="UTF-8",na="")
}

v2_write_pipeline_gaps <- function(path) {
  z <- data.frame(
    file=c("changes.csv","comparisons.csv","observations.csv",
           "country_source_codes.csv","sources.csv","availability.csv",
           "observations.csv","observations.csv","observations.csv"),
    field_or_concept=c(
      "change_se; ci_low; ci_high; significant_change",
      "difference_se; difference_ci_low; difference_ci_high; significant_difference",
      "SE/CI for selected official PISA non-mean statistics",
      "historical code/name validity beyond observed envelope",
      "release_date",
      "nonvalidated modules",
      "absolute SES, gender, migration/home language, school sorting",
      "PISA mathematics and science",
      "TIMSS Grade 4 mathematics/science"),
    current_fill_status=c("intentionally_blank","intentionally_blank",
      "partially_fillable","observed_envelope_only","not_captured",
      "hidden_by_module_status","not_validated","not_validated","discovery_only"),
    blocking_issue_nl=c(
      "Geen gevalideerde cross-wave variantie inclusief relevante linking error.",
      "Variantie/covariantie van landwaarde minus panelgemiddelde is nog niet gestandaardiseerd.",
      "Niet alle officiële SE-kolommen zijn als publicatieschema gevalideerd.",
      "Historische broncode-/naamintervallen zijn nog niet als afzonderlijk register geaudit.",
      "Exacte releasedata zijn nog niet gestructureerd geverifieerd.",
      "Deze modules mogen nog niet als dashboardkeuze verschijnen.",
      "Module-specifieke extractie/berekening/validatie is nog niet afgerond.",
      "Vaste domeinspecifieke panels en sanity checks ontbreken nog.",
      "Nog geen gevalideerde estimator of panel."),
    blocking_issue_en=c(
      "No validated cross-wave variance including relevant linking error.",
      "Variance/covariance of country value minus panel mean is not yet standardised.",
      "Not all official SE columns have been validated for the publication schema.",
      "Historical source-code/name intervals have not yet been audited as a separate registry.",
      "Exact release dates have not yet been structurally verified.",
      "These modules must not yet appear as dashboard choices.",
      "Module-specific extraction/computation/validation is not complete.",
      "Fixed domain-specific panels and sanity checks are still missing.",
      "No validated estimator or panel yet."),
    required_additional_work_nl=c(
      "Valideer trend-SE/variantie inclusief linking error.",
      "Definieer benchmarkvariantie en covariantie; valideer daarna inferentie.",
      "Bouw tabelspecifieke SE-selectie met header-audit.",
      "Audit code-/naamwijzigingen per survey en periode.",
      "Voeg gecontroleerde releasedata toe aan sources.csv.",
      "Rond iedere module eerst methodologisch af.",
      "Voer afgesproken module-audits en validatie uit.",
      "Bouw en valideer fixed panels per domein.",
      "Volledige data-audit, estimatorvalidatie en panelkeuze."),
    required_additional_work_en=c(
      "Validate trend SE/variance including linking error.",
      "Define benchmark variance and covariance; then validate inference.",
      "Build table-specific SE selection with header audit.",
      "Audit code/name changes by survey and period.",
      "Add controlled release dates to sources.csv.",
      "Complete methodological validation for each module first.",
      "Complete the agreed module audits and validation.",
      "Build and validate fixed panels by domain.",
      "Complete data audit, estimator validation and panel selection."),
    stringsAsFactors=FALSE
  )
  write.csv(z,path,row.names=FALSE,fileEncoding="UTF-8",na="")
}

v2_write_bundle <- function(master,asg,oecd,pisa_core) {
  t0 <- v13_tic()
  dir.create(dashboard_v2_dir,recursive=TRUE,showWarnings=FALSE)

  observations <- v2_build_observations(master,asg,oecd,pisa_core)
  pm <- v2_panel_members()
  countries <- v2_country_table_from_used_ids(observations,pm)
  country_source_codes <- v2_country_source_codes(observations,oecd,asg,countries)
  samples <- v2_samples(observations)
  comparisons <- v2_make_comparisons(observations,V2_PANELS,pm)
  changes <- v2_make_changes(observations)
  availability <- v2_make_availability(observations,countries)

  files <- list(
    countries=countries,
    country_source_codes=country_source_codes,
    observations=observations,
    comparisons=comparisons,
    changes=changes,
    indicators=V2_INDICATORS,
    groups=V2_GROUPS,
    content_questions=V2_CONTENT_QUESTIONS,
    sources=V2_SOURCES,
    panels=V2_PANELS,
    panel_members=pm,
    availability=availability,
    module_status=V2_MODULE_STATUS,
    scales=V2_SCALES,
    thresholds=V2_THRESHOLDS,
    samples=samples,
    caveats=V2_CAVEATS
  )
  dd_stub <- data.frame(
    file=character(),field=character(),semantic_type=character(),
    nullable=logical(),enum_name=character(),
    description_nl=character(),description_en=character(),
    stringsAsFactors=FALSE)
  vc_stub <- data.frame(
    check_id=character(),pass=logical(),severity=character(),file=character(),
    details_nl=character(),details_en=character(),stringsAsFactors=FALSE)
  files$data_dictionary <- v2_make_dictionary(c(files,
    list(data_dictionary=dd_stub,validation_checks=vc_stub)))
  checks <- v2_validate_bundle(files,V2_METHODS,V2_BENCHMARKS)
  if(anyDuplicated(checks$check_id))
    stop("Duplicate validation check_id values in schema-v2 validation.")
  files$validation_checks <- checks

  # Write the 19 contract CSVs.
  for(nm in names(files))
    write.csv(files[[nm]],file.path(dashboard_v2_dir,paste0(nm,".csv")),
              row.names=FALSE,fileEncoding="UTF-8",na="")

  # Supporting controlled metadata.
  write.csv(V2_METHODS,file.path(dashboard_v2_dir,"methods.csv"),
            row.names=FALSE,fileEncoding="UTF-8",na="")
  write.csv(V2_BENCHMARKS,file.path(dashboard_v2_dir,"benchmarks.csv"),
            row.names=FALSE,fileEncoding="UTF-8",na="")
  write.csv(V2_STATUS_DEFINITIONS,file.path(dashboard_v2_dir,"status_definitions.csv"),
            row.names=FALSE,fileEncoding="UTF-8",na="")
  v2_write_schema_keys_enums(file.path(dashboard_v2_dir,"SCHEMA_KEYS_ENUMS.csv"))
  v2_write_pipeline_gaps(file.path(dashboard_v2_dir,"PIPELINE_GAPS.csv"))

  # Human-readable validation.
  rpt <- c(
    "# Dashboard schema v2.1 validation report","",
    paste("Release:",DASHBOARD_V2_RELEASE_ID),
    paste("Created:",Sys.time()),"",
    paste("Checks passed:",sum(checks$pass),"/",nrow(checks)),"",
    apply(checks,1,function(r)
      paste0("- ",ifelse(r[["pass"]],"PASS","FAIL")," — ",
             r[["check_id"]],": ",r[["details_nl"]])),
    "","No error-level failure may be released."
  )
  writeLines(rpt,file.path(dashboard_v2_dir,"validation_report.md"))
  if(any(!checks$pass & checks$severity=="error"))
    stop("Dashboard schema v2.1 validation failed. See validation_report.md")

  readme <- c(
    "# PISA/PIRLS dashboard bundle — schema v2.1","",
    paste("Release:",DASHBOARD_V2_RELEASE_ID),
    "Status: review/full-data export; not a claim that future modules are validated.","",
    "Core rules:",
    "- countries.csv uses stable country/system IDs; source codes live in country_source_codes.csv.",
    "- observations.csv contains publishable validated reading modules only.",
    "- changes.csv contains changes; uncertainty/significance stays blank until valid trend variance exists.",
    "- comparisons.csv separates descriptive point_relation from statistical inference.",
    "- rank/tercile is restricted to named fixed panels; outside-panel comparable values can still be compared with the panel mean.",
    "- PISA and PIRLS achievement scales remain separate.",
    "- frontend availability is governed jointly by availability.csv and module_status.csv.",
    "- all user-facing methodological metadata has Dutch and English fields.","",
    paste("PISA observation rows:",sum(observations$survey=="PISA")),
    paste("PIRLS observation rows:",sum(observations$survey=="PIRLS")),
    paste("Countries/systems:",nrow(countries)),
    paste("Comparison rows:",nrow(comparisons)),
    paste("Change rows:",nrow(changes))
  )
  writeLines(readme,file.path(dashboard_v2_dir,"README.md"))

  # Five examples for review.
  ex <- c("# Five example rows per core dashboard file","")
  for(nm in names(files)) {
    ex <- c(ex,paste0("## ",nm,".csv"),
      capture.output(utils::write.table(utils::head(files[[nm]],5),
        sep=" | ",row.names=FALSE,quote=FALSE,na="")),"")
  }
  writeLines(ex,file.path(dashboard_v2_dir,"example_rows.md"))

  # Manifest last.
  ff <- list.files(dashboard_v2_dir,full.names=TRUE,recursive=FALSE)
  ff <- ff[basename(ff)!="manifest.csv"]
  mani <- data.frame(
    file=basename(ff),bytes=file.info(ff)$size,
    sha256=vapply(ff,file_sha256,character(1)),stringsAsFactors=FALSE)
  write.csv(mani,file.path(dashboard_v2_dir,"manifest.csv"),row.names=FALSE)

  v13_toc("dashboard_schema_v2_export",t0)
  list(files=files,validation=checks,directory=dashboard_v2_dir)
}


# =============================================================================
# 17. PIPELINE EXECUTION
# =============================================================================

master_rds <- file.path(root,"PISA_PIRLS_MASTER_ANALYSIS.rds")
resume_science <- FALSE
master_checkpoint <- NULL

if(RUN_MODE=="fast" && isTRUE(FAST_REUSE_VALIDATED_MASTER) &&
   !isTRUE(FORCE_SCIENTIFIC_REBUILD) && file.exists(master_rds)) {
  q <- try(readRDS(master_rds),silent=TRUE)
  if(!inherits(q,"try-error") && v2_checkpoint_valid(q)) {
    master_checkpoint <- q
    resume_science <- TRUE
    log_msg("FAST RESUME: validated master checkpoint accepted — scientific core not rebuilt.")
  } else {
    log_msg("FAST RESUME: existing master checkpoint rejected; scientific core will rebuild.")
  }
}

if(resume_science) {
  master <- master_checkpoint
  asg <- master$pirls_asg_manifest
  ash <- master$pirls_ash_manifest
  oecd <- master$pisa_official_extract
  pisa_core <- master$pisa_core
  pisa_products <- master$pisa_fixed32
  pisa_paths <- master$pisa_workbook_paths
} else {
  master <- list(
    metadata=list(
      created_at=as.character(Sys.time()),
      version="1.3.5-fast-schema-order-fix",
      script="PISA_PIRLS_MASTER_PIPELINE_v1_3_5_FAST_SCHEMA_ORDER_FIX.R",
      downloads=downloads,
      methodological_note="Style guide governs formatting only; scientific choices follow the analysis plan."
    ),
    caveats=caveats
  )

  # ---- PIRLS -----------------------------------------------------------------
  if(RUN_PIRLS_AUDITS || RUN_PIRLS_VALIDATION || RUN_PIRLS_MAIN_PRODUCTION) {
    log_msg("=== PIRLS: discover and extract exact main-cycle files ===")
    pirls_zips <- discover_pirls_zips()
    asg <- extract_pirls_main_files(pirls_zips,"ASG")
    ash <- extract_pirls_main_files(pirls_zips,"ASH")
    master$pirls_zip_map <- pirls_zips
    master$pirls_asg_manifest <- asg
    master$pirls_ash_manifest <- ash

    if(RUN_PIRLS_AUDITS) {
      log_msg("=== PIRLS: student resource audit ===")
      master$pirls_student_resource_audit <- pirls_student_resource_audit(asg)
      log_msg("=== PIRLS: Home Questionnaire response audit ===")
      master$pirls_home_response_audit <- pirls_home_response_audit(asg,ash)
    }

    if(RUN_PIRLS_PARENT_ROBUSTNESS_PREP) {
      master$pirls_parent_variable_dictionary <- prepare_parent_ses_robustness(ash)
    }

    if(RUN_PIRLS_VALIDATION) {
      log_msg("=== PIRLS: validation panel ===")
      valcodes <- names(PIRLS_2021_VALIDATION_MEANS)
      val <- run_pirls_panel(asg,valcodes,"VALIDATION5")
      master$pirls_validation <- val
      master$pirls_validation_check <- validate_pirls_2021(val$estimates)
    }

    if(RUN_PIRLS_MAIN_PRODUCTION) {
      log_msg("=== PIRLS: MAIN-13 full production ===")
      main13 <- run_pirls_panel(asg,PIRLS_MAIN13,"MAIN13")
      robust16 <- run_pirls_panel(asg,PIRLS_ROBUST16,"ROBUST16")
      mainwide <- pirls_estimates_wide(main13$estimates)
      robwide <- pirls_estimates_wide(robust16$estimates)

      write.csv(mainwide,file.path(dirs$pirls_results,"PIRLS_MAIN13_country_year_wide.csv"),
                row.names=FALSE)
      write.csv(robwide,file.path(dirs$pirls_results,"PIRLS_ROBUST16_country_year_wide.csv"),
                row.names=FALSE)

      # Fixed-panel NL ranks and dynamic terciles for all headline metrics.
      headline <- c(
        mean_reading="high",
        prof_ge475="high",
        p90_p10_scoregap="low",
        q1_mean_reading="high",
        q4_mean_reading="high",
        q4_q1_scoregap="low",
        q1_prof_ge475="high",
        q4_prof_ge475="high",
        q4_q1_profgap="low"
      )
      rank_outputs <- list()
      for(metric in names(headline)) {
        rt <- rank_and_terciles(mainwide,metric=metric,direction=headline[[metric]])
        nlrank <- rt$ranks[rt$ranks$country_code3=="NLD",
                           c("year","country_code3",metric,"rank")]
        write.csv(nlrank,file.path(dirs$pirls_results,
          paste0("PIRLS_MAIN13_NL_rank_",metric,".csv")),row.names=FALSE)
        write.csv(rt$assignments,file.path(dirs$pirls_results,
          paste0("PIRLS_MAIN13_dynamic_terciles_",metric,".csv")),row.names=FALSE)
        rank_outputs[[metric]] <- list(nlrank=nlrank,assignments=rt$assignments)
      }

      master$pirls_main13 <- main13
      master$pirls_robust16 <- robust16
      master$pirls_main13_wide <- mainwide
      master$pirls_robust16_wide <- robwide
      master$pirls_ranks_terciles <- rank_outputs

      if(RUN_PIRLS_FIGURES) make_pirls_figures(mainwide)
    }
  }

  # ---- PISA official OECD -----------------------------------------------------
  pisa_paths <- NULL
  oecd <- NULL
  pisa_core <- NULL
  pisa_products <- NULL

  if(RUN_PISA_OFFICIAL_DOWNLOAD || RUN_PISA_OFFICIAL_EXTRACT ||
     RUN_PISA_CORE_READING || RUN_PISA_EQUITY_RAW_EXTRACTS) {
    log_msg("=== PISA: official OECD StatLink workbooks ===")
    pisa_paths <- download_oecd_workbooks()
    master$pisa_workbook_paths <- pisa_paths

    if(RUN_PISA_OFFICIAL_EXTRACT) {
      oecd <- extract_oecd_targets(pisa_paths)
      master$pisa_official_extract <- oecd
      log_msg("OECD target extraction: ",nrow(oecd$cells),
              " numeric mapped cells; ",length(oecd$failures),
              " non-core/target extraction failure(s) recorded")
    } else {
      rds <- file.path(dirs$pisa_extract,"OECD_official_target_cells.rds")
      if(file.exists(rds)) oecd <- readRDS(rds)
    }

    if(RUN_PISA_CORE_READING && !is.null(oecd) && nrow(oecd$cells)) {
      log_msg("=== PISA: build fixed-32 core reading series ===")
      pisa_core <- pisa_build_core_reading(oecd$cells)
      master$pisa_core <- pisa_core
      master$pisa_internal_consistency <- validate_pisa_internal_consistency(
        pisa_core$long,pisa_core$ses
      )
      master$pisa_sanity <- validate_pisa_nl(pisa_core$long,pisa_core$ses)
      pisa_products <- pisa_fixed32_products(pisa_core)
      master$pisa_fixed32 <- pisa_products
      if(RUN_PISA_FIGURES) make_pisa_figures(pisa_products)
    }

    if(RUN_PISA_OVERLAP_AUDIT_2022_2025 && !is.null(oecd) && nrow(oecd$cells)) {
      master$pisa_overlap_audit <- pisa_overlap_audit(oecd$cells)
    }
  }

  if(RUN_PISA_MICRODATA_AUDIT) {
    log_msg("=== PISA: optional microdata equity-variable audit ===")
    master$pisa_microdata_dictionary <- pisa_microdata_dictionary_audit()
  }

  if(RUN_TIMSS_DISCOVERY) {
    log_msg("=== TIMSS: future Grade-4 module discovery ===")
    master$timss_discovery <- timss_discovery()
  }

}

# Schema v2.1 export runs after either a clean build or validated checkpoint resume.
if(isTRUE(RUN_SCHEMA_V2_EXPORT)) {
  t_schema <- v13_tic()
  if(is.null(pisa_core)||is.null(oecd)||is.null(asg))
    stop("Schema-v2 export requires pisa_core, OECD extract and PIRLS ASG manifest.")
  master$dashboard_bundle_v2 <- v2_write_bundle(master,asg,oecd,pisa_core)
  master$metadata$last_dashboard_export_at <- as.character(Sys.time())
  master$metadata$dashboard_schema_version <- "2.1"
  master$metadata$pipeline_wrapper_version <- "1.3.5-fast-schema-order-fix"
  master$metadata$scientific_core_reused <- resume_science
  v13_toc("schema_v2_total",t_schema,
          if(resume_science)"checkpoint_resume"else"clean_science_build")
}


# =============================================================================
# 18. MASTER OUTPUT / MANIFEST
# =============================================================================

if(!resume_science || length(figure_registry)) master$figure_registry <- figure_registry
master$caveat_register <- caveats
master$session_info <- utils::capture.output(sessionInfo())

saveRDS(master,master_rds,compress=MASTER_RDS_COMPRESSION)

writeLines(c(
  "PISA/PIRLS master pipeline finished.",
  paste("Master analysis RDS:",master_rds),
  paste("Log:",logfile),
  paste("Figures:",dirs$figures),
  paste("PIRLS results:",dirs$pirls_results),
  paste("PISA results:",dirs$pisa_results),
  if(RUN_SCHEMA_V2_EXPORT)
    paste("Dashboard schema v2.1 bundle:",dashboard_v2_dir)
  else
    "Dashboard schema v2.1 export disabled.",
  "",
  "Scientific rule: do not treat a completed script as validation.",
  "Inspect validation CSVs, source manifests, caveat register and figure register before release."
),file.path(root,"WHERE_IS_MASTER_OUTPUT.txt"))

# Simple machine-readable artifact manifest
allfiles <- list.files(root,recursive=TRUE,full.names=TRUE)
manifest <- data.frame(
  path=normalizePath(allfiles,winslash="/",mustWork=FALSE),
  size_bytes=file.info(allfiles)$size,
  modified=as.character(file.info(allfiles)$mtime),
  stringsAsFactors=FALSE
)
write.csv(manifest,file.path(root,"artifact_manifest.csv"),row.names=FALSE)


write.csv(V13_TIMINGS,
          file.path(dirs$logs,paste0("stage_timings_v1_3_",timestamp,".csv")),
          row.names=FALSE)

autopilot_summary <- c(
  "PISA/PIRLS AUTOPILOT RUN SUMMARY",
  paste("Finished:", Sys.time()),
  paste("Master RDS:", master_rds),
  paste("Main log:", logfile),
  paste("Diagnostics directory:", AUTOPILOT_DIAG_DIR),
  "",
  paste("PISA long years:",
        if(!is.null(pisa_core) && nrow(pisa_core$long))
          paste(sort(unique(as.integer(pisa_core$long$year))),collapse=", ")
        else "not produced"),
  paste("PISA SES years:",
        if(!is.null(pisa_core) && nrow(pisa_core$ses))
          paste(sort(unique(as.integer(pisa_core$ses$year))),collapse=", ")
        else "not produced"),
  paste("PISA Netherlands sanity:",
        if(!is.null(master$pisa_sanity))
          if(all(master$pisa_sanity$pass)) "PASS" else "FAIL"
        else "not run"),
  paste("PISA fixed long panel N:",
        if(!is.null(pisa_products)) length(unique(pisa_products$long$country))
        else NA),
  paste("PISA fixed SES panel N:",
        if(!is.null(pisa_products)) length(unique(pisa_products$ses$country))
        else NA),
  "",
  paste("PIRLS derived-result reuse:",if(isTRUE(REUSE_DERIVED_PIRLS_OUTPUTS))"enabled" else "disabled"),
  paste("OECD parsed-table cache reuse:",if(isTRUE(REUSE_OECD_EXTRACT_CACHE))"enabled" else "disabled"),
  paste("OECD cache/network actions:",
        if(nrow(DOWNLOAD_CACHE_AUDIT))
          paste(paste0(DOWNLOAD_CACHE_AUDIT$action,":",
                       basename(DOWNLOAD_CACHE_AUDIT$canonical_file)),
                collapse=" | ")
        else "no OECD workbook action recorded"),
  paste("Pipeline wrapper: 1.3.5-fast-schema-order-fix"),
  paste("Scientific core reused:",resume_science),
  paste("Dashboard schema v2.1:",if(RUN_SCHEMA_V2_EXPORT)dashboard_v2_dir else "disabled"),
  "No unresolved OECD header ambiguity is silently guessed."
)
writeLines(autopilot_summary,
           file.path(root,"AUTOPILOT_RUN_SUMMARY.txt"))

log_msg("DONE — PISA/PIRLS MASTER PIPELINE")
log_msg("Master RDS: ",master_rds)
cat("\n============================================================\n")
cat("DONE — PISA/PIRLS MASTER PIPELINE\n")
cat("============================================================\n")
cat("Master RDS:\n",master_rds,"\n",sep="")
if(RUN_SCHEMA_V2_EXPORT) {
  cat("Dashboard schema v2.1 bundle:\n",dashboard_v2_dir,"\n",sep="")
  cat("Scientific core reused from validated checkpoint: ",resume_science,"\n",sep="")
} else {
  cat("Dashboard schema v2.1 export disabled.\n")
}
if(isTRUE(AUTOPILOT_MODE)) options(error=AUTOPILOT_PREVIOUS_ERROR_OPTION)
cat("\nAlways inspect the validation and comparability outputs before publication.\n")
