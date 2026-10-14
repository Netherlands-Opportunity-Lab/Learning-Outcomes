# Kritische audit — bron, scope, producten en bewijs

De kritische audit is afgerond als inventarisatie, bronreconciliatie en beoordeling van bestaand bewijs. De wetenschappelijke vrijgave is **niet** verleend. Iedere geïnventariseerde productvereiste heeft een expliciete afhankelijkheid van het historische resultaatgrid, nieuwe peer-cellen of een aanvullende specificatie. Een aanvullende specificatie is zichtbaar werk dat nog moet worden uitgewerkt; zij telt niet als een gevuld of goedgekeurd resultaat.

De audit begon op commit `24f9202ed4e176ce9da8f84e34e3e2274b63a566`. Voor integratie zijn ook de inmiddels toegevoegde compacte productiescripts op `c4075497d4babe512e81f91306a718568bf54dd7` beoordeeld. Bronbestanden zijn alleen gelezen. Er is geen pupilberekening, publicatie, verhuizing of opschoning uitgevoerd.

## Wat nu aan het grid is gekoppeld

`PRODUCT_REQUIREMENTS.json` bevat **247 vereisten**: alle 21 beleidsslides, 50 wetenschappelijke slides, 17 hoofdstukken en de finale update van de notitie, 138 historische dashboardfiguren, Q01–Q08, zes empirische paper-exhibits, de resultaatproductie en vijf productoverstijgende eisen. De langere wetenschappelijke presentatie blijft een optioneel product; wanneer zij wordt gemaakt, blijven haar eigen inhoudelijke vereisten behouden.

- `PRODUCT_GRID_REQUIREMENTS.csv`: per vereiste de bronlocatie, scope, rol en aantallen cellen met verschillende soorten bewijs.
- `PRODUCT_GRID_DEPENDENCIES.csv`: product → figuur of aanvullende specificatie, inclusief de nieuwe primaire peer-cellen.
- `DERIVED_FIGURE_DEPENDENCIES.csv`: kloven, spreiding, complementen en rangen met expliciete bronfiguren; onzekerheid vereist waar nodig gezamenlijke PV/replicatie of covariantie.
- `FIGURE_SCOPE_EVIDENCE.csv`: alle 138 figuren afzonderlijk voor de drie scopes. Een oude figuurtitel of standaardreferentie wordt niet stilzwijgend een nieuwe wetenschappelijke definitie.
- `SUPPLEMENTAL_RESULT_REQUIREMENTS.csv`: 28 aanvullende afhankelijkheden, waaronder één redactionele titel zonder schatting. Deze lijst onderscheidt inhoudelijke resultaten, methodetoetsen en productkwaliteit.

De volledige koppeling product → individuele cel staat lokaal in `PRIVATE_PRODUCT_CELL_LINKS.csv`. De nieuwe lage-peer-cellen staan afzonderlijk in `PRIVATE_NEW_LOW_PEER_GRID.csv`. Beide worden niet als ongetoetste bulk naar publiek GitHub gekopieerd.

## Vastgestelde scope

| Scope | Stelsels | Historische cellen | Actieve historische cellen | Nieuwe lage-peer-cellen |
|---|---:|---:|---:|---:|
| Nederland | 1 | 1.867 | 1.529 | 240 |
| Nederland + vaste referentie | 20 | 29.846 | 24.355 | 3.954 |
| Alle benodigde stelsels | 50 | 70.633 | 57.690 | 9.198 |

De oorspronkelijke **79.448 sleutels in 91 stelsels** blijven als historisch contract bestaan. Zij zijn geen juiste werkvoorraad voor het huidige dashboard. De website heeft 42 selecteerbare stelsels; acht extra stelsels zijn nodig voor de vaste referentie. De 57.690 actieve historische cellen omvatten ook historische afleidbare uitkomsten: dit is uitdrukkelijk geen aantal zelfstandige pupilberekeningen. Met de nieuwe lage-peer-cellen zijn 66.888 actieve doelcellen gespecificeerd voor de 50-systemenscope, vóór verdere aanvullende uitkomsten. Ontbrekende uitbreidingen mogen niet als nul worden geteld.

De primaire peermaat wordt het aandeel peers onder de eigen prestatiedrempel. Historische hoge-peer-resultaten kunnen die cellen niet vullen. PISA onder niveau 2 en IEA onder intermediate 475 blijven afzonderlijke definities. De directe leeromgeving en de gehele school blijven afzonderlijke eenheden. Zelfuitsluiting en gezamenlijke PV/replicatie zijn vrijgavevoorwaarden.

De officiële PISA-SES, de viergolfs Cobreros-SES en boekenkwartielen zijn afzonderlijke constructen. Vooral de oorspronkelijke beleidsslides 4–6 kunnen niet uitsluitend met het bestaande PISA-harmonisatiegrid worden afgedekt. Daarom is officiële PISA-SES expliciet toegevoegd. Ook SES × gender, officiële IEA Home SES, vier taalgebruikscategorieën, absolute internationale SES, school-/klassensortering, Theil H, cohortcontext en de oude brede/kwaliteits-panels staan apart geregistreerd.

## Herstelde bronfouten

1. **Beleidsdeck:** de leidende versie met 20261001 heeft 21 slides en 48 gekoppelde grafieken. De presentatie-relaties zijn gecontroleerd, inclusief de niet-standaard benoemde slidebestanden. Een telling op alleen `slide1.xml`, `slide2.xml`, enzovoort is onjuist. Het bronhash blijft `cea8dc8a42c3e63e435c16ef13ea6cc1b634f5ca4d95af8c29dafba7397631ac`.
2. **Wetenschappelijke bronnen:** de finale notitie van 28 september heeft 16 pagina's; de oudere bron in de zip heeft 15. Het seminar heeft 50 slides. De finale update heeft chronologische prioriteit, maar lost tegenstrijdige SE-teksten niet op zonder koppeling aan de concrete gerepareerde records. Seminar-slide 6 bevat de oude core-SE-hold; slide 49 bevat juist een finale update met resterende lokale holds.
3. **PPP-bron teruggevonden:** het oorspronkelijke bestand `WB_NY.GDP.PCAP.PP.CD_2024_raw.json` is aanwezig in twee lokale LO01-bronpakketten. Beide hebben SHA256 `0d21bdc1cc3070a632d09a76620dab0c971ba1c7053a95027b7f685f43db5df3`. De bewaarde bronupdate is 13 juli 2026; er is geen nieuwe WDI-revisie gedownload. Alle 38 waarden in het lidmaatschapsextract stemmen overeen. Tsjechië heeft 57.625,0961715706 PPP-dollar per inwoner. **Strikt groter dan**, niet groter dan of gelijk aan, levert precies Nederland en de 19 vastgelegde buitenlandse referentielanden op. Zie `VERIFIED_PPP_MEMBERSHIP_2024.csv` en `RECOVERED_REFERENCE_SOURCE_AUDIT.json`. De originele OECD-HTML ontbreekt; het bewaarde lidmaatschapsextract bevat wel toetredingsdatums. Panelbeschikbaarheid per uitkomst en Q06 blijven afzonderlijke toetsen.
4. **Historische vergelijkingsgroepen:** de standaard `OECD_HIGH_INCOME_FY2027` in alle 138 oude figuurcontracten is geen PPP-2024-definitie. De effectieve nieuwe scope staat er nu naast. De oorspronkelijke 31-, 13/32-, 45- en 46/48/49-panels behouden hun eigen bronidentiteit en mogen niet onzichtbaar in de PPP-referentie veranderen.
5. **Opslag:** bronnen mogen op C: blijven, tussenresultaten gaan naar private Google Drive en definitieve, vrijgegeven resultaten naar GitHub. Het projectbestandsoverzicht is metadata-bewijs; het bewijst niet dat ieder bestand door RStudio is gemaakt of mag worden verwijderd. De gemeten mastermap telt 35.087 bestanden en 95.566.093.858 bytes.

## Wat bestaand resultaatbewijs daadwerkelijk aantoont

| Huidige 50-systemenscope | Aantal unieke historische cellen |
|---|---:|
| Exacte kandidaat in LO01, LO02 of de geïnspecteerde centrale `results_v4` | 19.050 |
| Minstens één kandidaat met eindige schatting en niet-negatieve SE | 18.775 |
| LO01-bronbestand SHA klopt én bronrij reproduceert schatting en eindige SE | 11.192 |
| Door deze audit wetenschappelijk goedgekeurd | **0** |

Voor Nederland zijn deze aantallen respectievelijk **494, 473 en 363**. Dit zijn oplopende bewijscategorieën, geen vrijgavepercentages. Numerieke bronpariteit controleert het gearchiveerde bronpayload; bij een geregistreerde transformatie moet daarna de afgeleide doelcel afzonderlijk worden gecontroleerd.

Over het gehele LO01-archief zijn 16.767 rijverwijzingen onderzocht: bij 14.460 klopt het huidige bronbestandhash, bij 13.467 de teruggevonden schatting en bij 12.364 tegelijk het hash, de schatting en de eindige SE. Afwijkingen kunnen voortkomen uit een andere bronversie, gewijzigde rijverwijzing, geregistreerde transformatie of ontbrekende SE. Er wordt geen recentste waarde als winnaar gekozen. De private ontvangstbewijzen leggen de afzonderlijke controles vast.

De centrale SQLite bevat **59.822 resultaatversies voor 55.915 sleutels**, waarvan 58.838 versies een eindige schatting en SE hebben. De oude auditcode sloeg de tabel `results_v4` geheel over; dat is hersteld. Alle 59.822 rijen koppelen aan een specificatie, maar slechts 7.814 aan een geregistreerd taakbestand. `dependencies_v4` is leeg. De 9.691 productrelaties noemen alleen het generieke `DECK_CURRENT`, zonder bewezen koppeling aan de actuele 21 slides. Geen van de 59.822 input-fingerprints heeft SHA256-formaat: de ingevulde historische omvang/tijd-signatures vormen geen geverifieerde inputhashes. De eerdere samenvatting “complete fingerprints” is dus onvoldoende en mag niet als kwaliteitsgoedkeuring worden gebruikt.

In het gehele historische grid verschillen bij **811 sleutels** eindige schatting/SE-paren tussen exacte archiefkandidaten. Dat is een signaal voor versie- en methodereconciliatie, niet automatisch een statistische fout. Bij 59.036 historische sleutels is geen exacte match in deze drie bronnen gevonden. V8/V9, oudere reparatie-output, officiële tabellen en anders gedefinieerde V11-records kunnen aanvullende kandidaten bevatten; daarom is geen enkele ontbrekende match automatisch vrijgegeven voor herberekening.

De labels `VALIDATED`, `AVAILABLE_POINT`, `REUSE` of `COMPUTED_PENDING_VALIDATION` zijn geïnventariseerd, niet overgenomen als onafhankelijk oordeel. N, populatie, broneditie, methode, drempel, gewichten, PV's, replicatie, producerhash, inputhash en numerieke toetsing moeten op dezelfde resultaatversie aansluiten. Bestaande officiële tabelcellen verdienen een eigen bronceltoets; zij hoeven niet automatisch opnieuw uit microdata te worden geschat.

## Codeherstel en open productiegrens

- De bewijsaudit leest nu `results_v4`, behoudt de versie- en current-status en onderscheidt SHA256 van omvang/tijd-signatures. Grote historische fingerprintteksten worden niet uit iedere back-up in het werkgeheugen gekopieerd.
- De kwaliteitstoets kan ook rapporteren wanneer nul nieuwe-peer-cellen of nul actieve cellen ontbreken. De eerdere R-fout met een tabel van nul versus één rij is verholpen.
- De finale toets gebruikt nu de exacte grid-/broneditie-/designcontrole in plaats van alleen een schema met cell-ID en waarden. Negatieve standaardfouten worden geweigerd.
- De nieuwe compacte producer op de bijgewerkte branch accepteert wel `grid`, maar geeft die goedgekeurde cellen niet door: `lo_compact_run` bouwt zelf alle actieve taken en nieuwe peers op. Daarom staat een gerichte blokkade vóór uitvoering. De compacte implementatie is behouden; zij moet eerst uitsluitend gecertificeerde cellen verwerken en bijbehorende input-/produceridentiteiten opnieuw controleren. Dit is een concrete resterende reparatie voor de productiestap, geen verzoek om alvast een brede R-run te starten.

## Vervolgvolgorde en acceptatie

1. Herstel de exacte celsturing en maak van ontbrekende aanvullende specificaties toetsbare celcontracten. Onderhoud de historische cellen en afgeleide afhankelijkheden afzonderlijk.
2. Reconcilieer eerst de 811 versieverschillen en de bronrij-/hashafwijkingen; zoek daarna overige oudere reparaties en officiële broncellen. Beoordeel echte hergebruikbaarheid voordat een rekenopdracht ontstaat.
3. Certificeer methode en input per module/survey/broneditie; sluit Q01–Q08. Schat uitsluitend het daarna nog aantoonbaar ontbrekende werk in de bestaande `fixed-produce`-stap.
4. Laat dashboard, slides en paper exact dezelfde vrijgegeven gridversie gebruiken. Toets taalpariteit, exportpariteit, bronnoten, Nederlandse interpretatie, laatste huisstijl, logo's, toegankelijkheid en het presentatiegrid.
5. Pas na reproduceerbare vrijgave volgen definitieve GitHub-producten en private Drive-overdracht. Opschoning blijft afhankelijk van actuele bron- en productafhankelijkheden en geverifieerd herstel.

De audit vereist nu geen handmatige R-productierun van de gebruiker. De volgende actie is het repareren en certificeren van de uitvoerbare celsturing met de gevonden bewijshiaten als acceptatievoorwaarden.

## Reproduceerbare controle

`PRODUCT_EVIDENCE_AUDIT.py` gebruikt alleen de Python-standaardbibliotheek en accepteert expliciete paden. `--bundle` wijst naar het uitgepakte bronpakket; `--registry` naar de lokale centrale aggregate SQLite; `--verify-lo01-sources` controleert de expliciete LO01-bronverwijzingen; `--reference-raw` toetst de teruggevonden oorspronkelijke WDI-snapshot. `--out` moet een lokale/private rapportmap zijn. De definitie- en bronhashes staan in `SOURCE_MANIFEST.csv`.

Het script voert geen R-estimator uit en maakt geen productieprotocol naast `fixed-audit`, `fixed-produce`, `fixed-finalize`. De synthetische tests controleren onder meer onjuiste scopeleden bij gelijke aantallen, ontbrekende SE's, foutieve bronhashes, afzonderlijke lage-peer-identiteiten, nul ontbrekende cellen en verwisselde doelcontracten. De definitieve CI-uitkomsten zijn gekoppeld aan de commit in PR #5; een geslaagde softwaretest verleent geen wetenschappelijke vrijgave.
