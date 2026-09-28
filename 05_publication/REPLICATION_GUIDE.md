# Replication guide

This guide is for researchers who want to reproduce the results rather than download a mirror of the project's complete derived database.

## A. Freeze to reproduce

Scientific/product lock:
`749a0de8e6ab707f4ecd887247ea8fde82f55656`

Canonical analysis:
`02_analysis/current/EXECUTED_COMPLETION_SCRIPT_SANITISED.R`

Executed-source SHA-256 before path sanitisation:
`6d0f91e562f3ed3d85f34761e98d148b8c222848cdd2542dc5557587e61e1aab`

Canonical dashboard renderer:
`03_dashboard/app/`

Complete expected dashboard-data inventory:
`03_dashboard/data/PRODUCTION_DATA_MANIFEST.csv`

## B. Obtain source data yourself

Do not use this repository as a source-data mirror.

### OECD PISA

Obtain the required PISA public-use files from OECD's official PISA database pages and accept the current PUF terms. The production pipeline uses student/design/background information, plausible values, weights and the identifiers needed for the documented aggregate calculations.

Current PUF terms:
https://survey.oecd.org/index.php?r=survey%2Findex&sid=197663

The repository source registry and code document the specific cycles/files actually used.

### IEA PIRLS

Obtain public-use PIRLS files from the IEA Data Repository. Relevant dataset identifiers include:
- PIRLS 2001: https://doi.org/10.58150/PIRLS_2001_data
- PIRLS 2006: https://doi.org/10.58150/PIRLS_2006_data
- PIRLS 2011: https://doi.org/10.58150/PIRLS_2011_data
- PIRLS 2016: https://doi.org/10.58150/PIRLS_2016_data
- PIRLS 2021: https://doi.org/10.58150/PIRLS_2021_edition_2_including_Log-file_data

### IEA TIMSS Grade 4

Obtain public-use TIMSS files from the IEA Data Repository. Relevant recent dataset identifiers include:
- TIMSS 2011 G4: https://doi.org/10.58150/IEA_TIMSS_2011_G4
- TIMSS 2015 G4: https://doi.org/10.58150/IEA_TIMSS_2015_G4
- TIMSS 2019 G4: https://doi.org/10.58150/IEA_TIMSS_2019_G4
- TIMSS 2023 G4: https://doi.org/10.58150/IEA_TIMSS_2023_G4_data_edition_1

Earlier-cycle provenance is recorded in the source registry and production code.

IEA terms:
https://www.iea.nl/sites/default/files/data-repository/Disclaimer_and_License_Agreement.pdf

## C. Put source files outside Git

Keep official source bytes in a local data/download directory, never in this repository. The code contains source-discovery and validation logic; user-specific fallback paths have been sanitised from the committed canonical script.

Read:
- `01_data_download_preprocessing/README.md`
- `01_data_download_preprocessing/current/SOURCE_FUNCTION_MAP.md`
- `01_data_download_preprocessing/source_registry/FINAL_RUN_SCOPE.csv`
- `01_data_download_preprocessing/source_registry/OFFICIAL_EXPANDED_ANCHORS.csv`
- `01_data_download_preprocessing/source_registry/OFFICIAL_PISA_MEAN_ANCHORS.csv`
- `01_data_download_preprocessing/source_registry/SCIENTIFIC_DECISION_REGISTER.txt`

## D. Run the canonical analysis

Run `02_analysis/current/EXECUTED_COMPLETION_SCRIPT_SANITISED.R` against the official source layout.

The implementation preserves the survey-specific structure:
- PISA, PIRLS and TIMSS remain separate instruments/scales;
- survey-specific weights and plausible values are used;
- cycle-appropriate replicate/JRR rules are applied;
- availability/support gates remain explicit;
- unavailable or failed cells are not silently imputed;
- panel and geography definitions are preserved.

Do not substitute an archived/superseded script for the canonical production script.

## E. Validate before using results

Compare your generated validation/status outputs with:
- `02_analysis/release_registers/FINAL_SELFTEST_RESULTS.csv`
- `02_analysis/release_registers/FINAL_TECHNICAL_VALIDATION.csv`
- `02_analysis/release_registers/FINAL_OPEN_POINTS_STATUS.csv`
- `02_analysis/release_registers/FINAL_USE_STATUS_REGISTER.csv`
- `02_analysis/release_registers/FINAL_TASK_STATUS.csv`
- `02_analysis/release_registers/FINAL_CHANGE_AND_LOSS_REGISTER.csv`

Review [KNOWN_LIMITATIONS.md](../KNOWN_LIMITATIONS.md). A replication is not equivalent merely because a headline mean is close; source edition, population, panel, uncertainty method and use-status matter.

## F. Recreate the dashboard

The browser does not estimate results. Materialise the frozen aggregate dashboard files described in `03_dashboard/data/PRODUCTION_DATA_MANIFEST.csv` and render them with the canonical files in `03_dashboard/app/`.

For the public Pages version, `05_publication/build_public_pages.py` intentionally excludes the two full masters while retaining the aggregate runtime required by the interface.

## G. What exact equality means

For released files, use SHA-256 where a byte-identical artefact is expected. For regenerated statistical output, use the project's validation/status logic and documented external anchors; do not infer equivalence from rounding alone.

If an official source provider revises a source edition after this release, record that as a new source edition rather than silently overwriting the 28 September 2026 reproduction target.
