# Kernbegrippen en definities

## Instrument en leeftijd

- PIRLS: lezen rond 10 jaar.
- TIMSS Grade 4: wiskunde en science rond 10 jaar, later toe te voegen.
- PISA: lezen, wiskunde en science bij 15-jarigen.

PISA, PIRLS en TIMSS vormen geen gezamenlijke scorelijn. De website kan de
leeftijden naast elkaar presenteren, maar verbindt de toetsschalen niet.

## Trends en landenpopulatie

Een hoofdtrend gebruikt de grootste verdedigbare fixed balanced landenset die
in alle getoonde waves met vergelijkbare data aanwezig is. De rang van een land
wordt per wave binnen exact dat panel bepaald en altijd als `rang/N` getoond.

Benchmarktercielen worden per wave opnieuw binnen het vaste panel bepaald. De
onderliggende landenpopulatie blijft dus gelijk, terwijl de samenstelling van
onderste, middelste en bovenste derde kan veranderen.

## Sociale achtergrond

PISA en PIRLS gebruiken niet automatisch dezelfde achtergrondmaat.

- PISA: ESCS en vooraf vastgelegde nationale of internationale groepen.
- PIRLS-hoofdreeks 2001–2021: student-gerapporteerd aantal boeken thuis in vijf
  stabiele categorieën; ouder-SES is een robustnessanalyse.
- TIMSS: alleen officiële vergelijkbare maat in de hoofdreeks; een
  leerlingproxy wordt afzonderlijk als gevoeligheidsanalyse aangeduid.

De dashboarddata benoemen altijd maat, indelingsschema en groep. Een knop die
kwartielen en quintielen ongemerkt verwisselt is niet toegestaan.

## Onzekerheid

Schattingen gebruiken alle plausible values, het officiële hoofdgewicht en de
voorgeschreven replicate-variantieprocedure. Steekproefonzekerheid en linking
uncertainty worden afzonderlijk bewaard of hun combinatie wordt gemotiveerd.

## Rangrichting

- Prestatieniveau en aandeel boven basisniveau: rang 1 is het hoogste niveau.
- Ongelijkheidskloof: rang 1 is de kleinste kloof, wanneer de rang als
  gelijkheidsrang wordt gepresenteerd.

Iedere uitvoer bevat daarom expliciet `rank_direction`.
