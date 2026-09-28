# One-time public runtime asset

The public Pages build expects one controlled binary asset at:

`05_publication/public_dashboard_runtime_20260928.zip`

Expected SHA-256:

`1e8dab161a4998aadfabd97a1224cc7a52505a7a2e80fc186e1558f632d0278e`

The ZIP was generated from the final 28 September dashboard distribution by taking every file listed in `03_dashboard/data/PRODUCTION_DATA_MANIFEST.csv` except:

- `product_data/FINAL_PRODUCT_BASIS.csv.gz`
- `product_data/RESULTATEN_MASTER.csv.gz`

It therefore contains the aggregate JSON required by the interface and the project-authored figure SVG/CSV files, but neither complete bulk master and no source microdata.

`build_public_pages.py` verifies the ZIP hash and then verifies each contained file's byte size and SHA-256 against the canonical manifest before anything is published.

This is a transport artefact, not a new scientific release.
