# 03 — Dashboard

`app/` is the exact final tested static dashboard source from the 28 September 2026 product integration. The browser renders precomputed values and does not estimate scientific quantities or recompute ranks.

## Production data

The four small final status/validation files committed under `data/` are project-authored control metadata. Large final score/result bundles and country profile data are not committed here because public redistribution rights are not assumed and the repository should not become a de facto data mirror. `data/PRODUCTION_DATA_MANIFEST.csv` records the exact file names, byte sizes and SHA-256 hashes of the tested dashboard data package.

To reproduce a full local dashboard, generate the frozen aggregate data from `02_analysis/current/` and materialise the files listed in the manifest using `scripts/prepare_product_dist.py` / the documented product build process.

The final local QA reported HTTP 200 for the index, downloads page, JS, metadata and final product basis. Full cross-browser/mobile manual QA was not claimed.
