# =============================================================================
# PISA RC1 MODAL-ISCED SORTING MAIN SPECIFICATION
# Version 1.0 — 21 September 2026
#
# PURPOSE
#   Recompute PISA social and academic school sorting on schools with the
#   modal ISCED level for 15-year-olds, matching the preferred OECD analysis
#   population.  The previous full-sample results remain robustness results.
#
# OECD logic implemented:
#   - Modal ISCED level(s): each ISCED level attended by at least one-third
#     of the country/economy's PISA sample.
#   - Restriction is at SCHOOL level: identify schools containing sampled
#     students in a modal ISCED level, then retain all sampled students in
#     those schools (including students in another ISCED level).
#
# OUTPUT
#   - modal-ISCED social rank school-sorting share
#   - modal-ISCED raw-ESCS school-sorting diagnostic
#   - modal-ISCED academic school-sorting share (all reading PVs)
#   - modal-level / modal-school coverage audit
#   - NLD 2018 coverage sanity diagnostic
#   - metadata-only handoff ZIP
#
# RAW DATA
#   Raw PUFs remain local.  Only a small ISCEDL bridge is cached locally.
# =============================================================================

options(stringsAsFactors=FALSE)

DOWNLOADS <- normalizePath(file.path(Sys.getenv("USERPROFILE"),"Downloads"),winslash="/",mustWork=TRUE)
ROOT <- file.path(DOWNLOADS,"PISA_PIRLS_MASTER_PIPELINE")
if(!dir.exists(ROOT)) stop("Project root not found: ",ROOT)

if(!requireNamespace("haven",quietly=TRUE))
  stop("Package haven is required.")
if(!requireNamespace("tidyselect",quietly=TRUE))
  stop("Package tidyselect is required.")

if(!requireNamespace("SAScii",quietly=TRUE)) {
  cat("Installing CRAN package SAScii for 2006/2012 fixed-width files...\n")
  install.packages("SAScii",repos="https://cloud.r-project.org",type="binary")
}
if(!requireNamespace("SAScii",quietly=TRUE))
  stop("Package SAScii could not be installed/loaded.")

PHYSICAL_CORES <- suppressWarnings(parallel::detectCores(logical=FALSE))
LOGICAL_CORES <- suppressWarnings(parallel::detectCores(logical=TRUE))
if(is.na(PHYSICAL_CORES)||PHYSICAL_CORES<2L)
  PHYSICAL_CORES <- max(2L,LOGICAL_CORES-2L)
CPU_WORKERS <- max(2L,min(8L,PHYSICAL_CORES-2L))

STAMP <- format(Sys.time(),"%Y%m%d_%H%M%S")
OUT_ROOT <- file.path(ROOT,"17_rc1_modal_isced_sorting")
OUT <- file.path(OUT_ROOT,paste0("run_",STAMP))
BRIDGE_ROOT <- file.path(OUT_ROOT,"iscedl_bridge_v1")
CACHE_ROOT <- file.path(OUT_ROOT,"cache_v1")
HANDOFF_DIR <- file.path(ROOT,"RUNNER","handoffs")
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
dir.create(BRIDGE_ROOT,recursive=TRUE,showWarnings=FALSE)
dir.create(CACHE_ROOT,recursive=TRUE,showWarnings=FALSE)
dir.create(HANDOFF_DIR,recursive=TRUE,showWarnings=FALSE)

norm <- function(x) normalizePath(x,winslash="/",mustWork=FALSE)
safe_num <- function(x) suppressWarnings(as.numeric(x))

cat("\n============================================================\n")
cat("PISA RC1 MODAL-ISCED SORTING V1\n")
cat("============================================================\n")
cat("Detected cores: ",PHYSICAL_CORES," physical / ",LOGICAL_CORES," logical\n",sep="")
cat("CPU workers: ",CPU_WORKERS,"\n\n",sep="")

# =============================================================================
# Helpers
# =============================================================================

weighted_midrank <- function(x,w) {
  x <- safe_num(x); w <- safe_num(w)
  out <- rep(NA_real_,length(x))
  ok <- is.finite(x)&is.finite(w)&w>0
  if(!any(ok)) return(out)
  xx <- x[ok]; ww <- w[ok]
  u <- sort(unique(xx))
  gw <- vapply(u,function(v)sum(ww[xx==v]),numeric(1))
  before <- c(0,cumsum(gw))[seq_along(gw)]
  rr <- (before+.5*gw)/sum(gw)
  map <- setNames(rr,as.character(u))
  out[ok] <- unname(map[as.character(xx)])
  out
}

between_share <- function(y,cluster,w) {
  y <- safe_num(y); w <- safe_num(w); cl <- as.character(cluster)
  ok <- is.finite(y)&is.finite(w)&w>0&!is.na(cl)&nzchar(cl)
  if(sum(ok)<10L) return(NA_real_)
  y <- y[ok]; w <- w[ok]; cl <- cl[ok]
  mu <- sum(w*y)/sum(w)
  tv <- sum(w*(y-mu)^2)/sum(w)
  if(!is.finite(tv)||tv<=0) return(NA_real_)
  sw <- as.numeric(rowsum(w,cl,reorder=FALSE))
  sy <- as.numeric(rowsum(w*y,cl,reorder=FALSE))
  gm <- sy/sw
  bv <- sum(sw*(gm-mu)^2)/sum(sw)
  100*bv/tv
}

FAY_VARIANCE_FACTOR <- 1/20
brr_variance <- function(full,reps) {
  reps <- safe_num(reps)
  ok <- is.finite(reps)&is.finite(full)
  if(sum(ok)<60L) return(NA_real_)
  FAY_VARIANCE_FACTOR*sum((reps[ok]-full)^2)
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
  c(
    estimate=th,
    se=if(is.finite(tot))sqrt(tot)else NA_real_,
    sampling_variance=U,
    pv_imputation_variance=imp,
    total_variance=tot
  )
}

run_tasks_stable <- function(rows,worker_fun,preferred_workers,export_names,export_env) {
  attempts <- unique(c(preferred_workers,6L,4L,2L,1L))
  attempts <- attempts[attempts>=1L & attempts<=length(rows)]
  last_error <- NULL

  for(nw in attempts) {
    cat("PSOCK_MODAL_ISCED: trying ",nw,
        if(nw==1L)" sequential worker...\n" else " workers...\n",sep="")

    if(nw==1L) {
      ans <- tryCatch(lapply(rows,worker_fun),error=function(e)e)
    } else {
      worker_log <- file.path(OUT,paste0("PSOCK_MODAL_ISCED_",nw,"workers.log"))
      cl <- NULL
      ans <- tryCatch({
        cl <- parallel::makePSOCKcluster(nw,outfile=worker_log)
        smoke <- parallel::clusterCall(cl,function()TRUE)
        if(!all(vapply(smoke,isTRUE,logical(1)))) stop("PSOCK smoke test failed.")
        parallel::clusterExport(cl,export_names,envir=export_env)
        parallel::parLapplyLB(cl,rows,worker_fun)
      },error=function(e)e,
      finally={
        if(!is.null(cl)) try(parallel::stopCluster(cl),silent=TRUE)
      })
    }

    if(!inherits(ans,"error")) {
      attr(ans,"workers_used") <- nw
      cat("PSOCK_MODAL_ISCED: succeeded with ",nw," worker(s).\n",sep="")
      return(ans)
    }
    last_error <- ans
    cat("Attempt failed: ",conditionMessage(ans),"\n",sep="")
  }
  stop("All modal-ISCED worker attempts failed: ",conditionMessage(last_error))
}

# =============================================================================
# Raw-source discovery
# =============================================================================

all_files <- list.files(DOWNLOADS,recursive=TRUE,full.names=TRUE,all.files=FALSE)
all_files <- all_files[!grepl("\\.crdownload$",basename(all_files),ignore.case=TRUE)]
bn <- basename(all_files)

pick <- function(patterns) {
  hit <- rep(FALSE,length(all_files))
  for(p in patterns) hit <- hit|grepl(p,bn,perl=TRUE,ignore.case=TRUE)
  z <- all_files[hit]
  if(!length(z)) return("")
  info <- file.info(z)
  norm(z[order(info$size,decreasing=TRUE,na.last=TRUE)][1])
}
pick_preferred <- function(primary,fallback) {
  z <- pick(primary)
  if(nzchar(z)) z else pick(fallback)
}

sources <- data.frame(
  year=c(2006,2006,2012,2012,2015,2018,2022,2025),
  role=c("data","control","data","control","data","data","data","data"),
  path=c(
    pick(c("^INT_Stu06_Dec07(?:\\s*\\(\\d+\\))?\\.zip$")),
    pick(c("^PISA2006_SAS_student(?:\\s*\\(\\d+\\))?\\.sas$")),
    pick(c("^INT_STU12_DEC03(?:\\s*\\(\\d+\\))?\\.zip$")),
    pick(c("^PISA2012_SAS_student(?:\\s*\\(\\d+\\))?\\.sas$")),
    pick_preferred(
      c("^(PUF_)?SPSS_COMBINED_CMB_STU_QQQ(?:\\s*\\(\\d+\\))?\\.zip$"),
      c("^(PUF_)?SAS_COMBINED_CMB_STU_QQQ(?:\\s*\\(\\d+\\))?\\.zip$")
    ),
    pick_preferred(
      c("^SPSS_STU_QQQ(?:\\s*\\(\\d+\\))?\\.zip$"),
      c("^SAS_STU_QQQ(?:\\s*\\(\\d+\\))?\\.zip$")
    ),
    pick(c("^STU_QQQ_SPSS(?:\\s*\\(\\d+\\))?\\.zip$","^STU_QQQ_SAS(?:\\s*\\(\\d+\\))?\\.zip$")),
    pick(c("^CY09_MS_STU_PUF(?:\\s*\\(\\d+\\))?\\.(sav|zip)$"))
  ),
  stringsAsFactors=FALSE
)
sources$exists <- nzchar(sources$path)&file.exists(sources$path)
write.csv(sources,file.path(OUT,"PISA_MODAL_ISCED_SOURCE_DISCOVERY.csv"),row.names=FALSE)
if(any(!sources$exists))
  stop("Required PISA source/control missing; inspect PISA_MODAL_ISCED_SOURCE_DISCOVERY.csv")

# =============================================================================
# ZIP extraction / dictionaries
# =============================================================================

extract_zip_member <- function(zip_path,extension) {
  zl <- utils::unzip(zip_path,list=TRUE)
  pat <- paste0("\\.",toupper(extension),"$")
  hit <- grepl(pat,toupper(zl$Name))&grepl("STU|QQQ",toupper(zl$Name))
  if(!any(hit)) hit <- grepl(pat,toupper(zl$Name))
  if(!any(hit)) stop("No .",extension," member in ",basename(zip_path))
  cand <- zl[hit,,drop=FALSE]
  member <- cand$Name[which.max(as.numeric(cand$Length))]
  td <- tempfile("pisa_isced_"); dir.create(td)
  out <- suppressWarnings(try(
    utils::unzip(zip_path,files=member,exdir=td,junkpaths=TRUE,overwrite=TRUE),
    silent=TRUE
  ))
  dest <- file.path(td,basename(member))
  if(!file.exists(dest)||file.info(dest)$size<=0) {
    if(!requireNamespace("archive",quietly=TRUE)) {
      install.packages("archive",repos="https://cloud.r-project.org",type="binary")
    }
    if(!requireNamespace("archive",quietly=TRUE))
      stop("Could not install archive for ZIP extraction.")
    archive::archive_extract(zip_path,dir=td,files=member)
    all <- list.files(td,recursive=TRUE,full.names=TRUE)
    same <- all[tolower(basename(all))==tolower(basename(member))]
    if(length(same)) file.copy(same[which.max(file.info(same)$size)],dest,overwrite=TRUE)
  }
  if(!file.exists(dest)||file.info(dest)$size<=0)
    stop("Could not extract ",member)
  list(path=dest,tempdir=td)
}

dictionary_sas_setup <- function(path) {
  x <- SAScii::parse.SAScii(path)
  data.frame(
    variable=toupper(as.character(x$varname)),
    width=as.numeric(x$width),
    char=as.logical(x$char),
    divisor=as.numeric(x$divisor),
    stringsAsFactors=FALSE
  )
}

read_selected_fwf <- function(data_zip,control,selected_vars) {
  st <- dictionary_sas_setup(control)
  selected_vars <- toupper(selected_vars)
  keep <- !is.na(st$variable)&nzchar(st$variable)&st$variable%in%selected_vars

  # IDs must remain character.
  force_char <- st$variable %in% c("CNT","COUNTRY","SCHOOLID","CNTSCHID","STIDSTD","CNTSTUID")
  st$char[force_char] <- TRUE

  widths <- abs(st$width)
  widths[!keep] <- -widths[!keep]
  kr <- which(keep)

  zl <- utils::unzip(data_zip,list=TRUE)
  hit <- grepl("\\.(TXT|DAT)$",toupper(zl$Name))
  member <- zl$Name[which.max(as.numeric(zl$Length)*hit)]
  td <- tempfile("pisa_fwf_"); dir.create(td)
  ex <- utils::unzip(data_zip,files=member,exdir=td,junkpaths=TRUE)
  if(!length(ex)||!file.exists(ex[1])) stop("Could not extract fixed-width data.")
  on.exit(unlink(td,recursive=TRUE,force=TRUE),add=TRUE)

  d <- utils::read.fwf(
    ex[1],widths=widths,
    col.names=st$variable[kr],
    colClasses="character",
    comment.char="",strip.white=FALSE,buffersize=2000
  )

  for(j in seq_along(kr)) {
    rr <- kr[j]
    if(!isTRUE(st$char[rr])) {
      raw <- trimws(as.character(d[[j]]))
      z <- safe_num(raw)
      div <- st$divisor[rr]
      if(is.finite(div)&&div!=1) {
        nonblank <- raw[nzchar(raw)&!is.na(raw)]
        if(length(nonblank)&&!any(grepl(".",nonblank,fixed=TRUE))) z <- z*div
      }
      d[[j]] <- z
    } else d[[j]] <- trimws(as.character(d[[j]]))
  }
  d
}

choose_one <- function(nms,candidates) {
  uu <- toupper(nms)
  j <- match(toupper(candidates),uu,nomatch=0L)
  j <- j[j>0L]
  if(length(j)) nms[j[1]] else NA_character_
}

read_isced_bridge <- function(year) {
  bridge_file <- file.path(BRIDGE_ROOT,paste0("PISA_",year,"_ISCEDL_BRIDGE.rds"))
  if(file.exists(bridge_file)) {
    b <- tryCatch(readRDS(bridge_file),error=function(e)NULL)
    if(is.data.frame(b)&&all(c("CNT","STUDENT_ID","ISCEDL")%in%names(b)))
      return(b)
  }

  data_path <- sources$path[sources$year==year&sources$role=="data"][1]

  if(year%in%c(2006,2012)) {
    control <- sources$path[sources$year==year&sources$role=="control"][1]
    st <- dictionary_sas_setup(control)
    cnt <- choose_one(st$variable,c("CNT","COUNTRY"))
    sid <- choose_one(st$variable,c("CNTSTUID","STIDSTD","STUDENTID"))
    sch <- choose_one(st$variable,c("CNTSCHID","SCHOOLID","SCHOOL_ID"))
    isc <- choose_one(st$variable,c("ISCEDL"))
    if(any(is.na(c(cnt,sid,isc))))
      stop(year,": CNT/student ID/ISCEDL not found in SAS setup.")
    d <- read_selected_fwf(data_path,control,na.omit(c(cnt,sid,sch,isc)))
  } else {
    p <- data_path; td <- NULL
    if(tolower(tools::file_ext(p))=="zip") {
      zl <- utils::unzip(p,list=TRUE)
      ext <- if(any(grepl("\\.SAV$",toupper(zl$Name)))) "sav" else "sas7bdat"
      ex <- extract_zip_member(p,ext)
      p <- ex$path; td <- ex$tempdir
      on.exit(unlink(td,recursive=TRUE,force=TRUE),add=TRUE)
    }
    h <- if(grepl("\\.sav$",p,ignore.case=TRUE))
      haven::read_sav(p,n_max=1) else haven::read_sas(p,n_max=1)
    nms <- names(h)
    cnt <- choose_one(nms,c("CNT","COUNTRY"))
    sid <- choose_one(nms,c("CNTSTUID","STIDSTD","STUDENTID"))
    sch <- choose_one(nms,c("CNTSCHID","SCHOOLID","SCHOOL_ID"))
    isc <- choose_one(nms,c("ISCEDL"))
    if(any(is.na(c(cnt,sid,isc))))
      stop(year,": CNT/student ID/ISCEDL not found in raw PUF.")
    cols <- na.omit(c(cnt,sid,sch,isc))
    d <- if(grepl("\\.sav$",p,ignore.case=TRUE))
      haven::read_sav(p,col_select=tidyselect::any_of(cols)) else
      haven::read_sas(p,col_select=tidyselect::any_of(cols))
  }

  names(d) <- toupper(names(d))
  cnt_actual <- choose_one(names(d),c("CNT","COUNTRY"))
  sid_actual <- choose_one(names(d),c("CNTSTUID","STIDSTD","STUDENTID"))
  sch_actual <- choose_one(names(d),c("CNTSCHID","SCHOOLID","SCHOOL_ID"))
  isc_actual <- choose_one(names(d),c("ISCEDL"))

  b <- data.frame(
    CNT=toupper(trimws(as.character(d[[cnt_actual]]))),
    STUDENT_ID=trimws(as.character(d[[sid_actual]])),
    RAW_SCHOOL_ID=if(!is.na(sch_actual))trimws(as.character(d[[sch_actual]])) else "",
    ISCEDL=safe_num(d[[isc_actual]]),
    stringsAsFactors=FALSE
  )
  b <- b[!is.na(b$CNT)&nzchar(b$CNT)&!is.na(b$STUDENT_ID)&nzchar(b$STUDENT_ID),]
  b <- b[!duplicated(paste(b$CNT,b$STUDENT_ID,sep="::")),]
  saveRDS(b,bridge_file,compress=FALSE)
  b
}

# =============================================================================
# Build bridges
# =============================================================================

years <- c(2006,2012,2015,2018,2022,2025)
bridges <- setNames(vector("list",length(years)),years)
for(yr in years) {
  cat("Building/reusing ISCEDL bridge for PISA ",yr,"...\n",sep="")
  bridges[[as.character(yr)]] <- read_isced_bridge(yr)
  cat("  rows: ",nrow(bridges[[as.character(yr)]]),"\n",sep="")
}

# =============================================================================
# Country×wave sorting worker
# =============================================================================

STD_ROOT <- file.path(ROOT,"15_rc1_pisa_normalised","standardised_extracts")

modal_worker <- function(task) {
  year <- as.integer(task$year)
  cc <- as.character(task$source_country_code)
  cache <- as.character(task$cache)
  if(file.exists(cache)) {
    x <- tryCatch(readRDS(cache),error=function(e)NULL)
    if(is.list(x)&&identical(x$cache_version,"modal_isced_v1")) return(x)
  }

  d <- readRDS(as.character(task$path))
  names(d) <- toupper(names(d))
  br <- task$bridge[[1]]
  br <- br[br$CNT==cc,c("STUDENT_ID","ISCEDL"),drop=FALSE]

  d$STUDENT_ID <- as.character(d$STUDENT_ID)
  d <- merge(d,br,by="STUDENT_ID",all.x=TRUE,sort=FALSE)

  w0 <- safe_num(d$W_FSTUWT)
  isc <- safe_num(d$ISCEDL)

  valid <- is.finite(isc)
  if(sum(valid)<100L)
    stop(year," ",cc,": insufficient ISCEDL data.")

  # OECD wording is sample-based: each level attended by >= 1/3 of sample.
  tab <- table(isc[valid])
  shares_unweighted <- tab/sum(tab)
  modal_levels <- as.numeric(names(shares_unweighted)[shares_unweighted>=1/3])
  if(!length(modal_levels))
    modal_levels <- as.numeric(names(which.max(shares_unweighted)))

  school <- as.character(d$SCHOOL_ID)
  modal_schools <- unique(school[valid & isc%in%modal_levels & !is.na(school)&nzchar(school)])
  keep <- !is.na(school)&school%in%modal_schools

  if(sum(keep)<100L)
    stop(year," ",cc,": modal-school restriction retained too few students.")

  dm <- d[keep,,drop=FALSE]
  wm <- safe_num(dm$W_FSTUWT)
  escs <- safe_num(dm$ESCS)

  # social sorting
  rr <- weighted_midrank(escs,wm)
  social_rank <- between_share(rr,dm$SCHOOL_ID,wm)
  social_raw <- between_share(escs,dm$SCHOOL_ID,wm)

  rw <- grep("^RW[0-9]+$",names(dm),value=TRUE)
  rw <- rw[order(safe_num(sub("^RW","",rw)))]
  if(length(rw)!=80L) stop(year," ",cc,": expected 80 replicate weights.")

  rep_rank <- rep_raw <- rep(NA_real_,80)
  for(r in seq_along(rw)) {
    wr <- safe_num(dm[[rw[r]]])
    rrank <- weighted_midrank(escs,wr)
    rep_rank[r] <- between_share(rrank,dm$SCHOOL_ID,wr)
    rep_raw[r] <- between_share(escs,dm$SCHOOL_ID,wr)
  }
  vr <- brr_variance(social_rank,rep_rank)
  vraw <- brr_variance(social_raw,rep_raw)

  social <- rbind(
    data.frame(
      year=year,source_country_code=cc,
      statistic="social_rank_school_sorting_share_modal_isced",
      estimate=social_rank,se=sqrt(vr),
      ci_low=social_rank-1.96*sqrt(vr),ci_high=social_rank+1.96*sqrt(vr),
      stringsAsFactors=FALSE
    ),
    data.frame(
      year=year,source_country_code=cc,
      statistic="social_raw_escs_school_sorting_share_modal_isced",
      estimate=social_raw,se=sqrt(vraw),
      ci_low=social_raw-1.96*sqrt(vraw),ci_high=social_raw+1.96*sqrt(vraw),
      stringsAsFactors=FALSE
    )
  )

  # academic sorting
  pv <- grep("^PV[0-9]+READ$",names(dm),value=TRUE)
  pv <- pv[order(safe_num(sub("^PV([0-9]+)READ$","\\1",pv)))]
  th <- U <- rep(NA_real_,length(pv))

  for(m in seq_along(pv)) {
    y <- safe_num(dm[[pv[m]]])
    full <- between_share(y,dm$SCHOOL_ID,wm)
    reps <- rep(NA_real_,80)
    for(r in seq_along(rw))
      reps[r] <- between_share(y,dm$SCHOOL_ID,safe_num(dm[[rw[r]]]))
    th[m] <- full
    U[m] <- brr_variance(full,reps)
  }
  cmb <- combine_pv(th,U)
  academic <- data.frame(
    year=year,source_country_code=cc,
    statistic="academic_school_sorting_share_modal_isced",
    estimate=cmb["estimate"],se=cmb["se"],
    ci_low=cmb["estimate"]-1.96*cmb["se"],
    ci_high=cmb["estimate"]+1.96*cmb["se"],
    stringsAsFactors=FALSE
  )

  coverage <- data.frame(
    year=year,source_country_code=cc,
    modal_levels=paste(modal_levels,collapse=";"),
    iscedl_nonmissing_unweighted_share=mean(valid),
    modal_level_unweighted_share=mean(valid & isc%in%modal_levels),
    modal_school_unweighted_share=mean(keep),
    modal_school_weighted_share=sum(w0[keep & is.finite(w0)&w0>0],na.rm=TRUE)/
      sum(w0[is.finite(w0)&w0>0],na.rm=TRUE),
    n_students_all=nrow(d),
    n_students_modal_school=sum(keep),
    n_schools_all=length(unique(school[!is.na(school)&nzchar(school)])),
    n_schools_modal=length(modal_schools),
    stringsAsFactors=FALSE
  )

  ans <- list(cache_version="modal_isced_v1",
              social=social,academic=academic,coverage=coverage)
  saveRDS(ans,cache,compress=FALSE)
  ans
}

# Build tasks; bridge list-column stays small enough to export with task.
tasks <- list(); ii <- 1L
for(yr in years) {
  cdir <- file.path(STD_ROOT,paste0("PISA_",yr,"_countries"))
  ff <- list.files(cdir,pattern="\\.rds$",full.names=TRUE)
  bridge <- bridges[[as.character(yr)]]
  for(f in ff) {
    cc <- toupper(tools::file_path_sans_ext(basename(f)))
    tasks[[ii]] <- list(
      year=yr,source_country_code=cc,path=f,
      cache=file.path(CACHE_ROOT,paste0(yr,"_",cc,".rds")),
      bridge=bridge
    )
    ii <- ii+1L
  }
}
rows <- tasks
cat("Modal-ISCED country×wave tasks: ",length(rows),"\n",sep="")

export_names <- c(
  "safe_num","weighted_midrank","between_share","brr_variance",
  "combine_pv","FAY_VARIANCE_FACTOR","modal_worker"
)
ans <- run_tasks_stable(rows,modal_worker,CPU_WORKERS,export_names,environment())
workers_used <- attr(ans,"workers_used")

social <- do.call(rbind,lapply(ans,`[[`,"social"))
academic <- do.call(rbind,lapply(ans,`[[`,"academic"))
coverage <- do.call(rbind,lapply(ans,`[[`,"coverage"))

# country mapping
BUNDLE <- file.path(ROOT,"11_dashboard_bundle_v2")
cm <- read.csv(file.path(BUNDLE,"country_source_codes.csv"),stringsAsFactors=FALSE)
cm <- cm[cm$survey=="PISA",c("source_country_code","country_id")]
cm$source_country_code <- toupper(cm$source_country_code)
cm <- cm[!duplicated(cm$source_country_code),]

social <- merge(social,cm,by="source_country_code",all.x=TRUE,sort=FALSE)
academic <- merge(academic,cm,by="source_country_code",all.x=TRUE,sort=FALSE)
coverage <- merge(coverage,cm,by="source_country_code",all.x=TRUE,sort=FALSE)

write.csv(social,file.path(OUT,"PISA_MODAL_ISCED_SOCIAL_SORTING.csv"),row.names=FALSE)
write.csv(academic,file.path(OUT,"PISA_MODAL_ISCED_ACADEMIC_SORTING.csv"),row.names=FALSE)
write.csv(coverage,file.path(OUT,"PISA_MODAL_ISCED_COVERAGE.csv"),row.names=FALSE)

# NLD 2018 sanity: OECD published modal-school sample coverage ~99.0%.
nld18 <- coverage[coverage$year==2018 & coverage$country_id=="iso3:NLD",]
sanity <- data.frame(
  check="NLD_2018_modal_school_unweighted_share_vs_OECD_99pct",
  observed=if(nrow(nld18))100*nld18$modal_school_unweighted_share[1] else NA,
  official_reference=99.0,
  abs_diff_pp=if(nrow(nld18))abs(100*nld18$modal_school_unweighted_share[1]-99.0) else NA,
  status=if(nrow(nld18) && abs(100*nld18$modal_school_unweighted_share[1]-99.0)<=1.5)
    "PASS_le1.5pp" else "INSPECT",
  stringsAsFactors=FALSE
)
write.csv(sanity,file.path(OUT,"PISA_MODAL_ISCED_SANITY.csv"),row.names=FALSE)

writeLines(c(
  "PISA RC1 MODAL-ISCED SORTING V1",
  paste0("Created: ",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  paste0("Workers used: ",workers_used),
  paste0("NLD 2018 modal-school coverage observed: ",round(sanity$observed,2),"%"),
  paste0("OECD reference: 99.0%; sanity status: ",sanity$status),
  "",
  "These are the preferred PISA main-specification sorting estimates.",
  "Previous full-sample results remain unrestricted robustness results.",
  "Official OECD inclusion-table validation still has to be closed before release."
),file.path(OUT,"README_MODAL_ISCED.txt"))

# metadata-only zip
if(!requireNamespace("zip",quietly=TRUE)) {
  install.packages("zip",repos="https://cloud.r-project.org",type="binary")
}
zipfile <- file.path(
  HANDOFF_DIR,paste0("PISA_PIRLS_RC1_MODAL_ISCED_SORTING_",STAMP,".zip")
)
ff <- list.files(OUT,full.names=TRUE,recursive=TRUE)
ff <- ff[!grepl("\\.rds$",ff,ignore.case=TRUE)]
zip::zipr(zipfile,files=ff,root=OUT,include_directories=FALSE)

cat("\n============================================================\n")
cat("MODAL-ISCED SORTING COMPLETE\n")
cat("============================================================\n")
print(sanity,row.names=FALSE)
cat("\nUPLOAD ONLY:\n",norm(zipfile),"\n",sep="")
