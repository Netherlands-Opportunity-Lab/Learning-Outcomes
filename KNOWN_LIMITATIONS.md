# Known limitations

The final scientific/product release is complete with explicit caveats. The authoritative per-issue status is `02_analysis/release_registers/FINAL_OPEN_POINTS_STATUS.csv`.

Key remaining non-blocking items:

- **PISA 2003 Korea reading supplement:** one supplement task failed a plausible-value integrity range check; preserved baseline rows remain untouched.
- **PIRLS 2006 Spain language-within-assessment sorting:** 73/75 replicates are finite; no released SE for that specific statistic.
- **Strict external TIMSS checks:** Iran 2003 mathematics, Philippines 2003 science and Italy 2011 mathematics remain `REVIEW_REQUIRED`; tolerances were not widened.
- **PISA 2025 gender:** source fields that are all-missing or combine Female/Other are not recoded into a clean girl/boy split.
- **School sorting:** all-target and modal-ISCED specifications remain available; claims are restricted to conclusions robust to both where necessary.
- **Replicate arrays:** large per-task aggregate-replicate caches are retained locally and not committed.

## Publication-rights limitation

The public dashboard uses a deliberately narrower distribution boundary than the internal final product package. It serves aggregate values needed for the interactive research presentation and project-authored figures, but it does not publish OECD/IEA source microdata or the full project bulk masters `FINAL_PRODUCT_BASIS.csv.gz` and `RESULTATEN_MASTER.csv.gz`.

This is a distribution constraint, not a change to the scientific results. The exact complete production-data inventory and hashes remain recorded in `03_dashboard/data/PRODUCTION_DATA_MANIFEST.csv`. The public-site policy and rationale are documented in `05_publication/PUBLICATION_RIGHTS_REVIEW.md`.
