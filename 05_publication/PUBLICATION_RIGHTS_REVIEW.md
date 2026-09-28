# Publication-rights review — PISA / PIRLS / TIMSS dashboard

Review date: 28 September 2026

Purpose: define a conservative operational boundary for a public research/policy dashboard while keeping all project code and replication instructions public.

This is a source-terms review, not legal advice.

## 1. OECD PISA

The current PISA Public Use File terms state two relevant rules together:

1. the PISA Dataset/PUF itself must not be distributed, disclosed or made available to third parties;
2. aggregated data may be included in reporting provided individual participants or schools cannot be identified.

The terms also require OECD/PISA source acknowledgement.

Source:
https://survey.oecd.org/index.php?r=survey%2Findex&sid=197663

### Decision

PUBLIC:
- project-computed country/system aggregates;
- project-authored tables, charts and interactive views based on those aggregates;
- uncertainty/status/caveat information at aggregate level;
- code that reproduces the calculations.

HOLD:
- PISA PUF/source files;
- student/school records or outputs that could identify participants/schools;
- any source content whose redistribution is separately restricted.

Required attribution in relevant documentation:
“Programme for International Student Assessment (PISA), Organisation for Economic Co-operation and Development (OECD), Paris.”

## 2. IEA PIRLS and TIMSS

IEA provides public-use PIRLS/TIMSS datasets through its Data Repository, but access is subject to the IEA Disclaimer and License Agreement.

The agreement says, among other things:
- IEA publications and restricted-use items are for non-commercial educational/research purposes;
- distribution/redistribution/reproduction of those publications/restricted-use items, or parts of them, requires written permission;
- source/year/title must be acknowledged when quoting/citing;
- IEA cannot authorize third-party copyrighted assessment material such as reading passages, photographs or images; permission must come from the relevant rights holder.

Source:
https://www.iea.nl/sites/default/files/data-repository/Disclaimer_and_License_Agreement.pdf

The text does not state as explicitly as the PISA terms whether a large independently computed derived aggregate database may be redistributed. We therefore do not treat silence from IEA as permission for a full bulk mirror.

### Decision

PUBLIC:
- project-authored reporting of aggregate PIRLS/TIMSS statistics;
- aggregate values strictly needed to render the project's interactive analyses;
- project-authored charts and small figure-level CSVs;
- code, methods, source references, DOI references and reproducibility documentation.

HOLD pending explicit clarification:
- IEA source data files;
- restricted-use items;
- assessment questions/items, reading passages, questionnaire reproductions, photographs or copied IEA publication graphics;
- the complete project bulk aggregate masters.

## 3. Why the two full masters are withheld

The internal final dashboard package contains:
- `FINAL_PRODUCT_BASIS.csv.gz` — the 283,284-row final estimate basis;
- `RESULTATEN_MASTER.csv.gz` — the complete result master.

Those files are useful internally and for exact product assembly, but making them a one-click public download would move the website closer to being an alternative OECD/IEA-derived database. They are therefore excluded from GitHub Pages pending an explicit answer on redistribution.

Their filenames, byte sizes and SHA-256 hashes remain in `03_dashboard/data/PRODUCTION_DATA_MANIFEST.csv`, so the boundary is auditable.

## 4. Runtime aggregate data

An interactive static site cannot function without serving its displayed aggregate values. The public build therefore includes the aggregate JSON/CSV/SVG files the browser actually consumes. It does not include the two complete masters.

The publication build validates that:
- every runtime file matches the frozen final manifest;
- no source microdata file type enters the site;
- the two complete bulk master files are absent;
- the downloads page does not offer them;
- the browser does not recompute scientific estimates/ranks.

## 5. Source citation examples / dataset identifiers

IEA supplies dataset DOIs in its repository. Examples used in this project include:

PIRLS:
- 2001: https://doi.org/10.58150/PIRLS_2001_data
- 2006: https://doi.org/10.58150/PIRLS_2006_data
- 2011: https://doi.org/10.58150/PIRLS_2011_data
- 2016: https://doi.org/10.58150/PIRLS_2016_data
- 2021: https://doi.org/10.58150/PIRLS_2021_edition_2_including_Log-file_data

TIMSS Grade 4:
- 2011: https://doi.org/10.58150/IEA_TIMSS_2011_G4
- 2015: https://doi.org/10.58150/IEA_TIMSS_2015_G4
- 2019: https://doi.org/10.58150/IEA_TIMSS_2019_G4
- 2023: https://doi.org/10.58150/IEA_TIMSS_2023_G4_data_edition_1

For earlier TIMSS cycles and all PISA cycles, use the exact official source entries/provenance recorded by the project and the provider's current database pages/terms.

## 6. Change rule

If OECD or IEA later provides explicit written guidance, update this publication boundary prospectively and record the change. Do not silently replace the scientific release or historical public-site manifest.
