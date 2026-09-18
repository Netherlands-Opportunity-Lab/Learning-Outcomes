import type { Locale } from "../i18n/messages";

export type TrendDirection = "increase" | "decrease" | "stable";

export function classifyTrend(change: number, standardError?: number): TrendDirection {
  const threshold = standardError === undefined ? 2 : 1.96 * standardError;
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
  changeStandardError?: number;
}): string {
  const direction = classifyTrend(input.change, input.changeStandardError);

  if (input.locale === "nl") {
    const verb = {
      increase: "stegen",
      decrease: "daalden",
      stable: "lieten geen statistisch duidelijk verschil zien tussen het eerste en laatste jaar"
    }[direction];
    return `${input.domain}prestaties van ${input.ageLabel} in ${input.country} ${verb} in deze voorbeeldreeks`;
  }

  const verb = {
    increase: "increased",
    decrease: "decreased",
    stable: "showed no statistically clear difference between the first and final year"
  }[direction];
  return `${input.domain} outcomes for ${input.ageLabel} in ${input.country} ${verb} in this example series`;
}
