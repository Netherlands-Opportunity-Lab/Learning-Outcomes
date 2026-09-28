# Beslisregister

## D001 Eén infrastructuur voor alle landen en talen

- Datum: 2026-09-18
- Status: vastgesteld
- Besluit: één codebasis, één taalneutrale feitenlaag en afzonderlijke routes
  voor taal en land.
- Reden: land en taal vallen niet één-op-één samen. De opzet schaalt met talen
  plus landen in plaats van met iedere taal-landcombinatie.

## D002 Nederlands standaard en Engels volledig gelijkwaardig

- Datum: 2026-09-18
- Status: vastgesteld
- Besluit: `/` verwijst naar `/nl/`; Nederlands en Engels gebruiken dezelfde
  componenten, data en narratieve regels.

## D003 Geen vrije AI-tekst in het publieke dashboard

- Datum: 2026-09-18
- Status: vastgesteld
- Besluit: conclusietitels en toelichtingen worden opgebouwd uit vooraf
  gecontroleerde sjablonen en gevalideerde feiten.
- Reden: reproduceerbaarheid, vertaalconsistentie en claimdiscipline.

## D004 Astro met Observable Plot

- Datum: 2026-09-18
- Status: voorlopig vastgesteld
- Besluit: Astro levert statische routes en pagina's; Observable Plot tekent de
  interactieve figuren; R produceert vooraf alle survey-estimates.

## D005 Nog geen publieke Pages-deployment

- Datum: 2026-09-18
- Status: vastgesteld
- Besluit: CI mag controleren en bouwen, maar bevat geen deployjob.
- Herziening: na rechtenbevestiging, datavalidatie en verwijdering van alle
  synthetische prototypegegevens.

## D006 Definitieve stijlgids is visueel leidend

- Datum: 2026-09-18
- Status: vastgesteld
- Besluit: `Stijlgids_slides_figuren_PISA_PIRLS_v1_1_definitief(3).docx`
  van 18 september 2026 is uitsluitend leidend voor vormgeving, visuele
  grammatica, slide-opbouw, typografie, kleuren, grafiekkeuze, annotaties,
  toegankelijkheid, technische productie en visuele reproduceerbaarheid
  (SHA-256 `89b25e67e8574722ebe55302bc8b32a466fa84214fd8142149018260dfbb0327`).
- Begrenzing: de stijlgids bepaalt geen estimands, groepsdefinities,
  steekproeven, analysemethoden of inhoudelijke conclusies. Daarvoor zijn het
  analyseprotocol, gevalideerde code en gecontroleerde outputs leidend.
- Afwijkingen: visuele afwijkingen alleen om een gemotiveerde inhoudelijke,
  toegankelijkheids- of responsieve reden en altijd kort vastgelegd in
  `docs/style/design-tokens.md` of het figuurregister.
