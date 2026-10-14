# PISA/PIRLS/TIMSS — integraal masterplan en besluitregister

> **Historical plan — superseded for execution on 14 October 2026.** Read [START_HIER_ACTUEEL.md](START_HIER_ACTUEEL.md) and the four assignments first. This text remains provenance, not a separate next-action list. Fixed 42/50 output counts, mandatory low peers, automatic scientific-deck expansion and older publish/next-batch instructions no longer govern new production. The three R phase names remain in the updated frozen protocol.

Versie 2.0 — 11 oktober 2026. Status: leidend **uitvoeringsplan**, geen wetenschappelijke resultaatvrijgave. Project: Learning Outcomes. Dit document bundelt de oudere afspraken en het actuele bewijs. Nieuwe expliciete gebruikersbesluiten hebben voorrang boven oudere technische prototypes; de numerieke freeze van 28 september 2026 blijft onaangetast totdat een nieuwe freeze alle controles doorstaat.

## 1. Bestuursbesluit: weg uit de auditlus

We stoppen met losse inventarisaties en herhaald uitvoeren van `next-batch`. Er is een vaste volgorde: **(A) gecontroleerde, productgedreven productie en hergebruik; (B) wetenschappelijke beoordeling en één resultatenbasis; (C) eindproducten plus volledige replicatie.** Veilige opslagmigratie en lokale opruiming lopen parallel, niet als algemene stop op de wetenschap.

Elke toekomstige run heeft een inhoudelijk resultaat, een blijvende log, een ondubbelzinnig stop-/doorgaanbesluit en één vervolgactie. `PASS` bij code of opslag staat nooit gelijk aan `VALIDATED` bij wetenschap of `RELEASED` bij een product. De gebruiker voert zo mogelijk alleen het ene GitHub-gestuurde `START.R`-commando uit; terugkerende handmatige downloads, losse scripts en standaard nieuwe uploads worden vermeden. Er draait nooit meer dan één schrijvende productierun.

### Bewijshiërarchie

1. Concrete Windows-retour/console plus outputmanifest en exacte bytes/hashes.
2. Actuele, read-only onderzochte privéregisters en wetenschappelijke broncode met vastgelegde SHA-256.
3. Bestaande schriftelijke besluiten, productcontracten en wijzigings-/lossregisters.
4. Historische overdrachten en oudere chats, met een expliciet versievoorbehoud.
5. Technische aannames of productbeschrijvingen, nooit als empirisch bewezen presenteren.

## 2. Gecontroleerde stand van zaken op 11 oktober

| Component | Bewijs | Betekenis / grens |
|---|---|---|
| Oktober-v2-bronbundel | SHA-256 `ceddf194ab3ad60bee5100450145f879aec17073b7567ed6127bf071eb6869dc`, manifest 56/56; private Drive-kopie beschikbaar | Exacte wetenschappelijke codeversie, geen wetenschappelijke vrijgave |
| Windows productplanning | 29.846 geselecteerde contracten: 1.867 NL, 27.979 buitenlandse 19; `plan_only` geslaagd | Aanwezigheid van contract ≠ werkelijk te berekenen taak |
| Contractmatrix totaal | 79.448 unieke metric_keys; overige internationale scope 49.602 | Geen stilzwijgende beperking tot NL+19 |
| Centrale SQLite-resultatenreconciliatie | 538.398 bekeken registerrijen, 55.915 wetenschappelijke identiteiten; 52.008 identiteiten met overeenkomstige hashes en 3.907 met hashverschillen | Duplicaten van historische snapshots komen vaker voor; dit is niet het aantal nieuwe resultaten |
| Numerieke vergelijking van conflicten | Bestaand privérapport meldt **0 afwijkende combinaties van schatting en SE**, **0 multiple-current numeric conflicts** | Verificatie van daadwerkelijk aanwezige numerieke velden en CI/sample/methode is nog nodig; NA/NA mag nooit als numerieke gelijkheid tellen |
| Huidige contracttriage vóór nieuwste correctie | 15.977 bestaande kandidaten, 1.757 contracten met hashconflict, 61.714 zonder gematchte canonieke identiteit | Laatste categorie is NIET bewezen ontbrekend: LO01, LO02, V8/V9/V11 en Parquet moeten worden meegewogen |
| LO02 bewaarde batch | 3.486 resultaten, allemaal `COMPUTED_PENDING_VALIDATION` en `NOT_RELEASED`; zes NL | Native V5 hergebruikt exact identieke science-/inputfingerprints uit eigen live register |
| LO01 historisch | 16.767 unieke taakkeys, allemaal `UNVALIDATED`; 947 overlappen met LO02 | Bewijs van historische output, geen automaat voor publicatie |
| Binnen NL+19 PISA core/gender | 5.027 contracten | Eerste gecertificeerde technische rekenroute; niet gelijk aan 5.027 noodzakelijke nieuwe berekeningen |
| Opslag | 35.087 bestanden; 95,566 GB decimaal = ca. 89 GiB | Inventaris compleet, bytes niet integraal inhoudelijk gemigreerd |
| Exacte bestandsduplicaten | 2.257 SHA-identieke groepen in huidige audit; theoretisch 2,787 GiB | Niet vrijgegeven voor verwijdering; geen herstel-/productclosure-bewijzen |
| Cloud en Git | GitHub PR #5 draft; private Drive heeft geverifieerde oktoberbronbundel en metadata-/rapporten | Geen bewijs dat alle benodigde 95,6 GB off-device herstelbaar is |
| Status van eindproducten | Gebruikersdeck 21 slides, seminar 50 slides, notitie 16 pagina's, 138 figuurcontracten, 42 selecteerbare systemen, paper Q01–Q08 open | Bronproducten intact; nieuwe wetenschappelijke datafreeze is **niet** gemaakt |

De meest recente technische run (`next-batch`) had 8 PASS en 0 HOLD. Dat beschrijft uitgevoerde technische stappen, niet de wetenschappelijke resultatenstatus. De R-preflight had daarna een syntaxfout; die is op GitHub hersteld en is niet als wetenschappelijke productie gestart.

## 3. Leidend product- en scopespecificatieregister

| Product | Leidende verplichting | Huidige open beslissing |
|---|---|---|
| Beleidsdeck | Nieuwste geverifieerde gebruikersversie van 1 oktober: **21 slides**, niet 13; inhoudelijke wijzigingen en slide 12 behouden | Fig/data per slide aan exact resultaat koppelen; illustratieve claims niet als gecontroleerde resultaten weergeven |
| Wetenschappelijk seminar | Afzonderlijke **50-slide** bron | Relevante analyses, onzekerheid, methoden, broncitaten en beperkingen afmaken |
| Wetenschappelijke notitie | Afzonderlijke **16 pagina's**; oude bronstatus en latere reparaties consistent wegen | Historische reparatieclaims numeriek controleren vóór publicatie |
| Nederlands dashboard | Één paneel; één/twee/soms drie verenigbare grafieken binnen dezelfde plotruimte; betekenisvolle controles | Geen facetten, dubbele assen of kunstmatige schalen; beschikbaarheid/SE/CI duidelijk |
| Internationaal dashboard | **42 selecteerbare systemen**; één app en databasis met `/nl/` en `/en/` | 19 productie-referenties vervangen de 42 selecteerbare systemen niet; focusland uit zijn eigen referentie |
| Figuren | **138 figuurcontracten**; zes rankingposities alleen afgeleid uit geldige nationale resultaten | De huidige figuurdefault `OECD_HIGH_INCOME_FY2027` is niet automatisch dezelfde als de nieuwere PPP-2024-referentie |
| Paper en appendix | Acht afzonderlijke verplichtingen **Q01–Q08**, journal-grade code+data statement+exhibit map | Open totdat feitelijk berekend, gevalideerd en gekoppeld; volledige reproducerbaarheid |
| Onderzoeksmethoden | lezen/taal, rekenen/wiskunde, natuurwetenschappen; PIRLS/TIMSS rond 10 jaar, PISA 15-jarigen; niveaus, spreiding, SES, gender, taal/migratie, peercontext, trends, kwaliteit | Geen schaalmix; TIMSS 1995 doelpopulatie speciaal beoordelen; onzekerheid en vergelijkbaarheid per survey/wave |

**Referentiegroepen zorgvuldig onderscheiden.** Voor de actuele oktober-productie geldt de bevroren OESO-selectie op WDI `NY.GDP.PCAP.PP.CD`, 2024, lidmaatschap 31 december 2024: 21 landen op/ boven Tsjechië inclusief Tsjechië en Nederland, waarvan 19 buitenlandse landen strikt boven Tsjechië voor NL-vergelijkingen; daarnaast alle OESO-landen als alternatieve referentie. De exacte ruwe 2024-WDI-waarden en de bronversie ontbreken nog als onafhankelijk gevalideerde bron. Oudere common-42 leave-one-out-figuren en het 31-landenpanel voor absolute SES zijn afzonderlijke productdefinities. Wijzig de referentiekeuze nooit impliciet en herbereken daarvoor geen leerlingdata.

**Dashboardbegrippen.** Nederlandse labels zijn onder meer leerprestaties, taal, rekenen/wiskunde, natuurwetenschappen, leeromgeving en meisjes minus jongens. Taaltestfrequentie thuis is niet automatisch thuistaalidentiteit of Nederlands/niet-Nederlands. Migratiegeneraties worden alleen onderscheiden indien de vragenlijst ze werkelijk meet. Peers zijn afzonderlijk directe leeromgeving (IEA klas; PISA school×programma/track) en hele school; eigen leerling uit de noemer. Sorteer- en volg-/cohortuitkomsten zijn beschrijvend tenzij een afzonderlijk identificeerbaar causaal ontwerp bestaat.

**Historische scopebesluiten.** De architektuurfreeze van 29 september stelde voor een nieuwe compacte publieke release sommige modules (absolute versus relatieve SES, institutionele verklaringen, TIMSS 1995 in de kernfiguren) buiten de hoofdinterface. Latere afspraken van 9 oktober verlangen dat deze opties per product als actief, vervangen of uitgesteld worden geregistreerd, niet stilzwijgend gewist. De 20 buitenlandse common-42/high-income-landen uit 6 oktober zijn niet meer het algemene PPP-2024-productiestandaardpanel; hun historische productresultaten blijven als provenance bestaan.

## 4. Wetenschappelijke regels voor hergebruik en berekening

Hanteer per **uniek inhoudelijk resultaatcontract**, niet per bestandsnaam of hele tabel:

1. `REUSE_VALIDATED`: exacte metriek/populatie/groep, inputfingerprint, methode-/specificatiefingerprint, codeversie, surveyvariantie, resultaatversie en onafhankelijke numerieke/broncontrole komen overeen. Geen herberekening.
2. `DERIVE_VALIDATED`: referentie-, rang-, contrast- of productreeks kan aantoonbaar worden opgebouwd uit bestaande gevalideerde aggregaten, inclusief correcte onzekerheid/covariantie. Geen leerlingherberekening.
3. `COMPUTE_REQUIRED`: geen bruikbaar bestaand resultaat na de gecontroleerde zoekronde door centrale SQLite, CURRENT/HISTORY Parquet, LO02 en V8/V9/V11/LO01; exact benoemde cache/bron en gecertificeerde estimator beschikbaar. Alleen deze taak uitvoeren.
4. `HOLD_SOURCE`, `HOLD_METHOD`, `HOLD_VERSION_CONFLICT`, `HOLD_UNCERTAINTY`, `UNAVAILABLE`: concrete blokkade, eigenaar, benodigde bewijsstukken en productimpact.
5. `NOT_REQUIRED`: geen actuele productafhankelijkheid of noodzakelijke ondersteuning; niet produceren, maar ook niet wissen zonder bewaarbeleid.

Een match op `metric_key`, gelijke numerieke waarde of dezelfde SHA van een archief is op zichzelf nooit voldoende voor `REUSE_VALIDATED`. De waargenomen hashverschillen worden nu gesplitst in metadata/CI, numeriek onvergelijkbaar en daadwerkelijk numeriek afwijkend. Een missende schatting of SE telt nooit als numerieke gelijkheid. Gelijke gemiddelden zonder correcte plausible-values-/replicatiegewichten worden niet wetenschappelijk vrijgegeven.

Twee technische hergebruikroutes worden NIET door elkaar gehaald:

- **Bestaande LO02 V5 PISA core/gender:** vergelijkt op runtime `metric_key` en **exacte** science- en inputfingerprint met de eigen huidige LO02-database; identieke resultaten worden hergebruikt. Deze technische idempotentie is in synthetische tests en eerdere zes-resultaten Windows-proef aangetoond. Historische centrale bestanden zonder aantoonbaar dezelfde wetenschappelijke identiteit blijven review.
- **Andere vakken/modules:** oude resultaten zijn kandidaat; aparte methodencertificering voor PIRLS/TIMSS, SES/Cobreros, migratie, taal, peers en varianten is nodig. Reeds aanwezige kandidaatcheckpoint-RDS worden pas herberekend bij relevante gewijzigde input, code of specificatie; zij blijven buiten de publieke resultatenbasis.

De later toegevoegde generieke `reuse-preflight` houdt momenteel alle 29.846 contracten tegen als niet ieder contract een aparte goedkeuring heeft. Dat is **te breed** als voorwaarde om de reeds gecertificeerde V5-deelroute te testen. De Github-runner heeft daarom een beperkte actie voor uitsluitend Nederlandse PISA core/gender gekregen. De gewone brede `execute` blijft dicht totdat selectieve hergebruik- en methodechecks daadwerkelijk bewezen zijn. De smalle actie schakelt alle niet-gecertificeerde V11-kandidaatberekeningen en automatische GC expliciet uit.

## 5. Eén uitvoerketen, drie hoofdopdrachten

### Opdracht A — selectief werkbaar maken (huidige fase)

A1. Contradictie-/versielijst per product aflopen; de 21/50/16-bronnen en 138 figuren aan unieke benodigde taken binden; de gebruikersversie blijft leidend.
A2. Van resultaatidentiteit naar echte record-versie: registreer bron, input, code, methode, PV/replicate en variantie. Vergelijk dezelfde contracten over centrale SQLite, Parquet, LO01, LO02 en V8/V9/V11 met één duidelijk gesorteerde beslisregel.
A3. Los eerst de metadata-/numeriek-onvergelijkbare hashverschillen inhoudelijk op. Het huidige privérappport meldt geen verschillende schattingen/SE onder de onderzochte rijen; aanvullende volledigheidscontrole bepaalt hoeveel daadwerkelijk volledig numeriek vergelijkbaar zijn.
A4. Nederlandse PISA core/gender via uitsluitend native V5-pad: Windows-integratietest, geldige inputversies, per-taak exacte fingerprintcontrole, registraties in nieuwe LO02; overige families blijven alleen als REVIEW/HOLD zichtbaar. Reeds afgemaakte 3.486 LO02-resultaten bewaren.
A5. Integreer per survey/module en productie-eenheid alleen wat de actieve figuren, paper of replicatie nodig hebben. Geen volledige cartesische land×golf×statistiekproductie, geen parallelle schrijvers en geen herhaalde volledige disk-scan.

**A voltooid wanneer** alle actieve verplichtingen een exact berekenbare/afleidbare/bruikbare route of specifiek inhoudelijk gemotiveerde HOLD hebben; minstens het eerste NL-rekenpad aantoonbaar herbruikbaar is; geen bewezen bestaande berekening zonder reden opnieuw wordt gedraaid.

### Opdracht B — resultaten produceren, controleren, bevriezen

B1. PISA-NL na de lokale Windows-sciencechecks; houd 2003/2006 uit ontbrekende canonical input en 2015–2025 conflicterende caches expliciet op HOLD waar toepasselijk, in plaats van recentste pad te kiezen.
B2. PIRLS/TIMSS en niet-core PISA modules in afgebakende survey×wave×land-batches. Gebruik correcte PV, BRR/JRR, sample-/leeftijd-/graadgrenzen, gewichten, vragenlijstcodering en officiële OECD/IEA-ankers. PIRLS 2001 gebruikt de gedocumenteerde leeftijdscode `ASDGAGE`; TIMSS 1995 alleen na populatiebesluit.
B3. SES met afzonderlijke nationale/gewijzigde ESCS, Cobreros-trendconstructie vanaf 2015, exacte auteur-replicaties Q03/Q04 en bruikbare missingness- en overlaprapporten. Absolute SES alleen bij als actief gemarkeerde productafhankelijkheid.
B4. 19 buitenlandse PPP-referentielanden alleen voor werkelijk gebruikte reeksen, daarna overige benodigde internationale systemen om de 42 dashboardsystemen af te dekken; alternatieve referenties assembleren uit gevalideerde landrecords en gelijke landenweging, niet opnieuw uit leerlingdata.
B5. Q01–Q08 afronden: dekking/representativiteit; SES 34/36-systemenreplicatie; vaste parameters; referentie N/SE/covariantie; officiële wave-SES; trendverschillen inclusief linking-/covariantie-onzekerheid.
B6. Eén controleschema voor SQLite/current/history en productlinks: slechts één huidige versie per sleutel; geldigheid en publicatie als verschillende statussen; cold restart + cross-run reuse + officiële benchmarks + dataset/fingerprint-/runmanifesten + numerieke en CI-pariteit.

**B voltooid wanneer** iedere actieve figuur/paperbehoefte een gevalideerd en gepind record heeft, of aantoonbaar niet beschikbaar is inclusief gevolg voor het product. Nieuwe publicatiebasis is pas dan een **wetenschappelijke release**.

### Opdracht C — feitelijke eindproducten en replicatie

C1. Nederlandse figuren en 21-slide beleidsdeck; afzonderlijk 50-slide seminar en 16-pagina wetenschappelijke notitie, met behoud van de gebruikerswijzigingen. Iedere figuur: definitie, survey, golf, doelpopulatie, landenset, SE/CI, bron en versie-ID.
C2. Eén tweetalige publieke dashboardapp (`/nl/`, `/en/`), 42 selecteerbare systemen, vier gebruikersvragen als navigatie, steeds één grafisch paneel en één consistente datarelease. Gezamenlijke kernwaarden nooit in het browserproces herberekenen.
C3. Economisch paper, appendix, Q01–Q08 en volledig tijdschriftwaardig replicatiepakket: bronverkrijging/rechten, data-access statement, environment lock, producer chain, program-to-exhibit map, resultatenmanifests, figuurtest en cold-source reproduceerbaarheid.
C4. Visuele QA van slides; functionele browser-/mobile-/NL-EN-test; onafhankelijke product/resultaat-celpariteit; expliciete juridische rechtencheck vóór openbare publicatie.

**C voltooid wanneer** de werkende bestanden, dashboard/publicatieartefacten en journal-grade replicatie (of wettelijk toelaatbare reproduceerbaarheidsroute) zijn opgeleverd, niet wanneer uitsluitend plannen klaarstaan.

## 6. Parallelle opslagroute — van 95,6 GB naar toetsbaar minimaal lokaal gebruik

De inventaris bevat ongeveer 40,42 GB archieven met bronrechtenreview, 22,94 GB officiële bronnen/microdata, 21,89 GB afgeleide kandidaten en 5,16 GB kernregisters en resultaten, naast logs/overige bestanden. De grootste afzonderlijke post is `PIRLS_CACHE_SNAPSHOT_20260920_123815.zip` (35,872 GB); PISA-2022 `CY08MSP_STU_QQQ.SAV` heeft vier vermoedelijk redundante kopieën van elk ongeveer 2,097 GB. Deze bestanden niet zomaar uploaden of verwijderen: rechten en afhankelijkheden komen vóór omvang.

Opslagplaatsen:

- **GitHub:** actuele code, exact gepinde producer-sha's, niet-gevoelige configuraties, tests, beslisregister, kleine juridisch toegestane aggregaten, statische publieke dashboardbestanden. Geen privé-SQLite, microdata of private bestandsnamen in een publieke commit.
- **Private Google Drive:** originele gecontroleerde bronbundel (reeds aanwezig), noodzakelijke rechten-toegestane wetenschappelijke aggregaten, private resultaat- en productmanifests en controle-/migratierapporten. Een Drive-upload of GitHub-commit alleen is geen hersteltest.
- **Tweede onafhankelijke opslag:** apart onafhankelijk herstelbaar medium/account/opslaglocatie, met echte cold restore en volledige SHA-controle. Een tweede map op dezelfde laptop is niet onafhankelijk.
- **Lokaal Downloads:** tijdelijk actieve bronnen en werkcache totdat onafhankelijke bewijzen bestaan. Andere persoonlijke Downloads-bestanden vallen buiten het project.

Beheerprocedure: `KEEP` → `ARCHIVE` → (uitsluitend bij echte redundantie + complete productdependency closure + twee onafhankelijke off-device gecontroleerde kopieën + bewezen restore + expliciete goedkeuring) `QUARANTINE` → na ten minste **30 dagen**, hercontrole en definitieve toestemming `DELETE`. Quarantaine buiten Downloads op **dezelfde schijf** vermindert onmiddellijk de inhoud van Downloads, maar **maakt geen schijfruimte vrij** tot definitieve verwijdering. De bestaande `LOCAL_QUARANTINE` is een veilige technische voorziening, geen bewijs dat één bestand reeds verwijderbaar is. Een automatisch gegenereerde CSV met juiste veldnamen kan niet zelfstandig een echte hersteltest bewijzen.

Prioriteit voor opslagwinst: niet de 2.257 kleine duplicaatgroepen blind afhandelen, maar eerst de 35,872 GB cache-ZIP en de PISA-kopieën semantisch/bytegewijs beoordelen. Back-upquota en bronvoorwaarden bepalen daarna welke migratie haalbaar is. Geen *storage-migrate* voor ongetoetste officiële bronbestanden of live databases.

## 7. Versie- en wijzigingsbesluiten / verliesrisico's

| ID | Besluit of probleem | Leidende oplossing | Status |
|---|---|---|---|
| V01 | 13 prototype versus 21 gebruikersslides | 21-slide gebruikersdeck leidend; 13 alleen geschiedenis | Gesloten voor bronkeuze; cijferpariteit open |
| V02 | 20 buitenlandse high-income common42 versus 19 buitenlandse PPP-2024 | PPP-2024 in oktoberproductie; older panels blijven per figuur traceerbaar | Referentienumeriek bronbestand nog verifiëren |
| V03 | common42 dashboard versus productie19 | Alle 42 blijven selecteerbaar; referentie19 is alleen productieprioriteit | Scope vastgesteld; berekeningen open |
| V04 | 3.907 hashconflicten | Eerst metadata/CI en compleetheid numerieke velden, dan methodeversie | Correctie code aanwezig; real-data vervolgtest nodig |
| V05 | 61.714 'niet gevonden' | Niet 'nieuw te berekenen' noemen vóór archive-first LO01/LO02/V8/V9/V11 check | Nieuwe code aanwezig; real-data rerun nodig |
| V06 | brede execute permanent geblokkeerd | Beperkte native V5-NL-route, andere modules apart certificeren | Route code toegevoegd; Windows proof nog nodig |
| V07 | Datasets/PV/SE/CI en rechten | Numerieke, definitorische en licentiegates los van technische PASS | Open |
| V08 | PISA2006, PIRLS2001 leeftijd, TIMSS1995 | Gericht bron-/populatieherstel, geen generieke ontbrekend/NA-oplossing | Gedeeltelijk; per survey bewijs open |
| V09 | Q01–Q08 | Alle acht apart traceren tot output/appendix | Open |
| V10 | Lokale bestanden verwijderen | Niet vóór onafhankelijke herstelbare back-up, productclosure en bewaartermijn | Geen verwijdering |
| V11 | 28-september-release en Pages | Behoud tot nieuwe scientifically frozen, volledig gerepliceerde editie | Behouden |
| V12 | GitHub masterplan en historie | Dit document is **één** leidende toekomstige uitvoeringstekst; oudere roadmaps alleen provenance | Actief |

## 8. Technische regressie- en productacceptatiecriteria

Een codewijziging is pas lokaal uitnodigingsklaar na (1) GitHub Windows én Linux parse/CI, (2) synthetische tests voor aangeraakte status-/input-/resume-/GC-regels, en (3) code-review van mogelijke wijzigingen in gebruikersbestanden. GitHub-tests kunnen de exacte 95 GB Windows-opslag niet simuleren. Daarom:

- Veilig no-double: in LO02 `0 COMPUTE` en `N REUSE` bij identieke taak-/input-/sciencefingerprint na herhaalde run; een gewijzigde variabele herberekent alleen de direct afhankelijke taak. Geen source-file mtime als identiteit.
- Hervatten: na onderbreking per taak/land×golf verder; geen dubbele SQLite-writer en geen Arrow mmap Windows-error 1224.
- Resultaten: exact result-version- en productpin, complete sample/populatie-/gewichts-/PV-/SE-regels; officiële benchmarks en stabiliteit van outputs.
- Opslag: echte remote SHA readback, onafhankelijke tweede restore, productdependency closure, dry-run delete-lijst en echte restore-proef vóór enig verplaatsen.
- Publiek: zelfde records en figuurwaarden als de wetenschappelijke freeze; géén private data of ongemerkt veranderde bron-/cohortgroep.

Geen eerste lange productierun voor 29.846 contracten. Eerst de smalle Nederlandse PISA core/gender-route. De gewone `execute` blijft voorlopig technisch dicht zolang zijn selectieve niet-core adapter nog niet is gevalideerd. De nieuwe actie wordt alleen gebruikt na succesvolle CI; de ingebouwde Windows-proeven zijn onderdeel van de eigen uitvoering. Zij stopt zonder productie wanneer de echte bronnen of acceptatievoorwaarden niet kloppen.

## 9. Eerstvolgende gebruikershandeling en verdere bediening

Na geslaagde CI: **één RStudio Console-commando**, geen nieuwe ZIP/download of losse scripts:

```r
Sys.setenv(LO_START_ACTION="execute-nld-core", LO_SCOPE="nld_only")
source(file.path(repo,"START.R"))
```

Deze actie draait de gecontroleerde LO05-integratie voor Nederland, met **alleen** de native LO02 PISA core/gender-productieroute. De ingebouwde acceptatietests beoordelen echte cacheversies en storage parity voordat leerlingresultaten worden gemaakt. LO05-candidate-V11, raw imports, automatische GC en centrale wetenschappelijke promotie zijn in deze route uitgeschakeld. Zij kan nieuwe PISA core/gender-resultaten berekenen waar geen exact identiek LO02-resultaat bestaat; dat is wetenschappelijk nog geen finale release. Start deze stap niet gelijktijdig met andere productieruns. Na afloop dienen uit de gegenereerde retour de `PHASE_STATUS.csv`, `AANTALLEN.csv`, `PRODUCTIEPLAN.csv`, `WINDOWS_INTEGRATION_TESTS.csv` en `STATUS.txt` voor de vervolgkeuze. Bij een HOLD onderzoeken we de specifieke input/methode, niet opnieuw de 95 GB.

Daarna volgt zonder opnieuw scannen: goedkeuren/hergebruiken van gecontroleerde LO02-versies → resterende Nederlandse methoden → 19 referentielanden → 42-systemen/overige figuren → volledige validatie en eindproducten. GitHub issue #6 is het open checklistregister; PR #5 blijft draft totdat de wetenschap en productpariteit getoetst zijn.

## 10. Bronnen voor deze revisie

- `20261009_OVERDRACHT_COMPLEET.zip`, met `20261009_OVERDRACHT_LO.txt` en `DRIE_OPDRACHTEN.txt`.
- `LEARNING_OUTCOMES_INTEGRAAL_v2_20261010(1).zip`, inclusief 56-file SHA-manifest, `code/INTEGRATED.R`, LO04/LO05 modules, `engine/production.R`, contractmatrix, LO01/LO02 bewijs en Q01–Q08.
- `PISA_LEARNING_OUTCOMES_HANDOFF_20261007_v1.zip`; `PISA_LEARNING_OUTCOMES_NEXT_CHAT_HANDOFF_20261006_v1(1).zip`; `PISA_PIRLS_TIMSS_STEP1_SCOPE_LOCK_20260929(1).zip` en latere expliciete oktoberbesluiten.
- Gebruikersconsole 11 oktober (`plan_only`, `next-batch`, `reuse-preflight`), de private Drive-rapporten `CANONICAL_RECONCILIATION_SUMMARY.csv` en `CONTRACT_COVERAGE_BY_FAMILY.csv`, en de met GitHub gecontroleerde PR #5 / issue #6.
- `PISA_20261010_19_OPSLAGAUDIT_EN_VERVOLG.md`, `SCIENCE_AUDIT_20261010.md`, `HISTORICAL_LESSONS_AND_PARITY.md`, en de oorspronkelijke wetenschappelijke release-/projectlocks.

Geen enkele bron bewijst momenteel een volledig afgeronde oktober-wetenschappelijke release, volledig naar Drive overgezette 95,6 GB of veilig uitvoerbare massale opschoning. Dergelijke claims worden pas gemaakt na de hiervoor omschreven acceptatietests.
---

## 11. Correctie 12 oktober 2026 — lokaal RStudio, GitHub definitieve publicatie, Google tussenresultaten

**Leidend gebruikersbesluit (herbevestigd 12 oktober, gebaseerd op expliciete afspraken 10 oktober):** ALLE wetenschappelijke berekeningen blijven in de Windows-RStudio-installatie op de eigen computer draaien, met de bestaande reeds gedownloade data. GEEN Google Cloud VM, remote RStudio of andere cloud-compute veronderstellen. De eerdere op 12 oktober kort genoteerde 'cloud-only/cloudcomputer' interpretatie was onjuist en is vervallen; zij blijft via Git-geschiedenis controleerbaar.

**Centraal opslag- en publicatiemodel**:
1. **GitHub:** gepinde en geteste wetenschappelijke R-code, versiebesluiten, manifesten, tests, lichte rechtengecontroleerde *definitief gevalideerde* aggregate cijferpublicaties, het definitieve figurenpakket, de geschikte (grootte/rechten) PPTX/PDF-publicaties, paper/appendix en statische dashboard/site, met commit/release versie-IDs. Geen privacygevoelige lokale paden, ruwe OECD/IEA-microdata, restricted bytes, geheime sleutels of niet-gevalideerde resultaten publiek.
2. **Private Google Drive:** automatische versioned upload van **tussenresultaten, checkpoints, logs, historische code-/resultaatbundels, interne SQLite/Parquet-registers waar rechtmatig en veilig, samenvattende productierapporten en herstelbare back-ups**. SHA-256 verifiëren op remote bytes, readback en manifest. Grote opslagvraag en het op 11 oktober bekende beperkte Drivequotum apart beheren. Een onafhankelijke back-up buiten de primaire Drive-kopie kan noodzakelijk blijven voor veilige verwijdering.
3. **Lokale RStudio:** voert berekeningen uit vanuit de versiebeheerde GitHub-checkout, gebruikt bestaande bronbestanden en eerder gemaakte lokale caches *voordat* het iets opnieuw rekent, bewaart noodzakelijke tijdelijke checkpoint- en scratchbestanden lokaal tijdens de run. Deze tijdelijke werkopslag is normaal en onvermijdelijk op de eigen laptop, maar mag niet automatisch tot permanente dubbele archieven in Downloads leiden.
4. **Automatische opbrengst:** na iedere afgeronde taak/run geschikte tussenresultaten + runlog + status + gezuiverde retour naar private Drive; finale resultaten na science freeze naar GitHub. Geen handmatige chat-ZIP-uploads/downloads als standaardproces. Status alleen op GitHub bewijst geen geslaagde volledige upload; de `DRIVE_SYNC.R`-allowlist is inmiddels uitgebreid met de gepinde LO05-retour-ZIP en veilige losse rapporten, met ZIP-inhoudscontrole, SHA-readback en benoemde Drive-mirrors. De code is versiebeheerd en ondergaat Windows/Linux-CI; een echte overdracht vanaf deze laptop moet nog worden uitgevoerd en bevestigd. Grote RDS/Parquet-caches zijn **niet** ineens gekopieerd.
5. **Bewaren en opruimen:** hergebruik en productafhankelijkheden vaststellen via reeds gedane 35.087-bestanden/95,566-GB-inventaris; geen nieuwe volle scan zonder aanleiding. Lokale R-geproduceerde **afgeleide** bestanden komen pas voor verwijdering in aanmerking na aantoonbaar geslaagde cloudmigratie, exact SHA-/method-/resultaatversie-register, volledige afhankelijkheidsclosure, onafhankelijk geteste back-up en restore, bronrechtencheck en voorafgaande expliciete goedkeuring. Script mag dan na goedgekeurde quarantaine en minimaal 30 dagen + verse controle **automatisch namens gebruiker de toegestane bestanden verwijderen**. Ruwe originele bronnen, benodigde uitvoercode, credentials, actieve caches en andere persoonlijke Downloads-bestanden zijn standaard uitgesloten. Niets wordt nu verwijderd.
6. **Geen extra run voor synctest:** controleer eerst bestaande `run_20261012_084825`, zijn `LEARNING_OUTCOMES_RETURN.zip`, `PHASE_STATUS.csv`, `AANTALLEN.csv`, `PRODUCTIEPLAN.csv` en medische/onderzoekssensitiviteit lokaal via versiebeheerde veilige exporter; sync bestanden automatisch naar private Drive. Daarna per module ontbrekende wetenschappelijke validatie of nieuwe computation doen.

**Visualisatieregel (12 oktober):** iedere lijn die een gecombineerde referentiegroep (gelijk gewogen gemiddelde van beschikbare, passend gekozen landen/systemen) voorstelt krijgt **geen SE, geen CI en geen foutbalk**. De individuele landenresultaten behouden intern de correcte survey-design/PV/replicate-SE's; NL/focusland CI kan op de grafiek als relevant. Een expliciete inferentiële toets van focusland versus benchmark moet afzonderlijk worden opgebouwd met passende variantie en mag niet gebaseerd worden op visuele overlap van foutbalken. Bij longitudinale panels vaste leden en referentiedefinitie op de figuur; focusland uitsluiten van eigen comparator.

**Figuurkeuzes:** zie [FIGURE_LITERATURE_MAPPING_20261012.md](FIGURE_LITERATURE_MAPPING_20261012.md). Figuur 3 vervalt als aparte publicatie; 12 is onder basisniveau naar SES; 13 (hoog niveau naar SES) appendix/optioneel; 11 en 15 zijn contrasten op groepsscores, SE alleen met contrastcovariantie/replicates; 23 peers onder basis als hoofdfiguur, hoog als optionele aanvulling. Bewaar originele 138 contracts en 21-slide gebruikersbasis als provenance; wijzigingen zijn nieuwe productversies.

**Eerstvolgende concrete actie**: **geen nieuwe leerlingrun**. Voer na geslaagde CI uitsluitend de private publicatieactie uit voor de **reeds voltooide** Nederlandse `run_20261012_084825`, vanuit de GitHub-gestuurde Windows-RStudio-runner, met `LO_START_ACTION=publish` en `LO_DRIVE_SYNC_RUN_ID=run_20261012_084825`. Controleer daarna via Drive de aantallen/status/QA en de volledige SHA-geverifieerde ZIP. Daarna reconcileer bestaande caches en breng alleen gevalideerde, rechtengecontroleerde definitieve publicatiebestanden naar GitHub. De actie heeft geen leerlingberekeningen en verwijdert geen bestanden. GitHub-publicatie van definitieve wetenschappelijke cijfers pas na de science release en rechtencontrole.



## 12. Uitvoeringsregel 12 oktober — proactief maximaal voorbereiden vóór gebruikers-RStudio

De gebruiker wil geen keten van eenmalige mini-R-runs. Vóór een volgend RStudio-commando moet de assistent alle redelijkerwijs mogelijke **GitHub-codewijzigingen**, synthetische **Windows én Linux CI**, testdekking, toelichtingen, bestaande Google Drive-rapportcontroles en bekende foutpaden afronden. Lever alleen een uitvoercommando voor een werkelijk geteste, zoveel mogelijk gecombineerde actie; als wetenschappelijke input/gates ontbreken, rapporteer expliciet de HOLD i.p.v. compleetheid te suggereren. Geen onnodige herberekeningen of handmatige ZIP-uitwisselingen.

Huidige vaststelling: de private export van `run_20261012_084825` gaf `HOLD_NO_EXACT_RUN_LINK` (40 verwacht, 0 gelinkt). De gevonden SQLite-`results`-tabel heeft `metric_key`, `estimate` en `se`, maar geen exact run-ID-veld. De code `EXISTING_LO02_EXPORT.R` maakt nu tevens read-only `LO02_SNAPSHOT_COUNTS.csv`: SHA van bestaand SQLite-bestand, tabelnaam, aantal rij-/unieke metric_keys, aanwezige estimator-/SE-/run-ID-velden. Upload automatisch met private Drive-manifest en SHA-readback. Dit is **metadata**, geen bewijs dat de 40 nieuwe records uniek zijn, en verandert noch valideert de leerlinguitkomsten.

Geplande drie geïntegreerde rondes, nog niet volledig uitvoeringsklaar:
- Ronde A: lokale oude/huidige LO02/LO01/V8/V9/V11-registraties exact vergelijken; alleen goed bewezen identieke input-/methode-/resultaatversies hergebruiken; selectieve recompute queue. Geen promotie bij alleen overeenkomende `metric_key`.
- Ronde B: resterende wetenschappelijk gecertificeerde modules in taakgroepen produceren, met per-task fingerprints, resumable checkpoints en automatische private Google Drive-tussenopslag. Nieuwe estimators pas na benchmark, PV/design-SE, SES-, cohort- en peergates; geen globale force-override.
- Ronde C: Q01–Q08, survey/PV/SE/linking/bronrechten, complete productpariteit (21 beleids- en 50 wetenschappelijke slides, 16-page note, 42-system dashboard, figuren en paper), definitieve geautoriseerde aggregate GitHub-release. Publicatiefouten mogen niet automatisch een freeze legitimeren.

Opslag: RStudio Windows blijft rekenen; GitHub is code + finale toegestane publicatie; private Google Drive is tussentijdse resultatenopslag; redundante R-geproduceerde lokale files pas verwijderen na exacte dependency closure, twee onafhankelijk herstelbare backups, SHA- en restorebewijzen, quarantaine en expliciete toestemming. Gecombineerde referentiegroeplijnen krijgen in figuren geen zichtbare SE of CI.


## 13. Resultaat 13 oktober — minimale aanvullende berekeningen per figuur (bronbasis uitgevoerd)

**Bronanalyse daadwerkelijk uitgevoerd:** originele 79.448 metric_keys/138 figure contracts en 16.767 LO01 / 3.486 LO02-archivekeys vanuit de gepinde 11 oktober overdrachtsbundel vergeleken. Union 19.306 historische kandidaten, 60.142 nog zonder match in deze twee specifieke registers. Het volledige familieoverzicht met exacte aantallen staat in [FIGURE_ARCHIVE_COVERAGE_BASELINE_20261013.csv](FIGURE_ARCHIVE_COVERAGE_BASELINE_20261013.csv); interpretatie, aangepaste contractscope en methodologische begrenzing in [MINIMUM_FIGURE_COMPUTATIONS_20261013.md](MINIMUM_FIGURE_COMPUTATIONS_20261013.md). Dit is niet een exacte telling van noodzakelijke nieuwe analyses: ongevalideerde kandidaten, centrale andere SQLite-/Parquet-versies en V8/V9/V11 moeten eerst inhoudelijk geadjudiceerd worden.

De oude aparte 1.735 op/over-basisniveau-productposities vervallen als grafiek (complement van onder basis), 2.466 SES-high posities zijn optioneel, 10.410 oude high-peer posities zijn alleen optionele robuustheid. Hierdoor **64.837** actieve oorspronkelijke posities, met 13.520 archiefkandidaten; daarvan zijn **13.378** bestaande afgeleide gap/spread-contracten waarbij gezamenlijke variantie/PV nog kan ontbreken. De nieuwe hoofdmaat peer-exposure onder basisniveau is **niet** aanwezig in het oorspronkelijke high-peers-register: **3.470** land×survey×jaar×vak×direct/school-contexten, maximaal **10.410 nieuwe candidate slots** als drie eigen-basiscategorieën worden gemaakt. Deze zijn niet automatisch allemaal wetenschappelijk realiseerbaar of opnieuw te berekenen. Het aantal nieuw te berekenen leerlingresultaten is **niet bewezen**.

**Code:** [MINIMUM_FIGURE_QUEUE.R](MINIMUM_FIGURE_QUEUE.R) is een read-only GitHub-gestuurde automatische triage van alle originele contracten met hun actieve/optionele/afgeleide status en archiefkandidaten. De actie `LO_START_ACTION="figure-minimum-plan"` doet geen leerlingproductie en verwijdert niets; ze maakt privé-invoerqueue plus samenvattende familie- en extra lage-peer-requirementtabellen. Uitsluitend de expliciet veilige aggregaatsamenvattingen gaan via automatische SHA-geverifieerde Drive-upload; de persoonlijke metric_key-taskqueue niet. Geen oude wetenschappelijke release wordt daardoor automatisch goedgekeurd.

**Eerstvolgende wetenschappelijke gate:** match alle actieve vereisten (inclusief nieuwe lage-peersplit) tegen validatie- en fingerprintbewijzen uit *werkelijke* centrale current/history SQLite, LO01/LO02 en V8/V9/V11/Parquet op de laptop. Markeer `COMPUTE_REQUIRED` pas bij *bewezen* ontbreken, geteste methode, correcte SE/covariantie en onderliggende bronbeschikbaarheid. Niet massaal 51.317 of 60.142 'ontbrekende' berekeningen starten.


## 14. Bronverificatie 13 oktober — beperkte grid en prioritaire C:-opslag

**Type besluit:** uitvoeringsaanvulling op het bestaande v2-masterplan. Geen wetenschappelijke freeze, geen lokale verwijdermachtiging. De op 13 oktober aangeleverde compacte ZIP is read-only geverifieerd: alle 1.366/1.366 externe SHA-256-manifestbestanden en 56/56 wetenschappelijke code-/evidencebestanden zijn correct; het ZIP slaagt de CRC-test. Dat bewijst uitsluitend integriteit van de compacte overdracht, niet de 95,6 GB Windows-projectmap.

### 14.1 Productgedreven, minimale grid

De grid bestaat uit de **unieke voor actieve producten benodigde wetenschappelijke resultaatidentiteiten**: survey, broneditie, wave, systeem, vak, doelpopulatie, uitkomstmaat, uitsplitsing/groepsniveau en — waar relevant — peeromgeving; per cel: estimate, N, SE/CI/covariantie, PV/designregels en volledige bron-/input-/code-/methode-/versieprovenance. Producten: gebruikersbeleidsdeck 21 slides, seminar 50 slides, notitie 16 pagina's, 138 figuren, tweetalig 42-systemen-dashboard en paper/appendix Q01–Q08. Nationale gemiddelden worden slechts één keer geproduceerd; referentiegroep, ranking en grafiekvariant zijn afleidingen zonder nieuwe leerlingrun. Geen volledige cartesische productiebatch van alle mogelijke combinaties.

De GitHub-figuurplanning van 13 oktober meldt 64.837 actieve oorspronkelijke contractposities, 13.520 kandidaten in LO01/LO02, 51.317 zonder match **alleen** in die twee bronnen, en maximaal 10.410 conceptuele nieuwe posities voor peers onder basisniveau. Dit zijn **geen** tellingen van nodige nieuwe berekeningen. Eerst echte current/history SQLite, Parquet, V8/V9/V11, LO01/LO02, de 40 nieuwe NL-LO02-records en beschikbaarheid van correcte covariantie/PV per unieke contractcel afdoende toetsen. Pas dan REUSE_VALIDATED, DERIVE_VALIDATED, COMPUTE_REQUIRED, HOLD of NOT_REQUIRED toekennen. De historische matrix van 1 oktober heeft 54.768 rijen inclusief 37.030 placeholders en 4.200 HOLD-rijen, niet 54.768 vrijgegeven resultaten.

### 14.2 Bron-/versieconflicten die niet mogen verdwijnen

- **Gecorrigeerd na lokale relatie-audit op 13 oktober:** de gebruikers-PPTX bevat **21 gekoppelde slides en 48 gekoppelde grafieken**. De eerdere telling van 13 miste de niet-standaard `v8_slide*.xml`-delen. Alle 21 slide-targets bestaan; de SHA is exact de geregistreerde gebruikersbron. Zie `review_20261013/POLICY_DECK_RELATIONSHIP_AUDIT.json`. Dit is pakketcontrole, geen wetenschappelijke/visuele vrijgave.
- **Lokaal opgelost op 13 oktober:** de zip bevat de 15-pagina-versie van 27 september. De echte notitie van 28 september staat in Downloads, heeft **16 pagina's** en SHA `be3b9ba0b9b4e5bdeb428695919dd46d521e32ddd64fc3e31eca55392a91ba27`. Pagina 16 is een inhoudelijke completion-update; eerdere hoofdstukken bevatten nog oude beperkingen. Match de gemelde reparaties op de oorspronkelijke resultaatversies.
- Het startdocument verwijst naar een fysieke 07_SCOPE_LOCKS_20260929-map die niet onder die naam in de ZIP staat; STEP1-scope-lockbestanden zijn gedeeltelijk onder historie/provenance teruggevonden. Geen automatische hercreatie of conclusie dat besluiten vervallen.

### 14.3 Opslagroute: eerst de echte tientallen GB

Windows-inventaris 10–11 oktober: **95.566.093.858 bytes in 35.087 bestanden**, geen live vrije-ruimtecontrole. Grootste projectonderdelen: RUNNER 39,15 GB, 29_results_resume_v11 22,82 GB, 00_PROJECT_REGISTRY 13,35 GB, 27_dashboard_multicountry_v9 8,56 GB, 20_rc2_domains 5,05 GB.

**P0:** maak waar veilig ruimte via Windows Opslag/Tijdelijke bestanden, maar verwijder geen projectmappen en sluit Downloads en mogelijk waardevolle caches uit. Controleer of onafhankelijke externe opslag beschikbaar is.
**P1:** beoordeel eerst read-only het archief RUNNER/cache_snapshots/PIRLS_CACHE_SNAPSHOT_20260920_123815.zip, **35.872.083.611 bytes**: ZIP-directory, wetenschappelijke unieke inhoud, verwijzingen vanuit producer en exacte restore-check; niet uitpakken op volle C:. Verplaats de veilige, verifieerbare bewaarversie naar onafhankelijk volume zodra de bron-/dependency-/herstelgate slaagt; geen definitieve lokale retire zonder volledige procedure.
**P2:** vier PISA-2022 .SAV-exemplaren van **2.096.666.903 bytes per bestand** in registry en oude caches: eerst 4 exacte hashes en broneditie, vervolgens één canonieke input en technische referenties bewijzen. Gelijke bestandsomvang is geen bewijs van gelijke inhoud.
**P3:** 2.257 SHA-identieke groepen, theoretisch 2,787 GiB extra winst, alleen gericht groeperen en na productdependency- en herstelcontrole; geen blind duplicate-delete.
**P4:** overige oude cache- en run-snapshots uitsluitend selectief op basis van herleidbare producer, wetenschappelijke noodzaak, juridisch toegestane externe kopieën en een geteste restore. Live databases vereisen consistente snapshotprocedure.

Bij de laatste controle had private Drive **14,985 GiB vrij**, dus het PIRLS-archief past daar niet. In de bestaande lokale opruimqueue is **nul** item geautoriseerd; het historische retirement-plan markeert elk bestand HOLD. Voor het verwijderen van projectbestanden blijven de afgesproken gates gelden: correcte bronrechten, onafhankelijke off-device back-ups, SHA en cold-restore, dependency closure, expliciete toestemming en waar van toepassing ≥30 dagen quarantaine. Quarantaine op C: wint **geen** vrije C:-bytes. Geen leerlingdata of private bestandsnamen naar publieke GitHub.

**Geactualiseerd opslagbesluit 13 oktober:** bronbestanden mogen op C: blijven, tussenresultaten gaan naar private Google Drive, definitieve toegestane resultaten en code naar GitHub. De eerdere eis eerst circa 40 GB externe ruimte te zoeken is daarmee geen algemene voorwaarde voor codeherstel. Voor daadwerkelijk verwijderen blijven aantoonbare herstelbaarheid en de bestaande verwijdervoorwaarden gelden. Zie het geïntegreerde uitvoerplan hieronder.

**Eerstvolgende wetenschappelijke stap:** maak één per contract geadjudiceerde, leesbare reuse/derive/compute/HOLD-queue uit het actuele productregister én de feitelijke centrale resultatenregisters, met bijzondere aandacht voor de 40 NL-LO02-records. Vervolgens uitsluitend de eerste nog nodige en wetenschappelijk gecertificeerde Nederlandse uitkomsten via de native V5-route berekenen.


## 15. Onafhankelijke kritische review en integraal uitvoerplan — 13 oktober 2026


Opgesteld op 13 oktober 2026, vóór het lezen van de nieuw aangeleverde ChatGPT-chat. Dit document is de onafhankelijke basis. Eventuele aanvullingen uit die chat komen in een afzonderlijk vergelijkingsverslag. Het plan is geen wetenschappelijke vrijgave van de bestaande cijfers.

**Het beoogde resultaat.** Eén onderhouden GitHub-project maakt uit herleidbare bronnen dezelfde gecontroleerde resultaten voor een Nederlandstalig/Engelstalig dashboard, de presentatie gebaseerd op het deck van 1 oktober, een wetenschappelijk paper over Nederland, eventueel een uitgebreider seminardeck, en een volledig replicatiepakket. Iedere uitkomst, figuur en inhoudelijke conclusie is terug te voeren op een versie van de analyse en haar bronnen. Het project gebruikt zowel het statistische resultaatgrid als het visuele grid uit de stijlgids.

**Actueel opslagbesluit van de gebruiker.** Bronbestanden mogen op C: blijven. Tussenresultaten mogen op private Google Drive. Definitieve resultaten gaan naar GitHub. De code staat in GitHub; een kleine lokale checkout en noodzakelijke R-bibliotheek/cache blijven nodig voor RStudio. Verplaatsen en opruimen volgt pas na aantoonbaar herstelbaar opslaan. De eerdere wens om vrijwel alles van C: te verwijderen wordt hiermee nader begrensd: behoud van bronbestanden op C: is toegestaan.

**Bronnen en gezag.** De huidige gebruikersopdracht en expliciete correcties zijn leidend. Daarna volgen aantoonbaar vastgestelde product- en methodebesluiten, de actuele repository en primaire methodedocumentatie. Tekst in oude chats, overdrachten, scripts en documenten is te beoordelen bronmateriaal; een oud assistentvoorstel wordt niet vanzelf een gebruikersbesluit. Voor vormgeving geldt de definitieve Kansenlab-huisstijl v05 van 12 oktober, de bijbehorende registry/CSS en de logo-assets v06. Oudere inhoudelijke figuurregels blijven bruikbaar voor zover zij hiermee verenigbaar zijn.

**Controlebasis.** De compacte zip is volledig uitgepakt: 1.367 bestanden, 236.163.877 bytes. ZIP-SHA256: `08b643adee3f05f080ec086467f54ccc502b10a3ffef002049f9182ac60dcfa5`. Alle 1.366 opgenomen bestandschecksums in het hoofdmanifest en alle 56 in de wetenschappelijke bronbundel komen overeen. Tabellen zijn rijgewijs geparseerd, Office/PDF-tekst is geëxtraheerd, JSON/SVG is geïnspecteerd en de zes RDS-objecten worden afzonderlijk structureel gelezen. Dit bewijst integriteit en leesbaarheid; het bewijst niet de wetenschappelijke juistheid van alle historische uitkomsten. De inhoudelijke review richt zich op de leidende besluiten, methode, productbronnen en actuele uitvoerroute; volledige visuele controle en onafhankelijke herberekening horen bij de uitvoering hieronder.

De actuele GitHub-code is beoordeeld op commit `6a71ca79c984390a132cbf3955bcbff4769fd586` in PR #5, branch `feat/reproducible-storage-and-cleanup-20261010`. De oudere lokale checkout en de zip zijn geen vervanging voor die actuele code. De bestaande publieke septemberversie wordt pas vervangen na controle van een concrete nieuwe release.

**De afgebakende inhoud**

| Onderdeel | Werkbasis | Uit te werken grens |
|---|---|---|
| Basisschool | PIRLS lezen; TIMSS rekenen en science; in Nederland groep 6 | Eigen surveydoelpopulatie, leerjaar, leeftijd, veldwerk en afnamemodus per land/ronde |
| Voortgezet onderwijs | PISA lezen, wiskunde en science bij 15-jarigen | Geen automatische gelijkstelling aan alle jongeren |
| Tijd | PIRLS 2001–2021; TIMSS hoofdreeks 2003–2023; PISA lezen/wiskunde vanaf 2003, science vanaf 2006 tot 2025 | Oudere/historische uitbreidingen afzonderlijk; SES-harmonisatie primair 2015/2018/2022/2025 |
| Uitkomsten | Gemiddelde, aandeel onder basisniveau, hoge/advanced prestaties, P10/P50/P90 en spreiding | Survey- en domeinspecifieke grenzen; 475/550/625 bij IEA correct benoemen |
| Groepen | Totaal, sociale achtergrond, meisjes/jongens volgens bron, thuistaal, migratieachtergrond inclusief generaties | Geen gelijkstelling van thuistaal, nationaliteit en migratie; missings apart |
| Onderwijsomgeving | Peerblootstelling, school-/klassensortering, waar ondersteund taal-/migratiescheiding | Klas, school×programma en school onderscheiden; geen causaliteit suggereren |
| Verdieping | SES×gender, absolute versus relatieve SES, fasevergelijkingen, gevoeligheidsanalyses | Afzonderlijke productvereisten; niet verdwijnen omdat ze buiten oude task-keys vallen |

De 42 dashboardstelsels zijn ALB, ARE, AUS, AZE, BGR, BRA, CYP, CZE, DEU, DNK, ESP, FIN, FRA, GEO, HUN, IRL, ITA, JOR, KAZ, LTU, LVA, MAR, MKD, MNE, NLD, NOR, NZL, POL, PRT, QAT, SAU, SGP, SRB, SVK, SVN, SWE, TUR, TWN, USA, HKG, MAC en XKX. Dit is het vastgelegde dashboardbereik, niet de bewering dat ieder stelsel iedere meting heeft.

De vastgelegde buitenlandse referentie voor Nederland bevat AUS, AUT, BEL, CAN, CHE, DEU, DNK, ESP, FIN, FRA, GBR, IRL, ISL, ITA, KOR, LUX, NOR, SWE en USA. Deze 19 volgen de geregistreerde regel OESO-lidmaatschap en BBP per hoofd in koopkrachtpariteit in 2024 **strikt boven** Tsjechië, met Nederland uitgesloten uit zijn eigen vergelijking. De registratie moet nog op het oorspronkelijke World Bank-snapshot worden aangesloten; in de compacte membership-CSV ontbreken de feitelijke BBP-waarden. Een actuele API-revisie mag de historische ledenlijst niet stil wijzigen.

De unie van dashboard- en referentielanden omvat 50 stelsels. Oostenrijk, België, Canada, Zwitserland, het VK, IJsland, Zuid-Korea en Luxemburg zijn de acht extra rekenlanden buiten de dashboard-42. De Cobreros-replicaties gebruiken weer eigen 34- en 36-stelselpanels. Ook de historische internationale SES-referentie van 31 andere stelsels en de vakgebonden fasepanels blijven afzonderlijk herkenbaar. Deze panels mogen niet worden samengevoegd onder één label ‘internationaal’.

Voor tijdreeksen: een vooraf afgebakend, per uitkomst en periode vast panel, gelijke landenweging en uitsluiting van het focusland uit zijn eigen referentie. Bij onvolledige deelname geen ongemerkt wisselende samenstelling. Een beschikbaar-panelvariant kan als benoemde gevoeligheidsanalyse. Op de gecombineerde benchmarklijn komen volgens het bestaande productbesluit geen SE/CI; nationale onzekerheid blijft wel zichtbaar. Een inferentiële claim over een land versus de benchmark vraagt een afzonderlijke, geldige contrastberekening.

**Kritische review: de belangrijkste correcties**

| Prioriteit | Vastgesteld probleem of te toetsen risico | Herstel en bewijs dat het is opgelost |
|---|---|---|
| P0 | De GitHub R-tests falen op Windows en Linux: nul ontbrekende peer-rijen worden gecombineerd met één statuswaarde | Lege tabellen correct maken; regressietest met nul én meerdere ontbrekende rijen; daarna de gehele relevante CI-keten |
| P0 | `LO_FIXED_CONTROLLER.R` geeft `grid=grid` aan `lo_fixed_produce`; de functie accepteert geen grid | Eén contract voor controller/producer; een integratietest die de echte aanroep uitvoert, niet alleen R-bestanden parseert |
| P0 | De huidige producer routeert hoofdzakelijk PISA core/gender en beperkt native productie tot NL/19; andere modules blijven HOLD | Een echte capability-matrix, moduleadapters voor alle actieve vereisten, en gridgestuurde batches die uitsluitend goedgekeurde ontbrekende taken uitvoeren |
| P0 | Een geldige hash, task-key of statuswoord is nog geen wetenschappelijk bewijs | Identiteit én herkomst én methode én waarden toetsen; goedkeuringsbestanden koppelen aan bewijsbestanden en reviewer/versie, niet aan vrij invulbare PASS-labels |
| P0 | De resultaatscope bevat onmeetbare combinaties en placeholders | Elke cel eindigt als gevalideerd, onderbouwd niet beschikbaar/niet vergelijkbaar, of concreet open; een onmogelijke waarde mag de release niet eindeloos blokkeren en mag nooit worden verzonnen |
| P0 | Er is nauwelijks vrije schijfruimte; oude routes bevatten automatische opruimopties | Voor productie ruimte/RAM/buffer toetsen; geen dubbele volledige uitpakacties; oude delete/gc-routes niet via een omweg activeren |
| P1 | Het archief meldt ten onrechte 13 in plaats van 21 slides | De presentatie-relaties leveren 21 bestaande slides en 48 gekoppelde grafieken; de afwijkende `v8_slide`-namen meenemen. Geen acht ontbrekende slides reconstrueren |
| P1 | De oude figuurcontracten gebruiken overal een andere standaardreferentie (`OECD_HIGH_INCOME_FY2027`) | Contracten, renderer, labels en downloads aansluiten op de vastgelegde PPP2024-referentie; oude keuze als historische variant bewaren |
| P1 | De matrix van 1 oktober heet canonical, maar bevat 37.030 placeholders op 54.768 rijen en 4.200 held-rijen | Geen vrijgave op bestandsnaam; per resultaat daadwerkelijk bewijs en broneditie vaststellen. Oude VALIDATED-labels opnieuw aan hun voorwaarden koppelen |
| P1 | Het SES-coverage-register bevat 966 rijen zonder bruikbare coveragecijfers | Q01 werkelijk produceren: gewogen en ongewogen dekking, N, componentmissings en analysepopulatie per definitie |
| P1 | Officiële ESCS, geharmoniseerde ESCS en boeken thuis worden in eerdere stukken soms te gemakkelijk vergeleken | Eigen construct-ID's, aparte kwartielregels en missings; harmonisatie-aannamen en gevoeligheden rapporteren |
| P1 | Groepsgaps en P90–P10 zijn afleidbaar, hun SE niet uit losse marginale SE's | Gezamenlijke PV/replicaten of passende covariantie bewaren; Var(A−B)=Var(A)+Var(B)−2Cov(A,B) |
| P1 | De nieuwe hoofdmaat lage-prestatiepeers ontbreekt in de oude high-peer-taken | Eigen uitkomst en keys; juiste drempel, uitsluiting van de leerling zelf, geldige noemer, surveyomgeving en gezamenlijke PV/replicatie |
| P1 | Historische PIRLS-corevarianties, gendercodering, TIMSS-1995-populatie en TIMSS/Numeracy zijn eerder problematisch geweest | Gericht terug naar bronvariabelen/labels en cyclusmethode; reparatie van één module niet als bewijs voor alle modules gebruiken |
| P1 | PISA/PIRLS/TIMSS en verschillende leeftijden hebben geen gemeenschappelijke ruwe vaardigheidsschaal | Geen ruwe scoreaftrek tussen surveys, geen individueel leerverlies uit opeenvolgende dwarsdoorsneden, geen causaal selectie- of peereffect |
| P1 | Bronrevisies en ontbrekende representativiteit kunnen conclusies veranderen | Editie-lock, overlapcontrole, officiële respons-/uitsluitingswaarschuwingen, modal- versus all-target-populaties apart |
| P2 | Huisstijlbestanden zijn deels nieuwer dan het dashboard; fonts zijn niet meegeleverd | V05-registry als bron voor tokens; fontbestanden/licenties vastleggen en embedding controleren; v06-SVG's gebruiken |
| P2 | Sommige Leerprestaties-logo's hebben intern nog de titel Onderwijsverschillen | Metadata/accessibility-titel corrigeren zonder de vormgeving opnieuw te tekenen |

Deze review omvat ook de voorgestelde aanpak zelf. Meer HOLD-registers lossen ontbrekende estimatoren niet op. Een nieuw framework of nieuwe runner is geen vooruitgang als hetzelfde wetenschappelijke probleem blijft liggen. ‘Alles opnieuw berekenen’ is evenmin het doel: eerst bestaande bewijsbare resultaten terugvinden, dan de minimale resterende berekeningen uitvoeren. De omvang van de oude contracten — 79.448 — is geen schatting van resterende rekentijd. Ook de 60.142 zonder match in twee archiefregisters zijn geen bewezen nieuwe rekentaken.

**De wetenschappelijke ruggengraat: het grid**

Behoud de bestaande gridmodules en maak ze daadwerkelijk sturend. Eén primitieve cel wordt bepaald door survey, land, ronde, domein, doelgroep/steekproef, groepsvariabele en niveau, SES-construct, uitkomst/drempel, peeromgeving en estimatorversie. Aan dezelfde cel hangen broneditie, input- en codehash, gewicht-/PV-/variantie-/linkingregel, aantallen, estimate/SE, covariancegroep, run-ID en bewijsstatus. Ontbrekende identiteit wordt eerst ingevuld; een match op metric_key alleen mag nooit een resultaat overnemen.

Maak daarnaast een afhankelijkhedentabel: product → figuur/tabel/tekstgetal → afgeleide schatting → primitieve cel → bron. Gemiddelden, percentielen en groepen worden eenmaal berekend. Gaps, complementen, spreads en referenties worden uit gevalideerde onderliggende objecten afgeleid waar hun onzekerheid dit toelaat. Een gewijzigde bron of methode maakt alleen afhankelijke resultaten ongeldig. Versies worden toegevoegd; historische cijfers worden niet ongemerkt overschreven.

De batchplanner onderscheidt hergebruik, nog te toetsen kandidaat, afleiden, ontbrekende bron, niet vergelijkbaar, gericht berekenen en niet nodig voor het actieve product. Iedere uitvoerbare batch heeft bronselectie, methode, verwachte cellen, benodigde ruimte, hervatpunt en foutafhandeling. Bij peerberekeningen moet de indeling van de leerling zelf per plausible value correct samenhangen met de uitkomst van de peers. Kleine groepen en een ongeldige/no-peer-noemer krijgen een expliciete status.

**Statistische controles die vooraf worden vastgelegd**

Plausible values worden per populatie-estimator gecombineerd; een gemiddelde PV per leerling vervangt die procedure niet. PISA Fay-BRR en IEA JRR worden per cyclus gecontroleerd, inclusief aantallen en schaalfactoren. Fractionele kwartielen bij discrete boekenitems verschillen van random tie-breaking in de externe replicatie. Voor een exacte replicatie worden de oorspronkelijke tie-regel, seed, imputation en herberekening onder replicaatgewichten gevolgd; alternatieven krijgen een andere methodenaam. Een vaste itemset alleen bewijst nog geen meetinvariantie over landen of jaren.

Trendtoetsen volgen de relevante broneditie en linking-onzekerheid. Een gemeenschappelijke linkingcomponent mag niet ten onrechte door het aantal referentielanden worden gedeeld; eventuele annulering in gaps vereist de passende aannamen. Geen onafhankelijkheidsformule gebruiken voor afhankelijke groepscontrasten. Voor veel vergelijkingen worden primaire contrasten en families vooraf aangewezen en multipliciteit/robustheid verantwoord. Een niet-significante uitkomst betekent niet dat er geen verandering is.

Kwantielen, prevalentie, SES-groepen, schooldecompositie en Theil H hebben ieder een eigen estimator en doelpopulatie. Bewaar aantallen leerlingen/scholen/klassen, gewogen dekking en relevant effectief N. Een uitsluitend op gewichten gebaseerde effectieve steekproefgrootte is geen vervanging voor de complexe steekproefvariantie. Geen uitkomstgestuurde tolerantieverruiming om externe ankers te laten ‘passen’.

**Q01–Q08 als concrete werkpakketten**

| Gate | Op te leveren bewijs |
|---|---|
| Q01 SES-dekking | Land×ronde×construct; gewogen/ongewogen N en missingness; componenten en imputatie; gelijksoortige noemers |
| Q02 populatiekwaliteit | Doelgroep, afname/veldwerk, uitsluiting, school- en leerlingrespons; NL-waarschuwingen in alle relevante producten |
| Q03 vier-cyclusreplicatie | Cobreros-basis 2015/2018/2022/2025, 34 stelsels, 13 gedeelde items; exacte codeversie en vooraf bepaalde toleranties |
| Q04 twee-cyclusreplicatie | 2022/2025, 36 stelsels, 16 gedeelde items; tabellen/figuren en individuele stelselresultaten naast bron |
| Q05 uitbreiding | Vaste parameters naar extra landen/rondes alleen na mapping, overlap, missingness en steun van de items; niet presenteren als exacte oorspronkelijke replicatie |
| Q06 referentie | Historisch bron-snapshot, leden, periode, N en gelijke weging; focusland eruit; expliciete panel- en onzekerheidskeuze |
| Q07 officiële SES | Naast harmonisatie ook de officiële rondegebonden maat; definities, bronrevisies en componentanalyses als robuustheid |
| Q08 verandering | Niveaus, groepsverschillen, veranderingen en verschillen in veranderingen met juiste gezamenlijke variantie/linking; beschrijvend tenzij een causale identificatie bestaat |

De meegeleverde Cobreros-workingpaper is externe literatuur, geen bewijs dat onze eigen pipeline hem reeds repliceert. Zijn conclusies over een internationaal gemiddelde mogen niet rechtstreeks de Nederlandse conclusie worden. Het Nederlandse paper moet bijvoorbeeld verschillen tussen officiële ESCS en de geharmoniseerde maat zelf aantonen, met Nederlandse onzekerheid en dekkingsanalyse.

**Uitvoering in vijf samenhangende werkpakketten**

| Werkpakket | Concrete werkzaamheden | Klaar wanneer |
|---|---|---|
| 1. Bronnen, review en scope vastzetten | Inventaris afronden; besluitconflicten oplossen; bron-/productregister; PR/head en grid vereisten vastzetten; relevante oude output terugvinden | Elke productvereiste heeft een bron, bestemming, methode/status en controle; geen onbewezen scope-uitbreiding |
| 2. Uitvoerroute herstellen | CI-fouten en controller/producer-contract repareren; identiteit en resultaatimport sluiten; moduleadapters afmaken; RStudio-config en opslagroutes testen | Windows/Linux contracttests en synthetic end-to-end slagen; geen productie buiten gekozen grid; gecontroleerd hervatten en hergebruik bewezen |
| 3. Resultaten produceren en onafhankelijk controleren | Eerst NL, dan referentie, dan aanvullende dashboardlanden binnen dezelfde scopes; Q01–Q08 en variantiereparaties; pilot-runtime meten | Alle actieve vereisten gevalideerd of onderbouwd onbeschikbaar; ontbrekende berekenbare resultaten niet weggelabeld; herhaalrun consistent |
| 4. Producten uit dezelfde release bouwen | Dashboard, 21-slide-basis, optionele seminaruitbreiding, paper en technische appendix, figuurdata/downloads | Getallenpariteit tussen producten, visuele controle, toegankelijke bediening, wetenschappelijk controleerbare tekst |
| 5. Replicatie, vrijgave en opslag afronden | Schone reconstructie, README, metadata/licenties/bronrechten, release-archief, publicatievoorstel, gecontroleerde opruimlijst | Onafhankelijke run reproduceert tabellen/figuren/tekstgetallen; definitieve GitHub-release gereed; private tussenresultaten herstelbaar op Drive |

GitHub bevat de codewijzigingen en reviewbare documentatie op de bestaande featurebranch. Geen proliferatie van alternatieve runners of nieuwe grote zip-uitgaven. Bronnen en privé-inventarissen worden niet meegecommit. GitHub Actions controleert synthetische kleine voorbeelden en productcontracten; zware leerlingproductie blijft op de eigen Windows/RStudio-omgeving. Een kleine representatieve pilot bepaalt looptijd, RAM en tijdelijke schijfruimte; vooraf een totale duur beloven zou nu ongefundeerd zijn.

De drie bestaande RStudio-acties blijven `fixed-audit`, `fixed-produce`, `fixed-finalize`, met één constante scope per traject (`nld_only`, `nld_plus_19`, `all_required`). Voor de uitvoering worden de bestaande `START.R`/`RUN.R`-scripts hersteld en getest, niet vervangen door een nieuwe knip-en-plakrunner. De huidige head is nog niet productierijp. Omdat START.R automatisch een branch kan ophalen, moet de uitvoerder vóór het starten aantoonbaar dezelfde gereviewde commit gebruiken en de werkelijk uitgevoerde SHA vastleggen. Een later gewijzigde head mag niet onopgemerkt een goedgekeurde run wijzigen.

**Dashboard en huisstijl**

GitHub Pages is passend voor het bestaande statische dashboard: R produceert vooraf gevalideerde aggregaten; de browser verzorgt selectie en visualisatie. Er is geen noodzaak om via een aparte ChatGPT-websitebouwroute te migreren. De actieve publicatiebron in de repository en de Pages-workflow zijn leidend; de archiefkopie van de oude app is referentie. Serverberekeningen in R draaien niet op Pages. Zie [GitHub Pages-documentatie](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site).

Behoud de geplande landen-, leeftijds-, vak-, uitkomst- en groepskeuzes en een begrijpelijke leesroute. Toon ontbrekende/niet-vergelijkbare cijfers expliciet, met een bruikbare uitleg. Een placeholder is geen nul. Bouw figuurdownloads met dezelfde selectie, labels, precisie, broneditie en status als de grafiek; vergelijk machineleesbare output tegen het grid. Browsertests toetsen NL/EN-pariteit, toetsenbordbediening, mobiel/desktop, lange labels, downloadinhoud en alle route-/filtercombinaties die door de contracten worden toegestaan. Productieschermen bevatten geen interne runpaden of programmeertermen.

Inter Semibold 600 blijft het woordmerk. Oswald Light 300 voor korte labels, Regular 400 voor lopende dashboardtekst, Medium 500 voor koppen en geselecteerde filters. Gebruik de v05-tokens voor achtergrond/tekst/Leerprestaties (#F7F5F0/#17242D/#5365A3) en de originele logo-assets v06. De merkring bepaalt niet automatisch de datakleuren. Wetenschappelijke kleurrollen uit de figuurstijlgids, zoals de Nederlandse focusserie, blijven expliciet gekoppeld aan hun betekenis. Voor slides geldt het 16:9/12-kolomsgrid met vaste marges, panelen, bron- en notenruimte; voor papertekst nemen we de documentregels, niet automatisch smalle dashboardtypografie. Controleer contrast, fontsubstitutie en export.

**Presentaties en paper**

De presentatie van 1 oktober met 21 gekoppelde slides en 48 gekoppelde grafieken is de inhoudelijke basis. Bouw een slide-voor-slide-mapping met huidige figuren, behouden boodschap, noodzakelijke wijziging en resultaat-ID's. Bewaar de originele versie en herstel de foutieve 13-slide-audit. Verwerk de gekozen vervanging van boven-basis door onder-basis, de SES-niveaus naast hun kloof, de optionele high-SES-figuur en lage-prestatiepeers als hoofdmaat. De oude 50-slidevariant vervangt deze presentatie niet. Een wetenschappelijk seminardeck kan dezelfde figuren aanvullen met methoden, sensitiviteit, dekking en replicatie; de lengte volgt de inhoud en het beoogde gebruik.

Het paper krijgt een Nederlandse interpretatie en als werkbasis Nederlandse hoofdtekst: onderzoeksvragen en bijdrage; surveys/populaties; bronselectie; estimator en onzekerheid; nationale trends en verdeling; groepen en SES-constructies; internationale vergelijking; onderwijsomgeving; robuustheid/dekking; beperkingen en conclusie. De technische appendix specificeert iedere recode, weging, PV-/replicaatregel, drempel, panel, missingskeuze en variantieformule. Cijfers in proza komen uit dezelfde export als tabellen en figuren. Een korter beleidsverhaal en langer wetenschappelijk verhaal delen cijfers maar hoeven niet dezelfde tekst te hebben.

De inhoudelijke discussie behandelt ook wat de data niet identificeren: veranderingen in groepen kunnen door samenstelling en meting ontstaan; onderwijsfasen zijn geen gevolgd cohort; schoolscheiding en peerblootstelling tonen geen oorzakelijke effecten; een kleinere kloof door achteruitgang aan de bovenkant is niet zonder meer een verbetering. Literatuur, waaronder ESB, wordt gebruikt voor context en toetsbare mechanismen, niet als vervanging voor projectresultaten.

**Replicatie en FAIR op het beoogde AER-niveau**

Een GitHub-map alleen voldoet niet. Lever een master-run die alle definitieve tabellen, figuren en tekstgetallen reproduceert, met README (ook PDF), softwareversies/lockfile, packagebronnen, hardware, seedbeleid, geschatte looptijd en schijfruimte, data-availability statement, toegangsstappen, licenties, checksums en resultaatmapping. Test dit vanuit een schone omgeving met een andere werkmap dan die van de auteur. Leg afwijkingen/toleranties vast. Maak een versieerbare eindrelease en een duurzaam archiverings-/DOI-voorstel; claim pas reproduceerbaarheid nadat de controle is uitgevoerd. [AEA-richtlijnen](https://www.aeaweb.org/journals/data) en [de AEA-controlepraktijk](https://www.aeaweb.org/journals/data/faq) zijn de norm, geen belofte van acceptatie door een tijdschrift.

FAIR betekent hier vindbare stabiele identifiers en metadata; expliciete toegang tot openbare of beperkte bronnen; machineleesbare tabellen met woordenboek en eenheden; herbruikbare code, herkomst, versie en licenties. FAIR vereist niet dat alle leerlingdata openbaar worden. Maak definitieve toegestane aggregaten/producten publiek, houd microdata/tussenresultaten en lokale padinventarissen buiten de publieke repository. [GO FAIR](https://www.go-fair.org/fair-principles/) biedt het toetsingskader.

**Downloads en gecontroleerd opruimen**

De nieuwe metadata-inventaris bevat 46.020 bestanden, zonder scanerrors of overgeslagen reparsepunten. De bekende projectwerkruimten omvatten 35.292 bestanden/96,788 GB: onderzoeksbronmaster 95,566 GB; LO05-resultaten 0,961 GB; LO02-productie 0,261 GB. Daarnaast zijn 5.707 bestanden op projectnaam en 20 bestanden op R-specifieke extensie kandidaat voor verdere beoordeling. 5.001 bestanden zijn niet toegeschreven. Deze categorieën bewijzen niet dat RStudio elk bestand heeft gemaakt: brondata, scripts, branding en downloads kunnen er ook onder vallen.

Vervolg: koppel paden aan scriptuitvoer, runmanifests en bronregisters; classificeer bron/code/tussenresultaat/eindresultaat/dubbel/onbekend; hash alleen relevante potentiële dubbelen stapsgewijs. Bewaar de volledige inventaris privé. Publiceer alleen samenvattingen. Een bestandsnaam of gelijke grootte is nooit genoeg om iets weg te gooien. Bronbestanden mogen op C: blijven. Drive krijgt onveranderlijke tussenresultaatobjecten met manifest en controle op upload/herstel. GitHub krijgt definitieve, rechtengecontroleerde releasebestanden en hun code.

De repository schrijft voor verwijdering nog twee onafhankelijke herstelbare kopieën buiten C:, een quarantaineperiode van 30 dagen en een expliciet beoordeelde bestandslijst voor. Het huidige opslagbesluit autoriseert de bestemming, maar bewijst deze herstelbaarheid nog niet. Het uitvoerplan maakt eerst concreet welke objecten hieraan voldoen; uniek werk en onduidelijke bestanden blijven bewaard. Geen automatische verwijdering vanuit een gewone analyse- of publicatierun.

**Vijf opdrachten aan Codex**

1. **Rond de kritische audit en scope af.** Werk dit plan in GitHub uit tot één bron-, besluit-, product- en risicoregister. Controleer alle actieve claims tegen de zip, actuele code, primaire methoden en oorspronkelijke resultaten. Corrigeer aantoonbare eerdere fouten, inclusief de onjuiste slidetelling. Koppel iedere vereiste aan het grid en inventariseer Downloads met expliciete bewijskracht. Bewaar mijn opslagverdeling: bronnen op C:, tussenresultaten op Drive, definitieve resultaten op GitHub.
2. **Maak de bestaande RStudio-route werkelijk uitvoerbaar.** Herstel de controller, producenten en validatie, sluit alle noodzakelijke modules aan op het grid, maak de minimale hervatbare rekenplanning en test op Windows/Linux. Behoud START.R met fixed-audit, fixed-produce en fixed-finalize. Lever pas daarna exacte geteste RStudio-instructies met commit, scope, configuratie en ruimtevereisten.
3. **Produceer en valideer de resultaten.** Hergebruik aantoonbaar juiste bestaande resultaten, voer uitsluitend ontbrekende noodzakelijke batches uit en sluit Q01–Q08. Begin met Nederland, breid via de vastgelegde scopes uit en controleer PV's, replicatie, covariantie, SES, populatie en panels onafhankelijk. Lever één versieerbare resultaatrelease met volledige herkomst en onderbouwde beschikbaarheidsstatussen.
4. **Bouw de producten uit diezelfde resultaatrelease.** Voltooi het bestaande GitHub Pages-dashboard volgens het dashboardplan en de nieuwste Kansenlab-stijl; maak het definitieve presentatiedek vanuit de 21-slideversie van 1 oktober, het Nederlandse paper met volledige methoden en desgewenst het uitgebreide wetenschappelijke deck. Gebruik statistisch en visueel grid, controleer elke figuur en ieder tekstgetal, en lever bewerkbare bronnen plus exports.
5. **Maak replicatie, publicatie en opslag af.** Voer een schone onafhankelijke replicatie uit volgens het AEA/FAIR-toetsingskader, maak de definitieve GitHub-release en een concreet publicatievoorstel, verifieer de Drive-opslag en werk de opruimlijst af zodra herstelbaarheid en de overeengekomen verwijdervoorwaarden zijn aangetoond. Verwijder niets uitsluitend omdat het oud, dubbel genoemd of opnieuw te downloaden lijkt.

**Acceptatie van het geheel.** Geen product heeft eigen afwijkende cijfers; ieder getal is herleidbaar; de uitvoerroute is getest en hervatbaar; geen ongetoetste resultaatrij krijgt een wetenschappelijk vrijgavestempel; onbeschikbaarheid is onderbouwd; de 21-slidebasis en nieuwste huisstijl zijn gerespecteerd; de resultaten zijn reproduceerbaar uit een schone omgeving; de opslag volgt het actuele gebruikersbesluit. Het vervolg mag dit plan aanscherpen op bewijs, maar een andere chat neemt de regie niet automatisch over.


## 16. Vergelijking met de nagezonden chat en aanvullend lokaal bewijs


De onafhankelijke basis is vastgelegd op 13 oktober 2026 om 18:36:30 UTC, met SHA256 `ccdac2d9a441c1d3cf4c056b1669e6a7b8d00a0a805c5c890a9b3a0f248a6222`. Pas daarna is de nieuwe chat gelezen. De vijf werkpakketten blijven staan. Dit verslag voegt controleerbare aanvullingen toe en corrigeert onjuiste aannamen uit die chat.

| Onderwerp uit de chat | Beoordeling | Doorwerking |
|---|---|---|
| Eén eenvoudig te starten programma dat alles kan produceren | De gebruikerswens is duidelijk en terecht. De huidige modules moeten worden afgemaakt en geïntegreerd | Eén toegang via START.R; controles, hervatten en minimale taakselectie binnen het programma. De drie bestaande acties kunnen als expliciete fasen blijven bestaan; geen telkens nieuw handmatig commando per diagnose |
| Prioriteit werkende code, geen eindeloze planning | Overnemen als uitvoeringsregel | Dit is de consolidatie van het plan. De volgende substantiële uitvoerfase levert code, tests en een echte beperkte productietest, geen nieuw masterplan |
| Het deck bevat aantoonbaar slechts 13 slides | Onjuist | De presentatievolgorde verwijst naar 21 bestaande slides; 48 grafieken zijn gekoppeld. De eerdere teller miste `v8_slide*.xml`. Niet naar een ontbrekende 21-slideversie zoeken of acht slides erbij verzinnen |
| De notitie van 16 pagina's ontbreekt of heeft mogelijk andere paginering | Inmiddels opgelost met lokaal bewijs | Downloads bevat de echte 28-septembernotitie met 16 pagina's en exact de geregistreerde hash. De zip bevat de versie van 27 september met 15 pagina's. Pagina 16 is een inhoudelijke completion-update, geen louter opmaakverschil |
| LO05_RESULTATEN is circa 40 GB | Niet bevestigd door de nieuwe meting | LO05_RESULTATEN is nu 961.405.674 bytes (0,961 GB). De master-submap RUNNER is 39.150.330.148 bytes. Dit kan de verwarring verklaren, maar is geen bewezen verklaring van wat eerder zichtbaar was |
| De compacte resultaatgrid kan klein zijn | Bevestigd met echte bronbytes, niet met fictieve waarden | De bestaande matrix is 32.166.066 bytes en 2.334.636 bytes met gzip, zonder numerieke afronding. Dit is géén meting van de toekomstige complete grid: de matrix bevat veel placeholders |
| Scores/percentages één decimaal; SE twee decimalen; N geheel | Bruikbare presentatiekeuze | Volledige precisie blijft in de wetenschappelijke basis en reproduceerbare downloads. Alleen weergave afronden, na contrasten/CI/rangen; vermeld percentage versus procentpunt expliciet |
| Alle oude bestanden wissen en opnieuw beginnen | Afwijzen als uitvoeringsmethode | Unieke bron-, resultaat- en variantie-informatie kan verloren gaan en onnodige herberekening veroorzaken. Het actuele directe gebruikersbesluit laat bronbestanden op C: toe |
| Een execute-blokkade is uitsluitend technische complexiteit | Te algemeen | De gevonden aanroepfout is technisch. Onjuiste steekproefdefinities, ontbrekende bronnen of covariantie zijn inhoudelijke problemen. Het programma moet die onderscheiden en de overige geldige taken laten doorgaan |
| Binnenkort alles snel klaar | Niet onderbouwd | Een kleine echte pilot meet capaciteit en looptijd. Programmeerwerk, benodigde bronreparatie en rekentijd apart rapporteren |
| Harde aantallen 50 seminardias en 16 pagina's in het eindproduct | Historische bronversies zijn daadwerkelijk 50/16; niet automatisch een nieuwe omvangseis | De huidige vraag noemt het lange deck optioneel en vraagt een volledig paper. Behoud de historische inhoud en traceerbare wijzigingen; forceer het nieuwe paper niet naar precies 16 pagina's |

**Aanvullend lokaal bronbewijs na de chatvergelijking.**

- De PDF `PISA_PIRLS_TIMSS_FINAL_WETENSCHAPPELIJKE_NOTITIE_20260928.pdf` heeft 16 pagina's; SHA256 `be3b9ba0b9b4e5bdeb428695919dd46d521e32ddd64fc3e31eca55392a91ba27`.
- De PDF `PISA_PIRLS_TIMSS_FINAL_WETENSCHAPPELIJK_DECK_20260928.pdf` heeft 50 slides; SHA256 `b6e4ed6fe21ba5e0e764a1a2656722776d4a6539da8ffd79915fc670d4054dc4`.
- Pagina 16 van de notitie rapporteert 283.284 schattingsregels en 2.569 van 2.570 completiontaken, en meldt reparaties aan PIRLS-corevarianties, historisch PISA-gender, TIMSS 1995 en Numeracy. Dit is een bronclaim die op de bestaande completion-output moet worden gematcht, geen reden om de reparaties klakkeloos opnieuw uit te voeren of ongezien vrij te geven. Eerdere hoofdstukken bevatten nog oude beperkingen; die inhoudelijke inconsistentie moet worden gereconcilieerd.
- Alle zes RDS-objecten uit de zip zijn succesvol gelezen voor structuur, tabellen en kolommen. R meldde locale-/encodingwaarschuwingen; die zijn geen validatie van de cijfers. De bestanden bevatten nuttige bestaande estimate-, PV- en diagnostiektabellen die hergebruikonderzoek ondersteunen.

**Verduidelijking van de minimale opslag.** Een resultatenmatrix is slechts een deel van het replicatiepakket. Gezamenlijke replicaatschattingen/covariantiematrices, methodeparameters, herkomst, tabellen en exportassets kunnen extra ruimte vragen. Bewaar hiervan de noodzakelijke compacte voldoende informatie, met een gedocumenteerd bewaarbeleid. Een dashboarddoel van bijvoorbeeld minder dan 10 MB mag wetenschappelijk noodzakelijke informatie niet wegdrukken. Er is in deze ronde niets verwijderd en geen grote wetenschappelijke productierun gestart.

**De uiteindelijke route.** Bronnen op C:, private tussenresultaten op Google Drive, definitieve toegestane resultaten en code op GitHub. Het eigen plan wordt geïntegreerd in het bestaande GitHub-masterplan. De auditfouten worden daarin gecorrigeerd; de uitvoeringsvolgorde blijft bronidentiteit → werkende geïntegreerde pipeline → gecontroleerde resultaten → producten → replicatie/vrijgave/opslag. Ruimtebeheer en het voorkomen van onnodige kopieën lopen vanaf het eerste werkpakket mee.

## 15. Implementatiestand 13 oktober — één compacte nieuwe producer, geen nieuwe scopebesluiten

Deze sectie registreert **uitgevoerde codewijzigingen**, geen wetenschappelijke vrijgave. De op 12–13 oktober gekozen figuurrollen en het bestaande 1/20/50-scopecontract blijven leidend. De oorspronkelijke 79.448 taken en 138 figuurcontracten blijven onveranderd; de actieve oorspronkelijke selectie omvat aantoonbaar 64.837 posities, met een afzonderlijke nieuwe onder-basis-peermeting. Het gebruikersleidende beleidsdeck met correcte bronhash heeft 21 fysieke slides.

- `LO_COMPACT_GRID_STORE.R`: één SQLite-current-ledger met unieke wetenschappelijke resultaatcel, volledige **estimate**, **standard_error**, exact ongewogen **N**, meeteenheid, input- en codefingerprint, methode-ID en controle-/HOLD-status. Daarnaast twee kleine gzip-CSVs: volledige interne precisie en een **uitsluitend voor weergave afgeronde** export (scores/percentages 1 decimaal, SE 2); `unit=proportion` wordt alleen in de presentatie naar procent omgezet. Geen leerlingrows, replicatematrices, telkens volledige databasehistorie of grote snapshotzips in deze nieuwe opslag.
- `LO_COMPACT_RECOMPUTE.R`: berekeningen per vaste `survey × year × country`-bronbatch; producten buiten actieve figuurselectie overgeslagen, landresultaten slechts eenmaal; broncacheverificatie leest potentiële dubbele RDS opeenvolgend in plaats van allemaal tegelijk; per taak herstart/hergebruik uitsluitend met exact dezelfde huidige input-, code- en methodfingerprint. Wetenschappelijke code berust op de gepinde V11/LO04-bron en bestaande PV-/replicatefuncties, niet op een nieuw geïmproviseerd standaardfoutrecept.
- Nieuwe metingen: peeraandeel **onder basisniveau**, met self-exclusion en afzonderlijke directe-/schoolomgeving; voor migratiegeneraties worden de gepinde PV/replicate-demografie-estimators gekoppeld; migratiepeers hebben correcte bron-groepdenominatoren en surveyreplicates. Het oorspronkelijke `MIGRATION_ANY_PARENT_ABROAD` wordt voor berekening/projection expliciet vertaald naar de bestaande `nl_one_parent_abroad`-functie, terwijl de contractuele cel-ID ongewijzigd blijft.
- Nog niet wetenschappelijk gedekte methoden, Cobreros-specificaties zonder juiste reconstructie, ontbrekende canonieke bronnen, tegenstrijdige cacheprojections en onvolledige PV/SE/N leveren expliciet **HOLD** in plaats van verzonnen uitkomsten. `COMPUTED_PENDING_VALIDATION` is uitdrukkelijk geen `SCIENTIFICALLY_VALIDATED`.
- `LO_FIXED_PRODUCERS.R` gebruikt voor de bestaande actie `fixed-produce` nu standaard de compacte kandidaatproducer. De oudere LO05-engine wordt niet automatisch opgestart om volledige resultatenregisters/snapshots te kopiëren. De vaste gebruikersactie blijft `START.R` met `LO_START_ACTION=fixed-audit|fixed-produce|fixed-finalize`. Geen nieuwe reguliere stage toegevoegd.
- Windows/Linux CI is uitgebreid met parsercontrole en synthetische tests voor SQLite-idempotentie, volledige precisie versus displayafronding, bronwijzigingen, ontbrekende N/SE, nieuwe peerdefinitie en migratiegroep-N. De definitieve status van de meest recente CI-commit wordt via GitHub Actions vastgesteld; een groene synthetische CI is geen daadwerkelijke RStudio-run op de originele microdata.

**Nog verplicht voordat een nieuwe wetenschappelijke release mogelijk is:** volledige Windows-local `fixed-audit` en `fixed-produce` met de exacte gepinde bronbundel; module-/wave-specifieke officiële OECD/IEA-benchmarkcontroles, Q01–Q08, goedgekeurde Cobreros- en speciale cohort/migratie-/taalmethoden, en per figuur volledige productpariteit, waarna pas `fixed-finalize`. Een compacte kandidaatdatabase wordt niet automatisch als definitieve `SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv` gepubliceerd. De laatste C:-schijfmetingen van LO05 en oude archieven zijn nog niet opnieuw lokaal vastgesteld, en er is niets verwijderd. Opruiming blijft separaat en veiligheidsgegate.


## 18. Afgeronde kritische bron-, scope- en bewijsaudit (13 oktober 2026)

De actuele audit staat in [AUDIT_CLOSURE_20261013.md](review_20261013/AUDIT_CLOSURE_20261013.md), met 247 productvereisten, expliciete gridafhankelijkheden en SHA-gecontroleerde bronpariteit. De originele PPP-2024-snapshot is teruggevonden en de strikte 19-landenreferentie numeriek bevestigd. De 50-systemenscope omvat 70.633 historische cellen en 9.198 afzonderlijke nieuwe lage-peer-cellen. Een exact archiefmatch is geen vrijgave: 19.050 huidige cellen hebben kandidaten; 11.192 hebben tevens bronhash- en schatting/SE-pariteit; nul zijn door deze audit zelfstandig wetenschappelijk gecertificeerd. Aanvullende inhoudelijke eisen en Q01–Q08 blijven zichtbaar. De compacte producer blijft behouden maar de vaste productiestap blokkeert zolang de adapter de goedgekeurde individuele gridcellen niet consumeert. Geen brede pupilrun, verwijdering of publieke productrelease is uitgevoerd.


