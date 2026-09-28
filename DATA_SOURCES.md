# Data sources and acquisition

The project uses OECD PISA and IEA PIRLS/TIMSS source files. Access, citation and redistribution conditions are source-specific. This repository does not redistribute pupil-level source files.

## Required source families

- **PISA:** student questionnaire/design files and plausible values for reading, mathematics and science; ESCS/background variables; school/student IDs where required.
- **PIRLS:** cycle-specific student files, plausible values, final student weights and cycle-specific replicate/JRR variables.
- **TIMSS Grade 4:** mathematics/science student files, plausible values, weights, replicate design variables, and where required the distinct TIMSS Numeracy companion sample.

The source registry directory contains final source/provenance tables and documented unavailable means. User-specific absolute paths are replaced by `${LOCAL_DOWNLOADS}`.

## Redistribution rule

When redistribution permission for OECD/IEA-derived bytes is not clearly established, commit provenance, checksums, download instructions and code—not the source bytes. The same rule is applied to the large production dashboard data package.
