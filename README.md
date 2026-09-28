# Learning Outcomes — PISA / PIRLS / TIMSS

Reproducible analyses and a public research dashboard on international learning outcomes at approximately age 10 and age 15.

## Scientific source lock

The scientific/product source of truth is commit `749a0de8e6ab707f4ecd887247ea8fde82f55656` (28 September 2026). Publication-only commits after that lock may add hosting, rights documentation, a public-safe data subset and build/QA automation, but do not alter the scientific analysis or the canonical dashboard implementation in `03_dashboard/`.

The final analysis basis contains 283,284 estimate rows. PISA, PIRLS and TIMSS remain separate measurement systems; raw score points are never subtracted across surveys.

## Repository structure

| Directory | Purpose |
|---|---|
| [`01_data_download_preprocessing/`](01_data_download_preprocessing/README.md) | Source acquisition, provenance, dictionaries, harmonisation history and source-side preprocessing |
| [`02_analysis/`](02_analysis/README.md) | Canonical production analysis and archived/superseded scripts |
| [`03_dashboard/`](03_dashboard/README.md) | Frozen tested dashboard source and complete production-data manifest |
| [`04_products_or_release/`](04_products_or_release/README.md) | Release manifests, product matrix, validation and change/loss records |
| [`05_publication/`](05_publication/README.md) | Public-site boundary, rights review, replication guide and GitHub Pages build/QA |

Start with [REPRODUCIBILITY.md](REPRODUCIBILITY.md), [DATA_SOURCES.md](DATA_SOURCES.md), [METHODS.md](METHODS.md), [KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md), and [05_publication/PUBLICATION_RIGHTS_REVIEW.md](05_publication/PUBLICATION_RIGHTS_REVIEW.md).

## Public dashboard boundary

The public site is a research/policy publication, not a mirror of OECD/IEA source databases.

Published:
- project-authored interactive analyses and figures;
- aggregate country/system estimates needed to render those analyses;
- figure-level CSV exports, methods, sources, status and caveat information;
- all project analysis/dashboard/publication code.

Not published:
- pupil- or school-level source data;
- OECD/IEA source files;
- assessment items, reading passages, questionnaire content, photographs or other third-party copyrighted assessment material;
- the complete bulk tables `FINAL_PRODUCT_BASIS.csv.gz` and `RESULTATEN_MASTER.csv.gz`;
- local caches, credentials, private file inventories and user-specific paths.

See [DATA_LICENSE.md](DATA_LICENSE.md) and [05_publication/RIGHTS_MATRIX.csv](05_publication/RIGHTS_MATRIX.csv).

## Reproduce the results

1. Obtain the official OECD/IEA source files yourself under the source providers' current terms.
2. Keep pupil-level files outside Git.
3. Follow [05_publication/REPLICATION_GUIDE.md](05_publication/REPLICATION_GUIDE.md).
4. Run the canonical production code in `02_analysis/current/`.
5. Compare the resulting validation/status files with `02_analysis/release_registers/`.
6. Build the dashboard from the frozen aggregates. The browser renders precomputed values; it does not estimate scientific quantities or recompute ranks.

## Licences

Project code is MIT unless a file states otherwise. No repository-level open-data licence is asserted for OECD/IEA source data or derived aggregates. Source-provider terms remain applicable; see [DATA_LICENSE.md](DATA_LICENSE.md).
