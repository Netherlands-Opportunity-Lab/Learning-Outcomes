# Current replication entry point — 14 October 2026

This is an executable development pipeline, not a completed scientific replication release. Real production now covers independently verified Netherlands PISA, PIRLS and TIMSS cells across the complete 40-combination Dutch core-year anchor. The current count, result sizes and closure receipts are recorded in `review_20261013/STEP1_EXECUTION_EVIDENCE_20261014.json`. The broader approved scope still requires source/sample/method certification, reconciliation of older candidates, country approval and independent replication. See `START_HIER_ACTUEEL.md` and `ACCEPTATIE_EN_VOORTGANG.csv` for the current decisions. Do not infer readiness from a successful software test.

## One configuration, three existing stages

Copy `RUN_CONFIG.example.json` to a private local file and set `LO_RUN_CONFIG` to that file's absolute path. Its fields are:

| Field | Meaning |
|---|---|
| `scope` | `nld_only`, `nld_plus_19`, or `all_required`; these names do not certify a fixed number of countries. |
| `selection.surveys` | Optional subset of the approved surveys. |
| `selection.years` | Optional year strings such as `["2022"]`. |
| `selection.domains` | Optional exact domain identifiers from the grid. |
| `selection.modules` | Optional exact approved module identifiers from the grid. |
| `selection.countries` | Optional subset within the chosen scope; never substitutes for country approval. |
| `selection.stats`, `groups`, `definitions`, `peer_environments` | Optional exact grid values for statistics, groups, construct definitions and peer environments. |
| `selection.cell_ids` | Optional exact cell identifiers for a bounded run. |
| `max_compute_units` | Maximum number of previously incomplete source/method blocks attempted per production invocation; default 1. Completed blocks do not consume the limit. |

Empty selections mean all currently approved targets in that dimension. Filters intersect; they cannot authorize a new cell, country or statistic. Unknown selections and an empty intersection fail explicitly. A subset run does not certify complete dashboard balance or a complete paper. Scientific/source approvals remain mandatory, including for approved scope extensions. A choice of country group or visual style never authorizes additional pupil calculations.

Use the existing Git checkout and `START.R` entry point in RStudio. Set paths to the actual checkout, retained source bundle and private output root; never copy data into Git. For example, after adapting the paths:

```r
Sys.setenv(
  LO_REPO_ROOT = "/path/to/Learning-Outcomes",
  LO_RUN_CONFIG = "/private/path/run-config.json",
  LO05_BUNDLE = "/private/path/retained/LEARNING_OUTCOMES_PIPELINE",
  LO_FIXED_ROOT = "/private/path/results",
  LO_START_ACTION = "fixed-audit"
)
Sys.unsetenv("LO_SCOPE") # the explicit JSON configuration supplies the scope
source(file.path(Sys.getenv("LO_REPO_ROOT"), "START.R"))
```

After reviewing `GRID_AUDIT_SUMMARY.csv`, `PRIVATE_MASTER_GRID.csv` and `PRIVATE_BATCH_PLAN.csv`, use the same configuration with `LO_START_ACTION="fixed-produce"`. Repeat that bounded action to resume remaining approved blocks. Use `fixed-finalize` for reviewed private products. `fixed-status` is read-only. There are no hidden interactive menus and no automatic broad production, deletion or public deployment. The run fails if an explicit `LO_SCOPE` disagrees with the JSON.

`START.R` normally fast-forwards the development branch. For immutable reproduction set `LO_REPRODUCE_COMMIT` to the full recorded 40-character commit SHA in a separate checkout already at that commit. This disables the pull, requires unchanged tracked code and checks the exact R/package versions against `renv.lock`. Restore that environment with `renv::restore(prompt=FALSE)` before running. The lock records R 4.6.1 and 35 packages; clean restoration and exact-version checks have passed on Windows and Linux. Do not alter the environment of an active RStudio analysis.

The retained scientific source bundle remains an explicit external dependency. Its statistical files are fingerprinted. A clean end-to-end run from original sources and a fully portable release still require consolidation of that bundle and source access documentation. The existing original ZIP must be retained until those dependencies are replaced. A clean dependency-install test is not a complete scientific replication.

## Result identity, reuse and uncertainty

Each result carries its exact cell identity, source/input fingerprint, producer fingerprint, method, estimate, standard error and N. For low/high achievement peer targets, target membership can vary by plausible value: the scalar N explicitly describes the invariant analytic peer frame, while `PV_TARGET_SAMPLE_COUNTS.csv` records every exact target N separately. Its hash is bound to the source and method certificate, checked independently and included in export metadata; it must not be described as a fixed latent-group sample size. Source/method certificates preserve sample, weights, plausible values and variance definitions. `execution_receipts` ties an exact scientific execution to its numerical result hash. Result rows and receipts are committed in the same SQLite transaction; interruption cannot leave a falsely reusable partial result. Recovery verifies completed receipts independently and closes those cells before resuming only genuinely missing cells. Reuse checks the receipt, current result content, certificate, code and source bytes; a filename or an old `VALIDATED` label is insufficient.

`FIXED_INPUT_MANIFEST.json` freezes the selected configuration, target grid and input/scope/product hashes. Changing these requires a new audit. `RUN_RECORDS/*.json` preserves the configuration itself, input manifest, code hashes, Git commit when available, package/R versions, session information, output hashes and the selected result-version hashes. These records are private because they can contain source paths. Hashes identify versions; they do not independently certify scientific validity.

`COMPACT_MASTER_GRID.sqlite` holds one current row per cell plus each distinct successful numerical version once in `result_versions`. Exact reruns do not add duplicate numerical versions. No full checkpoint database is copied after each block. The old numerical version is retained before a replacement. Only exact approved cells are scheduled; derived gaps/ranks/reference means use certified parent results and do not automatically create pupil tasks. Necessary joint replicate/covariance information still needs to be retained for the approved derived claims; marginal standard errors alone are not enough. The full derived-result release is not yet certified.

## Precision and size

Scientific numbers remain native 64-bit floating-point values in SQLite. The interoperable `COMPACT_MASTER_GRID.csv.gz` uses 17 significant digits for round-trip precision, not 17 decimal places. Rounding a double saves no space in the database. Gzip compresses repeated metadata without losing precision.

`COMPACT_DASHBOARD_ROUNDED.csv.gz` is a separate presentation export: score/percentage estimates use one decimal, standard errors two, counts remain integers. Proportions are converted to percent and relabelled. It is never an input to ranks, gaps, uncertainty calculations or scientific verification. A future fractional-tie rank must not be forced to an integer without its documented rule. Both compact exports currently contain candidate results and are private until the scientific/publication gates pass.

The audit measures actual files in `RESULT_STORAGE_SIZE.csv`; the dated public evidence summary records those byte counts. The Netherlands target has 2,678 primitive cells, including separately approved PISA extensions that an earlier 2,526-row audit omitted. Unavailable constructs stay in that grid with source evidence. The numerical database, compressed scientific table, display table and joint PV/replicate evidence are measured separately. The eventual multi-country size depends on the approved eligible countries and retained covariance; it is not extrapolated from a mostly empty grid.

## Storage and deletion

Necessary original source bytes may stay on C:. Allowed intermediates use private Drive; eligible final code/results go to GitHub. Each production block requires a measured resource budget and at least 2 GiB operating reserve on both output and temporary volumes. Measured pilots now cover modern PISA, older PISA, IEA core/variance, IEA books and both peer source families. Their measured peak, pupil/PV/replicate limits and 64 MiB scratch budgets bind each certified batch. The space gate preserves 2 GiB reserve; it is not an operating-system disk quota.

The user's 14 October permission allows removing unnecessary RStudio/ChatGPT/Codex-generated project files, including recomputable intermediates. Creation by these tools alone does not establish that a file is unnecessary. Use an exact reviewed path selection, verify retained source/code dependencies and hashes immediately before deletion, and save a private receipt. Preserve necessary sources, unique results/evidence and unrelated material. Targeted removal and hash-verified NTFS deduplication have freed 16,475,670,096 physical bytes. Hardlinked source paths are preserved and immutable: modifying an alias modifies the shared bytes. No blanket deletion of the LO05/master folders. Unknown content inside a misleadingly named archive is not disposable project output. Cleanup remains an explicit operation, not a side effect of running analyses.

## FAIR and release requirements

This package aims at the [FAIR principles](https://www.gofair.foundation/fair-principles) and follows the [AEA preparation guidance](https://aeadataeditor.github.io/aea-de-guidance/preparing-replication-package.html). Completion requires a permanent version identifier, searchable metadata, source access instructions and editions, a data dictionary, licenses, declared computational requirements, all necessary code/dependencies, a product-to-result map and successful independent execution. See `../DATA_LICENSE.md` for the current publication boundary. Restricted sources need not become public to document their provenance/access route.

Still outstanding: complete approved-module/source certification; exact required covariance/derived products; approved eligible foreign-country list; complete scientific bundle portability; clean reproduction from original sources without hidden Downloads dependencies; final rights/QA review and durable release. The verified source blocks and green Windows/Linux checks are evidence of progress; full scientific completion and AEA-level external verification are still separate requirements.
