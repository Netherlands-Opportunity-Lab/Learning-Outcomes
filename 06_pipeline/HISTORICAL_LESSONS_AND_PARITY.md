# Lessons and open parity gates from earlier R versions

This note records lessons supported by the historical scripts, user-supplied Windows run reports, and the original 28 September code lock. It is **not** a claim that every historical R function has already been equivalence-tested.

| Historical behavior or failure | Required October regression gate | Current status |
|---|---|---|
| Historical v8/v9/v11 result caches and central SQLite/Parquet may contain useful results | Search the whole known register and follow source-code identity before computing; do not equate CURRENT with VALIDATED | Partial: registries inventoried; science adjudication pending |
| Windows error 1224 opening memory-mapped Parquet | No outstanding mmap file handles; one writer; test rerun/restart | Windows production retest pending |
| Two same-named Dutch PISA RDS caches differing in bytes | Compare actual analysis-relevant columns and identifiers by survey/wave/module | Candidate detection implemented; release adjudication pending |
| Old national results absent when runner searches only fixed cache paths | Recursive, checkpointed cache discovery covering V11 and previous release directories | Discovery implemented; final input map pending |
| Misaligned table(phase, planning_action) vectors | Count after one keyed join; fail closed on mismatched keys | October LO05 regression implemented |
| PISA 2025 ESCS questionnaire change | Use a justified trend-comparable Cobreros construction where applicable; separate from OECD PPP comparator | Scientific reproduction pending |
| PIRLS/TIMSS weights, plausible values, and JRR/BRR | Preserve survey/year-specific uncertainty method and benchmark validation | Scientific release audit pending |
| PISA school-only peer fallback would conflate tracks | Keep programme/track and school units distinct; IEA class units separate | Scientific release audit pending |
| Same test language at home is not automatically Dutch identity | Keep instrument wording and exact coding, including multilingual systems | Scientific release audit pending |
| Alternate comparator should not rerun pupil estimates | Reassemble comparisons from frozen national results; fixed balanced members for trends | Contract exists, Windows equivalence pending |
| Repeated large source scans and rehashes caused costly plan runs | Content-addressed checkpoints, stable input fingerprints, indexed incremental sources | Storage core implemented, performance benchmark pending |
| Storage cleanup must not destroy reproducibility or Git history | Retire only after complete product pins, independent backup+restore and clean-from-source replication | Cleanup safety gate implemented, not enabled |

## Git audit coverage

Current repository inspected: official committed canonical R script in `02_analysis/current/`, historical RC1 normalisation/results/sorting scripts in `02_analysis/archive_or_superseded/`, source preprocessing archives in `01_data_download_preprocessing/`, repository manifests and release registers, and the new `06_pipeline/` branch.

The latest October LO05 package contains additional producer code (including V11/BACKEND and LO04/LO05 modules) that is not yet committed in full to this branch. Exact code SHA-256 history is not yet complete. The branch's `vendor` action exists to prepare that code for review; it does not publish raw data or guarantee scientific equivalence.

Before concluding the parity audit, compare each named producer's source hash, required input columns, estimator version, output schema, and representative results against the September lock and the historical returns. The corresponding project master task is tracked in issue #6.

## Operational boundary

- Code and reviewed metadata: GitHub.
- Restricted/full results: private cloud storage with independent second backup; direct reading from ChatGPT requires a separately authorized Drive connection.
- Historic source archives and frozen published releases: preserve until provider rights and full independent restoration are confirmed.
- Automatic cloud sync is **not** proof of scientific release.
- A GitHub CI pass is **not** a full Dutch Windows microdata production pass.
