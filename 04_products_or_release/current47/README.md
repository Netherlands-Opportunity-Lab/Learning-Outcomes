# Nederlandse leerprestaties — huidige 47 landen

Deze producten gebruiken de afgehandelde selectie van 47 landen en
onderwijssystemen. De 36 uitgestelde landen worden pas na deze afronding in R
aangevuld. Hun bestaande resultaten en doelen blijven in de volledige
wetenschappelijke administratie bewaard.

- `paper/Leerprestaties_paper_current47.pdf`: Nederlandgerichte paper, inclusief
  steekproefverantwoording, goedgekeurde uitbreidingen, appendix en landenrangen.
- `paper/Leerprestaties_paper_current47.md`: bewerkbare tekst met dezelfde tabellen.
- `deck/final/Leerprestaties_beleid_current47.pptx`: bewerkbare presentatie met
  90 native grafieken. De oorspronkelijke 21 slides leveren 22 slides op doordat
  de lage en hoge peeruitkomst afzonderlijk zijn opgenomen. Hoog vaardigheidsniveau
  naar SES staat in de appendix, zoals goedgekeurd.
- `deck/final/Leerprestaties_beleid_current47.pdf`: vaste weergave van de presentatie.
- `data/`: volledige numerieke productgegevens, exacte oudercellen, referenties,
  steekproefinformatie en figuurbronnen. Afronding gebeurt alleen bij weergave.

De gedeelde dashboardcode staat in `05_publication/preview_overlay`. De website
gebruikt één applicatie voor Nederlands en Engels. De huidige productstatus,
exacte code- en resultaatversies en nog niet uitgevoerde controles staan in
`06_pipeline/START_HIER_ACTUEEL.md` en de bijbehorende acceptatieregistratie.
Aanwezigheid van deze bestanden is geen verklaring dat een volledige nieuwe
leerlingbronreplicatie is uitgevoerd.

## Scripts en verbinding met resultaten

| Script | Invoer | Uitvoer |
|---|---|---|
| `scripts/build_research_data.mjs` | Gecontroleerde dashboardkandidaat; exacte landen-/figuurcontracten | `RESEARCH_PRODUCT_DATA.json`, `PRODUCT_POINT_LINEAGE.json`; 174 figuren, geen leerlingberekening |
| `scripts/prepare_research_tables.py` | Vastgelegde resultaatcommit, Q01/Q02/Q08, kwaliteitsbeperkingen | Nederlandse tabellen, appendix, 12 geregistreerde claims |
| `scripts/plot_paper_figures.R` | Bovenstaande aggregaten en meegeleverde lettertypen | Zes wetenschappelijke figuren in SVG/PNG, puntbestanden en hashmanifest |
| `scripts/build_paper.py` | Tabellen, geverifieerde figuren en oorspronkelijke claims | PDF, bewerkbare tekst en tabel-/claimregister |
| `scripts/reproduce_policy_deck.py` | Meegeleverde bewerkbare PPTX en exact grafiekregister | Opnieuw gevulde native grafieken en ingebedde werkbladen |
| `scripts/render_deck_pdf.py` | 22 gecontroleerde hoge-resolutierenders | PDF en herkomstmanifest |
| `scripts/verify_research_products.py` | Producten en gecertificeerde resultaatadministratie | Controle van 3.554 punten, 112 landenrangen, alle native grafiekcoördinaten en geschreven tabellen |

`scripts/build_policy_deck.mjs` documenteert ook de oorspronkelijke authoring via
de presentatie-runtime. Dat vereist de aangegeven runtime en het aangeleverde
ontwerp van 1 oktober. De openbare reconstructieroute gebruikt de meegeleverde
PPTX als bewerkbare vormgeving en heeft die private authoringomgeving niet nodig.
Zij controleert de huidige release; nieuwe reeksen of een andere verhaallijn
vereisen opnieuw inhoudelijke en visuele beoordeling.

## Reconstructie vanuit aggregaten

Installeer de in `PRODUCT_ENVIRONMENT.json` vastgelegde productbibliotheken.
Dit verandert de wetenschappelijke R-omgeving in `renv.lock` niet.
Voer vanuit de repository uit:

```sh
python 04_products_or_release/current47/REBUILD_PRODUCTS.py --output rebuilt_products
```

Deze route gebruikt geen leerlingbestanden en berekent geen nieuwe statistiek.
De meegeleverde figuurbronnen worden eerst met hun manifest gecontroleerd.
Met `--render-figures` worden ook de zes figuren opnieuw met R gemaakt.
De grafiekwaarden in PowerPoint gebruiken 14 significante cijfers vanwege de
ingebedde Excel-werkbladen; onderzoeksgegevens behouden hun volledige precisie.
De verificatietolerantie is absoluut `1e-9`.

Voor een nieuwe schatting uit officiële leerlingbestanden blijft `START.R` met
`06_pipeline/RUN.R` de enige wetenschappelijke ingang. Gebruik de passende
configuratie voor `nld_only`, `nld_plus_19` of `all_required`. De huidige faseconfiguratie
beperkt `all_required` tot de expliciete 47 landen. `nld_plus_19` is een historische
naam en dwingt geen aantal referentielanden af.

## Interpretatie en gebruik

De drie PISA-trendtoetsen bevatten linking-onzekerheid en Holm-correctie. De
overige geregistreerde veranderingen zijn beschrijvend. De 12 claims zijn
achteraf geregistreerd, voordat de paper is geschreven; dit is geen prospectieve
preregistratie. Er zijn geen nieuwe automatische toetsen toegevoegd.

Volledige vaste referenties gelden per figuur en kunnen tussen figuren verschillen.
Lege referenties en ontbrekende waarnemingen blijven leeg. Landen wegen gelijk;
het hoofdland is uitgesloten van zijn referentie. Een rang gebruikt hoofdland plus
diezelfde groep en krijgt geen groepslijn of betrouwbaarheidsinterval.

Code: MIT, zie de repositorylicentie. Lettertypen: SIL OFL, meegeleverd in `fonts/`.
Bron-, merk- en logovoorwaarden blijven afzonderlijk van toepassing. Leerling- en
schoolbestanden worden niet verspreid. Gebruik de repositorycitatie in `CITATION.cff`.
