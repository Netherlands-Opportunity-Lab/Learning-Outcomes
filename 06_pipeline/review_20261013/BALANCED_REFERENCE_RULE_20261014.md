# Definitieve gebruikersregel voor landen en gebalanceerde referenties

Dit besluit verwerkt het antwoord van de gebruiker op 14 oktober 2026 en vervangt de open vraag over uitzonderingen voor de vaste 20. De 20 rijke OESO-landen zijn een **kandidatenpool**, geen gegarandeerde groep van 20 toegelaten landen of 19 buitenlandse referenties.

## Drie afzonderlijke selecties

1. **Dashboardland:** minstens drie onderscheiden, brongecontroleerde en vergelijkbare meetgolven in elk van de zes combinaties van leeftijd en domein. Voor de rijke kandidaten gelden geen uitzonderingen op deze 6×3-regel.
2. **Standaardreferentie Nederland:** alleen rijke kandidaten met volledige dekking van de Nederlandse leeftijden, domeinen en jaren uit het leidende 21-slide-deck. Nederland zelf telt niet mee. Extra jaren bij een kandidaat zijn toegestaan; ontbrekende vereiste jaren niet.
3. **Referentie bij een gekozen hoofdland:** alleen dashboardlanden die ten minste alle vereiste cellen van dat hoofdland voor de betreffende vergelijking hebben. Bij de standaardselectie wordt bovendien de rijke kandidatenpool toegepast. De gebruiker kan vervolgens zelf andere geschikte landen aanvinken.

Er wordt geen getal 19, 20, 42 of 50 als selectie-uitkomst afgedwongen. De drie productieopties blijven beschikbaar: Nederland; Nederland plus de rijke kandidaten; deze kandidaten plus de overige toegelaten dashboardlanden. Een productiescope bepaalt welke resultaten worden onderzocht/geproduceerd en garandeert geen toelating tot een referentiegroep.

## Jaaranker uit het leidende deck

De oorspronkelijke presentatie is gepind op SHA256 `cea8dc8a42c3e63e435c16ef13ea6cc1b634f5ca4d95af8c29dafba7397631ac`. Slide 2 bevat de volgende basisperioden:

| Leeftijd | Domein | Vereiste Nederlandse meetgolven in de bronpresentatie |
|---|---|---|
| Rond 10 | Lezen, PIRLS | 2001, 2006, 2011, 2016, 2021 |
| Rond 10 | Rekenen, TIMSS | 2003, 2007, 2011, 2015, 2019, 2023 |
| Rond 10 | Natuurwetenschappen, TIMSS | 2003, 2007, 2011, 2015, 2019, 2023 |
| 15 | Lezen, PISA | 2003, 2006, 2009, 2012, 2015, 2018, 2022, 2025 |
| 15 | Wiskunde, PISA | 2003, 2006, 2009, 2012, 2015, 2018, 2022, 2025 |
| 15 | Natuurwetenschappen, PISA | 2006, 2009, 2012, 2015, 2018, 2022, 2025 |

Dit zijn **40 vereiste leeftijd-domein-jaarcombinaties**, geen 40 onafhankelijk gevalideerde schattingen. De bronpresentatie is het anker voor de gevraagde dekking; beschikbare en geldige cijfers moeten nog uit de wetenschappelijke bronregistratie blijken. Een jaartal of een getekend punt in een PowerPoint bewijst geen bronbeschikbaarheid of vrijgave. Een ongeldige broncel blijft zichtbaar geblokkeerd en wordt niet ongemerkt uit het anker verwijderd om landen te behouden.

`EXTRACT_POLICY_SUPPORT.py` reconstrueert het anker rechtstreeks uit de gepinde presentatievolgorde en aslabels. Het leest daarnaast alle 48 gekoppelde native grafieken, inclusief de niet-standaard XML-paden en de scattergrafieken, in `NLD_POLICY_CHART_SUPPORT.csv`. De originele presentatie blijft intact.

## Balans voor heterogeniteit en leeromgeving

Dezelfde eis geldt voor geslacht, SES, taal, migratie en klas-/schoolcompositie. Het vereiste support is de **unie van alle reeksen die samen worden vergeleken**, met hun eigen werkelijk bedoelde jaren. Het landpanel is binnen deze vergelijking constant over jaren, groepen, uitkomsten, leeftijden en gebruikte peer-eenheden. Bij een andere analyse wordt de geschiktheid opnieuw getoetst en de wijziging zichtbaar gemaakt.

Voorbeelden:

- Meisjes en jongens samen: een referentieland moet beide groepen voor alle benodigde jaren hebben. Een gat bij jongens sluit het land voor de hele vergelijking uit, ook van de meisjeslijn.
- SES: onderste en bovenste kwart, en eventuele afgeleide kloof, gebruiken hetzelfde panel. Officiële en geharmoniseerde ESCS zijn geen verwisselbare vervangers. PISA-SES begint in het deck in 2015, niet automatisch in 2003.
- Migratie: eerste en tweede generatie worden niet samengevoegd om een ontbrekende categorie te verbergen. De native bronfiguren gebruiken voor PIRLS 2001/2006 en voor TIMSS 2003/2007/2015; hun dekking is dus niet gelijk aan die van totale scores.
- Thuistaal: daadwerkelijke broncategorieën moeten vergelijkbaar zijn. Een frequentieantwoord is niet automatisch taalidentiteit. De TIMSS-taalfiguur betreft vier categorieën in 2023. Voor een nog niet ingevulde Nederlandse taal- of peerreeks wordt geen referentiegeschiktheid verondersteld.
- Compositie: dezelfde doelgroep, peerdoelgroep, vaardigheidsdrempel en eenheid. Een gehele school mag een ontbrekende directe klas-/programmaomgeving niet vervangen.

De oude voetnoot op slide 2, waarin per jaar alleen beschikbare landen meetellen, is hiermee inhoudelijk vervallen. Zij moet bij de uiteindelijke deckproductie worden vervangen. Ook oude per-jaar- of per-groepgemiddelden mogen niet als nieuwe gebalanceerde referentie worden hergebruikt.

## Uitwerking in R en dashboard

`LO_BALANCED_MEMBERSHIP.R` bevat geteste functies voor:

- `lo_dashboard_eligibility()`: 6×3 op gecertificeerde totale scorecellen, zonder dubbele bronversies of onvergelijkbare populaties samen te tellen;
- `lo_balanced_membership()`: volledige dekking van exact vereiste cellen, met ontbrekende sleutels per kandidaat;
- `lo_balanced_reference_points()`: gelijk gewogen gemiddelden over de complete gekozen groep, zonder het hoofdland en zonder SE/CI voor het samengestelde gemiddelde.
- `lo_dashboard_reference_options()` en `lo_dashboard_reference_points()`: gecombineerde dashboardtoets, zodat ook een land dat de getoonde groepsfiguur kan vullen wordt geweigerd wanneer het niet aan de algemene 6×3-toelating voldoet.

Geldige input vereist onafhankelijke wetenschappelijke verificatie, exacte bronrecord-ID's, N en onzekerheid. Vergelijkbaarheids-ID's voor populatie en methode moeten inhoudelijk zijn gecertificeerd; gelijke labels alleen bewijzen dat niet. Vereiste cellen hebben expliciete velden voor survey, leeftijd, domein, jaar, uitkomst, uitsplitsing, subgroep, SES, peergroep/-eenheid, drempel en eenheid. De functies maken geen nieuwe schattingen en autoriseren geen aanvullende analyses.

De dashboardvinkjes worden gebaseerd op deze geschiktheid. Een ongeschikt land kan niet in de gekozen groep komen; de interface toont de ontbrekende dekking als reden. Na wisseling van hoofdland, uitkomst of uitsplitsing wordt een ongeldige bestaande selectie gemarkeerd en geen gemiddelde getoond voordat een geldige selectie is bevestigd. Het hoofdland, de gekozen leden, de periode, definities en releaseversie horen in exports en de deelbare toestand. Een lege geschikte groep levert een duidelijke melding op, geen beperkter stilzwijgend gemiddelde. Het hoofdland wordt nooit ingekort om andere landen passend te maken.

**Implementatiegrens:** de nieuwe R-selectiefuncties en tests zijn gereed. De oude `LO_SCOPE_LOCK.R` en `LO_FIXED_COMPARATOR.R` beschrijven nog historische kandidaat-/fixturelogica; zij leveren geen bewijs van deze nieuwe toelating. De koppeling aan gecertificeerde reële broncellen en de dashboardbediening moet nog worden uitgevoerd. Er is nu geen definitieve landenlijst of aantal buitenlandse referentielanden vastgesteld en er is geen nieuwe productie of publicatie gestart. De open goedkeuringspunten A01–A17 blijven afzonderlijk staan.
