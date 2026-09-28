# Learning Outcomes — PISA / PIRLS / TIMSS

This private repository contains the reproducible code and documentation for the Netherlands Opportunity Lab project on international learning outcomes at approximately age 10 and age 15.

## Current scientific basis

The current production basis is the final 28 September 2026 integration derived from the completed PISA/PIRLS/TIMSS completion run. The final product basis contains 283,284 estimate rows. Of 2,570 planned tasks, 2,569 completed pending validation and one local PISA 2003 Korea reading supplement remains non-blocking. The product release therefore uses explicit use-status fields rather than treating every cell as equally strong.

Surveys remain separate measurement systems: PIRLS (reading, ≈10), TIMSS (mathematics/science, ≈10), and PISA (reading/mathematics/science, age 15). Raw score points are never subtracted across surveys.

## Repository structure

| Directory | Purpose |
|---|---|
| [`01_data_download_preprocessing/`](01_data_download_preprocessing/README.md) | Source acquisition, provenance, dictionaries, harmonisation history and source-side preprocessing |
| [`02_analysis/`](02_analysis/README.md) | Canonical production analysis and archived/superseded analysis scripts |
| [`03_dashboard/`](03_dashboard/README.md) | Final tested dashboard source, data contract and production-data manifest |
| [`04_products_or_release/`](04_products_or_release/README.md) | Release manifests, product matrix, impact matrix, validation and change/loss records |

Start with [REPRODUCIBILITY.md](REPRODUCIBILITY.md), [DATA_SOURCES.md](DATA_SOURCES.md), [METHODS.md](METHODS.md), and [KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md).

## From official source to dashboard

1. Obtain official OECD/IEA source files under their original access and redistribution terms.
2. Keep pupil-level files outside Git. See `01_data_download_preprocessing/` and [DATA_SOURCES.md](DATA_SOURCES.md).
3. Run the canonical completion script in `02_analysis/current/` against the documented local source layout.
4. Validate the generated aggregates against `02_analysis/release_registers/` and the documented external anchors.
5. Build the dashboard distribution from the frozen aggregate release. The browser never recomputes scientific estimates or ranks.
6. Use the final use-status and caveat registers in every downstream product.

## What is not committed

Student microdata, local caches, private file inventories, credentials, chat transcripts, user-specific absolute paths, and source bytes without clear redistribution permission are excluded. Large final dashboard result bundles are represented by exact SHA-256 manifests and are regenerated from the analysis pipeline or supplied as controlled release assets when rights permit.

## Current release status

The final product integration is `FINAL_PRODUCT_INTEGRATION_WITH_LOCAL_CAVEATS`. See [KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md) and `02_analysis/release_registers/FINAL_OPEN_POINTS_STATUS.csv`.

## Licences

Code is MIT unless a file states otherwise. Data/source rights are source-specific; see [DATA_LICENSE.md](DATA_LICENSE.md). No repository-level open-data licence is asserted for OECD/IEA-derived aggregates.
