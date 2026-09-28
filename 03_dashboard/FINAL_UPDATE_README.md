# Final dashboard update - 2026-09-28

This package preserves the working Step-4 dashboard implementation and adds the final freeze data/register layer.

Canonical final files added under `product_data/`:
- `FINAL_PRODUCT_BASIS.csv.gz` (283,284 rows)
- `FINAL_OPEN_POINTS_STATUS.csv`
- `FINAL_IMPACT_MATRIX.csv`
- `FINAL_USE_STATUS_REGISTER.csv`
- `FINAL_TECHNICAL_VALIDATION.csv`

The dashboard is not allowed to compute scientific estimates or ranks in the browser. Existing app data are retained for UI compatibility; final download/provenance layer is versioned as `FINAL_ANALYSIS_FREEZE_20260928`.