# Read programme identity from PISA's own labelled codebook. IEA participation
# and an ISO numeric prefix cannot establish PISA programme validity (the UK
# has multiple national programme prefixes; Kosovo's code changed by cycle).
lo_pisa_program_dictionary <- local({
  cache<-new.env(parent=emptyenv())
  function(row) {
    modern<-as.integer(row$year)>=2015L
    path<-if(modern)row$raw_path else row$control_path
    hash<-if(modern)row$raw_sha256 else digest::digest(file=path,algo='sha256')
    key<-paste(path,hash)
    if(exists(key,cache,inherits=FALSE))return(get(key,cache))
    if(modern) {
      h<-haven::read_sav(path,n_max=0)
      labels<-attr(h$PROGN,'labels')
    }else {
      text<-paste(readLines(path,warn=FALSE,encoding='UTF-8'),collapse='\n')
      at<-regexec('(?is)\\bvalue\\s+\\$prognf?\\s+(.*?)(?:;\\s*\\n|\\n\\s*(?:value|run)\\b)',text,perl=TRUE)
      block<-regmatches(text,at)[[1]]
      if(length(block)!=2L)stop('PISA_PROGRAM_DICTIONARY_NOT_FOUND')
      # Match each quoted code/label separately; a quote inside a label is not
      # interpreted as executable SAS and missing code 999999 is not a country.
      hit<-regmatches(block[2],gregexpr('(?m)^\\s*["\x27]([0-9]+)["\x27]\\s*=\\s*(["\x27])(.*?)\\2\\s*$',block[2],perl=TRUE))[[1]]
      parse<-lapply(hit,function(z)regmatches(z,regexec('^\\s*["\x27]([0-9]+)["\x27]\\s*=\\s*(["\x27])(.*?)\\2\\s*$',z,perl=TRUE))[[1]])
      if(!length(parse)||any(lengths(parse)!=4L))stop('PISA_PROGRAM_DICTIONARY_INVALID')
      labels<-stats::setNames(vapply(parse,`[`,character(1),2),vapply(parse,`[`,character(1),4))
    }
    if(is.null(labels)||!length(labels)||is.null(names(labels)))stop('PISA_PROGRAM_LABELS_REQUIRED')
    z<-list(labels=labels,path=path,sha256=hash)
    assign(key,z,cache);z
  }
})

lo_pisa_valid_programs <- function(program,labels,country,aliases,year=NULL) {
  clean<-function(x)gsub('[^a-z0-9]','',tolower(x))
  prefix<-sub(':.*$','',names(labels))
  wanted<-clean(unique(c(country,aliases)))
  belongs<-clean(prefix)%in%wanted
  # These are components of the official national GBR sample, not substitute
  # regional samples. The row selector remains the exact national CNT=GBR.
  if(country=='GBR')belongs<-belongs|grepl('^unitedkingdom',clean(prefix))
  # Explicit source-dictionary aliases. CNT still selects the national pupil
  # sample; these labels describe its programmes, never a replacement country.
  if(country=='TWN')belongs<-belongs|prefix=='TAP'
  if(country=='ARE'&&identical(as.integer(year),2009L))
    belongs<-belongs|prefix%in%c('DUBAI','ARE (ex. Dubai)')
  if(country=='LIE'&&identical(as.integer(year),2012L))
    belongs<-belongs|prefix=='Switzerland'
  belongs<-belongs&!grepl(':\\s*(missing|invalid|not applicable|no response)\\s*$',names(labels),ignore.case=TRUE)
  valid<-as.character(labels[belongs])
  if(!length(valid))stop('PISA_PROGRAM_COUNTRY_LABEL_UNRESOLVED: ',country)
  normalize<-function(x)sub('^0+(?=[0-9])','',as.character(x),perl=TRUE)
  is_valid<-!is.na(program)&normalize(program)%in%normalize(valid)
  list(values=ifelse(is_valid,as.character(program),NA_character_),
       allowed_codes=sort(unique(valid)),labels=names(labels)[belongs],
       invalid_or_missing=sum(!is_valid))
}

lo_pisa_program_review <- function(repo,row,program) {
  dictionary<-lo_pisa_program_dictionary(row)
  p<-file.path(repo,'06_pipeline/review_20261013/OFFICIAL_SAMPLE_TABLES.json')
  aliases<-jsonlite::fromJSON(p,simplifyVector=FALSE)$country_aliases[[row$country]]
  mapped<-lo_pisa_valid_programs(program,dictionary$labels,row$country,unlist(aliases),row$year)
  mapped$source_path<-dictionary$path;mapped$source_sha256<-dictionary$sha256
  mapped$aliases_sha256<-digest::digest(file=p,algo='sha256')
  mapped
}
