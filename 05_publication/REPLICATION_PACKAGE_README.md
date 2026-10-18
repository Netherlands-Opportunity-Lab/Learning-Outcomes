# Learning Outcomes — replication package, interim release

This package contains the current analysis and publication code, its R environment
lock, approved scope, source catalogues, and the aggregate observations displayed
in the accompanying dashboard. Read `release_inputs/PROVENANCE.json` for the exact
snapshot, code commit and validation evidence. Each point preserves its cell ID,
input/code fingerprints, result hash, sample, standard error and observed sample N.

## Rebuild the published figures

With Python 3.11 or newer, extract the package into a fresh directory and run:

```sh
python reproduce_dashboard.py
python -m http.server 8769 --directory rebuilt_dashboard
```

Open `http://localhost:8769/nl/` (or `/en/`). The first command verifies every
package file and rebuilds the original dashboard runtime byte for byte. It fails
on changed input or an existing output directory. This reconstructs the public
figures from checked aggregates; it does not rerun pupil-level analysis. The
additional release information and ZIP download on the hosted site are publication
attachments; the reconstruction checks the original runtime and data before those
attachments are added.

Only project-authored aggregate points required by approved dashboard figures are
included. Appendix-only research results and complete bulk masters are excluded.
Missing years/groups remain explicitly missing; no interpolation or zero fill is
used. Country selection, reference means and ranks are enabled only for exact
source-, sample- and method-bound comparisons. Missing focus years or groups
block the complete comparison; the country list explains excluded candidates.
The package includes the same balance evidence and rechecks every membership. The displayed point count counts country/figure/year/
series combinations: one underlying cell can support more than one product.

## Recalculate from original sources

The scientific entry point is `START.R` with `06_pipeline/RUN.R`. Follow
`06_pipeline/REPLICATION_CURRENT.md`. The current executable workflow is
`fixed-audit` → `fixed-produce` → `fixed-finalize` → `fixed-status`; `produce-approved`
orchestrates these stages. Use a Git checkout pinned to the package's source commit
for scientific production, restore the R environment from `renv.lock`, and bind
official source files through the source catalogues and `LO_SOURCE_BINDINGS.R`.
`06_pipeline/RUN_CONFIG.example.json` specifies the scope and optional exact filters.
Use `all_required` for all admitted countries and approved analyses. The number of
countries is determined by evidence, not by the historical names of country sets.

Official OECD/IEA pupil files must be obtained by the replicator under their terms;
they are not redistributed here. The current production runner also requires the
retained, hash-locked `LEARNING_OUTCOMES_PIPELINE` source bundle and the identified
external SES author code. Public sanitised copies of the historical engine are
included with an original/public hash map, but are not a replacement for that
original bundle. A clean installation using only this public ZIP has **not** been
certified to reproduce every pupil-level result. This dependency and remaining
scientific checks are open, not hidden by the working dashboard reproduction.

## Code and result map

| Location | Responsibility |
|---|---|
| `START.R`, `06_pipeline/RUN.R`, `LO_FIXED_CONTROLLER.R` | One run configuration, stage order, immutable execution version |
| `MASTER_ESTIMATION_GRID.R`, `GRID_ARCHIVE_BATCH.R` | Exact targets, evidence validation, reuse and missing-cell accounting |
| `LO_EXACT_DISPATCH.R`, `LO_EXACT_ESTIMATORS.R` | Approved estimators and exact-cell dispatch |
| `LO_INTERNATIONAL_*.R`, `LO_*SOURCE*.R` | Source binding, country/year blocks, variable availability |
| `LO_REMOTE_CHECKPOINT.R`, `LO_ATOMIC_CHECKPOINT.R` | Durable block receipts, verified Drive checkpoints and crash-safe writes |
| `LO_FINAL_GUIDED_EXPORT.R` | Independently rechecked grid → approved public product rows |
| `LO_FINAL_GUIDED_DASHBOARD_BUILD.py` | Product rows → figures, availability and bilingual website |
| `05_publication/preview_overlay/` | Five-choice interface, chart rendering, exact reference and rank logic |
| `LO_PARTIAL_DASHBOARD_RELEASE.py` | Interim publication gate; no claim of complete paper/scientific release |

Not all files in the historical engine are executed by the active route. The
current scope decisions and exact cell dispatcher, not archived broad run commands,
determine production. Approved appendix and research extensions remain available
in the pipeline but do not silently become dashboard products.

## Precision, resumability and storage

Estimates and uncertainty retain full available numerical precision. Rounding is
only for labels, tooltips and tables; CSV/JSON downloads preserve the stored values.
Compression reduces size without truncating estimates. Completed and certified
blocks are recorded before the next block; an identical resumed run reuses matching
source/method/configuration fingerprints. A failure in a block may require that
unfinished block to run again. Changed inputs are not treated as an identical run.

Raw sources may stay locally; private intermediates/checkpoints belong on private
Drive; approved code and public products belong on GitHub. Temporary local files
and a small working result index remain necessary while R runs. GitHub and Drive
credentials are deliberately absent. Do not delete source files or active locks.

Code is under the repository MIT licence. OECD/IEA data conditions and brand/font
licences remain applicable; see `DATA_LICENSE.md` and the included asset licences.
The interim publication does not constitute acceptance of Q01–Q08, the paper,
the 21-slide presentation or complete scientific replication.

Country selection provenance: `release_inputs/BALANCED_REFERENCE_EXPORT.json` binds every comparison cell to result/source certificates. Its fixed panels are produced by the existing R membership engine and independently checked during Python reconstruction. Default membership uses the eligible rich candidates, excludes the focus, and never silently fills missing years or pools incompatible definitions. Changing checkboxes recalculates equal-country means from the selected complete panel; ranks use that same panel and never plot a group rank.
