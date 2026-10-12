# PISA/PIRLS/TIMSS — integraal masterplan en besluitregister

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

