source('06_pipeline/LO_ENVIRONMENT.R')
work<-tempfile('env_');dir.create(work)
lock<-list(R=list(Version=as.character(getRversion())),Packages=list(
 digest=list(Package='digest',Version=as.character(packageVersion('digest')))))
jsonlite::write_json(lock,file.path(work,'renv.lock'),auto_unbox=TRUE)
a<-lo_environment_check(work,strict=TRUE)
stopifnot(a$all_match,nrow(a$versions)==2L)
lock$Packages$digest$Version<-'0.0.0'
jsonlite::write_json(lock,file.path(work,'renv.lock'),auto_unbox=TRUE)
stopifnot(!lo_environment_check(work)$all_match,
 inherits(try(lo_environment_check(work,strict=TRUE),silent=TRUE),'try-error'))
unlink(work,recursive=TRUE)
cat('PASS immutable environment check, changed-version rejection and actual version evidence\n')
