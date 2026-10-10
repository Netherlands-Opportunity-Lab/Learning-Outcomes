# Private Google Drive result sharing

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

The upload tool selects stable files under LO05_RESULTATEN/runs and
LO05_RESULTATEN/candidate_checkpoints, never raw source datasets.
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
