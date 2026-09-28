# 05 — Public publication layer

This directory turns the frozen dashboard into a public GitHub Pages research site without changing the scientific analysis or the canonical dashboard implementation.

## Source lock

- Repository: `Netherlands-Opportunity-Lab/Learning-Outcomes`
- Scientific/product source commit: `749a0de8e6ab707f4ecd887247ea8fde82f55656`
- Canonical dashboard source: `03_dashboard/app/`
- Canonical complete data manifest: `03_dashboard/data/PRODUCTION_DATA_MANIFEST.csv`

Publication code may copy and label the canonical dashboard for hosting, but it must not recompute scientific values or ranks.

## Public boundary

The Pages build includes:
- canonical HTML/CSS/JavaScript;
- aggregate JSON required by the interactive dashboard;
- project-authored SVG figures and their small figure-data CSVs;
- methods, source attribution, public status and replication documentation.

It excludes:
- `product_data/FINAL_PRODUCT_BASIS.csv.gz`;
- `product_data/RESULTATEN_MASTER.csv.gz`;
- all pupil/school microdata and official source bytes;
- assessment items, passages, questionnaire reproductions and copied IEA publication figures.

## Files

- `PUBLICATION_RIGHTS_REVIEW.md` — terms review and PUBLIC/HOLD decisions.
- `RIGHTS_MATRIX.csv` — machine-readable publication boundary.
- `REPLICATION_GUIDE.md` — end-to-end reproduction instructions.
- `build_public_pages.py` — assembles the Pages artifact without scientific computation.
- `validate_public_site.py` — blocks forbidden/bulk files and checks key frozen hashes.
- `public_dashboard_runtime_20260928.zip` — controlled aggregate runtime used by Pages; generated from the final 28 September dashboard bundle and intentionally excludes the two bulk masters.

The runtime ZIP expected by the build has SHA-256:

`1e8dab161a4998aadfabd97a1224cc7a52505a7a2e80fc186e1558f632d0278e`

The build also validates every file in that ZIP against the canonical production-data manifest.

## Hosting

The workflow `.github/workflows/pages.yml` builds and validates the public artifact and deploys it to GitHub Pages. GitHub Pages itself performs no scientific analysis.
