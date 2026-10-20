# Learning Outcomes — Kansenlab

**[Dashboard Nederlands](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/nl/)** · **[English](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/en/)** · **[Methode en replicatie](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/info/nl/)**

De gecontroleerde huidige selectie bevat 47 landen en onderwijsstelsels:
90.829 doelen, 82.142 gevalideerde resultaten en 8.687 onderbouwd onbeschikbare
doelen. Het dashboard bevat 63.384 figuurpunten en 174 goedgekeurde figuurcontracten.
De 36 overige landen blijven uitgesteld. Q01–Q08 zijn op deze resultaatbasis
inhoudelijk afgesloten; de volledige nieuwe leerlingbronreplicatie blijft op
uitdrukkelijk verzoek uitgesteld en wordt niet als uitgevoerd voorgesteld.

Toelating geldt per leeftijd/domein met minstens drie vergelijkbare meetgolven.
Binnen iedere figuur zijn de referentielanden vast over alle hoofdlandjaren en
gezamenlijk getoonde groepen. De referentie weegt landen gelijk en sluit het
hoofdland uit. Een lege referentie blijft leeg. Rangen gebruiken dezelfde basis;
er is geen groepsranglijn. NL/EN delen één applicatie, gegevensset en selectielogica.

[Vaste release](https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes/releases/tag/v2026.10.20-current47-dashboard.1) · [Actueel einddossier](06_pipeline/review_20261013/release47_20261020/STEP3_CLOSURE.md).

## Privé en openbaar

Paper, slides, hun bewerkbare inhoud en private reconstructiebundel zijn uitsluitend
voor de eigenaar. Zij horen niet in openbare downloads, repositorybestanden of
CI-artifacts. De publicatiecontrole weigert die bestanden. Onderzoeksmethoden,
gecontroleerde aggregaten, bronregistratie en dashboardcode blijven openbaar.
De terugtrekking van actuele bestanden is afzonderlijk van de nog te beoordelen
toegang via oude Git-commits en caches; zie het actuele afsluitdossier.

## Gebruik en reproduceren

Download het [openbare replicatiepakket](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/replication/learning-outcomes-replication.zip).
Begin met `python REPLICATE.py inspect`. Gebruik vervolgens
`python REPLICATE.py dashboard --output rebuilt_dashboard` om de website uit
aggregaten te reconstrueren. Python 3.12 is getest. De README en drie configuraties
staan in het pakket; `nld_plus_19` is een historische naam, geen vast aantal landen.

De aparte bronroute blijft `START.R` → `06_pipeline/RUN.R`, met audit, uitsluitend
goedgekeurde berekeningen en finalisatie. Officiële bronbestanden worden niet
meegeleverd. De gepinde [publieke wetenschappelijke afhankelijkheden](02_analysis/scientific_dependencies/README.md)
vervangen de oude private ZIP. Gebruik geen onbegrensde `all_required`-run voor de
huidige fase. Bronreplicatie is een andere controle dan aggregaatherbouw.

- [Actuele start en besluiten](06_pipeline/START_HIER_ACTUEEL.md)
- [Acceptaties](06_pipeline/ACCEPTATIE_EN_VOORTGANG.csv)
- [Uitvoeringshandleiding](06_pipeline/REPLICATION_CURRENT.md)
- [Broncatalogus en exacte bronhashes](06_pipeline/review_20261013/international/SOURCE_CATALOG.csv)
- [Gecontroleerde resultaten, datadictionary en producentkoppelingen](04_results/review/all_required/README.md)
- [Resultaatmanifest](04_results/review/all_required/manifest.json)
- [Wetenschappelijk reviewbewijs](06_pipeline/review_20261013/release47_20261020/SCIENTIFIC_REVIEW_COMPLETION.json)
- [Reproductieroutes en instellingen](replication/ROUTES.md)
- [Septemberdashboardarchief](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/archive/2026-09-28/)

De exportcommit is niet de productiecommit. Iedere cel behoudt bron-, methode-,
producent-, resultaat- en certificaathashes, met historische uitvoeringskoppelingen.
Onderzoekswaarden behouden hun precisie. Alleen de presentatie rondt af; ontbrekende
waarden worden niet gevuld. Er worden geen leerling-/schoolmicrodata, credentials
of private configuratie gepubliceerd. Zie `LICENSE`, `DATA_LICENSE.md` en
`CITATION.cff`. De documentatie volgt de AEA-readmeprincipes; dit is geen claim
van AEA-certificering of voltooiing van de uitgestelde volledige bronreplicatie.
