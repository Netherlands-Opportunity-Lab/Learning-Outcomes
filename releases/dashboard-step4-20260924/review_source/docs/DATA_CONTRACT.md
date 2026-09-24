# Data contract

`source_snapshot/` contains 41 byte-preserved aggregate CSV files from RC1 v3. Their hashes are in `audit/SOURCE_MANIFEST.csv`. `addenda/` contains the separately controlled group-level rank addendum and the 16-cell conditional Netherlands domain context. `data/csv/` contains exact copies; the JSON country profiles are deterministic denormalisations for browser use.

The builder copies and indexes. It does not estimate, construct panels, calculate ranks, calculate gaps or combine standard errors. The explicit Kosovo bridges in `comparison_geography_bridges.csv` are reused with their survey/year scope; source identifiers remain available.

Current release fields (`release_main_eligible`, `release_caveat_ids`) control main observations and demographic output. Latest N=45 is retained as the user-requested maximal comparison, with the original source role preserved. N=43 and N=44 are separate sensitivities. Gaps are presented alongside their source group levels.

Missing numeric values become JSON null and display as an em dash, never as zero. CSV downloads contain the underlying displayed rows and provenance. Static table downloads also preserve excluded/conditional rows for audit; an export is not an unrestricted publication authorisation.
