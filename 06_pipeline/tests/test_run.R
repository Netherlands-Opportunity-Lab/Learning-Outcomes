# Pure smoke test: no microdata, no database writes, no product computations.
options(lo.pipeline.functions_only=TRUE)
source("06_pipeline/RUN.R",encoding="UTF-8")
repo <- normalizePath(".",winslash="/",mustWork=TRUE)
r <- read.csv("06_pipeline/reference_oecd19_2024.csv",stringsAsFactors=FALSE)
stopifnot(nrow(r)==19L,!anyDuplicated(r$country),
          !"NLD"%in%r$country,
          identical(unique(r$reference_id),"OECD_PPP_GT_CZE_2024_RECONSTRUCTED"))
bundle <- tempfile("mock_local_bundle_")
dir.create(bundle)
write.csv(data.frame(country=c(r$country,"NLD","CZE"),
 strictly_above_czechia=c(rep("TRUE",19),"TRUE","FALSE")),
 file.path(bundle,"PPP_COMPARATOR_MEMBERSHIP_v2.csv"),row.names=FALSE)
stopifnot(nrow(lo_pipeline_validate_reference(repo,bundle))==19L)
bad <- read.csv(file.path(bundle,"PPP_COMPARATOR_MEMBERSHIP_v2.csv"))
bad$country[1] <- "XXX"
write.csv(bad,file.path(bundle,"PPP_COMPARATOR_MEMBERSHIP_v2.csv"),row.names=FALSE)
e <- try(lo_pipeline_validate_reference(repo,bundle),silent=TRUE)
stopifnot(inherits(e,"try-error"))
unlink(bundle,recursive=TRUE)
# Regression: after RStudio restart, discover the previous Documents/Downloads
# cloud sync settings even when LO_DRIVE_SYNC_CONFIG is not retained.
tmpHome <- tempfile("win_profile_")
cfg <- file.path(tmpHome,"Documents","Downloads","LO05_RESULTATEN",
                 ".cloud_sync","drive.local.json")
dir.create(dirname(cfg),recursive=TRUE,showWarnings=FALSE)
writeLines("{}",cfg)
prevHome <- Sys.getenv("USERPROFILE",unset=NA_character_)
prevConfig <- Sys.getenv("LO_DRIVE_SYNC_CONFIG",unset=NA_character_)
Sys.setenv(USERPROFILE=tmpHome)
Sys.unsetenv("LO_DRIVE_SYNC_CONFIG")
stopifnot(identical(lo_pipeline_drive_config_path(),cfg))
if(is.na(prevHome)) {Sys.unsetenv("USERPROFILE")} else {Sys.setenv(USERPROFILE=prevHome)}
if(is.na(prevConfig)) {Sys.unsetenv("LO_DRIVE_SYNC_CONFIG")} else {Sys.setenv(LO_DRIVE_SYNC_CONFIG=prevConfig)}
unlink(tmpHome,recursive=TRUE)
cat("PASS fixed-reference membership and mismatch fail-closed\n")
