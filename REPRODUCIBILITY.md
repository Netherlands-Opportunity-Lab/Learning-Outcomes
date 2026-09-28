# Reproducibility

## Canonical scientific code

The canonical production implementation for the 28 September 2026 release is:

`02_analysis/current/EXECUTED_COMPLETION_SCRIPT_SANITISED.R`

The executed source SHA-256 before path sanitisation is:

`6d0f91e562f3ed3d85f34761e98d148b8c222848cdd2542dc5557587e61e1aab`

The sanitised copy removes a user-specific fallback Downloads path; scientific logic is unchanged.

The scientific/product lock is Git commit:

`749a0de8e6ab707f4ecd887247ea8fde82f55656`

Later publication commits must not silently alter `02_analysis/` or the canonical implementation under `03_dashboard/app/`.

## End-to-end reproduction

A researcher can reproduce the project without receiving our copy of the source microdata:

1. Read [DATA_SOURCES.md](DATA_SOURCES.md) and [05_publication/REPLICATION_GUIDE.md](05_publication/REPLICATION_GUIDE.md).
2. Obtain the official OECD PISA and IEA PIRLS/TIMSS public-use files from the source providers and accept their current terms.
3. Keep those source files outside the Git repository.
4. Use `01_data_download_preprocessing/source_registry/` to check scope, official anchors and documented unavailable cells.
5. Run `02_analysis/current/EXECUTED_COMPLETION_SCRIPT_SANITISED.R`. The source-side function map is in `01_data_download_preprocessing/current/SOURCE_FUNCTION_MAP.md`.
6. Require the script's self-tests and source/technical gates to complete. Do not turn unavailable/blocked cells into zeros and do not widen validation tolerances ad hoc.
7. Compare the resulting status/validation tables with `02_analysis/release_registers/`, especially:
   - `FINAL_SELFTEST_RESULTS.csv`
   - `FINAL_TECHNICAL_VALIDATION.csv`
   - `FINAL_OPEN_POINTS_STATUS.csv`
   - `FINAL_USE_STATUS_REGISTER.csv`
   - `FINAL_TASK_STATUS.csv`
   - `FINAL_CHANGE_AND_LOSS_REGISTER.csv`
8. Freeze downstream aggregates before producing figures or the website. The dashboard is a renderer, not an estimator.
9. For the public website, follow the build boundary in `05_publication/`: omit the two bulk master tables and all source microdata; publish only the aggregate runtime required by the dashboard.

## Replicate arrays and local caches

Large per-task aggregate-replicate caches are not committed. Their omission does not change released point estimates, but it means that exact independent reconstruction of every replicate-derived variance requires rerunning the canonical analysis from the official source files. The release registers preserve the final results, validation status and provenance.

## Historical code

Earlier RC1 and pipeline scripts are retained under `archive_or_superseded/` for provenance. They are not current production entry points.
