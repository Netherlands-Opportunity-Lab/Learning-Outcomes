# Ontwerptokens voor dashboard en figuren

Deze waarden volgen `Stijlgids_slides_figuren_PISA_PIRLS_v1_1_definitief(3).docx`
van 18 september 2026. Dit is de leidende projectstandaard. De gecontroleerde
bron heeft SHA-256
`89b25e67e8574722ebe55302bc8b32a466fa84214fd8142149018260dfbb0327`.

## Functionele kleuren

| Functie | Hex |
| --- | --- |
| Achtergrond | `#F7F5F0` |
| Hoofdtekst | `#17242D` |
| Secundaire tekst | `#59636A` |
| Focaal land | `#315D8A` |
| Context licht | `#C3C7C9` |
| Context donker | `#8B9298` |
| Gridlijn | `#D8D8D3` |
| Waarschuwing | `#984F3F` |

## Ordinale achtergrondkleuren

| Positie | Vlak | Lijn |
| --- | --- | --- |
| 1 laag | `#EBC45A` | `#9A6D00` |
| 2 | `#82A85B` | `#587A32` |
| 3 midden | `#5EA6A7` | `#2C807F` |
| 4 | `#4C77A8` | `#4C77A8` |
| 5 hoog | `#6B5A8E` | `#6A4C93` |

Gebruik bij twee groepen posities 1 en 5, bij drie groepen posities 1, 3 en 5,
en bij vier groepen posities 1, 2, 4 en 5. Bij vijf inhoudelijk geordende
groepen wordt de volledige reeks gebruikt. Kleuren krijgen nooit achteraf een
andere rangbetekenis. In PIRLS verwijzen de vijf posities primair naar de echte
categorieën boeken thuis en niet naar quintielen.

## Regels

- Eén analytische taak per figuur.
- Focus krijgt kleur; context wordt grijs.
- Maximaal vijf opvallend gekleurde series.
- Directe labels hebben voorrang op legenda's.
- Onzekerheid blijft zichtbaar.
- Kleur is nooit de enige informatiedrager.
- Geen 3D, decoratieve schaduwen, dubbele y-assen of afgekapte staafassen.
- Een losse figuur bevat titel, statistische subtitel, bron en noodzakelijke
  caveats.

## Webspecifieke toepassing en gemotiveerde afwijkingen

De gids is geschreven voor slides en losse figuren; het dashboard is ook een
responsieve applicatie. Daarom gelden drie vastgelegde aanpassingen:

- Het webcanvas volgt geen vaste 16:9-afmeting, zodat telefoon, tablet en
  desktop bruikbaar blijven. De printweergave reduceert wel tot één zelfstandig
  leesbare figuur.
- Puntgroottes uit PowerPoint worden niet één-op-één als CSS-pixels gebruikt.
  Grafieklabels zijn op het web minimaal 16 CSS-pixels; bronregels minimaal
  12 CSS-pixels. De hiërarchie en contrastregels uit de gids blijven gelden.
- Selectievelden en actieknoppen zijn functionele bediening, geen decoratieve
  dashboardkaarten. Zij mogen daarom een zichtbare focus- en invoerrand hebben.

Alle overige afwijkingen vereisen een vermelding in dit bestand of in het
figuurregister.
