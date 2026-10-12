# Private Google Drive result sharing

## R-native publisher (10 October update)

The active R runner now uses `DRIVE_SYNC.R` to invoke the already authorized
rclone executable directly. Python is **not required** for Drive publication.
R packages `jsonlite` and `digest` are used for manifests and SHA-256.
The previously created `drive.local.json` remains valid; do not run
`setup-drive` again. Use the same local R entry point with
`LO_ACTION=publish`, then source RUN.R.

The R-native publisher now has two tightly scoped private outputs: the
existing small quota report and, when present, the **latest completed, audited
LO05 return** (`LEARNING_OUTCOMES_RETURN.zip`) together with a fixed list of
named CSV/TXT status, counts, validation and coverage reports. It does **not**
recurse over arbitrary files or automatically upload source microdata, raw
student-level rows, SQLite, Parquet, or RDS. The run ZIP is uploaded only after
its known member names, member sizes, text payload and credential signatures
are checked against the pinned LO05 archive contract. Unknown members cause
a HOLD; the run is not silently skipped when an explicit run ID was requested.

After every private SHA-256 readback the files are stored both as immutable
`objects/<SHA>` and (for finished runs only) under recognisable
`reports/run_YYYYMMDD_HHMMSS/<report>` paths. The `LATEST.json` pointer is
only advanced after *every* selected file and named mirror is verified.
Cloud success never implies scientific validation.

**12 October 2026: publish the existing Windows run without recomputing:**

```r
repo <- "C:/Users/bason/Downloads/Learning-Outcomes-Git-20261010"
Sys.setenv(
  LO_REPO_ROOT = repo,
  LO_START_ACTION = "publish",
  LO_SCOPE = "nld_only",
  LO_DRIVE_SYNC_RUN_ID = "run_20261012_084825"
)
source(file.path(repo,"START.R"), encoding="UTF-8")
```

This *does not run a scientific calculation*, change central scientific
registries, or delete any files. The existing rclone OAuth is reused. It
does create only small local transfer manifests/checkpoint metadata in
`LO05_RESULTATEN/.cloud_sync`. A normal future `plan/execute` completion
may publish the latest completed return automatically; the chosen run
must have its reviewed `STATUS.txt`, `PHASE_STATUS.csv`,
`PLAN_COUNTS.csv` and `LEARNING_OUTCOMES_RETURN.zip`.
Set `LO_DRIVE_SYNC_RUN_ID` to a specific completed run if desired,
or unset it to select the most recent complete run. Do not infer that
remaining large result caches have already been migrated.

Two separate user authorizations are needed: (1) connect Google Drive to
ChatGPT, and (2) authenticate rclone against the same Google Drive account on
Windows. Neither authorization is available to repository scripts automatically.

## Current project: rclone OAuth already works

The user has completed Google OAuth and verified the private Drive folder
from Windows. ChatGPT independently read the uploaded connection_test.txt.
Do not repeat the OAuth or Google Cloud setup.

**One-time local setup using the existing R runner:**

    Rscript 06_pipeline/RUN.R --action=setup-drive

This finds the extracted rclone.exe in Downloads, checks the configured
lo_private remote and the existing Learning-Outcomes-Private folder, and
writes a local-only drive.local.json under
Downloads/LO05_RESULTATEN/.cloud_sync/. No upload or deletion occurs.

**First real upload (after setup):**

    Rscript 06_pipeline/RUN.R --action=publish

After that, plan and execute actions attempt a verified Drive upload
automatically at completion. For checkpoints during a long-running job,
run the same entry point with --action=watch in a separate PowerShell
window. This does not start a second scientific R run.

These commands assume a local clone of the feature branch and Python 3
on PATH. The October scientific engine still needs the local LO05_BUNDLE
setting for actual calculations; the cloud setup alone does not validate it.

## Local Windows setup (manual alternative)

1. Connect Google Drive in the ChatGPT connection flow, with the account
   that will own the private project folder. User authorization is required.
2. Install rclone from https://rclone.org/downloads/ and run the following
   commands in PowerShell:

    rclone config
    rclone lsd lo_private:
    rclone mkdir lo_private:Learning-Outcomes-Private

   The first command should create a Google Drive remote named lo_private.
   Keep its OAuth configuration outside Git. Do not make the Drive folder public.
3. Clone the feature branch and copy 06_pipeline/drive.example.json to
   drive.local.json OUTSIDE the repository. Set local_results_root to
   the existing LO05_RESULTATEN directory and remote to
   lo_private:Learning-Outcomes-Private. Use PRIVATE_ACCOUNT_ONLY.
4. Configure the local environment variables LO_REPO_ROOT to the cloned Git
   root, LO_DRIVE_SYNC_CONFIG to the full private JSON configuration path,
   and LO_PYTHON to the installed Python 3 executable.
5. From the Git clone, first preview without transmitting any data:

    python 06_pipeline/drive_sync.py preview --config PRIVATE_DRIVE_CONFIG

6. Publish stable, completed results using the ONE canonical R entry point:

    Rscript 06_pipeline/RUN.R --action=publish

7. While another RStudio process is running long calculations, optionally run
   this same entry point in a second terminal:

    Rscript 06_pipeline/RUN.R --action=watch

   The watch action is a cloud sync worker only; it does NOT run a second
   scientific calculation. It repeats every 180 seconds, by default.
   Alternatively schedule the publish action periodically in Windows.
   After normal plan or execute, the R runner also attempts cloud sync once.

## Cloud storage contract

The Drive folder has:
- objects/ — immutable content-addressed result bytes, keyed by SHA-256
- manifests/ — timestamped provenance indexes with relative paths, hashes,
  sizes, producer Git commit, and NOT_AUTOMATICALLY_VALIDATED status
- LATEST.json — updated only after the remote checksum check succeeds

The active R-native uploader selects only completed, reviewed LO05 run reports and the tiny quota summary. It does not publish arbitrary files from candidate_checkpoints or raw sources.
CSV/TXT/JSON summaries can be reviewed through a connected Drive account.
Binary RDS/Parquet may require a readable summary export for ChatGPT review.

Result checkpoints are staged as SHA-256 immutable objects, transferred with
rclone copy (NEVER destructive rclone sync), verified with checksum matching
against the cloud folder, and indexed by a final manifest. A failed upload
does not change any locally computed scientific value.

A Drive copy by itself is not sufficient to delete local results. Cleanup
also requires complete product-result dependency pins, an independently
tested off-device second backup and restore, and a successful clean-from-source
scientific replication receipt tied to the exact release.

## Security and science gates

Never upload official OECD/IEA microdata, tokens, credentials, original student
or school records, private SQLite provenance databases, or anything requiring
a provider redistribution permission to this shared folder. The Drive folder
must remain private.

Do not equate a cloud publication with science VALIDATED. A final AER-ready
replication package needs the complete October producer code in Git, exact
source editions and survey methods, full Windows production tests, numeric
fidelity against published exhibits and trusted archival deposit.

CI tests here are synthetic smoke tests, not a complete Windows pupil-data run.
See issue #6 for remaining scientific and production acceptance gates.
