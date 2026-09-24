# PISA/PIRLS dashboard · stap 4 · private review

Deze versie bevat de beschikbare leesanalyse en 16 gecontroleerde Nederlandse domeingemiddelden als beperkte context. Er is geen volledige RC2-freeze en geen openbare publicatie.

## Direct bekijken

Pak de ZIP uit, open een terminal in deze map en voer uit:

```sh
python -m http.server 8000
```

Open `http://localhost:8000`. Het dashboard gebruikt lokale bestanden en heeft geen npm-installatie of externe CDN nodig. Rechtstreeks dubbelklikken op `index.html` werkt in veel browsers niet vanwege lokale fetch-beperkingen.

## Reproduceren

Python 3 en Node.js volstaan; geen aanvullende packages voor build/validatie:

```sh
python scripts/build_bundle.py
python scripts/build_downloads.py
python scripts/validate_release.py
node --check assets/app.js
node tests/render_checks.cjs
```

De leesbron is RC1 v3 (41 exacte CSV-tabellen); nieuwe addenda blijven apart. Elke leeftijd heeft een eigen schaal. Nederland/Nederlands is de standaard; land, leeftijd, onderwerp, taal en panel worden in de URL opgeslagen. N=45 maximaal en N=43 kwaliteitsselectie zijn afzonderlijk kiesbaar. MAIN12 zonder Noorwegen is beschikbaar naast MAIN13/ROBUST16. Groepsniveaus, kloven, rangen en SE’s worden apart gelabeld.

De publicatievoorwaarde C001 blijft open. Het pakket bevat geen individuele leerlinggegevens. Zie `DASHBOARD_VALIDATION.md`, `docs/SCIENTIFIC_BOUNDARIES.md`, `docs/PUBLICATION_STATUS.md` en `audit/` voor controles, methoden, versieherkomst en beperkingen.

## Browsercontrole

De renderfuncties, HTTP-bestanden, alle bronhashes en logische regressies zijn gecontroleerd. Er is geen volledige browser-/screenshotcontrole voltooid: Chromium ontbrak en de browserdownload leverde een ongeldig archief. De meegeleverde Playwright-test is een optionele latere controle, geen geslaagde testclaim.
