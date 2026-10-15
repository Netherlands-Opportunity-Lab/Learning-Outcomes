# ENIG ACTIEF STARTBESTAND — PISA / PIRLS / TIMSS
# Plaats dit .R-bestand in Downloads; pak de ZIP uit zodat de map
# Downloads/LEARNING_OUTCOMES_PIPELINE/ bestaat.
# Run in de RStudio Console:
# source("~/Downloads/LEARNING_OUTCOMES_RUN.R", encoding="UTF-8")
# De configuratie staat uitsluitend in LEARNING_OUTCOMES_PIPELINE/PROJECT_CONFIG.R.
# Geen aparte scripts voor plannen, testen, produceren of hervatten.

lo_run_main <- function() {
  home <- Sys.getenv("USERPROFILE")
  if (!nzchar(home)) home <- path.expand("~")
  bundle <- getOption("learning_outcomes.bundle_dir",
    file.path(home,"Downloads","LEARNING_OUTCOMES_PIPELINE"))
  if (!dir.exists(bundle)) stop("Pakketmap ontbreekt: ",bundle,
    "\nPak LEARNING_OUTCOMES_INTEGRAAL_20261010.zip uit in Downloads.",call.=FALSE)
  source(file.path(bundle,"code","INTEGRATED.R"),local=.GlobalEnv,encoding="UTF-8")
  lo_integrated_main(normalizePath(bundle,winslash="/",mustWork=TRUE))
}
lo_run_main()
