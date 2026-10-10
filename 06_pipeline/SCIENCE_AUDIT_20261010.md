# October 2026 scientific reconstruction: verified facts and open gates

## Evidence inspected

Checked source archive: `LEARNING_OUTCOMES_INTEGRAAL_v2_20261010.zip`, SHA-256 `ceddf194ab3ad60bee5100450145f879aec17073b7567ed6127bf071eb6869dc`. Its embedded `MANIFEST_SHA256.csv` binds 56 members. The R-code producer `engine/BACKEND.R` has SHA-256 `6d0f91e562f3ed3d85f34761e98d148b8c222848cdd2542dc5557587e61e1aab`, matching the **pre-sanitisation executed-source fingerprint** documented for the September 28 freeze in the repository's `REPRODUCIBILITY.md`. This is **code-byte identity for that backend**, not a proof that the newly composed October runner has achieved a full scientific release.

Contract matrices in archive: `engine/TASKS.csv`, `FIGURE_SERIES_CONTRACT_20261002.csv`, `PRODUCT_FIGUUR_RESULTAAT.csv.gz`, `REFERENTIE_ASSEMBLAGE.csv.gz`, `PPP_COMPARATOR_MEMBERSHIP_v2.csv`, `OPEN_PAPER_REQUIREMENTS.csv`, and evidence LO02 / LO01 archived result files. This evidence is **not** a fresh Windows learner run.

## Audited contracts

| Contract | Number | Notes |
|---|---:|---|
| Task keys | 79,448 | All unique; each appears exactly once in the task-to-product map |
| Netherlands | 1,867 | 310 PIRLS, 957 PISA, 600 TIMSS |
| 19 foreign reference countries | 27,979 | 3,534 PIRLS, 18,045 PISA, 6,400 TIMSS |
| Other international | 49,602 | Separate user-authorized production mode |
| Figure contracts | 138 | 132 with direct task mapping; six international ranking figures are **derived** from validated country scores |
| User-leading policy deck | 21 slides | October 1 PowerPoint is authoritative; previous 13-slide kernel only a historical prototype |
| Paper Q01–Q08 | 8 open requirements | SES coverage, samples, exact Cobreros replication, reference/covariance, within-wave SES robustness, trend uncertainty |
| LO02 previous current results | 3,486 | All are `COMPUTED_PENDING_VALIDATION` and `NOT_RELEASED`; six are for NLD |
| LO01 historic evidence | 16,767 | All explicitly `UNVALIDATED` and `NOT_RELEASED` |

### Key scientific and product caveats

- The 138 figure contracts all have `comparison_default=OECD_HIGH_INCOME_FY2027`, while the October **production** comparator is 19 foreign members with `reference_id=OECD_PPP_GT_CZE_2024_RECONSTRUCTED`. This discrepancy must be explicitly adjudicated at *product assembly* rather than silently treating both definitions as equivalent. The 19 membership list is fixed by the user-approved October contract; exact World Bank PPP 2024 numeric source snapshot and revision/version are still needed for publication.
- The six `TR_POSITION_*` contracts must compute valid panel/ranking functions from released national inputs. They are **not** missing microdata estimation tasks.
- TIMSS 1995 is absent from the current 79,448-row task grid. Any inclusion requires a population/grade decision and separate new scientific tasks.
- The `ses_harmonized`, `migration_generation` and `migration_peer_exposure` module families do not have independently released direct adapters. The remaining non-core modules also require method/variance/official-anchoring checks. Candidate calculations are not publication-ready.
- The 21-slide user-leading deck uses school×class peers for PIRLS/TIMSS and school×programme peers for PISA. School-only results cannot silently replace them. Home assessment-language frequency is not automatically a Dutch/non-Dutch indicator.
- For PISA, national/year-specific published ESCS is not a substitute for the trend-comparable Cobreros SES definition. Q03/Q04 exact 34-/36-system replication and Q08 change uncertainty are open.
- The previous six Dutch LO02 rows are not evidence that the Netherlands 253 PISA core/gender scope cells are complete: the rest must be matched against older central records and actual inputs before calculating.
- `RESULT_PROVENANCE.sqlite` / immutable Parquet consolidation in the October v2 runner is a **provenance sidecar**. Its presence alone is not independent scientific equivalence, complete original-source migration, or a cold-replication PASS.
- Prevent destructive garbage collection until every published product's exact result-version dependencies are pinned, a second independent off-device restore passes, and clean-from-source reproduction has passed.

## Architecture and acceptance

One Git-root `06_pipeline/RUN.R` entry point. `BUNDLE_DISCOVERY.R` refuses unknown/mixed October sources, checks the immutable archive identity and each source manifest entry. `PRODUCT_SCOPE_GATE.R` enumerates all figure/slide/paper needs before running the existing scientific estimators. The October v2 bundle is retained locally as raw immutable source input. A `vendor` / `vendor-push` action archives only the producer R code in Git with **original** source SHA and a separate public, path-sanitized Git copy SHA. Any path sanitization must be tested for numerical equivalence before it becomes a certified reproduction method.

Scientific data and Cobreros / sample / design variance tests remain on the user's Windows computer, followed by 19-country production. The static dashboard release remains unchanged until its public manifest and numerical fidelity gate pass. This report is a historical audit and implementation record, **not** a statement that all estimates were produced.

## 10 October attachment reconciliation (supersedes 13-slide assumption)

The user's uploaded October 1 controlled PowerPoint contains **21 slides** and its SHA-256 and exact title/family list are pinned in `BR_POLICY_DECK_21_SOURCE_REGISTER_20261010.csv`. The scientific seminar PDF contains **50 slides**, and the final note contains **16 pages**. These are separate products; compare their source editions and limitations rather than merging them or overwriting the user's deck. See `PRODUCT_SOURCE_RECONCILIATION_20261010.md`. The September 28 note's final update reports completed cycle-specific PIRLS core-SE repairs and TIMSS 1995/2015 fixes, whereas older body pages still retain pre-repair holds. Those discrepancies are intentionally registered for source-lineage review. The 19-country OECD-PPP group is **not** a replacement for the 31-system absolute SES benchmark or the 42-system pool explicitly labelled on policy slide 2.
