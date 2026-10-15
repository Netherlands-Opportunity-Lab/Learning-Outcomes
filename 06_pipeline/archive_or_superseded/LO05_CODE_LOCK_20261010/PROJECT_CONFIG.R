# Definitieve projectconfiguratie: geen losse productierunners meer.
# Deze R-list wordt gelezen met dget(); het bestand voert zelf niets uit.
list(
  action = "production",         # production | test_only | plan_only
  phases = c("NLD","OECD19"),    # Nederland eerst; daarna uitsluitend 19 referentielanden
  run_mode = "NLD_PLUS_OECD_PPP",
  focus_country = "NLD",
  reference_id = "OECD_PPP_GT_CZE_2024_RECONSTRUCTED",
  expected_reference_country_count = 19L,
  surveys = c("PISA","PIRLS","TIMSS"),
  domains = c("reading","mathematics","science","all"),
  waves = c(1995L,2001L,2003L,2006L,2007L,2009L,2011L,2012L,
            2015L,2016L,2018L,2019L,2021L,2022L,2023L,2025L),
  modules = "ALL_CONTRACT_MODULES",
  reviewed_plan_fingerprint = "", # nog geen afzonderlijke menselijke acceptatie vereist; acceptance met code-hash bindend
  approved_module_gate_file = "", # geen automatische wetenschappelijke promotie
  cache_inspection = "semantic", # vergelijk gebruikte kolommen van conflicterende RDS
  candidate_calculation = TRUE,   # bereken in QUARANTAINE: geen wetenschappelijke vrijgave
  gc_policy = "auto_exact_duplicate_run_exports", # veilig automatisch na geslaagde consolidatie
  # Modi: NLD_ONLY (NLD), NLD_PLUS_OECD_PPP (NLD+OECD19),
  # OECD_PPP_ONLY (OECD19), OTHER_INTERNATIONAL (FULL, overige landen)
  # alle Nederlandse kandidaten eerst; buitenland alleen relevante series van 19 landen
  allow_unverified_promotion = FALSE,
  allow_raw_imports = FALSE,      # nooit onverwacht downloads/raw reads starten
  delete_files = FALSE,
  write_existing_project_registry = FALSE,
  workers = 1L,                   # slechts één schrijvend proces
  project_root = file.path(Sys.getenv("USERPROFILE"),"Downloads","PISA_PIRLS_MASTER_PIPELINE"),
  lo02_root = file.path(Sys.getenv("USERPROFILE"),"Downloads","LO02_PRODUCTIE"),
  output_root = file.path(Sys.getenv("USERPROFILE"),"Downloads","LO05_RESULTATEN")
)
