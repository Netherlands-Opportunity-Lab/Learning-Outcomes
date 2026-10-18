# Vijf keuzes, één figuur — uitwerking en acceptatie

## Leidende opdracht

Op 15 oktober vraagt de gebruiker het dashboard volledig af te werken terwijl
RStudio de resultaten produceert. Rust, vijf hoofdkeuzes en de eerder gekozen
figuren zijn leidend. Dit besluit vervangt de verplichte aparte startpagina en
de losse knoppen uit de eerdere versie; de visuele opzet van 1 oktober blijft.
De nieuwe Kansenlab-overdracht 1.1.0 vervangt eerdere web-/logo-specificaties.
Het pakket is als vormgevingsbron gelezen, niet als nieuwe onderzoeksscope.

## Bedieningsplan en implementatie

1. **Hoofdland.** Alle landen uit de dynamische 6×3-brontoelatingsregistratie.
   Een bron-toegelaten land kan nog lege figuren hebben: toelating is geen
   certificering van al zijn resultaten. Geen vaste 19, 20, 42 of 50 landen.
2. **Uitkomst en leeftijd.** Precies zes combinaties: lezen, wiskunde en
   natuurwetenschappen, elk voor internationaal vierde leerjaar/Nederlandse
   groep 6 of 15-jarigen. PIRLS en TIMSS blijven onderscheiden.
3. **Statistiek.** Gemiddelde, onder basisniveau, hoog/gevorderd, de vastgelegde
   percentielen/spreiding en waar goedgekeurd het groepsverschil. Alleen
   statistieken uit het actieve figuurcontract staan in de lijst. Rang is een
   expliciete variant van de gekozen statistiek; geen nieuwe leerlingberekening.
4. **Uitsplitsing.** Alle leerlingen, geslacht, SES, taal en de afzonderlijke
   migratiedefinities. Leeromgeving is een apart onderdeel van dezelfde lijst:
   directe omgeving/gehele school en prestaties/SES/taal/migratie. Geen nieuwe
   kruisingen; appendix- en wetenschappelijke uitbreidingen blijven apart.
5. **Internationale vergelijking.** Schuif aan/uit, met een dialoog voor landen.
   Standaard is de aantoonbaar passende subset van rijke OESO-kandidaten, zonder
   hoofdland. Ieder land telt even zwaar. Een eigen lege selectie blijft leeg.
   Onvergelijkbare landen blijven zichtbaar met uitleg en zijn niet selecteerbaar.

De vier onderzoeksvragen blijven uitklapbare snelkoppelingen. De grote witte
figuur bevat titel, populatie, meetjaren, definities en een rustige bronregel.
Methode, getoonde gegevens, SVG/CSV/JSON-downloads en delen zijn secundair.
De gehele selectie, inclusief een lege of aangepaste referentiegroep, staat in
de URL en blijft bij een taalwisseling behouden.

## Inhoudelijke preciseringen

- Gemiddelde score is een score per domein, geen samengestelde totaalscore.
- Onder basisniveau en hoog/gevorderd zijn verschillende afkappunten; beide
  kunnen bestaan. De overbodige complementfiguur komt niet terug.
- Rang gebruikt dezelfde gekozen referentiegroep. Alleen hoofdland en eventueel
  één aangevinkt ander land krijgen lijnen. Geen internationale groepsrang,
  groepsgemiddelde-rang of landenranglijst op het dashboard.
- Rang 1: hoogste gemiddelde/percentiel/hoogvaardig aandeel; laagste aandeel
  onder basisniveau of spreiding; kleinste absolute groepskloof bij gap-rang.
  Deze expliciete presentatieregels staan in `RANK_RULES`. Gelijke waarden krijgen
  gemiddelde rangen. Punt-rangen impliceren geen significant verschil.
- Peers krijgen geen automatische normatieve rangorde. Beide goedgekeurde
  prestatiestaarten en de bestaande compositiematen blijven als waarden bereikbaar.
- Bij ‘meisjes + other’ blijven de echte labels zichtbaar en wordt een verandering
  van categorie niet door een ononderbroken lijn verhuld. Er vindt geen imputatie plaats.
- De referentiegroep gebruikt volledige passende jaren én alle samen getoonde
  groepen en composities. De Nederlandse volledige kernankerregel blijft gelden.
  Een gewijzigde figuur verkort nooit de periode om een eigen selectie passend
  te maken. Een niet meer passende selectie krijgt een melding.

## Resultaten toevoegen via de bestaande keten

`fixed-finalize` gebruikt `LO_FINAL_GUIDED_EXPORT.R` en vervolgens
`LO_FINAL_GUIDED_DASHBOARD_BUILD.py`. Er is geen aparte rekenroute toegevoegd.
De export bewaart nu het exacte `cell_id`. De gecertificeerde balansuitvoer
bewaart afzonderlijk `view_cell_ids`, naast het volledige kernanker. De bouwer
verbindt die IDs en maakt `data/explorer_references.json`.

Alle benodigde balansviews moeten passen; hun landenverzamelingen worden
doorsneden. Een land moet bovendien de volledige figuurpayload hebben. Oude
exports zonder de nieuwe ID-koppeling blijven expliciet in afwachting. Een
browser kan ontbreken van bewijsmateriaal niet omzetten in toelating. Gewijzigde
input, frontend of export levert via de bestaande fingerprint een nieuwe build.

De browser leest alleen openbare gecontroleerde aggregaten, laadt gekozen landen
op verzoek en hergebruikt geladen payloads. Referentiegemiddelden en punt-rangen
worden deterministisch daarvan afgeleid. CSV behoudt numerieke precisie; JSON en
SVG-metadata bewaren selectie, ouderresultaathashes, bewijsversie en methode.
Geen bronmicrodata, lokale paden of afhankelijkheid van een lopende R-sessie.

Ontbrekende figuren houden alle bediening beschikbaar. Er zijn afzonderlijke
meldingen voor verwerking, bewezen bronafwezigheid, onvolledige vergelijking en
een laadfout. Ontbrekende waarden worden nooit nullen. Onvolledige figuren krijgen
geen gereed-label en geen download met schijnbaar volledige resultaten.

## Huisstijl en technische afronding

De originele Nederlandse/Engelse SVG-woordmerken en het nieuwe pictogram zijn
overgenomen; `assets/brand/BRAND_RELEASE.json` bevat de exacte bronhashes.
Accent #4D52BF, achtergrond #F7F5F0, tekst #17242D en Oswald variant B.
Analytische kleuren blijven apart; SES-lijnkleuren gebruiken de donkere
lijnvarianten uit de nieuwe tokens. Vorm/strepen ondersteunen kleurverschillen.
De al aanwezige gelicentieerde Oswald-webfontimplementatie blijft behouden voor
een werkende lokale preview. Het nieuwe woordmerk bestaat uit vectorpaden.

GitHub Pages bouwt voortaan uitsluitend een benoemde, gecertificeerde kandidaat
met gecontroleerd manifest. De oude workflow combineerde een historisch archief
met nieuwe code en forceerde COMMON42. Dat pad is vervangen. De bestaande online
release verandert pas bij een expliciete deploy van een geverifieerde kandidaat.

## Acceptatie

- Alle 174 actieve figuurcontracten hebben een unieke, bereikbare combinatie
  van onderwerp, uitsplitsing en statistiek. Het brondocument en oude IDs blijven
  intact; 174 figuren betekenen niet 174 nieuwe statistieken.
- Unitchecks: selectie, lege groep, ongeldige landen, ontbrekende jaar/groep,
  gelijke landenweging, rangrichting, gelijke rangen, maximaal twee ranglanden,
  afwezige groeps-CI, echte ontbrekende waarden, URL en exact gekoppelde cel-IDs.
- Browserchecks met bestaande gecontroleerde Nederlandse waarden én een
  afzonderlijke, duidelijk gemarkeerde synthetische fixture voor referentie/rang.
- Nederlandse/Engelse pagina, mobiel, toetsenborddialoog en export worden
  gecontroleerd; bewijs en definitieve testuitkomsten staan in
  `06_pipeline/review_20261013/DASHBOARD_UI_ACCEPTANCE_20261015.json`.

Een afgeronde frontend is geen verklaring dat de internationale analyses of
wetenschappelijke vrijgave klaar zijn. De eerste ontwerpcontrole gebruikte
1.893 bestaande Nederlandse productregels; buitenlandse numerieke figuren en
nog ontbrekende certificaten blijven zichtbaar in afwachting van de R-uitvoer.
