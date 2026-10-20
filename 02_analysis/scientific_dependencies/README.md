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

On 20 October the public bundle was loaded without the private source ZIP or
old result caches for 58 approved cells: PIRLS 2021 (12), TIMSS 2023 (24) and
PISA 2003 (22), all Netherlands. The direct official-source Windows probe took
39 seconds. Its largest estimate difference was 7.96e-13 and largest SE
difference 3.62e-13, below the fixed 1e-9 tolerance; every N matched exactly.
See the hash-bound proof in
`../../06_pipeline/review_20261013/release47_20261020/public_replication/`.
The six technical Windows/Linux jobs also passed in workflow run
39415511216. These are targeted source probes and technical platform tests,
not a claim that every scientific result has been freshly recalculated on
both platforms. Integration with the reviewed current47 route remains a
separate versioned step.

The portable numerical probe is `scripts/verify_public_raw_probes.R`. Its
private configuration supplies official raw paths and hashes, exact tasks,
expected aggregate hashes and source-population metadata. It reads expected
values only after estimation, writes all estimates/SE/N and comparisons, and
requires a new output directory. Source data are never copied into the public
repository.
