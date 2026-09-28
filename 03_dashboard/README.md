# 03 — Dashboard

`app/` is the exact final tested static dashboard renderer from the 28 September 2026 product integration. The browser renders precomputed values and does not estimate scientific quantities, SEs, confidence intervals, panels or ranks.

## Scientific source versus public product layer

The scientific/dashboard source of truth remains here under `03_dashboard/`. The public production layer is the already-established equivalent structure under `../05_publication/`; it copies the canonical renderer at build time rather than maintaining a second scientific frontend.

Public-release controls:
- `../05_publication/PUBLIC_DATA_GATE.csv` — every public runtime file plus explicit excluded classes;
- `../05_publication/PUBLIC_DASHBOARD_MANIFEST.json` — release, analysis lock, integration base SHA, byte size, SHA-256, publication status and provenance for every runtime data/figure file;
- `../05_publication/PUBLIC_RESULT_FIDELITY.json` — field-level comparison evidence against the final frozen result master and frozen panel/rank release;
- `../05_publication/tests/` — public-build, privacy, link, blocked-state and fidelity-validation code.

## Production data

The small final status/validation tables committed under `data/` are project-authored control metadata. `data/PRODUCTION_DATA_MANIFEST.csv` remains the complete authoritative inventory of the tested final dashboard package.

The public runtime is intentionally narrower: it includes only the frozen aggregate country/system profiles, precomputed rank/panel/quality metadata and project-authored figure files required by the interactive site. It excludes `FINAL_PRODUCT_BASIS.csv.gz` and `RESULTATEN_MASTER.csv.gz`, source microdata, official restricted source bytes, caches and private inventories.

To reproduce the full analysis, obtain the official OECD/IEA source files under their current terms and run the canonical analysis under `02_analysis/current/`. To reproduce the public product boundary, use the scripts and registers under `05_publication/`.

The final integration comparison checked 278,431 published country/system result rows field-by-field against the frozen result master, 12,619 precomputed rank rows, 172 panel definitions and all 257 public runtime files. No content difference was found; no new scientific calculation was introduced.
