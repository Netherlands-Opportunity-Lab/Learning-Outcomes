# One internal module of 06_pipeline/RUN.R; no learner estimators or release here.
# Verifies all slide/dashboard/paper contracts against the unchanged October bundle.
lo_product_gate <- function(bundle, output_root, expected=list(
    tasks=79448L, figures=138L, paper=8L, refs=300L,
    nld=1867L, oecd19=27979L, other=49602L, ranks=6L)) {
  read_contract <- function(name) {
    p <- file.path(bundle,name)
    if(!file.exists(p)) stop("Contract missing: ",name)
    con <- if(grepl("[.]gz$",p)) gzfile(p,"rt") else file(p,"rt")
    on.exit(close(con),add=TRUE)
    read.csv(con,colClasses="character",check.names=FALSE,
             na.strings=character(),stringsAsFactors=FALSE)
  }
  require <- function(ok,label) if(!isTRUE(ok))
    stop("CONTRACT_INTEGRITY_FAIL: ",label,call.=FALSE)
  tasks <- read_contract("engine/TASKS.csv")
  figures <- read_contract("FIGURE_SERIES_CONTRACT_20261002.csv")
  links <- read_contract("PRODUCT_FIGUUR_RESULTAAT.csv.gz")
  paper <- read_contract("OPEN_PAPER_REQUIREMENTS.csv")
  ref <- read_contract("REFERENTIE_ASSEMBLAGE.csv.gz")
  comparator <- read_contract("PPP_COMPARATOR_MEMBERSHIP_v2.csv")
  require(nrow(tasks)==expected$tasks,"task count")
  require(nrow(figures)==expected$figures,"figure count")
  require(nrow(paper)==expected$paper,"paper contract count")
  require(nrow(links)==nrow(tasks),"task/product mapping count")
  require(!anyDuplicated(tasks$metric_key)&&!anyDuplicated(links$metric_key),"unique metric keys")
  require(setequal(tasks$metric_key,links$metric_key),"one mapping per task")
  require(!anyDuplicated(figures$figure_id),"unique figure IDs")
  if(identical(expected$paper,8L))
    require(identical(sort(paper$requirement_id),sprintf("Q%02d",1:8)),"Q01-Q08")
  r <- ref[ref$reference=="OECD_GDP_PPP_GE_CZE_2024",,drop=FALSE]
  require(nrow(r)==expected$refs&&length(unique(r$eligible_members))==1L,
          "fixed reference series and membership")
  ge <- strsplit(r$eligible_members[1L],";",fixed=TRUE)[[1L]]
  foreign <- sort(setdiff(ge,c("NLD","CZE")))
  require(length(foreign)==19L&&!"NLD"%in%foreign&&!"CZE"%in%foreign,
          "19 foreign countries")
  require(setequal(comparator$country[comparator$strictly_above_czechia=="TRUE"],
                   c(foreign,"NLD")),"strict foreign membership")
  scientific_keys <- c("survey","domain","module","stat","group","definition",
                       "peer_definition","threshold","unit","calculation_policy")
  require(all(scientific_keys%in%names(tasks)),"semantic task keys")
  task_series <- do.call(paste,c(tasks[scientific_keys],sep="|"))
  wanted <- unlist(Map(function(series,years)
    paste(series,strsplit(years,";",fixed=TRUE)[[1L]],sep="~YEAR~"),
    r$series_id,r$years),use.names=FALSE)
  phase <- rep("OTHER",nrow(tasks))
  phase[tasks$country=="NLD"] <- "NLD"
  phase[tasks$country%in%foreign&
        paste(task_series,tasks$year,sep="~YEAR~")%in%wanted] <- "OECD19"
  counts <- table(factor(phase,levels=c("NLD","OECD19","OTHER")))
  require(identical(unname(as.integer(counts)),
     as.integer(c(expected$nld,expected$oecd19,expected$other))),
     "contract country/scope counts")
  unmapped <- setdiff(figures$figure_id,links$contract_figure_id)
  require(length(unmapped)==expected$ranks &&
       all(grepl("^TR_POSITION_",unmapped)) &&
       !length(setdiff(links$contract_figure_id,figures$figure_id)),
       "unlinked figures must be derived country rank outcomes")
  fig <- data.frame(figure_id=figures$figure_id,
    survey=figures$survey,age=figures$age,domain=figures$domain,
    outcome=figures$outcome,release_role=figures$release_role,
    contract_reference=figures$comparison_default,
    configured_reference="OECD_PPP_GT_CZE_2024_RECONSTRUCTED",
    comparator_review=ifelse(figures$comparison_default==
      "OECD_PPP_GT_CZE_2024_RECONSTRUCTED","ALIGNED",
      "REVIEW_SCOPE_DIFFERS_FROM_FIGURE_CONTRACT"),
    scientific_status=ifelse(figures$figure_id%in%unmapped,
      "DERIVE_RANK_ONLY_FROM_VALIDATED_COUNTRY_RESULTS",
      "NOT_RELEASED_REQUIRES_RECORD_VERSION_AND_METHOD_VALIDATION"),
    stringsAsFactors=FALSE)
  tab <- table(links$contract_figure_id)
  fig$linked_contracts <- as.integer(tab[fig$figure_id])
  fig$linked_contracts[is.na(fig$linked_contracts)] <- 0L
  links$phase <- phase[match(links$metric_key,tasks$metric_key)]
  for(target in c("NLD","OECD19")) {
    n <- table(links$contract_figure_id[links$phase==target])
    field <- if(target=="NLD")"nl_contracts" else "reference_contracts"
    fig[[field]] <- as.integer(n[fig$figure_id])
    fig[[field]][is.na(fig[[field]])] <- 0L
  }
  slides <- data.frame(slide=1:13,
    purpose=c("Title","Means","P10/P50/P90","SES levels","SES gaps",
              "Basic proficiency by SES","Gender means","Home language means",
              "Migration means","Low-SES pupils' high-SES peers",
              "High-SES pupils' low-SES peers","Language peer composition",
              "Migration peer composition"),
    outcome=c("","mean_score","p10;p50;p90","ses_mean_levels",
              "ses_score_gap","ses_basic_levels","gender_mean_levels",
              "home_language_mean_levels","migration_mean_levels",
              "ses_peer_exposure","ses_peer_exposure",
              "home_language_peer_exposure","migration_peer_exposure"),
    science_status=c("TITLE_NO_DATA",rep("NOT_SCIENTIFICALLY_RELEASED",8),
       "Q1_TO_Q4_PEER_GROUP_BINDING_REVIEW","Q4_TO_Q1_PEER_GROUP_BINDING_REVIEW",
       "LANGUAGE_UNIT_AND_DEFINITION_REVIEW",
       "MIGRATION_AND_PEER_UNIT_REVIEW"),
    stringsAsFactors=FALSE)
  slides$figure_contracts <- vapply(slides$outcome,function(x)
    if(!nzchar(x))0L else sum(figures$outcome%in%
      strsplit(x,";",fixed=TRUE)[[1L]]),integer(1))
  require(all(slides$figure_contracts[-1]>0L),"current 13-slide deck outcome families")
  # Never interpret historical source_slides column as the NEW 13-slide numbering.
  paper$scientific_release_status <- "REVIEW_REQUIRED_NO_VALIDATED_SOURCE_ADAPTER"
  by_module <- as.data.frame(table(phase=phase,module=tasks$module))
  names(by_module)[3] <- "task_contracts"
  by_module <- by_module[by_module$task_contracts>0L,,drop=FALSE]
  by_module$engine_status <- ifelse(by_module$module%in%
      c("ses_harmonized","migration_generation","migration_peer_exposure"),
      "NO_VERIFIED_DIRECT_ADAPTER",
      ifelse(by_module$module%in%c("core","gender"),
      "PISA_CORE_GENDER_ONLY_APPROVED_SUBSET",
      "V11_CANDIDATE_REQUIRES_METHOD_REVIEW"))
  preflight <- data.frame(
    check=c("CONTRACT_JOIN","NL_SCOPE","OECD19_SCOPE","OTHER_SCOPE",
       "FIGURE_CONTRACTS","DIRECT_LINKED_FIGURES","DERIVED_POSITION_FIGURES",
       "PAPER_GATES_OPEN","TIMSS_1995_GRID","COMPARATOR_DEFAULT","KERNEL_SLIDE_MAP",
       "SCIENTIFIC_RELEASE"),
    value=c("PASS",as.character(counts[[1]]),as.character(counts[[2]]),
      as.character(counts[[3]]),as.character(nrow(figures)),
      as.character(nrow(figures)-length(unmapped)),as.character(length(unmapped)),
      as.character(nrow(paper)),"NOT_IN_GRID",
      "DIFFERENT_FROM_19_COUNTRY_PRODUCTION_SCOPE",
      "13_SLIDE_FAMILY_LINKS_REVIEW_GROUP_DETAILS","NOT_GRANTED"),
    stringsAsFactors=FALSE)
  dir.create(output_root,recursive=TRUE,showWarnings=FALSE)
  dest <- file.path(output_root,paste0("scope_preflight_",
                  format(Sys.time(),"%Y%m%d_%H%M%S")))
  if(!dir.create(dest,showWarnings=FALSE))stop("Could not create new contract report")
  atomic <- function(x,name) {
    tmp <- tempfile(tmpdir=dest)
    on.exit(if(file.exists(tmp))unlink(tmp),add=TRUE)
    write.csv(x,tmp,row.names=FALSE,na="",fileEncoding="UTF-8")
    if(!file.rename(tmp,file.path(dest,name)))stop("Atomic report write failed")
  }
  atomic(preflight,"PRODUCT_SCOPE_STATUS.csv")
  atomic(fig,"FIGURE_REQUIREMENT_STATUS.csv")
  atomic(slides,"SLIDE_13_REQUIREMENT_STATUS.csv")
  atomic(paper,"PAPER_Q01_Q08_STATUS.csv")
  atomic(by_module,"SCIENTIFIC_ADAPTER_REQUIREMENTS.csv")
  cat("Product contract PASS: ",counts[[1]]," NL, ",counts[[2]],
      " OECD19, ",counts[[3]]," other tasks; 138 figure contracts, ",
      length(unmapped)," derived ranks, 8 paper gates open.\n",sep="")
  invisible(list(report_dir=dest,counts=counts,
                 positions=unmapped,open_paper=paper$requirement_id))
}
