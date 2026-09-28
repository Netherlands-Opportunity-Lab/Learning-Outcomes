# Final dashboard update — 2026-09-28

This repository stores the final tested static dashboard source and the exact manifest of the tested production-data package.

Canonical final dashboard inputs in the controlled distribution include:
- `FINAL_PRODUCT_BASIS.csv.gz` — 283,284 final estimate rows;
- `FINAL_OPEN_POINTS_STATUS.csv`;
- `FINAL_IMPACT_MATRIX.csv`;
- `FINAL_USE_STATUS_REGISTER.csv`;
- `FINAL_TECHNICAL_VALIDATION.csv`;
- precomputed metadata, ranks, curated content, quality data and country profiles listed in `data/PRODUCTION_DATA_MANIFEST.csv`.

The browser does not compute scientific estimates or ranks. Large OECD/IEA-derived result bundles are deliberately not committed until redistribution rights are confirmed; the manifest preserves exact filenames, sizes and hashes.
