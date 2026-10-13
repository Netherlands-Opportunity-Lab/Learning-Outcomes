# Definitief concept: één mastergrid voor alle PISA/PIRLS/TIMSS-schattingen

## Doel

Eén rij per unieke **primitive estimate** (land/systeem × survey × jaar × domein × exact sample × outcome × subgroup × construct × drempel × peeromgeving × definitie/methode). Resultaatafhankelijkheden zoals Q4−Q1, meisjes−jongens, P90−P10, 100−onder-basis en internationale gemiddelden komen in een **afgeleide laag**, niet als dubbel te berekenen leerlingstatistiek. De grid is het vooraf vastgelegde calculatiecontract; alle figuren/slides/dashboard/paper linken naar cell-ID's.

## Exacte velden

`cell_id, survey, country, year, age, domain, sample_id, population_id, subgroup_variable, subgroup_level, outcome_id, statistic, ses_construct_id, threshold_id, peer_environment, peer_target_group, peer_own_group, method_version, weight_design, pv_rule, variance_rule, linking_rule, n_unweighted, n_effective, estimate, standard_error, covariance_group_id, input_fingerprint, code_fingerprint, result_hash, archive_source, status, hold_reason`

Daarnaast noodzakelijk als aparte tabellen: `GRID_DERIVED_RELATIONSHIPS` met eindcel, onderliggende cell-IDs, contrastregel, gezamenlijk design/PV/replicate-covariantieobject; `GRID_FIGURE_DEPENDENCIES` voor figuur/sheet/dashboard/paper; `GRID_RESULT_VERSIONS` voor verschillende historische resultaatversies, oorsprong en wetenschappelijke validatie. Scorepunten mogen niet tussen PISA/PIRLS/TIMSS worden afgetrokken.

De historische 79.448 metric_keys zijn **broncontractposities**, niet automatisch 79.448 onafhankelijk te berekenen primitive estimates. De basisgrid wordt in `LO_START_ACTION=figure-minimum-plan` met deze 79.448 IDs opgebouwd, alle `estimate`, `standard_error` en `N` leeg. Actieve productbesluiten en toekomstige nieuwe lage-peer-items komen in aparte afgeleide/nieuwe-requirement-tabellen totdat exact gedefinieerd, en worden pas na crosswalk in de canonieke werkgrid verenigd. De nieuwe onder-basis-peers staan niet als schijnbaar reeds bestaande oude high-peer resultaten.

## Snellere R-verwerking

De efficiency komt vooral uit:
- éénmalige planning: niets buiten de vereiste grid berekenen;
- archief/SQLite/Parquet/LO01/LO02/V8/V9/V11 eerst met exacte `cell_id` én sample/methode/input/PV-fingerprints matchen;
- één data-/surveywave-opening per `survey×land×jaar×sample×source_edition×method_version`, daaruit in een **batch** alle benodigde vakken, subgroepen, percentielen en drempelshares berekenen;
- gezamenlijke replicate/PV-vectoren en contrast-covarianties binnen één batch opslaan zodat derived SEs niet apart dure microdata-runs vragen;
- per taak/pakket idempotent checkpoint met input-, code- en methodehash; herstart doet alleen echt ontbrekende cellen;
- na wetenschappelijke validatie resultaten in de grid plaatsen; geen automatisch geldig label voor oude kandidaten.

*Niet* sneller door uitsluitend veel gridrijen te maken: het is sneller door de batchplanner en identieke steekproeven/microdata-doorgangen te delen. Grote batches mogen niet de correcte BRR/JRR/PV-linking-berekening vervangen.

## Normatieve statuslevenscyclus

`TARGET_DEFINED` → `ARCHIVE_CANDIDATE_FOUND` → `ARCHIVE_PROVENANCE_PASS` / `DERIVABLE_WAIT_JOINT_VARIANCE` / `COMPUTE_REQUIRED_AFTER_METHOD_GATE` / `HOLD` → `CALCULATED_PENDING_VALIDATION` → `SCIENTIFICALLY_VALIDATED` → `PUBLISHED_RIGHTS_OK`.

De 40 nieuw berekende NL LO02-resultaten blijven `CALCULATED_PENDING_VALIDATION` totdat eerdere/huidige SQLite-versies exact op sample, spec, output en hashes zijn vergeleken; `run_id` ontbreekt in huidige results table.

## Presentatie

Gecombineerde gelijk gewogen referentiegroep: **alleen puntlijn, geen SE/CI/foutbalk**. Individuele landen/contrastpunten bewaren correcte SE en covariance metadata intern. Eén grafiekpaneel per dashboardsectie, geen stille dubbele as of facet. Hele-school versus directe leeromgeving strikt onderscheiden.

## Implementatiestatus 13 oktober 2026

`MASTER_ESTIMATION_GRID.R` definieert nu vast schema en fail-closed validatie voor het vullen uit bestaande archieven; `RUN.R` maakt bij de bestaande read-only `figure-minimum-plan` automatisch `PRIVATE_MASTER_ESTIMATION_GRID.csv`, uitsluitend op de lokale Windows-analyseomgeving. Alleen gezuiverde aggregaatrapporten komen op Google Drive via de bestaande allowlist; persoonlijke volledige cell-ID-rijen nooit op de publieke GitHub branch. Dit is fase 1: **nog geen gevalideerde archiefvulling**, dus het grid wordt niet onterecht als wetenschappelijk compleet gepresenteerd.

Volgende implementatiefase: concrete `GRID_DERIVED_RELATIONSHIPS`, `GRID_FIGURE_DEPENDENCIES`, en archiefhergebruik-adapters koppelen aan exacte outcome/sample/construction; vervolgens geteste gedeelde-wave batchproducer. Alle output via GitHub-code en private Google Drive, geen handmatige ZIPs en geen automatische verwijdering.

## Implementatie 13 oktober — archiefvulling en batchplanner

`GRID_ARCHIVE_BATCH.R` bevat nu (i) `lo_grid_mark_archive_candidates` die LO01/LO02 exact op metric_key herkent maar nooit estimates/SE/N invult; (ii) `lo_grid_archive_fill` die alleen onafhankelijk `SCIENTIFICALLY_VALIDATED` verklaarde, van 64-char source-/code-/result-hashes voorziene en exact op `cell_id + sample_id` passende statistische resultaten vult; (iii) `lo_grid_batch_plan` die uitsluitend voor expliciet `COMPUTE_REQUIRED_AFTER_METHOD_GATE` goedgekeurde cellen met compleet sample-/input-/methode-/weight-/PV-/variance-design één gezamenlijke berekenbatch vormt. De batchplanner executeert geen microdata-code: de methodespecifieke batchproducer volgt na survey-gates.

De bestaande GitHub-actie `figure-minimum-plan` maakt nu in één uitvoering:
- `PRIVATE_MASTER_ESTIMATION_GRID.csv` met de volledige 79.448 historische contract-IDs, `estimate`/`SE`/`N` ontbrekend tenzij exact gevalideerd;
- `GRID_DERIVED_RELATIONSHIPS.csv` voor contrasten/benchmarks; geen dubbele leerlingruns;
- `GRID_ARCHIVE_FILL_COUNTS.csv` en `GRID_BATCH_READY_COUNTS.csv`, veilige samenvattingen die naar private Google Drive kunnen;
- de eerder vastgelegde 138-figurenafdekking en nieuwe below-basic peervereisten.

Als lokaal reeds een onafhankelijk gevalideerde `master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv` met volledig bewijs bestaat, gebruikt de runner die read-only; ontbreekt ze, dan blijven de archiefkandidaten kandidaat en wordt er niets gefabriceerd. De private volledige metric-key-grid wordt niet naar publieke GitHub of Google Drive geëxporteerd onder de samenvattingsallowlist.

De volgende echte wetenschappelijke producerstap moet de precieze PV/replicate-methode en input-edities per survey met de batch-ID verbinden; geen algemene reken-release uit louter grid/queue-status.
