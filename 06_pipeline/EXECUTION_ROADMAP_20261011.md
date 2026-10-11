# Integrated execution and cleanup roadmap — 2026-10-11

Controlling sources: 20261009_OVERDRACHT_LO.txt, DRIE_OPDRACHTEN.txt, project records, draft PR #5. This is not scientific release approval.

## Science first
1. User products: leading 21-slide policy deck, 50-slide seminar, 16-page note, 42 selectable dashboard systems (single plot pane), economics paper, appendix, Q01–Q08, full replication. 19 OECD/PPP reference countries are a first production priority only.
2. Reconcile canonical SQLite and current/history Parquet plus V8/V9/V11/LO02 result stores using metric_key, source/specification/code fingerprints and result hash; expose conflicting and incomplete lineage.
3. Product-driven metric-level REUSE/DERIVE/COMPUTE/HOLD with reasons; avoid full Cartesian product and unnecessary pupil reads.
4. Produce NL, required OECD19, then remaining dashboard/paper scope; checkpoint by survey/wave; validate PV, BRR/JRR, linking, geography, SES/Cobreros, panels and OECD/IEA anchors.
5. Freeze validated results, then deliver dashboard, figures, decks, paper and replication.

## Storage and safe local cleanup
- Inventoried 35,087 local files, 95.57 decimal GB. Only one small quota report has been verified through private Drive so far, not the research archive.
- Preserve original raw sources, producer code, product masters, current/historical registers and all decision/loss records.
- next-batch: one read-only science identity reconciliation, bounded 2-GiB exact duplicate SHA audit, conservative retirement and cleanup queue.
- Cloud migrate separately under provider rights and SHA readback; demonstrate independent second backup and restore.
- Only redundant derived files with exact duplicate SHA, verified cloud receipt, independently tested restore, complete product dependency closure and per-SHA approval enter quarantine.
- cleanup-stage atomically renames approved copies outside Downloads on same volume; verifies hashes, records ledger. cleanup-restore reverses.
- cleanup-finalize requires >=30 days, fresh matching receipts and explicit final SHA approval. No unrelated Downloads item is in scope.
- No qualifying candidates -> zero moves, without obstructing scientific production.

## Logging and status
- GitHub draft PR #5 captures code history and review, not all local RStudio runlogs, chat history, or private results.
- lo-run-status is a limited public-safe status branch; full private lineage and receipts remain in local/private stores.
- CI success is not Windows scientific or restore certification.

## One next local command
Sys.setenv(LO_START_ACTION="next-batch")
source(file.path(repo,"START.R"))

Do not repeat unchanged audits without evidence. Report completed work, count-backed outcomes, blockers and one next action.