# Next scientific release — reproducible storage and production

This directory is a **new development workflow**, not a replacement for the
locked 28 September 2026 release. The scientific code already published in
[02_analysis/current](../02_analysis/current) and the existing
[dashboard](../03_dashboard/README.md) are unchanged.

## What is implemented

- One R entry point: RUN.R, with scopes nld_only, nld_plus_19,
  reference_19, other, all.
- Incremental execution delegates to the existing locally installed,
  checksum-verified LO05 integrated engine. It **does not** silently promote
  non-core candidate estimators into scientifically released results.
- A separate full-source reproduction action delegates to the pinned
  28 September canonical production script.
- A standard-library Python content-addressed object store, SHA-256
  verification, SQLite artifact and origin registration, optional row-level
  result index, product-release pins, and independently verified backup/restores.
- Cleanup is opt-in, and is *blocked* until independent backups and
  product dependency pins are complete. A deleted local duplicate must
  still be reconstructible by its immutable SHA-256 object ID.

## What is NOT yet achieved

The October LO05/LO04 modules are not integrated into a standalone,
scientifically validated release. Existing LO05 results are candidates until
their input and estimator fingerprints, design variance and external anchors
are independently validated. A Windows production test has not been run
by this Git branch. The legacy bundle is still required for incremental
October processing and should **not** be deleted.

The GitHub repository cannot see files on the user's laptop. The
new archive and its backup will initially exist outside Git; there is no
claim that thousands of old caches have already migrated to GitHub.

## Initial Windows setup

1. Clone the repository. Keep the existing original data and LO05 bundle.
2. Set LO_REPO_ROOT to your clone; LO05_BUNDLE to the extracted LO05/LO04
   bundle containing code/INTEGRATED.R; LO_STORAGE_CONFIG to your own
   config.local.json; LO_PYTHON to Python 3.
3. Copy config.example.json to config.local.json, replacing environment
   placeholders with actual paths, each OUTSIDE this Git repository.
4. Check status before migration:
   Rscript 06_pipeline/RUN.R --action=status
5. Make an inventory and migrate safe derived intermediate files:
   Rscript 06_pipeline/RUN.R --action=inventory
   Rscript 06_pipeline/RUN.R --action=migrate
6. Run a dry planning pass:
   Rscript 06_pipeline/RUN.R --action=plan --scope=nld_plus_19
7. After the Windows tests and science gates pass, perform incremental
   calculation, first NL then 19 reference countries:
   Rscript 06_pipeline/RUN.R --action=execute --scope=nld_plus_19
8. Other countries form an independent scope:
   Rscript 06_pipeline/RUN.R --action=execute --scope=other

The full clean replication is explicitly gated by LO_ALLOW_FULL_REPLICATION=YES
and uses the 28 September scientific lock. It is not equivalent to an
October re-estimation until all October extensions are independently validated.

## Store lifecycle (only controlled non-source files)

The local-only config identifies the original result directories, primary
archive and independent backup drive. Use:

    python 06_pipeline/storage_manager.py migrate --config .../config.local.json
    python 06_pipeline/storage_manager.py index-csv --input RESULTS.csv --config .../config.local.json
    python 06_pipeline/storage_manager.py pin --input release-pins.json --config .../config.local.json
    python 06_pipeline/storage_manager.py verify-backup --config .../config.local.json
    python 06_pipeline/storage_manager.py cleanup-plan --config .../config.local.json
    python 06_pipeline/storage_manager.py export-manifest --config .../config.local.json --output .../release_manifest_for_review.json

A pin manifest is JSON, e.g.:
    {"product":"slides","release_id":"v1",
     "dependency_closure_verified":true,
     "artifact_sha256":["<exact-64-character-SHA256>"]}

Release pins must collectively cover slides, dashboard, and paper for the same
release, with an explicit attestation that the entire dependency closure has
been checked. The absence of a pin must never mean permission to erase a file.
A separate clean-replication PASS receipt, bound by an SHA-256 checksum in the
local config and matching that release, must also document verified source
editions and numerical output fidelity. It is generated only AFTER an actual
end-to-end replication check, not by this storage tool.

Default cleanup is still disabled. The tool refuses deletion without the
complete pins, independent off-device backup, tested restoration, replication
receipt and retention period. Method, source and validation registers and
current central-result registries are explicitly protected.

**For intermediate results in Git:** commit only reviewed, path-free release manifests with content hashes, sizes, scientific status and producer-code references. The `export-manifest` command generates a draft metadata-only inventory; it does NOT approve publication of the underlying result bytes. Upload small aggregated result files only after the existing scientific and source-provider rights gates permit it.

**Never push the local provenance.sqlite or object store into public Git.**
They can contain sensitive absolute paths, restricted source lineage and
large derived files. Commit *sanitised* release-level file manifests only
after the existing [rights review](../DATA_LICENSE.md) is satisfied.
Code history is kept by Git commits/tags; each released metric must additionally
name its producing code SHA, source SHA, estimator fingerprint and validation.

## AER replication

GitHub stores source, specifications, tests, version history, documentation,
and approved small public aggregates. OECD/IEA microdata stay outside Git.
A complete AER submission uses a trusted repository, such as the AEA Data
and Code Repository (openICPSR), with a dataset access statement, exact
program-to-exhibit map, runtime, platform/package versions, source editions,
coverage, and all legally sharable outputs.

See [REPRODUCIBILITY.md](../REPRODUCIBILITY.md),
[05_publication/REPLICATION_GUIDE.md](../05_publication/REPLICATION_GUIDE.md)
and the [AEA policy](https://www.aeaweb.org/journals/data/data-code-policy).

## Deletion policy

The default is report-only; no automatic deletion on migration or production.
A later housekeeping job can be enabled without prompts for each file only
after a verified complete product pin set, scientific/replication gates,
independent second copy, successful restore test and retention period.
Never delete official data, canonical code, central result registries,
published versions, or the only copy of an input.
