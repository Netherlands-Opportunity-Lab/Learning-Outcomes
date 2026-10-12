# Projectuitvoering — actuele ingang 11 oktober 2026

> **12 oktober 2026 — bevestigde uitvoering:** RStudio blijft op de eigen Windows-computer rekenen. GitHub is voor versiebeheerde code en gecontroleerde definitieve publieke resultaten/producten; private Google Drive voor automatische opslag van tussenresultaten/caches/rapporten. De eerder kort opgenomen cloud-computerinterpretatie is ingetrokken. Gebruik de lokale runner alleen voor gericht wetenschappelijk werk. De *eerstvolgende* stap is bestaande resultaten automatisch veilig naar Google Drive synchroniseren (de huidige Drive allowlist omvat alleen het quotarapport); niet de vorige run herhalen. Lokale R-geproduceerde bestanden kunnen pas na volledige dependency/backup/restore-gates en toestemming worden opgeruimd. Zie §11 van het [masterplan](MASTERPLAN_20261011_v2.md).


**Leidend plan:** [MASTERPLAN_20261011_v2.md](MASTERPLAN_20261011_v2.md). De septemberfreeze en publieke website blijven onaangetast totdat wetenschappelijke en productacceptatie zijn bewezen. Oude instructies hieronder zijn historisch of specifiek voor onderhoud en zijn niet de standaardvolgende stap.

**Enige gebruikersingang in Windows RStudio:**
```r
Sys.setenv(LO_START_ACTION="execute-nld-core", LO_SCOPE="nld_only")
source(file.path(repo,"START.R"))
```
Pas toepassen als [PR #5](https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes/pull/5) alle Windows/Linux CI-tests doorstaat. Deze smalle actie gebruikt de bestaande LO02 V5-route voor alleen Nederlandse PISA core/gender (wetenschappelijke input-/codefingerprint hergebruik), zonder automatische V11-kandidaatproductie, bronimport of GC. Niet gelijk aan definitieve wetenschappelijke vrijgave en niet aan de volledige 29.846-taakproductie. Andere modules worden afzonderlijk wetenschappelijk beoordeeld.

**Niet doen:** automatisch herhaald `next-batch`, de oude `reconcile-and-plan` voor wetenschappelijke productie, of de brede `execute` zolang de productieadapter voor niet-kernmodules niet is gecertificeerd. Gebruik opslaginstructies hieronder alleen wanneer het masterplan de betreffende stap expliciet vrijgeeft.

---

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
    source(file.path(Sys.getenv('USERPROFILE'),'Downloads','Learning-Outcomes','06_pipeline','RUN.R'))

The historic/producer code archival is a separate one-time invocation
(set `LO_ACTION='vendor-push'`) so that Git history is preserved **before**
starting long production. Subsequently set `LO_ACTION='execute'` and
`LO_SCOPE='nld_plus_19'` in the same RStudio session.

The existing September frozen public dashboard is unchanged until a
new release is scientifically validated and the public data/fidelity
manifests pass. Do not delete historical result files in the meantime.

## One RStudio command, no routine PowerShell

Save the reviewed GitHub root `START.R` **once** to the Windows Downloads
folder (a standalone identical copy is included in the 10 October handoff ZIP).
Then run just:

    source(file.path(Sys.getenv("USERPROFILE"),"Downloads","START.R"))

It checks the exact expected repository and feature branch, runs a
`git pull --ff-only` (no force/reset or branch switching), and invokes the
existing `06_pipeline/RUN.R`. By default it selects the non-destructive
`storage-audit`, regardless of an old RStudio LO_ACTION. Explicitly set
`LO_START_ACTION` for other stages; see the source-locked handoff. It does
not run science/cleanup invisibly.

## Large historical 89-GB local master: safe native R reconciliation

The user's `PISA_PIRLS_MASTER_PIPELINE` (approximately 89 GB according
to the owner) is a mixed **historical raw-source / current / history / cache /
code / release** tree. It has not yet been traversed from a local Windows
session. DO NOT classify the whole tree as redundant scientific results.

The owner-controlled private Drive location
[Canonical-Results-v1](https://drive.google.com/drive/folders/1i4Kl8BOonSrAEdK_MH8wcEiPE41_Zwkb)
contains separate catalogue, immutable objects, releases and private migration
reports. It is not an independent backup by itself and may not have enough
free quota for a 89-GB full copy.

The same versioned `RUN.R` supports the following ordered actions, none of
which launches student-level estimators:

1. `LO_ACTION=storage-audit`: scan the complete project directory, report
   file/folder bytes and classifications, inspect SQLite *schema* where
   RSQLite/DBI is available, register all original relative paths LOCALLY,
   and publish only metadata reports to the private Drive folder. No
   hashes of all 89 GB, no cloud bulk transfer and no deletion.
2. `LO_ACTION=storage-plan`: read the inventory, distinguish authoritative
   current/historical registries from candidate caches and restricted input
   files, and check Google Drive's actual free quota. No migration yet.
3. `LO_ACTION=storage-dedupe`: optional, incremental SHA-256 audit of
   equal-size derived files; resumable (default 2 GiB of read work per pass)
   and estimates strictly byte-identical possible savings. **Never delete**
   solely because sizes or SHA hashes coincide.
4. `LO_ACTION=storage-migrate`: explicitly authorized limited batch
   (default up to 1 GiB) of safe, high-priority aggregated result artifacts
   only. Uses SHA-256 content-addressed Drive objects, downloads them to
   re-check actual bytes and persists a local copy-register before proceeding.
   This is not permission to upload OECD/IEA microdata, live SQLite files,
   unknown archives, or code that should be versioned in Git.
5. `LO_ACTION=storage-retirement-plan`: show files that might eventually
   be retired, after full source/code/result/product lineage, tested
   independent backup, clean scientific replication, and provider-rights
   checks.
6. `LO_ACTION=storage-cleanup-apply`: **explicitly blocked** at this
   stage. We do not destroy unique historical research evidence just
   because a single Drive copy exists.

The original source directory is READ ONLY in all implemented storage
actions. Its deletion is **not** safe until every unique and licensed
source/input asset also has a separately recoverable authorized source,
all product-version dependencies are pinned, and real end-to-end restore
tests have passed. The journal-style relational lineage schema is tracked
in [RESULT_LINEAGE_SCHEMA.sql](RESULT_LINEAGE_SCHEMA.sql); schema existence
is not proof that old rows have been remapped.

**One next local command after git pull:**

    Sys.setenv(LO_ACTION="storage-audit")
    source(file.path(Sys.getenv("USERPROFILE"),
       "Downloads","Learning-Outcomes","06_pipeline","RUN.R"))

The local report directory is under
`Downloads/LO05_RESULTATEN/master_reconciliation/`. Its private Drive
mirror will permit ChatGPT to examine findings without another uploaded ZIP.
The Git public run-status channel receives only aggregate counts, never
a list of filenames or absolute paths.

**Product basis corrected from uploaded attachments:** the current policy
deck contains **21 slides**, not the older prototype's 13; the science
seminar has **50 slides** and the final science note **16 pages**.
See [PRODUCT_SOURCE_RECONCILIATION_20261010.md](PRODUCT_SOURCE_RECONCILIATION_20261010.md)
and the exact SHA-256 product locks. The frozen September dashboard remains
on GitHub Pages and does not need Google Drive at runtime.


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
