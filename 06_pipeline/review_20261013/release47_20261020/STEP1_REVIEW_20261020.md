# Stap 1 — hercontrole van de bestaande wetenschappelijke basis

Beoordeling van 20 oktober 2026, na de gebruikerskeuze om **de 36 uitgestelde landen én de volledige nieuwe bronreplicatie later te doen**. De opnieuw ingevoerde historische opdracht verandert die afbakening niet. Ook de latere toelating per afzonderlijke leeftijd-uitkomstcombinatie blijft leidend.

## Uitkomst en precieze reikwijdte

**Stap 1 is afgesloten voor de huidige 47 landen en onderwijsstelsels, met de hieronder beschreven wetenschappelijke beperkingen.** Het gecontroleerde grid bevat 90.829 doelen: 82.142 gevalideerde resultaten, 8.687 onderbouwd onbeschikbare doelen en nul open rekentaken. Alle 101 geldige nulschattingen blijven resultaten. Er zijn geen doelen of uitkomsten verwijderd en geen leerlinganalyses herhaald.

De resultaatbasis is `d36eea18980101ce354ebb05ce5f5d91280a70f8`, met de onveranderde redepositie op `afd8bb1155c84d78e49dc3751f80b37c620abade`. De oorspronkelijke afsluiting en werkelijk uitgevoerde eindcontrole staan in [SCIENTIFIC_REVIEW_COMPLETION.json](SCIENTIFIC_REVIEW_COMPLETION.json). De nieuwe [machinecontrole](STEP1_EVIDENCE_RECHECK.json) herleest de opgeslagen bewijsstukken en exacte koppelingen. Zij schrijft geen goedkeuringen en is geen nieuwe bronreplicatie.

De eerdere resultaatcommit `ac9f0bdb…`, de toenmalige 34 landen en Q01–Q08 0/8 zijn historische standen. De huidige acht dossiers zijn inhoudelijk beoordeeld en aan de huidige resultaten gebonden. De 36 uitgestelde landen behouden hun doelen, eerdere resultaten en latere hervatconfiguratie. Zij leveren nu geen hoofdlanden of referentielanden.

## Wat opnieuw is gecontroleerd

- Alle 127 gebonden runtime-/beleidsbestanden en 46 openbare wetenschappelijke bewijsbestanden zijn op SHA256 vergeleken met de aanvaarde review. De enige toegelaten latere runtimewijziging is de afzonderlijk beoordeelde publicatiecontrole; geen schatter, brondefinitie of wetenschappelijke selectieregel is gewijzigd.
- Alle acht gedeponeerde resultaatbestanden en twaalf dekkingsbestanden komen overeen met hun manifest. Alle 90.829 doelidentiteiten, statussen en resultaatkoppelingen sluiten aan op de vastgelegde selectie.
- De producttrace bevat 326.460 koppelingen en 921 productplaatsingen voor 185 inhoudelijke eis-ID's. Eén inhoudelijke eis kan meerdere producten/figuren bedienen; dit zijn geen 921 afzonderlijke statistieken. Iedere plaatsing sluit aan op exacte goedgekeurde cellen en een geregistreerde afleiding.
- Alle 20.065 SES-bewijskoppelingen sluiten aan op dezelfde resultaat-, bron- en taakidentiteit en dezelfde ongewogen N.
- Alle 8.178 land-figuurcontracten blijven behouden. Het bewijs van de eerder uitgevoerde onafhankelijke controle van volledige jaren en groepsdekking is ongewijzigd.
- De twaalf Nederlandse paperclaims zijn opnieuw numeriek met hun ouders vergeleken: zes trends en zes SES-kloven. De zes kloven sluiten aan op de vastgelegde gezamenlijke covariantie; de drie formele PISA-trendtoetsen sluiten aan op linking-onzekerheid en de Holm-correctie.
- De lokale actuele en beoordeelde grids hebben dezelfde SHA256 `a3f41d058b94dd5d4136a1186cdbda2bcccd5285c34d7aa8acfb7f6934b1f38f`. Het goedkeuringsregister heeft SHA256 `bc6a6c78e0e4030b761a82fcb68a8742c27bb7b769a29ab9f6cd9fdcc99ed5ec`.

Uitvoerbaar met uitsluitend openbare repositorybestanden:

```sh
python scripts/verify_step1_current_release.py --repo . --output step1-proof.json
```

Dit is een compacte bewijscontrole, geen opdracht aan RStudio. De gerichte regressietests weigeren onder andere gewijzigde bronidentiteiten, extra resultaten, verwijderde doelen, verhulde nulresultaten en een onbeoordeelde wijziging van de schatter.

## Landen, meetgolven en referenties

De huidige 47 zijn: ALB, ARE, ARG, ARM, AUS, AUT, AZE, BEL, BGR, BHR, BRA, BRN, CAN, CHE, CHL, COL, CZE, DEU, DNK, ESP, FIN, FRA, GBR, GEO, HKG, HUN, IRL, ITA, LIE, LTU, LUX, LVA, MAR, NLD, NOR, NZL, POL, PRT, QAT, RUS, SAU, SGP, SVK, SVN, SWE, TWN en USA.

Van hun 282 mogelijke leeftijd-domeincombinaties zijn **241 bronmatig toegelaten**. De [volledige leesbare landentabel](CURRENT47_COMBINATION_COVERAGE.csv) vermeldt per land, leeftijd en domein alle vergelijkbare meetgolven, het toelatingsbesluit en de huidige resultaatdekking. Domeinonafhankelijke compositiematen staan eenmaal onder `domain=all` in het volledige dekkingsrapport en worden niet bij elk domein dubbel geteld. De oorspronkelijke grotere broninventaris blijft bewaard; deze hercontrole neemt geen nieuwe beslissing over de 36 uitgestelde landen.

Een land wordt voor een combinatie toegelaten bij minstens drie vergelijkbare meetgolven. Binnen iedere figuur moet de referentie alle hoofdlandjaren en gezamenlijk getoonde groepen/leeromgevingen dekken. Tussen figuren mag de referentie verschillen. Rijke kandidaten krijgen geen uitzondering. Nationale en regionale populaties worden niet samengevoegd: bijvoorbeeld Vlaamse of Engelse IEA-bestanden worden geen nationale BEL- of GBR-reeks. CAN en POL behouden hun geldige andere combinaties, maar voldoen niet aan de nationale vergelijkbare PIRLS-reeks.

De vaste rijke kandidatenlijst is onveranderd. Voor Nederlandse gemiddelde-scorereeksen levert de volledige balans de volgende standaardreferenties op:

| Combinatie | Nederlandse jaren | Passende rijke referentielanden |
|---|---|---|
| Lezen, leerjaar 4 / groep 6 | 2001, 2006, 2011, 2016, 2021 | DEU, FRA, ITA, SWE, USA |
| Wiskunde, leerjaar 4 / groep 6 | 2003, 2007, 2011, 2015, 2019, 2023 | AUS, ITA, USA |
| Natuurwetenschappen, leerjaar 4 / groep 6 | 2003, 2007, 2011, 2015, 2019, 2023 | AUS, ITA, USA |
| Lezen, 15 jaar | 2003, 2006, 2009, 2012, 2015, 2018, 2022, 2025 | AUS, BEL, CAN, CHE, DEU, DNK, FIN, FRA, IRL, ITA, NOR, SWE |
| Wiskunde, 15 jaar | dezelfde acht PISA-golven | AUS, BEL, CAN, CHE, DEU, DNK, FIN, FRA, IRL, ITA, NOR, SWE, USA |
| Natuurwetenschappen, 15 jaar | 2006, 2009, 2012, 2015, 2018, 2022, 2025 | AUS, BEL, CAN, CHE, DEU, DNK, FIN, FRA, GBR, IRL, ITA, NOR, SWE, USA |

Dit is geen standaardpanel voor iedere split: extra eisen aan SES, geslacht, taal, migratie of compositie kunnen het panel verder verkleinen. De [volledige referentietabel](../scientific_review/REFERENCE_BY_VIEW.csv) bevat iedere keuze, inclusief lege vergelijkingen. Een land telt even zwaar; het hoofdland wordt uitgesloten. Rang gebruikt dezelfde geselecteerde landen en het hoofdland eenmaal, zonder groepslijn. Exact gelijke ongeronde waarden krijgen een gemiddelde rang. De rangrichting en eventuele transformatie staan per maat in [RANK_PRODUCT_CONTRACT.json](../RANK_PRODUCT_CONTRACT.json).

## Dekking en wat terecht ontbreekt

Het [bestaande volledige dekkingsrapport](../grid_coverage/README.md) is de actuele rapportage van current47. Het oudere `grid_coverage_combination_scope` is historisch bewijs van de eerdere 34-landenstap.

| Hoofdreden | Doelen |
|---|---:|
| Resultaat beschikbaar | 82.142 |
| Schaal niet gedefinieerd in de cyclus | 3.429 |
| Benodigd bronveld niet geobserveerd | 3.259 |
| Leeromgeving niet geobserveerd | 1.140 |
| Analysegroep onbruikbaar | 309 |
| Officiële trend niet vergelijkbaar | 289 |
| Groepsdefinitie niet geobserveerd | 161 |
| Vragenlijst niet afgenomen | 63 |
| Domein niet geldig in deze bron | 37 |

De hoofdredenen tellen precies op tot 90.829. Een ontbrekende bronkoppeling is een andere categorie dan een niet-afgenomen vragenlijst; er zijn nu geen open bronkoppelingen in deze selectie. Er ontbreken geen nog uit te rekenen goedgekeurde current47-cellen. Onbeschikbaarheid wordt niet verholpen door nullen in te vullen of het hoofdlandanker in te korten.

Daarnaast hebben 1.412 berekende resultaten beperkte steekproefondersteuning. Deze kwaliteitstoets staat los van ontbrekendheid en laat de doelcellen intact. Zij beperkt gebruik in producten en claims; een geldig berekend getal is niet automatisch geschikt voor publicatie.

Voor volledige detailcontrole:

- [Per land, studie, leeftijd, domein, jaar en split](../grid_coverage/BY_EXACT_COMBINATION.csv).
- [Per product, slide/bronlocatie en figuur](../grid_coverage/REQUIREMENT_COVERAGE.csv).
- [Iedere product-celverbinding](../grid_coverage/PRODUCT_CELL_TRACE.csv.gz).
- [Exacte broneditie, populatie, definitie, methode, onzekerheid en hashes](../grid_coverage/EXACT_CELL_COVERAGE.csv.gz).
- [Ontbrekende cellen en hun redenen](../grid_coverage/MISSING_CELLS.csv).
- [Afzonderlijke beperkingen van analysegroepen](../grid_coverage/ANALYSIS_SUPPORT_RESTRICTIONS.csv).

## Inhoudelijke beoordeling Q01–Q08

| Controle | Bewijs en beoordeling | Blijvende interpretatiegrens |
|---|---|---|
| Q01 | 20.065 SES-resultaatcellen, 532 bestanden, 7.855 analysegroepen; gewogen/ongewogen dekking en nul N-afwijkingen. Onafhankelijke ondersteuningstoets voor alle 82.142 resultaten. | Missingness is niet bewezen aselect. Vooral beperkte Home-SES-ouderrespons moet zichtbaar blijven. |
| Q02 | Officiële steekproef-, populatie-, respons-, uitsluitings- en modusgegevens voor 888 eerder onderzochte broncontexten; onveranderd bewijs hergebruikt. | Niet-gepubliceerde percentages blijven onbekend. Lage respons wordt niet gerepareerd door een gewicht of klein p-getal. |
| Q03 | Gepinde auteurscommit `1da4b260…`, vier golven en dertien items; kalibratie N=1.079.563, parameterafwijking maximaal circa 8,1×10⁻¹¹. | Het kalibratiepanel bepaalt niet onze dashboardlanden. |
| Q04 | Exacte taken/methodeafhankelijkheden bevatten nul tweegolfanalyses. | Aantoonbaar niet van toepassing; geen nieuwe analyse toegevoegd. |
| Q05 | 169 canonieke scorebestanden, 164 gebruikte land-golven en 60 land-golven buiten kalibratie gecontroleerd; nul scoreafwijking. | Meetinvariantie en de imputatieaannames buiten kalibratie zijn aannames, geen bewezen empirische uitkomsten. |
| Q06 | 8.178 volledige figuurcontracten, 48 numerieke probes en aansluiting van de werkelijk uitgevoerde eindexport. | Geen verkorte ankers, wisselende jaarpanels, groepsrang of referentie-/ranginterval. |
| Q07 | Gekozen PISA-SES behouden; geen nieuwe officiële ESCS-analyse. Home-SES levert 819 cellen: PIRLS 2021 en TIMSS 2023. | Home-SES heeft per studie slechts één bruikbare golf: dus geen trend, geen koppeling aan oudere Home Resources. |
| Q08 | Twaalf retrospectief geregistreerde claims; zes SES-kloven met gezamenlijke covariantie; alleen drie PISA-trendtoetsen met linking-onzekerheid en Holm. | Geen preregistratieclaim; IEA-trends blijven beschrijvend met conditionele steekproef/PV-intervallen. Wijzigingen in de paper vereisen hercontrole. |

De [acht beoordelingen en bijbehorende dossiers](../scientific_review/SCIENTIFIC_REVIEW_MANIFEST.json) zijn ongewijzigd. De [twaalf claimuitkomsten](../scientific_review/PAPER_CLAIM_RESULTS.csv) en [exacte ouders](../scientific_review/PAPER_CLAIM_DEPENDENCIES.csv) blijven de basis voor de paper.

PISA 2025 is op 20 oktober opnieuw gecontroleerd op de [officiële databasepagina](https://www.oecd.org/en/data/datasets/pisa-2025-database.html) en [OESO-FAQ](https://www.oecd.org/en/about/programmes/pisa/pisa-frequently-asked-questions-faqs.html): de data zijn gepubliceerd op 8 september 2026; het definitieve technische rapport wordt in 2027 verwacht. Dit bevestigt beschikbaarheid, niet zelfstandig de identiteit van iedere lokale rij. Die identiteit volgt uit de bestaande broncertificaten. De reeds bewaarde officiële NCES-linkingtabel is opnieuw op haar geregistreerde SHA256 gecontroleerd; een nieuwe online opvraag van die pagina gaf een timeout.

Afzonderlijke meisjes blijven de eerste keuze. Alleen in de goedgekeurde bronnen zonder die categorie wordt `Female / Other` gebruikt, met een eigen label en definitie; ontbrekende antwoorden tellen niet als meisje. De drie migratiedefinities behouden hun eigen noemers en missingnessregels. Er wordt geen derde generatie afgeleid. PISA en IEA, hun prestatiedrempels, SES-constructen en leeftijden blijven onderscheiden. Alle uitkomsten zijn beschrijvend voor herhaalde dwarsdoorsneden; zij bewijzen geen causale effecten of individuele cohortontwikkeling.

## Hersteld en bewust behouden

De actieve ingang, acceptatietabel en PR verwezen nog naar een onmiddellijk te starten volledige bronreplicatie. Dat is na de laatste gebruikerskeuze vervangen door expliciet uitstel. Ook zijn oude actuele formuleringen over 34 landen, 267 productvereisten en 42 numerieke probes gecorrigeerd of als historische stand aangeduid.

Wetenschappelijke manifesten, oude uitvoeringsontvangsten en historische bronbestanden blijven bytegetrouw behouden. Een oud veld zoals `public_deployment: false` beschrijft het moment van die wetenschappelijke controle. Het verandert niet de later bewezen publicatie; die staat in [CURRENT47_DELIVERY.json](CURRENT47_DELIVERY.json). Ook de oude implementatiestatus in de gehashte balanspolicy is historische metadata: de actuele export en website zijn getoetst op strikte balans.

Voor deze stap is nu geen RStudio-commando nodig. De volgende opdracht kan de bestaande producten van stap 2 grondig controleren en alleen aangetroffen fouten herstellen. De volledige nieuwe bronreplicatie en productie voor de 36 uitgestelde landen blijven **niet uitgevoerd en uitgesteld**, niet ten onrechte geslaagd.
