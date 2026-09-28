# 05 — Public publication layer

This directory is the definitive public product layer for the frozen PISA/PIRLS/TIMSS dashboard. It does not replace the scientific source under `03_dashboard/`; it builds from the canonical renderer and precomputed frozen aggregates.

## Source locks

- Scientific/product source commit: `749a0de8e6ab707f4ecd887247ea8fde82f55656`
- Analysis release: `FINAL_ANALYSIS_FREEZE_20260928`
- Public integration base SHA: `db8b7d7ddc22c6d96191148ffac9c2953dc00900`
- Canonical dashboard renderer: `03_dashboard/app/`
- Complete private production-data inventory: `03_dashboard/data/PRODUCTION_DATA_MANIFEST.csv`

## Publication controls

- `PUBLIC_DATA_GATE.csv` — file/data classification.
- `PUBLIC_DASHBOARD_MANIFEST.json` — exact public runtime files, byte sizes, SHA-256 and provenance.
- `PUBLIC_RESULT_FIDELITY.json` — recorded public-to-freeze comparison results.
- `PUBLICATION_QA_REPORT_20260928_FINAL.md` — final integration QA.
- `tests/build_public_release_registers.py` — reproducible private-master comparison code.
- `tests/validate_public_integration.py` — repository/public-site checks.
- `public_dashboard_runtime_20260928.zip` — minimal 253-file runtime transport.

The runtime ZIP is 14,525,361 bytes with SHA-256:
`ae6404aeedecdf3f42e22ef1612e27d3f0e61bc663a0fc99f89aad4c8c15a706`.

It contains only the aggregate JSON and project-authored figure assets needed by the public site. Four small project control tables that are not fetched or linked by the frontend are omitted from the runtime; the two complete derived masters are also omitted.

## Scientific rule

The browser does not compute estimates, SEs, CIs, ranks, panels or scientific aggregates. Public-result fidelity is checked against the final frozen master before merge, while public CI verifies the committed manifest, runtime hashes and recorded zero-mismatch evidence.

## Hosting

`.github/workflows/pages.yml` is manual-only. A merge does not trigger a deployment. Deployment from `main` requires an explicit workflow dispatch and confirmation.
