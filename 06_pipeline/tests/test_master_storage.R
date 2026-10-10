# Synthetic-only, no original research data, network access or deletions.
source("06_pipeline/MASTER_STORAGE.R",encoding="UTF-8")
base<-tempfile("test_master_inventory_")
root<-file.path(base,"PISA_PIRLS_MASTER_PIPELINE")
state<-file.path(base,"LO05_RESULTATEN","master_reconciliation")
dir.create(root,recursive=TRUE);dir.create(state,recursive=TRUE)
add<-function(rel,bytes=10L) {
 p<-file.path(root,rel)
 dir.create(dirname(p),recursive=TRUE,showWarnings=FALSE)
 writeBin(as.raw(rep(41L,bytes)),p)
}
add("00_PROJECT_REGISTRY/PROJECT_RESULTS_REGISTRY.sqlite")
add("03_RESULTS/current/CURRENT_RESULTS.parquet",16L)
add("05_pirls_results/cache/pirls_results.rds")
add("official_source/pisa_students.sav")
add("scripts/analysis.R")
add("decks/BR_POLICY_21.pptx")
add("misc/unknown.xyz")
cfg<-list(root=normalizePath(root,winslash="/",mustWork=TRUE),
 state=normalizePath(state,winslash="/",mustWork=TRUE),
 remote="lo_private:Learning-Outcomes-Private/Canonical-Results-v1")
files<-lo_master_inventory(cfg)
stopifnot(nrow(files)==7L,
  identical(files$classification[files$relative_path==
     "official_source/pisa_students.sav"],"SOURCE_OR_MICRODATA_HOLD"),
  identical(files$classification[files$relative_path==
     "03_RESULTS/current/CURRENT_RESULTS.parquet"],
           "CANONICAL_REGISTRY_PROTECTED"),
  sum(files$bytes)==16L+6*10L)
status_dir<-lo_master_record_run_status(cfg,"storage-audit")
stopifnot(file.exists(file.path(status_dir,"STATUS.txt")),
  any(grepl("^STORAGE_FILES_SCANNED=7$",
      readLines(file.path(status_dir,"STATUS.txt")))))
plan<-lo_master_plan(cfg)
stopifnot(!any(plan$can_delete_local=="YES"),
          identical(plan$storage_action[plan$relative_path==
                "official_source/pisa_students.sav"],
                    "HOLD_SOURCE_NOT_FOR_AUTOMATIC_CLOUD_TRANSFER"),
          identical(plan$storage_action[plan$relative_path==
                "00_PROJECT_REGISTRY/PROJECT_RESULTS_REGISTRY.sqlite"],
                    "HOLD_DB_SNAPSHOT_REQUIRED"))
gc<-lo_master_gc_plan(cfg)
stopifnot(!any(gc$can_delete_now),all(file.exists(
  file.path(cfg$root,files$relative_path))))
# A copy to private Drive alone must NEVER be enough to retire local values.
fake<-data.frame(relative_path="05_pirls_results/cache/pirls_results.rds",
 bytes=10,sha256=paste(rep("a",64),collapse=""),
 remote_object="objects/aa/a.rds",verification="READBACK_SHA256_PASS")
lo_master_write_csv(fake,file.path(cfg$state,"VERIFIED_CLOUD_ARTIFACTS.csv"))
gc<-lo_master_gc_plan(cfg)
stopifnot(any(gc$retirement_status=="HOLD_SECOND_BACKUP_AND_PRODUCT_LINEAGE"),
          !any(gc$can_delete_now))
denied<-try(lo_master_action("storage-cleanup-apply"),silent=TRUE)
# This direct test may also fail before root discovery, but it must never delete.
stopifnot(inherits(denied,"try-error"))
stopifnot(all(file.exists(file.path(cfg$root,files$relative_path))))
unlink(base,recursive=TRUE)
cat("PASS metadata-only master scan, privacy classification and fail-closed cleanup\n")
