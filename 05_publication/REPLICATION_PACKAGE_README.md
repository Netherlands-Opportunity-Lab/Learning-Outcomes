# Learning Outcomes — current 47-country replication package

This version contains the explicitly selected 47 countries/education systems.
The other 36 are deferred, not deleted or treated as unavailable. Their approved
targets and separate resume configuration remain in the repository. Do not use an
unfiltered `all_required` run for the current phase.

The selected grid has 90,829 targets: 82,142 certified results, 8,687 documented
unavailable targets and no unresolved calculations. These counts do not imply
that every country has every outcome or a usable reference group.
`release_inputs/PROVENANCE.json` identifies the exact release. Result records
preserve producer, source, method, configuration, uncertainty and result hashes;
the export commit is not necessarily the producer commit.

## One entry point, three distinct routes

Start with `python REPLICATE.py inspect`. Python 3.12 is the tested version;
the entry point uses only the standard library. `python REPLICATE.py --help`
lists the routes. Source estimation still delegates to `START.R`/`RUN.R`.
The full source exercise and deferred36 are deliberately outside the current
execution decision. They are not silently started by package inspection.

Paper, slides, editable narrative, slide images and their private reconstruction
bundle are not distributed here. Their reviewed private copies remain with the
owner. This restriction does not remove the public statistical methods or data.

## Three distinct reproduction routes

On Windows, extract to a short directory name (for example `C:/LO47`) to avoid
legacy path-length limits in older ZIP extraction tools. Use a new empty output
directory; never extract over an existing result run.

1. **Dashboard from aggregates:** Python 3.12, standard library only:

   ```sh
   python REPLICATE.py dashboard --output rebuilt_dashboard
   python -m http.server 8769 --directory rebuilt_dashboard
   ```

   Open `http://localhost:8769/nl/` or `/en/`. The script checks package hashes,
   rebuilds figures and their exact missing-point reasons, and checks the original
   runtime manifest. Documentation and downloads are separate attachments.
   This route does not estimate statistics from pupil records.

2. **Inspect results:** `python REPLICATE.py inspect` verifies every package hash,
   the sealed result manifest, target status counts and the explicit current47
   filter. It calculates no statistics and prints a machine-readable receipt.

3. **Fresh estimates from official sources:** use the pinned Git checkout,
   `START.R`, `06_pipeline/RUN.R`, and the locked `renv.lock`.
   `02_analysis/scientific_dependencies/README.md` explains the public engine,
   source bindings and pinned external SES author code. The original private
   source ZIP is no longer required for this explicit fresh route. Obtain the
   official pupil files under OECD/IEA conditions; they are not redistributed.
   Calibration input countries do not automatically become output countries.

   The stages remain `fixed-audit` → `fixed-produce` → `fixed-finalize`.
   Set a new output root and `LO_FRESH_REPLICATION=1` for an independent run.
   Use `CURRENT_RELEASE47_RUN_CONFIG.json` for this phase. The separate
   `DEFERRED36_RUN_CONFIG.json` is for the later, user-initiated R run.

Evidence distinguishes these routes. Q01–Q08 have been reviewed on this result
basis. Genuine Windows source probes cover 58 cells in three studies, with
absolute estimate/SE differences below `1e-9` and exact N. Technical installation
and regression checks run on Windows and Linux. A new full 47-country source
replication without old result caches has **not** yet been certified. Neither
website operation nor aggregate reconstruction is represented as that full run.
Consult current completion receipts rather than historical dated counts.

## Country admission, comparisons and ranks

Admission requires at least three comparable waves per country/age/domain
combination. A country may qualify for some combinations only. Every figure
retains the complete focus-country year anchor and all jointly displayed groups
and learning environments. Reference membership is constant within the figure
and may differ between figures. The historical rich-country pool is unchanged;
no count of 19, 20, 34, 47 or 50 is forced.

Reference countries weigh equally and exclude the focus. Checkboxes select
eligible countries; an empty group stays empty. Ranks use the focus plus that
same group, average exact ties, and the direction in the figure contract. There
is no group-rank line; one additional country may share the same basis.
This release uses verified strict balance, not historical available cases.

## Definitions and uncertainty

International grade 4 is Dutch group 6; PISA concerns 15-year-olds. Repeated
cross sections do not identify individual cohorts or causal effects. Keep study
scales, books quartiles, chosen four-wave Cobreros SES and official IEA Home-SES
constructs separate. Appendix placement does not add dashboard controls.

Separate girls remain separate where observed. Only otherwise is girls + other
used, with its own label and definition break. Migration retains at least one
foreign-born parent, both parents foreign-born, and first/second generation
separately. Unknown birthplace is not native; third generation is not inferred.

The default-on uncertainty switch shows focus-country normal-approximation 95%
intervals, estimate ± 1.96 × certified SE. Gaps use joint-replication SEs.
Reference means and ranks receive no interval. Interval overlap is not a trend
test. The paper's three registered PISA trend tests include linking uncertainty
and Holm correction; no automatic broad testing series is added.

Core below-basic/high proportions and their SEs are multiplied by 100 only for
display. SES/peer percentages are not multiplied again. Research values retain
full precision; rounding is for presentation. Missing values remain missing,
never zero-filled or interpolated. A valid zero with adequate support remains
a result.

## Code, results and product map

| Location | Responsibility |
|---|---|
| `START.R`, `06_pipeline/RUN.R`, `LO_FIXED_CONTROLLER.R` | Entry point, configuration, stages and scope |
| `MASTER_ESTIMATION_GRID.R`, `LO_EXACT_DISPATCH.R`, `LO_EXACT_ESTIMATORS.R` | Approved exact-cell estimation and reuse |
| `LO_INTERNATIONAL_*.R`, `LO_*SOURCE*.R` | Source identity and country/wave bindings |
| `LO_REMOTE_CHECKPOINT.R`, `LO_ATOMIC_CHECKPOINT.R` | Recoverable blocks and atomic receipts |
| `LO_FINAL_GUIDED_EXPORT.R`, `LO_FINAL_GUIDED_DASHBOARD_BUILD.py` | Checked cells → bilingual dashboard |
| `05_publication/preview_overlay/` | Shared NL/EN selection, reference and rank logic |
| `04_results/review/all_required/` | Sealed aggregates and provenance |
| `replication/` | Three example configurations, resource evidence and route documentation |
| `06_pipeline/review_20261013/release47_20261020/` | Current/deferred scope and verification receipts |

An interrupted block may restart; certified completed blocks are reused only
when source/method/configuration fingerprints match. Changed inputs invalidate
affected dependencies. A zero compute queue alone does not prove completion.

Sources may remain locally. Private intermediate checkpoints belong on Drive;
public code, aggregates and dashboard files belong on GitHub. Paper/slides and their content remain private and are excluded from this package. A bounded local work
directory remains necessary during R execution. Credentials and pupil/school
microdata are excluded. Restore proofs and measured resource records are in the
phase dossier. Preserve unique sources and active locks.

Code is MIT; source data, brand assets and SIL OFL fonts retain their own terms.
See `LICENSE`, `DATA_LICENSE.md`, `CITATION.cff` and the source register.
This reproducibility package does not claim AEA certification.

## Configurations and resources

`replication/config/nld_only.json`, `nld_plus_19.json` and `all_required.json`
use the same controller schema. The second is a historical mode name, not a
promise of 19 eligible reference countries; the current phase excludes the
36 deferred countries. Within each figure, strict reference eligibility still
applies. Empty lists in other selection fields mean all approved values in
that dimension, not permission to add unapproved outcomes.

See `replication/RESOURCE_EVIDENCE.json`, `replication/ROUTES.md`, the result
README/dictionary and `06_pipeline/review_20261013/international/SOURCE_CATALOG.csv`.
The source catalogue records exact file hashes, populations and access evidence;
the separate home-source catalogue covers parent questionnaires. OECD/IEA data
access is under their terms, not the repository MIT licence. External author
code is pinned in `02_analysis/scientific_dependencies/README.md`.

Source estimates/SE retain binary-double research precision in the stored
aggregates. CSV decimal serialization and public JSON are distinct from display
rounding. Inspect numeric tolerances in the recorded source/platform proofs.
No full-run duration or peak memory is fabricated when it was not measured.
