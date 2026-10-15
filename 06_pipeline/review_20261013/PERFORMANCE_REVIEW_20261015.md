# Uitvoeringsreview: snelheid, hervatten en bronkwaliteit

15 oktober 2026. De configuratie kiest `all_required`, zonder aanvullende selectiefilters. Er zijn 77.611 exacte doelen voor 34 landen die de bronregel 6×3 halen. Bij de gecontroleerde stop voor deze verbetering waren 2.850 doelen gecertificeerd, 3.597 specifiek onbeschikbaar en 71.164 nog open. Het internationale dashboard is dus nog niet volledig gevuld. Dit document vervangt geen scopebesluit.

## Geïmplementeerd en gecontroleerd

- De producent verwerkt alle plausible values samen in een matrix. Afkappuntindicatoren, sorteervolgorde en vaste school-/klasidentiteiten worden binnen een blok hergebruikt. De gekozen statistieken, alle officiële replicaties en de pooling blijven behouden.
- Lineaire taal- en migratieschattingen gebruiken maximaal zestien gewichtskolommen tegelijk. Groepscontrasten worden binnen elke replicatie berekend. Peerberekeningen gebruiken groepssommen met dezelfde zelfuitsluiting, ontbrekende categorieën en geldige noemers.
- Bij hervatten worden bewezen bronafwezigheden uit de uitvoeringslijst gehouden; ze blijven met redenen in het grid. Een ontbrekende Home-SES-appendix blokkeert geen beschikbare taaluitkomsten meer.
- De audit hergebruikt een bronbewijs pas na verse hashes van ruwe bron, canoniek bestand, volledig broncontract, certificaat en alle bewijsbestanden. Binnen één audit wordt dezelfde grote ruwe bron slechts eenmaal gehasht. Opnieuw inlezen van onveranderde PV-matrices en herschrijven van 525 identieke certificaten vervallen.
- Een proceslock wordt verkregen vóór een eventuele Git-update. Een tweede start kan daardoor de code van de lopende analyse niet wijzigen. `fixed-status` trekt geen Git-updates binnen. Echte procesbeëindiging en hervatten zijn getest; een identieke herhaling voegt geen berekening toe.

## Gemeten prestaties

De volgende metingen betreffen de geselecteerde producenten op dezelfde Windows-machine. Het zijn opeenvolgende metingen, geen gerandomiseerde benchmark. Bronlezen, onafhankelijke referentieberekening, certificering, audit en uploads komen daar nog bij.

| Blok | Cellen | Eerdere gemeten tijd | Nieuwe tijd |
|---|---:|---:|---:|
| Nederland PISA 2022 achtergrond | 30 | 12,53 s | 2,73 s |
| Nederland PISA 2022 prestatiepeers | 30 | 19,38 s | 14,89 s |
| Nederland PIRLS 2021 prestatiepeers | 10 | 6,57 s | 4,55 s |
| VAE PIRLS 2021 achtergrond | 24 | 92,68 s | 71,25 s |

De laatste allocatieverbetering bracht daarnaast VAE PIRLS 2021 kern van 39,03 naar 24,34 seconden en boeken-SES van 87,39 naar 46,93 seconden. Onafhankelijke controles omvatten acht echte blokken met 200 gekozen cellen. Maximale verschillen in schattingen, standaardfouten en gezamenlijke PV-/replicatiewaarden zijn kleiner dan 1,1e-11, ruim binnen de vastgelegde 1e-9-tolerantie. N is afzonderlijk gecontroleerd. Zie [machineleesbaar bewijs](international/PERFORMANCE_REVIEW_EVIDENCE.json). De twee `tests/verify_real_*_producer.R`-scripts reproduceren deze controles met expliciete private bronpaden en bestaande onafhankelijke certificaten.

Meer processen zijn nu geen verstandige standaard: deze laptop heeft 16 GiB RAM en tijdens de eerdere productie was circa 0,54 GiB fysiek geheugen vrij. Meerdere kopieën van de leerlingmatrices kunnen paging veroorzaken. Eerst minder allocaties en hergebruik, vervolgens eventueel een gemeten begrensde workerpool op een machine met voldoende vrij geheugen. Eén schrijver beheert de resultaatdatabase. Geen wijziging van BLAS, gewichten, PV-aantal, statistische definities of precisie om een tijdwinst te forceren.

De totale resterende productietijd is nog niet betrouwbaar gemeten. Reken op een langdurige run; de lokale bloktijden zijn geen bewijs voor een volledige doorlooptijd van enkele minuten. De voortgangs- en meetreceipts maken een latere schatting mogelijk. 64-bit getallen blijven behouden; gzip bespaart ruimte zonder schijnnauwkeurige afronding. De internationale eindomvang wordt na productie gemeten.

## Bron- en uitvoeringsbevindingen

De Nederlandse PISA-2025-genderbeperking en concrete voorbeelden staan in [de bronreview](PISA2025_GENDER_REVIEW.md). Een andere survey-package herstelt geen ontbrekende categorie. De huidige code gebruikt de officiële student- en replicatiegewichten en alle PV's; softwarevervanging is geen voorwaarde voor de overige productie.

De [Amerikaanse officiële technische toelichting](https://nces.ed.gov/surveys/pisa/pisa2025/technical-notes/) meldt dat ruim 40% geen leerlingvragenlijst kreeg en beperkt rapportage met die variabelen. Dit vereist controle van de daadwerkelijke constructdekking voordat Amerikaanse achtergrondreeksen internationaal vergelijkbaar of publiceerbaar worden verklaard. Een berekende waarde en brondekking zijn daarvoor niet genoeg; tracking-geslacht en vragenlijstvariabelen moeten afzonderlijk worden beoordeeld. De 6×3-kernregel wordt hierdoor niet stilzwijgend veranderd.

De gemelde RStudio-logfout en verbinding 10053 dateren na de eerdere opgeslagen productie. Bij controle bestaat de logmap en slaagt schrijven plus teruglezen van een tijdelijk testbestand. De historische oorzaak is niet bewezen; er zijn daarom geen rechten, antivirus- of RStudio-instellingen gewijzigd. De statistische checkpoints zijn onafhankelijk van de IDE-verbinding. Dezelfde run kan ook met `Rscript` buiten de IDE worden uitgevoerd.

## Uitvoeren

Gebruik de bestaande lokale wrapper met `lo.current.action = "produce-approved"`. De naam `RUN_CURRENT_NLD.R` is historisch; de JSON-configuratie bepaalt nu `all_required`. Git wordt eenmaal bijgewerkt, vervolgens blijft de berekencommit vast. De audit verifieert eerdere resultaten; de producent hervat ontbrekende goedgekeurde blokken. Na de gekozen productie worden gecertificeerde aggregaten met herkomst naar de ontwikkelbranch gestuurd en wordt de private Drive-kopie gecontroleerd. Na onderbreking hetzelfde commando herhalen. Geen tweede run starten zolang de eerste actief is; de lock weigert dat expliciet.

De huidige wijzigingen claimen geen voltooide internationale productie, echte rang-/referentiecertificaten, dashboardbediening of publicatierelease. De rangafleidingsfunctie is getest op gecontroleerde fixtures; integratie met echte volledige vergelijkingscontracten en producten blijft noodzakelijk.
