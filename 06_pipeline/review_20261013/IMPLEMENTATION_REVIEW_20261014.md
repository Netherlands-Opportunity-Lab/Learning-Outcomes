# Kritische implementatiereview — 14 oktober 2026

De bestaande keten is gerepareerd op de ontwikkelbranch van PR #5. De bron-ZIP en ongewijzigde eerdere inventarisatie zijn niet opnieuw uitgepakt of uitgevoerd. De oorspronkelijke audit blijft bronbewijs; onderstaande wijzigingen betreffen de actieve uitvoering en nieuwe expliciete besluiten.

## Wat daadwerkelijk is aangepast

- De drie modi gebruiken één bronregistry en de 6×3-regel. Het oorspronkelijke 79.448-key-bestand blijft een broncontract; het is geen verplichte productiescope. Ontbrekende dekking leidt niet tot vaste 19/20/42/50 aantallen. Buitenlandse productie vereist bovendien het gevraagde afzonderlijke landenbesluit.
- De referentieadapter controleert het hele hoofdlandanker en alle gezamenlijk aangeleverde vergelijkingscellen. Exacte vergelijkbaarheidsbewijzen binden brondefinities en resultaten. Geen jaarlijks wisselende leden, stille verkorting of SE op de gelijkgewogen referentie.
- De dispatcher gebruikt uitsluitend cellen met een exact doelcontract en expliciet bron-/methodebewijs. Veranderde bron, input, code of certificering maakt eerdere uitvoering ongeldig. SQLite-receipts ondersteunen hervatten; een identieke tweede run gebruikt de bestaande kandidaat. Nieuwe schattingen krijgen geen automatische wetenschappelijke vrijgave.
- Goedgekeurde uitbreidingen A04/A06/A11–A14 krijgen afzonderlijke contracten in hetzelfde grid. De echte estimator gebruikt PV/replicatiepooling en berekent geselecteerde statistieken. Klasanalyses verlangen echte klassen binnen scholen; een PISA-school×programma-proxy wordt niet als klas verkocht. SES-gender en Home-SES zijn appendixinhoud. A02/A03 zijn na de afzonderlijke antwoorden geactiveerd.
- Onder basisniveau naar SES wordt uit oudere boven-basisniveau-resultaten alleen via een expliciete eenheidsbewuste complementtransformatie afgeleid. De afleiding heeft een eigen hash en bewaart de ouderhash. Hoog/gevorderd gebruikt een andere drempel en is geen complement van onder basisniveau.
- De producttrace verbindt actieve bronvereisten en nieuwe menselijke keuzes aan exacte cellen, afleidingen, populatie-/methodevelden en bewijsstatus. Oude wetenschapsslides autoriseren hun inhoud niet zelfstandig.

## Werkelijk uitgevoerd lokaal bewijs

`fixed-audit` heeft op de huidige keuzes 2.526 Nederlandse doelcellen geregistreerd, met 518 archiefkandidaten, nul wetenschappelijk vrijgegeven cellen en nul geautoriseerde rekenbatches. Twee aansluitende `fixed-produce`-runs hebben daarom nul leerlingcellen geladen/berekend. Dit is een geslaagde technische audit met een lege geautoriseerde werkvoorraad, geen geslaagde niet-lege wetenschappelijke productie. De gedetailleerde grid-, bron- en producttracebestanden blijven lokaal/private opslag.

Lokale regressies controleren de exacte lees-/schrijfselectie, tweede identieke run, hervatten met een batchlimiet, gewijzigde bron/code/input, verkeerde bronidentiteit, extra output, uitsluiting van onbesliste analyses, dynamische landen buiten COMMON42, volledige groep×jaar-dekking, echte certificaatbestanden en de nieuwe goedgekeurde contracten. De Windows/Linux-CI op deze commit is het externe softwarebewijs; alleen werkelijk geslaagde runs worden als geslaagd gemeld.

## Kritische beoordeling van de voorstellen

De 6×3-regel is een toelatingsregel, geen bewijs dat elke gewenste vergelijking mogelijk is. De volledige Nederlandse jaar- en groepsbalans kan de standaardreferentie sterk verkleinen of leeg maken. Een leeg panel is een inhoudelijk resultaat van de regel; het mag niet stilzwijgend worden gerepareerd door jaren te verwijderen. Andere hoofdlanden kunnen andere passende referenties hebben. De interface moet dit uitleggen.

Twee afkappunten beperken het aantal uitkomsten, maar maken de berekening niet automatisch goedkoop. De kosten hangen ook af van leerlingaantallen, plausible values, replicaten, groepen en peereenheden. De minimale werkvoorraad wordt daarom uit werkelijk ontbrekende gecertificeerde cellen afgeleid, niet uit alle historische keys.

Een uniforme lange Home-SES-reeks is met de officiële moderne schaal niet over alle oude golven beschikbaar. De appendix moet het verschil tussen ontbrekende schaal, niet-afgenomen oudervragenlijst en selectieve respons expliciet tonen. Voor Nederland ontbreekt TIMSS-2023-Home-SES; PIRLS-2021 kent volgens IEA 47,7% SES-respons. Geen harmonisatie claimen door labels gelijk te trekken.

Het overnemen van de opgegeven PISA-SES-aanpak vereist een gepinde auteurversie en protocol. De twee-/viergolvenanalyses, 36-/34-auteurpanels en R/Python-verschillen zijn vastgelegd; een andere referentielandenlijst verandert de kalibratievraag. Dit is geen vrijbrief voor alle analyses uit de externe repository.

## Opslagbewijs en grenzen

Een oude identieke PISA-2022-bronkopie van 2.096.666.903 bytes is na verse SHA256-controle verwijderd. De blijvende kopie is gecontroleerd; vrije ruimte daarna 2.230.206.464 bytes. De laatste gebruikersopdracht staat verwijdering van herberekenbare projectbestanden toe zonder extra schijf; zij omvat geen persoonlijke data. Een 35,87 GB groot cache-benoemd archief bevat niet-projectmateriaal en bleef behouden.

Een kleine private Drive-overdracht is werkelijk teruggelezen en hersteld met dezelfde SHA256. Dit bewijst geen volledige back-up. De space-gate verlangt een gemeten pilotbudget en operationele reserve; zij is geen OS-quota. Een grote run en brede opruiming zijn niet uitgevoerd.

## Nog nodig om opdracht 1 volledig af te sluiten

De lokale bron- en methodecertificaten voor echte niet-lege productie ontbreken nog. Ook nodig: de concrete landenlijst met gecontroleerde dekking, actuele piekruimtemeting en voldoende begrensde werkruimte, gerichte archiefreconciliatie, en sluiting van de brondefinities voor SES/taal/migratie/klassen. Een succesvol synthetisch testresultaat sluit die wetenschappelijke eisen niet. Het probleemregister noemt deze open punten expliciet; de opdracht wordt niet als volledig klaar aangeduid.
