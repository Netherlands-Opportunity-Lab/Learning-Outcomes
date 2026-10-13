# CODEX COMPLETE HANDOFF — 13 October 2026

Read repository-root AGENTS.md and 06_pipeline/FROZEN_3_STAGE_PRODUCTION_PLAN_20261013.md before doing any work. These govern the project. Codex becomes the primary code developer and test runner; scientific production stays on the owner's Windows PC in RStudio. Cloud Codex does not get the restricted pupil-data archive.

Repository: https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes
Development branch: feat/reproducible-storage-and-cleanup-20261010
Draft PR: https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes/pull/5
Scientific execution issue: https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes/issues/6
Windows checkout folder: Downloads/Learning-Outcomes-Git-20261010
Pipeline entrypoint: START.R to 06_pipeline/RUN.R

Three fixed production stages and exact scopes:
(1) fixed-audit — complete grid plus LO01/LO02/V8/V9/V11/current/history SQLite/Parquet source/provenance evidence and minimum approved compute queue; no pupil computation.
(2) fixed-produce — only independently approved missing primitive cells through scientifically certified task-level input+method+PV/replicate batching, resumable; do not run all missing archive keys.
(3) fixed-finalize — scientific freeze/official anchors/Q01-Q08/rights/figures/21-slide policy deck/50-slide science deck/16-page note/paper and the actual 42-system bilingual guided dashboard.
Optional fixed-cleanup-plan — no deletion; independent off-C restorable backup, private Google Drive SHA-readback, product dependency closure and two distinct user approvals with >=30 days of quarantine.

Supported scopes: nld_only (1 system); nld_plus_19 (20); all_required (50 unique = COMMON42 dashboard countries plus eight other reference countries). Comparator equal country weights, fixed membership, exclude focus where in group, no shown combined benchmark CI. Do not confuse old full 91-system experimental route with the precise all_required 50.

Scientific source anchors: original 79,448 metric keys and 138 figure contracts, pinned SHA reviewed October v2 source ZIP, old 28 September frozen public release remains protected. The six country-position/rank figures are derived. New primary below-basic peer results are different from older high-achiever peer results and must prove correct PV/replicate uncertainty, source edition and self-excluded direct environment. SES below-basic is complement of validated at/above intermediate results; incomplete joint covariance remains HOLD. Q01–Q08 not yet demonstrated as passed.

Existing archive counts: LO01 16,767 unique keys, LO02 3,486, overlap 947, union 19,306; 60,142 keys not found in these TWO archives only, never a blanket instruction to calculate. New LO02 NLD core/gender run had 40 computed result candidates but lacked exact run_id field, export HOLD_NO_EXACT_RUN_LINK, 0 uniquely linked. Some LO01/LO02/V8/V9 historical tables have estimates/SE but missing unweighted pupil sample N. Do not fabricate N/SE, method approval, outcome values, paper or official source availability.

Actual live website: 05_publication/preview_overlay with .github/workflows/pages.yml (NL/EN 42 selected systems and four questions). 03_dashboard/app is older and must not be mistaken for the deployed guided frontend. New builder LO_FINAL_GUIDED_DASHBOARD_BUILD.py builds independent private candidate from pinned figure contracts; no live site is overwritten.

As of this handoff, code modules include LO_SCOPE_LOCK.R, MASTER_ESTIMATION_GRID.R, GRID_ARCHIVE_BATCH.R, LO_EXISTING_RESULT_REGISTRY.R, LO_FIXED_CONTROLLER.R, LO_FIXED_PRODUCERS.R, LO_FIXED_VALIDATION.R, LO_FIXED_COMPARATOR.R, LO_FINAL_GUIDED_EXPORT.R, LO_FINAL_GUIDED_DASHBOARD_BUILD.py, LO_FINAL_GUIDED_PUBLIC_RELEASE.py and LO_FIXED_CLEANUP_GATES.R. These are NOT proof of complete science. Prior HEAD aaca7e5039a429ef804f91eb3b8fc1027e1da645 passed ordinary repository-checks but failed the full Windows/Linux scientific workflow. Re-fetch current HEAD and CI. Work in feature branch, commit verified changes; do not merge or deploy without explicit release permission.

FIRST CODEX MISSION: inspect all scripts and tests, source bundle interfaces and the existing CI failure logs. Reproduce and fix all CI failures on Windows/Linux synthetic fixtures. Audit exact sample/source/method/target hash joins, 1/20/50 scopes, new low-peer input targets, O(1) resume/backups, startup/pull logic and legacy scientific code. Test whether the new frontend builder can render the exact real 42-system guided runtime and all source-derived 138 figure contracts, with honest PLACEHOLDER/UNAVAILABLE when data are unvalidated. Ensure the correct reviewed private intermediate grid and aggregate backups go to Google Drive with SHA readback. After CI is green, hand the owner ONE local RStudio fixed-audit instruction. Only then use real local scientific evidence to design per-module compute adapters, rerun full CI and certify fixed-produce. Finally run fixed-finalize and stage restricted/rights-reviewed output only after all scientific paper and dashboard checks pass.

Codex should use separate Git worktree or task branch for changes, never overwrite the source-data directories, never copy OECD/IEA microdata or secrets into cloud, and never delete local files automatically. State factual completion gates, code revisions, test links and one next action at end of each substantive task. Do not create new stage names or restart former next-batch diagnostic loops. The user prefers Dutch and minimum manual interventions.
