export type DashboardState = {
  country: string;
  age: 10 | 15;
  domain: "reading";
  metric: "mean_score";
  view: "trend";
  comparison: "fixed_panel";
  release: string;
};

export function buildViewQuery(state: DashboardState): string {
  const params = new URLSearchParams({
    country: state.country,
    age: String(state.age),
    domain: state.domain,
    metric: state.metric,
    view: state.view,
    comparison: state.comparison,
    release: state.release
  });
  params.sort();
  return params.toString();
}
