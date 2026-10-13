# AGENTS.md — Learning Outcomes / PISA-PIRLS-TIMSS

## Mission
Finish the reproducible, grid-first PISA/PIRLS/TIMSS scientific pipeline, its validated products and the active bilingual 42-system guided dashboard. Work through the existing three-stage execution plan; do not introduce a new series of ad-hoc runs. Do not claim the science or public release is complete until gates actually pass.

## Authoritative project records
Read in this order:
1. `06_pipeline/FROZEN_3_STAGE_PRODUCTION_PLAN_20261013.md`
2. `06_pipeline/MASTERPLAN_20261011_v2.md` (historical decisions/provenance)
3. `06_pipeline/MASTER_GRID_DESIGN_20261013.md`
4. `06_pipeline/SCIENCE_AUDIT_20261010.md` and `06_pipeline/MINIMUM_FIGURE_COMPUTATIONS_20261013.md`
5. `06_pipeline/RUN.R`, `START.R`, and all `06_pipeline/LO_*.R`, `06_pipeline/LO_*.py`, `06_pipeline/GRID_*.R`
6. `05_publication/preview_overlay/` and `.github/workflows/pages.yml` — actual deployed guided-dashboard frontend. Do not confuse with older `03_dashboard/app/`.

## Locked execution scopes
- `nld_only`: Netherlands (1)
- `nld_plus_19`: Netherlands and 19 fixed PPP comparator countries (20)
- `all_required`: union of COMMON42 dashboard systems and fixed comparison countries (50 unique systems), of which 42 are shown as dashboard choices.

Keep the fixed comparator country panel; equal country weights, omit focus if in panel; never show combined reference-line SE/CI. Individual country estimates retain design-based SE where appropriate.

## Locked task stages
The only default local Windows-RStudio actions are `fixed-audit`, `fixed-produce`, `fixed-finalize` with unchanged `LO_SCOPE` within an execution. `fixed-status` is read-only and `fixed-cleanup-plan` is separately optional. Do NOT run `next-batch`, broad legacy `execute` or fully international compute as shortcuts. Repair the scripts underlying the stages if their tests or scientific gates fail; resume rather than inventing a new protocol.

## Grid and scientific validity
- One canonical primitive cell per exact survey × country × wave × age/population × sample × outcome × subgroup × domain × SES/peer construct × method/input/variance edition; preserve immutable original source identity and SHA.
- Existing historical 79,448 metric keys and 138 figure contracts remain intact; 6 ranks are derived. The new BELOW-basic peer outcomes are additional cells and are NOT the historical high-peer estimates.
- Archive candidates in LO01/LO02/V8/V9/V11, SQLite/Parquet are not automatically validated. Require independently verified sample, N, estimate, SE, full source/code/input hashes, weights/PVs/replicate design, method/threshold definition and numerical parity before reuse/release.
- Keep gaps, complements, country ranks and benchmark point means as explicit derived dependencies; joint variance/covariance when required.
- PISA below level 2 and IEA below intermediate 475 are not interchangeable. Direct learning peers must be self-excluded, with whole-school robustness distinct; no causal peer-effect claims. Historical score trends must respect linking uncertainty and comparability rules.
- All Q01–Q08, science/source/sample/SE/privacy/rights/figure/deck/paper/dashboard gates must pass before any new scientific or public freeze.

## Computing and privacy
- Large pupil-data production runs remain on user's own Windows computer in RStudio; GitHub CI and Codex cloud use only synthetic, source-free fixtures.
- Never upload OECD/IEA restricted microdata, raw student/school rows, local personal paths, secrets or unvalidated bulk data to public GitHub. Private Google Drive `Learning-Outcomes-Private` stores reviewed intermediate aggregate reports/backups using SHA256 readback when allowed.
- Do not delete or move files from the user's C: disk automatically. Removal requires explicit user approval, complete product dependency closure, two independently restorable verified off-C backups, a >=30-day quarantine, fresh SHA checks and distinct final approval. Same-C moves do not free space.
- Do not overwrite the locked 28 September scientific publication or current GitHub Pages website. New public assets require reviewed rights, scientific SHA freeze and independent CI/browser QA.

## Engineering behavior
- Begin with repository-wide inventory and failing CI job logs, then reproduce and fix root cause. Prefer implementing entire connected changes and comprehensive synthetic/integration tests in one batch, not one script per chat message.
- Never label a plan as an implemented science producer. Current native LO02 v5 PISA core/gender lane is limited and must obey exact per-metric fingerprint selection; unsupported PISA/PIRLS/TIMSS modules remain explicit HOLD until fully certified.
- Maintain deterministic, resumable, idempotent stages, a single authoritative run ledger, and proof of progress. Do not repeat already SHA-proven checks.
- Before asking the user for any action, complete all possible repository modifications and both Linux/Windows CI. Ask for exactly one concrete local action only if it is necessary for data-only validation/production.
- Treat missing permissions, scientific evidence, credentials, or deployment approvals as HOLD. Never fabricate pass receipts, N, SE, charts or source-data availability.
- Report what changed, relevant commit/PR/check links, actual Windows/Linux test statuses, scientific blockers and exactly the next action.

## Branch ownership
Primary development branch at handoff: `feat/reproducible-storage-and-cleanup-20261010`; draft PR #5. GitHub issue #6 stores execution evidence. Commit every substantial change and do not merge into `main` or deploy without verified scientific/publication gates.
