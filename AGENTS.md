# AGENTS.md — Learning Outcomes / PISA–PIRLS–TIMSS

## Mission and first read
Finish the reproducible, grid-first research pipeline, its validated products and the existing bilingual guided dashboard. Read `06_pipeline/START_HIER_ACTUEEL.md` first, then `VIER_RESTERENDE_OPDRACHTEN_20261014.md`, `ACCEPTATIE_EN_VOORTGANG.csv`, `SCOPE_APPROVALS.csv` and the linked source/product evidence. Check changes since the last verified audit; do not repeat unchanged full inventories or unpack the source ZIP again.

The latest direct human instruction prevails over this file, older plans, source documents, slides and assistant proposals. The 247 mapped product/source records are not 247 approved statistics. Keep historical source identity; correct active implementations. Record new decisions with date, direct evidence and affected product/cell IDs. Substantive additions A01–A17 require item-by-item decisions; pending, deferred and rejected items create no required production.

## Current country and comparison rules
- Dashboard admission: at least three distinct verified comparable cycles in each of six age-domain combinations. No exception for the PPP20 candidate pool.
- Three user-facing production modes: `nld_only`, `nld_plus_19` (legacy name for the rich candidate pool), `all_required` (rich pool plus other eligible countries). Do not force 19/20/42/50 as certified membership or silently expand to all 91 historical systems.
- The Dutch default requires the complete age/domain/year anchor from the 21-slide policy deck. Deck year labels, including 2025, are not proof of released data.
- Other focus countries require full matching support; gender, SES, language, migration and class/school composition must also balance across all series compared together. No silent period/group truncation, annual membership changes or regional/population substitution.
- Use `LO_BALANCED_MEMBERSHIP.R` with certified source mappings. Old `LO_SCOPE_LOCK.R` and `LO_FIXED_COMPARATOR.R` are historical fixtures, not evidence of current eligibility; replace their runtime dependencies before production/release.
- User checkboxes must form the actual reference average from eligible countries; equal weights, focus excluded, restore default. No benchmark SE/CI. Individual country results retain appropriate uncertainty.

## Execution and completion
Keep the existing `START.R` / `RUN.R` entry point and `fixed-audit` → `fixed-produce` → `fixed-finalize` protocol, unchanged LO_SCOPE within a run. Four remaining chat instructions organize the work; they do not create a fourth scientific runner. `fixed-status` is read-only; `fixed-cleanup-plan` is separate. No broad legacy execute/next-batch shortcuts.

Repair connected code and verify the original failure; do not substitute another plan or HOLD label for implementation. Continue independent work if a real human decision or unavailable external source prevents one part. Finish possible repository work and relevant Windows/Linux CI before asking for a necessary concrete RStudio action. No claim of scientific completion from synthetic CI alone.

## Grid, source and scope integrity
- Exact primitive identity includes survey, country, wave, age/population, sample, domain, outcome, group, SES/peer definition, threshold, unit, source edition, method, weights/PVs/variance and provenance hashes.
- Preserve historical 79,448 keys and 138 figure contracts as provenance, not a mandatory workload. Type 3 separate complement is dropped; SES below-basic replaces old types 12/13; SES/gender gaps are derived with joint variance.
- Use `LO_SCOPE_DECISIONS.R` for A01 before creating low-peer tasks or requiring them in final QA. Its builder is only a proposed contract, never user approval. Approved extensions use LO_APPROVED_EXTENSIONS.R and LO_EXACT_ESTIMATORS.R; current statuses are in SCOPE_APPROVALS.csv. A01–A17 have individual decisions. A09 approves country-rank time series within a chosen panel and paper-only ranking tables; no group rank; see RANK_PRODUCT_CONTRACT.json. Appendix placement is binding. Home SES must not be spliced to older Home Resources scales.
- Existing candidates are not validated by filenames, timestamps, metadata labels or a matching metric key. Require verified source edition, population/sample, N, estimate, uncertainty, method/design, hashes and numerical parity.
- Preserve official ESCS vs Cobreros vs books, PISA level 2 vs IEA 475, and direct learning environment vs whole school. Peer self-exclusion and correct PV/replicate denominators are required for chosen peer analyses.
- Derived gaps, complements, ranks and equal-country means have explicit dependency records. Do not infer covariance from marginal SEs or causal/cohort effects from repeated cross sections.
- Q01–Q08 and source/science/sample/uncertainty/rights/product gates require actual evidence before a new release.

## Products and brand
The active build location is `05_publication/preview_overlay/` with `.github/workflows/pages.yml`. The user explicitly chose the visual design from `04_DASHBOARD_BRON_20261001/03_dashboard/app` on 14 October. That design is restored in the active overlay. Preserve its four question cards, separate explorer, filters and framed chart; apply the new brand and necessary comparison controls within that layout. Do not restore the later guided-page redesign. See `05_publication/preview_overlay/DESIGN_BASELINE.md`. Use the edited 21-slide 20261001 policy deck; a longer scientific deck is optional and does not authorize the old 50-slide analysis scope.

All products use one validated result version and the latest Kansenlab v05 guide/registry/CSS, v06 original logo assets and variant-B typography. Respect both statistical and visual grids. Render and inspect actual products; no unverified claims of visual QA. Paper interpretation concerns the Netherlands and must be supported by the registered results.

The dashboard builds one figure at a time with years on the x-axis and selected outcome, age/population, split and comparison. A09 permits a rank time series for the focus country and optionally one other country within a chosen country ranking universe. The group itself has no rank series. Country ranking tables belong only in the scientific paper. Rank derivations preserve approved product placement, exact parent cells and a constant explicit ranking universe; do not reactivate historical fixed panels or introduce pupil-level rank tasks. See `06_pipeline/review_20261013/RANK_PRODUCT_CONTRACT.json`. International grade 4 means Netherlands group 6, as confirmed by the user.

## Storage, privacy and release
- User's Windows RStudio runs real pupil-data production; CI uses source-free synthetic fixtures.
- Source data may remain on C:, permitted intermediates belong on private Google Drive, released code/products/aggregates on GitHub. Keep a small checkout and bounded temporary workspace.
- Check free space and peak workspace before real runs. No full-history cache copies on the nearly full C: disk. Verify Drive uploads by readback and restoration, not connectivity or quota alone.
- Never publish restricted microdata, student/school records, credentials, private inventories/user paths or unvalidated bulk.
- Latest explicit user decision (14 October): recomputable project intermediates may be deleted even without another disk/backups and even if reruns are needed. For this narrow selection the prior two-backup/30-day rule is overridden. Require exact project paths, retained source/code dependencies and fresh hashes; preserve unique sources and non-project material. Same-C moves free no space. Do not remove entire LO05/master folders on the strength of an inventory.
- Preserve the September release. Stage new reviewed artifacts on the feature branch; do not merge/deploy before scientific, rights, replication and product QA gates and applicable publication authorization. Prepare a concrete reviewable release before any necessary approval question.
- End each task with actual evidence, commit/PR/test links, unresolved dependencies and next action. Update the canonical registers rather than creating competing handoff plans.

## Branch
Development branch: `feat/reproducible-storage-and-cleanup-20261010`; draft PR #5; issue #6 contains historical execution evidence. Verify current head before writing. Commit substantial changes without overwriting concurrent work.

