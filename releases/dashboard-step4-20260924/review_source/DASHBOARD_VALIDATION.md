# Dashboard step 4 validation · 2026-09-24

Status: PRIVATE_REVIEW_DELIVERABLE; reading remains conditional; complete RC2 freeze not claimed.

## Delivered

- 136 country/system browser profiles, generated from 41 exact RC1-v3 aggregate source CSVs (10,059 core observations).
- 43 aggregate download tables including two separately controlled addenda: 704 precomputed Q1/Q4 group ranks and 16 conditional Netherlands-only mathematics/science means.
- User-requested latest N=45 maximum panel and independent N=43 quality subset, with their own precomputed gap ranks and matching group levels. The historical exact-ID N=44 file is retained as a separate audit download.
- PISA/PIRLS separate scales and age filters; nationality and UI language independent. Longitudinal fixed panels PISA32, PIRLS13/16 and MAIN12 excluding Norway.
- National versus international SES; 31-country international-ESCS reference excluding the Netherlands; no confusion with income or OECD average.
- Nonempty social-school-sorting data, correct uncertainty labels, source eligibility, and explicit Dutch PIRLS participation warning. No unvalidated gender substitution.
- 30 revised scientific figure families, with PDF/SVG/PNG and plotting data from the final step-4 figure package.
- CSV and SVG downloads, shareable filter URLs, source manifests, reproducible builder, and local-server instructions.

## Tests and their scope

`audit/DATA_VALIDATION_CHECKS.csv` records 33 data and release checks; `audit/RENDER_CHECKS.json` records 21 render regressions using the real JS functions in a minimal DOM harness. JavaScript syntax is checked with Node. HTTP checks validate local resource paths. All final executed checks pass; the exact counts are machine-readable in these files.

The checks cover byte-preservation, source-row counts, exact panel membership, source eligibility, N45/N43 Netherlands anchors, source SEs, correct missing values, Kosovo bridging, MAIN12, relative/absolute SES, both interface languages, partial-domain restrictions, and real social-sorting rows. They do not establish new statistical validity beyond the source scientific review.

Browser layout/screenshot QA is NOT_RUN. Chromium was absent; the official download returned an invalid/empty archive. No browser screenshot is claimed. The optional Playwright test is provided for an environment with a browser. Responsive CSS and HTML/JS render paths have been checked structurally, not visually in a full browser.

## Preservation and supersession

The original attached repo/data ZIPs remain unchanged. The current site packages include only manifest-listed canonical source/output files. The old root-level F04/F05 mixed-scale figures, empty F09, obsolete latest N45 data, and old RC1 FINAL validation claims are excluded from the released package. They remain in the original supplied ZIPs for provenance, not as active products.

## Publication

A live GitHub check confirms that the repository is private and the previous PR #1 remains a draft. This delivery stages a new private draft for review. There is no merge or public deployment. IEA rights condition C001 remains unresolved; see `docs/PUBLICATION_STATUS.md`. The final branch/commit and PR receipt are provided separately.
