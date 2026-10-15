# Nederland PISA 2025: controle van het geslachtsveld

Gecontroleerd op 15 oktober 2026. Dit is een bronvraag, geen aanwijzing dat de Nederlandse meisjes niet aan PISA hebben meegedaan. Waardelabels in een codeboek bewijzen niet dat die waarden in het Nederlandse bestand voorkomen.

| ST004D01T | MALE | Label van MALE | Aantal leerlingen |
|---:|---:|---|---:|
| 99 | 0 | Female / Other | 3.237 |
| 99 | 1 | Male | 3.397 |
| 99 | 99 | no response | 2 |

Alle 6.636 Nederlandse records hebben ST004D01T=99. De labels 1=Female en 2=Male bestaan, maar geen Nederlands record heeft deze waarden. `ST004D01D`, `ST004`, `ST430Q01DA` en `FEMALE` ontbreken uit deze studentbron. Het bronbestand heeft SHA256 `6f6fa1e1ecce23d39183d44ec82ba05b245fe88a2416c8d8dc1b016d556fc379`. De tabel bevat alleen geaggregeerde voorbeelden, geen leerlingrecords of ID's. Zie [exacte tellingen en labels](PISA2025_GENDER_DIAGNOSTIC.json) en [CSV](PISA2025_GENDER_EXAMPLES.csv).

Met alle PV's, studentgewichten en BRR-replicatiegewichten levert MALE=0 de volgende gemiddelden op. De officiële kolom is de afzonderlijke meisjescategorie in de gecontroleerde OECD-tabel.

| Domein | Berekend Female / Other | Officieel meisjes | Absoluut verschil |
|---|---:|---:|---:|
| Lezen | 458,682106 | 458,692950 | 0,010844 |
| Wiskunde | 478,680489 | 478,697930 | 0,017441 |
| Natuurwetenschappen | 487,982649 | 487,996110 | 0,013461 |

Deze landelijke verschillen zijn inhoudelijk klein. Ze bewijzen geen groot effect binnen SES-groepen, maar evenmin exacte gelijkheid van de constructen. De drie jongensgemiddelden én standaardfouten reproduceren de officiële cijfers binnen hun afrondingsprecisie. De [volledige geaggregeerde vergelijking](PISA2025_GENDER_NUMERICAL_EXAMPLES.csv) bevat ook de standaardfouten. Er wordt geen individueel geslacht afgeleid uit scores of andere kenmerken.

## Gecontroleerde bronnen en alternatieven

- De actuele [OECD-databasepagina](https://www.oecd.org/en/data/datasets/pisa-2025-database.html), downloadindex en het verse [codeboek](https://webfs.oecd.org/pisa2022/2025/PISA2025_Codebook.xlsx) zijn gecontroleerd. Alle zeven tabbladen zijn doorzocht; er is geen afzonderlijk leerlingveld ST004D01D of FEMALE gevonden. Een lerarengeslachtsveld, buitenlandse steekproefstrata of vraagresponstijd zijn geen vervanging. Het codeboek heeft SHA256 `d527a3e75f4c2b49c9810728bea78381683ac98ddb28d40cc7d3824086473b1c`.
- De [officiële recodebestanden](https://webfs.oecd.org/pisa2022/2025/PISA_recoding_2025.zip) gebruiken ST004D01D voor de afzonderlijke categorieën; een andere recode combineert Female en Other. Dat veld staat niet in de gecontroleerde PUF. De oorzaak van deze discrepantie is nog niet door de uitgever bevestigd.
- ZIP-metadata van de huidige studentdownload hebben dezelfde onuitgepakte lengte en CRC als het lokale SAV. Dit is een gerichte editiecontrole, geen volledige SHA256-verificatie van een opnieuw gedownload gigabytearchief. Er is geen aanwijzing gevonden dat simpelweg dezelfde download opnieuw ophalen het ontbrekende veld toevoegt.
- De [OECD-methodologiepagina](https://www.oecd.org/en/about/programmes/pisa/pisa-data.html) verwijst naar IDB Analyzer voor analyse. Zij vermeldt niet dat deze software verschillen uitvlakt of ontbrekend individueel geslacht reconstrueert. De [IEA-handleiding, p. 27](https://www.iea.nl/sites/default/files/2022-06/IDB-Analyzer-Manual-%28Version-5-0%29.pdf) beschrijft de aanwezige groepsvariabelen, ontbrekende waarden, gewichten en PV's. Correcte surveyanalyse lost categorie-aggregatie niet op.
- De genoemde [NCES restricted-use-bron](https://nces.ed.gov/surveys/pisa/datafiles.asp) betreft Amerikaanse bestanden. Daarmee is geen Nederlandse licentieprocedure aangetoond. Het [Nederlandse contactpunt](https://www.pisa-nederland.nl/contact/) en [onderzoeksteam](https://www.pisa-nederland.nl/onderzoekers/) zijn wel geverifieerd; een beschikbaar aanvullend bestand of toegang is nog niet bevestigd. Er is geen bericht verstuurd.
- Het technische-rapportarchief en het Nederlandse rapport waren via de gebruikte rechtstreekse downloadroute niet toegankelijk (HTTP 403). Ze gelden niet als volledig gelezen bewijs.

## Uitgevoerde oplossing en resterende exacte bronvraag

De producent en de onafhankelijke referentieberekening gebruiken eerst geldige en gelabelde ST004D01T/ST004-waarden, daarna het gedocumenteerde afzonderlijke D-veld indien aanwezig. Tegenstrijdige velden leiden tot een fout. Waar alleen MALE beschikbaar is, worden de jongens wel berekend; MALE=0 wordt niet stilzwijgend meisjes. Voor Nederland zijn de drie jongensgemiddelden en achttien jongens-SES-cellen gecertificeerd. Vierentwintig doelen blijven afhankelijk van de afzonderlijke meisjescategorie: drie gemiddelden, drie gendercontrasten en achttien meisje-SES-cellen. Andere productie kan doorgaan.

Een praktische vervolgvraag aan de uitgever is: welk officieel veld of welke gecorrigeerde PUF reproduceert de afzonderlijke Nederlandse meisjescijfers, gezien bovenstaande bronhash, tellingen en de recodeverwijzing naar ST004D01D? Als alleen een aanvullend bestand beschikbaar is, zijn minimaal de exacte koppel-ID's, definities, broneditie, toegangsvoorwaarden en overeenkomende steekproef/gewichten nodig. Als toegang tot microdata niet mogelijk is, kunnen gecontroleerde geaggregeerde uitkomsten voor de 24 exacte cellen worden gevraagd, inclusief N, onzekerheid en gezamenlijk berekende contrasten; losse marginale standaardfouten volstaan niet voor verschillen.

De gebruiker heeft gevraagd de IDB-/toegangsroute te onderzoeken. Dat is geen toestemming om Female / Other opnieuw als meisjes te definiëren. De huidige exacte definitie blijft daarom gelden. Een expliciete andere keuze vraagt een nieuwe constructidentiteit en zichtbare trend-/balansbeoordeling; de bestaande meisjesreeks mag niet geruisloos worden overschreven.
