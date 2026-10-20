# Stap 2 — beoordeelde releasekandidaten voor current47

De aanvullende productreview is uitgevoerd op het bestaande werk van
20 oktober. De 36 uitgestelde landen en de volledige nieuwe leerlingbronreplicatie
vallen buiten deze opdracht. Er is geen nieuwe leerlinganalyse uitgevoerd.
De drie producten bestaan, zijn inhoudelijk gecontroleerd en gebruiken dezelfde
gecertificeerde resultaten. De gecorrigeerde paper is een nieuwe releasekandidaat;
de publicatie daarvan en van het bijgewerkte pakket hoort bij opdracht 3.

## Resultaatbasis en wijzigingsgrens

De wetenschappelijke basis blijft 90.829 doelen: 82.142 gecertificeerde
resultaten, 8.687 onderbouwd onbeschikbare doelen en nul open rekentaken.
De acht Q-dossiers, toelating per leeftijd-uitkomstcombinatie, volledige
referentieankers, gewichten, plausible values, peerdefinities en A-besluiten
zijn niet gewijzigd.

| Onderdeel | Vastgelegde identiteit |
|---|---|
| Beoordeelde basis vóór deze correcties | `27b4bb66942cf17ea6c5f482ffb8e83d637c80e2` |
| Resultaatcommit | `d36eea18980101ce354ebb05ce5f5d91280a70f8` |
| Ongewijzigde latere resultaatdepositie | `afd8bb1155c84d78e49dc3751f80b37c620abade` |
| Resultaatmanifest SHA256 | `5ab441b3036e794bcbc8e590fe2517619f0c5ed1ddae68e6cdd71593ed465122` |
| Wetenschappelijk manifest SHA256 | `c205f624793a9d55fc25ced02540f91466e5e0e78a8b69fe8c801b229c928965` |
| Faseconfiguratie SHA256 | `efa86d2a9ebb4a094f1bbd4d4b22978fd52b19af6e839e324aeecbcc4a456f43` |
| Live dashboardkandidaat | `ce55760e9df4f4b4428e` |
| Nieuwe paper-PDF SHA256 | `62026eedf668a8ca0d29d5f69e69bc7b7d0c8335b8b37983139c74bf2cd222aa` |
| Ongewijzigde PPTX SHA256 | `b80ec02032627e125a9839895a73516f43da744235a2d78acfc92ac83cc1df41` |

De voorbereidingsbranch is geïntegreerd in de gecontroleerde uitgangsbasis.
Afzonderlijke resultaatcommits en de nieuwere publicatiecode blijven behouden.
Voor het schrijven is gecontroleerd dat de werkboom schoon was en geen R- of
RStudio-schrijver actief was. De hier beschreven wijzigingen raken uitsluitend
productbouw, bewijscontrole en documentatie.

## Dashboard

De bestaande app in `05_publication/preview_overlay` blijft de gedeelde
Nederlandse/Engelse applicatie. De volgorde uitkomst/leeftijd, uitsplitsing,
weergave, hoofdland en beide standaard ingeschakelde schakelaars zijn bevestigd.
De onzekerheidsbediening en beperkingen staan onder de figuur.

De nieuwe uitvoerbare controle gebruikt de echte export en dezelfde selectielogica:

- alle 174 actieve figuurcontracten zijn bereikbaar via 204 toegestane
  dropdowncombinaties;
- alle 8.178 land-figuurcontracten zijn gecontroleerd;
- 63.384 getoonde hoofdlandpunten en 5.645 expliciete ontbrekende posities
  sluiten aan op de export;
- de standaardreferenties zijn constant binnen de volledige hoofdlandankers,
  sluiten het hoofdland uit en leveren 50.004 referentiepunten;
- rangfiguren bevatten geen groepslijn of onzekerheidsinterval;
- ontbrekende posities hebben in beide talen een specifieke reden; een
  ongeldig of leeg referentiepanel wordt niet verkort of met nullen gevuld.

Deze aantallen betreffen verschillende eenheden: de 5.645 ontbrekende
figuurposities zijn geen extra ontbrekende wetenschappelijke rekentaken.
Een resultaat kan in meer dan één productpositie voorkomen; kwaliteitsregels
kunnen een berekende cel terecht uit een figuur weren.

De live browserproeven omvatten desktop 1280×900 en mobiel 390×844,
landenzoeken, selecteren, lege groep, standaard herstellen, rang, Canada
met wel/niet toegelaten combinatie, gepoold geslacht, taalwisseling, URL-keuzes,
toetsenbordvolgorde en Escape met focusterugkeer. De JSON-download is daadwerkelijk
gedownload en op zestien hoofdlandwaarden, SE's, intervallen en resultaathashes
vergeleken met het resultaatbestand. De openbare JSON-serialisatie gebruikt
15 significante cijfers, de wetenschappelijke CSV 17. Het grootste gevonden
verschil is 4,55 × 10⁻¹³ scorepunt, ruim binnen de vooraf bestaande absolute
producttolerantie van 10⁻⁹; schermafronding wordt niet op de download toegepast.

Bewijs: `STEP2_DASHBOARD_SELECTION_RECHECK.json` en
`STEP2_BROWSER_RECHECK.json`. Eerdere volledige online SHA-controle blijft
geldig voor de ongewijzigde live dashboardbestanden.

## Presentatie

De bewerkbare presentatie behoudt het brondeck van 21 slides met `20261001`
in de naam. Zij telt 22 slides doordat de goedgekeurde lage en hoge peeruitkomst
ieder een eigen slide hebben. Het goedgekeurde hoge-SES-aandeel is naar de
appendix verplaatst. De oude 50 slides hebben geen extra analyses toegevoegd.

Alle 22 slides zijn opnieuw visueel bekeken. De 90 native PowerPointgrafieken
bevatten 3.436 gecontroleerde coördinaten. Hun exacte oudercellen, bronnoten,
full-year referenties en oorspronkelijke slidepositie staan in
`deck/POLICY_DECK_TRACE.json`. De PPTX, PDF en reproduceerbare figuurgegevens
blijven ongewijzigd. Er wordt geen optioneel langer deck gemaakt.

## Paper: concrete correcties en geschreven claims

De Nederlandgerichte paper bevat 29 pagina's met methoden, resultaten,
interpretatie, beperkingen, 112 land-rangposities, de goedgekeurde uitbreidingen
en appendices. De inhoud maakt onderscheid tussen afzonderlijke en gepoolde
meisjes, drie migratiedefinities, niet-afgenomen thuisvragenlijsten, andere
Home-SES-schalen, bronpopulaties en inferentiebeperkingen.

De review vond en repareerde drie concrete tekortkomingen:

1. Vrije ggplot-facetassen verborgen ontbrekende eindjaren. Bij PIRLS-migratie
   eindigde de as na de laatste waarneming. Alle 36 panelen houden nu de volledige
   vereiste jaren. Afwezige golven worden als asanker geregistreerd zonder
   nulwaarde of kunstmatig datapunt. De daadwerkelijk getrainde ggplot-assen
   worden bij de bouw gecontroleerd en vastgelegd.
2. Twee peerreeksen kregen door de standaardpalette dezelfde blauwe kleur.
   Alle leerlingen, leerlingen onder basisniveau en leerlingen daarboven hebben
   nu afzonderlijke semantische kleuren. Definities en waarden blijven gelijk.
3. De lopende tekst had minder precieze herkomstregistratie dan de tabellen.
   Alle 53 paragrafen hebben nu eigen tekst-ID's. Empirische conclusies verwijzen
   naar de exacte oudercellen van de twaalf bestaande paperclaims.

Daarnaast is de uitleg van procentweergave verduidelijkt: uitsluitend
proporties en hun SE worden met 100 vermenigvuldigd; bestaande percentages
blijven ongewijzigd.

`PAPER_WRITTEN_Q08_REVIEW.json` sluit de daadwerkelijk geschreven tekst opnieuw
aan op Q08. De zes trendclaims en zes SES-kloofclaims veranderen niet.
De drie formele PISA-trendtoetsen behouden linking-onzekerheid en Holm-correctie.
IEA-trends blijven beschrijvend; gezamenlijke SES-covariantie blijft behouden.
Er is geen nieuwe toetsfamilie, causale claim of cohortinterpretatie toegevoegd.
De claims zijn achteraf geregistreerd; de paper noemt dit geen preregistratie.

De paper is opnieuw gerenderd. Alle pagina's zijn geïnspecteerd; pagina's 4, 8
en 9 zijn zichtbaar veranderd en afzonderlijk beoordeeld. De overige 26 pagina's
zijn pixelgelijk aan de reeds beoordeelde versie. Geen clipping of overlap is
gevonden. Het bewijs staat in `PRODUCT_VISUAL_REVIEW.json` en
`PAPER_RENDER_COMPARISON.json`.

## Reconstructie, invalidatie en bewijs

Het gedeelde productregister is `PRODUCT_TRACE_INDEX.json`. De volledige
script/invoer/uitvoer-koppeling staat in
`04_products_or_release/current47/README.md`.
Het bewerkbare manuscript, de afzonderlijke bibliografie, zes SVG/PNG-figuren,
puntenbestanden, asankers, PPTX en beide PDF's staan in dezelfde productmap.

De bestaande `REBUILD_PRODUCTS.py` controleert het volledige bestandenmanifest
vóór herbouw. De aangescherpte productverificatie toetst 3.554 figuurpunten,
112 rangposities, alle native grafiekcoördinaten, tabelwaarden, 36 jaarassen
en 53 tekst-ID's tegen de exacte basis. Acht regressieproeven verwerpen
onder meer een verkorte as, een verdwenen ontbrekend jaar, een gewijzigde
abstractwaarde en een gewijzigde claimouder. De bestaande GitHub-workflow
voert deze controles en de aggregaatherbouw uit op Windows en Linux.

Gewijzigde resultaat-, bron-, methode-, beleids- of configuratiehashes vereisen
een nieuwe wetenschappelijke beoordeling. Een gewijzigde productbouwer,
tekst of figuur maakt de bijbehorende productcontrole ongeldig. Alleen een
nieuw manifest schrijven is geen goedkeuring. Het oude wetenschappelijke
bewijs wordt niet herschreven voor een vormgevingscorrectie.

## Reële grenzen en vervolg

De browserproeven gebruiken Chromium; fysieke iPhone/Safari is niet getest.
De presentatie is via de bestaande renderketen en structureel als native PPTX
gecontroleerd, zonder een afzonderlijke Microsoft PowerPoint-weergaveproef.
Dit zijn expliciete platformgrenzen, geen nieuwe wetenschappelijke HOLD.

Opdracht 3 moet de nieuwe paper en het gewijzigde replicatiepakket publiceren,
de online producthashes controleren en de releaseadministratie bijwerken.
De huidige live paper is nog de vorige versie. Geen nieuwe pupilberekening
of handeling in RStudio is nodig voor deze productcorrecties. De 36 uitgestelde
landen en de volledige bronreplicatie blijven buiten de huidige opdracht.
