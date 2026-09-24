# PISA/PIRLS dashboard step 4 — private review

This directory contains the complete tested private dashboard snapshot, readable application source, and the exact build inputs. The existing application elsewhere in this repository is unchanged.

## Restore and view

Run in this directory:

```sh
python restore_snapshot.py
python -m http.server 8000 --directory PISA_PIRLS_DASHBOARD_STEP4_PRIVATE
```

Then open `http://localhost:8000`. Python 3 is the only requirement to view the restored static site. The archive is split into two binary parts solely to meet the connector's upload limit. The restoration script checks the complete SHA-256 and all ZIP members before extracting.

The exact single-file archive delivered separately is `PISA_PIRLS_DASHBOARD_STEP4_PRIVATE.zip` (19,842,618 bytes; SHA-256 `72eb4d337019274cc3a1faf29972c81170541e21f75cd8026f2c1f059ad8482b`). `DASHBOARD_MANIFEST_SHA256.csv` enumerates its controlled contents.

## Scope

- 136 country/system profiles and 10,059 reading observations from 41 byte-preserved RC1-v3 tables.
- N45 maximal and N43 quality panels, underlying group levels, source uncertainty, and precomputed Q1/Q4 ranks.
- Separate instrument scales, absolute versus relative SES, 31-country reference, MAIN12 sensitivity, corrected social sorting, and Dutch PIRLS representativeness warning.
- 30 revised figure families with PNG/SVG/PDF and plotting data.
- Only 16 Netherlands mathematics/science overall means are accepted as conditional context. No full RC2 freeze, cross-domain SES release, or complete international math/science comparison.
- 33 data/release checks, 21 real-render regressions in a minimal DOM harness, and 10 HTTP checks passed. Full browser/screenshot QA was unavailable; it is not claimed.

`review_source/` makes the application and build changes reviewable in the pull request. `DASHBOARD_BUILD_INPUTS.zip` contains the exact aggregate source tables and addenda. The full archive includes the generated site, data, figures, and audit records.

No main-branch replacement, merge, public Pages deployment, or public data publication is included. IEA republication caveat C001 remains open. The repository was verified private on 2026-09-24.
