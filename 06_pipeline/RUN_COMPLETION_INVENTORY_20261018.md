# Wat nu uitvoeren — inventaris van 18 oktober 2026

**Latere eindstand en installatieherstel:** de oude run is inmiddels afgesloten:
69.437 geregistreerde resultaten, 7.739 onderbouwd onbeschikbaar en 435 open.
De eerste hervatpoging miste een Git-trackingverwijzing in de single-branch-clone;
de hulp is gericht hersteld en behoudt hetzelfde commando. Zie
[het actuele herstelbewijs](review_20261013/MAINTENANCE_FETCH_REPAIR_20261018.json).
De onderstaande 16:07-inventaris blijft een historische momentopname; haar
uitvoeringsvolgorde en afzonderlijke eindvoorwaarden blijven gelden.

Tijdens de onderstaande momentopname liep de R-productie nog. Laat een actieve run eerst afronden, of stop haar zelf
en wacht tot RStudio weer de `>`-prompt toont. Start daarna één keer de lokaal
voorbereide **`RESUME_WITH_FINAL_CHECKS.R`** met `source(..., encoding = "UTF-8")`.
Deze installatiehulp haalt de geteste reparatie op en roept de bestaande
`RUN_CURRENT_NLD.R` → `START.R`-keten aan. Ondanks de oude naam NLD staat de
huidige runconfiguratie op **`all_required`**. Er is geen tweede rekenprogramma
en geen handmatige start bij Zweden nodig.

Dit document beschrijft de resterende uitvoering, geen volledige wetenschappelijke
vrijgave. De actuele instellingen en de resultaten van een nieuwe run worden
opnieuw vastgelegd; de onderstaande aantallen zijn een gedateerde momentopname.

## Wat daadwerkelijk is gecontroleerd

Om 16:07 Nederlandse tijd (14:07 UTC) is de bestaande alleen-lezen
`LO_COMPLETION_PREFLIGHT.R` uitgevoerd op een stabiele kopie van vier kleine
status-/resultaatbestanden. SHA256 is vóór en na kopiëren vergeleken. Een eerdere
poging op veranderende live bestanden stopte terecht en leverde geen eindstand.
De actieve checkout, bronnen, locks en resultaten zijn niet gewijzigd.

| Status in `all_required` | Cellen |
|---|---:|
| Goedgekeurde doelen in het huidige grid | 77.611 |
| Als wetenschappelijk gevalideerd geregistreerde resultaten | 68.321 |
| Onderbouwd niet berekenbaar voor de exacte gevraagde cel | 7.699 |
| Nog niet afgehandeld | 1.591 |

Dit is 88,0% met een geregistreerde schatting en 97,95% afgehandeld inclusief
bewezen onbeschikbaarheid. **Het is niet 97,95% berekend of wetenschappelijk
vrijgegeven.** De preflight controleert onder meer identiteit, unieke cellen,
eindige waarden/SE/N en checkpointdekking; hij herhaalt geen volledige
onafhankelijke bronreplicatie van iedere schatting. Het volledige eerdere
certificaatonderzoek van 64.362 cellen blijft afzonderlijk bewijs.

Alle 68.321 geregistreerde resultaatversies staan in de geverifieerde private
Drive-index. Het actuele register met afwezigheidsbewijzen staat daar nog niet
in. Juist daarvoor bevat de voorbereide reparatie een checkpointaanpassing.
De lopende run kan na deze momentopname al meer hebben geproduceerd.

De checkout stond op `32c48305e3db57e43fb14da49fae7c0f70de5541`; de nieuwe
installatiereceipt ontbrak. De laatste hervathulp was dus nog niet uitgevoerd.
De echte RStudio-procesnaam is `rsession-utf8`; bovendien bevestigde de
schrijverslock dat productie actief was. Alleen zoeken naar `rsession` of
`Rscript` zou ten onrechte suggereren dat er niets draaide.

Bewijs en alle 166 resterende land/onderzoek/jaar/module-combinaties staan in
[het statusbewijs](review_20261013/RUN_COMPLETION_INVENTORY_20261018.json) en
[de resterende werkvoorraad](review_20261013/REMAINING_BY_CONTEXT_20261018.csv).
Dit zijn geaggregeerde statussen zonder leerlinggegevens of lokale bronpaden.

## Wat nog openstond per land

| Land | Resterende cellen |
|---|---:|
| Verenigde Staten | 1.156 |
| Polen | 149 |
| Marokko | 130 |
| Nieuw-Zeeland | 39 |
| Zweden | 34 |
| Slovenië | 33 |
| Azerbeidzjan | 30 |
| Qatar | 20 |

De Verenigde Staten vormden nog reguliere productiewerkvoorraad. Een open cel
is niet automatisch een bronprobleem. De resterende andere landen overlappen
met de eerder onderzochte probleemblokken; de nieuwe run beoordeelt iedere
exacte cel opnieuw en gebruikt geldige bestaande resultaten.

De grootste open modules waren lage-prestatiepeers (234), migratie (174),
landelijke kernuitkomsten (161), hoge-prestatiepeers (156), peerbaselines (152),
SES × geslacht in de appendix (144) en migratiegeneratie (125). De CSV bevat
ook alle kleinere modules. Een ontbrekende gevraagde groep, nul geldige
waarnemingen of lege PV-/replicatienoemer wordt geen nulresultaat. Een werkelijk
geschatte nul blijft geldig. Ontbrekende jaren blijven in het vereiste anker.

## De enige volgende RStudio-opdracht en haar onderdelen

De lokale wrapper is machinegebonden; gebruik het volledige pad naar
`RESUME_WITH_FINAL_CHECKS.R` dat in deze chat is gegeven. De replicatiecode in
GitHub bevat geen persoonlijke paden. Voer de wrapper pas na de huidige run uit.

| Volgorde | Bestaand script / onderdeel | Functie en controleerbare uitvoer |
|---|---|---|
| 1 | `RESUME_WITH_FINAL_CHECKS.R` + lokale installatiehulp | Controleert checkout- én masterlock; integreert de vastgepinde geteste reparatie op de bestaande ontwikkelbranch; behoudt tussentijdse resultaatcommits; verifieert GitHub-push en schrijft integratiereceipt. Bij onverwachte codewijzigingen stopt hij veilig. |
| 2 | `RUN_CURRENT_NLD.R`, `START.R`, `LO_RUN_CONFIG.R` | Leest `CURRENT_RUN_CONFIG.json`, gebruikt `all_required` en de bestaande goedgekeurde dimensies; legt één codecommit, configuratie, bronmanifest en R/pakketversies vast voor alle fasen. |
| 3 | `RUN.R` → `LO_FIXED_CONTROLLER.R`, fase `fixed-audit` | Bouwt/reconcilieert het exacte goedgekeurde grid; controleert hergebruik, bronidentiteit en afwezigheidsbewijs. Schrijft grid, werkvoorraad, audit- en uitvoeringsreceipts. Geen afgewezen/onbesliste uitbreiding. |
| 4 | `fixed-produce`, `LO_INTERNATIONAL_PRODUCTION.R`, `LO_FIXED_PRODUCERS.R` | Produceert alleen nog ontbrekende toegestane cellen met bestaande gewichten, PVs en surveyvariantie; roept de bestaande onafhankelijke controles aan; certificeert afgesloten blokken en schrijft hun exacte resultaatversies. |
| 5 | `LO_ESTIMATION_AVAILABILITY.R`, `LO_SOURCE_UNAVAILABILITY.R` | Handelt onbeschikbaarheid per exacte cel af, zodat één ontbrekende subgroep niet het hele geldige blok tegenhoudt. Bewaart diagnose-, bron-, taak- en codehashes. |
| 6 | `LO_REMOTE_CHECKPOINT.R`, `LO_ATOMIC_CHECKPOINT.R` | Draagt afgesloten blokken en afwezigheidsbewijzen over naar private Drive; leest ze terug en herstelt/gehasht ieder pakketbestand. Tijdelijke Windows sharing locks worden begrensd opnieuw geprobeerd. Geen nieuwe berekeningen bij onbevestigde overdracht. |
| 7 | `fixed-finalize`, `LO_COMPLETION_PREFLIGHT.R` | Controleert een stabiele eindstand, ontbrekende cellen, dubbele resultaten, eindige waarden en externe checkpointdekking. Schrijft `FINAL_CHECK_PREPARATION`. |
| 8 | `LO_BALANCED_EXPORT.R`, `LO_BALANCED_VIEWS.R`, `LO_BALANCED_MEMBERSHIP.R` | Toetst de volledige hoofdland-/jaar-/groepsdekking aan bestaande bron- en celcontracten; maakt referentie- en rangafleidingen waar bewijs bestaat. Geen geforceerd landenaantal of stilzwijgend korter tijdvak. |
| 9 | `LO_FINAL_GUIDED_EXPORT.R`, `LO_FINAL_GUIDED_DASHBOARD_BUILD.py` | Koppelt uitsluitend goedgekeurde dashboardcellen aan de figuurcontracten; maakt een private websitekandidaat met expliciete gaten en herkomst. Appendixuitkomsten worden niet alsnog dashboardopties. |
| 10 | `LO_PAPER_GATE_EVIDENCE.R` en bestaande final-quality-gate | Toetst Q01–Q08 en product-/methodevoorwaarden aan echte bewijzen onder `PAPER_QA_CURRENT.json`. Schrijft de eindrapportage; een open controle wordt niet automatisch PASS. |
| 11 | `fixed-status`, laatste checkpoint, `LO_GITHUB_RESULTS.R` | Rapporteert de opgeslagen actuele stand; bevestigt de laatste externe overdracht; deponeert toegestane aggregaten, code-/resultaatfingerprints en herkomst op GitHub; synchroniseert private rapporten. |

De volgorde audit → produce → finalize → status is in de bestaande `START.R`
geïmplementeerd en getest. Een uitvoeringsfout stopt afhankelijke vervolgfasen.
Bij een wetenschappelijk aandachtspunt blijft de reden zichtbaar; nul taken
in de rekenwachtrij is geen bewijs dat alle eindvoorwaarden zijn vervuld.

Bij onderbreken hetzelfde commando herhalen. Afgesloten gecertificeerde blokken
blijven behouden en worden niet opnieuw berekend. Het op het onderbreekmoment
nog niet gecommitte blok kan wel opnieuw nodig zijn. Verwijder geen lockbestand,
checkpointindex of mastergrid en start geen tweede schrijver. Schrijf tijdens
de huidige run geen nieuwe code naar haar checkout.

## Welke reparaties al klaarstaan

- 15 probleemblokken: 401 geselecteerde cellen; 304 berekenbaar en 97 met
  aantoonbaar ontbrekende subgroep/noemer. Alle 304 zijn op echte brondata
  onafhankelijk vergeleken; verschillen kleiner dan 1e-9; identieke tweede
  proeven maakten nul nieuwe schattingen. Dit zijn reparatieproeven, nog geen
  toevoeging van die 304 aan het actieve mastergrid.
- Polen/PISA/2009: een afwezige tweede generatie blokkeert geobserveerde
  migratiegroepen niet langer. Lage en hoge peers hanteren dezelfde exacte
  beschikbaarheidsvoorwaarden.
- Windows-bestandsdeling: tijdelijke en blijvende locks op index en
  `.previous` zijn getest; de vorige index blijft behouden bij mislukken.
- Afwezigheidsbewijzen krijgen dezelfde daadwerkelijke externe hersteltest
  als resultaatpakketten. De preflight controleert hun opname.
- De nieuwe gewone `produce-approved`-route voert ook finalize en status uit.

Zie [probleemblokbewijs](review_20261013/PROBLEM_BLOCK_REPAIR_20261018.json) en
[hervat-/lockbewijs](review_20261013/CHECKPOINT_RESUME_20261018.json).

## Wat daarna nodig blijft om het hele project af te maken

1. **Bronnen en landen definitief beoordelen.** Het huidige productiegrid
   betreft de 34 brongetoetste landen. BEL, CHE, GBR, ISL, KOR en LUX hebben in
   het bevroren register nog geen volledige geverifieerde bronkoppeling. Dit
   is geen bewijs dat hun officiële data ontbreken. Hun nationale populaties
   en zes reeksen moeten afzonderlijk worden beoordeeld. Een run over het
   huidige grid kan landen zonder toegelaten taken niet automatisch toevoegen.
2. **Volledige balans en wetenschap afronden.** Het definitieve dashboard
   vereist minimaal drie golven in alle zes leeftijd/domeincombinaties; de
   Nederlandse standaard gebruikt het volledige Nederlandse 21-slide-anker.
   Vergelijkingen van groepen/compositie vereisen gezamenlijke passende dekking.
   Controleer Q01–Q08, bronedities, noodzakelijke paperclaims en onzekerheid.
   De eerdere cijfers 19/20/42/50 zijn geen af te dwingen toegelaten aantallen.
3. **Nieuwe resultaten naar de website brengen.** Na de run: gecontroleerde
   export bevriezen, `LO_DASHBOARD_COMPARABILITY.py` →
   `LO_DASHBOARD_REFERENCE_EXPORT.R` → `LO_DASHBOARD_REFERENCE_VERIFY.py`,
   vervolgens de bestaande dashboardbouwer, `LO_DASHBOARD_PUBLIC_PACKAGE.py`
   en `LO_FINAL_GUIDED_PUBLIC_RELEASE.py`. Voer de Windows/Linux-reconstructie,
   browsercontrole en `pages.yml`-publicatie uit; verifieer de online SHA256s.
   RStudio publiceert niet stilzwijgend de website. De huidige website bevat
   nog de momentopname van 09:59:58 UTC: 51.304 dashboardpunten. Dat zijn
   productpunten, niet hetzelfde telobject als 68.321 gecertificeerde cellen.
4. **Eindproducten en volledige replicatie.** De definitieve 21-slide-presentatie
   en het wetenschappelijke paper staan nog als `NOT_BUILT` geregistreerd.
   Ze worden uit het vrijgegeven grid gemaakt en inhoudelijk/visueel beoordeeld;
   een langer wetenschappelijk deck is optioneel. Schone leerlingbronreplicatie,
   rechten/FAIR-metadata en de duurzame volledige release blijven aparte
   acceptaties. De openbare ZIP reproduceert de dashboardfiguren vanuit
   aggregaten; hij bewijst geen volledige herberekening van leerlingbronnen.

De definitieve **bediening** is nu: uitkomst/leeftijd → uitsplitsing →
**Weergave** → hoofdland, plus internationale vergelijking. Vergelijking en
onzekerheidsmarge staan standaard aan; expliciete gebruikerskeuzes blijven in
de URL. De onzekerheidsknop en voorlopige tekst staan onder de figuur.
De tijdelijke referentielijn verbindt beschikbare opeenvolgende golven en
vermeldt de veranderende samenstelling. Echte ontbrekende golven,
definitiebreuken en wijzigingen van een rangbasis worden niet overbrugd.
Definitieve bediening betekent niet dat voorlopige resultaten definitief zijn.

## Opslag en herleidbaarheid

Gebruik de huidige configuratie en dezelfde scripts. Verwijder geen geldige
resultaten om de nieuwe code te kunnen gebruiken. Schattingen/SEs blijven op
volledige rekenprecisie; de website rondt alleen de presentatie af. Een
resultaatversie is gekoppeld aan celcontract, bron-/inputhash, code, configuratie,
methode en certificaat. Bronbestanden mogen lokaal blijven; noodzakelijke
hervatstaat blijft tijdens productie lokaal, private tussenresultaten op Drive
en vrijgegeven code/aggregaten op GitHub. Er was bij deze controle circa
16,5 GB vrij op C:. Eventuele verdere opruiming volgt de bestaande concrete
selectieregels en wacht tot de schrijver vrij is en herstel is bevestigd.
