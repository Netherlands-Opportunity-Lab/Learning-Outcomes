# Dashboard RC1 validation report

Status: `DASHBOARD_RC1 = FINAL_DEPLOYABLE_PRIVATE`

## Build summary

- Release: `dashboard-rc1-20260922`
- Analysis source: `ANALYSIS_RELEASE_RC1_20260922_v3` (as frozen by Step 1 / consumed by Step 2)
- Figure source: `FIGURE_RELEASE_RC1_FINAL`
- Countries/systems with generated browser profiles: 136
- Core observations: 10,059
- Frozen figure assets carried forward: 14 figure families, SVG/PDF/PNG where available
- Automated release checks: 18/18 PASS
- Raw microdata included: no
- Scientific estimators in frontend: no

## Key regression checks

The dashboard data build verifies four Netherlands latest-wave N=45 anchors against the frozen Step-2 plotting data: score gap age≈10, score gap age15, baseline-proficiency gap age≈10 and age15, including their ranks and SEs.

The main latest-wave SES panel contains 45 systems through the explicit Kosovo education-system bridge. The exact-ID N=44 version is retained as a separate sensitivity download.

## Scientific boundary

The browser only selects, formats and renders precomputed data. It does not calculate ranks, panels, group gaps, sampling variances, plausible-value combinations, JRR/BRR statistics, sorting measures or sample selections.

## Quality propagation

Representativeness, sorting-vs-OECD and language/migration remain conditional modules where specified by RC1. The interface therefore shows status badges and does not translate conditional evidence into causal claims.

## Web smoke test

Static files were served successfully with Python's HTTP server and critical resources returned HTTP 200. JavaScript syntax was checked with Node. Headless Chromium/Playwright navigation to localhost is blocked by the execution environment's browser administrator policy, so no claim of an automated visual-browser screenshot is made here.

## Public deployment gate

The pre-existing project caveat register still says not to activate a public PIRLS/TIMSS republication/download layer before IEA rights are clarified in writing. Therefore Step 3 produces a complete deployable private release and GitHub staging PR, but does not knowingly make the PIRLS-derived public data layer live.
