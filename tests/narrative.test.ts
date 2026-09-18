import { describe, expect, it } from "vitest";
import { messages } from "../src/i18n/messages";
import { classifyTrend, trendTitle } from "../src/lib/narrative";
import { buildViewQuery } from "../src/lib/viewState";

function flattenKeys(value: unknown, prefix = ""): string[] {
  if (typeof value !== "object" || value === null) return [prefix];
  return Object.entries(value).flatMap(([key, child]) =>
    flattenKeys(child, prefix ? `${prefix}.${key}` : key)
  );
}

describe("controlled narrative", () => {
  it("classifies direction with a neutral interval", () => {
    expect(classifyTrend(-3)).toBe("decrease");
    expect(classifyTrend(3)).toBe("increase");
    expect(classifyTrend(1)).toBe("stable");
    expect(classifyTrend(-3, 2)).toBe("stable");
    expect(classifyTrend(-5, 2)).toBe("decrease");
  });

  it("renders parallel Dutch and English claims", () => {
    const nl = trendTitle({
      locale: "nl",
      country: "Nederland",
      domain: "lees",
      ageLabel: "15-jarigen",
      change: -10,
      changeStandardError: 2
    });
    const en = trendTitle({
      locale: "en",
      country: "the Netherlands",
      domain: "reading",
      ageLabel: "15-year-olds",
      change: -10,
      changeStandardError: 2
    });
    expect(nl).toContain("daalden");
    expect(en).toContain("decreased");
    expect(`${nl} ${en}`).not.toMatch(/veroorzaakt|caused by/i);
  });

  it("keeps translation keys in sync", () => {
    expect(flattenKeys(messages.nl).sort()).toEqual(flattenKeys(messages.en).sort());
  });
});

describe("shareable view state", () => {
  it("serialises every active option into a stable query string", () => {
    const query = buildViewQuery({
      country: "NLD",
      age: 15,
      domain: "reading",
      metric: "mean_score",
      view: "trend",
      comparison: "fixed_panel",
      release: "prototype-0.1.0"
    });
    expect(query).toBe(
      "age=15&comparison=fixed_panel&country=NLD&domain=reading&metric=mean_score&release=prototype-0.1.0&view=trend"
    );
  });
});
