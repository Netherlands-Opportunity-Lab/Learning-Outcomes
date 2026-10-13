# VAST DRIE-STAPPEN PRODUCTIEPROTOCOL — LEARNING OUTCOMES

Vastgesteld: 13 oktober 2026 · Status: `FROZEN_EXECUTION_PLAN_v1` · leidend boven eerdere losse `next-batch`-, `execute`-, `figure-minimum-plan`- en overdrachtsprompts voor nieuwe productie. Alleen aantoonbaar foutieve implementatie en controleerbare wetenschappelijke blokkades mogen worden hersteld; wijziging van scope/onderzoeksvraag vereist een expliciete nieuwe gebruikersbeslissing plus versie.

## Waarom dit protocol bestaat

Eerdere runs leverden steeds diagnoses op zonder gesloten wetenschappelijke keten. Het probleem is niet primair R-rekentijd, maar de **ontkoppeling van resultaatidentiteit, lokale cache, wetenschappelijke correctheid, figuureis, release en dashboard**. Daarom zijn dit voortaan één workflow met drie opeenvolgende uitvoeringscommando's per gebruikersgekozen scope, één ledger en verboden onbedoelde zijpaden. Een stap mag een gedetailleerde `HOLD` opleveren; hij mag nooit `PASS` veinzen.

## Definitieve scope

| Gebruikersscope | `LO_SCOPE` | Unieke landen/systemen | Inclusief |
|---|---|---:|---|
| Nederland | `nld_only` | 1 | NLD |
| Nederland plus vaste referentie | `nld_plus_19` | 20 | NLD + exact 19 buitenlandse referentielanden |
| Alle voor producten vereiste landen | `all_required` | 50 | COMMON42 (42 dashboardkeuzes) ∪ exact 19 buitenlandse referenties + NLD |

De 42 dashboardlanden zijn **geen** onderverzameling van de vergelijkingsgroep: 8 comparatorlanden ontbreken uit COMMON42 (AUT, BEL, CAN, CHE, GBR, ISL, KOR, LUX). Comparator = gelijke landenweging, vast panel per serie/jaar, focusland uit eigen lijn, geen SE/CI/foutbalk op samengestelde referentielijn. Landresultaten behouden design-SE's. De verouderde 91-landen FULL modus mag geen all50-rekenproxy zijn.

## Stap 1 van 3 — `fixed-audit`: één grid, volledige hergebruiksketen, minimale tekortlijst

Verplicht, ook bij later uit te voeren grotere scope, maar herhaalt bewijsgeldige eerdere checks niet.
1. Verifieer gepinde oktober-2026 bundel SHA en bron-manifest (56/56), originele 79.448 metric_keys, 138 figuureisen, 300 referentieseries, 21-slide bronregister, Q01–Q08.
2. Filter **uitsluitend** gekozen scope, fixeer land×survey×wave×vak×exacte populatie×sample×outcome×uitsplitsing×SES-construct×peerniveau×methode×variantie. Voeg aparte nieuwe below-basic-peer-uitkomsten toe; eerdere high-peer zijn andere resultaten, nooit ongemerkt hergebruiken.
3. Eén *mastergrid*: `cell_id, survey, country, year, sample_id, population_id, outcome_id, subgroup, method_version, threshold, PV/design/weights, N, estimate, SE, result/input/code hashes, status, bron`. De afgeleide gaps/rang/100%-complementen zijn aparte dependency nodes met joint PV/replicate covariance (waar relevant), niet automatisch nieuwe pupilreads.
4. Bekijk op identieke bron/samplespecificatie: LO01/LO02/V8/V9/V11, centrale current/history SQLite en Parquet, eigen recente Windows-snapshots. Vergelijk numerieke velden **met aanwezige** SE en N; hashverschil ≠ statistisch conflict; gelijke metric_key ≠ wetenschappelijk hergebruik. Onduidelijke lineage `HOLD`.
5. Vul bestaande uitkomsten uitsluitend na controle van broneditie, doelpopulatie, steekproef, gewichten, plausible values, definitie, code en numerieke parity; log provenance. Archiveer geen ingebeelde N's of CI's. De 40 nieuwe NL-LO02-resultaten zonder run_id blijven kandidaat tot exact snapshotverschil plus producentbewijs.
6. Productgedreven triage: `REUSE_VERIFIED`, `DERIVE`, `COMPUTE_REQUIRED` (alleen als ontbreken bewezen, methode getoetst), `UNAVAILABLE_REVIEW`, `HOLD_PROVENANCE`, `OPTIONAL`. Maak minimal compute batchplan op `survey×country×wave×sample×input fingerprint×method×design`.
7. Reproduceerbare ledger + SHA'd rapporten en veilige (geen microdata) samenvattingen automatisch op **private Google Drive**, zelfde configuratie gebruiken; netwerkstoring = `SYNC_PENDING` en volledig lokaal resultaat intact.

Exit: exact per-metric grid, numeraire keep/compute/derive/HOLD-tellingen, selectievolledigheid, bron/versiecontroledossier. Geen nieuwe leerlingberekeningen; geen local delete; geen wetenschappelijke of publieke release. Bij `HOLD` blijft dit dezelfde Stap 1 (script fixen, NIET een nieuwe stap 0 bedenken).

## Stap 2 van 3 — `fixed-produce`: álle aantoonbaar ontbrekende GOEDGEKEURDE cellen

1. Lees uitsluitend bevroren Stap-1 grid en taak-goedkeuringen; geen impliciete compute op basis van `NA`, een uitgekeerde archiefkandidaat of een ontbrekende filenaam.
2. Gebruik gecertificeerde, SHA-gepinde wetenschappelijke methodes; test specifieke survey/wave/data-editie, steekproeven, sampling weights, plausible values, replicate weights/Fay/BRR/JRR, scorekoppeling en peerzelfuitsluiting; keurt `Cobreros` trend-SES los van wave-specifieke ESCS.
3. Eerste gecertificeerde baan: LO02 V5 PISA core/gender NLD en OECD19, per exact task input/science-fingerprint reuse. Geen kandidaat-V11 achteraf als 'vrijgegeven' markeren.
4. Tweede baan: bestaande LO04/V11 adapters voor PIRLS/TIMSS, SES/migratie/taal/peers, **uitsluitend na** onafhankelijke per-module codeSHA-, Windows- en methodecertificaten; nieuwe bronversies/ontbrekende golf = explicit HOLD. Cobreros, speciale migratie- en nieuwe below-basic-peers blijven HOLD zonder afzonderlijke echte methodecertificatie. Batching: één canonieke bronopen per country×survey×wave en gezamenlijk geteste PV/replicates, checkpoint per metric_key.
5. Uitvoering is hervatbaar en idempotent, no double compute if identical original input/science hashes; sla schatting, correcte SE, N, covariance/PV state, CI waar verantwoord, broneditie, code/data SHA en geanonimiseerde softwareversie op.
6. Upload afgeronde toegestane tussenaggregaten + betrouwbare herstelkopieën naar private Drive met SHA readback; GitHub bevat enkel code en publiek-veilige statussen, **geen** microdata/ongevalideerde bulkresultaten.
7. Bij selectieve onmogelijkheid: method+land+golf+oorzaak in `HOLD`-ledger; uitsluitend die cellen niet produceren. Voortgaan met onafhankelijk uitvoerbare batches, geen batch van 60.142 missende archivekeys als één massarun.

Exit: alle haalbare gecertificeerde primitive cellen ingevuld, exacte reproduceerbare `HOLD` voor restant; alle actieve figuurafhankelijkheden en onzekerheden gecontroleerd. **Een succesvolle technische run is geen wetenschappelijke release**.

## Stap 3 van 3 — `fixed-finalize`: wetenschappelijke freeze → producten → website

1. Alle resultaten onafhankelijk wetenschappelijk controleren: officiële OECD/IEA benchmarks, correcte PV/replicate SE, trendlink-/covariantie, cohort-/SES-/migratie-/taal-/peerverschillen, Q01–Q08; pin per-cell bron/provenance/certificaat. `PASS`/documented `UNAVAILABLE` per noodzakelijk contract, niet enkel count.
2. Kies één wetenschappelijke SHA-frozen analysebasis. Geen stap3 bij ontbrekend wetenschappelijk bewijs. Historical Sep28 public release blijft beschermd.
3. Materieel opleveren: 21-slide gebruikersbeleidsdeck (leidend), 50-slide wetenschappelijk seminar, 16-pagina notitie, figurenpakket incl 138 historische contracten en nieuwe primary below-basic peer, paper en appendices, 42-system bilingual dashboard. Slides/figuren gebruiken exact dezelfde result IDs en bewezen covariance, geen losse cijfers.
4. Maak *werkelijke actieve* guided dashboard uit `05_publication/preview_overlay` (NIET alleen verouderde `03_dashboard/app`). Pinned `FIGURE_SERIES_CONTRACT_20261002.csv` → 132 actieve figuurpanelen (6 aparte redundante complementpanels vervallen), inclusief 12 peerpanelen met nieuwe below-basic-betekenis. Bereken onbekende waarden niet in browser. Voor elk (country,figure): `VALIDATED` of onafhankelijk gemotiveerd `UNAVAILABLE`; geen geheimzinnige lege grafieken.
5. NL/EN × 42 × trends/distribution/gaps/environment deeplinks; vaste vergelijkingspanels; gelijkgewogen benchmark zonder foutband; één paneel; bron- en methodedisclosures; toegankelijkheid, iPhone/mobiel, downloadbare getoonde aggregaten, full fingerprinted release-manifest en smoke op echte website.
6. Rechtenreview: OECD/IEA licenties. Alleen toelaatbare definitieve geaggregeerde cijfers/visualisaties/artifacten op **publiek GitHub**; bruto pupilgegevens en volledige restricted bulkmasters niet publiek, ook niet indirect via distributies. Publieke statussen/labels mogen geen ongereviewde schattingen bevatten.
7. Onafhankelijk certificeer per bronmanifest/site: `scientific_status`, `rights_status`, `Q01_Q08`, `all50_research_scope`, `dashboard42`, `slides21`, `replication`, `static_site_QA`, `peer_below_basic_definition`; alle `PASS`, SHA-pinned naar exacte nieuwe site en code. Nieuwe guided release wordt immutable op GitHub **feature branch** geënsceneerd; deployment uitsluitend na CI, review en merge naar gepinde main Pages-release. Oude site niet autonoom vervangen.
8. Archief/backup van data/code/manifests; hersteltests onafhankelijk uitvoeren. Audit van iedere figuur, bronnummer, paperclaim en slide tegen exact mastergrid.

Exit: wetenschappelijke freeze, complete uitkomsten/Productregisters en onafhankelijke reproducibility, sitesmoke en publicatiebewijs — of een concrete, blijvend traceerbare `HOLD` met exact ontbrekend contract.

## Afzonderlijk afgeschermde fase: C:-schijf

Is **GEEN vierde wetenschappelijke run**. `fixed-cleanup-plan` is uitsluitend review. De bestaande `LOCAL_CLEANUP_GATE.R`, `LOCAL_QUARANTINE.R` en `LO_FIXED_CLEANUP_GATES.R` beoordelen uitsluitend R-geproduceerde, aantoonbaar redundante bestanden onder geverifieerde projectroot. Originele leerlingbronnen, code, huidige/historische registers, figuur- en productmaster, persoonlijke downloads zijn uitgesloten. Vóór mogelijke quarantaine: actuele file-SHA, SHA-readback van private Google Drive backup, **tweede onafhankelijk buiten C: terugleesbare/restorable backup**, exacte productdependency-closure en persoonlijke per-SHA toestemming. Quarantaine >=30 dagen; expliciete tweede per-SHA goedkeuring voor definitief verwijderen. Verplaatsen binnen C: wint **0 bytes**. Geen automatische delete, ook niet na wetenschappelijke PASS; gebruiker kan deze fase uitstellen zonder wetenschappelijke productie stil te zetten.

## Beheersregels, uitdrukkelijk bevroren

- **Geen** nieuwe stapnamen, ad-hoc `next-batch`, script per onduidelijkheid, stille scope-uitbreiding, nieuwe klant-run om alleen te informeren, of herhaald produceren van reeds fingerprint-identieke resultaten.
- Alle methodische wijzigingen krijgen één los gedocumenteerde `FIX/BLOCKER` in stage-ledger met bron, reden, impacted IDs, wijziging hash en CI; run hervat vanaf juiste stap zonder startover.
- Geen aannames over resultaten op persoonlijke C: vanuit uitsluitend GitHub/Drive. Codesynthetische CI ≠ echte lokale wetenschappelijke validatie.
- Bestaande wetenschappelijke/geografische scope en bronrondes worden gehandhaafd. Alleen gebruiker kan de onderzoeksdoelen/scopes veranderen; bugs oplossen is toegestaan zonder hernieuwde goedkeuring.
- De drie **enige** reguliere RStudio-acties zijn `fixed-audit`, `fixed-produce`, `fixed-finalize`; `fixed-status` is een alleen-lezen voortgangsweergave, `fixed-cleanup-plan` is los en optioneel.
- **Publicatie of fysiek wissen** is high impact en mag uitsluitend na de hierboven exact omschreven SHA-receipts en expliciete rechten-/gebruikersautorisatie.

## De drie vaste RStudio-commando's (zelfde repo/scope; eenmaal per fase)

```r
repo <- file.path(Sys.getenv("USERPROFILE"),"Downloads","Learning-Outcomes-Git-20261010")
Sys.setenv(LO_REPO_ROOT=repo,LO_SCOPE="nld_only",LO_START_ACTION="fixed-audit")
source(file.path(repo,"START.R"),encoding="UTF-8")
```

```r
Sys.setenv(LO_START_ACTION="fixed-produce")
source(file.path(repo,"START.R"),encoding="UTF-8")
```

```r
Sys.setenv(LO_START_ACTION="fixed-finalize")
source(file.path(repo,"START.R"),encoding="UTF-8")
```

Zet vóór Stap 1 `LO_SCOPE="nld_plus_19"` of `LO_SCOPE="all_required"` voor de grotere scope; houd die exact gelijk in Stap 2 en 3. Niet eerst de brede run draaien om een klein NL-probleem te diagnosticeren. Elke volgende stap vereist het bijbehorende bewijs uit de vorige en mag bij een `HOLD` uitsluitend relevante code/gates herstellen, niet andere onderzoeksbeslissingen nemen.

## Scriptregister (alle uitvoeringen via `START.R` / `RUN.R`)

| Fase | Script | Verantwoordelijkheid |
|---|---|---|
| 1 | `LO_SCOPE_LOCK.R` | 1/20/50 controle, 42 dashboard, 19 vergelijkingslanden |
| 1 | `MINIMUM_FIGURE_QUEUE.R`, `MASTER_ESTIMATION_GRID.R`, `GRID_ARCHIVE_BATCH.R` | alle originele contracten, mastergrid, afgeleide statistieken en batchdifferentiatie |
| 1 | `LO_EXISTING_RESULT_REGISTRY.R`, `RESULT_EXACT_COMPARE.R`, `EXISTING_LO02_EXPORT.R` | LO01/LO02/V8/V9/V11/current/history exact-scientific reuse en cache snapshotparity (legacy onderdelen beperkt tot huidige bron/kolommen) |
| 2 | `LO_FIXED_PRODUCERS.R`, `V5_NLD_CORE_ONLY.R` | pinned native NLD/OECD19 PISA core/gender fingerprint productie |
| 2 | `LO04_EXTENDED_EXECUTION.R` (pinned bundle), methodcertificaten | PIRLS/TIMSS/SES/peers pas na independent tests en auditable source matches |
| 2 | `LO_FIXED_COMPARATOR.R` | vaste gelijke-landengewichten, focus uitgesloten, zonder benchmark SE |
| 3 | `LO_FIXED_VALIDATION.R` | full grid, Q01–Q08, nieuwe low peers, wetenschappelijke freeze |
| 3 | `LO_FINAL_GUIDED_EXPORT.R`, `LO_FINAL_GUIDED_DASHBOARD_BUILD.py` | echte 42-landen guided data/interface i.p.v. oude legacyapp |
| 3 | `LO_FINAL_GUIDED_PUBLIC_RELEASE.py` | SHA-pinned rechten/21 slides/science/github stage |
| apart | `LOCAL_CLEANUP_GATE.R`, `LO_FIXED_CLEANUP_GATES.R`, `LOCAL_QUARANTINE.R` | derde onafhankelijke restore, quarantine en deletion alleen opt-in |
| alle | `DRIVE_SYNC.R`, `GITHUB_STATUS.R`, `RUN.R` | private immutable SHA backups, zonder microdata, vaste runner en audit |

**Geldige status op 13 oktober:** technische code deels geïmplementeerd; PISA V5 core/gender native bekend; historische grafiekmaster en LO01/LO02 kandidaten bekend; *niet* alle andere modules wetenschappelijk gecertificeerd; definitieve gevalideerde 50-landen-grid/42-landen-dashboard/paper Q01–Q08 **niet** bereikt. Een script dat '0 errors' meldt is geen productvrijgave.
