# GitHub run status and private Drive outputs

The active scientific entry point remains `06_pipeline/RUN.R`. No second R producer is introduced.

## Public branch: only safe metadata

The repository is public. The Git status sender publishes only allowlisted categorical machine statuses, nonnegative planning/production counts, a sanitized run ID, and the exact code commit. It deliberately excludes detailed logs, raw statistical results, user paths, personal identifiers, secrets, source microdata, and unvalidated estimates. A status update never implies scientific release.

Destination: https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes/blob/lo-run-status/run_status/latest.json

History is preserved through ordinary Git commits to the separate `lo-run-status` branch. The publisher uses a detached temporary Git worktree and a normal non-force push, leaving the science source branch and `main` untouched.

## First use in Windows

Pull latest feature-branch code in PowerShell:

    git -C "$env:USERPROFILE\Downloads\Learning-Outcomes" pull --ff-only

Then in RStudio:

    Sys.setenv(LO_ACTION="status-publish")
    source(file.path(Sys.getenv("USERPROFILE"), "Downloads",
                     "Learning-Outcomes", "06_pipeline", "RUN.R"))

The first GitHub push may ask to authenticate with Git Credential Manager. Do not put a personal access token into a script, screenshot, chat or repository. If the git push fails, the safe pending status remains locally under ignored `06_pipeline/state/`; scientific results are unaffected.

## During regular runs

Set LO_ACTION to `plan` or `execute`, with existing LO05_BUNDLE configured. The same R entry point publishes Git status automatically on success or failure. Set LO_ACTION to `publish` to run the optional private Drive publisher and then GitHub status, without computing new scientific estimates.

During very long runs, call the same `status-publish` action periodically from another R session if live progress is needed. Ordinary runs publish Git status on exit, not continuously. The existing Drive `watch` action remains optional.

Disable automatic GitHub status by setting LO_GITHUB_STATUS=OFF.

## Why not upload all results to public Git?

The existing research repository is public and the OECD/IEA source terms require a conservative redistribution boundary. Larger output files, raw diagnostics, full result history and private intermediate caches remain local or in the owner-controlled private Drive, with separate archive/backup controls. GitHub is not a safe bulk-microdata repository. This status channel cannot publish scientific results until exact product and scientific release gates have approved them.

## Tests and limitations

Run `Rscript 06_pipeline/tests/test_github_status.R` or use CI. Synthetic tests assert that paths, emails and credential-looking strings in source log files cannot reach the Git status JSON. Windows and Linux CI test the R parser and privacy allowlist. A real Windows Git authenticated push is still required before declaring the upload operational. The full October estimator release and clean AER replication remain separate open tasks tracked in issue #6.
