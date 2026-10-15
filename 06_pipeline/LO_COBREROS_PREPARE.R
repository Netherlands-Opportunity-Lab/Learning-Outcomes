# Reproduce only the chosen 13-item/four-wave R index, not the author's full
# table/figure/robustness workflow. All author files and extracts remain read-only.
# This prepares an input; it grants no scientific certificate to grid results.
lo_prepare_cobreros_four <- function(author, output_dir) {
for(pkg in c('data.table','arrow','Rcpp','digest','jsonlite','tidyselect'))
  if(!requireNamespace(pkg,quietly=TRUE))stop('COBREROS_MISSING_PACKAGE: ',pkg)
suppressPackageStartupMessages(library(data.table))
previous_threads<-getDTthreads();on.exit(setDTthreads(previous_threads),add=TRUE)
setDTthreads(1L)
author<-normalizePath(author,winslash='/',mustWork=TRUE)
dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
out<-normalizePath(output_dir,winslash='/',mustWork=TRUE)
if(startsWith(out,paste0(author,'/')))stop('COBREROS_OUTPUT_MUST_BE_SEPARATE_FROM_AUTHOR_CHECKOUT')
git<-Sys.which('git');if(!nzchar(git))stop('COBREROS_GIT_REQUIRED')
head <- trimws(system2(git,shQuote(c('-C',author,'rev-parse','HEAD')),stdout=TRUE))
stopifnot(head=='1da4b26097e84e732973af672355a1c3103d5d33')
inputs <- file.path(author,'data/extract',paste0('stu_',c(2015,2018,2022,2025),'.parquet'))
sources <- file.path(author,'code/r/R',c('core.R','irt.R','kernels.cpp'))
hashes <- data.frame(path=c(inputs,sources),sha256=vapply(c(inputs,sources),function(p)digest::digest(file=p,algo='sha256'),character(1)))
fingerprint <- digest::digest(list(head,hashes,protocol='R_PAPER_FOUR_13ITEMS_34_COUNTRIES_SELECTED_ESCS_ONLY_V1',adapter_body=body(lo_prepare_cobreros_four)),algo='sha256')
marker <- file.path(out,'PREPARATION_MANIFEST.json')
if(file.exists(marker)) {
 previous<-jsonlite::fromJSON(marker)
 if(!identical(previous$fingerprint,fingerprint))stop('COBREROS_CHANGED_INPUT_USE_NEW_OUTPUT_DIRECTORY')
 if(identical(previous$status,'CALIBRATION_PREPARED_REQUIRES_RAW_INPUT_AND_NLD_ESTIMATE_VERIFICATION')) {
  output<-file.path(out,previous$output_filename)
  if(!file.exists(output)||digest::digest(file=output,algo='sha256')!=previous$output_sha256)stop('COBREROS_PREPARED_OUTPUT_CHANGED')
  return(invisible(previous))
 }
}
env <- new.env(parent=globalenv())
# Function-only boot deliberately skips author's mkdir/sourceCpp top-level code.
for(p in sources[1:2])for(expr in parse(p)) {
 if(is.call(expr)&&identical(expr[[1]],as.name('<-'))&&is.call(expr[[3]])&&
    identical(expr[[3]][[1]],as.name('function')))eval(expr,env)
}
env$ROOT<-author;env$INTERIM<-out;env$CACHE<-file.path(out,'cache')
env$OUT<-out;env$AUDIT<-out
for(p in c(env$CACHE,file.path(out,'tables')))dir.create(p,recursive=TRUE,showWarnings=FALSE)
Rcpp::sourceCpp(sources[3],cacheDir=file.path(env$CACHE,'Rcpp'),env=env)
manifest<-list(status='PREPARATION_STARTED_NOT_GRID_CERTIFIED',fingerprint=fingerprint,
 author_commit=head,input_and_code_hashes=hashes,
 R=R.version.string,packages=lapply(c('data.table','arrow','Rcpp','digest','jsonlite'),function(p)list(package=p,version=as.character(packageVersion(p)))),
 selected='four waves; 13 items; paper common countries excluding CRI; R regression-imputed ESCS only',
 excluded='Two-wave model; OECD35 extension; PCA; no-imputation variant; author figures and result tables',
 official_trend_indices='Omitted: only supplies published-index sensitivity columns; does not enter paper-scope harmonized ESCS')
jsonlite::write_json(manifest,marker,auto_unbox=TRUE,pretty=TRUE,digits=17)
parts<-lapply(c(2015L,2018L,2022L,2025L),function(year) {
 fields<-if(year<=2018L)c(sprintf('st011q%02dta',c(2,4,5,6,9)),sprintf('st012q%02dta',c(1,2,3)),sprintf('st012q%02dna',6:9),'books6') else
 c(sprintf('st250q%02dja',c(1,2,3,5)),sprintf('st251q%02dja',c(1,3,6,7)),sprintf('st254q%02dja',1:5),'st255q01ja')
 keep<-c('wave','cnt','cntstuid','w_fstuwt','hisei','paredint','hisced')
 g<-env$read_extract(year,unique(c(keep,fields)))
 cbind(g[,c(keep,'raw_row'),with=FALSE],env$recode_four(g))
})
common<-setdiff(Reduce(intersect,lapply(parts,function(g)unique(g$cnt))),'CRI')
stopifnot(length(common)==34L,'NLD'%in%common)
d<-rbindlist(parts,fill=TRUE);rm(parts);d<-d[cnt%in%common];gc(FALSE)
stopifnot(!anyDuplicated(d[,.(wave,cnt,cntstuid)]),all(is.finite(d$w_fstuwt)&d$w_fstuwt>0))
mapping<-d[wave==2018L&is.finite(hisced)&is.finite(paredint),.(years=as.numeric(names(sort(table(paredint),decreasing=TRUE))[1])),by=hisced]
d[wave==2015L,paredint:=mapping$years[match(hisced,mapping$hisced)]]
d[,pared_c:=fifelse(paredint==3,6,fifelse(paredint==14.5,14,paredint))]
items<-c('room','computer','software','internet','art','instruments','cars','bathrooms','televisions','tablets','ereaders','computers','books')
manifest$calibration_countries<-sort(common);manifest$n<-nrow(d)
manifest$country_wave_counts<-d[,.(n=.N),by=.(cnt,wave)]
jsonlite::write_json(manifest,marker,auto_unbox=TRUE,pretty=TRUE,digits=17)
cat('Starting chosen four-cycle calibration for',nrow(d),'rows and',length(common),'countries\n');flush.console()
ir<-env$fit_and_score(d,items,8,'irt13')
w<-env$senate(d)
score<-env$escs(cbind(d$hisei,d$pared_c,ir$score),env$cell_id(d),w)
d[,`:=`(SES=score$score,homepos_irt=ir$score)]
# Retain only NLD analysis inputs; calibration parameters/diagnostics suffice
# for recomputation of other countries if subsequently approved.
selected<-d[cnt=='NLD',.(wave,cnt,cntstuid,raw_row,w_fstuwt,SES,homepos_irt,hisei,pared_c)]
path<-file.path(out,paste0('NLD_CHOSEN_SES_',substr(fingerprint,1,16),'.rds'))
if(file.exists(path))stopifnot(identical(readRDS(path),selected)) else saveRDS(selected,path,compress=FALSE)
expected<-fread(file.path(author,'results/r/tables/irt_parameters_four_cycles.csv'))
actual<-fread(file.path(out,'tables/irt_parameters_four_cycles.csv'))
stopifnot(identical(expected$item,actual$item))
diff_a<-max(abs(expected$a-actual$a))
diff_b<-max(vapply(seq_len(nrow(actual)),function(i)max(abs(jsonlite::fromJSON(expected$steps[i])-jsonlite::fromJSON(actual$steps[i]))),numeric(1)))
manifest$status<-'CALIBRATION_PREPARED_REQUIRES_RAW_INPUT_AND_NLD_ESTIMATE_VERIFICATION'
manifest$model_parameter_max_absolute_difference<-list(discrimination=diff_a,steps=diff_b)
manifest$output_sha256<-digest::digest(file=path,algo='sha256');manifest$output_filename<-basename(path)
manifest$valid_nld_ses<-selected[,.(n=.N,valid_ses=sum(is.finite(SES))),by=wave]
manifest$imputed_percent<-score$pct_imputed
jsonlite::write_json(manifest,marker,auto_unbox=TRUE,pretty=TRUE,digits=17)
print(manifest$model_parameter_max_absolute_difference)
cat('Chosen SES input prepared; no grid results certified automatically\n')

invisible(manifest)
}
