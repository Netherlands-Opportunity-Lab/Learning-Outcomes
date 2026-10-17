# Gebruikerskeuzes, landenregel en afzonderlijke goedkeuring — 14 oktober 2026

Actuele status van de afzonderlijke A-besluiten: [SCOPE_APPROVALS.csv](../SCOPE_APPROVALS.csv). Dit document bewaart de toelichting en beslisstand van 14 oktober; nieuwe expliciete antwoorden worden met datum en gebruikersbewijs in dat register verwerkt, samen met de getroffen code en productvereisten. Overkoepelend ingangspunt: [START_HIER_ACTUEEL.md](../START_HIER_ACTUEEL.md).

**Nader gebruikersbesluit:** [de definitieve balansregel](BALANCED_REFERENCE_RULE_20261014.md) vervangt de open vraag over de 20 kandidaten en specificeert balans voor alle groeps- en compositiereeksen.

Deze aanvulling corrigeert de scope-uitleg van de audit van 13 oktober. Rechtstreekse gebruikerskeuzes gaan vóór bronpresentaties, historische registers en voorstellen van de assistent. De 247 gekoppelde regels zijn een **inventarisatie van broninhoud en afhankelijkheden**, geen 247 goedgekeurde statistieken. Ook het produceren van een langer wetenschappelijk deck is geen toestemming om alle analyses uit een ouder deck opnieuw uit te voeren.

## Teruggevonden handmatige keuzes

In de meegeleverde chattekst met het antwoordkopje `20261012 09` staat het oorspronkelijke gebruikersbericht, regels 948–958. Het zegt letterlijk: **“schrap 3 en vervang 12 en 13 door ‘onder basisniveau’”**. De gebruiker vraagt daarnaast of figuur 11 uit 10, en 15 uit 14 kan worden afgeleid. Dat zijn SES- en genderkloven uit groepsniveaus; een betrouwbaar interval vereist gezamenlijke replicaties of covariantie.

Dezelfde gebruiker schrijft **“Zullen we voor 23 dan ook het basisniveau nemen? Of ook nog hoog niveau?”** en vraagt wat trendverschillen toevoegen. Dit zijn vragen, geen definitieve goedkeuring van beide peer-varianten of van een hele nieuwe familie trendtoetsen. De daaropvolgende voorstellen van de assistent waren te stellig tot productiebesluit verheven. Lage-prestatiepeers staan daarom nu als voorstel A01; het apart behouden van hoge-prestatiepeers als A03. De al gemaakte celdefinities blijven traceerbaar, maar zijn niet geautoriseerd voor productie.

De expliciete oorspronkelijke keuzes zijn:

- Figuurtype 3: geen afzonderlijke grafiek op/boven basisniveau.
- Typen 12 en 13: één familie onder basisniveau naar SES; hoog niveau naar SES niet standaard toevoegen.
- Typen 11 en 15: behouden verschillen uit de groepsniveaus, met correcte onzekerheid.
- De 21-slideversie met `20261001` blijft de productbasis, gelezen samen met latere menselijke wijzigingen.
- Aanvullende heterogeniteit uit de 50 wetenschappelijke slides vereist afzonderlijke menselijke goedkeuring.

De teruggevonden bron is de door de gebruiker meegeleverde volledige geplakte chattekst. De actuele chatzoekfunctie leverde dit precieze oudere bericht niet onder een verifieerbare chattitel op; daarom wordt hier geen titel verzonnen. Wel is in `20261007 Verder met productievalidatie` het oorspronkelijke gebruikersbericht over de mastermap en de leidende 21 slides teruggevonden.

## Landeninclusie: gewenste regel versus oude code

De oude code controleert alleen exact lidmaatschap van COMMON42 en de vaste PPP20: 1/20/50 landen voor de drie productiescopes. Zij controleert **niet** minimaal drie meetgolven in elk van zes combinaties. De oudere presentatie noemt COMMON42 als de gemeenschappelijke groep “in alle drie”; het register bevat geen bewijs van een 6×3-regel.

De nieuwe inhoudelijke regel is minimaal drie **onderscheiden meetgolven per combinatie**:

| Leeftijd/populatie | Lezen | Rekenen/wiskunde | Natuurwetenschappen |
|---|---|---|---|
| Ongeveer 10 jaar, beoogde basisschoolpopulatie | PIRLS | TIMSS | TIMSS |
| Ongeveer 15 jaar | PISA | PISA | PISA |

Dit betekent zes keer ten minste drie; niet drie golven in totaal en niet noodzakelijk ieder kalenderjaar. De golven hoeven niet in hetzelfde kalenderjaar te vallen. Alleen werkelijk beschikbare, vrijgegeven en voor de beoogde populatie vergelijkbare meetgolven tellen. Taakregels, placeholders, dubbele bronversies, ongepubliceerde golven en anders afgebakende populaties tellen niet. Steekproefkwaliteit, toetsmodus, broneditie en afnameleeftijd blijven afzonderlijk zichtbaar. Landnamen mogen regionale steekproeven niet ongemerkt samenvoegen (bijvoorbeeld Engeland versus het Verenigd Koninkrijk).

De hercontrole van de oude `AVAILABILITY_MATRIX.csv` geeft 31 van de 42 met minstens drie als AVAILABLE/VALIDATED **gelabelde** golven per combinatie. Elf halen dat niet in dit register: ALB, BRA, CYP, JOR, KAZ, MAC, MKD, MNE, SRB, TUR, XKX. Dit is historische labeldekking, geen nieuwe wetenschappelijke validatie of definitieve uitsluitingslijst. Acht van de vaste PPP20 staan helemaal niet in die matrix. Alle kandidaatlanden moeten uit bron-/deelnamebewijs worden beoordeeld; alleen de oude 42 filteren zou opnieuw een scopefout zijn.

Besloten op 14 oktober: ook de rijke kandidaten moeten voor dashboardtoelating aan 6×3 voldoen. Referentietoelating vereist daarnaast volledige dekking van het hoofdland; voor de Nederlandse standaard zijn de 21 slides het jaaranker. Onvolledige kandidaten vallen uit de referentie. De 20 is een kandidatenpool; 19/20/42/50 zijn geen af te dwingen uitkomsten.

## Drie productiekeuzes en dashboardreferentie

| Instelling | Betekenis |
|---|---|
| `nld_only` | Alleen Nederlandse primaire resultaten produceren. Voor een buitenlandse referentielijn zijn daarnaast reeds gevalideerde buitenlandse aggregaten nodig; anders toont de publicatie die lijn niet. |
| `nld_plus_19` | Nederland plus de 19 buitenlandse rijke kandidaten; daadwerkelijke referentietoelating wordt afzonderlijk op balans getoetst. |
| `all_required` | Unie van de vaste 20 en de overige landen die de brononderbouwde inclusieregel halen. Geen dubbele landen, geen stilzwijgende uitbreiding naar alle 91 historische stelsels. |

De vaste groep is de eerder vastgelegde OESO-PPP2024-groep: bbp per inwoner in koopkrachtpariteit strikt boven Tsjechië, volgens het gepinde bronbestand. Dit is niet automatisch de Wereldbankcategorie “high income”. De 20 codes zijn NLD AUS AUT BEL CAN CHE DEU DNK ESP FIN FRA GBR IRL ISL ITA KOR LUX NOR SWE USA.

Voor een toegelaten focusland uit deze kandidaten is de standaardselectie het volledig passende deel van de overige rijke kandidaten; dit kan minder dan 19 zijn. Het dashboard moet een toegankelijk vak **Referentiegroep samenstellen** krijgen met landvinkjes en **Herstel standaardgroep**. Een eigen selectie bepaalt daadwerkelijk het groepsgemiddelde; zij mag niet alleen losse landenlijnen toevoegen. Het focusland wordt altijd uitgesloten. Landen tellen gelijk mee. Geen SE/CI rond het samengestelde referentiegemiddelde; individuele landschattingen behouden hun geldige onzekerheid.

De gekozen groep en feitelijke datadekking zijn afzonderlijke gegevens. Ontbrekende landen worden niet stilzwijgend vervangen of per meetgolf weggelaten. Een vaste volledige referentielijn wordt alleen getoond waar het volledige panel wordt gedragen. De gebruiker kan een kleiner constant panel kiezen uit volledig geschikte landen; een zoom of periodefilter maakt een ongeschikt land niet alsnog geschikt. Het volledige hoofdlandanker blijft leidend. Een inhoudelijke wijziging daarvan vereist een nieuw expliciet besluit, geen automatische verkorting. Export en deelbare URL bewaren selectie, focusland, periode, definities en resultaatversie. Alleen gevalideerde landelijke aggregaten worden gecombineerd; er worden geen leerlinggegevens in de browser berekend.

De geïnspecteerde actieve frontend (`05_publication/preview_overlay/assets/app-shell.js`, commit 9349236) heeft een focuslandselector en vooraf berekende referentiereeksen. De gevraagde vrije groepssamenstelling is daar **nog niet geïmplementeerd**. Dit is een concrete wijziging voor de dashboardbouw. Een eerdere beperking tot 42 focuslanden mag daarbij de nieuwe inclusieregel of de vereiste toegang tot de 20 niet automatisch overrulen.

## Beslisblad: elk inhoudelijk extra onderdeel afzonderlijk

De onderstaande tabel bewaart het historische beslisblad van vóór de antwoorden. De actuele afzonderlijke besluiten staan in `SCOPE_APPROVALS.csv`. Een aanbeveling is geen akkoord. Besluiten kunnen worden gegeven als `A01 ja, A02 nee, ...`; een overgeslagen regel blijft uit nieuwe productie. Een ja op inhoudelijke scope is nog geen wetenschappelijke vrijgave.

| ID | Onderdeel en herkomst | Verschil met de gekozen basis / mijn advies |
|---|---|---|
| A01 | Aandeel peers onder basisniveau, naar eigen vaardigheid; gebruikersvraag 12 oktober | Nieuwe primaire peermaat naast/vervangend voor slide 20. Advies: opnemen als hoofdmaat; directe leeromgeving en hele school apart. |
| A02 | Hoog vaardigheidsniveau naar SES; beleidslide 10, wetenschap 16 | Door de gebruiker uit de standaard verwijderd. Advies: weglaten; alleen na apart akkoord als appendix terugzetten. |
| A03 | Hoogpresterende peers als aanvullende variant | Oud beleidsslide 20; behoud naast A01 is een aparte keuze. Advies: voorlopig weglaten om de productie te begrenzen. |
| A04 | Officiële IEA Home-SES-groepen en prestaties; wetenschap 17 | Extra SES-maat bovenop boekenkwartielen. Advies: alleen appendix; respons/coveragecontrole blijft sowieso nodig. |
| A05 | Internationale absolute SES-grenzen; wetenschap 19–21 | Andere populatie-indeling dan nationale kwartielen, met oud buitenlands panel. Advies: voorlopig uitstellen. |
| A06 | SES × geslacht; wetenschap 24 | Vier gezamenlijke groepen in plaats van twee afzonderlijke uitsplitsingen. Advies: nuttige optionele verdieping, pas na akkoord. |
| A07 | Thuistaal × migratiegeneratie; wetenschap 28 | Nieuwe gezamenlijke verdeling; niet dezelfde figuur als losse taal- of migratiegroepen. Advies: optionele appendix. |
| A08 | Historische leesrangen in vaste 13/32-panels; wetenschap 31–32 | Extra paneldefinities naast de nieuwe vaste referentie. Advies: uit de nieuwe hoofdproducten laten. |
| A09 | Rang van de SES-kloof in oud 45-panel; wetenschap 33 | Extra rangstatistiek en rangonzekerheid. Advies: voorlopig weglaten. |
| A10 | Kwantitatieve vergelijking tussen leeftijden, brede/kwaliteitspanels en cohortvarianten; wetenschap 34–38 | Extra afbakening en afgeleide vergelijkingen. Advies: alleen beschrijvende context nu; nieuwe schattingen na akkoord. |
| A11 | Aandeel prestatievariantie tussen scholen; wetenschap 39–43 | Nieuwe maat voor schoolsortering, anders dan peerblootstelling. Advies: inhoudelijk waardevol als wetenschappelijke uitbreiding. |
| A12 | Aandeel prestatievariantie tussen klassen; wetenschap 45 | Apart hiërarchisch niveau en aparte variantiedefinitie. Advies: alleen samen met expliciete afbakening van A11. |
| A13 | Aandeel SES-variantie tussen scholen; wetenschap 44 | Sociale sortering, niet de Q1/Q4-peermaat. Advies: inhoudelijk waardevol als wetenschappelijke uitbreiding. |
| A14 | Aandeel SES-variantie tussen klassen; wetenschap 45 | Apart niveau naast A13. Advies: optionele uitbreiding. |
| A15 | Theil-H-segregatie naar taal; wetenschap 46–47 | Nieuwe segregatie-index en categorievereisten. Advies: voorlopig uitstellen. |
| A16 | Theil-H-segregatie naar migratie; wetenschap 46–47 | Zelfstandige uitkomst naast A15. Advies: voorlopig uitstellen. |
| A17 | Systematische trendcontrasten en verschillen in veranderingen; gebruikersvraag en wetenschap 5/14/23/26 | Nieuwe reeks toetsen bovenop trendfiguren. Advies: beperk tot concrete paperclaims; geen uitputtende standaardproductie. |

Broncontrole, N, steekproefkwaliteit, SES-dekking, correcte gewichten/PVs/replicaties, covariantie, noodzakelijke linking-onzekerheid, versiecontrole en reproduceerbaarheid zijn kwaliteitsvoorwaarden voor de behouden analyses. Ze voegen op zichzelf geen nieuw inhoudelijk onderzoeksdoel toe en blijven nodig. Nieuwe claims over cohortontwikkeling of causaliteit volgen niet uit vergelijking van twee leeftijdsgroepen.

## Historische technische stand direct na de scopecorrectie

Deze alinea beschrijft het eerdere moment. De latere implementatie en echte uitvoeringsbewijzen staan in START_HIER_ACTUEEL.md en STEP1_EXECUTION_EVIDENCE_20261014.json.

`PRODUCT_SCOPE_APPROVAL.py` maakt het onderscheid bij elke hergeneratie expliciet. De 247 bronkoppelingen blijven controleerbaar; hangende aanvullingen krijgen beslis-ID's en worden niet meer als verplichte nieuwe productie gelabeld. De bestaande numerieke bewijscontroles en hun uitslagen zijn niet opnieuw geïnterpreteerd als wetenschappelijke goedkeuring. De productie blijft bovendien geblokkeerd zolang exacte gecertificeerde celsturing ontbreekt. Er is geen nieuwe analyse uitgevoerd, geen site gepubliceerd en niets van C: verwijderd.

## Definitief productbesluit A09 — 14 oktober 2026

De gebruiker kiest rangontwikkeling van het hoofdland en eventueel één ander land als tijdreeks in het dashboard. De gekozen internationale vergelijkingsgroep bepaalt de rang van Nederland (of het gekozen hoofdland), maar wordt zelf niet geplot. Dit is dezelfde referentiegroep als bij de gekozen vergelijking, geen afzonderlijk te kiezen rangpanel. Het hoofdland hoeft niet aan zijn eigen referentiegroep te worden toegevoegd. De dashboardbouwer draait steeds om één figuur met jaren op de x-as, voor de gekozen uitkomst, leeftijd/doelpopulatie, uitsplitsing en vergelijking. Een ranglijst van landen komt uitsluitend in de wetenschappelijke paper. De vormgeving uit het archief van 1 oktober blijft leidend. De vier vraagkaarten zijn ingangen naar die ene figuur, geen opdracht voor vier gelijktijdige grafieken.

A09 is hiermee inhoudelijk goedgekeurd; de oude vaste 13-/32-/45-landenpanels zijn niet opnieuw gekozen. Rangen zijn afleidingen van exact gecertificeerde uitkomsten (waaronder SES-kloven), met expliciete constante landenbasis en herleidbare oudercellen. De trace registreert kandidaat-oudercellen; de uiteindelijke selectie volgt de gekozen uitkomst en vergelijking. Dit voegt geen aparte leerlingberekeningen toe en geeft geen gegevens vrij. Een rangnummer is niet automatisch een statistisch significant verschil; score-SE's worden geen rang-SE's.

Nadere gebruikersbesluiten: geen groepsrang; wel eventueel één ander land naast het hoofdland, met rangen relatief tot dezelfde gekozen internationale vergelijkingsgroep; die groep krijgt geen lijn. ‘Groep 4’ is bevestigd als internationaal vierde leerjaar, dus Nederlandse groep 6 (rond tien jaar). Alle A-besluiten zijn hiermee beantwoord. De numerieke rangafleiding en dashboardbediening zijn nog niet gebouwd. Zie `RANK_PRODUCT_CONTRACT.json`.
