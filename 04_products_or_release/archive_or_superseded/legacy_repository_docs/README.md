# Leerprestaties in beeld

Reproduceerbare analyses en een Nederlandstalig en Engelstalig dashboard over
internationale leerprestaties, verschillen naar sociale achtergrond en trends
op ongeveer 10- en 15-jarige leeftijd.

De repository is een private ontwikkelomgeving. GitHub Pages staat bewust nog
niet aan. De huidige webdata zijn synthetische demonstratiegegevens en mogen
niet als onderzoeksresultaten worden geciteerd.

## Inhoudelijke uitgangspunten

- PISA, PIRLS en TIMSS blijven afzonderlijke meetreeksen.
- Levels en verschillen worden samen getoond.
- Trends en rangposities gebruiken een vaste, vergelijkbare landenpopulatie.
- Schattingen gebruiken alle plausible values en de voorgeschreven
  replicate-weightmethode.
- Onzekerheid, linking en relevante designbreuken blijven zichtbaar.
- De taal blijft beschrijvend waar geen causaal effect is geïdentificeerd.
- Land en interfacetaal zijn onafhankelijke dimensies.

## Repositorystructuur

| Pad | Functie |
| --- | --- |
| `R/` en `_targets.R` | Reproduceerbare analyse- en publicatiepijplijn |
| `data-raw/` | Alleen lokale bronbestanden; nooit in Git |
| `data-derived/` | Lokale tussenbestanden; nooit in Git |
| `data-public/` | Alleen gecontroleerde land-jaaraggregaten |
| `src/` | Astro-dashboard, teksten, componenten en voorbeelddata |
| `docs/methods/` | Definities, vergelijkbaarheid en kwaliteitsregister |
| `docs/style/` | Visuele tokens uit de projectstijlgids |
| `tests/` | Tests voor teksten en logica |
| `.github/workflows/` | Controle en build, zonder publicatiestap |

## Dashboard lokaal starten

Vereisten: Node.js 24 of nieuwer en npm.

```bash
npm ci
npm run dev
```

De productiecontrole bestaat uit:

```bash
npm run check
npm test
npm run build
```

De hoofdpagina verwijst naar `/nl/`; de Engelse versie staat onder `/en/`.
Landpagina's gebruiken stabiele ISO3-codes, bijvoorbeeld
`/nl/country/NLD/` en `/en/country/NLD/`.

## Analysepijplijn

De R-structuur is voorbereid, maar bevat nog geen publieke microdata of
definitieve estimates. Zodra de gevalideerde productiescripts worden
ingebracht:

1. registreer bronbestanden en checksums in `sources.yml`;
2. bewaar bronbestanden uitsluitend lokaal in `data-raw/`;
3. laat `_targets.R` alle schattingen en kwaliteitscontroles uitvoeren;
4. publiceer alleen bestanden die aan `data-public/schema.json` voldoen;
5. maak pas daarna een vaste analyserelease.

Een `renv.lock` wordt gemaakt bij de eerste uitvoerbare R-release. Een
schijn-lockfile zonder lokaal geteste pakketversies wordt bewust niet
opgenomen.

## Publicatieblokkades

Publiceer de website en afgeleide datasets pas nadat:

- de definities van SES-groepen en PIRLS-tiehandling zijn vergrendeld;
- de PISA-reeks volledig is gevalideerd;
- schriftelijk is bevestigd welke PIRLS- en TIMSS-aggregaten openbaar mogen
  worden verspreid;
- alle synthetische voorbeelddata zijn vervangen;
- de rechten- en toegankelijkheidscontrole is voltooid.

Zie [DATA_LICENSE.md](DATA_LICENSE.md), [NOTICE.md](NOTICE.md),
[DECISIONS.md](DECISIONS.md) en [CAVEATS.md](CAVEATS.md).

## Licenties

- Code: MIT, zie [LICENSE](LICENSE).
- Eigen teksten en vormgeving: beoogd CC BY 4.0, met de uitzonderingen in
  [DATA_LICENSE.md](DATA_LICENSE.md).
- Data en afgeleide data: bronafhankelijk; er geldt geen overkoepelende open
  datalicentie.
