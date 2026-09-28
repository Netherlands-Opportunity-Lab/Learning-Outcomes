# Controlled minimal public runtime

GitHub Pages uses:
`05_publication/public_dashboard_runtime_20260928.zip`

Final public-integration transport:
- files: 253
- bytes: 14,525,361
- SHA-256: `ae6404aeedecdf3f42e22ef1612e27d3f0e61bc663a0fc99f89aad4c8c15a706`

The runtime contains only files marked `PUBLIC_OK` and `INCLUDED` in `PUBLIC_DATA_GATE.csv`. It intentionally excludes:
- `FINAL_PRODUCT_BASIS.csv.gz`;
- `RESULTATEN_MASTER.csv.gz`;
- four small project control tables not fetched or linked by the frontend;
- all source microdata, restricted official source bytes, caches and private inventories.

Every included file is verified against `PUBLIC_DASHBOARD_MANIFEST.json`. The runtime is a transport artefact, not a new scientific release.
