# Architectuur van analyse en dashboard

## Hoofdprincipe

R berekent. De browser filtert, visualiseert en exporteert. De browser berekent
geen nieuwe survey-estimates, standaardfouten, rangen of SES-indelingen.

## Datastroom

1. Officiële bestanden blijven lokaal in `data-raw/`.
2. `_targets.R` maakt geharmoniseerde tussenbestanden in `data-derived/`.
3. De analyse produceert vooraf alle estimates, standaardfouten,
   betrouwbaarheidsintervallen, rangen, panel-ID's en kwaliteitsvlaggen.
4. Een schema- en disclosurecontrole bepaalt welke regels naar `data-public/`
   mogen.
5. Astro bouwt statische taal- en landpagina's.
6. Observable Plot visualiseert alleen de gecontroleerde openbare laag.

## Taal en land

Taal en land zijn onafhankelijke parameters. Een taalversie geldt voor alle
landen; een landpagina kan in iedere ondersteunde taal worden geopend.

```text
/nl/country/NLD/
/en/country/NLD/
/nl/country/DEU/
/en/country/DEU/
```

ISO3-codes blijven stabiel. Vertaalde landnamen zijn alleen presentatievelden.

## Deelbare views

Iedere actieve keuze staat in het pad of de querystring. Een volledige URL ziet
er bijvoorbeeld zo uit:

```text
/nl/country/NLD/?age=15&comparison=fixed_panel&country=NLD&domain=reading&metric=mean_score&release=2026.1&view=trend
```

De productiespecificatie reserveert daarnaast:

- `background`: bijvoorbeeld `national_quartile` of
  `international_escs_decile`;
- `groups`: bijvoorbeeld `q1,q4`;
- `threshold`: bijvoorbeeld `pisa_level_2` of `pirls_475`;
- `countries`: maximaal vijf expliciet gekozen vergelijkingslanden;
- `panel`: stabiele ID van de fixed balanced landenpopulatie.

Onbekende waarden vallen terug op een veilige standaard. De analyserelease in
de URL voorkomt dat een citeerbare link stilzwijgend andere cijfers gaat tonen.

## Gecontroleerde automatische tekst

Tekst ontstaat uit taalneutrale feiten en gereviewde taalsjablonen. Vrije
generatieve tekst hoort niet in de publieke runtime. Tests bewaken ten minste:

- gelijke sleutelsets in alle talen;
- dezelfde richting, jaren en waarden;
- afwezigheid van ongeoorloofde causale formuleringen;
- correcte locale-notatie van getallen en landen;
- aanwezigheid van kwaliteitswaarschuwingen.
