# Minimaal resterende berekeningen — audit van de volledige figuurscope (13 oktober 2026)

**Status: bron- en contractaudit gereed; het exacte aantal nieuwe leerlingberekeningen is NIET bewezen.** Dit is een minimum-reken*planning*, geen toestemming om ongevalideerde kandidaten te hergebruiken of massaal opnieuw te rekenen.

## Controlling sources

- Vastgepinde `LEARNING_OUTCOMES_INTEGRAAL_v2_20261010.zip` binnen `PISA_LEARNING_OUTCOMES_VOLLEDIGE_OVERDRACHT_20261011_v1.zip`, met `engine/TASKS.csv`, `FIGURE_SERIES_CONTRACT_20261002.csv`, `evidence/LO01_HISTORICAL_CANDIDATES.csv.gz`, `evidence/LO02_RETURN_20261010_CURRENT_RESULTS.csv.gz`.
- Gebruikersbesluiten 12 oktober 2026 in `FIGURE_ACTIVE_DECISIONS_20261012.csv`. De 21-slide gebruikers-PowerPoint blijft leidend.
- Bestaande productieaudit 12 oktober: 40 nieuw berekende Nederlandse PISA core/gender-records, 0 native hergebruikt, 1.827 NL HOLD; `LO02_EXPORT_STATUS.csv` vindt wegens ontbrekende SQLite-run-ID nog geen individuele exacte runmatch.
- Deze telling is rechtstreeks berekend uit volledige originele CSV-rijen, niet uit aantallen in een oudere chat.

## Feitelijke voorselectie (geen gelijkstelling met nieuwe berekening)

| Contractcategorie | Aantal |
|---|---:|
| Alle oorspronkelijke `engine/TASKS.csv` contracten | 79.448 |
| Unieke `LO01_HISTORICAL_CANDIDATES` metric_keys | 16.767 |
| Unieke `LO02_RETURN_CURRENT_RESULTS` metric_keys | 3.486 |
| Overlap van beide archieven | 947 |
| Union met ten minste een archiefkandidaat | 19.306 |
| Zonder LO01/LO02 archiefmatch | 60.142 |
| Figuur-ID's met inputcontracten | 132 |
| Afgeleide rangfiguren zonder eigen inputcontract | 6 |
| Totaal figurenregister | 138 |

Elke archiefmatch betekent hooguit `VALIDATE_CANDIDATE`: geen automatisch `REUSE_VERIFIED`. Voor 60.142 ontbreekt uitsluitend een match in deze TWEE registers; centrale historische/current SQLite, Parquet, V8/V9/V11 en andere lokaal verifieerbare resultaten zijn nog niet volledig geadjudiceerd. Dit is absoluut **niet** het aantal nog te berekenen leerlingresultaten.

## Productbesluiten als concrete reductie/uitbreiding

| Onderdeel | Oude taakposities | Actuele beslisregel |
|---|---:|---|
| `TR_BASIC` (op/over basisniveau, afzonderlijk) | 1.735 | Als apart figuur schrappen; complement van de 1.735 `TR_BELOW`-posities; exact dezelfde scoregrens, onzekerheid spiegelen |
| `GP_SES_HIGH` | 2.466 | Alleen optionele appendix/robuustheid, niet eerst berekenen |
| `EN_PERFORMANCE_PEER` met **hoge peers** | 10.410 | Oude `high_peer_raw_sample` is een *andere* maat; uitsluitend optionele high/advanced robustness |
| Oorspronkelijke nog actieve taakposities na bovenstaande productprioriteit | **64.837** | Nog geen nieuwe berekeningen; inclusief al aanwezige kandidaten |
| Daarvan met LO01/LO02-kandidaat | **13.520** | Eerst inhoudelijk valideren/hergebruiken |
| Daarvan zonder LO01/LO02-kandidaat | **51.317** | Zoek oudere/canonieke caches vóór herberekening |
| Puntcontrasten/spreads in actieve scope: `DS_SPREAD`, SES-, gender-, taal- en migratiegap | **13.378** | Schatting afleidbaar uit juiste groepsniveaus/percentielen; SE vereist covariantie of gezamenlijke PV/replicate estimates, dus niet automatisch 'gratis' |
| Nieuwe hoofdmaat **aandeel peers onder basisniveau** | **3.470 leeromgevingscontexten**, ten hoogste **10.410 conceptuele cellen** bij total/zelf onder/zelf op-of-boven | **Niet aanwezig als aparte uitkomst in de oude 79.448**; vereiste definitie, toelaatbare leeromgeving, scoregrens en beschikbaarheid van oude raw/intermediate peerdata controleren. Niet verward met high peers. |
| Theoretische gecombineerde actieve taakslots vóór hergebruik en methodesluiting | **75.247** (64.837 + 10.410) | *Omvang ontwerpscope*, **NIET** 75.247 te berekenen nieuwe resultaten. Feitelijke benodigde taken kunnen aanzienlijk minder zijn. |

Let op: de 10.410 nieuwe peer-cellen zijn een **bovengrens voor de volledige oorspronkelijke land×wave×domein×omgeving-universum** als de gewenste lage-basissplit driemaal per context wordt opgebouwd. De empirisch toelaatbare steekproeven, surveys en variabelen moeten eerst worden gecontroleerd. Andere wetenschappelijke uitbreidingen buiten de oude taakbasis (Q01–Q08, absolute versus relatieve SES, cross-age, sorting, SES×gender) dienen een eigen aanvullende requirement-status te behouden en kunnen niet verantwoord op nul worden gezet.

## Taakverdeling — oorspronkelijke 22 resultaatfamilies

Voor exacte aantallen per familie, bekend historisch archief en NL-dekking zie `FIGURE_ARCHIVE_COVERAGE_BASELINE_20261013.csv`. Enkele grote niet-gematchte blokken:

- Migratiegemiddelden: 12.145 oude contracten; 0 match in LO01/LO02.
- Migratiecontrasten: 6.940; 0 archiefmatch, in principe afgeleid uit groepsniveaus mits correcte covariantie.
- Migratie-peers: 9.228; 0 archiefmatch.
- Taalgroep-gemiddelden: 3.470; 74 archiefmatches.
- Taal-peer-exposure: 3.076; 20 archiefmatches.
- Directe hoogpresterende-peers: 10.410; 3.800 archiefmatches, **optionele** oude maat.
- Gemiddelde scores: 1.735; 1.707 archiefmatches; hoogste hergebruikpotentieel.
- Hoge-scoreaandeel: 1.735; 1.596 archiefmatches.
- Low/basic SES: 2.466; 1.462 archiefmatches; historische definitie op/boven drempel is complementair aan de nieuwe onder-drempel figuur.

## Beslisregel per werkelijk benodigde leerlingberekening

Een taak wordt pas `COMPUTE_REQUIRED` als (1) hij nodig is voor een **actief** figuur/paper/dashboard/Q-gate; (2) hij niet zuiver uit andere wetenschappelijk gecontroleerde resultaten inclusief relevante covariance kan worden afgeleid; (3) er geen gevalideerde exact overeenkomende resultaatversie in centrale/current/history SQLite, LO01/LO02 of V8/V9/V11/Parquet bestaat; (4) complete source edition, populatie, groepsdefinitie, peeromgeving, PV/weights/design/linking en uitvoerbare wetenschappelijke methode beschikbaar en goedgekeurd zijn; en (5) de module een geteste hergebruikte taak-fingerprint/resumable productieroute heeft.

Anders `REUSE_CANDIDATE`, `DERIVE_PENDING_VARIANCE`, `SEARCH_OLDER_CACHE`, `HOLD_UNVALIDATED_METHOD` of `NOT_REQUIRED_BY_ACTIVE_PRODUCT`; nooit alle ontbrekende matches massaal uitvoeren.

Het script `MINIMUM_FIGURE_QUEUE.R` maakt voor alle oorspronkelijke metric_keys, figuurfamilies en de extra onder-basis-peercontexten een reproduceerbare, **niet-uitvoerende** triage uit de gepinde bronbundel en bestaande lokale centrale queue. Het weigert zelf nieuwe leerlingberekeningen te autoriseren. De 6 afgeleide rangfiguren vragen alleen gevalideerde landcijfers, geen nieuwe leerlingrun.

## Wat nog ontbreekt voor één definitief getal

Exacte matching van iedere taak met huidige/historische valide centrale SQLite- en Parquet-versies, oude V8/V9/V11 caches, aparte covariance/PV-basis, de 40 nieuwe NLD LO02-records zonder run-ID, de correcte SES-constructie en de nieuw gekozen onder-basismeting bij peers. Het huidige bewijs ondersteunt **geen exact numeriek minimum aan extra leerlingberekeningen**. Alle genoemde aantallen hierboven zijn reproduceerbare volledige-contracttellingen of duidelijk gedefinieerde kandidaatvolumes; geen onbewezen validatiestempel.

## Productie- en publicatieregels

RStudio Windows blijft de rekenomgeving. GitHub beheert code en *gevalideerde rechtengecontroleerde finale* cijfers/producten, Google Drive de private tussenresultaten. Op gecombineerde gelijkgewogen benchmarklijnen verschijnen geen SE/CI. Bronnen, historie en 28 september-release blijven bewaard; geen automatische lokale verwijderingen. 
