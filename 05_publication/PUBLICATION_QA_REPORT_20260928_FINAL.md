# Public dashboard integration QA — 28 September 2026

## Source locks
- Git base SHA before this integration: `db8b7d7ddc22c6d96191148ffac9c2953dc00900`
- Scientific/product source lock: `749a0de8e6ab707f4ecd887247ea8fde82f55656`
- Analysis release: `FINAL_ANALYSIS_FREEZE_20260928`
- Public release: `PUBLIC_DASHBOARD_20260928_FINAL`
- Controlled runtime ZIP: 257 files, 14,528,896 bytes
- Runtime ZIP SHA-256: `f230fd4090ecfb0574d4c0379231e79e6ec662c504d5c782f109c9488479cdf1`

## Public data gate
The gate was constructed before the public-release branch was created. It inventories every file in the public runtime and explicitly records the main excluded classes. The two complete derived masters are `PUBLIC_SUMMARY_ONLY`; source microdata, restricted source bytes, chats/personal files, credentials and third-party assessment content are `DO_NOT_PUBLISH`; analysis/replicate caches and private inventories are `PRIVATE_REPRODUCIBILITY_ONLY`.

## Scientific fidelity
- 160 country/system profile files compared field-by-field with frozen `RESULTATEN_MASTER.csv.gz`.
- 278,431 published result rows compared.
- 0 missing result IDs.
- 0 field mismatches.
- Fields include result ID, estimate, SE, CI, year, group, status and source, plus the remaining public result-contract fields.
- 12,619 precomputed rank rows matched the final dashboard release.
- 172 panel definitions matched for panel ID, N, membership, status and source.
- 812 quality rows matched.
- Curated product mappings matched.
- All 257 public runtime files were byte-identical to the definitive local dashboard release.

## Publication boundary
`FINAL_PRODUCT_BASIS.csv.gz` and `RESULTATEN_MASTER.csv.gz` remain absent from the public runtime and are not linked as downloads. The public browser consumes only frozen aggregates and never computes estimates, SEs, CIs, ranks or scientific aggregations.

## Result
**PASS**
