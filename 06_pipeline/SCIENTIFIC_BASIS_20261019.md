# Wetenschappelijke basis en definitieve scope — 19 oktober 2026

Dit dossier beoordeelt de afgesloten resultaatbasis `ac9f0bdb15b5bf3fcf843f3e4f857995d182aef2` inhoudelijk. De historische run bevat 77.611 doelen: 69.775 geregistreerd gevalideerde resultaten, 7.836 onderbouwd onbeschikbare doelen en nul open rekentaken. Die rekenkundige stand blijft bewaard. Latere uitsluitingen voor landen en vergelijkbaarheid staan afzonderlijk; een correctie herschrijft geen historisch resultaatcertificaat.

De actuele bewijsbinding staat in [scientific_review/SCIENTIFIC_REVIEW_MANIFEST.json](review_20261013/scientific_review/SCIENTIFIC_REVIEW_MANIFEST.json). De bestaande `fixed-finalize` controleert de oorspronkelijke bewijsbestanden, actuele code, besluiten, exacte doelcontracten en resultaatbytes voordat Q01–Q08 voor een run worden geaccepteerd. Een identieke controle mag dezelfde numerieke bewijsstukken gebruiken. Gewijzigde bronnen, resultaten, claims of beleidsregels vereisen nieuwe beoordeling van de getroffen onderdelen. De wetenschappelijke basis en de uiteindelijke product-, rechten- en replicatievrijgave zijn afzonderlijke controles.

## Afbakening en dekkingsrapport

Het [dekkingsrapport](review_20261013/grid_coverage/README.md) beschrijft alle landen, meetgolven, leeftijden, domeinen, splits, maten en producten. `BY_EXACT_COMBINATION.csv` bevat iedere combinatie. `PRODUCT_CELL_TRACE.csv.gz` koppelt 267 productvereisten en geregistreerde claims aan exacte cellen of afleidingen; `EXACT_CELL_COVERAGE.csv.gz` bevat de bijbehorende bron-, populatie-, methode-, onzekerheids-, resultaat- en code-identiteiten. Er zijn geen actieve cellen zonder productkoppeling.

| Studie/populatie | Domein | Nederlands volledige jaaranker |
|---|---|---|
| PIRLS, internationaal leerjaar 4 / Nederlandse groep 6 | Lezen | 2001, 2006, 2011, 2016, 2021 |
| TIMSS, internationaal leerjaar 4 / Nederlandse groep 6 | Wiskunde en natuurwetenschappen | 2003, 2007, 2011, 2015, 2019, 2023 |
| PISA, 15-jarigen | Lezen en wiskunde | 2003, 2006, 2009, 2012, 2015, 2018, 2022, 2025 |
| PISA, 15-jarigen | Natuurwetenschappen | 2006, 2009, 2012, 2015, 2018, 2022, 2025 |

Dit zijn 40 leeftijd-domein-jaarcombinaties. Meetgolven zijn geen jaarlijkse observaties. Elk ander hoofdland behoudt zijn volledige eigen vastgelegde anker. Niet iedere maat of split bestaat in iedere golf. De gekozen scope is geen volledig kruisproduct van alle denkbare analyses.

De goedgekeurde plaatsingen blijven bindend: beide lage en hoge peeruitkomsten; hoog/gevorderd naar SES, SES × geslacht en officiële IEA Home-SES in de appendix; prestatie- en SES-variantie tussen scholen als wetenschappelijke uitbreiding; klasvarianten alleen bij vergelijkbare klasidentificatie, met SES tussen klassen in de appendix. Geen internationale absolute SES-grenzen, taal × migratie of oude vaste rangpanels. Cross-age/cohortuitbreidingen en Theil-H blijven uitgesteld. De afwijzing van A17 betreft de systematische toetsenreeks; noodzakelijke geregistreerde paperclaims blijven toegestaan.

Het oorspronkelijke `01_data_download_preprocessing/source_registry/SCIENTIFIC_DECISION_REGISTER.txt` blijft bytegetrouw historisch bronmateriaal. De oude tekst daarin om beide sorteervarianten te berekenen is geen actieve opdracht. De actuele beslissingen staan in `START_HIER_ACTUEEL.md` en `SCOPE_APPROVALS.csv` en worden in het exacte takenregister getoetst.

Ontbrekende doelen krijgen precies één hoofdreden: ontbrekende bronkoppeling, niet-afgenomen vragenlijst, niet-bestaande schaal in de cyclus, onbruikbare analysegroep, ongeldig/ontbrekend domein, ontbrekende leeromgeving, niet-geobserveerde groepsdefinitie of benodigd bronveld. Kwaliteitsnotities staan daarnaast en tellen niet dubbel. Een geldige nul is een resultaat. Een lage respons of niet-vergelijkbare golf wordt niet als een ontbrekende vragenlijst voorgesteld. De volledige tabel staat in `MISSING_CELLS.csv`; tellingen staan in `BY_MISSING_REASON.csv`.

## Landen en referenties

De beoordeelde kandidateninventaris bevat 116 broncodes/landen/stelsels; dat zijn niet 116 soevereine landen. Ook systemen buiten COMMON42 zijn gecontroleerd. [COUNTRY_REVIEW.csv](review_20261013/scientific_review/COUNTRY_REVIEW.csv) geeft per kandidaat de uitkomst en reden; de zes afzonderlijke tellers staan in `VERIFIED_COUNTRY_SIX_COMBINATIONS.csv`. Ontbrekende certificering is op zichzelf geen bewijs van niet-deelname.

Er voldoen 32 landen/stelsels aan ten minste drie vergelijkbare meetgolven in elk van de zes combinaties: **ARE, AUS, AUT, AZE, BGR, CZE, DEU, DNK, ESP, FIN, FRA, GEO, HKG, HUN, IRL, ITA, LTU, LVA, MAR, NLD, NOR, NZL, PRT, QAT, RUS, SAU, SGP, SVK, SVN, SWE, TWN en USA**. Hongkong en Chinees Taipei blijven hun consequent gedefinieerde onderwijsstelsel; ze worden niet omgedoopt tot China. Voor Noorwegen tellen uitsluitend de passende leerjaar-4-bestanden, waaronder de officiële aanvullende steekproeven, niet de leerjaar-5-populatie.

| Kandidaat | Inhoudelijke uitkomst |
|---|---|
| CAN | De als nationaal gecertificeerde PIRLS-2001-bron omvat Ontario en Québec. Na correctie blijven twee passende nationale leesgolven over; Canada voldoet niet aan 6×3. Historische resultaten blijven bewaard. |
| POL | PIRLS 2006/2011 en TIMSS 2011 betreffen de Poolse derde klas. PIRLS gebruikt vanaf 2016 de vierde klas, TIMSS vanaf 2015. De leerjaarwisseling is geen vergelijkbare tijdreeks; slechts twee vrijgegeven PIRLS-golven betreffen de consistente vierde-klaspopulatie. |
| BEL | Vlaamse/Franse onderwijsgemeenschappen in IEA zijn niet uitwisselbaar met nationaal PISA-België. Geen stilzwijgende regionale of nationale reconstructie. |
| GBR | Engeland, Schotland en Noord-Ierland in IEA zijn niet hetzelfde als nationaal PISA-Verenigd Koninkrijk. |
| CHE en KOR | Geen drie PIRLS-leesgolven in de beoordeelde vrijgegeven cycli; TIMSS-deelname levert geen leesuitkomst. |
| ISL | Twee PIRLS-golven: 2001 en 2006. |
| LUX | Eén PIRLS-golf, 2006; de afwijkende lokale leerjaaraanduiding maakt daar geen drie golven van. |
| IRN en OMN | Voldoende IEA-golven, maar geen drie PISA-golven in de beoordeelde cyclusbestanden. |
| MKD | Drie PIRLS-golven, maar slechts twee passende TIMSS-leerjaar-4-golven. |
| MLT | De officiële deelname is ruimer dan de lokale bestandsinventaris: PIRLS 2011/2016/2021, maar slechts twee TIMSS-golven op het primaire niveau, 2011/2019. TIMSS 2023 betreft het voortgezet onderwijs en telt niet mee. |

De [Poolse nationale bron](https://ibe.edu.pl/en/assessments/assessments-international-large-scale-assessments/pirls-international-assessments) en het gepinde nationale rapport onderscheiden de leerjaren expliciet. Een algemene internationale code voor leerjaar 4 is hier onvoldoende bewijs van een ongewijzigde nationale populatie. Bij Malta bevestigt de [nationale TIMSS-deelnamelijst](https://curriculum.gov.mt/timss/) het onderscheid tussen beide onderwijsniveaus. `COUNTRY_PARTICIPATION_CLARIFICATIONS.json` legt vast dat aanwezige bronbestanden, officiële deelname en vergelijkbare golven verschillende tellers zijn.

De rijke kandidatenlijst is ongewijzigd: AUS, AUT, BEL, CAN, CHE, DEU, DNK, ESP, FIN, FRA, GBR, IRL, ISL, ITA, KOR, LUX, NLD, NOR, SWE en USA. De historische constructie is **OESO-lidmaatschap en bbp per hoofd in koopkrachtpariteit in 2024 strikt boven Tsjechië**, uit World Bank `NY.GDP.PCAP.PP.CD`; dit is niet de algemene World Bank-inkomensclassificatie. De teruggevonden bron en drempel zijn afzonderlijk gepind. Het getal twintig verleent geen toelating.

De drie modi blijven `nld_only`, `nld_plus_19` en `all_required`; de tweede naam is een historische naam voor de toegelaten rijke kandidaten. De bestaande toestemming voor alle bronmatig toegelaten landen geldt. Er worden geen extra landen of regio's onder een nieuwe inhoudelijke definitie toegevoegd.

Binnen de rijke kandidaten dekt **alleen Italië** het volledige Nederlandse basisanker. Buiten die kandidaten dekken ook Hongkong, Hongarije en Nieuw-Zeeland dat basisanker. Dit is nog geen universele referentie voor iedere uitsplitsing: de vereiste gezamenlijke groeps- en peercompositie kan de set verkleinen of leeg maken. [REFERENCE_BY_VIEW.csv](review_20261013/scientific_review/REFERENCE_BY_VIEW.csv) legt voor ieder hoofdland en iedere dashboardfiguur de uiteindelijke passende en standaardleden vast. Een leeg veld blijft een lege referentie.

AUT 2009 en ESP 2018 blijven historische resultaten, maar worden wegens de expliciete officiële trendvoorbehouden uitgesloten van gecertificeerde vergelijkbare trenddekking. Hun vereiste jaren verdwijnen niet uit het hoofdlandanker. De private definitieve productexport laat zulke punten open en bewaart de reden. Dit is een voorzichtige toepassing van de afgesproken vergelijkbaarheidsregel; het is geen bewering dat de OESO alle dwarsdoorsnederesultaten van die cycli heeft ingetrokken. Zie de [OESO-toelichting op afwijkende afnames](https://www.oecd.org/en/about/programmes/pisa/pisa-frequently-asked-questions-faqs.html).

De referentie is steeds een gelijkgewogen gemiddelde van landen, exclusief het hoofdland, met constante volledige dekking van het hoofdlandanker plus de gezamenlijk gekozen figuurreeksen. De tijdelijke available-cases-website is geen bewijs van deze definitieve balans. De bestaande publieke vormgeving en laatste UI-code worden behouden voor de daaropvolgende productstap.

Bronresultaten en afgeleide weergaven hebben afzonderlijke hashes. Bij SES-percentages onder basisniveau wordt de oorspronkelijke cel met het aandeel boven de grens bewaard; de afleiding bevat de exacte omzetting naar het complement en de meegeschaalde standaardfout. `PRODUCT_DERIVATION_REVIEW.csv` maakt deze koppelingen zichtbaar. De publicatiecontrole controleert ook de waarden en doeljaren; Nederlandse figuursjablonen verkorten of verlengen het eigen hoofdlandanker van een ander land niet.

Rang gebruikt precies de geselecteerde referentielanden plus het hoofdland eenmaal als rangbasis. Bij rang wordt geen groepslijn, groepsrang of groepsinterval geproduceerd. Een eventuele tweede landlijn moet tot dezelfde basis behoren. Bij gemiddelde, percentielscores en hoog/gevorderd staat de grootste waarde op rang 1; bij onder basisniveau, P90–P10 en de absolute kloofgrootte de kleinste. Dit behoudt de bestaande dashboardregels. Het teken van een kloof blijft in het bronresultaat bewaard. Gelijke ongeronde waarden na de expliciete transformatie krijgen de gemiddelde rang. Een rangverschil is geen bewijs van een statistisch significant verschil. Peer-rangen worden niet aangeboden. Een ranglijsttabel hoort alleen in de paper.

## Q01–Q08: inhoud en bewijs

| Dossier | Werkelijk gecontroleerd bewijs | Interpretatiegrens |
|---|---|---|
| Q01 | 17.617 SES-gerelateerde resultaatcellen, 489 bronbestanden, 6.925 analysegroepen; gewogen/ongewogen dekking, alle relevante PV's en opgeslagen N; nul N-afwijkingen. | Dekking bewijst geen aselecte ontbrekende waarden. De Nederlandse PIRLS-2021 Home-SES-dekking is ongeveer 47,7% gewogen; vermeld selectie. |
| Q02 | Officiële doelpopulaties, respons, uitsluitingen, afnamemodus en nationale voorbehouden voor alle 544 gebruikte land-cycli, met exacte tabellen, pagina's en hashes. | De gecombineerde Chinese-Taipei-afname 2006/2007 mist enkele gepubliceerde percentages. Die blijven onbekend. Responsgrenzen zijn geen automatische herstelprocedure. |
| Q03 | Auteurscommit `1da4b26097e84e732973af672355a1c3103d5d33`, viergolvenmodel met 13 items; kalibratie N=1.079.563; maximale parameterafwijking <8,2×10⁻¹¹. Alle 130 gebruikte canonieke scorebestanden sluiten exact aan op de gepinde toepassing. | Het auteursvalidatiepanel bepaalt onze dashboardlanden niet. |
| Q04 | Alle exacte taken en methodeafhankelijkheden onderzocht: nul gebruikte tweegolfanalyses. | Niet van toepassing, aantoonbaar uitgesloten; geen extra analyse om een historische eis af te vinken. |
| Q05 | Vaste parameters, velden, gewichten, scoreprojectie, ontbrekende componenten en imputatie gecontroleerd in 129 gebruikte land-golven, waaronder 41 buiten de oorspronkelijke kalibratielanden. | Meetinvariantie en negeerbare missingness buiten kalibratie blijven aannames; numerieke pariteit bewijst die niet. |
| Q06 | Exacte bron/resultaat/methodekoppelingen, volledige ankers, 6×3, gezamenlijke splits en leeromgevingen; echte referentiegemiddelden en rangafleidingen met oudercellen en gewichten. | Geen referentie- of rang-CI. Een onvolledig hoofdlandanker of onvolledige split blijft zichtbaar onvergelijkbaar. |
| Q07 | Gekozen PISA-SES behouden; geen officiële ESCS-robuustheidsanalyse. 774 bruikbare Home-SES-cellen: PIRLS 2021 en TIMSS 2023, uitsluitend appendix. | Geen Home-SES-trend: één bruikbare golf per studie. Oudere Home Resources is een ander construct en wordt niet eraan vastgeplakt. |
| Q08 | Twaalf retrospectief geregistreerde Nederlandse claims: zes langetermijngemiddelden en zes laatste SES-kloven; gezamenlijke PV/replicatiecovariantie voor de kloven. | Alleen drie PISA-trendtoetsen, met linking-onzekerheid en Holm-correctie. IEA-trendintervallen zijn conditioneel op de gelinkte schaal, zonder formele trendtoets. Hercontrole bij gewijzigde paperclaims. |

De openbare dossiers, volledige tabellen en bewijsidentiteiten staan in [scientific_review](review_20261013/scientific_review/SCIENTIFIC_REVIEW_MANIFEST.json). De onderliggende privébewijzen en leerlingbestanden worden niet gepubliceerd. `PAPER_CLAIMS.json` is nadrukkelijk een retrospectief register, geen preregistratie. De afzonderlijke dossiers maken kwalificaties zichtbaar; PASS betekent dat de gekozen analyse en beperkingen beoordeeld zijn, niet dat alle denkbare onzekerheid meetbaar is.

## Definities, drempels en onzekerheid

Bij PISA blijft de afzonderlijke meisjescategorie voorrang houden. Alleen waar die niet afzonderlijk in de geverifieerde bron voorkomt, geldt de expliciet goedgekeurde `Female / Other`-pooling met een eigen celidentiteit, label en herkomst. Nonrespons wordt niet gepoold. De Nederlandse 2025-bron bevat bij `ST004D01T` uitsluitend 99, terwijl `MALE` 3.237 Female / Other, 3.397 Male en twee ontbrekende waarden bevat. De gepoolde uitkomst wordt niet alsnog als meisjes-only gepresenteerd.

Migratie heeft drie afzonderlijke definities: minstens één buitenlandse ouder; beide buitenlandse ouders; en eerste/tweede generatie afzonderlijk. Voor de generatie-indeling zijn leerlinggeboorteplaats en beide buitenlandse ouders nodig; minstens één in het testland geboren ouder behoort tot de referentiecategorie. Logisch beslisbare gedeeltelijke antwoorden mogen classificatie toestaan, bijvoorbeeld één bekende buitenlandse ouder bij de any-parent-definitie. Onbeslisbare combinaties blijven ontbrekend. Daarom verschillen analysegroepen/noemers tussen definities. `MIGRATION_RECORDED_ANALYSIS_SAMPLES.csv` toont de aan bestaande bron- en methodebewijzen gekoppelde N per resultaat; de onafhankelijke achtergrondverificatie gebruikt dezelfde expliciete missingnesslogica. Er wordt geen derde generatie afgeleid. In PISA 2025 worden parent/guardian 1 en 2 niet ten onrechte moeder en vader genoemd.

PISA gebruikt de domeinspecifieke afkapwaarden voor onder niveau 2 en niveau 5/6; IEA gebruikt 475 en 625 op de eigen schaal. Onder basisniveau en hoog/gevorderd hebben dus verschillende grenzen en zijn geen complementen. Proporties en percentages blijven expliciet onderscheiden. De volledige maat-, drempel- en onzekerheidscontracten staan in `METHOD_CONTRACTS.csv` en het exacte grid.

De productie gebruikt de studentgewichten en alle voorgeschreven plausible values: vijf in de oudere PISA-cycli en IEA, tien in PISA vanaf 2015. PISA gebruikt 80 Fay-BRR-replicatiegewichten met factor 1/20; IEA gebruikt de cyclusgebonden JRR-constructie en factor. Peeranalyses sluiten de leerling zelf uit en onderscheiden directe leeromgeving van de gehele school; bij PISA is een programma binnen school geen universeel geobserveerde klas. Kloven worden uit gezamenlijke replicaties en PV-covariantie afgeleid, niet uit een optelsom van marginale SE's zonder covariantie.

De 2025-editie is gecontroleerd tegen officiële bronbeschikbaarheid en editie-identiteit; het grafiekjaar was geen vrijgavebewijs. De [officiële reader's guide](https://www.oecd.org/en/publications/pisa-2025-results-volume-i_73451bc5-en/full-report/reader-s-guide_0364240f.html) onderscheidt de analysedatabase van latere publieke updates. In de VS is ontbrekende achtergrondinformatie niet automatisch een niet-ingevulde oudervragenlijst: het nationale voorbehoud betreft mede niet-afgenomen leerlingvragenlijsten. Ook Nederlandse uitsluitingen en nonrespons, en relevante modusverschillen per cyclus, moeten bij conclusies zichtbaar blijven. De weergegeven steekproef/PV-intervallen omvatten geen onbekende nonresponsbias.

PISA en IEA, de SES-constructen en de twee leeftijden blijven afzonderlijke reeksen. Dit zijn herhaalde dwarsdoorsneden; geen individuele cohortontwikkeling of causaal effect.

## Vervolg binnen dezelfde keten

`START.R` en `RUN.R` blijven de ingang; `fixed-audit → fixed-produce → fixed-finalize` en de drie modi blijven intact. Er is geen nieuwe brede analyseopdracht. Herberekening is uitsluitend nodig als een geautoriseerde cel nieuw, ongeldig of aantoonbaar ontbrekend is. De inhoudelijke correcties hierboven vragen geen nieuwe leerlingberekeningen. De afsluiting bouwt wel opnieuw de betrokken bron-/scope-/referentie- en productkoppelingen.

De volgende productstap maakt dashboard, 21-slide-presentatie en Nederlandse paper uit deze gepinde basis. Zij moet de actuele publicatie-overlay behouden, de definitieve vergelijkingsregels aansluiten, de daadwerkelijke paperclaims opnieuw toetsen en de afzonderlijke product-/rechten-/replicatiecontroles afronden. Dat is geen reden om Q01–Q08 zonder bewijs open te laten of om al een definitieve publieke release te claimen.
