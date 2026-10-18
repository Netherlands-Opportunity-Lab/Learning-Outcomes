# 05 — Dashboardcode, resultaten en publicatie

Bijgewerkt: 18 oktober 2026. De vijfkeuze-interface en gecontroleerde resultaten staan op GitHub Pages. De laatste gebruikerskeuze activeert tijdelijk vergelijkingen met beschikbare punten via [REFERENCE_POLICY.json](REFERENCE_POLICY.json). Ieder vergelijkingspunt registreert de daadwerkelijk gebruikte landen; de definitieve balanscontrole volgt na volledige productie. [Actuele versie](INTERIM_CURRENT.json) en [uitvoeringsbewijs](../06_pipeline/review_20261013/DASHBOARD_PROVISIONAL_20261018.json).

## Actieve code en uitleg

| Onderdeel | Bestand of map |
|---|---|
| Actuele besluiten en voortgang | [START_HIER_ACTUEEL.md](../06_pipeline/START_HIER_ACTUEEL.md) |
| Vijf keuzes, figuren en huisstijl | [Dashboarduitwerking](preview_overlay/DASHBOARD_UITWERKING_20261015.md) |
| HTML, CSS, JavaScript, originele logo's en fonts | [preview_overlay](preview_overlay/) |
| Goedgekeurde R-cellen naar productregels | [LO_FINAL_GUIDED_EXPORT.R](../06_pipeline/LO_FINAL_GUIDED_EXPORT.R) |
| Volledige passende landen en groepen | [LO_BALANCED_VIEWS.R](../06_pipeline/LO_BALANCED_VIEWS.R) |
| Statische website bouwen uit gecontroleerde export | [LO_FINAL_GUIDED_DASHBOARD_BUILD.py](../06_pipeline/LO_FINAL_GUIDED_DASHBOARD_BUILD.py) |
| Onafhankelijke vrijgavecontrole en staging | [LO_FINAL_GUIDED_PUBLIC_RELEASE.py](../06_pipeline/LO_FINAL_GUIDED_PUBLIC_RELEASE.py) |
| Exacte kandidaat voorbereiden voor Pages | [prepare_verified_pages.py](prepare_verified_pages.py) |
| GitHub Pages-publicatie | [pages.yml](../.github/workflows/pages.yml) |
| Windows/Linux- en browserbewijs | [Dashboardacceptatie](../06_pipeline/review_20261013/DASHBOARD_UI_ACCEPTANCE_20261015.json) |

## Van RStudio naar de openbare website

1. De bestaande goedgekeurde productie maakt de statistieken. De bestaande
   `fixed-finalize`-fase exporteert gecertificeerde resultaten en balansbewijs
   en bouwt hiermee een nieuwe kandidaat. Dit is geen tweede analyseketen.
2. De kandidaat bevat openbare aggregaten, beschikbaarheidsmeldingen,
   figuurdefinities, referentiebewijs en een SHA-256-manifest. Ontbrekende
   resultaten blijven zichtbaar; een preview is geen wetenschappelijke vrijgave.
3. De vrijgavecontrole toetst de kandidaat tegen het onafhankelijke certificaat,
   inclusief wetenschappelijke, scope-, rechten-, replicatie- en productcontroles.
   Een geslaagde kandidaat wordt opgeslagen onder
   `verified_guided_candidates/<candidate-id>/`.
4. Na review en de toepasselijke publicatiegoedkeuring worden de benodigde
   wijzigingen via PR #5 overgenomen. De handmatige GitHub Actions-workflow
   `publish-verified-dashboard-pages` krijgt het exacte candidate-ID van 20
   hexadecimale tekens. Zij controleert en publiceert uitsluitend die bestanden.

GitHub bewaart de code, versies en toegestane resultaten. GitHub Pages serveert
de gebouwde website. De URL `127.0.0.1` is alleen een lokale preview op de
computer waarop de previewserver draait. ChatGPT Pages en Sites zijn voor deze
GitHub-route niet nodig.

De browser schat geen nieuwe statistieken uit leerlingdata. Hij kan wel de
expliciet gekozen referentiegemiddelden en puntrangen afleiden uit gecertificeerde
aggregaten. De tijdelijke stand registreert leden per punt; de strenge stand
vereist vaste leden over de volledige vergelijking. Beide bewaren oudercellen.
De oorspronkelijke septemberrelease hieronder had een andere runtime en blijft
als historische release beschreven; haar beperkingen zijn geen beschrijving
van de nieuwe figuurbouwer.

---

# Historische septemberrelease — bewaard als bewijs

This directory is the definitive public product layer for the frozen PISA/PIRLS/TIMSS dashboard. It does not replace the scientific source under `03_dashboard/`; it builds from the canonical renderer and precomputed frozen aggregates.

## Source locks

- Scientific/product source commit: `749a0de8e6ab707f4ecd887247ea8fde82f55656`
- Analysis release: `FINAL_ANALYSIS_FREEZE_20260928`
- Public integration base SHA: `db8b7d7ddc22c6d96191148ffac9c2953dc00900`
- Canonical dashboard renderer: `03_dashboard/app/`
- Complete private production-data inventory: `03_dashboard/data/PRODUCTION_DATA_MANIFEST.csv`

## Publication controls

- `PUBLIC_DATA_GATE.csv` — file/data classification.
- `PUBLIC_DASHBOARD_MANIFEST.json` — exact public runtime files, byte sizes, SHA-256 and provenance.
- `PUBLIC_RESULT_FIDELITY.json` — recorded public-to-freeze comparison results.
- `PUBLICATION_QA_REPORT_20260928_FINAL.md` — final integration QA.
- `tests/build_public_release_registers.py` — reproducible private-master comparison code.
- `tests/validate_public_integration.py` — repository/public-site checks.
- `public_dashboard_runtime_20260928.zip` — minimal 253-file runtime transport.

The runtime ZIP is 14,525,361 bytes with SHA-256:
`ae6404aeedecdf3f42e22ef1612e27d3f0e61bc663a0fc99f89aad4c8c15a706`.

It contains only the aggregate JSON and project-authored figure assets needed by the public site. Four small project control tables that are not fetched or linked by the frontend are omitted from the runtime; the two complete derived masters are also omitted.

## Scientific rule

The browser does not compute estimates, SEs, CIs, ranks, panels or scientific aggregates. Public-result fidelity is checked against the final frozen master before merge, while public CI verifies the committed manifest, runtime hashes and recorded zero-mismatch evidence.

## Hosting

The September runtime remains historical evidence. The current manual publication workflow is described above; it now requires an independently certified October candidate ID. A merge alone does not deploy a website.
