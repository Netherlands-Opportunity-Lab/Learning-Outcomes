# Y-axis scaling rule — Learning Outcomes Dashboard

Status: implementation rule for the chart-first dashboard.

## User-facing wording

Do not use the word “filters”. Use “choices”, “your choices”, “current view”, or “selected view” in public copy.

## Default rule: tight dynamic range

For every single-panel time-series figure, derive the y-axis from all point estimates that are visible in the current view.

1. Collect every visible estimate across all visible years, all visible series/groups, the selected reference country/system, and the visible comparison series if one is drawn.
2. Let point_min and point_max be the lowest and highest visible point estimates.
3. Add only a small visual margin:
   - default: 6% of the point-estimate span above and below;
   - minimum margin when the span is very small:
     - score / score-point outcomes: 2.5 points;
     - percent / percentage-point outcomes: 1 point;
     - rank: 0.5 position;
     - other numeric units: 1% of the absolute midpoint, with a small numeric floor.
4. Do not automatically anchor score or percentage line charts at zero.
5. For percentages, clamp the final domain to the logical bounds 0–100.
6. For ranks, clamp the lower bound to 1 and, where comparator_n is available, the upper logical bound to comparator_n + 1.
7. Confidence intervals must never be clipped. First determine the tight range from the visible point estimates, then extend only as far as needed to contain visible CI whiskers plus a small safety margin.
8. Direct labels and markers must not be clipped.

The visual aim is that the y-axis ends just below the lowest and just above the highest visible point, while leaving enough room for uncertainty and labels.

## When a fixed/shared y-axis is required

Keep or impose a shared/fixed y-axis only when the visual comparison itself requires the same scale:

1. Simultaneous small multiples or side-by-side panels that are explicitly meant to be compared quantitatively. All panels in that comparison must use the same scale_id, unit and y-domain.
2. 100% composition/stacked-share charts. Use 0–100.
3. Bar/deviation charts where zero is the quantitative baseline required for correct length comparison. Include zero.
4. A figure definition that explicitly carries a scientifically justified fixed-domain contract. The fixed domain must be declared upstream, not improvised in the browser.

## When a fixed y-axis should NOT be retained

Do not preserve the prior chart’s y-domain merely because the user changes:
- country/system;
- age/stage;
- domain;
- outcome;
- group split;
- levels versus difference;
- peer definition.

A new selected view may use a new tight y-domain unless it is part of an explicit simultaneous/shared-scale comparison.

Never share a score scale across PISA, PIRLS and TIMSS. They remain distinct assessment scales.

## Difference/gap series

For line charts of gaps/differences, use the same tight dynamic rule. Do not force zero into the domain if zero is far outside the observed range. If zero falls naturally inside or very near the dynamic domain, it may be shown as a subtle reference line. For future deviation/bar charts, zero remains mandatory.

## Tick rule

Keep approximately four y-axis ticks. The chart domain is determined by the data envelope above; tick placement must not expand the domain materially just to reach round numbers.

## QA

For every rendered chart:
- y_min is lower than the minimum visible estimate;
- y_max is higher than the maximum visible estimate;
- no visible CI endpoint is clipped;
- logical bounds are respected for percent/rank;
- the dynamic domain is not silently replaced by 0–100 for ordinary percentage time series;
- shared/fixed scales are used only under one of the explicit exceptions above.
