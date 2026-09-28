# Final product integration control report

Basis: `PISA_PIRLS_FINAL_OUTPUT_20260927_202010_THIN_HANDOFF_FINAL.zip`.

## Technical freeze checks

- Completion estimates: 283,284 rows.
- Task status: 2,569/2,570 computed pending validation; 1 local task error.
- Self-tests: 20/20 pass.
- Technical validation: 7/8 pass. The finite-replication check has known unavailable/blocked cells; specific final status is in `FINAL_OPEN_POINTS_STATUS.csv` and `FINAL_USE_STATUS_REGISTER.csv`.
- Source holds: 0.

## Product integration rules applied

- No new pupil-level calculations.
- No new R script.
- Existing Step-4 decks/dashboard/figures retained where not affected.
- General statements that older PIRLS core-SEs were blocked are replaced by the final cycle-specific JRR status.
- PISA gender use follows label-verified variables; invalid PISA 2025 sources are blocked, not recoded.
- `aggregate_replicates/` remains locally retained and omitted from upload; registers/provenance included.

## Tested here

- Final thin handoff manifest/hash/size verified earlier on upload.
- Product-basis exports created and row counts checked.
- Registers written from final freeze.
- Deck PPTX files patched at XML level and rendered to PDF with LibreOffice.
- Scientific note DOCX rendered to PDF with LibreOffice; page images generated for QA.
- Dashboard served locally via HTTP for basic endpoint checks.

## Not tested here

- Interactive PowerPoint editing in Microsoft PowerPoint.
- Full cross-browser/mobile manual dashboard QA beyond local endpoint and HTML/data availability.
- Recompute of omitted aggregate replicate arrays; they are retained locally and registered.

## Render and endpoint QA

- Policy deck rendered to PDF and slide montage inspected.
- Scientific deck rendered to PDF and slide montage inspected.
- Scientific note rendered to PDF and page montage inspected.
- Dashboard local HTTP endpoints returned 200 for index, downloads, JS, metadata and FINAL_PRODUCT_BASIS.csv.gz.
