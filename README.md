# Learning Outcomes — Kansenlab

**[Open het dashboard](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/nl/)** · **[English](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/en/)** · **[Methode en replicatiepakket](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/info/nl/)**

De tussenstand van 18 oktober 2026 bevat **51.304 gecontroleerde dashboardpunten voor 34 landen**. Kies een hoofdland, leeftijd/domein, statistiek en uitsplitsing. Beschikbare punten worden getoond; ontbrekende jaren en groepen blijven open. Landen zijn selecteerbaar zodra hun bron, methode, volledige periode en alle vergeleken groepen aantoonbaar passen. De landenkeuze vermeldt ontbrekende meetjaren. Rangen gebruiken dezelfde vaste landenbasis.

Het [replicatiepakket](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/replication/learning-outcomes-replication.zip) bevat 173 bestanden en is circa 13,1 MB: actuele analysescripts, omgevingsversies, scope, broncatalogi, dashboardaggregaten en herkomst. De openbare figuren worden met `python reproduce_dashboard.py` opnieuw opgebouwd en byte voor byte gecontroleerd. Volledige replicatie vanaf leerlingbestanden heeft nog de vastgelegde bronbundel nodig en is niet als afgerond gecertificeerd.

- Publicatiekandidaat: `b4b8af52c36aa1bdf238`; volledige bestandsvingerafdrukken staan in de website en kandidaatmap.
- Vastgelegde analyse- en dashboardcode: [6c7f404c99f5](https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes/tree/6c7f404c99f52935b7ee8b213815f7d75f0b15f2). Deze code blijft afzonderlijk ontwikkeld op de bestaande ontwikkelbranch en PR #5.
- [Actuele wetenschappelijke uitvoeringshandleiding](https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes/blob/6c7f404c99f52935b7ee8b213815f7d75f0b15f2/06_pipeline/REPLICATION_CURRENT.md) en [besluitregister](https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes/blob/6c7f404c99f52935b7ee8b213815f7d75f0b15f2/06_pipeline/START_HIER_ACTUEEL.md).
- De figuurdownloads bewaren SE, N, exacte cellen en bron-/code-/resultaathashes en de exacte vergelijkingsbasis. Afronding gebeurt alleen bij weergave.
- [Septemberarchief](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/archive/2026-09-28/) en de historische code blijven behouden.

Deze publicatie verandert de wetenschappelijke productie niet en verleent geen PASS aan open paper-, presentatie- of vergelijkbaarheidscontroles. Leerling-/schoolbestanden en complete afgeleide bulkmasters worden niet publiek gemaakt.

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
