# Public dashboard integration QA — 28 September 2026

## Source locks
- Git base SHA before this integration: `db8b7d7ddc22c6d96191148ffac9c2953dc00900`
- Scientific/product source lock: `749a0de8e6ab707f4ecd887247ea8fde82f55656`
- Analysis release: `FINAL_ANALYSIS_FREEZE_20260928`
- Public release: `PUBLIC_DASHBOARD_20260928_FINAL`
- Minimal public runtime: 253 files, 14,525,361 bytes
- Runtime SHA-256: `ae6404aeedecdf3f42e22ef1612e27d3f0e61bc663a0fc99f89aad4c8c15a706`

## Public data gate
The gate was constructed before the public-release branch was created. Every public runtime file is `PUBLIC_OK`. The two complete derived masters are `PUBLIC_SUMMARY_ONLY`; source microdata, restricted source bytes, chats/personal files, credentials and third-party assessment content are `DO_NOT_PUBLISH`; analysis/replicate caches and private inventories are `PRIVATE_REPRODUCIBILITY_ONLY`.

The final minimal runtime omits four small project control tables that the frontend does not fetch or link. They remain part of the reproducibility repository where applicable, but not the public website runtime. This removes an unnecessary legacy local-path detail from the pre-integration transport without changing any scientific result.

## Scientific fidelity
- 160 public country/system profile files checked against frozen `RESULTATEN_MASTER.csv.gz`.
- 278,431 published result rows checked field-by-field.
- 0 missing result IDs; 0 field mismatches.
- Result ID, estimate, SE, CI, year, group, status and source were checked together with the remaining public result-contract fields.
- 12,619 precomputed rank rows: exact match.
- 172 panel definitions including N/membership/status/source: exact match.
- 812 quality rows: exact match.
- Curated mappings: exact match.
- All 253 final public runtime files: unchanged scientific/data bytes from the definitive local dashboard package.

## Publication/download boundary
`FINAL_PRODUCT_BASIS.csv.gz` and `RESULTATEN_MASTER.csv.gz` are absent from the public runtime and have no public download link. The public browser consumes only frozen aggregates and never computes estimates, SEs, CIs, ranks or scientific aggregations.

## Result
**PASS**
