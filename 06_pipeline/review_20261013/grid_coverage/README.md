# Resultatengrid: volledige dekking en ontbrekende uitkomsten

Dit overzicht is gegenereerd uit het opgeslagen auditgrid. Het telt exacte doelcellen, geen figuren, leerlingen of afzonderlijke R-runs. De actuele scope is **nld_only**. Productkoppelingen bewijzen herkomst; zij bewijzen niet automatisch een oude slidetitel of paperclaim.

**2678 doelcellen; 2373 gecontroleerde uitkomsten; 281 gedocumenteerd onbeschikbaar; 24 open.** Alle doelcellen hebben een productkoppeling. Het volledige internationale dashboard is nog niet gevuld.

## Jaren, populaties en domeinen

| Bron | Populatie | Domein | Gekozen golven |
|---|---|---|---|
| PIRLS | internationaal vierde leerjaar / Nederlandse groep 6, circa 10 jaar | lezen | 2001, 2006, 2011, 2016, 2021 |
| PISA | 15-jarigen | wiskunde | 2003, 2006, 2009, 2012, 2015, 2018, 2022, 2025 |
| PISA | 15-jarigen | lezen | 2003, 2006, 2009, 2012, 2015, 2018, 2022, 2025 |
| PISA | 15-jarigen | natuurwetenschappen | 2006, 2009, 2012, 2015, 2018, 2022, 2025 |
| TIMSS | internationaal vierde leerjaar / Nederlandse groep 6, circa 10 jaar | wiskunde | 2003, 2007, 2011, 2015, 2019, 2023 |
| TIMSS | internationaal vierde leerjaar / Nederlandse groep 6, circa 10 jaar | natuurwetenschappen | 2003, 2007, 2011, 2015, 2019, 2023 |

Dit zijn meetgolven, geen jaarlijkse metingen. De 40 domein-jaarcombinaties volgen het vastgelegde Nederlandse anker uit het 21-slide-deck. Andere historische golven zijn niet automatisch gekozen. Een afwezig jaar buiten dit anker is dus geen bewezen ontbrekende bron. PISA-wiskunde/lezen beginnen in dit contract in 2003, science in 2006. PIRLS 2021 omvat de officieel vertraagd afgenomen cohort; age10 is een populatieaanduiding, geen exacte individuele leeftijd.

## Statistieken en splits

De scope is een gekozen familie-matrix, geen kruisproduct van elke statistiek met elke achtergrondgroep. De exacte combinatie inclusief drempel staat in BY_EXACT_COMBINATION.csv en EXACT_CELL_COVERAGE.csv.

- Landelijk totaal: gemiddelde, aandeel onder basisniveau, aandeel hoog/gevorderd, P10, mediaan/P50, P90 en P90−P10.
- SES: nationaal Q1 en Q4, hun gemiddelden en Q4−Q1, onder basisniveau naar Q1/Q4; hoog/gevorderd naar Q1/Q4 alleen appendix (A02). IEA gebruikt boekenkwartielen in alle gekozen golven; PISA de gekozen Cobreros-harmonisatie uitsluitend 2015, 2018, 2022 en 2025. Dit is niet hetzelfde als officiële ESCS. Oudere PISA-SES-jaren zijn niet stilzwijgend toegevoegd. De opgeslagen historische q1_basic/q4_basic zijn het complement; de productexport zet ze om naar onder basisniveau met behoud van SE.
- Geslacht: gemiddelde meisjes, gemiddelde jongens en meisjes−jongens. Geen automatisch toegevoegde staartaandelen voor elke geslachtsgroep.
- Thuistaal: IEA altijd/bijna altijd tegenover soms/nooit, PISA toetstaal thuis tegenover andere taal; groepsgemiddelden en kloof. Deze constructen blijven onderscheiden.
- Migratie: twee aparte oudergeboortelanddefinities (ten minste één ouder buiten testland; beide ouders buiten testland), elk groepsgemiddelden en kloof. Daarnaast native/eerste/tweede generatie en eerste−native/tweede−native.
- Peercompositie, steeds zelf uitgesloten: Q1 met Q4-peers en Q4 met Q1-peers; minder frequente/andere thuistaal met referentietaalpeers; migratiegroepen met referentie/native peers. Nationale compositie-baselines horen bij de interpretatie en zijn niet nog een aparte peeruitkomst.
- Prestatiepeers: aandeel onder basisniveau voor alle leerlingen, zelf onder basisniveau en zelf minstens basisniveau (A01); aandeel hoog/gevorderde peers voor zelf hoog en zelf niet hoog (A03). Per domein en voor beide leeromgevingen.
- Leeromgevingen: directe omgeving is bij IEA de klas binnen de school en bij PISA school×programma; daarnaast gehele school. PISA school×programma is geen geobserveerde klas.
- Appendix: SES×geslacht (Q1/Q4 × meisje/jongen; gemiddelde, onder basisniveau, hoog), officiële IEA Home-SES (lower/middle/higher, dezelfde drie uitkomsten). Home-SES is uitsluitend voor PIRLS 2021 in Nederland beschikbaar; responsselectiviteit blijft zichtbaar.
- Wetenschappelijke uitbreiding: aandeel prestatievariantie tussen scholen en, waar werkelijk vergelijkbaar, klassen; SES-variantie tussen scholen, klasvariantie SES alleen appendix. domain=all betekent achtergrondcompositie/SES-variantie en is geen vierde prestatiedomein.

Alle geselecteerde IEA-staarten gebruiken <475 en ≥625; 550 is hier niet gekozen. PISA gebruikt <niveau 2 en ≥niveau 5: lezen 407,47 / 625,61; wiskunde 420,07 / 606,99; science 409,54 / 633,33. Er zijn dus twee afkappunten met een middengroep. Onder basisniveau en hoog zijn geen complementen.

| Familie in code | Doelcellen | Gecontroleerd | Onbeschikbaar | Open |
|---|---:|---:|---:|---:|
| core | 280 | 280 | 0 | 0 |
| extension_home_ses | 153 | 9 | 144 | 0 |
| extension_performance_class | 40 | 17 | 23 | 0 |
| extension_performance_school | 40 | 40 | 0 | 0 |
| extension_ses_class | 15 | 11 | 4 | 0 |
| extension_ses_gender | 348 | 330 | 0 | 18 |
| extension_ses_school | 15 | 15 | 0 | 0 |
| gender | 120 | 114 | 0 | 6 |
| high_proficiency_peer_exposure | 160 | 160 | 0 | 0 |
| home_language_frequency_peer | 22 | 20 | 2 | 0 |
| home_language_peer_exposure | 16 | 16 | 0 | 0 |
| language_exact | 69 | 69 | 0 | 0 |
| language_frequency_binary | 51 | 48 | 3 | 0 |
| migration | 240 | 210 | 30 | 0 |
| migration_binary_peer | 76 | 60 | 16 | 0 |
| migration_generation | 200 | 175 | 25 | 0 |
| migration_peer_exposure | 76 | 60 | 16 | 0 |
| peer_baseline | 254 | 236 | 18 | 0 |
| peer_below_basic | 240 | 240 | 0 | 0 |
| ses_harmonized | 84 | 84 | 0 | 0 |
| ses_national | 119 | 119 | 0 | 0 |
| ses_peer_exposure | 60 | 60 | 0 | 0 |

## Dekking per golf

| Bron | Jaar | Doelcellen | Gecontroleerd | Onbeschikbaar | Open |
|---|---:|---:|---:|---:|---:|
| PIRLS | 2001 | 92 | 83 | 9 | 0 |
| PIRLS | 2006 | 92 | 76 | 16 | 0 |
| PIRLS | 2011 | 92 | 60 | 32 | 0 |
| PIRLS | 2016 | 92 | 60 | 32 | 0 |
| PIRLS | 2021 | 92 | 69 | 23 | 0 |
| PISA | 2003 | 92 | 90 | 2 | 0 |
| PISA | 2006 | 130 | 127 | 3 | 0 |
| PISA | 2009 | 130 | 127 | 3 | 0 |
| PISA | 2012 | 130 | 127 | 3 | 0 |
| PISA | 2015 | 197 | 193 | 4 | 0 |
| PISA | 2018 | 197 | 193 | 4 | 0 |
| PISA | 2022 | 197 | 193 | 4 | 0 |
| PISA | 2025 | 197 | 169 | 4 | 24 |
| TIMSS | 2003 | 158 | 140 | 18 | 0 |
| TIMSS | 2007 | 158 | 140 | 18 | 0 |
| TIMSS | 2011 | 158 | 106 | 52 | 0 |
| TIMSS | 2015 | 158 | 140 | 18 | 0 |
| TIMSS | 2019 | 158 | 140 | 18 | 0 |
| TIMSS | 2023 | 158 | 140 | 18 | 0 |

## Waarom 305 doelcellen geen uitkomst hebben

| Oorzaak | Cellen | Gevolg vanuit de gekozen regels |
|---|---:|---|
| Officiële Home-SES bestaat nog niet als gekozen construct: PIRLS 2001/2006/2011/2016; TIMSS 2003/2007/2011/2015/2019 | 126 | Geen oudere Home Resources-schaal aan de nieuwe Home-SES-reeks plakken. |
| TIMSS 2023: Nederlandse Home Questionnaire niet afgenomen | 18 | Geen officiële Home-SES uit niet-geobserveerde ouderdata maken. |
| Onvoldoende oudergeboortelandvelden: PIRLS 2011/2016/2021, TIMSS 2011 | 103 | Geen migratiegeneraties of ouderdefinities gokken; dit raakt ook peers en baselines. |
| Geen feitelijke PISA-klasidentificatie | 27 | 23 prestatie- en 4 SES-klasvarianties niet vervangen door school×programma. Schooluitkomsten blijven beschikbaar. |
| PIRLS 2006 heeft always/sometimes/never, niet de gekozen always-or-almost-categorie | 7 | Geen ongemerkte categorie- of constructwissel voor taal en taalpeers. |
| PISA 2025 NLD: geen afzonderlijk bruikbaar meisjesveld in gecontroleerde broneditie | 24 | 6 meisjesgemiddelden/geslachtskloven en 18 SES×meisje-uitkomsten blijven open; jongens zijn wel berekend. |

De 281 onbeschikbare cellen blijven als gedocumenteerde doelen in het grid. De 24 meisjescellen zijn een open bronvraag, geen bewijs dat zulke gegevens nergens bestaan. PIRLS 2021 Home-SES heeft 9 uitkomsten op 2.031 van 4.313 leerlingen; gewogen dekking 47,7027%. Geen claim van volledige ouderrespons.

## Landen en productieopties

Alleen Nederland is momenteel goedgekeurd voor productie en heeft gecertificeerde cellen in dit grid. Nederland voldoet voor de kern aan minstens drie geldige golven in elk van zes leeftijd-domeincombinaties. Dat certificeert niet automatisch alle splits of referentiegroepen.

De rijke kandidaten zijn hieronder herkenbaar. Rijk is geen toelatingsbewijs. Voor de Nederlandse standaard moeten kandidaten het volledige 40-combinatie-anker én de samen vergeleken groepen/peerconstructen dekken. Voor een ander hoofdland geldt diens volledige passende dekking. Er worden geen jaren of groepen ingekort en geen vaste aantallen geforceerd.

- nld_only: uitsluitend goedgekeurde Nederlandse cellen.
- nld_plus_19: Nederland plus goedgekeurde, brongetoetste leden van de rijke kandidaatpool; de naam garandeert geen 19.
- all_required: die pool plus andere goedgekeurde, toegelaten landen. Zoeken buiten COMMON42 blijft vereist; deze catalogus is geen volledige wereldinventaris.

| Code | Land/stelsel | Rijke kandidaat | Huidig bewijs |
|---|---|---|---|
| ALB | Albania | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| ARE | United Arab Emirates | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| AUS | Australia | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| AUT | AUT | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| AZE | Azerbaijan | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| BEL | BEL | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| BGR | Bulgaria | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| BRA | Brazil | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| CAN | CAN | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| CHE | CHE | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| CHL | CHL | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| COL | COL | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| CRI | CRI | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| CYP | Cyprus | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| CZE | Czechia | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| DEU | Germany | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| DNK | Denmark | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| ESP | Spain | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| EST | EST | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| FIN | Finland | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| FRA | France | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| GBR | GBR | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| GEO | Georgia | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| GRC | GRC | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| HKG | Hong Kong | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| HUN | Hungary | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| IRL | Ireland | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| ISL | ISL | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| ISR | ISR | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| ITA | Italy | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| JOR | Jordan | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| JPN | JPN | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| KAZ | Kazakhstan | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| KOR | KOR | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| LTU | Lithuania | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| LUX | LUX | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| LVA | Latvia | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| MAC | Macao | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| MAR | Morocco | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| MEX | MEX | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| MKD | North Macedonia | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| MNE | Montenegro | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| NLD | Netherlands | ja | NLD-kern geverifieerd; productie actief |
| NOR | Norway | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| NZL | New Zealand | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| POL | Poland | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| PRT | Portugal | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| QAT | Qatar | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| SAU | Saudi Arabia | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| SGP | Singapore | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| SRB | Serbia | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| SVK | Slovakia | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| SVN | Slovenia | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| SWE | Sweden | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| TUR | Türkiye | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| TWN | Chinese Taipei | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| USA | United States | ja | Brondekking nog niet gecertificeerd; geen productie-akkoord |
| XKX | Kosovo | nee | Brondekking nog niet gecertificeerd; geen productie-akkoord |

FALSE bij buitenlandse dashboard_eligible betekent hier nog niet geverifieerd, niet bewezen ongeschikt. Alle 58 catalogusrecords staan in COUNTRY_CANDIDATES.csv. Geen automatische productie voor deze 58; een concreet landenvoorstel en gebruikersakkoord blijven nodig.

## Zit alles voor het dashboard in het grid?

**De gekozen Nederlandse primitieve families staan erin; alle internationale dashboarduitkomsten nog niet.** Naast de genoemde gaten ontbreken gecertificeerde buitenlandse reeksen, de definitieve gebalanceerde referentieleden per vergelijking, en de werkelijke afgeleide referentiegemiddelden/rangtijdsreeksen met oudercellen en gekozen leden. De registratie van kandidaat-ouders voor A09 is geen voltooide rangberekening. De referentiebediening en complete productrelease zijn ook nog niet afgerond.

De gebruiker bouwt één figuur met jaren op de x-as. De rang van het hoofdland is relatief tot de gekozen internationale referentiegroep; die groep wordt niet als ranglijn geplot. Eventueel komt er één ander individueel land naast. Een ranglijst hoort alleen in de paper. Bij gewone vergelijkingen wegen referentielanden gelijk en blijft het hoofdland buiten zijn referentie; geen SE/CI op de samengestelde referentielijn.

Een complete kernreeks maakt een onvolledige split niet vergelijkbaar. Een combinatie met ontbrekende groepen/jaren moet zichtbaar onbeschikbaar zijn; geen stilzwijgende verkorting. De toegestane dashboardkeuzes zijn de goedgekeurde families, niet iedere mogelijke statistiek×split. Appendix- en wetenschappelijke uitbreidingen worden niet vanzelf dashboardopties.

## Bewust buiten de berekenvoorraad

A05 internationale absolute SES, A07 taal×migratie en A08 oude historische rangpanels zijn afgewezen. A10 leeftijd/cohortuitbreidingen en A15/A16 Theil-H zijn uitgesteld. A17 geeft alleen toestemming voor noodzakelijke, vooraf gekozen paperclaims, niet voor een massale reeks trendtoetsen. Het losse complementfiguurtype is geschrapt. Oude 13-/32-/45-landenpanels, alle 79.448 historische keys en het hele 50-slide-deck zijn geen productieopdracht. Q01–Q08 en paperclaims vragen afzonderlijk bewijs; producttrace alleen sluit ze niet af.

## Meisjes bij PISA en herkomst

De resolver gebruikt ST004D01T met labelcontrole én Female=1 / Male=2. ST004 en de gedocumenteerde ST004D01D zijn expliciete fallbacks; tegenstrijdige gevulde velden stoppen de run. Codes Other/95–99/ontbrekend worden geen meisjes. MALE=0 met label Female / Other evenmin. De onafhankelijke referentie-implementatie controleert dezelfde brondefinitie afzonderlijk. In de daadwerkelijk gecontroleerde Nederlandse PISA-2025-bron staan alle 6.636 ST004D01T-waarden op 99. MALE bevat 3.397 jongens, 3.237 Female / Other en 2 ontbrekend. Het label Female=1 bestaat dus, maar er zijn geen records met code 1. Zie ../PISA2025_USER_GENDER_FIELDS_RECHECK.json voor bronhash, tellingen en resolveruitkomst.

De officiële [OECD-database](https://www.oecd.org/en/data/datasets/pisa-2025-database.html) en [downloadindex](https://webfs.oecd.org/pisa2022/index.html) zijn geraadpleegd. De index biedt voor deze editie de SPSS-studentbron; er is daar geen afzonderlijke 2025-SAS-studentdownload aangetoond die dit oplost. Dezelfde bron opnieuw downloaden levert geen bewezen nieuwe meisjesinformatie op.

De audit heeft lege leeftijd-/populatievelden hersteld vanuit de gekozen surveycontracten. Oude certificaten mogen die metadata niet meer leeg overschrijven. Dit verandert geen schatting, SE, N, resultaat-hash of oorspronkelijke wetenschappelijke certificering. Alle resultaatwaarden behouden hun oorspronkelijke bron-, input-, code- en certificaathashes. manifest.json bindt dit overzicht aan exacte auditbestanden en de rapportgenerator.

Reproduceren: `python scripts/report_grid_coverage.py --state <private FIXED_PRODUCTION_V1/nld_only> --output 06_pipeline/review_20261013/grid_coverage`. Voer na gewijzigde scope eerst de bestaande fixed-audit uit; dit rapport berekent of autoriseert geen nieuwe cel.
