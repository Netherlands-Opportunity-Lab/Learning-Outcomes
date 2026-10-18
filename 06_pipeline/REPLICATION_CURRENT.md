# Current replication entry point — 18 October 2026

**Latest temporary display override:** the user requests comparisons from available results while production finishes. `05_publication/REFERENCE_POLICY.json` and the builder's `--reference-policy` option enable `AVAILABLE_CASES_PROVISIONAL`. Each year/series has explicit actual contributors, exclusions and parent hashes. The latest UI decision connects adjacent available reference waves and puts the membership caveat below the figure; missing waves and construct changes still break the line. Ranks retain their point-specific basis and denominator, with line breaks on a changing basis. Comparison and focus uncertainty default on. This changes the interim website only. Scientific production and final full-support rules below remain intact. The public package carries the same policy and reproduces it exactly. Omit the temporary policy when rebuilding after complete results and final review.

**Current execution inventory:** [what to run after the existing R process finishes](RUN_COMPLETION_INVENTORY_20261018.md), including the 16:07 snapshot, remaining modules, tested repairs, and separate final scientific/product requirements. No second concurrent writer.

**Public dashboard snapshot, 18 October:** the user explicitly requests publication of checked results with visible gaps. The website replication package rebuilds those aggregate figures without pupil data; see [the package guide](../05_publication/REPLICATION_PACKAGE_README.md). This does not certify clean-room scientific replication, Q01–Q08, the paper or slides. The 18 October country-selection repair adds a publication adapter over the frozen certified export: `LO_DASHBOARD_COMPARABILITY.py` binds source/sample/method evidence, `LO_DASHBOARD_REFERENCE_EXPORT.R` uses the existing balanced-membership engine, and `LO_DASHBOARD_REFERENCE_VERIFY.py` independently verifies every exported option. A missing mapping or focus year still blocks that comparison. This publication snapshot does not mutate the running production master. The retained original source-bundle dependency is also still open. Historical counts and gender findings below retain their dates; the later approved Female / Other pooling decision is controlling.

This is an executable development pipeline, not a completed scientific replication release. Real production now covers independently verified Netherlands PISA, PIRLS and TIMSS cells across the complete 40-combination Dutch core-year anchor. The current count, result sizes and closure receipts are recorded in `review_20261013/STEP1_EXECUTION_EVIDENCE_20261014.json`. The broader approved scope still requires source/sample/method certification, reconciliation of older candidates, country approval and independent replication. See `START_HIER_ACTUEEL.md` and `ACCEPTATIE_EN_VOORTGANG.csv` for the current decisions. Do not infer readiness from a successful software test.


## Eén opdracht voor hervatten en eindcontrole — 18 oktober 2026

De lokale installatiehulp gebruikt nu `LO_PREPARED_FETCH.R`: expliciete
fetchdoelen maken ook in een single-branch-clone de vereiste `origin`-verwijzingen.
Dit herstelt de gemelde ontbrekende voorbereidingsbranch vóór de merge zonder
de opgeslagen Git-fetchconfiguratie, resultaatcommits of wetenschappelijke
berekeningen te veranderen. Hetzelfde hervatcommando blijft gelden. Zie
`review_20261013/MAINTENANCE_FETCH_REPAIR_20261018.json` voor fout, test en actuele
eindstand van de vorige run.

De bestaande `LO_START_ACTION=produce-approved` voert audit, productie,
finalize en status achtereenvolgens uit, met dezelfde codecommit en configuratie.
Daarna volgen private checkpoint, GitHub-aggregaatdepositie en rapportoverdracht.
Gebruik de bestaande lokale configuratiewrapper in RStudio; stel de optie
`lo.current.action` op `produce-approved` in. Start geen tweede schrijver naast
een actieve run. De checkout-lock wordt vóór iedere Git-update gecontroleerd.

Voor de tijdens de lopende productie apart geteste reparatie is lokaal
`RESUME_WITH_FINAL_CHECKS.R` voorbereid. Die installatiehulp controleert checkout-
en masterlock, haalt de vastgelegde geteste commit op, behoudt eventuele nieuwe
resultaatcommits, voegt de reparatie zonder force/reset samen op de bestaande
ontwikkelbranch en verifieert de GitHub-push. Pas daarna wordt de bestaande
configuratiewrapper aangeroepen. Een tweede uitvoering is getest en veilig.
Deze machinegebonden installatiehulp bevat geen schatter en verandert geen scope.

De werkvoorraad bestaat uit alle ontbrekende goedgekeurde cellen, inclusief
eerdere probleemblokken; er is geen handmatige startlandinstelling nodig.
Geldige bestaande certificaten en resultaten worden hergebruikt. De gedeeltelijke
blokreparatie bewaart aantoonbare afwezigheid per cel, zonder een lege noemer op
nul te zetten of vereiste PVs/replicaten weg te laten. `fixed-finalize` maakt de
balans-/rangafleidingen, private dashboardkandidaat en het eindrapport. Open
wetenschappelijke controles blijven open; het commando verleent geen publicatierecht.

Een Windows `REMOTE_CHECKPOINT_INDEX_ATOMIC_REPLACE` kan ontstaan doordat een
lezer tijdelijk het vervangen van de index of `.previous` blokkeert. De atomische
schrijver probeert zulke sharing/lock-fouten maximaal circa twintig seconden
opnieuw en bewaart de vorige index. Bij blijvende blokkade stopt hij veilig;
herhalen probeert eerst de overdracht opnieuw, zonder gecertificeerde schattingen
te herberekenen. Wis geen locks, index of mastergrid om dit te omzeilen.
Werkelijke tijdelijke en blijvende Windows-locks, hervatten en de volledige
fasevolgorde worden getest; zie `CHECKPOINT_RESUME_20261018.json` in de reviewmap.

## Verlopen Drive-aanmelding tijdens productie — 17 oktober 2026

`PRIVATE_DRIVE_REAUTH_REQUIRED` / `invalid_grant` betekent dat Google de bestaande
OAuth-aanmelding niet meer accepteert. Nieuwe berekeningen stoppen; afgesloten
lokale resultaten en het laatste bevestigde externe checkpoint blijven behouden.
Automatisch herproberen herstelt een ingetrokken aanmelding niet.

Gebruik de rclone-binary uit de bestaande private `drive.local.json` en voer in
een terminal `rclone config reconnect lo_private: --auto-confirm` uit (of gebruik
het volledige pad naar die binary). Bevestig in de browser **hetzelfde Google-account**
als voor de bestaande private projectmap. Deel geen tokens of wachtwoorden.
Dit wijzigt de aanmelding; het verwijdert geen bestanden en start geen analyses.
Zie de [officiële reconnect-documentatie](https://rclone.org/commands/rclone_config_reconnect/).

Herhaal daarna het bestaande RStudio-productiecommando. De internationale
producent draagt eerst het nog niet extern bevestigde blok over en controleert
de teruggelezen bytes; daarna gaat hij verder met ontbrekende berekeningen.
Verwijder het lokale mastergrid, de certificaten en `.remote_checkpoints` niet.
Een nieuwe aanmelding of geslaagde overdracht lost afzonderlijke
`INTERNATIONAL_REPAIR_REQUIRED`-meldingen niet op.

Bij de onderbreking van 17 oktober zijn 49.992 unieke gecertificeerde cellen
lokaal aangetroffen, waarvan 49.972 in de laatst bevestigde externe index.
De overige 20 betreffen PRT/TIMSS/2023. De lokale certificaathash is opnieuw
gecontroleerd. Zie [het herstelbewijs](review_20261013/DRIVE_INTERRUPTION_20261017.json)
voor de actuele herstelstatus. Dit zijn checkpointaantallen; het oude auditgrid
is pas na een nieuwe audit weer een actuele volledige productiestatus.

## Actueel besluit: gepoold geslacht en externe checkpoints — 15 oktober 2026

De gebruiker heeft nu expliciet besloten: **“pool meisjes met other in landen waar meisjes niet apart is.”** Dit vervangt de eerdere open constructkeuze. De exacte bronresolver blijft afzonderlijke meisjes herkennen; een aparte, brongecontroleerde productielaag gebruikt alleen bij ontbrekende afzonderlijke meisjes de officiële categorie `Female / Other`. Resultaten heten zichtbaar **Meisjes + other**, inclusief verschillen en SES-appendix. Hun metric-key en calculation-policy veranderen; bestaande exacte meisjesresultaten kunnen niet als deze nieuwe definitie worden hergebruikt. De code controleert bronlabels, waarnemingen, leerling-ID's en gewichten. Onbekend/non-response blijft ontbrekend; dit is geen imputatie van afzonderlijke meisjes.

De huidige broneditie vereist deze wijziging voor PISA 2025 in AUS, CAN, DEU, DNK, ESP, IRL, NLD en NZL: 24 doelen per land. Andere jaren/landen behouden hun geobserveerde definitie. De Nederlandse echte proef van alle 24 doelen komt overeen met onafhankelijke gewogen PV/replicatieberekeningen; de identieke tweede proef berekent niets opnieuw. Zie `review_20261013/POOLED_GENDER_EXECUTION_EVIDENCE.json`. De beschikbare groepsdefinitie kan over landen/jaren verschillen; toon die definitie bij de figuur en presenteer dit niet als een overal identiek afzonderlijk meisjesconstruct. Alle bestaande balansvoorwaarden blijven gelden.

De productiefase betekent lokale R-berekeningen op de computer van de gebruiker. De scripts roepen geen taalmodel aan. RStudio of Rscript kan dezelfde vastgelegde route zonder doorlopende chatbegeleiding uitvoeren. Codex-gebruik betreft begeleiding, codewerk en gelezen uitvoer; de lokale rekentijd is geen taalmodeltokenverbruik.

`LO_REMOTE_CHECKPOINT.R` bewaart afgesloten gecertificeerde blokken tijdens productie op de bestaande private Drive. Het pakket bevat resultaatwaarden, fingerprints, certificaten en gezamenlijke PV/replicatieaggregaten. De overdracht wordt teruggelezen en alle opgenomen bestanden worden werkelijk hersteld en gehasht. De index wordt pas daarna bijgewerkt; een mislukte overdracht stopt nieuwe productie en blijft hervatbaar zonder herberekening. De volgende run probeert het nog niet extern bevestigde blok opnieuw over te dragen. Canonieke leerlingbestanden en andere binaire bronafhankelijkheden worden alleen met hun bronhash geregistreerd en blijven lokaal beschikbaar/herbouwbaar; dit is geen volledige back-up van alle bronnen. Alleen minimale lokale werk- en hervatbestanden zijn tijdens rekenen nodig. GitHub krijgt de gecertificeerde openbare aggregaten na een begrensde run, zodat de uitvoeringscommit gedurende rekenen vast blijft.

**VS-bronbesluit:** NCES vermeldt dat de ouder-/thuisvragenlijst niet is afgenomen bij [TIMSS 2023](https://nces.ed.gov/timss/technotes-2023.asp), [PIRLS 2021](https://nces.ed.gov/surveys/pirls/pirls2021/technotes.asp) en [PISA 2025](https://nces.ed.gov/surveys/pisa/pisa2025/technical-notes/index.asp). Een national add-on of restricted-use bestand kan niet-verzamelde antwoorden niet herstellen. Officiële Home-SES blijft voor die IEA-cellen expliciet onbeschikbaar. Studentantwoorden en de gekozen boeken-SES zijn afzonderlijke bronnen/constructen. Bij PISA 2025 beschrijft NCES bovendien meer dan 40% niet-afgenomen studentvragenlijsten; die dekking blijft een afzonderlijke kwaliteitsvoorwaarde voor Amerikaanse subgroepen.

Onderstaande aantallen en opmerkingen over een nog ontbrekend poolingbesluit zijn historische uitvoeringsmomenten. Ze zijn geen actuele afwijzing van dit nieuwe gebruikersbesluit. Volledige internationale productie en productvrijgave blijven afzonderlijk te bewijzen.

## One configuration, three existing stages

The ordinary `START.R` action `produce-approved` now fast-forwards the reviewed branch once, freezes one code commit across audit/produce/finalize/status, then deposits the certified aggregate review snapshot and sanitized provenance on that same GitHub branch. It never force-pushes or deploys Pages. Explicit `LO_REPRODUCE_COMMIT` keeps historical reproduction immutable. See [the result-deposit contract and measured runtime](review_20261013/GITHUB_RESULTS_AND_RUNTIME_20261015.md). `GITHUB_RESULTS_VERIFIED` confirms remote branch identity; `GITHUB_RESULTS_PENDING` means local results are safe but the upload has not completed. `LO_GITHUB_RESULTS=off` explicitly opts out of the deposit.

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

After reviewing `GRID_AUDIT_SUMMARY.csv`, `PRIVATE_MASTER_GRID.csv` and `PRIVATE_BATCH_PLAN.csv`, use the same configuration with `LO_START_ACTION="fixed-produce"`. Repeat that bounded action to resume remaining approved blocks. Use `fixed-finalize` for reviewed private products. `fixed-status` is read-only: it shows recorded target/validated/unavailable/remaining counts and the latest stage entries, while preserving the complete history. It detects a changed configuration or saved-grid hash and explicitly distinguishes an empty certified queue from completed science. It does not freshly certify source evidence. There are no hidden interactive menus and no automatic broad production, deletion or public deployment. The run fails if an explicit `LO_SCOPE` disagrees with the JSON.

`START.R` normally fast-forwards the development branch. For immutable reproduction set `LO_REPRODUCE_COMMIT` to the full recorded 40-character commit SHA in a separate checkout already at that commit. This disables the pull, requires unchanged tracked code and checks the exact R/package versions against `renv.lock`. Restore that environment with `renv::restore(prompt=FALSE)` before running. The lock records R 4.6.1 and 41 packages; clean restoration and exact-version checks have passed on Windows and Linux. Do not alter the environment of an active RStudio analysis.

The retained scientific source bundle remains an explicit external dependency. Its statistical files are fingerprinted. A clean end-to-end run from original sources and a fully portable release still require consolidation of that bundle and source access documentation. The existing original ZIP must be retained until those dependencies are replaced. A clean dependency-install test is not a complete scientific replication.

## Result identity, reuse and uncertainty

Each result carries its exact cell identity, source/input fingerprint, producer fingerprint, method, estimate, standard error and N. For low/high achievement peer targets, target membership can vary by plausible value: the scalar N explicitly describes the invariant analytic peer frame, while `PV_TARGET_SAMPLE_COUNTS.csv` records every exact target N separately. Its hash is bound to the source and method certificate, checked independently and included in export metadata; it must not be described as a fixed latent-group sample size. Source/method certificates preserve sample, weights, plausible values and variance definitions. `execution_receipts` ties an exact scientific execution to its numerical result hash. Result rows and receipts are committed in the same SQLite transaction; interruption cannot leave a falsely reusable partial result. A real R process has been forcibly terminated both during its next estimate and inside an uncommitted SQLite transaction on Windows and Linux. In both cases, the committed first cell survives, the incomplete second cell is recalculated, and a third identical run calculates nothing. Kernel-owned `filelock` locks release on process termination/reboot; their persistent `.lck` files are not stale locks and must not be deleted. Ambiguous legacy sentinel locks fail explicitly rather than unlocking a possibly active writer. Recovery verifies completed receipts independently and closes those cells before resuming only genuinely missing cells. Reuse checks the receipt, current result content, certificate, code and source bytes; a filename or an old `VALIDATED` label is insufficient.

`FIXED_INPUT_MANIFEST.json` freezes the selected configuration, target grid and input/scope/product hashes. Changing these requires a new audit. A durable run record is written before the first calculation, so a hard process kill cannot erase the configuration/code provenance. `RUN_RECORDS/*.json` preserves the configuration itself, input manifest, code hashes, Git commit when available, package/R versions, session information, output hashes and the selected result-version hashes. These records are private because they can contain source paths. Hashes identify versions; they do not independently certify scientific validity.

`COMPACT_MASTER_GRID.sqlite` holds one current row per cell plus each distinct successful numerical version once in `result_versions`. Exact reruns do not add duplicate numerical versions. No full checkpoint database is copied after each block. The old numerical version is retained before a replacement. Only exact approved cells are scheduled; derived gaps/ranks/reference means use certified parent results and do not automatically create pupil tasks. Necessary joint replicate/covariance information still needs to be retained for the approved derived claims; marginal standard errors alone are not enough. The full derived-result release is not yet certified.

## Precision and size

Scientific numbers remain native 64-bit floating-point values in SQLite. The interoperable `COMPACT_MASTER_GRID.csv.gz` uses 17 significant digits for round-trip precision, not 17 decimal places. Rounding a double saves no space in the database. Gzip compresses repeated metadata without losing precision.

`COMPACT_DASHBOARD_ROUNDED.csv.gz` is a separate presentation export: score/percentage estimates use one decimal, standard errors two, counts remain integers. Proportions are converted to percent and relabelled. It is never an input to ranks, gaps, uncertainty calculations or scientific verification. A future fractional-tie rank must not be forced to an integer without its documented rule. Both compact exports currently contain candidate results and are private until the scientific/publication gates pass.

The audit measures actual files in `RESULT_STORAGE_SIZE.csv`; the dated public evidence summary records those byte counts. The Netherlands target has 2,678 primitive cells, including separately approved PISA extensions that an earlier 2,526-row audit omitted. Unavailable constructs stay in that grid with source evidence. The numerical database, compressed scientific table, display table and joint PV/replicate evidence are measured separately. The eventual multi-country size depends on the approved eligible countries and retained covariance; it is not extrapolated from a mostly empty grid.

## Storage and deletion

Necessary original source bytes may stay on C:. Allowed intermediates use private Drive; eligible final code/results go to GitHub. Each production block requires a measured resource budget and at least 2 GiB operating reserve on both output and temporary volumes. Measured pilots now cover modern PISA, older PISA, IEA core/variance, IEA books and both peer source families. Their measured peak, pupil/PV/replicate limits and 64 MiB scratch budgets bind each certified batch. The space gate preserves 2 GiB reserve; it is not an operating-system disk quota.

The user's 14 October permission allows removing unnecessary RStudio/ChatGPT/Codex-generated project files, including recomputable intermediates. Creation by these tools alone does not establish that a file is unnecessary. Use an exact reviewed path selection, verify retained source/code dependencies and hashes immediately before deletion, and save a private receipt. Preserve necessary sources, unique results/evidence and unrelated material. Targeted removal and hash-verified NTFS deduplication have freed 26,008,379,325 physical bytes. Hardlinked source paths are preserved and immutable: modifying an alias modifies the shared bytes. On 15 October, 367 reviewed recomputable foreign-country PISA caches were removed (9,532,709,229 bytes); the observed C: free space immediately afterwards was 20,501,639,168 bytes. All original source files, NLD canonical inputs and unique result/evidence files were retained. No blanket deletion of the LO05/master folders. Unknown content inside a misleadingly named archive is not disposable project output. Cleanup remains an explicit operation, not a side effect of running analyses.

## FAIR and release requirements

This package aims at the [FAIR principles](https://www.gofair.foundation/fair-principles) and follows the [AEA preparation guidance](https://aeadataeditor.github.io/aea-de-guidance/preparing-replication-package.html). Completion requires a permanent version identifier, searchable metadata, source access instructions and editions, a data dictionary, licenses, declared computational requirements, all necessary code/dependencies, a product-to-result map and successful independent execution. See `../DATA_LICENSE.md` for the current publication boundary. Restricted sources need not become public to document their provenance/access route.

Still outstanding: exact required covariance/derived paper products; complete eligible international results and comparison mappings; complete scientific bundle portability; clean reproduction from original sources without hidden Downloads dependencies; final rights/QA review and durable release. All other selected NLD primitive targets have numerical certification or specific evidence of source unavailability. The verified source blocks and green Windows/Linux checks do not by themselves grant publication or AEA-level external verification.

## Corrected PISA 2025 gender source finding

The current NLD PUF has 6,636 rows and ST004D01T=99 throughout. This does not mean that all gender data are unavailable: MALE=1 identifies 3,397 boys, whose three domain means and standard errors independently match the published OECD tables to the tables' rounding precision. Those three exact cells are now certified. MALE=0 means Female / Other, not girls; it fails parity against the published girls. The official recode uses ST004D01D, absent from the local PUF edition. Twenty-four exact girl-dependent targets therefore remain a source-mapping review, not certified absence. Eighteen boy-by-SES targets are now independently certified using the chosen four-wave Cobreros calibration. Never shorten comparison years or silently label Female / Other as girls. The later explicit pooling decision authorises the visibly distinct pooled construct; it resolves the 24 targets without claiming an uncollapsed girls field. See the dated source register and gender correction evidence.

## Chosen SES calibration, checked 15 October

`LO_COBREROS_PREPARE.R` prepares only the selected four-wave, 13-item R protocol from the unchanged author commit `1da4b26097e84e732973af672355a1c3103d5d33`. Calibration uses 1,079,563 records in the author 34-country panel; it does not authorize foreign-country grid production. Each wave extract was checked against the original fields and exact source pupil set. The fitted model converged in 22 iterations and parameter differences from the author values are below 1e-10. The public preparation adapter reproduced exactly the independently prepared NLD scores; its second identical run preserved the existing output.

The 246 newly certified NLD results include SES levels/tails/gaps, the approved SES-by-gender appendix, school SES variance, SES peers and national composition baselines. A measured 48-cell pilot was reused; 198 remaining cells were calculated once, and a second identical production reused all 198. Standard errors are conditional on the fitted SES construct and do not claim to propagate the international calibration model's estimation uncertainty. Actual classroom effects and global paper/release gates are not certified by this comparison.

The final export contains 1,893 dashboard-context rows and 480 separately placed appendix/science rows, with zero mapping omissions. The historical figure-contract prose for 2025 is resolved explicitly to the chosen four-wave SES years. National SES shares are labelled composition baselines, not peer exposure. No numerical estimate was changed by this mapping repair.


## International production and explicit source bindings

The direct instruction of 15 October authorizes every country satisfying the existing source and 6x3 rules. `all_required` currently selects 34 source-eligible countries and 77,611 exact approved targets. This is neither a fixed country count nor a claim that those targets are all available or calculated. `EXECUTION_PROGRESS.json` and the live private grid distinguish completed certificates from remaining work. The same START.R action runs audit, production, status, aggregate GitHub deposit and private Drive verification; it does not deploy the dashboard.

Modern PISA is partitioned once using exact source country identifiers; legacy text files use immutable byte indexes. Every completed source/family block records its canonical source, exact selected tasks, independent estimates and joint PV/replicate matrices, producer outputs, measurement and scientific certificate. The master registry is atomically replaced after validation. A resumed run skips certified cells and reuses matching unfinished producer checkpoints. A whole-family independent reference interrupted before its checkpoint is recomputed; no uncommitted value is called validated.

The explicit public `review_20261013/international/SOURCE_CATALOG.csv` and `HOME_SOURCE_CATALOG.csv` pin original source/control hashes without exposing local paths. A private CSV with columns `sha256,path`, supplied as `LO_SOURCE_BINDINGS`, lets the existing audit build a missing international source manifest and country indexes through `LO_SOURCE_BINDINGS.R`. It resolves only named hashes; it does not search a Downloads folder or select a different edition. Existing runs keep their pinned path contracts; relocation uses a fresh output root. This portable international binding supplements the existing NLD and author-calibration preparation, whose clean end-to-end reconstruction remains a separate acceptance requirement. An unbound home file is not proof that a questionnaire was not administered.

Reference checks use matrix-weighted means and reuse sorted outcomes for exactly the selected quantiles. Source labels for school/class identities are converted once. The original definitions, thresholds, full PV/replicate arrays and uncertainty formulas remain unchanged; real PIRLS, TIMSS and PISA parity is recorded in `review_20261013/international/EXECUTION_PROGRESS.json`. Estimates retain full precision. No extra statistic is selected by this acceleration.

Reference membership is now evaluated per complete joint figure in `LO_BALANCED_VIEWS.R`, always retaining the full focus core anchor and every selected group/year. An unrelated appendix does not constrain a main figure. An unresolved focus group blocks its view explicitly; it never produces a shorter or girl-only comparison panel. This adapter still requires real comparability contracts before it can export international reference values; synthetic tests do not grant that certification.

## Partial blocks and end checks, 18 October

`LO_ESTIMATION_AVAILABILITY.R` checks each requested conditional denominator in all required PVs and replicates before reference/producer dispatch. An empty requested subgroup is registered as `UNAVAILABLE_VERIFIED_ANALYTIC_SAMPLE`, with exact task contracts and immutable source/code/diagnostic evidence. It stays in the target grid and cannot satisfy a balanced comparison. Valid zero results remain estimable. Invalid source columns, weights or codes remain errors. An absent unrelated migration generation no longer blocks a selected observed group. Real-source parity for 304 previously blocked cells and idempotent second runs is recorded in `review_20261013/PROBLEM_BLOCK_REPAIR_20261018.json`; these isolated tests do not certify new live results.

The existing remote checkpoint now includes changed absence registries and their evidence, even when no numerical value changed. Binary pupil-source dependencies remain local and hash-bound. The new preflight runs inside `fixed-finalize`, reporting remaining exact targets, remote coverage and verified absences from a stable read-only snapshot. Do not equate an empty compute queue or a preflight count with scientific approval.

Paper gates use `review_20261013/PAPER_QA_CURRENT.json`. A reviewed PASS row must contain `evidence_path` and `evidence_sha256`. Its JSON receipt needs `status`, `requirement_id`, `assessment`, `target_sha256`, `approval_sha256`, `policy_sha256` and a nonempty `evidence_files` table (`path`, `sha256`). Target hashing uses the sorted `cell_id,target_contract_sha256` table with reset row names; the result hash is the exact approved CSV hash, and the policy hash is `digest(policy$requirements, algo='sha256')`. All attached files are checked. Changed targets, results, policy or evidence require a new assessment. Historical Q03/Q04 country counts, Q06 benchmark intervals and Q07 extra PISA-SES analyses do not expand current approved production; see the explicit current criteria.

While the long run is active, preparation remains on `codex/problem-blocks-final-checks-20261018`. After its result deposit, integrate that branch into the existing development branch/PR #5 without overwriting results. The next ordinary `produce-approved` invocation uses the repaired existing pipeline. No second concurrent production run, manual editing of missing values, or new downloads are required for these verified repairs.

## Performance and concurrent starts, 15 October

The reviewed configuration now selects all_required without dimension filters. The second performance review preserves every PV and replicate, uses bounded weight matrices and verifies immutable source evidence before checkpoint reuse. START.R acquires a kernel lock before any Git update; fixed-status never pulls. Do not delete persistent lock files. See [measured timings and acceptance](review_20261013/PERFORMANCE_REVIEW_20261015.md). The remaining gender source decision is documented in [the raw-data examples and access review](review_20261013/PISA2025_GENDER_REVIEW.md); neither IDB Analyzer nor NCES US data provides a verified Dutch female field.

Uitvoering pooling: alle 24 Nederlandse nieuwe cellen zijn via de bestaande certificeringsbibliotheek geregistreerd. De nationale audit telt 2397 gecertificeerde cellen en 281 onderbouwde bronafwezigheden; geen overige open primitieve doelen. De hervatcontrole produceerde nul nieuwe berekeningen. Alle 3434 tot dan gecertificeerde nationale/internationale cellen zijn naar private Drive overgebracht met herstelcontrole. Paper-, balans- en productvrijgave blijven afzonderlijk. Ook code-, instellingen- en runregistraties worden incrementeel extern bewaard, inclusief een laatste checkpoint na afloop van START.R. De uitvoeringsstatus is geen claim dat alle internationale landen of dashboardproducten klaar zijn.
