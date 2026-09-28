import type { Locale } from "../i18n/messages";

export type TrendDirection = "increase" | "decrease" | "stable";

export function classifyTrend(change: number, threshold = 2): TrendDirection {
  if (change > threshold) return "increase";
  if (change < -threshold) return "decrease";
  return "stable";
}

export function trendTitle(input: {
  locale: Locale;
  country: string;
  domain: string;
  ageLabel: string;
  change: number;
}): string {
  const direction = classifyTrend(input.change);

  if (input.locale === "nl") {
    const verb = {
      increase: "stegen",
      decrease: "daalden",
      stable: "veranderden nauwelijks"
    }[direction];
    return `${input.domain}prestaties van ${input.ageLabel} in ${input.country} ${verb} in deze voorbeeldreeks`;
  }

  const verb = {
    increase: "increased",
    decrease: "decreased",
    stable: "changed little"
  }[direction];
  return `${input.domain} outcomes for ${input.ageLabel} in ${input.country} ${verb} in this example series`;
}
