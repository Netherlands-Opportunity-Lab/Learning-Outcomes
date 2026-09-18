export const locales = ["nl", "en"] as const;
export type Locale = (typeof locales)[number];

export const messages = {
  nl: {
    brand: "Leerprestaties in beeld",
    strapline: "Niveaus, verschillen en trends op 10- en 15-jarige leeftijd",
    pageTitle: "Leerprestaties in internationaal perspectief",
    intro:
      "Vergelijk de ontwikkeling van leerprestaties zonder meetreeksen, leeftijden of sociale groepen op één hoop te gooien.",
    prototype: "Werkend prototype met synthetische demonstratiegegevens — geen onderzoeksresultaten",
    skip: "Ga naar de figuur",
    language: "English",
    question: "Wat wilt u vergelijken?",
    questions: {
      trend: "Hoe ontwikkelt het prestatieniveau zich?",
      proficiency: "Welk percentage haalt het basisniveau?",
      background: "Hoe verschillen kinderen naar sociale achtergrond?",
      international: "Hoe staat het land internationaal?"
    },
    comingSoon: "Volgt na validatie",
    controls: "Kies wat u wilt zien",
    country: "Land",
    age: "Leeftijd",
    age10: "Ongeveer 10 jaar",
    age15: "15 jaar",
    domain: "Domein",
    reading: "Lezen",
    mathematics: "Wiskunde",
    science: "Science",
    chartEyebrow: "Ontwikkeling door de tijd",
    subtitle: "Gemiddelde score met 95%-betrouwbaarheidsinterval voor het gekozen land",
    points: "Toetspunten",
    noData: "Voor deze combinatie zijn nog geen gegevens beschikbaar.",
    interpretationHeading: "Wat betekent dit?",
    interpretation:
      "De lijn beschrijft het geschatte gemiddelde binnen iedere afzonderlijke internationale studie. Zij volgt niet dezelfde kinderen en bewijst geen oorzaak van veranderingen.",
    methodsHeading: "Hoe is dit berekend?",
    methods:
      "In productie worden alle plausible values, de voorgeschreven leerling- en replicategewichten en een vaste landenpopulatie gebruikt. PISA en PIRLS blijven afzonderlijke meetreeksen.",
    source: "Bron: synthetische gegevens voor interfaceontwikkeling. Analyserelease prototype-0.1.0.",
    downloadCsv: "Download getoonde data",
    printPdf: "Bewaar als PDF",
    share: "Kopieer link naar deze view",
    copied: "Link gekopieerd",
    unavailable: "Nog niet beschikbaar",
    footer:
      "Onafhankelijk onderzoeksprototype. Geen officiële publicatie van OECD, IEA of UNICEF."
  },
  en: {
    brand: "Learning Outcomes Explorer",
    strapline: "Levels, inequalities and trends at ages 10 and 15",
    pageTitle: "Learning outcomes in international perspective",
    intro:
      "Compare trends in learning outcomes without conflating assessments, ages or social groups.",
    prototype: "Working prototype with synthetic demonstration data — not research findings",
    skip: "Skip to the figure",
    language: "Nederlands",
    question: "What would you like to compare?",
    questions: {
      trend: "How is the performance level changing?",
      proficiency: "What share reaches basic proficiency?",
      background: "How do outcomes differ by social background?",
      international: "How does the country compare internationally?"
    },
    comingSoon: "Available after validation",
    controls: "Choose what to show",
    country: "Country",
    age: "Age",
    age10: "About age 10",
    age15: "Age 15",
    domain: "Domain",
    reading: "Reading",
    mathematics: "Mathematics",
    science: "Science",
    chartEyebrow: "Change over time",
    subtitle: "Mean score with a 95% confidence interval for the selected country",
    points: "Test-score points",
    noData: "No data are available for this combination yet.",
    interpretationHeading: "What does this mean?",
    interpretation:
      "The line describes the estimated mean in each separate international assessment. It does not follow the same children and does not identify the cause of changes.",
    methodsHeading: "How was this calculated?",
    methods:
      "Production estimates will use all plausible values, the prescribed student and replicate weights, and a fixed country panel. PISA and PIRLS remain separate series.",
    source: "Source: synthetic data for interface development. Analysis release prototype-0.1.0.",
    downloadCsv: "Download displayed data",
    printPdf: "Save as PDF",
    share: "Copy link to this view",
    copied: "Link copied",
    unavailable: "Not yet available",
    footer:
      "Independent research prototype. Not an official publication of OECD, IEA or UNICEF."
  }
} as const;

export function getMessages(locale: Locale) {
  return messages[locale];
}
