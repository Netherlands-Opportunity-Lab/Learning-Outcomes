# Data, code and redistribution

## Code

Code written for this project is licensed under the repository MIT licence unless an individual file states otherwise. The public repository is intended to make the complete analysis, dashboard and publication logic inspectable and reproducible.

## OECD PISA

The current PISA Public Use File terms distinguish access to the PISA Dataset from reporting results. They prohibit distributing/disclosing the PISA Dataset itself, while expressly allowing aggregated data to be included when individual participants or schools cannot be identified. They also require acknowledgement of OECD/PISA as the source.

Operational rule for this repository:
- do not redistribute PISA PUF/source files;
- publish only project-produced aggregate results;
- retain source attribution and study/table provenance;
- do not expose participant- or school-identifiable output.

Terms reviewed 28 September 2026:
https://survey.oecd.org/index.php?r=survey%2Findex&sid=197663

## IEA PIRLS/TIMSS

IEA makes public-use PIRLS/TIMSS datasets available through its Data Repository, subject to its Disclaimer and License Agreement. That agreement permits use for non-commercial educational and research purposes but restricts redistribution/reproduction of IEA publications and restricted-use items without written permission. It also states that third-party copyrighted assessment material (for example reading passages, photographs and images) requires permission from the relevant rights holder.

The agreement does not provide an equally explicit statement about redistribution of a large independently computed derived aggregate database. Pending an explicit response from IEA, this project therefore uses a conservative publication boundary:
- no IEA source files or restricted-use items;
- no assessment questions, reading passages, questionnaire reproductions or copied IEA publication figures;
- project-authored aggregate statistical reporting and project-authored figures may be shown with full attribution;
- the complete project bulk aggregate masters are not mirrored as public downloads.

IEA terms reviewed 28 September 2026:
https://www.iea.nl/sites/default/files/data-repository/Disclaimer_and_License_Agreement.pdf

## Public dashboard runtime

The public dashboard necessarily serves aggregate JSON/CSV/SVG files required to render its interactive views. These files contain project-computed aggregate results, not pupil microdata. They do not receive a blanket open-data licence from this repository. Users who want to reproduce the analysis should obtain the official source files from OECD/IEA and run the public code.

The complete bulk tables `FINAL_PRODUCT_BASIS.csv.gz` and `RESULTATEN_MASTER.csv.gz` remain outside the public site while the IEA redistribution question is unresolved.

This document records the project's operational interpretation of the source terms; it is not legal advice.
