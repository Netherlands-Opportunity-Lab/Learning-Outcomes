# Public scientific dependencies

These files replace the inaccessible private ZIP dependency for an **explicit
fresh source replication**. They are not a replacement for the historical
56-file bundle in an existing run. Existing results keep their original code
and source identities.

`MANIFEST_SHA256.csv` is pinned in `06_pipeline/BUNDLE_DISCOVERY.R`. It contains
the original task and figure contracts, the unchanged rich-candidate provenance
table and the statistical engine files required by the exact selected-cell
dispatcher. The public copies of `BACKEND.R` and `V11.R` replace only an old
machine-specific fallback path. Their original and public hashes are preserved.
They are loaded in functions-only mode; the current dispatcher, scope decisions
and source verification determine what is actually calculated.

Historical result archives, student or school records, private configuration and
old broad-run entry points are deliberately absent. Fresh replication starts an
empty result registry and computes the approved selection through the existing
`START.R` → `RUN.R` → `fixed-audit` → `fixed-produce` → `fixed-finalize` route.
The public dependency profile alone is not a certificate of numerical results.

Set `LO_FRESH_REPLICATION=1`, `LO_REPO_ROOT`, a new `LO_FIXED_ROOT`,
`LO_SOURCE_BINDINGS`, and `LO_RUN_CONFIG` explicitly. Use the recorded Git commit
and locked R environment. `LO_SOURCE_BINDINGS` is a private CSV with columns
`sha256,path`; hashes must match the public source catalogue. Raw files are
obtained from their official OECD/IEA access routes under their own terms.
`LO_COBREROS_ROOT` points to the separately pinned authors' Git checkout
`1da4b26097e84e732973af672355a1c3103d5d33`.

Chosen PISA SES additionally requires the authors' four source extracts and
reference parameter table. The fresh route rebuilds the chosen four-wave model,
independently checks every extraction field and pupil set against the official
files, and verifies the parameter agreement. Calibration and deterministic
imputation can need input countries outside the requested output selection;
these do not become result targets, dashboard countries or reference members.
It never runs the authors' two-wave or other robustness analyses.

The country selection does not authorize publication. The existing review,
rights, replication and product gates still apply to newly calculated results.
The exact same command resumes an interrupted fresh run from its own completed
blocks. Changing fresh mode, source identity or configuration requires a new
audit; it does not silently reuse the earlier meaning.

During preparation on 20 October this adapter is tested separately on the
preparation branch. The current47 release remains on its unchanged reviewed
execution route until integration and actual source probes have passed.
