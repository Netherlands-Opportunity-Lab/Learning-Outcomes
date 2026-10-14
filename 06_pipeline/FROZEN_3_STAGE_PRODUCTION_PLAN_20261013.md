# Vast protocol: drie R-fasen binnen vier resterende werkopdrachten

Actuele versie: 14 oktober 2026. Dit is een correctie van het protocol van 13 oktober; die versie blijft in Git-history bewaard. Lees eerst [START_HIER_ACTUEEL.md](START_HIER_ACTUEEL.md). De **drie actienamen blijven gelijk**. De oude verplichte 42/50-landenaantallen, lage-peeruitbreiding en verplichte 50-slideproductie zijn vervangen door de latere gebruikersbesluiten.

## Configuratie vóór uitvoering

Gebruik één kleine checkout van de gecontroleerde code en één expliciete configuratie voor bronlocaties, private Drive, tijdelijke werkruimte en scope. Kies `nld_only`, `nld_plus_19` of `all_required` volgens het actuele besluitregister. Deze namen zijn geen certificaat van 1/20/50 dashboardleden. Houd LO_SCOPE binnen dezelfde uitvoering gelijk. Een nieuwe scope krijgt een eigen ledger en hergebruikt passende bestaande bewijsstukken.

De grote bronbestanden mogen op C: blijven; tussenresultaten gaan naar private Drive, definitieve gecontroleerde producten naar GitHub. Meet voldoende piekruimte vóór echte productie. De oude compacte producent blijft geblokkeerd totdat exacte gecertificeerde celsturing is geïmplementeerd. De nieuwe A01-scopecontrole heft deze afzonderlijke blokkade niet op.

## Fase 1 — fixed-audit

Hoort bij [opdracht 1](VIER_RESTERENDE_OPDRACHTEN_20261014.md#1-maak-de-gekozen-scope-en-de-volledige-productieketen-uitvoerbaar).

- Verifieer gewijzigde bronnen en relevante bewijsstukken; herhaal geen ongewijzigde SHA-bewezen inventarisaties.
- Gebruik het actuele productregister en de expliciete A-besluiten. Historische keys, figuren en bronpresentaties zijn geen vereiste rekenvoorraad.
- Bouw exacte celidentiteiten en afleidingsrelaties met geverifieerde populatie-, bron-, methode- en onzekerheidsidentiteit.
- Inventariseer/reconcilieer werkelijke hergebruikskandidaten. Vul alleen wetenschappelijk gecertificeerde waarden.
- Maak per cel REUSE_VERIFIED / DERIVE / COMPUTE_REQUIRED / UNAVAILABLE / HOLD met bewijs en herstelactie. Definieer nieuwe lage-peertaken uitsluitend als A01 is goedgekeurd; de oude hoge-peercellen blijven andere uitkomsten.
- Certificeer dashboardinclusie met 6×3 en referentiegeschiktheid met volledig hoofdlandanker plus gezamenlijke groeps-/compositiedekking. Geen vaste eindtellingen afdwingen.
- Maak de minimale goedgekeurde batchvoorraad en een hervatbare ledger. Toets echte bronadapter en runtime-routing; een helper alleen is geen integratie.

Exit: exact geadjudiceerd grid, uitvoerbare goedgekeurde batches, werkruimte en bron-/methodebewijs. Geen nieuwe leerlingberekening of publicatie. Een inhoudelijk open A-besluit blokkeert alleen de betrokken uitbreiding.

## Fase 2 — fixed-produce

Hoort bij [opdracht 2](VIER_RESTERENDE_OPDRACHTEN_20261014.md#2-produceer-en-valideer-alle-gekozen-resultaten).

- Consumeer uitsluitend het gepinde fase-1-grid en de bijbehorende input-/methodecertificaten.
- Voer alleen gekozen, aantoonbaar nog ontbrekende cellen uit met de juiste survey/golf/PV/replicatie en exacte steekproef.
- Geen adapter mag intern een bredere taaklijst reconstrueren of een optionele maat verplicht maken.
- Hergebruik gelijke geldige fingerprints; hervat per checkpoint, begrens geheugen/tijdelijke ruimte en open gedeelde bronnen doelmatig.
- Bewaar N, estimate, geldige SE/covariantie, definities, bron-, code- en resultaathashes met echte logs.
- Synchroniseer toegestane tussenresultaten en herstelbewijs naar private Drive. Een mislukte sync laat het geldige lokale resultaat intact en krijgt SYNC_PENDING.
- Herstel fouten gericht; ga door met onafhankelijk uitvoerbare batches. Geen technisch succes omzetten in automatische wetenschappelijke vrijgave.

Exit: alle gekozen haalbare cellen gevalideerd en noodzakelijke bron-/methode-/Q01–Q08-controles onderbouwd; werkelijk onbeschikbare cellen afzonderlijk verantwoord. Onopgelost benodigd bewijs is geen voltooide productie.

## Fase 3 — fixed-finalize

Productbouw hoort bij opdracht 3; onafhankelijke replicatie en publicatie bij opdracht 4 in [de vier resterende opdrachten](VIER_RESTERENDE_OPDRACHTEN_20261014.md).

- Certificeer één immutable resultaatbasis, Q01–Q08, rechten, bron-/methodeherkomst en alle gekozen productafhankelijkheden.
- Bouw werkelijk het 21-slide beleidsdeck, de paper, resultaatfiguren en het actieve dashboard; een langer wetenschappelijk deck alleen als gekozen en zonder onbesliste inhoudelijke uitbreiding.
- Integreer dynamische landenregistratie en echte referentievinkjes in preview_overlay. Geen per-golf wisselende landen, hoofdland in eigen gemiddelde of referentie-SE/CI.
- Gebruik laatste huisstijl en controleer werkelijke renders, Nederlandse interpretatie, NL/EN-, bron- en exportpariteit.
- Een private technische preview kan vóór wetenschappelijke afronding bestaan, maar blijft als onvrijgegeven preview herkenbaar; zij telt niet als eindproduct.
- Reproduceer schoon uit gedocumenteerde bronnen/omgeving, zonder verborgen oude caches. Voeg FAIR metadata, licentie/toegangsroute, hashes, citatie en runtime-instructies toe.
- Maak een concrete releasekandidaat. Publiceer alleen na de bestaande vrijgavevoorwaarden en toepasselijke autorisatie. Controleer de werkelijke Pages-site na deployment; bewaar historische release en rollback.

Exit: aantoonbaar reproduceerbare resultaten, echte producten en gevalideerde publicatie, of exact benoemde externe/besluitafhankelijkheid. Een nieuw plan, lege grafiek of groene CI vervangt deze bewijzen niet.

## Eén RStudio-ingang, geen nieuwe runner

Onderstaand schema beschrijft de vaste acties. Geef de gebruiker pas een kopieerbaar lokaal commando wanneer repo/configuratie, werkruimte en relevante CI zijn gecontroleerd; raad geen lokaal checkoutpad.

```r
# repo bevat het werkelijk gecontroleerde lokale checkoutpad.
Sys.setenv(LO_REPO_ROOT=repo, LO_SCOPE="nld_only", LO_START_ACTION="fixed-audit")
source(file.path(repo, "START.R"), encoding="UTF-8")
# Later, met dezelfde repo/configuratie/scope en de vereiste fasebewijzen:
Sys.setenv(LO_START_ACTION="fixed-produce")
source(file.path(repo, "START.R"), encoding="UTF-8")
Sys.setenv(LO_START_ACTION="fixed-finalize")
source(file.path(repo, "START.R"), encoding="UTF-8")
```

`fixed-status` is alleen-lezen. `fixed-cleanup-plan` is een afzonderlijke reviewactie, geen vierde wetenschappelijke fase en geen toestemming tot wissen. Volg de bestaande dependency-, back-up-, herstel-, quarantaine- en gebruikersvoorwaarden uit het actuele startdocument. Plan noodzakelijke werkruimte in opdracht 1, rond brede opslagafsluiting af in opdracht 4.

## Huidige implementatiegrens

De bronnenaudit en synthetische balansfuncties zijn beschikbaar. De A01-controle is aangesloten op audit, compacte taakopbouw en finale kwaliteitstoets. Echte broncertificering, dynamische scope in alle legacy-adapters, exacte celsturing, referentievinkjes en nieuwe gevalideerde producten zijn nog resterend werk. Zie [ACCEPTATIE_EN_VOORTGANG.csv](ACCEPTATIE_EN_VOORTGANG.csv) voor bewijs per onderdeel. De autorisatie van overige A-uitbreidingen vereist ook samenhangende celcontracten, adapters en tests; alleen een statusveld wijzigen is onvoldoende.
