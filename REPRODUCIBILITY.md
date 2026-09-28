# Reproducibility

## Canonical production code

The canonical current production script is `02_analysis/current/EXECUTED_COMPLETION_SCRIPT_SANITISED.R`. It is a path-sanitised copy of the executed completion script. The executed source SHA-256 before path sanitisation is `6d0f91e562f3ed3d85f34761e98d148b8c222848cdd2542dc5557587e61e1aab`. The only intentional edit is removal of a user-specific fallback Downloads path; scientific logic is unchanged.

## Reproduction sequence

1. Download official source files listed/described in [DATA_SOURCES.md](DATA_SOURCES.md). Do not commit pupil microdata.
2. Set a local project/data root outside Git.
3. Run the canonical script. It uses cached aggregates when verified and re-computes only required tasks.
4. Require all self-tests and source/technical gates to complete. Preserve explicit holds; do not impute unavailable cells.
5. Compare outputs to `02_analysis/release_registers/FINAL_TECHNICAL_VALIDATION.csv`, `FINAL_OPEN_POINTS_STATUS.csv`, and `FINAL_USE_STATUS_REGISTER.csv`.
6. Produce/freeze the downstream aggregate basis and dashboard data. The dashboard is a renderer, not an estimator.

## Large local reproducibility caches

`aggregate_replicates/` was intentionally omitted from the compact handoff and this repository. The per-task replicate arrays remain local and are indexed by the final aggregate replicate register in the scientific handoff. Their omission does not change released estimates; it limits independent recomputation of every replicate-derived variance from this repository alone.

## Historical code

Earlier RC1 and pipeline scripts are retained under `archive_or_superseded/`. They are provenance, not current production entry points.
