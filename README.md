# Learning Outcomes — Kansenlab

**[Open het dashboard](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/nl/)** · **[English](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/en/)** · **[Methode en replicatiepakket](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/info/nl/)**

De gecontroleerde versie van 20 oktober 2026 bevat **63.384 dashboardpunten voor 47 landen en onderwijsstelsels**. De overige 36 landen zijn uitgesteld. Alle 90.829 gekozen doelen zijn verantwoord: 82.142 gevalideerde resultaten en 8.687 onderbouwd onbeschikbare doelen. Q01–Q08 zijn voor deze selectie afgesloten. Kies achtereenvolgens leeftijd/domein, uitsplitsing, Weergave en hoofdland.

De internationale vergelijking gebruikt nu de volledig gecontroleerde referentiegroep per figuur: dezelfde landen over alle hoofdlandjaren en gezamenlijk getoonde groepen. Tussen figuren mogen de groepen verschillen. De 8.178 land-figuurcontracten zijn onafhankelijk gecontroleerd. Ontbrekende punten behouden hun exacte reden; een lege vergelijkingsgroep blijft leeg.

De schakelaar **Onzekerheidsmarge / Uncertainty range** toont optioneel 95%-betrouwbaarheidsintervallen voor het hoofdland. Hij staat standaard aan en geldt niet voor rangen of de vergelijkingsgroep. Nederlands en Engels delen één applicatie en dezelfde gegevens; de taalwissel bewaart alle keuzes. Procentreeksen worden op de juiste schaal getoond en downloads bewaren de oorspronkelijke waarden en afleiding.

Het [replicatiepakket](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/replication/learning-outcomes-replication.zip) bevat 458 bestanden plus het pakketmanifest en is circa 98 MB. Het dashboard is vanuit dit pakket byte voor byte herbouwd; de onderzoekstabellen komen exact overeen. De paper telt 29 pagina's en de bewerkbare presentatie 22 slides met 90 native grafieken. Hun herbouw en numerieke aansluiting zijn op Windows en Linux geslaagd.

- Publicatiekandidaat: `ce55760e9df4f4b4428e`; zie [de exacte afleverstatus](06_pipeline/review_20261013/release47_20261020/CURRENT47_DELIVERY.json).
- Gepinde pakketcode: [92d5e38016cd](https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes/tree/92d5e38016cde66923c02d59c4e6b9730dd546a3). Historische producentcommits blijven per resultaat bewaard; de exportcommit is geen nieuwe producent.
- [Paper, presentatie, figuurbronnen en productherbouw](04_products_or_release/current47/README.md).
- [Actuele uitvoeringshandleiding](06_pipeline/REPLICATION_CURRENT.md), [besluitregister](06_pipeline/START_HIER_ACTUEEL.md) en [afrondingsbewijs voor de huidige 47](06_pipeline/review_20261013/release47_20261020/SCIENTIFIC_REVIEW_COMPLETION.json).
- De figuurdownloads bewaren SE, N, exacte cellen en bron-/code-/resultaathashes en de exacte vergelijkingsbasis. Afronding gebeurt alleen bij weergave.
- [Septemberarchief](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/archive/2026-09-28/) en de historische code blijven behouden.

De volledige nieuwe bronreplicatie van alle gekozen 47-landenresultaten, zonder oude resultaatcaches, is nog niet uitgevoerd. De 58 echte bronproeven en geslaagde aggregaatherbouw vervangen die eindcontrole niet. De openbare bronroute heeft de benodigde historische engine en gepinde auteurscode; de oorspronkelijke private ZIP is niet meer vereist. Leerling-/schoolmicrodata worden niet gepubliceerd. De gebruiker heeft zowel deze volledige bronreplicatie als de 36 resterende landen uitgesteld. De huidige controle van de drie stappen gebruikt het al afgeronde bewijs; geen van beide runs wordt nu gestart. Zie [de inhoudelijke hercontrole van stap 1](06_pipeline/review_20261013/release47_20261020/STEP1_REVIEW_20261020.md).

---

## Historische septemberdocumentatie

De onderstaande aantallen en bronversies beschrijven uitsluitend de bewaarde release van september.

# Learning Outcomes — PISA / PIRLS / TIMSS

Reproducible analyses and a public research dashboard on international learning outcomes at approximately age 10 and age 15.

## Scientific source lock

The scientific/product source of truth is commit `749a0de8e6ab707f4ecd887247ea8fde82f55656` (28 September 2026). Publication-only commits after that lock may add hosting, rights documentation, a public-safe data subset and build/QA automation, but do not alter the scientific analysis or the canonical dashboard implementation in `03_dashboard/`.

The final analysis basis contains 283,284 estimate rows. PISA, PIRLS and TIMSS remain separate measurement systems; raw score points are never subtracted across surveys.

## Repository structure

| Directory | Purpose |
|---|---|
| [`01_data_download_preprocessing/`](01_data_download_preprocessing/README.md) | Source acquisition, provenance, dictionaries, harmonisation history and source-side preprocessing |
| [`02_analysis/`](02_analysis/README.md) | Canonical production analysis and archived/superseded scripts |
| [`03_dashboard/`](03_dashboard/README.md) | Frozen tested dashboard source and complete production-data manifest |
| [`04_products_or_release/`](04_products_or_release/README.md) | Release manifests, product matrix, validation and change/loss records |
| [`05_publication/`](05_publication/README.md) | Public-site boundary, rights review, replication guide and GitHub Pages build/QA |

Start with [REPRODUCIBILITY.md](REPRODUCIBILITY.md), [DATA_SOURCES.md](DATA_SOURCES.md), [METHODS.md](METHODS.md), [KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md), and [05_publication/PUBLICATION_RIGHTS_REVIEW.md](05_publication/PUBLICATION_RIGHTS_REVIEW.md).

## Public dashboard boundary

The public site is a research/policy publication, not a mirror of OECD/IEA source databases.

Published:
- project-authored interactive analyses and figures;
- aggregate country/system estimates needed to render those analyses;
- figure-level CSV exports, methods, sources, status and caveat information;
- all project analysis/dashboard/publication code.

Not published:
- pupil- or school-level source data;
- OECD/IEA source files;
- assessment items, reading passages, questionnaire content, photographs or other third-party copyrighted assessment material;
- the complete bulk tables `FINAL_PRODUCT_BASIS.csv.gz` and `RESULTATEN_MASTER.csv.gz`;
- local caches, credentials, private file inventories and user-specific paths.

See [DATA_LICENSE.md](DATA_LICENSE.md) and [05_publication/RIGHTS_MATRIX.csv](05_publication/RIGHTS_MATRIX.csv).

## Final public dashboard integration

The definitive public publication layer is maintained under [`05_publication/`](05_publication/README.md) and is built directly from the frozen renderer in `03_dashboard/app/`; it is not a second scientific implementation.

Release anchors:
- scientific/product lock: `749a0de8e6ab707f4ecd887247ea8fde82f55656`;
- analysis release: `FINAL_ANALYSIS_FREEZE_20260928`;
- integration base SHA: `db8b7d7ddc22c6d96191148ffac9c2953dc00900`;
- public-data inventory and hashes: [`05_publication/PUBLIC_DASHBOARD_MANIFEST.json`](05_publication/PUBLIC_DASHBOARD_MANIFEST.json);
- file-by-file publication gate: [`05_publication/PUBLIC_DATA_GATE.csv`](05_publication/PUBLIC_DATA_GATE.csv);
- public-to-freeze fidelity evidence: [`05_publication/PUBLIC_RESULT_FIDELITY.json`](05_publication/PUBLIC_RESULT_FIDELITY.json).

The minimal public runtime contains 253 frozen aggregate/figure files actually required by the site. Four safe project control tables remain in the repository but are not shipped in the site runtime. The two complete derived masters remain documented by size and SHA-256 but are not served or linked as public downloads. Merge and deployment are deliberately separated: the GitHub Pages deployment workflow is manual-only, so merging a scientific/publication PR does not itself publish a new site build.

## Reproduce the results

1. Obtain the official OECD/IEA source files yourself under the source providers' current terms.
2. Keep pupil-level files outside Git.
3. Follow [05_publication/REPLICATION_GUIDE.md](05_publication/REPLICATION_GUIDE.md).
4. Run the canonical production code in `02_analysis/current/`.
5. Compare the resulting validation/status files with `02_analysis/release_registers/`.
6. Build the dashboard from the frozen aggregates. The browser renders precomputed values; it does not estimate scientific quantities or recompute ranks.

## Licences

Project code is MIT unless a file states otherwise. No repository-level open-data licence is asserted for OECD/IEA source data or derived aggregates. Source-provider terms remain applicable; see [DATA_LICENSE.md](DATA_LICENSE.md).
