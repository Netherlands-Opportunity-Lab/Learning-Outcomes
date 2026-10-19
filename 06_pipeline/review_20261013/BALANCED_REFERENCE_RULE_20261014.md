# Definitieve gebruikersregel voor landen en gebalanceerde referenties

Dit register is bijgewerkt na het expliciete antwoord op 19 oktober 2026: **“Ja, voer deze algemene regel in”** op [toelating per afzonderlijke leeftijd-uitkomstcombinatie](BALANCE_USER_DECISION_20261019.json). De vroegere eis dat een land alle zes combinaties moest halen vervalt. De 20 rijke OESO-landen blijven een **kandidatenpool**, geen gegarandeerde groep van 20 toegelaten landen of 19 buitenlandse referenties.

## Drie afzonderlijke selecties

1. **Toegelaten combinatie:** minstens drie onderscheiden, brongecontroleerde en vergelijkbare meetgolven voor dat land, die leeftijd en dat domein. Een land met minstens één toegelaten combinatie kan als hoofdland worden gekozen; andere combinaties blijven expliciet niet beschikbaar. De rijke kandidaten krijgen geen uitzondering.
2. **Standaardreferentie Nederland:** alleen rijke kandidaten met volledige dekking van de Nederlandse jaren van de **gekozen leeftijd-uitkomstcombinatie** uit het leidende 21-slide-deck, plus alle gezamenlijk vergeleken groepen. Nederland telt niet mee. Extra jaren bij een kandidaat zijn toegestaan; ontbrekende vereiste jaren niet.
3. **Referentie bij een ander hoofdland:** dezelfde regel met het volledige overeenkomstige hoofdlandanker. Binnen één figuur zijn landen en groepsdefinities constant. Tussen figuren mogen andere landen geschikt zijn. De gebruiker kan andere geschikte landen aanvinken; de gekozen groep bepaalt ook de rangbasis.

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

Deze catalogus bevat **40 leeftijd-domein-jaarcombinaties**. Voor één figuur geldt het volledige anker van de geselecteerde combinatie, niet de overige vijf. Dit zijn geen 40 onafhankelijk gevalideerde schattingen. Een grafiekjaar bewijst geen bronbeschikbaarheid. Een kwalificatie binnen dezelfde doelpopulatie blijft zichtbaar; een andere regio of een ander nationaal leerjaar wordt niet als ontbrekend jaar van die doelpopulatie voorgesteld. Zulke broncorrecties blijven afzonderlijk gedocumenteerd met behoud van historische doelen en resultaten.

`EXTRACT_POLICY_SUPPORT.py` reconstrueert het anker rechtstreeks uit de gepinde presentatievolgorde en aslabels. Het leest daarnaast alle 48 gekoppelde native grafieken, inclusief de niet-standaard XML-paden en de scattergrafieken, in `NLD_POLICY_CHART_SUPPORT.csv`. De originele presentatie blijft intact.

## Balans voor heterogeniteit en leeromgeving

Dezelfde eis geldt voor geslacht, SES, taal, migratie en klas-/schoolcompositie. Het vereiste support is de **unie van alle reeksen die samen worden vergeleken**, met hun eigen werkelijk bedoelde jaren. Het landpanel is binnen deze vergelijking constant over jaren, groepen, uitkomsten, leeftijden en gebruikte peer-eenheden. Bij een andere analyse wordt de geschiktheid opnieuw getoetst en de wijziging zichtbaar gemaakt.

Voorbeelden:

- Meisjes en jongens samen: een referentieland moet beide groepen voor alle benodigde jaren hebben. Een gat bij jongens sluit het land voor de hele vergelijking uit, ook van de meisjeslijn.
- SES: onderste en bovenste kwart, en eventuele afgeleide kloof, gebruiken hetzelfde panel. Officiële en geharmoniseerde ESCS zijn geen verwisselbare vervangers. PISA-SES begint in het deck in 2015, niet automatisch in 2003.
- Migratie: eerste en tweede generatie worden niet samengevoegd om een ontbrekende categorie te verbergen. De native bronfiguren gebruiken voor PIRLS 2001/2006 en voor TIMSS 2003/2007/2015; hun dekking is dus niet gelijk aan die van totale scores.
- Thuistaal: daadwerkelijke broncategorieën moeten vergelijkbaar zijn. Een frequentieantwoord is niet automatisch taalidentiteit. De TIMSS-taalfiguur betreft vier categorieën in 2023. Voor een nog niet ingevulde Nederlandse taal- of peerreeks wordt geen referentiegeschiktheid verondersteld.
- Compositie: dezelfde doelgroep, peerdoelgroep, vaardigheidsdrempel en eenheid. Een gehele school mag een ontbrekende directe klas-/programmaomgeving niet vervangen.

Domeinonafhankelijke samenstellingsmaten (SES-, taal- en migratiepeers) worden één keer per studie/populatie geproduceerd, zodra die studie voor het land ten minste één toegelaten combinatie heeft. Zij behouden hun volledige eigen figuurjaren, alle groepen en de exacte leeromgeving. Een niet-gebruikte lees- of rekenscore wordt geen aanvullende voorwaarde voor een figuur zonder prestatie-uitkomst. De bronnen PIRLS, TIMSS en PISA blijven gescheiden; dit creëert geen extra maat en vermenigvuldigt geen berekening.

De oude voetnoot op slide 2, waarin per jaar alleen beschikbare landen meetellen, is hiermee inhoudelijk vervallen. Zij moet bij de uiteindelijke deckproductie worden vervangen. Ook oude per-jaar- of per-groepgemiddelden mogen niet als nieuwe gebalanceerde referentie worden hergebruikt.

## Uitwerking in R en dashboard

`LO_BALANCED_MEMBERSHIP.R` bevat geteste functies voor:

- `lo_dashboard_eligibility()`: minimaal drie golven per combinatie op gecertificeerde totale scorecellen, zonder dubbele bronversies of onvergelijkbare populaties samen te tellen;
- `lo_balanced_membership()`: volledige dekking van exact vereiste cellen, met ontbrekende sleutels per kandidaat;
- `lo_balanced_reference_points()`: gelijk gewogen gemiddelden over de complete gekozen groep, zonder het hoofdland en zonder SE/CI voor het samengestelde gemiddelde.
- `lo_dashboard_reference_options()` en `lo_dashboard_reference_points()`: zowel toelating van de gekozen combinatie als volledige gezamenlijke dekking; ontbrekende gegevens voor een andere uitkomst blokkeren de gekozen figuur niet.

Geldige input vereist onafhankelijke wetenschappelijke verificatie, exacte bronrecord-ID's, N en onzekerheid. Vergelijkbaarheids-ID's voor populatie en methode moeten inhoudelijk zijn gecertificeerd; gelijke labels alleen bewijzen dat niet. Vereiste cellen hebben expliciete velden voor survey, leeftijd, domein, jaar, uitkomst, uitsplitsing, subgroep, SES, peergroep/-eenheid, drempel en eenheid. De functies maken geen nieuwe schattingen en autoriseren geen aanvullende analyses.

De dashboardvinkjes worden gebaseerd op deze geschiktheid. Een ongeschikt land kan niet in de gekozen groep komen; de interface toont de ontbrekende dekking als reden. Na wisseling van hoofdland, uitkomst of uitsplitsing wordt een ongeldige bestaande selectie gemarkeerd en geen gemiddelde getoond voordat een geldige selectie is bevestigd. Het hoofdland, de gekozen leden, de periode, definities en releaseversie horen in exports en de deelbare toestand. Een lege geschikte groep levert een duidelijke melding op, geen beperkter stilzwijgend gemiddelde. Het hoofdland wordt nooit ingekort om andere landen passend te maken.

**Bewijs en hergebruik:** de oude `LO_SCOPE_LOCK.R` en `LO_FIXED_COMPARATOR.R` blijven historische fixtures. De huidige keten gebruikt brongecontroleerde combinatiekeuzes, exacte rekentaken en per-figuurreferenties. Het besluit maakt geen afgewezen of uitgestelde A-uitbreiding actief. Bestaande celbewijzen worden hergebruikt; nieuwe bronkandidaten moeten afzonderlijk worden geverifieerd. De actuele uitvoering en acceptatie blijven in de bestaande registers zichtbaar; een geslaagde controle onder de vorige regel is geen bewijs voor de nieuwe selectie.
