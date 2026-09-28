# =============================================================================
# PISA/PIRLS RC1 — HISTORICAL PISA NORMALISER + EMPIRICAL COHORT AUDIT
# Version 9.0 CACHE-SAFE RESUME — 20 September 2026
#
# PURPOSE
#   Correct the remaining false-negative source audit for historical PISA:
#   - 2006/2012 fixed-width student PUF + SAS setup file
#   - 2015/2018 SAS student PUF (.sas7bdat inside ZIP)
#   - 2022 SPSS student PUF
#   - 2025 SPSS student PUF
#
#   It writes small standardised local RDS extracts for later RC1 sorting
#   computation, but NEVER puts microdata in the upload ZIP.
#
#   It also:
#   - audits actual variable names/labels;
#   - confirms 80 replicate weights and reading PVs;
#   - computes empirical weighted PISA mean ages;
#   - computes empirical weighted PIRLS mean ages (ASDGAGE in 2001, ASDAGE later);
#   - creates an empirical cohort-pair registry before any new sorting result;
#   - exports demographic variable candidates for later harmonisation.
#
# SAFETY
#   * No raw OECD/IEA source is modified.
#   * No data are downloaded.
#   * PISA microdata stay local.
#   * Final upload ZIP contains metadata/aggregates only.
#
# PARALLEL POLICY
#   * I/O-heavy PIRLS age extraction: preferred 6 PSOCK workers.
#   * automatic fallback 6 -> 4 -> 2 -> 1.
# =============================================================================

options(stringsAsFactors=FALSE)

DOWNLOADS <- normalizePath(file.path(Sys.getenv("USERPROFILE"),"Downloads"),winslash="/",mustWork=TRUE)
ROOT <- file.path(DOWNLOADS,"PISA_PIRLS_MASTER_PIPELINE")
if(!dir.exists(ROOT)) stop("Project root not found: ",ROOT)

# Packages already used in the project.
if(!requireNamespace("haven",quietly=TRUE)) stop("Package haven is required.")
if(!requireNamespace("tidyselect",quietly=TRUE)) stop("Package tidyselect is required.")

# The historical 2006/2012 files are fixed-width ASCII with an OECD SAS INPUT
# control file. SAScii does not parse these OECD control files
# reliably, so RC1 uses SAScii::parse.SAScii(), which is designed to translate
# SAS INPUT instructions to fixed-width column widths.
if(!requireNamespace("SAScii",quietly=TRUE)) {
  cat("Installing CRAN package SAScii (needed only for PISA 2006/2012 fixed-width PUFs)...\n")
  install.packages("SAScii",repos="https://cloud.r-project.org")
}
if(!requireNamespace("SAScii",quietly=TRUE))
  stop("Could not install/load SAScii.")

PHYSICAL_CORES <- suppressWarnings(parallel::detectCores(logical=FALSE))
LOGICAL_CORES <- suppressWarnings(parallel::detectCores(logical=TRUE))
if(is.na(PHYSICAL_CORES) || PHYSICAL_CORES<2L)
  PHYSICAL_CORES <- max(2L,LOGICAL_CORES-2L)
IO_WORKERS <- max(2L,min(6L,PHYSICAL_CORES-2L))
CPU_WORKERS_RECOMMENDED <- max(2L,min(8L,PHYSICAL_CORES-2L))

STAMP <- format(Sys.time(),"%Y%m%d_%H%M%S")
OUT_ROOT <- file.path(ROOT,"15_rc1_pisa_normalised")
OUT <- file.path(OUT_ROOT,paste0("build_",STAMP))
EXTRACT_ROOT <- file.path(ROOT,"15_rc1_pisa_normalised","standardised_extracts")
HANDOFF_DIR <- file.path(ROOT,"RUNNER","handoffs")
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
dir.create(EXTRACT_ROOT,recursive=TRUE,showWarnings=FALSE)
dir.create(HANDOFF_DIR,recursive=TRUE,showWarnings=FALSE)

norm <- function(x) normalizePath(x,winslash="/",mustWork=FALSE)
clean_label <- function(x) {
  if(is.null(x) || !length(x) || is.na(x[1])) return("")
  gsub("[\r\n\t]+"," ",trimws(as.character(x[1])))
}
wmean <- function(x,w) {
  x <- suppressWarnings(as.numeric(x)); w <- suppressWarnings(as.numeric(w))
  ok <- is.finite(x)&is.finite(w)&w>0
  if(!any(ok)) return(NA_real_)
  sum(x[ok]*w[ok])/sum(w[ok])
}
upper_names <- function(d) {
  names(d) <- toupper(names(d))
  d
}
num_suffix <- function(x) {
  suppressWarnings(as.integer(sub(".*?([0-9]+)$","\\1",x)))
}

cat("\n============================================================\n")
cat("RC1 HISTORICAL PISA NORMALISER + EMPIRICAL COHORT AUDIT\n")
cat("============================================================\n")
cat("Detected cores: ",PHYSICAL_CORES," physical / ",LOGICAL_CORES," logical\n",sep="")
cat("I/O workers: ",IO_WORKERS,"\n",sep="")
cat("CPU-heavy future workers: ",CPU_WORKERS_RECOMMENDED,"\n\n",sep="")

# -----------------------------------------------------------------------------
# File discovery
# -----------------------------------------------------------------------------

all_files <- list.files(DOWNLOADS,recursive=TRUE,full.names=TRUE,all.files=FALSE)
all_files <- all_files[file.exists(all_files)]
bn <- basename(all_files)
not_partial <- !grepl("\\.crdownload$",bn,ignore.case=TRUE)
all_files <- all_files[not_partial]; bn <- bn[not_partial]

pick <- function(patterns,prefer_largest=TRUE) {
  hit <- rep(FALSE,length(all_files))
  for(p in patterns) hit <- hit | grepl(p,bn,perl=TRUE,ignore.case=TRUE)
  z <- all_files[hit]
  if(!length(z)) return("")
  info <- file.info(z)
  if(prefer_largest) z <- z[order(info$size,decreasing=TRUE,na.last=TRUE)]
  else z <- z[order(info$mtime,decreasing=TRUE,na.last=TRUE)]
  norm(z[1])
}

pick_preferred <- function(primary_patterns,fallback_patterns) {
  primary <- pick(primary_patterns)
  if(nzchar(primary)) return(primary)
  pick(fallback_patterns)
}

modern_puf_kind <- function(path) {
  b <- toupper(basename(path))
  if(grepl("SPSS",b)) return("sav")
  if(grepl("SAS",b)) return("sas")

  # If filename is nonstandard, inspect archive members rather than guessing.
  if(tolower(tools::file_ext(path))=="zip") {
    zl <- tryCatch(utils::unzip(path,list=TRUE),error=function(e) NULL)
    if(!is.null(zl)) {
      nm <- toupper(zl$Name)
      if(any(grepl("\\.SAV$",nm))) return("sav")
      if(any(grepl("\\.SAS7BDAT$",nm))) return("sas")
    }
  }
  stop("Could not determine whether PUF is SPSS or SAS: ",path)
}

src <- data.frame(
  year=c(2006,2006,2012,2012,2015,2018,2022,2025),
  role=c("data","control","data","control","data","data","data","data"),
  path=c(
    pick(c("^INT_Stu06_Dec07(?:\\s*\\(\\d+\\))?\\.zip$")),
    pick(c("^PISA2006_SAS_student(?:\\s*\\(\\d+\\))?\\.sas$",
           "^PISA2006_SPSS_student(?:\\s*\\(\\d+\\))?\\.(txt|sps)$"),FALSE),
    pick(c("^INT_STU12_DEC03(?:\\s*\\(\\d+\\))?\\.zip$")),
    pick(c("^PISA2012_SAS_student(?:\\s*\\(\\d+\\))?\\.sas$",
           "^PISA2012_SPSS_student(?:\\s*\\(\\d+\\))?\\.(txt|sps)$"),FALSE),
    pick_preferred(
      c("^(PUF_)?SPSS_COMBINED_CMB_STU_QQQ(?:\\s*\\(\\d+\\))?\\.zip$"),
      c("^(PUF_)?SAS_COMBINED_CMB_STU_QQQ(?:\\s*\\(\\d+\\))?\\.zip$")
    ),
    pick_preferred(
      c("^SPSS_STU_QQQ(?:\\s*\\(\\d+\\))?\\.zip$"),
      c("^SAS_STU_QQQ(?:\\s*\\(\\d+\\))?\\.zip$")
    ),
    pick(c("^STU_QQQ_SPSS(?:\\s*\\(\\d+\\))?\\.zip$",
           "^STU_QQQ_SAS(?:\\s*\\(\\d+\\))?\\.zip$")),
    pick(c("^CY09_MS_STU_PUF(?:\\s*\\(\\d+\\))?\\.sav$",
           "^CY09_MS_STU_PUF(?:\\s*\\(\\d+\\))?\\.zip$"))
  ),
  stringsAsFactors=FALSE
)

src$exists <- nzchar(src$path) & file.exists(src$path)
write.csv(src,file.path(OUT,"PISA_SOURCE_DISCOVERY_RC1.csv"),row.names=FALSE)

required <- src$year %in% c(2006,2012,2015,2018,2022,2025)
if(any(required & !src$exists)) {
  print(src[required,],row.names=FALSE)
  stop("Required PISA RC1 source/control file missing. No import was started.")
}

# -----------------------------------------------------------------------------
# Dictionary helpers
# -----------------------------------------------------------------------------

dictionary_haven <- function(path,type=c("sav","sas")) {
  type <- match.arg(type)
  d <- if(type=="sav") haven::read_sav(path,n_max=1) else haven::read_sas(path,n_max=1)
  data.frame(
    variable=toupper(names(d)),
    label=vapply(d,function(x) clean_label(attr(x,"label",exact=TRUE)),character(1)),
    stringsAsFactors=FALSE
  )
}

dictionary_sas_setup <- function(path) {
  # SAScii returns one row per fixed-width field plus any explicit gap rows.
  # Keep its width/character/divisor metadata because they are needed to read
  # a selected subset without loading the full 1+ GB PISA ASCII file.
  x <- tryCatch(
    SAScii::parse.SAScii(path),
    error=function(e) {
      # Some SAS setup files contain the word INPUT before the actual INPUT
      # block. If that ever occurs, identify the likely standalone INPUT line
      # and retry from there.
      ln <- readLines(path,warn=FALSE,encoding="UTF-8")
      inp <- which(grepl("^\\s*INPUT\\s*$",toupper(ln)))
      if(!length(inp)) stop(e)
      SAScii::parse.SAScii(path,beginline=inp[1])
    }
  )
  if(!is.data.frame(x) || !all(c("varname","width","char","divisor") %in% names(x)))
    stop("Could not parse OECD SAS INPUT structure: ",path)

  out <- data.frame(
    variable=toupper(as.character(x$varname)),
    label="",
    setup_index=seq_len(nrow(x)),
    width=as.numeric(x$width),
    char=as.logical(x$char),
    divisor=as.numeric(x$divisor),
    stringsAsFactors=FALSE
  )

  # OECD PISA 2006/2012 SAS setup files encode several identifiers with
  # character formats that SAScii does not always flag as character.
  # If CNT is coerced to numeric, country codes such as AUS/NLD become NA and
  # the historical cohort panels disappear. Force the identifiers that must
  # remain strings.
  force_char <- grepl(
    "^(CNT|COUNTRY|SCHOOLID|STIDSTD|CNTSCHID|CNTSTUID)$",
    out$variable
  )
  out$char[force_char] <- TRUE

  out
}

extract_ascii_member <- function(zip_path) {
  if(tolower(tools::file_ext(zip_path))!="zip") {
    if(!file.exists(zip_path)) stop("ASCII data file not found: ",zip_path)
    return(list(path=zip_path,tempdir=NULL,member=basename(zip_path)))
  }

  zl <- utils::unzip(zip_path,list=TRUE)
  n <- toupper(zl$Name)
  j <- grepl("\\.(TXT|DAT)$",n)
  if(!any(j)) stop("No TXT/DAT student member found in ",basename(zip_path))

  cand <- zl[j,,drop=FALSE]
  # Prefer a student member if an archive ever contains more than one text file.
  score <- as.integer(grepl("STU",toupper(cand$Name)))*100 +
    log1p(as.numeric(cand$Length))
  member <- cand$Name[which.max(score)]

  td <- tempfile("pisa_ascii_")
  dir.create(td,recursive=TRUE)
  out <- utils::unzip(zip_path,files=member,exdir=td,junkpaths=TRUE,overwrite=TRUE)
  if(!length(out) || !file.exists(out[1])) stop("Could not extract ",member)
  list(path=out[1],tempdir=td,member=member)
}

read_selected_sascii_fwf <- function(data_zip,control,dict,selected_vars) {
  selected_vars <- unique(toupper(selected_vars))
  structure <- dict

  # SAScii width rows can include unnamed gap rows. Positive widths are read;
  # negative widths are skipped by read.fwf(). Turn every unselected data field
  # into a negative skip while preserving the exact logical record length.
  is_named <- !is.na(structure$variable) & nzchar(structure$variable)
  keep <- is_named & structure$variable %in% selected_vars

  widths <- abs(structure$width)
  widths[!keep] <- -widths[!keep]

  # Negative/zero malformed widths would make fixed-width reading unsafe.
  if(any(!is.finite(widths)) || any(widths==0))
    stop("Invalid fixed-width structure after parsing SAS control file.")

  kept_rows <- which(keep)
  if(!length(kept_rows)) stop("None of the requested columns were found in SAS setup.")

  ext <- extract_ascii_member(data_zip)
  on.exit(if(!is.null(ext$tempdir)) unlink(ext$tempdir,recursive=TRUE,force=TRUE),add=TRUE)

  cat("Reading fixed-width member ",ext$member,
      " with ",length(kept_rows)," selected columns; all other fields are skipped.\\n",sep="")

  d <- utils::read.fwf(
    file=ext$path,
    widths=widths,
    col.names=structure$variable[kept_rows],
    colClasses="character",
    comment.char="",
    strip.white=FALSE,
    buffersize=2000
  )

  # Mirror SAScii's numeric conversion: apply the SAS implied-decimal divisor
  # only if the source strings do not already contain a decimal point.
  for(j in seq_along(kept_rows)) {
    rr <- kept_rows[j]
    if(!isTRUE(structure$char[rr])) {
      raw <- trimws(as.character(d[[j]]))
      z <- suppressWarnings(as.numeric(raw))
      div <- structure$divisor[rr]
      if(is.finite(div) && div!=1) {
        nonblank <- raw[!is.na(raw) & nzchar(raw)]
        has_decimal <- length(nonblank) && any(grepl(".",nonblank,fixed=TRUE))
        if(!has_decimal) z <- z*div
      }
      d[[j]] <- z
    } else {
      d[[j]] <- trimws(as.character(d[[j]]))
    }
  }

  d
}

choose_one <- function(vars,candidates) {
  u <- toupper(vars)
  j <- match(toupper(candidates),u,nomatch=0L)
  j <- j[j>0L]
  if(length(j)) vars[j[1]] else NA_character_
}

select_required <- function(dict) {
  v <- toupper(dict$variable)
  lab <- toupper(ifelse(is.na(dict$label),"",dict$label))

  country <- choose_one(v,c("CNT","COUNTRY"))
  school <- choose_one(v,c("CNTSCHID","SCHOOLID","SCHOOL_ID"))
  student <- choose_one(v,c("CNTSTUID","STIDSTD","STUDENTID","STUDENT_ID"))
  age <- choose_one(v,c("AGE"))
  escs <- choose_one(v,c("ESCS"))
  immig <- choose_one(v,c("IMMIG"))
  weight <- choose_one(v,c("W_FSTUWT"))

  pvs <- v[grepl("^PV[0-9]+READ$",v)]
  pvs <- pvs[order(num_suffix(pvs))]
  reps <- v[grepl("^(W_FSTR|W_FSTURWT)[0-9]+$",v)]
  reps <- reps[order(num_suffix(reps))]

  birth <- v[
    grepl("ST003D0[23]|BIRTH.*(YEAR|MONTH)|(YEAR|MONTH).*BIRTH",v) |
      grepl("BIRTH.*(YEAR|MONTH)|(YEAR|MONTH).*BIRTH",lab)
  ]

  demo <- v[
    grepl(
      "LANG|IMMIG|COBN|BIRTH|BORN|MOTHER.?TONGUE|COUNTRY.?OF.?BIRTH|^ST0?04|SEX|GENDER",
      v
    ) |
      grepl(
        "LANGUAGE|IMMIGR|COUNTRY OF BIRTH|BORN IN|MOTHER TONGUE|SEX|GENDER",
        lab
      )
  ]

  core <- unique(na.omit(c(country,school,student,age,escs,immig,weight,pvs,reps,birth,demo)))
  list(
    all=core,country=country,school=school,student=student,age=age,
    escs=escs,immig=immig,weight=weight,pvs=pvs,reps=reps,
    birth=unique(birth),demo=unique(demo)
  )
}

# Extract one relevant microdata member from a ZIP.
#
# Some official OECD PISA ZIPs use a ZIP compression method that can be listed
# by R but is not supported by R's internal unzip or Windows .NET extraction.
# Therefore the extraction cascade is:
#   1. R internal unzip
#   2. Windows tar.exe / bsdtar (libarchive; no install needed)
#   3. CRAN archive package (libarchive; installed as a Windows binary if needed)
#   4. 7-Zip if already installed
#   5. Windows .NET as a final fallback
#
# Existing validated 2006/2012 standardised extracts are still resumed, so this
# change does not repeat those expensive fixed-width imports.

ps_single_quote <- function(x) {
  gsub("'", "''", normalizePath(x, winslash="\\", mustWork=FALSE), fixed=TRUE)
}

find_extracted_member <- function(root, member, dest, expected_bytes=NA_real_) {
  # A failed unzip attempt can leave an empty destination file behind.
  # Search recursively for ALL matching basenames and always prefer the
  # largest non-empty candidate.  If expected_bytes is known, prefer the
  # candidate with the exact expected uncompressed size.
  all <- list.files(root, recursive=TRUE, full.names=TRUE, all.files=TRUE)
  if(length(all)) {
    info <- file.info(all)
    all <- all[!is.na(info$isdir) & !info$isdir]
  }

  direct <- c(file.path(root,member), file.path(root,basename(member)))
  candidates <- unique(c(direct[file.exists(direct)], all[
    tolower(basename(all)) == tolower(basename(member))
  ]))
  if(!length(candidates)) return(FALSE)

  sizes <- suppressWarnings(as.numeric(file.info(candidates)$size))
  good <- is.finite(sizes) & sizes > 0
  candidates <- candidates[good]
  sizes <- sizes[good]
  if(!length(candidates)) return(FALSE)

  if(is.finite(expected_bytes) && expected_bytes > 0 &&
     any(sizes == expected_bytes)) {
    src_file <- candidates[which(sizes == expected_bytes)[1]]
  } else {
    src_file <- candidates[which.max(sizes)]
  }

  # Never allow an old zero-byte partial destination to mask the real file.
  if(file.exists(dest)) {
    dsz <- suppressWarnings(as.numeric(file.info(dest)$size))
    if(!is.finite(dsz) || dsz == 0 ||
       normalizePath(src_file,winslash="/",mustWork=FALSE) !=
       normalizePath(dest,winslash="/",mustWork=FALSE)) {
      unlink(dest,force=TRUE)
    }
  }

  if(normalizePath(src_file,winslash="/",mustWork=FALSE) !=
     normalizePath(dest,winslash="/",mustWork=FALSE)) {
    ok <- file.copy(src_file,dest,overwrite=TRUE,copy.date=TRUE)
    if(!ok) return(FALSE)
  }

  file.exists(dest) && is.finite(file.info(dest)$size) && file.info(dest)$size > 0
}

extract_zip_member_tar <- function(zip_path, member, td, dest, expected_bytes=NA_real_) {
  tar_exe <- Sys.which("tar")
  if(!nzchar(tar_exe)) tar_exe <- Sys.which("tar.exe")
  if(!nzchar(tar_exe)) return(list(ok=FALSE,message="Windows tar.exe not found"))

  ans <- tryCatch(
    system2(
      tar_exe,
      args=c(
        "-xf", shQuote(zip_path),
        "-C", shQuote(td),
        shQuote(member)
      ),
      stdout=TRUE, stderr=TRUE
    ),
    error=function(e) structure(character(),status=1L,errmsg=conditionMessage(e))
  )
  status <- attr(ans,"status")
  if(is.null(status)) status <- 0L

  ok <- status==0L && find_extracted_member(td,member,dest,expected_bytes)
  list(ok=ok,message=paste(ans,collapse="\n"))
}

extract_zip_member_archive <- function(zip_path, member, td, dest, expected_bytes=NA_real_) {
  if(!requireNamespace("archive",quietly=TRUE)) {
    cat("Installing CRAN package archive for robust ZIP/libarchive extraction...\n")
    try(
      install.packages(
        "archive",
        repos="https://cloud.r-project.org",
        type="binary"
      ),
      silent=TRUE
    )
  }
  if(!requireNamespace("archive",quietly=TRUE))
    return(list(ok=FALSE,message="R package archive could not be installed/loaded"))

  ans <- tryCatch({
    archive::archive_extract(
      archive=zip_path,
      dir=td,
      files=member
    )
    character()
  },error=function(e) conditionMessage(e))

  ok <- find_extracted_member(td,member,dest,expected_bytes)
  list(ok=ok,message=paste(ans,collapse="\n"))
}

find_7zip <- function() {
  cand <- c(
    Sys.which("7z"),
    Sys.which("7z.exe"),
    "C:/Program Files/7-Zip/7z.exe",
    "C:/Program Files (x86)/7-Zip/7z.exe"
  )
  cand <- unique(cand[nzchar(cand)])
  cand[file.exists(cand)][1] %||% ""
}

extract_zip_member_7zip <- function(zip_path, member, td, dest, expected_bytes=NA_real_) {
  seven <- find_7zip()
  if(!nzchar(seven)) return(list(ok=FALSE,message="7-Zip not installed/found"))

  ans <- tryCatch(
    system2(
      seven,
      args=c(
        "x", "-y",
        paste0("-o", shQuote(td)),
        shQuote(zip_path),
        shQuote(member)
      ),
      stdout=TRUE, stderr=TRUE
    ),
    error=function(e) structure(character(),status=1L,errmsg=conditionMessage(e))
  )
  status <- attr(ans,"status")
  if(is.null(status)) status <- 0L

  ok <- status==0L && find_extracted_member(td,member,dest,expected_bytes)
  list(ok=ok,message=paste(ans,collapse="\n"))
}

extract_zip_member_dotnet <- function(zip_path, member, dest) {
  ps1 <- tempfile("pisa_extract_", fileext=".ps1")
  ps <- c(
    "$ErrorActionPreference = 'Stop'",
    "Add-Type -AssemblyName System.IO.Compression",
    "Add-Type -AssemblyName System.IO.Compression.FileSystem",
    paste0("$zipPath = '", ps_single_quote(zip_path), "'"),
    paste0("$member = '", gsub("'", "''", member, fixed=TRUE), "'"),
    paste0("$dest = '", ps_single_quote(dest), "'"),
    "$z = [System.IO.Compression.ZipFile]::OpenRead($zipPath)",
    "try {",
    "  $entry = $z.Entries | Where-Object { $_.FullName -eq $member } | Select-Object -First 1",
    "  if ($null -eq $entry) { throw ('ZIP member not found: ' + $member) }",
    "  $parent = [System.IO.Path]::GetDirectoryName($dest)",
    "  if (-not [System.IO.Directory]::Exists($parent)) {",
    "    [System.IO.Directory]::CreateDirectory($parent) | Out-Null",
    "  }",
    "  [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $dest, $true)",
    "} finally {",
    "  $z.Dispose()",
    "}"
  )
  writeLines(ps, ps1, useBytes=TRUE)

  powershell <- Sys.which("powershell")
  if(!nzchar(powershell)) powershell <- Sys.which("powershell.exe")
  if(!nzchar(powershell)) return(list(ok=FALSE,message="PowerShell not found"))

  ans <- system2(
    powershell,
    args=c("-NoProfile","-NonInteractive","-ExecutionPolicy","Bypass",
           "-File",shQuote(ps1)),
    stdout=TRUE, stderr=TRUE
  )
  status <- attr(ans,"status")
  if(is.null(status)) status <- 0L
  list(
    ok=(status==0L && file.exists(dest)),
    message=paste(ans,collapse="\n")
  )
}

extract_member <- function(zip_path,kind=c("sas","sav")) {
  kind <- match.arg(kind)

  zl <- tryCatch(
    suppressWarnings(utils::unzip(zip_path,list=TRUE)),
    error=function(e) e
  )
  if(inherits(zl,"error")) {
    stop(
      "Cannot read ZIP directory for ",basename(zip_path),": ",
      conditionMessage(zl),
      ". The local download may be incomplete."
    )
  }

  n <- toupper(zl$Name)
  pat <- if(kind=="sas") "\\.SAS7BDAT$" else "\\.SAV$"
  j <- grepl(pat,n) & grepl("STU|QQQ",n)
  if(!any(j)) j <- grepl(pat,n)
  if(!any(j)) stop("No ",kind," student file found in ",basename(zip_path))

  cand <- zl[j,,drop=FALSE]
  score <- as.integer(grepl("QQQ",toupper(cand$Name)))*100 +
    as.integer(grepl("STU",toupper(cand$Name)))*10 +
    log1p(as.numeric(cand$Length))
  k <- which.max(score)
  member <- as.character(cand$Name[k])
  expected_bytes <- suppressWarnings(as.numeric(cand$Length[k]))

  td <- tempfile("pisa_rc1_")
  dir.create(td,recursive=TRUE)
  dest <- file.path(td,basename(member))

  extraction_log <- character()
  extracted <- FALSE
  method <- NA_character_

  # 1. Base R
  out_r <- tryCatch(
    suppressWarnings(
      utils::unzip(
        zip_path,files=member,exdir=td,junkpaths=TRUE,overwrite=TRUE
      )
    ),
    error=function(e) character()
  )
  if(file.exists(dest) &&
     is.finite(suppressWarnings(as.numeric(file.info(dest)$size))) &&
     suppressWarnings(as.numeric(file.info(dest)$size)) > 0) {
    extracted <- TRUE
    method <- "R_internal_unzip"
  } else {
    if(file.exists(dest)) unlink(dest,force=TRUE)
    extraction_log <- c(extraction_log,"R internal unzip: failed/empty partial removed")
  }

  # 2. Windows bsdtar/libarchive
  if(!extracted) {
    cat("R internal unzip could not extract ",basename(member),
        "; trying Windows tar/libarchive...\n",sep="")
    if(file.exists(dest) && suppressWarnings(file.info(dest)$size)==0) unlink(dest,force=TRUE)
    res <- extract_zip_member_tar(zip_path,member,td,dest,expected_bytes)
    extracted <- isTRUE(res$ok)
    if(extracted) method <- "Windows_tar_libarchive"
    extraction_log <- c(extraction_log,paste0("Windows tar: ",res$message))
  }

  # 3. R archive/libarchive
  if(!extracted) {
    cat("Windows tar could not extract it; trying R package archive/libarchive...\n")
    if(file.exists(dest) && suppressWarnings(file.info(dest)$size)==0) unlink(dest,force=TRUE)
    res <- extract_zip_member_archive(zip_path,member,td,dest,expected_bytes)
    extracted <- isTRUE(res$ok)
    if(extracted) method <- "R_archive_libarchive"
    extraction_log <- c(extraction_log,paste0("R archive: ",res$message))
  }

  # 4. 7-Zip, if already installed
  if(!extracted) {
    cat("libarchive extraction did not succeed; trying 7-Zip if installed...\n")
    if(file.exists(dest) && suppressWarnings(file.info(dest)$size)==0) unlink(dest,force=TRUE)
    res <- extract_zip_member_7zip(zip_path,member,td,dest,expected_bytes)
    extracted <- isTRUE(res$ok)
    if(extracted) method <- "7Zip"
    extraction_log <- c(extraction_log,paste0("7-Zip: ",res$message))
  }

  # 5. .NET final fallback
  if(!extracted) {
    cat("Trying Windows .NET as final fallback...\n")
    if(file.exists(dest) && suppressWarnings(file.info(dest)$size)==0) unlink(dest,force=TRUE)
    res <- extract_zip_member_dotnet(zip_path,member,dest)
    extracted <- isTRUE(res$ok)
    if(extracted) method <- "Windows_dotNET"
    extraction_log <- c(extraction_log,paste0("Windows .NET: ",res$message))
  }

  if(!extracted) {
    log_file <- file.path(
      ROOT,"15_rc1_pisa_normalised",
      paste0("EXTRACTION_FAILURE_",format(Sys.time(),"%Y%m%d_%H%M%S"),".txt")
    )
    writeLines(
      c(
        paste0("ZIP: ",zip_path),
        paste0("Member: ",member),
        paste0("Expected uncompressed bytes: ",expected_bytes),
        "",
        extraction_log
      ),
      log_file
    )

    unlink(td,recursive=TRUE,force=TRUE)

    stop(
      "The student member ",member," could not be extracted by R, Windows tar/libarchive, ",
      "R archive/libarchive, 7-Zip (if present), or Windows .NET. ",
      "Do NOT re-download other PISA years. ",
      "At this point either this one local ZIP is incomplete or its compression is unusually unsupported. ",
      "Extraction diagnostics were written to: ",log_file
    )
  }

  actual_bytes <- file.info(dest)$size
  if(is.finite(expected_bytes) && expected_bytes>0 &&
     is.finite(actual_bytes) && actual_bytes!=expected_bytes) {
    unlink(td,recursive=TRUE,force=TRUE)
    stop(
      "Extracted member size mismatch for ",member,
      ": expected ",format(expected_bytes,scientific=FALSE),
      " bytes but got ",format(actual_bytes,scientific=FALSE),
      ". Only this year's ZIP needs attention."
    )
  }

  cat("Extracted ",member," using ",method,
      " (",sprintf("%.1f",actual_bytes/1024^2)," MB).\n",sep="")

  list(path=dest,tempdir=td,member=member,extract_method=method)
}

# -----------------------------------------------------------------------------
# Import each PISA year to a local standardised extract
# -----------------------------------------------------------------------------

normalise_names <- function(d,sel,year) {
  d <- upper_names(d)

  # If the fixed-width reader returned descriptive names, restore the selected
  # variable codes by position where possible.
  if(length(sel$all)==ncol(d) && !all(sel$all %in% names(d))) names(d) <- sel$all

  rename_one <- function(actual,canonical) {
    if(!is.na(actual) && actual %in% names(d) && actual!=canonical)
      names(d)[match(actual,names(d))] <<- canonical
  }
  rename_one(sel$country,"CNT")
  rename_one(sel$school,"SCHOOL_ID")
  rename_one(sel$student,"STUDENT_ID")
  rename_one(sel$age,"AGE")
  rename_one(sel$escs,"ESCS")
  rename_one(sel$immig,"IMMIG")
  rename_one(sel$weight,"W_FSTUWT")

  # Canonical replicate names RW1...RW80.
  for(i in seq_along(sel$reps)) {
    a <- sel$reps[i]
    if(a %in% names(d)) names(d)[match(a,names(d))] <- paste0("RW",num_suffix(a))
  }

  # Preserve PV1READ etc. in canonical uppercase form.
  names(d) <- toupper(names(d))

  if("CNT" %in% names(d)) d$CNT <- toupper(trimws(as.character(d$CNT)))
  if("SCHOOL_ID" %in% names(d)) d$SCHOOL_ID <- as.character(d$SCHOOL_ID)
  if("STUDENT_ID" %in% names(d)) d$STUDENT_ID <- as.character(d$STUDENT_ID)

  d$PISA_YEAR <- as.integer(year)
  d
}

cached_extract_valid <- function(path) {
  if(!file.exists(path)) return(FALSE)
  d <- tryCatch(readRDS(path),error=function(e) NULL)
  if(is.null(d) || !is.data.frame(d)) return(FALSE)

  names(d) <- toupper(names(d))
  n <- names(d)
  core <- c("CNT","SCHOOL_ID","STUDENT_ID","AGE","ESCS","W_FSTUWT")
  pvs <- grep("^PV[0-9]+READ$",n,value=TRUE)
  reps <- grep("^RW[0-9]+$",n,value=TRUE)

  core_ok <- all(core %in% n) && length(pvs)>=5L && length(reps)==80L
  if(!core_ok) {
    rm(d); gc()
    return(FALSE)
  }

  # Scientific/cache integrity guard.  The old 2006/2012 cache had all CNT
  # values missing because the three-letter country code was read as numeric.
  cnt <- toupper(trimws(as.character(d$CNT)))
  valid_cnt <- !is.na(cnt) & grepl("^[A-Z0-9]{3}$",cnt)
  country_codes <- sort(unique(cnt[valid_cnt]))

  school_ok <- sum(!is.na(d$SCHOOL_ID) & nzchar(as.character(d$SCHOOL_ID))) > 100L

  age_raw <- suppressWarnings(as.numeric(d$AGE))
  age_plausible <- is.finite(age_raw) & age_raw >= 14 & age_raw <= 18
  age_ok <- sum(age_plausible) > 1000L &&
    mean(age_plausible[is.finite(age_raw)]) > 0.90 &&
    median(age_raw[age_plausible],na.rm=TRUE) >= 15 &&
    median(age_raw[age_plausible],na.rm=TRUE) <= 16.5

  weight_ok <- sum(is.finite(suppressWarnings(as.numeric(d$W_FSTUWT)))) > 1000L

  ok <- length(country_codes) >= 10L &&
    ("NLD" %in% country_codes) &&
    school_ok && age_ok && weight_ok

  rm(d); gc()
  ok
}


dictionary_from_canonical_cache <- function(d) {
  data.frame(
    variable=toupper(names(d)),
    label=vapply(
      d,
      function(x) clean_label(attr(x,"label",exact=TRUE)),
      character(1)
    ),
    stringsAsFactors=FALSE
  )
}

canonicalise_cached_extract <- function(d,year) {
  names(d) <- toupper(names(d))

  # A cache accepted by cached_extract_valid() already has canonical scientific
  # names.  Never remap its columns by source-file position; doing so can
  # scramble AGE and other fields when source names differ from canonical names.
  if("CNT" %in% names(d)) d$CNT <- toupper(trimws(as.character(d$CNT)))
  if("SCHOOL_ID" %in% names(d)) d$SCHOOL_ID <- as.character(d$SCHOOL_ID)
  if("STUDENT_ID" %in% names(d)) d$STUDENT_ID <- as.character(d$STUDENT_ID)
  d$PISA_YEAR <- as.integer(year)
  d
}

dictionary_and_selection_for_year <- function(year,data_path) {
  if(year %in% c(2006,2012)) {
    control <- src$path[src$year==year & src$role=="control"][1]
    dict <- dictionary_sas_setup(control)
    sel <- select_required(dict)
    return(list(dict=dict,sel=sel))
  }

  if(year %in% c(2015,2018)) {
    kind <- modern_puf_kind(data_path)
    ext <- extract_member(data_path,kind)
    on.exit(unlink(ext$tempdir,recursive=TRUE,force=TRUE),add=TRUE)
    dict <- dictionary_haven(ext$path,kind)
    sel <- select_required(dict)
    return(list(dict=dict,sel=sel))
  }

  if(year==2022) {
    ext <- extract_member(data_path,"sav")
    on.exit(unlink(ext$tempdir,recursive=TRUE,force=TRUE),add=TRUE)
    dict <- dictionary_haven(ext$path,"sav")
    sel <- select_required(dict)
    return(list(dict=dict,sel=sel))
  }

  if(year==2025) {
    p <- data_path; td <- NULL
    if(tolower(tools::file_ext(p))=="zip") {
      ext <- extract_member(p,"sav")
      p <- ext$path; td <- ext$tempdir
      on.exit(unlink(td,recursive=TRUE,force=TRUE),add=TRUE)
    }
    dict <- dictionary_haven(p,"sav")
    sel <- select_required(dict)
    return(list(dict=dict,sel=sel))
  }

  stop("Unsupported year.")
}

read_year <- function(year) {
  cat("\n--- PISA ",year," ---\n",sep="")
  data_path <- src$path[src$year==year & src$role=="data"][1]

  extract_path <- file.path(
    EXTRACT_ROOT,paste0("PISA_",year,"_RC1_STANDARDISED.rds")
  )
  use_cache <- cached_extract_valid(extract_path)

  if(use_cache) {
    cat(
      "RESUME: reusing validated local standardised extract without reopening raw PUF:\n",
      norm(extract_path),"\n",sep=""
    )
    d <- readRDS(extract_path)
    d <- canonicalise_cached_extract(d,year)

    # Preserve a metadata/demography audit without extracting the original
    # 1–2 GB source again.
    dict <- dictionary_from_canonical_cache(d)
    sel <- select_required(dict)
    sel$all <- toupper(names(d))

    # Canonical caches name replicate weights RW1..RW80; include them explicitly
    # in the selected register even though source-file detectors use W_FSTR* /
    # W_FSTURWT*.
    sel$reps <- grep("^RW[0-9]+$",toupper(names(d)),value=TRUE)

  } else if(year %in% c(2006,2012)) {
    control <- src$path[src$year==year & src$role=="control"][1]
    dict <- dictionary_sas_setup(control)
    sel <- select_required(dict)

    if(any(is.na(c(sel$country,sel$school,sel$student,sel$age,sel$escs,sel$weight))) ||
       length(sel$pvs)<5L || length(sel$reps)<80L) {
      write.csv(dict,file.path(OUT,paste0("PISA_",year,"_FULL_DICTIONARY.csv")),row.names=FALSE)
      stop(
        "PISA ",year,": required variables were not all detected in the SAS INPUT block. ",
        "Dictionary exported to ",file.path(OUT,paste0("PISA_",year,"_FULL_DICTIONARY.csv"))
      )
    }

    d <- read_selected_sascii_fwf(
      data_zip=data_path,
      control=control,
      dict=dict,
      selected_vars=sel$all
    )

  } else if(year %in% c(2015,2018)) {
    kind <- modern_puf_kind(data_path)
    ext <- extract_member(data_path,kind)
    on.exit(unlink(ext$tempdir,recursive=TRUE,force=TRUE),add=TRUE)
    dict <- dictionary_haven(ext$path,kind)
    sel <- select_required(dict)

    if(any(is.na(c(sel$country,sel$school,sel$student,sel$age,sel$escs,sel$weight))) ||
       length(sel$pvs)<5L || length(sel$reps)<80L) {
      write.csv(dict,file.path(OUT,paste0("PISA_",year,"_FULL_DICTIONARY.csv")),row.names=FALSE)
      stop("PISA ",year,": required variables were not all detected. Dictionary exported.")
    }

    cat(
      "Reading ",if(kind=="sav")"SPSS" else "SAS",
      " PUF member ",ext$member,
      "; selected columns: ",length(sel$all),"\n",sep=""
    )
    d <- if(kind=="sav") {
      haven::read_sav(
        ext$path,
        col_select=tidyselect::any_of(sel$all)
      )
    } else {
      haven::read_sas(
        ext$path,
        col_select=tidyselect::any_of(sel$all)
      )
    }
    unlink(ext$tempdir,recursive=TRUE,force=TRUE)

  } else if(year==2022) {
    ext <- extract_member(data_path,"sav")
    on.exit(unlink(ext$tempdir,recursive=TRUE,force=TRUE),add=TRUE)
    dict <- dictionary_haven(ext$path,"sav")
    sel <- select_required(dict)
    cat("Reading 2022 SPSS PUF; selected columns: ",length(sel$all),"\n",sep="")
    d <- haven::read_sav(
      ext$path,
      col_select=tidyselect::any_of(sel$all)
    )
    unlink(ext$tempdir,recursive=TRUE,force=TRUE)

  } else if(year==2025) {
    p <- data_path
    if(tolower(tools::file_ext(p))=="zip") {
      ext <- extract_member(p,"sav")
      p <- ext$path
      on.exit(unlink(ext$tempdir,recursive=TRUE,force=TRUE),add=TRUE)
    }
    dict <- dictionary_haven(p,"sav")
    sel <- select_required(dict)
    cat("Reading 2025 SPSS PUF; selected columns: ",length(sel$all),"\n",sep="")
    d <- haven::read_sav(
      p,
      col_select=tidyselect::any_of(sel$all)
    )
  } else stop("Unsupported year.")

  if(!use_cache) {
    d <- normalise_names(d,sel,year)
  }

  # Core validity requirements for RC1 sorting.
  pvs <- grep("^PV[0-9]+READ$",names(d),value=TRUE)
  pvs <- pvs[order(num_suffix(pvs))]
  reps <- grep("^RW[0-9]+$",names(d),value=TRUE)
  reps <- reps[order(num_suffix(reps))]

  required_names <- c("CNT","SCHOOL_ID","STUDENT_ID","AGE","ESCS","W_FSTUWT")
  missing <- setdiff(required_names,names(d))
  if(length(missing)) stop("PISA ",year," missing canonical variables: ",paste(missing,collapse=", "))
  if(length(pvs)<5L) stop("PISA ",year," has fewer than 5 reading PVs after import.")
  if(length(reps)!=80L) stop("PISA ",year," expected 80 replicate weights; found ",length(reps),".")

  cnt_check <- toupper(trimws(as.character(d$CNT)))
  country_codes_check <- sort(unique(
    cnt_check[!is.na(cnt_check) & grepl("^[A-Z0-9]{3}$",cnt_check)]
  ))
  if(length(country_codes_check)<10L || !"NLD" %in% country_codes_check) {
    stop(
      "PISA ",year,
      " country-code integrity check failed after import: found ",
      length(country_codes_check),
      " valid three-character country codes and NLD_present=",
      "NLD" %in% country_codes_check,
      ". The standardised extract was NOT accepted."
    )
  }

  age_raw_check <- suppressWarnings(as.numeric(d$AGE))
  plausible_age_check <- is.finite(age_raw_check) &
    age_raw_check >= 14 & age_raw_check <= 18
  plausible_share <- if(any(is.finite(age_raw_check))) {
    mean(plausible_age_check[is.finite(age_raw_check)])
  } else 0
  plausible_median <- if(any(plausible_age_check)) {
    median(age_raw_check[plausible_age_check],na.rm=TRUE)
  } else NA_real_

  if(sum(plausible_age_check) < 1000L ||
     plausible_share < 0.90 ||
     !is.finite(plausible_median) ||
     plausible_median < 15 || plausible_median > 16.5) {
    stop(
      "PISA ",year,
      " AGE integrity check failed: plausible_share=",
      sprintf("%.3f",plausible_share),
      ", plausible_median=",plausible_median,
      ". Valid PISA ages should be roughly 15–16 years. ",
      "The standardised extract was NOT accepted."
    )
  }

  # Save aggregate dictionary evidence before removing large object later.
  dict$year <- year
  dict$selected_for_rc1 <- dict$variable %in% sel$all
  write.csv(dict,file.path(OUT,paste0("PISA_",year,"_DICTIONARY.csv")),row.names=FALSE)

  demo_vars <- unique(c(
    sel$demo,
    dict$variable[
      grepl(
        "LANG|IMMIG|COBN|BIRTH|BORN|MOTHER.?TONGUE|COUNTRY.?OF.?BIRTH|^ST0?04|SEX|GENDER",
        dict$variable,
        ignore.case=TRUE
      ) |
      grepl(
        "LANGUAGE|IMMIGR|COUNTRY OF BIRTH|BORN IN|MOTHER TONGUE|SEX|GENDER",
        dict$label,
        ignore.case=TRUE
      )
    ]
  ))
  demo_rows <- dict[dict$variable %in% demo_vars,c("year","variable","label"),drop=FALSE]
  write.csv(demo_rows,file.path(OUT,paste0("PISA_",year,"_DEMOGRAPHIC_CANDIDATES.csv")),row.names=FALSE)

  # Save one year-level standardised extract locally. It is deliberately omitted
  # from every upload handoff.
  extract_path <- file.path(EXTRACT_ROOT,paste0("PISA_",year,"_RC1_STANDARDISED.rds"))
  if(!use_cache) {
    saveRDS(d,extract_path,compress=FALSE)
  }

  # Country-level caches make later 8-worker sorting calculations memory-safe.
  cdir <- file.path(EXTRACT_ROOT,paste0("PISA_",year,"_countries"))
  dir.create(cdir,recursive=TRUE,showWarnings=FALSE)
  countries <- sort(unique(
    d$CNT[
      !is.na(d$CNT) &
      grepl("^[A-Z0-9]{3}$",toupper(trimws(as.character(d$CNT))))
    ]
  ))
  for(cc in countries) {
    cp <- file.path(cdir,paste0(cc,".rds"))
    if(!use_cache || !file.exists(cp)) {
      dd <- d[d$CNT==cc,,drop=FALSE]
      saveRDS(dd,cp,compress=FALSE)
    }
  }

  age_rows <- do.call(rbind,lapply(countries,function(cc) {
    x <- d[d$CNT==cc,,drop=FALSE]
    w <- suppressWarnings(as.numeric(x$W_FSTUWT))
    age <- suppressWarnings(as.numeric(x$AGE))
    age[!is.finite(age) | age < 14 | age > 18] <- NA_real_
    data.frame(
      pisa_wave=year,
      source_country_code=cc,
      mean_age=wmean(age,w),
      age_nonmissing_n=sum(is.finite(age)&is.finite(w)&w>0),
      n_students=nrow(x),
      stringsAsFactors=FALSE
    )
  }))

  out <- data.frame(
    year=year,
    rows=nrow(d),
    countries=length(countries),
    reading_pvs=length(pvs),
    replicate_weights=length(reps),
    ESCS="ESCS" %in% names(d),
    IMMIG="IMMIG" %in% names(d),
    age="AGE" %in% names(d),
    resumed_from_cache=use_cache,
    extract_path=norm(extract_path),
    stringsAsFactors=FALSE
  )

  rm(d); gc()
  list(summary=out,age=age_rows,dictionary=dict,demo=demo_rows)
}

pisa_years <- c(2006,2012,2015,2018,2022,2025)
year_results <- list()
for(yr in pisa_years) year_results[[as.character(yr)]] <- read_year(yr)

pisa_summary <- do.call(rbind,lapply(year_results,`[[`,"summary"))
pisa_age <- do.call(rbind,lapply(year_results,`[[`,"age"))
pisa_demo <- do.call(rbind,lapply(year_results,`[[`,"demo"))

write.csv(pisa_summary,file.path(OUT,"PISA_RC1_STANDARDISATION_SUMMARY.csv"),row.names=FALSE)
write.csv(pisa_age,file.path(OUT,"PISA_RC1_COUNTRY_AGE_SUMMARY.csv"),row.names=FALSE)
write.csv(pisa_demo,file.path(OUT,"PISA_RC1_DEMOGRAPHIC_VARIABLE_CANDIDATES.csv"),row.names=FALSE)

# -----------------------------------------------------------------------------
# PIRLS empirical ages, using target-population files only
# -----------------------------------------------------------------------------

target_files <- list.files(
  ROOT,pattern="^PIRLS_dashboard_target_population_audit\\.csv$",
  recursive=TRUE,full.names=TRUE,ignore.case=TRUE
)
if(!length(target_files)) stop("PIRLS target-population audit not found.")
target_files <- target_files[order(file.info(target_files)$mtime,decreasing=TRUE)]
ta <- read.csv(target_files[1],check.names=FALSE,stringsAsFactors=FALSE)

exc <- if(is.logical(ta$exclude_dashboard)) ta$exclude_dashboard else
  toupper(as.character(ta$exclude_dashboard)) %in% c("TRUE","T","1","YES")
pt <- ta[!exc,,drop=FALSE]
pt$local_path <- norm(pt$local_path)
pt <- pt[file.exists(pt$local_path),,drop=FALSE]
if(!"source_country_code" %in% names(pt))
  pt$source_country_code <- toupper(sub("^ASG([A-Z0-9]{3}).*$","\\1",basename(pt$local_path)))

pirls_age_worker <- function(row) {
  yr <- as.integer(row[["year"]]); p <- as.character(row[["local_path"]])
  code <- toupper(as.character(row[["source_country_code"]]))
  age_var <- if(yr==2001) "ASDGAGE" else "ASDAGE"
  tryCatch({
    d <- haven::read_sav(
      p,col_select=tidyselect::any_of(c(age_var,"TOTWGT"))
    )
    if(!all(c(age_var,"TOTWGT") %in% names(d))) stop(age_var,"/TOTWGT missing")
    a <- suppressWarnings(as.numeric(d[[age_var]]))
    w <- suppressWarnings(as.numeric(d$TOTWGT))
    a[a<6|a>20] <- NA_real_
    data.frame(
      pirls_wave=yr,source_country_code=code,age_variable=age_var,
      mean_age=wmean(a,w),
      age_nonmissing_n=sum(is.finite(a)&is.finite(w)&w>0),
      status="ok",stringsAsFactors=FALSE
    )
  },error=function(e) {
    data.frame(
      pirls_wave=yr,source_country_code=code,age_variable=age_var,
      mean_age=NA_real_,age_nonmissing_n=0,
      status=paste0("ERROR: ",conditionMessage(e)),stringsAsFactors=FALSE
    )
  })
}

rows <- split(pt,seq_len(nrow(pt)))
attempts <- unique(c(min(IO_WORKERS,length(rows)),4L,2L,1L))
attempts <- attempts[attempts>=1L & attempts<=max(1L,length(rows))]
pirls_list <- NULL
parallel_mode <- NA_character_

for(nw in attempts) {
  cat("\nPIRLS age audit: trying ",nw,if(nw==1)" sequential worker...\n" else " PSOCK workers...\n",sep="")
  if(nw==1L) {
    ans <- tryCatch(lapply(rows,pirls_age_worker),error=function(e)e)
  } else {
    worker_log <- file.path(OUT,paste0("PSOCK_PIRLS_AGE_",nw,"workers.log"))
    cl <- NULL
    ans <- tryCatch({
      cl <- parallel::makePSOCKcluster(nw,outfile=worker_log)
      parallel::clusterEvalQ(cl,suppressPackageStartupMessages({
        library(haven); library(tidyselect)
      }))
      parallel::clusterExport(cl,c("wmean","pirls_age_worker"),envir=environment())
      parallel::parLapplyLB(cl,rows,pirls_age_worker)
    },error=function(e)e,
    finally={if(!is.null(cl)) try(parallel::stopCluster(cl),silent=TRUE)})
  }
  if(!inherits(ans,"error")) {
    pirls_list <- ans
    parallel_mode <- if(nw==1)"sequential_fallback" else paste0("PSOCK_",nw)
    break
  }
  cat("  failed: ",conditionMessage(ans),"\n",sep="")
}

if(is.null(pirls_list)) stop("PIRLS age audit failed after fallback.")
pirls_age <- do.call(rbind,pirls_list)
write.csv(pirls_age,file.path(OUT,"PIRLS_RC1_COUNTRY_AGE_SUMMARY.csv"),row.names=FALSE)

# -----------------------------------------------------------------------------
# Map both surveys to stable dashboard country/system IDs
# -----------------------------------------------------------------------------

ccfile <- file.path(ROOT,"11_dashboard_bundle_v2","country_source_codes.csv")
cc <- read.csv(ccfile,check.names=FALSE,stringsAsFactors=FALSE)

map_pisa <- cc[cc$survey=="PISA",c("source_country_code","country_id"),drop=FALSE]
map_pirls <- cc[cc$survey=="PIRLS",c("source_country_code","country_id"),drop=FALSE]
map_pisa$source_country_code <- toupper(map_pisa$source_country_code)
map_pirls$source_country_code <- toupper(map_pirls$source_country_code)
map_pisa <- map_pisa[!duplicated(map_pisa$source_country_code),]
map_pirls <- map_pirls[!duplicated(map_pirls$source_country_code),]

pisa_age <- merge(pisa_age,map_pisa,by="source_country_code",all.x=TRUE,sort=FALSE)
pirls_age <- merge(pirls_age,map_pirls,by="source_country_code",all.x=TRUE,sort=FALSE)
write.csv(pisa_age,file.path(OUT,"PISA_RC1_COUNTRY_AGE_SUMMARY_MAPPED.csv"),row.names=FALSE)
write.csv(pirls_age,file.path(OUT,"PIRLS_RC1_COUNTRY_AGE_SUMMARY_MAPPED.csv"),row.names=FALSE)

# -----------------------------------------------------------------------------
# Empirical cohort-pair registry: locked pair roles, empirical age gaps
# -----------------------------------------------------------------------------

pair_design <- data.frame(
  pair_id=c(
    "PIRLS2001_PISA2006_MAIN",
    "PIRLS2006_PISA2012_MAIN",
    "PIRLS2011_PISA2015_MAIN",
    "PIRLS2011_PISA2018_ROBUST",
    "PIRLS2016_PISA2022_MAIN",
    "PIRLS2021_PISA2025_CURRENT"
  ),
  younger_wave=c(2001,2006,2011,2011,2016,2021),
  older_wave=c(2006,2012,2015,2018,2022,2025),
  pair_role=c(
    "main_pseudo_cohort","main_pseudo_cohort","main_pseudo_cohort",
    "robustness_literature_comparator","main_pseudo_cohort",
    "current_system_comparison"
  ),
  use_for_main_delta=c(TRUE,TRUE,TRUE,FALSE,TRUE,FALSE),
  stringsAsFactors=FALSE
)

member_rows <- list()
summary_rows <- list()

for(i in seq_len(nrow(pair_design))) {
  pr <- pair_design[i,]
  y <- pirls_age[pirls_age$pirls_wave==pr$younger_wave &
                   !is.na(pirls_age$country_id) & is.finite(pirls_age$mean_age),]
  o <- pisa_age[pisa_age$pisa_wave==pr$older_wave &
                  !is.na(pisa_age$country_id) & is.finite(pisa_age$mean_age),]
  m <- merge(
    y[,c("country_id","source_country_code","mean_age")],
    o[,c("country_id","source_country_code","mean_age")],
    by="country_id",suffixes=c("_pirls","_pisa")
  )
  if(nrow(m)) {
    m$pair_id <- pr$pair_id
    m$younger_wave <- pr$younger_wave
    m$older_wave <- pr$older_wave
    m$age_gap_years <- m$mean_age_pisa-m$mean_age_pirls
    # With mid-year timing as a transparent common approximation, zero means
    # the implied birth cohorts coincide.
    m$birth_cohort_gap_proxy_years <-
      (pr$older_wave-pr$younger_wave)-m$age_gap_years
    m$abs_birth_cohort_gap_proxy_years <- abs(m$birth_cohort_gap_proxy_years)
    member_rows[[i]] <- m
    summary_rows[[i]] <- data.frame(
      pair_id=pr$pair_id,
      pair_role=pr$pair_role,
      younger_wave=pr$younger_wave,
      older_wave=pr$older_wave,
      n_common_age_systems=nrow(m),
      median_pirls_age=median(m$mean_age_pirls,na.rm=TRUE),
      median_pisa_age=median(m$mean_age_pisa,na.rm=TRUE),
      median_birth_cohort_gap_proxy_years=median(m$birth_cohort_gap_proxy_years,na.rm=TRUE),
      median_abs_birth_cohort_gap_proxy_years=median(m$abs_birth_cohort_gap_proxy_years,na.rm=TRUE),
      p90_abs_birth_cohort_gap_proxy_years=unname(quantile(m$abs_birth_cohort_gap_proxy_years,.90,na.rm=TRUE)),
      use_for_main_delta=pr$use_for_main_delta,
      stringsAsFactors=FALSE
    )
  }
}

pair_members <- do.call(rbind,member_rows)
pair_summary <- do.call(rbind,summary_rows)
write.csv(pair_members,file.path(OUT,"COHORT_PAIR_MEMBERS_EMPIRICAL_v1.csv"),row.names=FALSE)
write.csv(pair_summary,file.path(OUT,"COHORT_PAIR_REGISTRY_EMPIRICAL_v1.csv"),row.names=FALSE)

# -----------------------------------------------------------------------------
# Readiness report
# -----------------------------------------------------------------------------

readiness <- do.call(rbind,lapply(pisa_years,function(yr) {
  z <- pisa_summary[pisa_summary$year==yr,,drop=FALSE]
  data.frame(
    year=yr,
    source_normalised=nrow(z)==1L,
    countries=if(nrow(z))z$countries else NA,
    reading_pvs=if(nrow(z))z$reading_pvs else NA,
    replicate_weights=if(nrow(z))z$replicate_weights else NA,
    ESCS=if(nrow(z))z$ESCS else FALSE,
    age=if(nrow(z))z$age else FALSE,
    ready_for_social_sorting=nrow(z)==1L && isTRUE(z$ESCS) && z$replicate_weights==80,
    ready_for_academic_sorting=nrow(z)==1L && z$reading_pvs>=5 && z$replicate_weights==80,
    stringsAsFactors=FALSE
  )
}))
write.csv(readiness,file.path(OUT,"PISA_RC1_SORTING_READINESS.csv"),row.names=FALSE)

# A concise human-readable report.
writeLines(c(
  "PISA/PIRLS RC1 HISTORICAL NORMALISATION + COHORT AUDIT",
  paste0("Created: ",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  paste0("PIRLS parallel mode: ",parallel_mode),
  "",
  "Historical PISA student PUFs were normalised locally; cache integrity requires valid country codes and plausible PISA ages; validated canonical caches are resumed without reopening or remapping raw PUF columns; SPSS is preferred for PISA 2015/2018 when present; large ZIP members use a libarchive/7-Zip extraction cascade; no microdata are included in the handoff.",
  "The next RC1 stage may compute social and academic school sorting from the local country caches.",
  "Demographic variables remain candidates until their value labels/definitions are harmonised.",
  "",
  paste0("Standardised extract root: ",norm(EXTRACT_ROOT))
),file.path(OUT,"README_RESULTS.txt"))

# -----------------------------------------------------------------------------
# Verified metadata-only handoff ZIP
# -----------------------------------------------------------------------------

# Explicitly include only files from OUT; OUT contains no microdata extracts.
files <- list.files(OUT,recursive=TRUE,full.names=TRUE,all.files=TRUE,no..=TRUE)
ii <- file.info(files)
files <- files[!is.na(ii$isdir)&!ii$isdir]
# Defensive exclusion if a future edit accidentally writes an RDS here.
files <- files[!grepl("\\.(rds|sav|sas7bdat|dat)$",files,ignore.case=TRUE)]

manifest <- data.frame(
  relative_path=substring(norm(files),nchar(norm(OUT))+2L),
  bytes=file.info(files)$size,
  md5=unname(tools::md5sum(files)),
  stringsAsFactors=FALSE
)
write.csv(manifest,file.path(OUT,"HANDOFF_MANIFEST.csv"),row.names=FALSE)

files <- list.files(OUT,recursive=TRUE,full.names=TRUE,all.files=TRUE,no..=TRUE)
ii <- file.info(files); files <- files[!is.na(ii$isdir)&!ii$isdir]
files <- files[!grepl("\\.(rds|sav|sas7bdat|dat)$",files,ignore.case=TRUE)]
stage_n <- length(files); stage_bytes <- sum(file.info(files)$size)

zipfile <- file.path(HANDOFF_DIR,paste0("PISA_PIRLS_RC1_NORMALISATION_COHORT_",STAMP,".zip"))
ps_quote <- function(x) gsub("'","''",normalizePath(x,winslash="\\",mustWork=FALSE),fixed=TRUE)
ps1 <- file.path(tempdir(),paste0("rc1_norm_zip_",STAMP,".ps1"))
ps <- c(
  "$ErrorActionPreference = 'Stop'",
  "Add-Type -AssemblyName System.IO.Compression",
  "Add-Type -AssemblyName System.IO.Compression.FileSystem",
  paste0("$src = '",ps_quote(OUT),"'"),
  paste0("$dst = '",ps_quote(zipfile),"'"),
  "if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Force }",
  "$fs = [System.IO.File]::Open($dst,[System.IO.FileMode]::CreateNew)",
  "$zip = New-Object System.IO.Compression.ZipArchive($fs,[System.IO.Compression.ZipArchiveMode]::Create,$false)",
  "try {",
  "  $files = Get-ChildItem -LiteralPath $src -File -Recurse | Where-Object { $_.Extension -notmatch '^\\.(rds|sav|sas7bdat|dat)$' } | Sort-Object FullName",
  "  foreach ($f in $files) {",
  "    $rel=$f.FullName.Substring($src.Length).TrimStart([char[]]'\\/').Replace('\\','/')",
  "    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$f.FullName,$rel,[System.IO.Compression.CompressionLevel]::Optimal)|Out-Null",
  "  }",
  "} finally { $zip.Dispose(); $fs.Dispose() }"
)
writeLines(ps,ps1,useBytes=TRUE)
powershell <- Sys.which("powershell"); if(!nzchar(powershell)) powershell <- Sys.which("powershell.exe")
if(!nzchar(powershell)) stop("PowerShell not found; result files were created but not zipped.")
res <- system2(powershell,args=c("-NoProfile","-NonInteractive","-ExecutionPolicy","Bypass","-File",shQuote(ps1)),
               stdout=TRUE,stderr=TRUE)
st <- attr(res,"status"); if(is.null(st)) st <- 0L
if(st!=0L || !file.exists(zipfile)) stop("Metadata handoff ZIP creation failed.")

zl <- utils::unzip(zipfile,list=TRUE)
zf <- zl[!grepl("/$",zl$Name),,drop=FALSE]
if(nrow(zf)!=stage_n || sum(as.numeric(zf$Length))!=stage_bytes) {
  file.remove(zipfile)
  stop("Handoff ZIP verification failed; ZIP deleted.")
}

cat("\n============================================================\n")
cat("RC1 NORMALISATION + EMPIRICAL COHORT AUDIT COMPLETE\n")
cat("============================================================\n")
print(readiness,row.names=FALSE)
cat("\nEmpirical cohort-pair summary:\n")
print(pair_summary,row.names=FALSE)
cat("\nUPLOAD ONLY THIS SMALL ZIP:\n",norm(zipfile),"\n",sep="")
cat("Do NOT upload the local standardised RDS extracts or raw OECD PUFs.\n")
