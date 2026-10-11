# Pinned science code/artifact discovery; internal to the ONE RUN.R entry point.
# Recovers the specific October v2 archive, never blends older module versions.
lo_bundle_expected_sha <- "ceddf194ab3ad60bee5100450145f879aec17073b7567ed6127bf071eb6869dc"
lo_bundle_verify <- function(bundle) {
  if(!requireNamespace("digest",quietly=TRUE))
    stop("Package digest is required for scientific source integrity")
  key <- file.path(bundle,"MANIFEST_SHA256.csv")
  if(!file.exists(key))stop("Bundle missing manifest")
  m <- read.csv(key,colClasses="character",stringsAsFactors=FALSE)
  if(!all(c("path","sha256")%in%names(m))||nrow(m)!=56L||
     anyDuplicated(m$path)||
     any(grepl("(^/|^[A-Za-z]:|[.][.]/|\\\\)",m$path)))
    stop("SOURCE_MANIFEST_INVALID")
  for(i in seq_len(nrow(m))) {
    p<-file.path(bundle,m$path[i])
    if(!file.exists(p)||dir.exists(p)||
       !identical(unname(digest::digest(file=p,algo="sha256")),m$sha256[i]))
      stop("SCIENCE_SOURCE_SHA256_FAIL: ",m$path[i])
  }
  anchored <- c("code/INTEGRATED.R"=
                   "32d78da7dd87a83f8c3bc5e470fe098cb87d95d940d8e1f72bfcffe9af2cab88",
                "engine/BACKEND.R"=
                   "6d0f91e562f3ed3d85f34761e98d148b8c222848cdd2542dc5557587e61e1aab",
                "engine/V11.R"=
                   "cdf8fd154028452698a5110044c63bf2ccfc957aa56f881a01fc424609ea29dc")
  ix <- match(names(anchored),m$path)
  if(anyNA(ix)||!identical(unname(m$sha256[ix]),unname(anchored)))
    stop("OCTOBER_SCIENCE_ENGINE_ANCHOR_CHANGED")
  invisible(TRUE)
}
lo_bundle_discover <- function() {
  explicit <- Sys.getenv("LO05_BUNDLE","")
  if(nzchar(explicit)) {
    if(!dir.exists(explicit))stop("LO05_BUNDLE directory missing: ",explicit)
    lo_bundle_verify(explicit)
    return(normalizePath(explicit,winslash="/",mustWork=TRUE))
  }
  home <- Sys.getenv("USERPROFILE",unset=path.expand("~"))
  bases <- unique(c(file.path(home,"Downloads"),
       file.path(path.expand("~"),"Downloads"),
       file.path(home,"Documents","Downloads")))
  for(base in bases) {
    candidates <- c(file.path(base,"LEARNING_OUTCOMES_PIPELINE"),
       file.path(base,"LEARNING_OUTCOMES_INTEGRAAL_v2_20261010",
                 "LEARNING_OUTCOMES_PIPELINE"))
    for(p in candidates) {
      if(!dir.exists(p))next
      valid <- tryCatch({lo_bundle_verify(p);TRUE},error=function(e)e)
      if(identical(valid,TRUE))return(normalizePath(p,winslash="/",mustWork=TRUE))
      message("Found older/different bundle: ",p,"; checking exact v2 archive")
    }
  }
  archives <- unlist(lapply(bases,function(base)
    file.path(base,c("LEARNING_OUTCOMES_INTEGRAAL_v2_20261010.zip",
                     "LEARNING_OUTCOMES_INTEGRAAL_v2_20261010(1).zip"))),
    use.names=FALSE)
  archives <- archives[vapply(archives,function(x)isTRUE(file.exists(x)),logical(1))]
  if(!length(archives)) {
    # Consult the completed 35k-file inventory, not a fresh recursive disk scan.
    state <- file.path(home,"Downloads","LO05_RESULTATEN",
                       "master_reconciliation","MASTER_FILES_PRIVATE.csv")
    inventory_found <- character()
    if(file.exists(state)) {
      inv <- tryCatch(read.csv(state,stringsAsFactors=FALSE,
                               check.names=FALSE),error=function(e)NULL)
      root <- Sys.getenv("LO_MASTER_PROJECT_ROOT",
                         file.path(home,"Downloads","PISA_PIRLS_MASTER_PIPELINE"))
      if(!is.null(inv) && "relative_path" %in% names(inv)) {
        likely <- inv$relative_path[grepl(
          "LEARNING_OUTCOMES_INTEGRAAL|OCTOBER.*BUNDLE|20261010.*[.]zip$",
          inv$relative_path,ignore.case=TRUE)]
        inventory_found <- file.path(root,likely)
        inventory_found <- inventory_found[file.exists(inventory_found) &
                         grepl("[.]zip$",inventory_found,ignore.case=TRUE)]
      }
    }
    archives <- unique(c(archives,inventory_found))
  }
  if(!length(archives))
    stop("OCTOBER_V2_BUNDLE_ABSENT: Checked usual Downloads locations and ",
         "completed project inventory. Other analyses may proceed; ",
         "product-contract validation requires the SHA-locked October v2 ZIP.")
  for(zip in archives) {
    hash <- unname(digest::digest(file=zip,algo="sha256"))
    if(!identical(hash,lo_bundle_expected_sha))next
    entries <- utils::unzip(zip,list=TRUE)
    paths <- entries$Name
    safe <- paths=="LEARNING_OUTCOMES_RUN.R" |
      startsWith(paths,"LEARNING_OUTCOMES_PIPELINE/")
    if(length(paths)>100L||anyDuplicated(paths)||any(!safe)||
       any(grepl("[.][.][/\\\\]|^[A-Za-z]:|^/",paths))||
       sum(entries$Length,na.rm=TRUE)>160e6)
      stop("Unsafe or changed science ZIP entry layout")
    destroot<-file.path(dirname(zip),"LO_SCIENTIFIC_BUNDLES")
    dest<-file.path(destroot,substr(hash,1,20))
    bundle<-file.path(dest,"LEARNING_OUTCOMES_PIPELINE")
    if(dir.exists(dest)) {
      lo_bundle_verify(bundle)
      return(normalizePath(bundle,winslash="/",mustWork=TRUE))
    }
    dir.create(destroot,recursive=TRUE,showWarnings=FALSE)
    staging<-tempfile("verify_science_",tmpdir=destroot)
    if(!dir.create(staging))stop("Cannot stage science source")
    on.exit(if(dir.exists(staging))unlink(staging,recursive=TRUE),add=TRUE)
    utils::unzip(zip,exdir=staging)
    lo_bundle_verify(file.path(staging,"LEARNING_OUTCOMES_PIPELINE"))
    if(!file.rename(staging,dest))
      stop("Cannot atomically install the verified science bundle")
    return(normalizePath(bundle,winslash="/",mustWork=TRUE))
  }
  stop("Known v2 ZIP found but SHA-256 differs from audited science archive. ",
       "No silent upgrade or mixing of historical method files.")
}
