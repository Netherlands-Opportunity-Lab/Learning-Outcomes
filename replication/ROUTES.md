# Execution routes and scope

The public ZIP has one entry point, `python REPLICATE.py`. Python 3.12 and
Node 24 are tested on Windows and Linux. Only the dashboard/application tests
need Node; inspection and dashboard reconstruction use Python's standard library.

1. `python REPLICATE.py inspect` validates exact package/result hashes and prints
   counts. It reads aggregate records and does not recalculate pupil statistics.
2. `python REPLICATE.py dashboard --output rebuilt_dashboard` reconstructs the
   checked dashboard from aggregates and compares the original core manifest.
3. `python REPLICATE.py source --config all_required` explains the source route.
   A future `--run --settings private-settings.json` explicitly delegates to the
   pinned Git checkout's `START.R` and `06_pipeline/RUN.R`, with fresh mode.
   It is not part of this release's executed acceptance. The owner deferred the
   full source exercise and the additional 36 countries.

The source settings contain `repository`, `code_commit`, `rscript` and an
`environment` object with `LO_FIXED_ROOT` (new bounded private workspace),
`LO_SOURCE_BINDINGS` (CSV: sha256,path), `LO_COBREROS_ROOT` (pinned authors'
checkout), `LO_DRIVE_SYNC_CONFIG`, and the recorded R/Python library settings.
These private paths and credentials do not belong in the public package.
`START.R` verifies the code/environment and invokes audit, approved production
and final checks; scientific review remains distinct from a successful exit.
Resume the same source run only with unchanged source, configuration and code
fingerprints. A changed source requires a new audited identity. No existing
result registry should be used as a fresh replication output.

Restore the R environment from `renv.lock` in the pinned checkout. Acquire OECD
and IEA source files through the routes in `SOURCE_CATALOG.csv` and
`HOME_SOURCE_CATALOG.csv`. Match raw hashes before estimation. Preserve their
terms. Obtain the authors' version `1da4b26097e84e732973af672355a1c3103d5d33`
using the route in `02_analysis/scientific_dependencies/README.md`. Its extracts
and parameters are necessary for the selected SES calibration; output country
selection is separate from calibration inputs. No private Downloads ZIP is a
dependency of this explicit source route.

All three example configurations limit production to the current phase.
`nld_plus_19` is the historical name for the rich candidate pool; strict balanced
reference membership may be smaller and differs between figures. It cannot
authorize missing countries, new research families or a shortened focus anchor.

The package keeps research precision and exact absence reasons. The public
source probe compares estimates/SE to `1e-9`, N and status exactly; broad source
replication is not inferred from it. Scientific-source probes were actually run
on Windows. Linux evidence covers technical contracts and aggregate rebuilds.

The private manuscript/presentation bundle, including editable source and
private rebuild scripts, is delivered separately to the owner. Public statistical
methods, source metadata, scientific evidence and aggregates remain available.
No public CI artifact should contain the private documents or their prose.
