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
cat("PASS fixed-reference membership and mismatch fail-closed\n")
