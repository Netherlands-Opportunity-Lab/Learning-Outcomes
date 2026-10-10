# One internal module of 06_pipeline/RUN.R; no learner estimators or release here.
# Verifies all slide/dashboard/paper contracts against the unchanged October bundle.
lo_product_gate <- function(bundle, output_root,
    product_register=file.path("06_pipeline","BR_POLICY_DECK_21_SOURCE_REGISTER_20261010.csv"),
    expected=list(
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
  expect_counts <- as.integer(c(expected$nld,expected$oecd19,expected$other))
  observed_counts <- unname(as.integer(counts))
  if(!identical(observed_counts,expect_counts))
    stop("CONTRACT_INTEGRITY_FAIL: scope counts observed=",
      paste(observed_counts,collapse="/")," expected=",
      paste(expect_counts,collapse="/"),
      " reference_series_match=",
      sum(paste(task_series,tasks$year,sep="~YEAR~")%in%wanted),
      call.=FALSE)
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
  # The uploaded 1 October user's authoritative policy deck has 21 slides,
  # NOT the provisional 13-slide October computation-kernel prototype.
  require(file.exists(product_register),"authoritative 21-slide register")
  slides <- read.csv(product_register,stringsAsFactors=FALSE,check.names=FALSE)
  required_slide_cols <- c("slide_number","title","analysis_family",
                           "release_status","product_id","product_sha256")
  require(all(required_slide_cols%in%names(slides)),
          "policy slide source register schema")
  require(identical(as.integer(slides$slide_number),seq_len(21L)),
          "authoritative policy deck MUST have all 21 slides in order")
  require(length(unique(slides$product_sha256))==1L &&
          identical(unique(slides$product_sha256),
            "cea8dc8a42c3e63e435c16ef13ea6cc1b634f5ca4d95af8c29dafba7397631ac"),
          "user-leading 1 October 21-slide sha256 changed")
  slides$contract_link_status <- ifelse(
       slides$analysis_family=="title","TITLE_NO_DATA",
       ifelse(slides$analysis_family%in%
          c("home_language_peer","home_language_means"),
          "MIXED_LANGUAGE_DEFINITIONS_SOURCE_VALIDATION_REQUIRED",
          "NEEDS_RESULT_VERSION_AND_PRODUCT_EQUIVALENCE_CHECK"))
  slides$historic_13_slide_alias <- "NOT_APPLICABLE_DIFFERENT_DECK"
  slides$comparison_requirement <- ifelse(slides$slide_number %in%
     c(2L,4L,5L,6L),"PRESERVE_ORIGINAL_42_PANEL_OR_ASSESSMENT_PANEL",
     ifelse(slides$slide_number %in% c(7L,8L,9L,21L),
             "COBREROS_13_COMMON_ITEMS",
             "RESPECT_SLIDE_SPECIFIC_POPULATION"))
  slides$numeric_result_lineage <- "NOT_VERIFIED_DO_NOT_AUTOPROMOTE"
  # The separate 50-slide scientific seminar and 16-page note are distinct
  # products. Their exact uploaded source hashes are in USER_PRODUCT_SOURCE_LOCK.
  lock <- file.path(dirname(product_register),"USER_PRODUCT_SOURCE_LOCK_20261010.csv")
  require(file.exists(lock),"scientific product lock")
  products <- read.csv(lock,stringsAsFactors=FALSE,check.names=FALSE)
  require(all(c("POLICY_DECK","SCIENTIFIC_SEMINAR","SCIENTIFIC_NOTE",
                "IMPACT_CONTEXT")%in%products$product_id),
          "four distinct deliverable source locks")
  require(as.integer(products$pages_or_slides[products$product_id=="SCIENTIFIC_SEMINAR"])==50L,
          "frozen scientific seminar 50 slides")
  require(as.integer(products$pages_or_slides[products$product_id=="SCIENTIFIC_NOTE"])==16L,
          "scientific note 16 pages")
  products$source_scientific_consistency <- ifelse(
      products$product_id=="SCIENTIFIC_NOTE",
      "FINAL_PAGE_REPAIRS_CONTRADICT_EARLIER_PIRLS_SE_HOLDS_REVIEW",
      ifelse(products$product_id=="SCIENTIFIC_SEMINAR",
      "SLIDES_6_49_PRE_FINAL_HOLD_TEXT_VS_FINAL_REPAIRS_REVIEW",
      ifelse(products$product_id=="POLICY_DECK",
       "21_SLIDE_USER_COPY_LEADING_PENDING_SOURCE_ROW_VALIDATION",
       "CONTEXT_NOT_DIRECT_ESTIMATOR_SOURCE")))
  products$release_status <- "PIN_SOURCE_KEEP_EXISTING_NOT_REESTIMATED"
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
       "PAPER_GATES_OPEN","TIMSS_1995_GRID","COMPARATOR_DEFAULT","POLICY_SLIDE_MAP",
       "SCIENTIFIC_RELEASE"),
    value=c("PASS",as.character(counts[[1]]),as.character(counts[[2]]),
      as.character(counts[[3]]),as.character(nrow(figures)),
      as.character(nrow(figures)-length(unmapped)),as.character(length(unmapped)),
      as.character(nrow(paper)),"NOT_IN_GRID",
      "DIFFERENT_FROM_19_COUNTRY_PRODUCTION_SCOPE",
      "21_SLIDE_USER_VERSION_PINNED_DISSIMILAR_13_PROTOTYPE","NOT_GRANTED"),
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
  atomic(slides,"SLIDE_21_REQUIREMENT_STATUS.csv")
  atomic(products,"SOURCE_PRODUCTS_LOCK_AND_CAVEATS.csv")
  atomic(paper,"PAPER_Q01_Q08_STATUS.csv")
  atomic(by_module,"SCIENTIFIC_ADAPTER_REQUIREMENTS.csv")
  cat("Product contract PASS: 21-slide policy; 50-slide seminar; 16-page note. ",counts[[1]]," NL, ",counts[[2]],
      " OECD19, ",counts[[3]]," other tasks; 138 figure contracts, ",
      length(unmapped)," derived ranks, 8 paper gates open.\n",sep="")
  invisible(list(report_dir=dest,counts=counts,
                 positions=unmapped,open_paper=paper$requirement_id))
}
