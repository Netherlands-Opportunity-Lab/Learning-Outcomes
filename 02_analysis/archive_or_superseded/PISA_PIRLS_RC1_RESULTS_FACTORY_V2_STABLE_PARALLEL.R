# =============================================================================
# PISA/PIRLS RC1 RESULTS FACTORY
# Version 2.0 STABLE PARALLEL — 20 September 2026
#
# PURPOSE
#   Compute the remaining high-priority RC1 reading results from the already
#   normalised local PISA caches and validated PIRLS target-population files:
#
#   PISA:
#   - national ESCS Q1/Q4 mean reading scores
#   - national ESCS Q1/Q4 Level-2 shares
#   - score/proficiency gaps
#   - social school sorting (rank-based + raw-ESCS validation diagnostic)
#   - academic school sorting (all reading PVs)
#
#   PIRLS:
#   - social school + classroom sorting using books-at-home rank
#   - academic school + classroom sorting using all five reading PVs
#
#   CROSS-AGE:
#   - pair-specific common panels
#   - social/academic sorting changes from ≈10 to 15
#   - fixed intersection panel across all main pseudo-cohort pairs
#   - latest-wave maximum identical country set for SES score/proficiency gaps
#
#   AUDIT:
#   - PISA SES validation against already-validated official 2015+ Level-2 data
#   - sample/cluster/missingness diagnostics
#   - demographic-variable harmonisation inputs (NO demographic main result yet)
#
# SCIENTIFIC LOCKS
#   - no raw PISA-minus-PIRLS score differences
#   - same conceptual sorting estimator at both ages
#   - levels retained alongside gaps
#   - demographic variables remain non-publishable until harmonised
#   - frontend/deck must consume frozen outputs, not recalculate estimates
#
# PARALLEL POLICY
#   Laptop: 10 physical / 12 logical cores
#   - PISA cached country×wave tasks: max 8 PSOCK workers
#   - PIRLS SAV + compute tasks: max 6 PSOCK workers
#   - replicate/PV loops stay inside each country×wave worker
#   - run-specific worker logs, never outfile=""
#   - country×wave result caches make reruns resumable
#
# RAW DATA
#   No raw microdata are copied into the handoff ZIP.
# =============================================================================

options(stringsAsFactors=FALSE)

DOWNLOADS <- normalizePath(file.path(Sys.getenv("USERPROFILE"),"Downloads"),winslash="/",mustWork=TRUE)
ROOT <- file.path(DOWNLOADS,"PISA_PIRLS_MASTER_PIPELINE")
if(!dir.exists(ROOT)) stop("Project root not found: ",ROOT)

if(!requireNamespace("haven",quietly=TRUE))
  stop("Package haven is required.")

PHYSICAL_CORES <- suppressWarnings(parallel::detectCores(logical=FALSE))
LOGICAL_CORES <- suppressWarnings(parallel::detectCores(logical=TRUE))
if(is.na(PHYSICAL_CORES) || PHYSICAL_CORES<2L)
  PHYSICAL_CORES <- max(2L,LOGICAL_CORES-2L)

CPU_WORKERS <- max(2L,min(8L,PHYSICAL_CORES-2L))
IO_WORKERS  <- max(2L,min(6L,PHYSICAL_CORES-2L))

PISA_LEVEL2 <- 407.47
FAY_VARIANCE_FACTOR <- 1/20  # 80 BRR-Fay reps, Fay=.5
STAMP <- format(Sys.time(),"%Y%m%d_%H%M%S")

OUT_ROOT <- file.path(ROOT,"16_rc1_results_factory")
OUT <- file.path(OUT_ROOT,paste0("run_",STAMP))
CACHE_ROOT <- file.path(OUT_ROOT,"cache_v1")
PISA_CACHE <- file.path(CACHE_ROOT,"PISA")
PIRLS_CACHE <- file.path(CACHE_ROOT,"PIRLS")
HANDOFF_DIR <- file.path(ROOT,"RUNNER","handoffs")
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
dir.create(PISA_CACHE,recursive=TRUE,showWarnings=FALSE)
dir.create(PIRLS_CACHE,recursive=TRUE,showWarnings=FALSE)
dir.create(HANDOFF_DIR,recursive=TRUE,showWarnings=FALSE)

norm <- function(x) normalizePath(x,winslash="/",mustWork=FALSE)
safe_num <- function(x) suppressWarnings(as.numeric(x))

cat("\n============================================================\n")
cat("PISA/PIRLS RC1 RESULTS FACTORY V1\n")
cat("============================================================\n")
cat("Detected cores: ",PHYSICAL_CORES," physical / ",LOGICAL_CORES," logical\n",sep="")
cat("PISA CPU workers: ",CPU_WORKERS,"\n",sep="")
cat("PIRLS I/O+CPU workers: ",IO_WORKERS,"\n",sep="")
open_conn <- tryCatch(
  nrow(showConnections(all=TRUE)),
  error=function(e) NA_integer_
)
cat("Open R connections at start: ",open_conn,"\n\n",sep="")
gc()

# =============================================================================
# 1. GENERIC WEIGHTED / SURVEY HELPERS
# =============================================================================

wmean <- function(x,w) {
  x <- safe_num(x); w <- safe_num(w)
  ok <- is.finite(x)&is.finite(w)&w>0
  if(!any(ok)) return(NA_real_)
  sum(x[ok]*w[ok])/sum(w[ok])
}

wvar_pop <- function(x,w) {
  x <- safe_num(x); w <- safe_num(w)
  ok <- is.finite(x)&is.finite(w)&w>0
  if(sum(ok)<2L) return(NA_real_)
  x <- x[ok]; w <- w[ok]
  m <- sum(w*x)/sum(w)
  sum(w*(x-m)^2)/sum(w)
}

weighted_midrank <- function(x,w) {
  x <- safe_num(x); w <- safe_num(w)
  out <- rep(NA_real_,length(x))
  ok <- is.finite(x)&is.finite(w)&w>0
  if(!any(ok)) return(out)

  xx <- x[ok]; ww <- w[ok]
  u <- sort(unique(xx))
  gw <- vapply(u,function(v) sum(ww[xx==v]),numeric(1))
  before <- c(0,cumsum(gw))[seq_along(gw)]
  rr <- (before + .5*gw)/sum(gw)
  map <- setNames(rr,as.character(u))
  out[ok] <- unname(map[as.character(xx)])
  out
}

weighted_fractional_tails <- function(x,w,target=.25) {
  x <- safe_num(x); w <- safe_num(w)
  q1 <- q4 <- rep(0,length(x))
  ok <- is.finite(x)&is.finite(w)&w>0
  if(!any(ok))
    return(list(q1=q1,q4=q4,valid_weight=0))

  xx <- x[ok]; ww <- w[ok]
  vals <- sort(unique(xx))
  W <- vapply(vals,function(v) sum(ww[xx==v]),numeric(1))
  total <- sum(W); need <- target*total
  lo_frac <- hi_frac <- rep(0,length(vals))

  rem <- need
  for(j in seq_along(vals)) {
    if(rem<=0) break
    if(W[j]<=rem+1e-12) {
      lo_frac[j] <- if(W[j]>0) 1 else 0
      rem <- rem-W[j]
    } else if(W[j]>0) {
      lo_frac[j] <- rem/W[j]
      rem <- 0
    }
  }

  rem <- need
  for(j in rev(seq_along(vals))) {
    if(rem<=0) break
    if(W[j]<=rem+1e-12) {
      hi_frac[j] <- if(W[j]>0) 1 else 0
      rem <- rem-W[j]
    } else if(W[j]>0) {
      hi_frac[j] <- rem/W[j]
      rem <- 0
    }
  }

  lo_map <- setNames(lo_frac,as.character(vals))
  hi_map <- setNames(hi_frac,as.character(vals))
  q1[ok] <- unname(lo_map[as.character(xx)])
  q4[ok] <- unname(hi_map[as.character(xx)])

  # exact weighted-tail integrity check
  if(abs(sum(w*q1,na.rm=TRUE)/total-target)>1e-8 ||
     abs(sum(w*q4,na.rm=TRUE)/total-target)>1e-8)
    stop("Fractional tail construction failed.")

  list(q1=q1,q4=q4,valid_weight=total)
}

between_share <- function(y,cluster,w) {
  y <- safe_num(y); w <- safe_num(w)
  cl <- as.character(cluster)
  ok <- is.finite(y)&is.finite(w)&w>0&!is.na(cl)&nzchar(cl)
  if(sum(ok)<10L) return(NA_real_)

  y <- y[ok]; w <- w[ok]; cl <- cl[ok]
  mu <- sum(w*y)/sum(w)
  tv <- sum(w*(y-mu)^2)/sum(w)
  if(!is.finite(tv) || tv<=0) return(NA_real_)

  sw <- as.numeric(rowsum(w,cl,reorder=FALSE))
  sy <- as.numeric(rowsum(w*y,cl,reorder=FALSE))
  gm <- sy/sw
  bv <- sum(sw*(gm-mu)^2)/sum(sw)
  100*bv/tv
}

brr_variance <- function(full,reps) {
  reps <- safe_num(reps)
  ok <- is.finite(reps)&is.finite(full)
  if(sum(ok)<60L) return(NA_real_)
  FAY_VARIANCE_FACTOR*sum((reps[ok]-full)^2)
}

jk2_variance <- function(full,reps) {
  reps <- safe_num(reps)
  ok <- is.finite(reps)&is.finite(full)
  if(sum(ok)<2L) return(NA_real_)
  .5*sum((reps[ok]-full)^2)
}

combine_pv <- function(theta_m,U_m) {
  theta_m <- safe_num(theta_m); U_m <- safe_num(U_m)
  ok <- is.finite(theta_m)
  if(!any(ok))
    return(c(estimate=NA,se=NA,sampling_variance=NA,
             pv_imputation_variance=NA,total_variance=NA))
  th <- mean(theta_m[ok])
  U <- if(any(is.finite(U_m))) mean(U_m[is.finite(U_m)]) else NA_real_
  B <- if(sum(ok)>=2L) stats::var(theta_m[ok]) else 0
  M <- sum(ok)
  imp <- (1+1/M)*B
  tot <- if(is.finite(U)) U+imp else NA_real_
  se <- if(is.finite(tot)) sqrt(tot) else NA_real_
  c(estimate=th,se=se,sampling_variance=U,
    pv_imputation_variance=imp,total_variance=tot)
}

# =============================================================================
# ROBUST WINDOWS PSOCK RUNNER
# =============================================================================

run_tasks_stable <- function(
  rows,
  worker_fun,
  preferred_workers,
  export_names,
  export_env,
  worker_packages=character(),
  log_prefix="PSOCK"
) {
  if(!length(rows)) return(list())

  # On this laptop: 8 is preferred for CPU-heavy country×wave jobs,
  # 6 for I/O-heavy jobs.  If Windows/RStudio socket startup is unstable,
  # retry automatically with fewer workers.  The country×wave caches make
  # retries cheap because completed tasks are reused.
  attempts <- unique(c(
    as.integer(preferred_workers),
    if(preferred_workers>=8L) 6L else preferred_workers,
    4L,2L,1L
  ))
  attempts <- attempts[
    is.finite(attempts) & attempts>=1L & attempts<=length(rows)
  ]

  last_error <- NULL

  for(nw in attempts) {
    cat(
      log_prefix,": trying ",nw,
      if(nw==1L) " sequential worker...\n" else " PSOCK workers...\n",
      sep=""
    )

    if(nw==1L) {
      ans <- tryCatch(
        lapply(rows,worker_fun),
        error=function(e)e
      )
    } else {
      worker_log <- file.path(
        OUT,
        paste0(log_prefix,"_",nw,"workers.log")
      )
      cl_local <- NULL

      ans <- tryCatch({
        cl_local <- parallel::makePSOCKcluster(
          nw,
          outfile=worker_log
        )

        # Smoke-test connections before exporting large function sets.
        smoke <- parallel::clusterCall(cl_local,function() TRUE)
        if(length(smoke)!=nw || !all(vapply(smoke,isTRUE,logical(1))))
          stop("PSOCK smoke test failed.")

        if(length(worker_packages)) {
          pkgs <- worker_packages
          parallel::clusterExport(
            cl_local,"pkgs",envir=environment()
          )
          parallel::clusterEvalQ(
            cl_local,
            for(p in pkgs)
              suppressPackageStartupMessages(
                library(p,character.only=TRUE)
              )
          )
        }

        parallel::clusterExport(
          cl_local,
          export_names,
          envir=export_env
        )

        parallel::parLapplyLB(
          cl_local,
          rows,
          worker_fun
        )
      },
      error=function(e)e,
      finally={
        if(!is.null(cl_local))
          try(parallel::stopCluster(cl_local),silent=TRUE)
      })
    }

    if(!inherits(ans,"error")) {
      cat(log_prefix,": succeeded with ",nw," worker(s).\n",sep="")
      attr(ans,"workers_used") <- nw
      return(ans)
    }

    last_error <- ans
    cat(
      log_prefix,": attempt with ",nw," worker(s) failed: ",
      conditionMessage(ans),"\n",sep=""
    )
    if(nw>1L)
      cat("Automatically retrying with fewer workers; completed country caches will be reused.\n")
  }

  stop(
    log_prefix,
    " failed after all automatic worker fallbacks. Last error: ",
    if(is.null(last_error)) "unknown" else conditionMessage(last_error)
  )
}

# =============================================================================
# 2. MAPPINGS / EXISTING VALIDATED BACKEND
# =============================================================================

BUNDLE <- file.path(ROOT,"11_dashboard_bundle_v2")
if(!dir.exists(BUNDLE))
  stop("Dashboard bundle v2 not found: ",BUNDLE)

country_map <- utils::read.csv(
  file.path(BUNDLE,"country_source_codes.csv"),
  stringsAsFactors=FALSE,check.names=FALSE
)
country_map$source_country_code <- toupper(country_map$source_country_code)

map_country_id <- function(code,survey) {
  z <- country_map[
    country_map$survey==survey &
      country_map$source_country_code==toupper(code),
    "country_id",drop=TRUE
  ]
  if(length(z)) z[1] else NA_character_
}

existing_obs <- utils::read.csv(
  file.path(BUNDLE,"observations.csv"),
  stringsAsFactors=FALSE,check.names=FALSE
)

# =============================================================================
# 3. PISA COUNTRY×WAVE ESTIMATOR
# =============================================================================

pisa_pv_stat_vector <- function(y,d,w,q1frac,q4frac) {
  q1w <- w*q1frac
  q4w <- w*q4frac

  c(
    overall_mean=wmean(y,w),
    overall_prof2=wmean(as.numeric(y>=PISA_LEVEL2),w),
    q1_mean=wmean(y,q1w),
    q4_mean=wmean(y,q4w),
    score_gap=wmean(y,q4w)-wmean(y,q1w),
    q1_prof2=wmean(as.numeric(y>=PISA_LEVEL2),q1w),
    q4_prof2=wmean(as.numeric(y>=PISA_LEVEL2),q4w),
    prof_gap=wmean(as.numeric(y>=PISA_LEVEL2),q4w)-
      wmean(as.numeric(y>=PISA_LEVEL2),q1w),
    academic_school_sorting_share=between_share(y,d$SCHOOL_ID,w)
  )
}

pisa_country_worker <- function(task) {
  year <- as.integer(task$year)
  cc <- as.character(task$source_country_code)
  f <- as.character(task$path)
  cache <- as.character(task$cache)

  if(file.exists(cache)) {
    x <- tryCatch(readRDS(cache),error=function(e)NULL)
    if(is.list(x) && identical(x$cache_version,"pisa_rc1_v1"))
      return(x)
  }

  d <- readRDS(f)
  names(d) <- toupper(names(d))
  need <- c("CNT","SCHOOL_ID","ESCS","W_FSTUWT")
  if(!all(need %in% names(d)))
    stop(year," ",cc,": missing ",paste(setdiff(need,names(d)),collapse=", "))

  pv <- grep("^PV[0-9]+READ$",names(d),value=TRUE)
  pv <- pv[order(suppressWarnings(as.integer(sub("^PV([0-9]+)READ$","\\1",pv))))]
  rw <- grep("^RW[0-9]+$",names(d),value=TRUE)
  rw <- rw[order(suppressWarnings(as.integer(sub("^RW([0-9]+)$","\\1",rw))))]
  if(length(pv)<5L || length(rw)!=80L)
    stop(year," ",cc,": PV/replicate count failed.")

  w0 <- safe_num(d$W_FSTUWT)
  escs <- safe_num(d$ESCS)
  tails <- weighted_fractional_tails(escs,w0,.25)
  q1frac <- tails$q1
  q4frac <- tails$q4

  # PV-dependent statistics
  theta <- list()
  Um <- list()

  for(m in seq_along(pv)) {
    y <- safe_num(d[[pv[m]]])
    full <- pisa_pv_stat_vector(y,d,w0,q1frac,q4frac)

    repmat <- matrix(
      NA_real_,nrow=length(rw),ncol=length(full),
      dimnames=list(rw,names(full))
    )
    for(r in seq_along(rw)) {
      wr <- safe_num(d[[rw[r]]])
      repmat[r,] <- pisa_pv_stat_vector(y,d,wr,q1frac,q4frac)
    }

    theta[[m]] <- full
    Um[[m]] <- vapply(
      seq_along(full),
      function(j) brr_variance(full[j],repmat[,j]),
      numeric(1)
    )
    names(Um[[m]]) <- names(full)
  }

  theta_mat <- do.call(rbind,theta)
  U_mat <- do.call(rbind,Um)
  outrows <- lapply(colnames(theta_mat),function(nm) {
    ccmb <- combine_pv(theta_mat[,nm],U_mat[,nm])
    data.frame(
      survey="PISA",year=year,source_country_code=cc,
      country_id=map_country_id(cc,"PISA"),
      statistic=nm,
      estimate=unname(ccmb["estimate"]),
      se=unname(ccmb["se"]),
      ci_low=unname(ccmb["estimate"]-1.96*ccmb["se"]),
      ci_high=unname(ccmb["estimate"]+1.96*ccmb["se"]),
      sampling_variance=unname(ccmb["sampling_variance"]),
      pv_imputation_variance=unname(ccmb["pv_imputation_variance"]),
      total_variance=unname(ccmb["total_variance"]),
      stringsAsFactors=FALSE
    )
  })
  pv_results <- do.call(rbind,outrows)

  # Social sorting: rank-based primary + raw ESCS diagnostic.
  rank0 <- weighted_midrank(escs,w0)
  social_rank_full <- between_share(rank0,d$SCHOOL_ID,w0)
  social_raw_full <- between_share(escs,d$SCHOOL_ID,w0)

  social_rank_rep <- social_raw_rep <- rep(NA_real_,length(rw))
  for(r in seq_along(rw)) {
    wr <- safe_num(d[[rw[r]]])
    rr <- weighted_midrank(escs,wr)
    social_rank_rep[r] <- between_share(rr,d$SCHOOL_ID,wr)
    social_raw_rep[r] <- between_share(escs,d$SCHOOL_ID,wr)
  }
  vrank <- brr_variance(social_rank_full,social_rank_rep)
  vraw <- brr_variance(social_raw_full,social_raw_rep)

  social_results <- rbind(
    data.frame(
      survey="PISA",year=year,source_country_code=cc,
      country_id=map_country_id(cc,"PISA"),
      statistic="social_rank_school_sorting_share",
      estimate=social_rank_full,se=sqrt(vrank),
      ci_low=social_rank_full-1.96*sqrt(vrank),
      ci_high=social_rank_full+1.96*sqrt(vrank),
      sampling_variance=vrank,pv_imputation_variance=0,
      total_variance=vrank,stringsAsFactors=FALSE
    ),
    data.frame(
      survey="PISA",year=year,source_country_code=cc,
      country_id=map_country_id(cc,"PISA"),
      statistic="social_raw_escs_school_sorting_share",
      estimate=social_raw_full,se=sqrt(vraw),
      ci_low=social_raw_full-1.96*sqrt(vraw),
      ci_high=social_raw_full+1.96*sqrt(vraw),
      sampling_variance=vraw,pv_imputation_variance=0,
      total_variance=vraw,stringsAsFactors=FALSE
    )
  )

  diag <- data.frame(
    survey="PISA",year=year,source_country_code=cc,
    country_id=map_country_id(cc,"PISA"),
    n_students=nrow(d),
    n_schools=length(unique(as.character(d$SCHOOL_ID[
      !is.na(d$SCHOOL_ID)&nzchar(as.character(d$SCHOOL_ID))
    ]))),
    escs_nonmissing_weighted=
      sum(w0[is.finite(escs)&is.finite(w0)&w0>0],na.rm=TRUE)/
      sum(w0[is.finite(w0)&w0>0],na.rm=TRUE),
    q1_weight_share=sum(w0*q1frac,na.rm=TRUE)/sum(w0[is.finite(w0)&w0>0],na.rm=TRUE),
    q4_weight_share=sum(w0*q4frac,na.rm=TRUE)/sum(w0[is.finite(w0)&w0>0],na.rm=TRUE),
    reading_pvs=length(pv),replicate_weights=length(rw),
    stringsAsFactors=FALSE
  )

  ans <- list(
    cache_version="pisa_rc1_v1",
    pv_results=pv_results,
    social_results=social_results,
    diagnostics=diag
  )
  saveRDS(ans,cache,compress=FALSE)
  ans
}

# =============================================================================
# 4. DISCOVER PISA COUNTRY CACHES + RUN IN PARALLEL
# =============================================================================

STD_ROOT <- file.path(ROOT,"15_rc1_pisa_normalised","standardised_extracts")
pisa_years <- c(2006,2012,2015,2018,2022,2025)

tasks <- list(); ti <- 1L
for(yr in pisa_years) {
  cdir <- file.path(STD_ROOT,paste0("PISA_",yr,"_countries"))
  if(!dir.exists(cdir)) stop("Missing PISA country cache dir: ",cdir)
  ff <- list.files(cdir,pattern="\\.rds$",full.names=TRUE)
  for(f in ff) {
    cc <- toupper(tools::file_path_sans_ext(basename(f)))
    cfile <- file.path(PISA_CACHE,paste0(yr,"_",cc,".rds"))
    tasks[[ti]] <- data.frame(
      year=yr,source_country_code=cc,path=f,cache=cfile,
      stringsAsFactors=FALSE
    )
    ti <- ti+1L
  }
}
pisa_tasks <- do.call(rbind,tasks)
cat("PISA country×wave tasks: ",nrow(pisa_tasks),"\n",sep="")

pisa_rows <- split(pisa_tasks,seq_len(nrow(pisa_tasks)))

pisa_export_names <- c(
  "safe_num","wmean","wvar_pop","weighted_midrank",
  "weighted_fractional_tails","between_share","brr_variance",
  "combine_pv","pisa_pv_stat_vector","pisa_country_worker",
  "PISA_LEVEL2","FAY_VARIANCE_FACTOR","country_map","map_country_id"
)

pisa_ans <- run_tasks_stable(
  rows=pisa_rows,
  worker_fun=pisa_country_worker,
  preferred_workers=CPU_WORKERS,
  export_names=pisa_export_names,
  export_env=environment(),
  worker_packages=character(),
  log_prefix="PSOCK_PISA"
)
nwp <- attr(pisa_ans,"workers_used")
if(is.null(nwp)) nwp <- NA_integer_

pisa_pv <- do.call(rbind,lapply(pisa_ans,`[[`,"pv_results"))
pisa_social <- do.call(rbind,lapply(pisa_ans,`[[`,"social_results"))
pisa_diag <- do.call(rbind,lapply(pisa_ans,`[[`,"diagnostics"))

write.csv(pisa_pv,file.path(OUT,"PISA_RC1_SES_AND_ACADEMIC_RESULTS.csv"),row.names=FALSE)
write.csv(pisa_social,file.path(OUT,"PISA_RC1_SOCIAL_SORTING_RESULTS.csv"),row.names=FALSE)
write.csv(pisa_diag,file.path(OUT,"PISA_RC1_SAMPLE_DIAGNOSTICS.csv"),row.names=FALSE)

# =============================================================================
# 5. PIRLS HELPERS + COUNTRY×WAVE ESTIMATOR
# =============================================================================

recode_books <- function(x) {
  v <- safe_num(x)
  # Main PIRLS student books-at-home variables are 1..5 in increasing order.
  out <- ifelse(v %in% 1:5,v,NA_real_)
  if(length(unique(out[is.finite(out)]))<4L)
    stop("Books-at-home coding could not be harmonised to ordered 1..5.")
  out
}

pirls_jk_weights <- function(w0,zone,repc) {
  zones <- sort(unique(zone[is.finite(zone)&is.finite(repc)&is.finite(w0)&w0>0]))
  out <- vector("list",2L*length(zones)); ii <- 1L
  for(h in zones) {
    inh <- is.finite(zone)&zone==h&is.finite(repc)
    for(keep in c(0,1)) {
      wr <- w0
      wr[inh & repc==keep] <- 2*w0[inh & repc==keep]
      wr[inh & repc!=keep] <- 0
      out[[ii]] <- wr; ii <- ii+1L
    }
  }
  out
}

pirls_country_worker <- function(task) {
  year <- as.integer(task$year)
  cc <- as.character(task$source_country_code)
  f <- as.character(task$path)
  cache <- as.character(task$cache)

  if(file.exists(cache)) {
    x <- tryCatch(readRDS(cache),error=function(e)NULL)
    if(is.list(x) && identical(x$cache_version,"pirls_rc1_v1"))
      return(x)
  }

  # Read only necessary variables.
  header <- haven::read_sav(f,n_max=1)
  nms <- names(header)
  books <- if("ASBGBOOK" %in% nms) "ASBGBOOK" else
    if("ASBG04" %in% nms) "ASBG04" else NA_character_
  if(is.na(books)) stop(year," ",cc,": no books-at-home variable.")

  pv <- grep("^ASRREA0[1-5]$",nms,value=TRUE)
  need <- unique(c(
    "IDSCHOOL","IDCLASS","IDSTUD","TOTWGT","JKZONE","JKREP",
    books,pv,
    "ASBGLANH","ASBGLNGH","ASBG03",
    "ASBGBRN1","ASBGBRN2","ASBGBRNM","ASBGBRNF","ASDGBRN"
  ))
  d <- haven::read_sav(f,col_select=tidyselect::any_of(need))
  if(length(pv)!=5L || !all(c("IDSCHOOL","IDCLASS","TOTWGT","JKZONE","JKREP") %in% names(d)))
    stop(year," ",cc,": PIRLS required variable check failed.")

  w0 <- safe_num(d$TOTWGT)
  zone <- safe_num(d$JKZONE)
  repc <- safe_num(d$JKREP)
  book_rank <- recode_books(d[[books]])
  social_rank0 <- weighted_midrank(book_rank,w0)

  # Social sorting school + classroom.
  social_school <- between_share(social_rank0,d$IDSCHOOL,w0)
  social_class <- between_share(
    social_rank0,paste(d$IDSCHOOL,d$IDCLASS,sep="::"),w0
  )

  jk <- pirls_jk_weights(w0,zone,repc)
  ss_rep <- sc_rep <- rep(NA_real_,length(jk))
  for(r in seq_along(jk)) {
    wr <- jk[[r]]
    rr <- weighted_midrank(book_rank,wr)
    ss_rep[r] <- between_share(rr,d$IDSCHOOL,wr)
    sc_rep[r] <- between_share(
      rr,paste(d$IDSCHOOL,d$IDCLASS,sep="::"),wr
    )
  }
  vss <- jk2_variance(social_school,ss_rep)
  vsc <- jk2_variance(social_class,sc_rep)

  social_results <- rbind(
    data.frame(
      survey="PIRLS",year=year,source_country_code=cc,
      country_id=map_country_id(cc,"PIRLS"),
      statistic="social_rank_school_sorting_share",
      estimate=social_school,se=sqrt(vss),
      ci_low=social_school-1.96*sqrt(vss),
      ci_high=social_school+1.96*sqrt(vss),
      sampling_variance=vss,pv_imputation_variance=0,total_variance=vss,
      stringsAsFactors=FALSE
    ),
    data.frame(
      survey="PIRLS",year=year,source_country_code=cc,
      country_id=map_country_id(cc,"PIRLS"),
      statistic="social_rank_classroom_sorting_share",
      estimate=social_class,se=sqrt(vsc),
      ci_low=social_class-1.96*sqrt(vsc),
      ci_high=social_class+1.96*sqrt(vsc),
      sampling_variance=vsc,pv_imputation_variance=0,total_variance=vsc,
      stringsAsFactors=FALSE
    )
  )

  # Academic sorting over 5 reading PVs.
  theta_school <- theta_class <- rep(NA_real_,length(pv))
  U_school <- U_class <- rep(NA_real_,length(pv))

  for(m in seq_along(pv)) {
    y <- safe_num(d[[pv[m]]])
    fs <- between_share(y,d$IDSCHOOL,w0)
    fc <- between_share(y,paste(d$IDSCHOOL,d$IDCLASS,sep="::"),w0)
    rs <- rc <- rep(NA_real_,length(jk))
    for(r in seq_along(jk)) {
      wr <- jk[[r]]
      rs[r] <- between_share(y,d$IDSCHOOL,wr)
      rc[r] <- between_share(y,paste(d$IDSCHOOL,d$IDCLASS,sep="::"),wr)
    }
    theta_school[m] <- fs
    theta_class[m] <- fc
    U_school[m] <- jk2_variance(fs,rs)
    U_class[m] <- jk2_variance(fc,rc)
  }

  cs <- combine_pv(theta_school,U_school)
  ccmb <- combine_pv(theta_class,U_class)
  academic_results <- rbind(
    data.frame(
      survey="PIRLS",year=year,source_country_code=cc,
      country_id=map_country_id(cc,"PIRLS"),
      statistic="academic_school_sorting_share",
      estimate=cs["estimate"],se=cs["se"],
      ci_low=cs["estimate"]-1.96*cs["se"],
      ci_high=cs["estimate"]+1.96*cs["se"],
      sampling_variance=cs["sampling_variance"],
      pv_imputation_variance=cs["pv_imputation_variance"],
      total_variance=cs["total_variance"],
      stringsAsFactors=FALSE
    ),
    data.frame(
      survey="PIRLS",year=year,source_country_code=cc,
      country_id=map_country_id(cc,"PIRLS"),
      statistic="academic_classroom_sorting_share",
      estimate=ccmb["estimate"],se=ccmb["se"],
      ci_low=ccmb["estimate"]-1.96*ccmb["se"],
      ci_high=ccmb["estimate"]+1.96*ccmb["se"],
      sampling_variance=ccmb["sampling_variance"],
      pv_imputation_variance=ccmb["pv_imputation_variance"],
      total_variance=ccmb["total_variance"],
      stringsAsFactors=FALSE
    )
  )

  diag <- data.frame(
    survey="PIRLS",year=year,source_country_code=cc,
    country_id=map_country_id(cc,"PIRLS"),
    n_students=nrow(d),
    n_schools=length(unique(as.character(d$IDSCHOOL))),
    n_classes=length(unique(paste(d$IDSCHOOL,d$IDCLASS,sep="::"))),
    books_nonmissing_weighted=
      sum(w0[is.finite(book_rank)&is.finite(w0)&w0>0],na.rm=TRUE)/
      sum(w0[is.finite(w0)&w0>0],na.rm=TRUE),
    reading_pvs=length(pv),jk_replicates=length(jk),
    stringsAsFactors=FALSE
  )

  # Demographic-variable input: observed labels/codes, not harmonized results.
  demo_candidates <- intersect(
    c(
      "ASBGLANH","ASBGLNGH","ASBG03",
      "ASBGBRN1","ASBGBRN2","ASBGBRNM","ASBGBRNF","ASDGBRN"
    ),
    names(d)
  )
  demo_rows <- list(); di <- 1L
  for(vn in demo_candidates) {
    x <- d[[vn]]
    labs <- attr(x,"labels",exact=TRUE)
    label <- attr(x,"label",exact=TRUE)
    observed <- sort(unique(safe_num(x)))
    observed <- observed[is.finite(observed)]
    labtxt <- if(!is.null(labs) && length(labs))
      paste(names(labs),as.numeric(labs),sep="=",collapse=" | ") else ""
    demo_rows[[di]] <- data.frame(
      survey="PIRLS",year=year,source_country_code=cc,
      variable=vn,label=if(is.null(label))"" else as.character(label),
      value_labels=labtxt,
      observed_values=paste(observed,collapse=";"),
      stringsAsFactors=FALSE
    ); di <- di+1L
  }
  demo <- if(length(demo_rows)) do.call(rbind,demo_rows) else data.frame()

  ans <- list(
    cache_version="pirls_rc1_v1",
    social_results=social_results,
    academic_results=academic_results,
    diagnostics=diag,
    demographic_input=demo
  )
  saveRDS(ans,cache,compress=FALSE)
  ans
}

# =============================================================================
# 6. DISCOVER PIRLS TARGET FILES + RUN IN PARALLEL
# =============================================================================

target_files <- list.files(
  ROOT,pattern="^PIRLS_dashboard_target_population_audit\\.csv$",
  recursive=TRUE,full.names=TRUE,ignore.case=TRUE
)
if(!length(target_files))
  stop("PIRLS target-population audit not found.")
target_files <- target_files[
  order(file.info(target_files)$mtime,decreasing=TRUE)
]
ta <- utils::read.csv(target_files[1],stringsAsFactors=FALSE,check.names=FALSE)

exc <- if(is.logical(ta$exclude_dashboard)) ta$exclude_dashboard else
  toupper(as.character(ta$exclude_dashboard)) %in% c("TRUE","T","1","YES")
pt <- ta[!exc,,drop=FALSE]
pt$local_path <- norm(pt$local_path)
pt <- pt[file.exists(pt$local_path),,drop=FALSE]
if(!"source_country_code" %in% names(pt))
  pt$source_country_code <- toupper(
    sub("^ASG([A-Z0-9]{3}).*$","\\1",basename(pt$local_path))
  )
pt$source_country_code <- toupper(pt$source_country_code)

pirls_tasks <- data.frame(
  year=as.integer(pt$year),
  source_country_code=pt$source_country_code,
  path=pt$local_path,
  cache=file.path(
    PIRLS_CACHE,
    paste0(as.integer(pt$year),"_",pt$source_country_code,".rds")
  ),
  stringsAsFactors=FALSE
)
cat("PIRLS country×wave tasks: ",nrow(pirls_tasks),"\n",sep="")

pirls_rows <- split(pirls_tasks,seq_len(nrow(pirls_tasks)))

pirls_export_names <- c(
  "safe_num","wmean","weighted_midrank","between_share",
  "jk2_variance","combine_pv","recode_books","pirls_jk_weights",
  "pirls_country_worker","country_map","map_country_id"
)

pirls_ans <- run_tasks_stable(
  rows=pirls_rows,
  worker_fun=pirls_country_worker,
  preferred_workers=IO_WORKERS,
  export_names=pirls_export_names,
  export_env=environment(),
  worker_packages=c("haven","tidyselect"),
  log_prefix="PSOCK_PIRLS"
)
nwi <- attr(pirls_ans,"workers_used")
if(is.null(nwi)) nwi <- NA_integer_

pirls_social <- do.call(rbind,lapply(pirls_ans,`[[`,"social_results"))
pirls_academic <- do.call(rbind,lapply(pirls_ans,`[[`,"academic_results"))
pirls_diag <- do.call(rbind,lapply(pirls_ans,`[[`,"diagnostics"))
demo_in <- do.call(rbind,lapply(pirls_ans,`[[`,"demographic_input"))

write.csv(pirls_social,file.path(OUT,"PIRLS_RC1_SOCIAL_SORTING_RESULTS.csv"),row.names=FALSE)
write.csv(pirls_academic,file.path(OUT,"PIRLS_RC1_ACADEMIC_SORTING_RESULTS.csv"),row.names=FALSE)
write.csv(pirls_diag,file.path(OUT,"PIRLS_RC1_SAMPLE_DIAGNOSTICS.csv"),row.names=FALSE)
write.csv(demo_in,file.path(OUT,"PIRLS_RC1_DEMOGRAPHIC_HARMONISATION_INPUT.csv"),row.names=FALSE)

# =============================================================================
# 7. PISA DEMOGRAPHIC HARMONISATION INPUT FROM NORMALISED CACHE METADATA
# =============================================================================

pisa_demo_files <- list.files(
  ROOT,pattern="^PISA_RC1_DEMOGRAPHIC_VARIABLE_CANDIDATES\\.csv$",
  recursive=TRUE,full.names=TRUE
)
if(length(pisa_demo_files)) {
  pisa_demo_files <- pisa_demo_files[
    order(file.info(pisa_demo_files)$mtime,decreasing=TRUE)
  ]
  file.copy(
    pisa_demo_files[1],
    file.path(OUT,"PISA_RC1_DEMOGRAPHIC_HARMONISATION_INPUT.csv"),
    overwrite=TRUE
  )
}

# =============================================================================
# 8. VALIDATE PISA SES PROFICIENCY AGAINST EXISTING OFFICIAL BACKEND
# =============================================================================

# Convert factory statistics into comparable official rows.
pisa_official <- existing_obs[
  existing_obs$survey=="PISA" &
    existing_obs$group_dimension=="national_escs_quartile" &
    existing_obs$indicator_id=="proficiency_baseline" &
    existing_obs$group_id %in% c("q1","q4") &
    existing_obs$year %in% c(2015,2018,2022,2025),
  c("year","country_id","group_id","estimate","quality_status")
]
names(pisa_official)[names(pisa_official)=="estimate"] <- "official_estimate"

factory_q <- pisa_pv[
  pisa_pv$statistic %in% c("q1_prof2","q4_prof2"),
  c("year","country_id","statistic","estimate","se")
]
factory_q$group_id <- ifelse(factory_q$statistic=="q1_prof2","q1","q4")
factory_q$factory_estimate_percent <- 100*factory_q$estimate

val <- merge(
  pisa_official,factory_q,
  by=c("year","country_id","group_id"),
  all=FALSE
)
val$abs_diff_pp <- abs(val$factory_estimate_percent-val$official_estimate)
val$validation_status <- ifelse(
  val$abs_diff_pp<=1,"GREEN_le1pp",
  ifelse(val$abs_diff_pp<=2.5,"YELLOW_le2.5pp","RED_gt2.5pp")
)
write.csv(val,file.path(OUT,"PISA_SES_OFFICIAL_VALIDATION.csv"),row.names=FALSE)

# =============================================================================
# 9. CROSS-AGE PAIRS / SORTING CHANGES
# =============================================================================

pair_design <- data.frame(
  pair_id=c(
    "PIRLS2001_PISA2006_MAIN",
    "PIRLS2006_PISA2012_MAIN",
    "PIRLS2011_PISA2015_MAIN",
    "PIRLS2011_PISA2018_ROBUST",
    "PIRLS2016_PISA2022_MAIN",
    "PIRLS2021_PISA2025_CURRENT"
  ),
  pirls_year=c(2001,2006,2011,2011,2016,2021),
  pisa_year=c(2006,2012,2015,2018,2022,2025),
  pair_role=c(
    "main","main","main","robustness","main","current_system"
  ),
  stringsAsFactors=FALSE
)

all_social <- rbind(
  pirls_social[pirls_social$statistic=="social_rank_school_sorting_share",],
  pisa_social[pisa_social$statistic=="social_rank_school_sorting_share",]
)
all_acad <- rbind(
  pirls_academic[pirls_academic$statistic=="academic_school_sorting_share",],
  pisa_pv[pisa_pv$statistic=="academic_school_sorting_share",]
)

build_changes <- function(dat,metric) {
  out <- list(); oi <- 1L
  for(i in seq_len(nrow(pair_design))) {
    pr <- pair_design[i,]
    y <- dat[dat$survey=="PIRLS"&dat$year==pr$pirls_year,]
    o <- dat[dat$survey=="PISA"&dat$year==pr$pisa_year,]
    m <- merge(
      y[,c("country_id","estimate","se")],
      o[,c("country_id","estimate","se")],
      by="country_id",suffixes=c("_age10","_age15")
    )
    m <- m[!is.na(m$country_id)&nzchar(m$country_id),]
    if(!nrow(m)) next
    m$pair_id <- pr$pair_id
    m$pair_role <- pr$pair_role
    m$metric <- metric
    m$change_age15_minus_age10 <- m$estimate_age15-m$estimate_age10
    # Covariance unavailable across independent surveys; descriptive SE proxy.
    m$change_se_independent_proxy <- sqrt(m$se_age10^2+m$se_age15^2)
    m$pair_n <- nrow(m)
    out[[oi]] <- m; oi <- oi+1L
  }
  if(length(out)) do.call(rbind,out) else data.frame()
}

chg_social <- build_changes(all_social,"social_rank_school_sorting_share")
chg_acad <- build_changes(all_acad,"academic_school_sorting_share")
chg <- rbind(chg_social,chg_acad)
write.csv(chg,file.path(OUT,"CROSS_AGE_SORTING_CHANGES.csv"),row.names=FALSE)

# Pair-specific panel registry + fixed intersection across all main pairs.
panel_rows <- list(); member_rows <- list(); pri <- 1L; mri <- 1L
for(metric in unique(chg$metric)) {
  zz <- chg[chg$metric==metric,]
  for(pid in unique(zz$pair_id)) {
    q <- zz[zz$pair_id==pid,]
    panel_id <- paste0("PAIR_MAX_COMMON_",metric,"_",pid)
    panel_rows[[pri]] <- data.frame(
      panel_id=panel_id,metric=metric,pair_id=pid,
      panel_type="pair_specific_common",n=nrow(q),
      stringsAsFactors=FALSE
    ); pri <- pri+1L
    for(cid in sort(unique(q$country_id))) {
      member_rows[[mri]] <- data.frame(
        panel_id=panel_id,country_id=cid,stringsAsFactors=FALSE
      ); mri <- mri+1L
    }
  }

  mains <- unique(
    zz$pair_id[zz$pair_role=="main"]
  )
  sets <- lapply(mains,function(pid)
    unique(zz$country_id[zz$pair_id==pid])
  )
  fixed <- if(length(sets)) Reduce(intersect,sets) else character()
  fid <- paste0("CROSS_PAIR_FIXED_MAIN_",metric)
  panel_rows[[pri]] <- data.frame(
    panel_id=fid,metric=metric,pair_id="ALL_MAIN",
    panel_type="fixed_intersection_across_main_pairs",
    n=length(fixed),stringsAsFactors=FALSE
  ); pri <- pri+1L
  for(cid in sort(fixed)) {
    member_rows[[mri]] <- data.frame(
      panel_id=fid,country_id=cid,stringsAsFactors=FALSE
    ); mri <- mri+1L
  }
}
panel_registry <- do.call(rbind,panel_rows)
panel_members <- do.call(rbind,member_rows)
write.csv(panel_registry,file.path(OUT,"RC1_PANEL_REGISTRY.csv"),row.names=FALSE)
write.csv(panel_members,file.path(OUT,"RC1_PANEL_MEMBERS.csv"),row.names=FALSE)

# =============================================================================
# 10. LATEST-WAVE MAXIMUM IDENTICAL SES-GAP PANELS
# =============================================================================

# PIRLS existing validated score/proficiency gaps.
pirls_latest <- existing_obs[
  existing_obs$survey=="PIRLS" &
    existing_obs$year==2021 &
    existing_obs$group_dimension=="pirls_books_at_home_quartile_bridge" &
    existing_obs$indicator_id %in% c("social_score_gap","social_proficiency_gap"),
  c("country_id","indicator_id","estimate","se","quality_status")
]

# PISA computed 2025 score/proficiency gaps.
pisa_latest <- pisa_pv[
  pisa_pv$year==2025 &
    pisa_pv$statistic %in% c("score_gap","prof_gap"),
  c("country_id","statistic","estimate","se")
]
pisa_latest$indicator_id <- ifelse(
  pisa_latest$statistic=="score_gap","social_score_gap","social_proficiency_gap"
)
pisa_latest$estimate[pisa_latest$indicator_id=="social_proficiency_gap"] <-
  100*pisa_latest$estimate[pisa_latest$indicator_id=="social_proficiency_gap"]

latest_rows <- list(); lri <- 1L
for(ind in c("social_score_gap","social_proficiency_gap")) {
  a <- pirls_latest[pirls_latest$indicator_id==ind,]
  b <- pisa_latest[pisa_latest$indicator_id==ind,]
  common <- sort(intersect(a$country_id,b$country_id))
  a <- a[a$country_id %in% common,]
  b <- b[b$country_id %in% common,]
  a <- a[order(a$estimate),]; a$rank <- seq_len(nrow(a))
  b <- b[order(b$estimate),]; b$rank <- seq_len(nrow(b))
  n <- length(common)

  for(age in c("age10","age15")) {
    q <- if(age=="age10") a else b
    q$age <- age
    q$panel_id <- paste0(
      "LATEST_IDENTICAL_",ind,"_PIRLS2021_PISA2025"
    )
    q$panel_n <- n
    latest_rows[[lri]] <- q[,c(
      "panel_id","panel_n","age","country_id",
      "indicator_id","estimate","se","rank"
    )]
    lri <- lri+1L
  }
}
latest_common <- do.call(rbind,latest_rows)
write.csv(
  latest_common,
  file.path(OUT,"LATEST_WAVE_IDENTICAL_SES_GAP_RANKINGS.csv"),
  row.names=FALSE
)

# =============================================================================
# 11. STATUS / VALIDATION GATES
# =============================================================================

red_val <- sum(val$validation_status=="RED_gt2.5pp",na.rm=TRUE)
yellow_val <- sum(val$validation_status=="YELLOW_le2.5pp",na.rm=TRUE)
green_val <- sum(val$validation_status=="GREEN_le1pp",na.rm=TRUE)

status <- list(
  created=format(Sys.time(),"%Y-%m-%d %H:%M:%S %z"),
  pisa_tasks=nrow(pisa_tasks),
  pirls_tasks=nrow(pirls_tasks),
  pisa_workers_used=nwp,
  pirls_workers_used=nwi,
  pisa_ses_validation=list(
    green=green_val,yellow=yellow_val,red=red_val,
    release_gate=if(red_val==0)"PASS_NO_RED" else "FAIL_RED_PRESENT"
  ),
  social_sorting_status="COMPUTED_PENDING_OECD_SOCIAL_INCLUSION_VALIDATION",
  academic_sorting_status="COMPUTED_PENDING_OECD_ACADEMIC_INCLUSION_VALIDATION",
  demographic_status="HARMONISATION_INPUT_ONLY_NOT_PUBLISHABLE",
  representativeness_status="SORTING_SAMPLE_DIAGNOSTICS_READY_FULL_RESPONSE_COVERAGE_REGISTER_STILL_REQUIRED",
  optional_pisa_2009_status=if(
    file.exists(file.path(STD_ROOT,"PISA_2009_RC1_STANDARDISED.rds"))
  ) "LOCAL_STANDARDISED_PRESENT" else "NOT_STANDARDISED_OPTIONAL_EXTENSION"
)

json_text <- if(requireNamespace("jsonlite",quietly=TRUE)) {
  jsonlite::toJSON(status,auto_unbox=TRUE,pretty=TRUE)
} else {
  paste(capture.output(str(status)),collapse="\n")
}
writeLines(json_text,file.path(OUT,"status.json"))

# =============================================================================
# 12. METADATA-ONLY HANDOFF ZIP
# =============================================================================

writeLines(c(
  "PISA/PIRLS RC1 RESULTS FACTORY V1",
  paste0("Created: ",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "",
  paste0("PISA country×wave tasks: ",nrow(pisa_tasks)),
  paste0("PISA workers actually used: ",nwp),
  paste0("PIRLS country×wave tasks: ",nrow(pirls_tasks)),
  paste0("PIRLS workers actually used: ",nwi),
  paste0("PISA SES validation RED cells: ",red_val),
  "",
  "IMPORTANT:",
  "- social/academic sorting estimates are computed but remain non-publishable until official OECD validation is closed;",
  "- demographic results are harmonisation inputs only;",
  "- full response/coverage representativeness register remains a separate required RC1 gate;",
  "- raw microdata/caches are NOT included in this handoff."
),file.path(OUT,"README_RESULTS_FACTORY.txt"))

files <- list.files(
  OUT,recursive=TRUE,full.names=TRUE,all.files=TRUE,no..=TRUE
)
ii <- file.info(files)
files <- files[!is.na(ii$isdir)&!ii$isdir]
# Never include RDS caches or raw source formats.
files <- files[!grepl("\\.(rds|sav|sas7bdat|dat)$",files,ignore.case=TRUE)]

manifest <- data.frame(
  relative_path=substring(norm(files),nchar(norm(OUT))+2L),
  bytes=file.info(files)$size,
  md5=unname(tools::md5sum(files)),
  stringsAsFactors=FALSE
)
write.csv(manifest,file.path(OUT,"HANDOFF_MANIFEST.csv"),row.names=FALSE)

zipfile <- file.path(
  HANDOFF_DIR,paste0("PISA_PIRLS_RC1_RESULTS_FACTORY_",STAMP,".zip")
)

# Use the CRAN 'zip' binary package rather than utils::zip(), because the
# Windows laptop does not have Rtools/external zip guaranteed.
if(!requireNamespace("zip",quietly=TRUE)) {
  cat("Installing CRAN package zip for the small metadata handoff...\\n")
  install.packages("zip",repos="https://cloud.r-project.org",type="binary")
}
if(!requireNamespace("zip",quietly=TRUE))
  stop("Package zip could not be installed/loaded; results are present but handoff ZIP was not created.")

rel <- list.files(OUT,recursive=TRUE,full.names=TRUE,all.files=FALSE)
rel <- rel[!grepl("\\.(rds|sav|sas7bdat|dat)$",rel,ignore.case=TRUE)]
zip::zipr(zipfile,files=rel,root=OUT,include_directories=FALSE)

if(!file.exists(zipfile))
  stop("Handoff ZIP creation failed.")

cat("\n============================================================\n")
cat("RC1 RESULTS FACTORY COMPLETE\n")
cat("============================================================\n")
cat("PISA SES official validation: GREEN=",green_val,
    ", YELLOW=",yellow_val,", RED=",red_val,"\n",sep="")
cat("Social sorting: computed, OECD validation still required.\n")
cat("Academic sorting: computed, OECD validation still required.\n")
cat("Demography: harmonisation input only; NOT publishable yet.\n")
cat("\nUPLOAD ONLY THIS SMALL ZIP:\n",norm(zipfile),"\n",sep="")
cat("Do NOT upload local country caches or raw OECD/IEA data.\n")
