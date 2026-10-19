# Country eligibility and balanced reference panels, user rule 14 Oct 2026.
# Input is certified aggregate support, never raw pupils or historical labels.
# Comparison IDs must already certify compatible populations and methods;
# country-specific sample IDs and source hashes remain on the source records.
# These helpers neither approve evidence nor add new analytical families.
lo_balance_columns <- function() c("survey","age_group","domain","year",
  "outcome","split_dimension","split_group","definition_id",
  "ses_definition_id","peer_definition","peer_target_group","threshold_id",
  "unit","population_comparison_id","method_comparison_id")

# Templates describe Dutch deck years. Other countries retain all years in
# their own exact contracts, including years with unavailable results.
lo_focus_product_years <- function(tasks,focus,figure) {
  if(focus=='NLD')return(sort(unique(strsplit(figure$required_years,';',fixed=TRUE)[[1]])))
  historical<-if('historical_figure_id'%in%names(figure))figure$historical_figure_id else figure$figure_id
  z<-tasks[tasks$country==focus & tasks$survey==figure$survey &
    tasks$contract_figure_id==historical,,drop=FALSE]
  sort(unique(as.character(z$year)))
}

lo_balance_key <- function(x) {
  cols <- lo_balance_columns()
  if(!all(cols %in% names(x))) stop("BALANCE_HOLD: exact support dimensions missing")
  z <- x[cols]
  if(anyNA(z) || any(vapply(z,function(v) any(!nzchar(as.character(v)) |
      grepl("[|;]",as.character(v))),logical(1))))
    stop("BALANCE_HOLD: incomplete or ambiguous support identity; use explicit none")
  if(!all(grepl("^[0-9]{4}$",as.character(z$year))))
    stop("BALANCE_HOLD: invalid survey cycle")
  do.call(paste,c(lapply(z,as.character),sep="|"))
}

lo_balance_validated <- function(available) {
  meta <- c("country","estimate","standard_error","n_unweighted","status",
            "source_record_id","verification_id")
  if(!all(meta %in% names(available)))stop("BALANCE_HOLD: evidence columns missing")
  key <- lo_balance_key(available)
  if(anyNA(available$country) || any(!grepl("^[A-Z0-9]{3}$",available$country)))
    stop("BALANCE_HOLD: invalid country identity")
  num <- function(z)suppressWarnings(as.numeric(as.character(z)))
  estimate <- num(available$estimate); se <- num(available$standard_error)
  n <- num(available$n_unweighted)
  ok <- !is.na(available$status) & available$status=="SCIENTIFICALLY_VALIDATED" &
    is.finite(estimate) & is.finite(se) & se>=0 & is.finite(n) & n>0 &
    !is.na(available$source_record_id) & nzchar(available$source_record_id) &
    !is.na(available$verification_id) & nzchar(available$verification_id)
  x <- available[ok,,drop=FALSE];x$balance_key <- key[ok]
  x$estimate <- estimate[ok]
  if(anyDuplicated(paste(x$country,x$balance_key,sep="|")))
    stop("BALANCE_HOLD: duplicate certified country cell; resolve source editions")
  x
}

lo_dashboard_eligibility <- function(available,candidates) {
  lo_support_eligibility(lo_balance_validated(available),candidates)
}

# Shared combinatorial rule; callers must verify either source or result evidence.
lo_support_eligibility <- function(x,candidates) {
  lo_balance_key(x)
  x <- x[x$outcome=="mean_score" & x$split_dimension=="none" &
    x$split_group=="total" & x$peer_definition=="none",,drop=FALSE]
  domains <- c("reading","mathematics","science")
  cells <- expand.grid(age_group=c("age10","age15"),domain=domains,
                       stringsAsFactors=FALSE)
  detail <- list()
  for(country in sort(unique(candidates))) for(i in seq_len(nrow(cells))) {
    age <- cells$age_group[i];domain <- cells$domain[i]
    survey <- if(age=="age15")"PISA" else if(domain=="reading")"PIRLS" else "TIMSS"
    z <- x[x$country==country & x$survey==survey & x$age_group==age &
      x$domain==domain,,drop=FALSE]
    # Never combine incompatible population/method series to reach three.
    identity <- c("population_comparison_id","method_comparison_id","definition_id","unit")
    groups <- if(nrow(z))split(z,do.call(paste,c(z[identity],sep="|"))) else list()
    counts <- vapply(groups,function(g)length(unique(g$year)),integer(1))
    best <- if(length(counts))max(counts) else 0L
    detail[[length(detail)+1L]] <- data.frame(country=country,survey=survey,
      age_group=age,domain=domain,verified_comparable_cycles=best,
      combination_pass=best>=3L,stringsAsFactors=FALSE)
  }
  d <- if(length(detail))do.call(rbind,detail) else
    data.frame(country=character(),survey=character(),age_group=character(),
      domain=character(),verified_comparable_cycles=integer(),combination_pass=logical())
  eligible <- vapply(sort(unique(candidates)),function(c)
    sum(d$country==c)==6L && all(d$combination_pass[d$country==c]),logical(1))
  list(countries=data.frame(country=names(eligible),dashboard_eligible=unname(eligible),
      row.names=NULL),detail=d)
}

lo_balanced_membership <- function(available,required,candidates,focus) {
  # required is a frozen union of ALL groups/years/outcomes/peer units being
  # compared together. Do not reduce it to improve another country's coverage.
  keys <- unique(lo_balance_key(required))
  if(!length(keys))stop("BALANCE_HOLD: empty focus requirements are not eligibility")
  if(length(focus)!=1L || is.na(focus) || !grepl("^[A-Z0-9]{3}$",focus))
    stop("BALANCE_HOLD: one focus country required")
  x <- lo_balance_validated(available)
  focus_missing <- setdiff(keys,x$balance_key[x$country==focus])
  if(length(focus_missing))
    stop("BALANCE_HOLD: focus itself lacks ",length(focus_missing)," certified required cells")
  rows <- lapply(sort(unique(candidates)),function(country) {
    missing <- setdiff(keys,x$balance_key[x$country==country])
    data.frame(country=country,focus_country=focus,required_cells=length(keys),
      covered_cells=length(keys)-length(missing),missing_cells=length(missing),
      eligible=country!=focus && !length(missing),
      reason=if(country==focus)"FOCUS_EXCLUDED" else if(length(missing))
        "MISSING_OR_INCOMPATIBLE_REQUIRED_CELLS" else "FULL_BALANCED_SUPPORT",
      missing_keys=paste(sort(missing),collapse=";"),stringsAsFactors=FALSE)
  })
  if(length(rows))do.call(rbind,rows) else
    data.frame(country=character(),focus_country=character(),required_cells=integer(),
      covered_cells=integer(),missing_cells=integer(),eligible=logical(),reason=character(),missing_keys=character())
}

lo_balanced_reference_points <- function(available,required,selected,focus) {
  selected <- sort(unique(selected))
  if(!length(selected))stop("BALANCE_HOLD: empty selected reference group")
  membership <- lo_balanced_membership(available,required,selected,focus)
  if(!all(membership$eligible))stop("BALANCE_HOLD: selected reference contains ineligible country")
  x <- lo_balance_validated(available)
  keys <- sort(unique(lo_balance_key(required)))
  rows <- lapply(keys,function(key) {
    z <- x[x$balance_key==key & x$country%in%selected,,drop=FALSE]
    if(nrow(z)!=length(selected))stop("BALANCE_HOLD: incomplete selected panel")
    z <- z[order(z$country),,drop=FALSE]
    data.frame(focus_country=focus,balance_key=key,estimate=mean(z$estimate),
      n_countries=length(selected),members=paste(selected,collapse=";"),
      country_weights="EQUAL_PER_COUNTRY",source_records=paste(z$source_record_id,collapse=";"),
      verification_ids=paste(z$verification_id,collapse=";"),
      benchmark_se_displayed=FALSE,stringsAsFactors=FALSE)
  })
  list(points=do.call(rbind,rows),membership=membership)
}

# Dashboard adapter: enforce BOTH admission and comparison support. A checkbox
# caller must use this combined gate, not just the lower-level panel helper.
lo_dashboard_reference_options <- function(available,required,candidates,focus) {
  admission <- lo_dashboard_eligibility(available,unique(c(candidates,focus)))$countries
  if(!isTRUE(admission$dashboard_eligible[match(focus,admission$country)]))
    stop("BALANCE_HOLD: focus does not satisfy certified dashboard 6x3 rule")
  options <- lo_balanced_membership(available,required,candidates,focus)
  options$dashboard_eligible <- admission$dashboard_eligible[match(options$country,admission$country)]
  bad <- !options$dashboard_eligible & options$country!=focus
  options$eligible[bad] <- FALSE
  options$reason[bad] <- "FAIL_DASHBOARD_6x3"
  options
}

lo_dashboard_reference_points <- function(available,required,selected,focus) {
  options <- lo_dashboard_reference_options(available,required,selected,focus)
  if(!nrow(options) || !all(options$eligible))
    stop("BALANCE_HOLD: dashboard selection is empty or ineligible")
  lo_balanced_reference_points(available,required,selected,focus)
}
