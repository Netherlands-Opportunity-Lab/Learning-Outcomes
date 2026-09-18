import * as Plot from "@observablehq/plot";
import exampleData from "../data/example-learning-outcomes.json";
import { getMessages, type Locale } from "../i18n/messages";
import { trendTitle } from "../lib/narrative";
import { buildViewQuery, type DashboardState } from "../lib/viewState";

type Observation = {
  country: string;
  survey: "PISA" | "PIRLS";
  age: 10 | 15;
  domain: "reading";
  year: number;
  estimate: number;
  se: number;
};

type ChartObservation = Observation & {
  ciLow: number;
  ciHigh: number;
  countryLabel: string;
};

const observations = exampleData.observations as Observation[];
const countryNames = {
  nl: { NLD: "Nederland", DEU: "Duitsland", BEL: "België" },
  en: { NLD: "Netherlands", DEU: "Germany", BEL: "Belgium" }
} as const;

const colours = {
  background: "#F7F5F0",
  text: "#17242D",
  muted: "#59636A",
  focus: "#315D8A",
  context: "#C3C7C9",
  contextDark: "#8B9298",
  grid: "#D8D8D3"
};

function validCountry(value: string | null): value is keyof typeof countryNames.nl {
  return value !== null && value in countryNames.nl;
}

function parseState(root: HTMLElement): DashboardState {
  const params = new URLSearchParams(window.location.search);
  const initial = root.dataset.initialCountry ?? "NLD";
  const countryParam = params.get("country");
  const ageParam = params.get("age");

  return {
    country: validCountry(countryParam) ? countryParam : validCountry(initial) ? initial : "NLD",
    age: ageParam === "10" ? 10 : 15,
    domain: "reading",
    metric: "mean_score",
    view: "trend",
    comparison: "fixed_panel",
    release: exampleData.meta.release
  };
}

function csvCell(value: string | number): string {
  const text = String(value);
  return /[",\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

function downloadCsv(rows: ChartObservation[], state: DashboardState, locale: Locale) {
  const header = [
    "country_iso3",
    "country",
    "survey",
    "cycle",
    "age_group",
    "domain",
    "metric",
    "estimate",
    "standard_error",
    "ci_low",
    "ci_high",
    "panel_id",
    "quality_flags",
    "source_id",
    "analysis_release"
  ];
  const body = rows.map((row) => [
    row.country,
    row.countryLabel,
    row.survey,
    row.year,
    `age_${row.age}`,
    row.domain,
    state.metric,
    row.estimate,
    row.se,
    row.ciLow.toFixed(3),
    row.ciHigh.toFixed(3),
    `${row.survey.toLowerCase()}_${row.age}_prototype_fixed_panel`,
    "synthetic_prototype",
    "synthetic-interface-data",
    state.release
  ]);
  const csv = [header, ...body].map((row) => row.map(csvCell).join(",")).join("\n");
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
  const href = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = href;
  anchor.download = `learning-outcomes_${state.country}_age-${state.age}_${state.domain}_${locale}_${state.release}.csv`;
  anchor.click();
  URL.revokeObjectURL(href);
}

function initialise(root: HTMLElement) {
  const locale = (root.dataset.locale === "en" ? "en" : "nl") as Locale;
  const copy = getMessages(locale);
  const names = countryNames[locale];
  const controls = root.querySelector<HTMLFormElement>("[data-controls]");
  const countrySelect = root.querySelector<HTMLSelectElement>("[data-country]");
  const domainSelect = root.querySelector<HTMLSelectElement>("[data-domain]");
  const chart = root.querySelector<HTMLElement>("[data-chart]");
  const chartTitle = root.querySelector<HTMLElement>("[data-chart-title]");
  const chartSubtitle = root.querySelector<HTMLElement>("[data-chart-subtitle]");
  const chartStatus = root.querySelector<HTMLElement>("[data-chart-status]");
  const languageLink = root.querySelector<HTMLAnchorElement>("[data-language-link]");
  const downloadButton = root.querySelector<HTMLButtonElement>("[data-download]");
  const printButton = root.querySelector<HTMLButtonElement>("[data-print]");
  const shareButton = root.querySelector<HTMLButtonElement>("[data-share]");
  const actionStatus = root.querySelector<HTMLElement>("[data-action-status]");

  if (!controls || !countrySelect || !domainSelect || !chart || !chartTitle || !chartSubtitle || !chartStatus) return;

  const chartElement = chart;
  const chartTitleElement = chartTitle;
  const chartSubtitleElement = chartSubtitle;
  const chartStatusElement = chartStatus;

  const state = parseState(root);
  countrySelect.value = state.country;
  domainSelect.value = state.domain;
  const ageInput = controls.querySelector<HTMLInputElement>(`input[name="age"][value="${state.age}"]`);
  if (ageInput) ageInput.checked = true;

  let displayedRows: ChartObservation[] = [];

  function syncUrl() {
    const query = buildViewQuery(state);
    const countryBase = root.dataset.countryBase ?? "/";
    const alternateBase = root.dataset.alternateBase ?? "/";
    const nextPath = `${countryBase}${state.country}/?${query}`;
    window.history.replaceState({}, "", nextPath);
    if (languageLink) languageLink.href = `${alternateBase}${state.country}/?${query}`;
  }

  function render() {
    const selected = observations
      .filter((row) => row.age === state.age && row.domain === state.domain)
      .map((row) => ({
        ...row,
        ciLow: row.estimate - 1.96 * row.se,
        ciHigh: row.estimate + 1.96 * row.se,
        countryLabel: names[row.country as keyof typeof names] ?? row.country
      }))
      .sort((a, b) => a.year - b.year || a.country.localeCompare(b.country));
    displayedRows = selected;

    const focus = selected.filter((row) => row.country === state.country);
    const context = selected.filter((row) => row.country !== state.country);

    if (focus.length === 0) {
      chartElement.replaceChildren();
      chartStatusElement.textContent = copy.noData;
      chartTitleElement.textContent = copy.noData;
      syncUrl();
      return;
    }

    chartStatusElement.textContent = "";
    const first = focus.at(0)!;
    const last = focus.at(-1)!;
    const ageLabel = state.age === 10 ? copy.age10.toLowerCase() : copy.age15.toLowerCase();
    const domainLabel = copy.reading.toLowerCase();
    const title = trendTitle({
      locale,
      country: names[state.country as keyof typeof names] ?? state.country,
      domain: domainLabel,
      ageLabel,
      change: last.estimate - first.estimate
    });
    chartTitleElement.textContent = title;
    chartSubtitleElement.textContent = copy.subtitle(
      first.survey,
      ageLabel,
      first.year,
      last.year
    );

    const values = selected.flatMap((row) => [row.ciLow, row.ciHigh]);
    const yMin = Math.floor((Math.min(...values) - 8) / 10) * 10;
    const yMax = Math.ceil((Math.max(...values) + 8) / 10) * 10;
    const lastContext = context.filter((row) =>
      !context.some((candidate) => candidate.country === row.country && candidate.year > row.year)
    );

    const plot = Plot.plot({
      width: Math.max(320, chartElement.clientWidth),
      height: 440,
      marginTop: 18,
      marginRight: 112,
      marginBottom: 46,
      marginLeft: 58,
      style: {
        background: "transparent",
        color: colours.text,
        fontFamily: 'Aptos, "Segoe UI", Arial, sans-serif',
        fontSize: "16px"
      },
      x: {
        label: null,
        ticks: [...new Set(focus.map((row) => row.year))],
        tickFormat: (year) => String(year)
      },
      y: {
        label: copy.points,
        domain: [yMin, yMax],
        grid: true,
        ticks: 5
      },
      marks: [
        Plot.areaY(focus, {
          x: "year",
          y1: "ciLow",
          y2: "ciHigh",
          fill: colours.focus,
          fillOpacity: 0.17
        }),
        Plot.lineY(context, {
          x: "year",
          y: "estimate",
          z: "country",
          stroke: colours.context,
          strokeWidth: 1.5
        }),
        Plot.lineY(focus, {
          x: "year",
          y: "estimate",
          stroke: colours.focus,
          strokeWidth: 4
        }),
        Plot.dot(focus, {
          x: "year",
          y: "estimate",
          fill: colours.focus,
          r: 4
        }),
        Plot.text(lastContext, {
          x: "year",
          y: "estimate",
          text: "countryLabel",
          dx: 8,
          textAnchor: "start",
          fill: colours.muted,
          fontSize: 16
        }),
        Plot.text([last], {
          x: "year",
          y: "estimate",
          text: (row) => `${row.countryLabel} ${row.estimate}`,
          dx: 8,
          textAnchor: "start",
          fill: colours.focus,
          fontWeight: 700,
          fontSize: 16
        })
      ]
    });
    plot.setAttribute("role", "img");
    plot.setAttribute("aria-label", title);
    chartElement.replaceChildren(plot);
    syncUrl();
  }

  controls.addEventListener("change", () => {
    state.country = countrySelect.value;
    state.domain = "reading";
    const selectedAge = controls.querySelector<HTMLInputElement>('input[name="age"]:checked');
    state.age = selectedAge?.value === "10" ? 10 : 15;
    render();
  });

  downloadButton?.addEventListener("click", () => downloadCsv(displayedRows, state, locale));
  printButton?.addEventListener("click", () => window.print());
  shareButton?.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(window.location.href);
      if (actionStatus) actionStatus.textContent = copy.copied;
    } catch {
      window.prompt(copy.share, window.location.href);
    }
  });

  let resizeTimer: number | undefined;
  window.addEventListener("resize", () => {
    window.clearTimeout(resizeTimer);
    resizeTimer = window.setTimeout(render, 120);
  });

  render();
}

export function initDashboards() {
  document.querySelectorAll<HTMLElement>("[data-dashboard]").forEach(initialise);
}
