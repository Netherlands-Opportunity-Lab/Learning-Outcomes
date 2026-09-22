# PISA/PIRLS Learning Outcomes Dashboard — RC1 staging

Step 3 release for the frozen reading RC1.

## Release status

- analysis: `ANALYSIS_RELEASE_RC1_20260922_v3`
- figures: `FIGURE_RELEASE_RC1_FINAL`
- dashboard: `dashboard-rc1-20260922`
- local validation: 18/18 release checks PASS
- browser profiles generated: 136 countries/systems
- core observations: 10,059
- raw OECD/IEA microdata: not included
- scientific estimators in browser: none

The browser may select, label, format and render frozen values. It may not compute ranks, panels, SES gaps, sorting measures, standard errors, plausible-value statistics, replicate estimates or sample selections.

## GitHub staging note

The complete tested snapshot is distributed as `PISA_PIRLS_DASHBOARD_RC1_FINAL_REPO.zip` with SHA-256
`7f4c92f8afe067099235b4818e67a57d5d94d75a8b61dbafffbe4f38e528a301`.

The aggregate data snapshot is `DASHBOARD_RC1_DATA_RELEASE.zip` with SHA-256
`48e729eef067af6459884c18fa66f5d47398a2c391593ba525d40e8a0bac65e2`.

This GitHub branch records the release metadata, validation and publication gate. The connector used for this staging pass cannot transfer the generated multi-file snapshot atomically from the analysis container, so the ZIP snapshot remains the byte-level source of truth for Step 3.

Do not enable a public PIRLS-derived download layer until the existing IEA republication-rights caveat has been resolved in writing.
