# Begrensde prioriteitsrun — 20 oktober 2026

De brede productie en automatische wetenschappelijke afsluiter zijn op expliciet verzoek gestopt.
Daarna zijn achtereenvolgens het Verenigd Koninkrijk, Liechtenstein, Luxemburg en de 140
gerichte peerreparaties uitgevoerd via de bestaande, ongewijzigde START.R-pipeline.
Hierna is alleen de volledige inventaris opnieuw gecontroleerd en zijn resultaten opgeslagen.
Andere landen, de brede wetenschappelijke eindcontroles en websitepublicatie zijn niet gestart.

Productiecode: `5fb49472682db7f5a65f241f18f2cd759639a500`. Resultaatcommit: `39f386caa9e6e8856405d8bbe748d51b24771d95`.

| Selectie | Gevalideerd | Onderbouwd onbeschikbaar | Nog open |
|---|---:|---:|---:|
| Verenigd Koninkrijk | 1.153 | 117 | 0 |
| Liechtenstein | 471 | 11 | 0 |
| Luxemburg | 935 | 138 | 0 |
| Zeven peerreparatiesets | 140 | 0 | 0 |

Volledige stand: **131.436 doelen**, **82.686 gevalideerd**, **9.511 onderbouwd onbeschikbaar**, **39.239 open**.
47 landen/stelsels hebben geen open rekentaken; 36 hebben nog open doelen.
Dit is een productie- en registratiecontrole, geen wetenschappelijke vrijgave van de uitbreiding.

De drie prioriteitslanden hebben uitsluitend de nationaal toegelaten PISA-combinaties in
deze run. Regionale PIRLS/TIMSS-populaties zijn niet als nationale gegevens toegevoegd.
De JSON-tabel vermeldt per domein de geselecteerde landjaren en Nederlandse ankerjaren
buiten die landenscope. Dit zijn geen vergeten rekentaken of toestemming om referentieperioden
in te korten. Berekende landen zijn niet automatisch passende Nederlandse referentielanden.
De zeven reparaties betreffen 2003 en de directe leeromgeving; bestaande hele-schoolresultaten
en andere reeds geldige cellen zijn niet opnieuw berekend.

Bij Luxemburg 2025 ontbreken alle 6.078 schoolidentificaties (`CNTSCHID`) in
de geverifieerde bron. De enige school-ID-kolom bevat geen waarnemingen;
de leerlingenscores zijn wel aanwezig. Dit blokkeerde een pakket met 57 doelen.
Voor de drie schoolvarianties is daarom exacte brononbeschikbaarheid vastgelegd,
waarna de 54 wel berekenbare landelijke resultaten via dezelfde gepinde keten
zijn afgerond. Voor 45 andere schoolafhankelijke doelen bleef hun bestaande
primaire afwezigheidsreden behouden; de ontbrekende school-ID is daarbij een
aanvullende kwaliteitsnotitie. Geen school-ID, schoolgroep of nulwaarde is verzonnen.
Zie `LUX_MISSING_SCHOOL_EVIDENCE.json`, `LUX_SCHOOL_PROBE.json` en de exacte
48 doelidentiteiten in `LUX_MISSING_SCHOOL_TARGETS.csv`.
Voor 62 Luxemburgse doelen in 2025 bewijzen de bestaande
SES-diagnostieken bovendien dat de gekozen Cobreros-maat geen geobserveerde
analysegroep heeft. De diagnose met ongewogen en gewogen noemer nul staat in
`LUX_SES_AVAILABILITY_DIAGNOSTICS.csv`. De kwaliteitsnotities kunnen overlappen;
de hoofdredenen tellen ieder onbeschikbaar doel precies eenmaal.

Er zijn 2699 nieuwe gevalideerde resultaten toegevoegd. Geen eerder geldig
resultaat of certificaat is gewijzigd en er zijn geen resultaten buiten de selectie toegevoegd.

- `PRIORITY_COUNTRY_STATUS_20261020.csv`: alle 83 landen met exacte totalen.
- `PRIORITY_PEER_REPAIRS_20261020.csv`: de twintig gecontroleerde reparaties per gekozen land.
- `PRIORITY_REMAINING_BLOCKS_20261020.csv`: resterend werk per land, leeftijd, studie, jaar, domein en module.
- `PRIORITY_SELECTED_COVERAGE_20261020.csv`: dekking van de drie prioriteitslanden.
- `PRIORITY_UNAVAILABLE_REASONS_20261020.csv`: onderbouwde ontbrekende cellen in deze selectie.
- De vier `*_CONFIG.json`-bestanden begrenzen de run; zij verlenen geen nieuwe inhoudelijke goedkeuring.
- `PRIORITY_RUN_20261020.json`: resultaat-/codebinding, bronhashes, deelreceipts en resterende stappen.

Het [volledige celregister](https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes/blob/39f386caa9e6e8856405d8bbe748d51b24771d95/04_results/review/all_required/target_status.csv)
bewaart ieder exact doel met zijn status. De naastgelegen `results.csv` bevat de
gecertificeerde waarden, onzekerheid en bron-/code-/resultaatfingerprints.

Na een afzonderlijke hervattingsopdracht moet eerst de resterende productie worden afgerond.
Vooraf moet de controle op ontbrekende school-ID's ook algemeen vóór schoolvarianties
en SES-peers worden toegepast (I160), zodat een nieuw brongeval geen geldige landelijke
resultaten blokkeert. Het Luxemburgse geval is met exact bronbewijs afgesloten.
Vervolgens moeten de uitgebreide Q-dossiers, steekproefomvangcontroles, vaste figuurreferenties
en rangafleidingen worden afgesloten op de echte resultaten. De voorbereide controles hergebruiken
ongewijzigde bewijzen. Pas daarna volgen veilige integratie, Windows/Linux-controles en de bestaande
finalizer. De historische 34-landencertificering blijft afzonderlijk bewijs.
