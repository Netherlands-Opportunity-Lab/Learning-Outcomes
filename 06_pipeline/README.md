# Next scientific release — reproducible storage and production

This directory is a **new development workflow**, not a replacement for the
locked 28 September 2026 release. The scientific code already published in
[02_analysis/current](../02_analysis/current) and the existing
[dashboard](../03_dashboard/README.md) are unchanged.

## What is implemented

- One R entry point: RUN.R, with scopes nld_only, nld_plus_19,
  reference_19, other, all.
- A one-time `vendor` action copies only scientific `.R` producer files from the
  existing local LO05 bundle into the feature-branch working tree, accompanied
  by a SHA-256/size manifest. These files must be reviewed and committed before
  claiming a self-contained October code release. No data or caches are copied.
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
6. To prepare the complete October **producer code history** for Git,
   run `Rscript 06_pipeline/RUN.R --action=vendor` with LO05_BUNDLE set;
   inspect `06_pipeline/vendor/PRODUCER_SOURCE_SHA256.csv`, review and commit
   only the listed source code. This is not a data migration and cannot be
   done remotely without access to the local bundle.
7. Run a dry planning pass:
   Rscript 06_pipeline/RUN.R --action=plan --scope=nld_plus_19
8. After the Windows tests and science gates pass, perform incremental
   calculation, first NL then 19 reference countries:
   Rscript 06_pipeline/RUN.R --action=execute --scope=nld_plus_19
9. Other countries form an independent scope:
   Rscript 06_pipeline/RUN.R --action=execute --scope=other

The full clean replication is explicitly gated by LO_ALLOW_FULL_REPLICATION=YES
and uses the 28 September scientific lock. It is not equivalent to an
October re-estimation until all October extensions are independently validated.

## Share completed results during long runs

The optional **private Google Drive** publisher has been wired into the same
R entry point, with actions publish and watch. It synchronizes finished
allowlisted R outputs (not raw source data) into immutable SHA-256 objects,
verifies cloud copies, and publishes a manifest pointer. GitHub stores code
history and reviewed metadata, not private raw data.

See [GOOGLE_DRIVE_SETUP.md](GOOGLE_DRIVE_SETUP.md) for user authorization,
rclone setup, the two separate connections, and exact Windows commands.

## Automatically publish safe run progress to GitHub

The ONE R entry point now supports `LO_ACTION=status-publish`, which reads
the latest local LO05 run metadata and commits a sanitized status-only JSON
to an isolated public GitHub branch. Plan, execute and replicate also attempt
this automatically on exit; `publish` attempts both private Drive and safe
GitHub status. No raw logs or statistical result rows are published to GitHub.
Detailed outputs stay local or in private Drive. The GitHub control branch
is separate from code/history branches and the locked September release.

See [GITHUB_STATUS_SETUP.md](GITHUB_STATUS_SETUP.md).

## Dashboard runtime location and fastest publication

The public dashboard is a static site. Its frozen aggregate profiles are
delivered as country/system JSON files and precomputed metadata/rank/panel
files in the **published GitHub Pages release** under `05_publication/`.
The canonical scientific frontend and its production data manifest live in
`03_dashboard/`. See `03_dashboard/README.md`,
`03_dashboard/data/PRODUCTION_DATA_MANIFEST.csv` and the
`05_publication/PUBLIC_DASHBOARD_MANIFEST.json` fidelity contract.

The browser reads precomputed aggregates directly from the published static
assets; it does **not** query Drive, SQLite, Parquet or an R session. This is
the efficient and fast architecture for website visitors. Google Drive is
optional for research backups and private collaboration, not a dependency of
the published dashboard. New scientific results must pass the scientific
release and public-data/fidelity gates before replacing the published JSON
assets; do not publish arbitrary LO05 run outputs directly as dashboard data.

## October scientific production: one active R entry point

The October v2 source bundle is **content-locked**. The single active
`06_pipeline/RUN.R` now discovers the precise existing extracted bundle or
the original reviewed `LEARNING_OUTCOMES_INTEGRAAL_v2_20261010.zip` under
Downloads. It verifies the ZIP SHA-256, all 56 source manifest entries
and critical R code SHAs. It refuses mismatched or mixed releases.

Actions with the same R entry point:

- `LO_ACTION=check-contract`: read-only scientific product contract audit,
  with 79,448 task IDs, 1,867 NL tasks, 27,979 tasks for 19 foreign
  reference countries, 49,602 other-country tasks, 138 figure contracts,
  13 core-deck slides and Q01–Q08. It writes explicit coverage/hold reports.
- `LO_ACTION=vendor-push`: one-time archive of original October scientific
  producer **R code only** on this feature Git branch, with SHA-256
  provenance and sanitation of any personal fallback path. This does not
  publish pupil files, result stores or caches.
- `LO_ACTION=plan`: invokes the same contract gate before the LO05
  planning and provenance consolidation, without calculations.
- `LO_ACTION=execute, LO_SCOPE=nld_plus_19`: NL phase first, then 19
  reference countries; previously verified core/gender engine estimates
  can be reused, and non-core legacy estimators remain in quarantined
  candidate checkpoints. No silent scientific promotion.
- `LO_SCOPE=other`: optional later international coverage, independently
  invoked and not blocking the main paper/deck release.
- `LO_ACTION=reference-audit`: separately pins the World Bank WDI 2024
  PPP numeric source snapshot and reports any differences without
  changing the locked 19-country production list.

Exact user-oriented status and scientific gaps are documented in
[SCIENCE_AUDIT_20261010.md](SCIENCE_AUDIT_20261010.md).
**Do not confuse successful structural validation with completed learner
calculations or an AER cold replication.** The source engine still blocks
some modules without validated input columns/design-based uncertainties,
and the eight paper QA gates remain open.

**Windows handoff after pulling this branch:**

    Sys.setenv(LO_ACTION='check-contract')
    source('C:/Users/bason/Downloads/Learning-Outcomes/06_pipeline/RUN.R')

The historic/producer code archival is a separate one-time invocation
(set `LO_ACTION='vendor-push'`) so that Git history is preserved **before**
starting long production. Subsequently set `LO_ACTION='execute'` and
`LO_SCOPE='nld_plus_19'` in the same RStudio session.

The existing September frozen public dashboard is unchanged until a
new release is scientifically validated and the public data/fidelity
manifests pass. Do not delete historical result files in the meantime.

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


A separately documented [historical results catalog](HISTORICAL_RESULT_FAMILIES.csv)
records known row counts, immutable archive hashes, uncertain producer links
and explicit publication holds. It is metadata, not an uploaded result archive.

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
