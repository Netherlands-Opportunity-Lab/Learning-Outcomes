# Kritische implementatiereview — 14 oktober 2026

Aanvullend gebruikersbesluit A09: rangontwikkeling is gekozen als tijdreeks in de figuurbouwer; een landenranglijst uitsluitend in de wetenschappelijke paper. De koppeling aan oude 13-/32-/45-landenpanels is losgemaakt. Het actuele productgrid registreert exacte kandidaat-oudercellen voor de afleiding, zonder nieuwe leerlingtaken of automatische uitbreiding van appendixinhoud naar het dashboard. Regressies controleren deze scheiding en behoud bij hergeneratie. De gebruiker heeft verduidelijkt: geen groepsrang; het hoofdland en eventueel één ander land krijgen hun rang binnen een gekozen landengroep. De populatie is bevestigd als internationaal vierde leerjaar / Nederlandse groep 6. Numerieke rangafleiding en bediening zijn nog geen opgeleverd product. Zie RANK_PRODUCT_CONTRACT.json.

De bestaande keten is gerepareerd op de ontwikkelbranch van PR #5. De bron-ZIP en ongewijzigde eerdere inventarisatie zijn niet opnieuw uitgepakt of uitgevoerd. De oorspronkelijke audit blijft bronbewijs; onderstaande wijzigingen betreffen de actieve uitvoering en nieuwe expliciete besluiten.

## Wat daadwerkelijk is aangepast

- De drie modi gebruiken één bronregistry en de 6×3-regel. Het oorspronkelijke 79.448-key-bestand blijft een broncontract; het is geen verplichte productiescope. Ontbrekende dekking leidt niet tot vaste 19/20/42/50 aantallen. Buitenlandse productie vereist bovendien het gevraagde afzonderlijke landenbesluit.
- De referentieadapter controleert het hele hoofdlandanker en alle gezamenlijk aangeleverde vergelijkingscellen. Exacte vergelijkbaarheidsbewijzen binden brondefinities en resultaten. Geen jaarlijks wisselende leden, stille verkorting of SE op de gelijkgewogen referentie.
- De dispatcher gebruikt uitsluitend cellen met een exact doelcontract en expliciet bron-/methodebewijs. Veranderde bron, input, code of certificering maakt eerdere uitvoering ongeldig. SQLite-receipts ondersteunen hervatten; een identieke tweede run gebruikt de bestaande kandidaat. Nieuwe schattingen krijgen geen automatische wetenschappelijke vrijgave.
- Goedgekeurde uitbreidingen A04/A06/A11–A14 krijgen afzonderlijke contracten in hetzelfde grid. De echte estimator gebruikt PV/replicatiepooling en berekent geselecteerde statistieken. Klasanalyses verlangen echte klassen binnen scholen; een PISA-school×programma-proxy wordt niet als klas verkocht. SES-gender en Home-SES zijn appendixinhoud. A02/A03 zijn na de afzonderlijke antwoorden geactiveerd.
- Onder basisniveau naar SES wordt uit oudere boven-basisniveau-resultaten alleen via een expliciete eenheidsbewuste complementtransformatie afgeleid. De afleiding heeft een eigen hash en bewaart de ouderhash. Hoog/gevorderd gebruikt een andere drempel en is geen complement van onder basisniveau.
- De producttrace verbindt actieve bronvereisten en nieuwe menselijke keuzes aan exacte cellen, afleidingen, populatie-/methodevelden en bewijsstatus. Oude wetenschapsslides autoriseren hun inhoud niet zelfstandig.

## Werkelijk uitgevoerd lokaal bewijs

`fixed-audit` registreert 2.526 Nederlandse doelcellen, 512 resterende archiefkandidaten en negen onafhankelijk gecontroleerde kerncellen. De echte controller heeft die negen exact goedgekeurde cellen berekend en bij de tweede run hergebruikt. Na controle accepteert de audit ze via de archieffill; nul geautoriseerde rekenbatches blijven over. De volledige resultaatrelease vereist nog controle van de overige resultaten. De gedetailleerde grid-, bron- en producttracebestanden blijven lokaal/private opslag.

Lokale regressies controleren de exacte lees-/schrijfselectie, tweede identieke run, hervatten met een batchlimiet, gewijzigde bron/code/input, verkeerde bronidentiteit, extra output, uitsluiting van onbesliste analyses, dynamische landen buiten COMMON42, volledige groep×jaar-dekking, echte certificaatbestanden en de nieuwe goedgekeurde contracten. De Windows/Linux-CI op deze commit is het externe softwarebewijs; alleen werkelijk geslaagde runs worden als geslaagd gemeld.

## Kritische beoordeling van de voorstellen

De 6×3-regel is een toelatingsregel, geen bewijs dat elke gewenste vergelijking mogelijk is. De volledige Nederlandse jaar- en groepsbalans kan de standaardreferentie sterk verkleinen of leeg maken. Een leeg panel is een inhoudelijk resultaat van de regel; het mag niet stilzwijgend worden gerepareerd door jaren te verwijderen. Andere hoofdlanden kunnen andere passende referenties hebben. De interface moet dit uitleggen.

Twee afkappunten beperken het aantal uitkomsten, maar maken de berekening niet automatisch goedkoop. De kosten hangen ook af van leerlingaantallen, plausible values, replicaten, groepen en peereenheden. De minimale werkvoorraad wordt daarom uit werkelijk ontbrekende gecertificeerde cellen afgeleid, niet uit alle historische keys.

Een uniforme lange Home-SES-reeks is met de officiële moderne schaal niet over alle oude golven beschikbaar. De appendix moet het verschil tussen ontbrekende schaal, niet-afgenomen oudervragenlijst en selectieve respons expliciet tonen. Voor Nederland ontbreekt TIMSS-2023-Home-SES; PIRLS-2021 kent volgens IEA 47,7% SES-respons. Geen harmonisatie claimen door labels gelijk te trekken.

Het overnemen van de opgegeven PISA-SES-aanpak vereist een gepinde auteurversie en protocol. De twee-/viergolvenanalyses, 36-/34-auteurpanels en R/Python-verschillen zijn vastgelegd; een andere referentielandenlijst verandert de kalibratievraag. Dit is geen vrijbrief voor alle analyses uit de externe repository.

## Opslagbewijs en grenzen

Een oude identieke PISA-2022-bronkopie van 2.096.666.903 bytes is na verse SHA256-controle verwijderd. De blijvende kopie is gecontroleerd; vrije ruimte daarna 2.230.206.464 bytes. De laatste gebruikersopdracht staat verwijdering van herberekenbare projectbestanden toe zonder extra schijf; zij omvat geen persoonlijke data. Een 35,87 GB groot cache-benoemd archief bevat niet-projectmateriaal en bleef behouden.

Een kleine private Drive-overdracht is werkelijk teruggelezen en hersteld met dezelfde SHA256. Dit bewijst geen volledige back-up. De space-gate verlangt een gemeten pilotbudget en operationele reserve; zij is geen OS-quota. Een grote run en brede opruiming zijn niet uitgevoerd.

## Aanvullende echte uitvoering en grens met opdracht 2

Aanvullend werkelijk bewijs na de eerste commit: een begrensde proef op 5.046 Nederlandse PISA-2022-leerlingen berekende negen gekozen kerncellen, met 10 PV's en 80 replicatiegewichten. De negen schattingen/SE's zijn eindig; circa 3,4 seconden rekentijd. De gemiddelden ronden af op 493/459/488, overeenkomstig de [OESO-trendtabel](https://www.oecd.org/en/publications/pisa-2022-results-volume-i_53f23881-en/full-report/overview-of-performance-trends_ae540546.html). Dit is afgeronde externe puntpariteit, geen volledige onafhankelijke bron-/SE-certificering. De werkelijke R-procespiek bedroeg 205.651.968 bytes; een afzonderlijke tempmap werd iedere 100 ms gecontroleerd, met nul waargenomen tijdelijke bytes. Dit budget geldt uitsluitend voor deze proef.

De proef leidde tot concrete reparaties: de bootstrap laadt statistische functies zonder de oude brede cache-inventarisatie; de Windows UTF-8-inleesfout is hersteld. Daarnaast bleken AGE en de thuistaalclassificatie in de bestaande Nederlandse cache te ontbreken terwijl de oorspronkelijke bron beide bevat. Zes gerichte bronkolommen zijn gelezen en op exact leerling-ID en gelijk hoofdgewicht gekoppeld. Leeftijd is hersteld; gewogen taalclassificatiedekking is 96,52706%. De oorspronkelijke bron/cache bleven behouden; de reparatie krijgt eigen bronhashes en wordt niet stilzwijgend als oude gevalideerde input hergebruikt. Taal blijft relatief aan de individuele toetstaal, geen Nederlands/niet-Nederlands-identiteit voor alle landen.

Na metadata- en verse hashcontrole zijn ook 38 oude afgeleide PISA-2022-caches verwijderd, samen 1.005.942.625 bytes. Nieuwere caches, ruwe bron en vier broncodebestanden zijn aantoonbaar behouden. Totaal verwijderd in deze opdracht: 3.102.609.528 bytes; vrije ruimte direct na die tweede selectie: 3.167.223.808 bytes. De code-/pad-/hashreceipts blijven privé. Geen complete map is verwijderd.

De niet-lege productietoets is inmiddels via de echte controller uitgevoerd. Alle 111 gebruikte bronkolommen en de exacte 5.046 leerling-ID’s zijn gelijk aan de ruwe bron. Een afzonderlijke matrixberekening reproduceert de negen schattingen en PV/Fay-BRR-standaardfouten binnen 1e-9. Eerst negen nieuwe cellen, daarna nul nieuwe en negen hergebruikte cellen; vervolgens negen gecontroleerde cellen via de archieffill en nul resterende geautoriseerde rekenbatches. De private finalize-route is uitgevoerd en verleent terecht geen volledige vrijgave: 2.373 actieve gaten en Q01–Q08 blijven voor opdracht 2. Volledige landen-/groepscertificering hoort volgens de oorspronkelijke vier opdrachten bij opdracht 2; de eerdere acceptatietoewijzing R02 is daarop gecorrigeerd. Geen inhoudelijke bewijsregel is verlaagd.

## Herstelde dashboardbasis en extra fouten uit de echte ketentest

De menselijke keuze voor de archiefversie van 1 oktober is verwerkt in de actieve frontend. Desktop en mobiel, NL/EN, woordmerkfont Inter en dashboardfont Oswald zijn daadwerkelijk gerenderd en gecontroleerd; geen horizontale overflow of JavaScript-fouten. De visuele preview gebruikt herkenbaar historische cijfers en is geen nieuwe wetenschappelijke release.

De echte finalize-route onthulde dubbele generatie van de nieuwe peercontracten. Dat is gerepareerd met regressie en succesvolle herhaling. De preview-identiteit omvat voortaan ook frontendbestanden, font-/logo-assets en referentie-export; oude previews kunnen een vormgevingswijziging niet langer verbergen. Ontbrekende intervallen tellen niet meer als nul; een referentiegroep krijgt geen interval. De finale kwaliteitscontrole verifieert nu de echte bron-/certificaatbestanden, ook voor peers. Broncertificaten vereisen hash-gecontroleerde bewijsbestanden; landen zonder bewijs worden niet meer als SHA-gecontroleerd omschreven.

Een private Drive-hersteltest van het echte bewijspakket is geslaagd: 28 bestanden bytegelijk, SQLite opent zonder integriteitsfout, negen resultaatrijen en negen receipts behouden. Dit vervangt de eerdere uitsluitend kleine receiptproef voor dit beperkte uitvoeringspakket; het is geen claim over alle brondata.

### Laatste gerichte ruimtecontrole

Nog 39 oude afgeleide PISA-2025-caches zijn na controle van metadata, bron, code en actuele hashes verwijderd; hun nieuwere opvolgers blijven bewaard. Deze selectie betreft herberekenbare oude versies, niet byte-identieke kopieën. Dit maakte 1.137.380.683 bytes vrij. Totaal van de drie gerichte selecties: 4.239.990.211 bytes. Direct na deze selectie was 2.772.025.344 bytes vrij op C:. De vrije systeemruimte fluctueert; het batchbudget en de reservecontrole blijven vóór iedere nieuwe run verplicht. Er is geen volledige projectmap verwijderd. Het actuele Drive-pakket bevat ook de bevroren onafhankelijke controlecode en is opnieuw volledig teruggehaald en gecontroleerd.
