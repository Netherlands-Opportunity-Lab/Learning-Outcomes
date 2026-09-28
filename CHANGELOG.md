# Changelog

## 2026-09-28 — final public dashboard integration

- Added a file-by-file public data gate with `PUBLIC_OK`, `PUBLIC_SUMMARY_ONLY`, `PRIVATE_REPRODUCIBILITY_ONLY` and `DO_NOT_PUBLISH` states.
- Added `05_publication/PUBLIC_DASHBOARD_MANIFEST.json` with the analysis release, integration base SHA, byte sizes, SHA-256 hashes, publication status and provenance for the public runtime.
- Verified 278,431 published country/system result rows against the frozen result master with zero field mismatches; verified 12,619 rank rows, 172 panel definitions and all 257 runtime files against the definitive dashboard release.
- Kept the complete derived masters out of the public runtime while retaining their filename/size/hash metadata for audit.
- Added reproducible public-release register generation and CI checks for hashes, links, blocked/empty states, download boundaries, privacy paths/secrets and source/microdata exclusions.
- Kept the canonical scientific renderer under `03_dashboard/app/`; the public layer remains a publication/build layer and performs no scientific recalculation.
- Changed GitHub Pages publication to an explicit manual deployment step so merge and deployment are separated.
- Preserved all prior scientific/reproducibility history and archived prototype branches/PRs rather than deleting history.

## 2026-09-28 — final reproducible repository integration

- Reorganised the private repository into source/preprocessing, analysis, dashboard and release layers.
- Added the final completion analysis script and final release/status registers.
- Replaced the synthetic-dashboard framing with the final tested dashboard source contract.
- Archived earlier RC1/pipeline scripts as superseded provenance rather than deleting them.
- Added reproducibility, data-source, methods, limitations, licensing and privacy documentation.
- Added production manifests and explicit handling of restricted/uncommitted large aggregate data.
- Supersedes the 24 September dashboard review snapshot; PR #2 remains historical context only.
