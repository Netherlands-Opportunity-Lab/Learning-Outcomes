# Learning Outcomes — figuurbesluiten en literatuurkoppeling (12 oktober 2026)

Status: gebruikersbesluit voor figuurontwerp; **geen wetenschappelijke vrijgave van resultaten**.

Leidend: de 21-slide gebruikersversie van 1 oktober, `MASTERPLAN_20261011_v2.md`, de 138 bestaande figuurcontracten (historisch bewaard), de literatuurmatrix van 29 september (30 bronnen), en de aanvullend geraadpleegde publicaties.

## Nieuwe figuurbesluiten
- Figuur 3 (≥ basisniveau totaal) vervalt als **apart plaatje**; complement 100 − aandeel onder basisniveau blijft berekenbaar zonder extra leerlingtaak.
- Figuur 12 wordt *onder basisniveau per SES Q1/Q4*; oude slide 6 en 9 moeten bij eindredactie worden gespiegeld. De bestaande gegevens en contracthistorie niet verwijderen.
- Figuur 13 hoog niveau per SES vervalt als verplichte standaardfiguur en blijft een optionele analyse van de bovenkant in appendix/dashboard. Geen tweede identieke onder-basisfiguur.
- Figuur 11 (SES Q4−Q1) en 15 (meisjes−jongens) zijn **afgeleide contrasten** van groepsgemiddelden. De puntschatting vereist geen nieuwe microdata; een correcte contrast-SE heeft *covariantie of gezamenlijke PV/replicate estimates* nodig.
- Figuur 23 krijgt *peer-aandeel onder basisniveau* als hoofdmaat, met eigen status onder/≥basis als subgroepen; *peer-aandeel op hoog niveau* is zelfstandige optionele robustness, wegens mogelijke andere vorm van prestatieconcentratie.
- 'Trendverschillen' zijn afgeleide veranderingen (jaar t − jaar s) en, waar nodig, verschillen in veranderingen, met relevante link-/steekproefonzekerheid. Geen extra hoofdgrafiek of automatisch causale DiD.
- IEA 'Intermediate International Benchmark' 475 en PISA niveau 2 zijn geen gelijkwaardige vaardigheidsschalen; maak de instrumentdrempel zichtbaar.
- School×klas voor IEA en school×programma voor PISA directe leeromgeving; whole-school afzonderlijk; eigen leerling altijd uit peernoemer.
- Trendvergelijkbare ESCS (Cobreros 13-item) en oorspronkelijke wave-specifieke ESCS hebben verschillende construct-ID's. Niet stapelen of impliciet vervangen.
- Reeksen blijven in vaste vergelijkingspanels, gelijk gewogen; focusland niet in eigen comparator. 42 dashboardlanden blijven scope; 19 buitenlandse referentielanden zijn productieprioriteit, niet volledige scope.

## Opslagbesluit (HARD REQUIREMENT)
De gebruiker wil geen nieuwe onderzoeksbestanden of RStudio-uitvoer onder Downloads/C:, geen handmatige ZIP-uploads, en GitHub/Google als primaire kanalen. **STOP nieuwe lokale productieruns** zolang code een C:-output kiest. Bestaande runner schrijft naar C: en Google Drive sync publiceert slechts de allowlist (laatste check: quotarapport). Een Google Drive-map is geen R-uitvoermachine. Vereist: Google Cloud R-runtime + private persistente data- en checkpointopslag (capaciteit en bronrechten toetsen), GitHub voor code/CI, Google Drive voor compacte rapporten met automatische verificatie. Eenmalige read-only migratie vanaf bestaande locatie kan nodig zijn; geen verwijderingen zonder bronrechten, 2 onafhankelijke restaurabele kopieën, SHA- en hersteltests en expliciete toestemming.

## 23 figuurtypen — literatuurkruisverwijzing

| Nr | Figuur | Besluit | Literatuur | Bestaande overlap | Relevante afwijking |
|---|---|---|---|---|---|
| 1 | Gemiddelde score | BEHOUDEN | L01 L02 L03 L04 | OECD/IEA en Spit tonen trends al | Vaste transparante panels, 2 leeftijden × 3 domeinen, 42 navigeerbare stelsels |
| 2 | Onder basisniveau | BEHOUDEN | L01 L02 L03 L20 | OECD/IEA rapporteren proficiency | Consistente geactualiseerde vergelijking per instrument en voor 42 stelsels |
| 3 | Op/boven basisniveau | VERVALT ALS FIGUUR | L01 L02 L03 | Complement van figuur 2 | Geen extra informatie en geen nieuwe estimator |
| 4 | Hoog vaardigheidsniveau | BEHOUDEN / SECUNDAIR | L01 L02 L03 | OECD/IEA publiceren top performers | Aanvulling naast laagprestaties om verschuivingen aan beide uiteinden zichtbaar te houden |
| 5 | Internationale rangpositie | AFGELEID / SECUNDAIR | L01 L04 L21 | CPB en OECD rangschikken al | Stabiele set en exacte rangnoemer i.p.v. wisselende deelnemers |
| 6 | Onderkant scoreverdeling P10 | BEHOUDEN | L01 L02 L03 L22 | P10 al veel gepubliceerd | Identieke recent vs historische tijdreeksregels en vakken |
| 7 | Mediaan P50 | BEHOUDEN | L01 L02 L03 | Midden van verdeling standaard | Symmetrische presentatie samen met P10 en P90 |
| 8 | Bovenkant P90 | BEHOUDEN | L01 L02 L03 | P90 standaard OECD/IEA | Analyse van top van volledige verdeling naast hoog-proficiency percentage |
| 9 | Spreiding P90−P10 | AFGELEID | L01 L08 L22 | Internationale spreidingsliteratuur bestaat | Vergelijkbare spreiding door waves en domeinen zonder scoreschalen te mixen |
| 10 | Scorelevels SES Q1/Q4 | BEHOUDEN | L05 L06 L07 L08 L09 | SES-groepsgemiddelden algemeen bekend | PISA 2015–2025 aparte harmoniseerde 13-item-SES en originele ESCS; IEA boekenproxy |
| 11 | SES-scorekloof Q4−Q1 | AFGELEID, FIGUUR BEHOUDEN | L05 L06 L07 L08 L09 | SES-gaptrend zeer uitvoerig onderzocht | Koppeling levels→gap, dezelfde valide constructie en landenpanels |
| 12 | Onder basisniveau naar SES | VERVANGT OUD FIGUUR 12 | L01 L05 L07 L09 | OECD 2022 laat low performers naar SES al zien | Cross-wave harmonisatie en combinatie met levels en peerexposure |
| 13 | Hoog niveau naar SES | VERVALT ALS STANDAARDFIGUUR; OPTIONEEL | L01 L07 L09 | OECD publiceert top performers naar SES | Nuttige robustness voor bovenkant, niet duplicaat van figuur 12 |
| 14 | Gemiddelde score naar geslacht | BEHOUDEN | L01 L05 L14 | OECD en Scheeren/Bol beschrijven al genderverschillen | Uniforme trends binnen drie vakken/twee leeftijden |
| 15 | Meisjes−jongens scoreverschil | AFGELEID, FIGUUR BEHOUDEN | L01 L14 | Gendergap bekende maat | Niveaus + contrast, vak-/agevergelijkingen zonder schaalmix |
| 16 | Score naar taalgebruik thuis | BEHOUDEN WAAR MEETBAAR | L02 L03 L01 L20 | OECD/IEA taalachtergrondtabellen bestaan | Onderscheid tussen frequentie van toetstaal en echte taalidentiteit |
| 17 | Taalcontrasten | AFGELEID, VOORWAARDELIJK | L01 L02 L03 | Veel rapporten tonen taalverschil | Harmonisatie beperkt; niet vergelijken bij veranderde categorieën |
| 18 | Score naar migratiegeneratie | BEHOUDEN | L13 L05 L01 | Alieva combineert drie assessments voor migratiegap | Per categorie niveaus/wave; geen cohortcausaliteit |
| 19 | Migratiegap t.o.v. zonder | AFGELEID, FIGUUR BEHOUDEN | L13 L23 | Alieva bestudeert migratiecross-age met ranks | Hier scores binnen instrument/wave, cohortbrug aanvullend |
| 20 | SES van directe peers | BEHOUDEN; 2 RICHTINGEN | L15 L17 L18 L19 L20 | Segregatie/exposure is bekende onderzoekslijn | School×klas of school×programma in plaats van uitsluitend school-level segregation; trends en twee richtingen |
| 21 | Taal van directe peers | BEHOUDEN, STRIKTE GATE | L17 L18 L23 | Verwant aan segregatie- en migratiestudies | Taalspecifieke peerexposure op directe leeromgeving; andere constructie dan etniciteit |
| 22 | Migratieachtergrond van peers | BEHOUDEN | L13 L17 L18 L23 | Tracking/migrant school segregation al onderzocht | Directe peerexposure in zelfde leeromgeving, niet causale tracking-effecten |
| 23 | Prestaties van peers | BASIS HOOFDMAAT + HOOG ROBUUSTHEID | L16 L17 L21 L12 | OECD academic inclusion; Salchegger/Hirczy verschillen tussen/ binnen scholen | Leerlingconditionele blootstelling directe leeromgeving en over tijd i.p.v. uitsluitend tussen-school variantie |

## Aanvullende figuren/validaties

| ID | Onderwerp | Besluit | Literatuur | Meerwaarde |
|---|---|---|---|---|
| X01 | Trendverschil | BEHOUDEN ALS INFERENTIE NIET EXTRA STANDAARDPLOT | L01 L09 L22 | Boven gewone lijnen: expliciete hypothesetoets, link uncertainty, covariantie |
| X02 | Academische schoolsorting | VERPLICHTE WETENSCHAPPELIJKE ANALYSE | L12 L15 L16 L21 | OECD benchmark of between-school variance, school ≠ school×programma |
| X03 | Sociale schoolsorting | VERPLICHTE WETENSCHAPPELIJKE ANALYSE | L15 L17 L20 L21 | H en SES-variance niet dezelfde grootheid; geen causale trackingclaim |
| X04 | Absolute versus relatieve SES | VOORWAARDELIJK RESEARCH | L01 L09 L21 | Nieuw referentiepunt, nadrukkelijk geen equivalent van nationale Q1/Q4 |
| X05 | Cross-age/pseudocohort | HOOFDONDERZOEK WAAR VALIDE | L10 L11 L12 L13 L14 | Geen PIRLS min PISA scorepunten en geen dezelfde leerlingen claimen |
| X06 | SES-dekking | VERPLICHTE TABEL, GEEN GRAFIEK | L09 L20 | Slide 21 reeds tabel; oorzaken missingness als interpretatiegate |
| X07 | Surveyrepresentativiteit | VERPLICHTE QUALITY-GATE | L01 L02 L03 L22 | Niet als los populair verhaal maar zichtbaar bij relevante figuren |
| X08 | SES×gender interactie | OPTIONELE VERDIEPING | L01 L05 L14 | Voorwaardelijk; geen dubbel tellen van hoofdeffecten |
| X09 | Institutionele context/tracking | VERKLAREND, NIET ZONDER DESIGN CAUSAAL | L10 L11 L12 L15 L16 | Onderscheid descriptieve schoolpatronen van eerder quasi-experimenteel onderzoek |

## Referentielijst en broncontrole

- **L01**: OECD (2026). *PISA 2025 Results (Volume I): Future-Ready Students*. OECD PISA 2025. https://www.oecd.org/en/publications/pisa-2025-results-volume-i_73451bc5-en.html — WEBSITE GECONTROLEERD.
- **L02**: Mullis, von Davier, Foy, Fishbein, Reynolds & Wry (2023). *PIRLS 2021 International Results in Reading*. IEA/Boston College. https://www.iea.nl/publications/study-reports/international-reports-iea-studies/pirls-2021-international-results — WEBSITE GECONTROLEERD.
- **L03**: von Davier et al. (2024). *TIMSS 2023 International Results in Mathematics and Science*. IEA/Boston College. https://www.iea.nl/publications/timss-2023-international-report — WEBSITE GECONTROLEERD.
- **L04**: Spit (2025). *Dalende leerprestaties aanleiding tot aanpassing onderwijscurriculum*. ESB 110(4848), 342–344. https://esb.nu/dalende-leerprestaties-aanleiding-tot-aanpassing-onderwijscurriculum/ — WEBSITE GECONTROLEERD.
- **L05**: Claes, Golsteyn, de Leeuw & de Wolf (2026). *Primary School Skill Development: From First to Sixth Grade*. Journal of Human Capital 20(2):261–286. https://doi.org/10.1086/740863 — WEBSITE GECONTROLEERD.
- **L06**: Passaretta, Skopek & van Huizen (2022). *Is Social Inequality in School-Age Achievement Generated before or during Schooling? A European Perspective*. European Sociological Review. https://doi.org/10.1093/esr/jcac005 — WEBSITE GECONTROLEERD.
- **L07**: Broer, Bai & Fonseca (2019). *Socioeconomic Inequality and Educational Outcomes: Evidence from Twenty Years of TIMSS*. IEA Research for Education 5, Springer. https://doi.org/10.1007/978-3-030-11991-1 — WEBSITE GECONTROLEERD.
- **L08**: Chmielewski (2019). *The Global Increase in the Socioeconomic Achievement Gap, 1964 to 2015*. American Sociological Review 84(3):517–544. https://doi.org/10.1177/0003122419847165 — WEBSITE GECONTROLEERD.
- **L09**: Cobreros, Colomer, Correig-Fraga, Gortazar & Sayol (2026). *Explaining the Learning Decline in PISA 2025 by Socioeconomic Quartiles through Methodological Changes*. EsadeEcPol working paper. https://www.esade.edu/ecpol/en/publications/explaining-the-learning-decline-in-pisa-2025-by-socioeconomic-quartiles-through-methodological-changes/ — WEBSITE + MEEGELEVERDE PDF GECONTROLEERD.
- **L10**: Hanushek & Woessmann (2006). *Does Educational Tracking Affect Performance and Inequality? Differences-in-Differences Evidence Across Countries*. Economic Journal 116:C63–C76. https://doi.org/10.1111/j.1468-0297.2006.01076.x — WEBSITE GECONTROLEERD.
- **L11**: Contini & Cugnata (2020). *Does Early Tracking Affect Learning Inequalities? Revisiting Difference-in-Differences Modeling Strategies*. Large-scale Assessments in Education 8:14. https://doi.org/10.1186/s40536-020-00094-x — WEBSITE GECONTROLEERD.
- **L12**: Strello, Strietholt, Steinmann & Siepmann (2021). *Early Tracking and Different Types of Inequalities in Achievement: Difference-in-Differences Evidence from 20 Years*. Educational Assessment, Evaluation and Accountability 33:139–167. https://doi.org/10.1007/s11092-020-09346-4 — WEBSITE GECONTROLEERD.
- **L13**: Alieva, Hildebrand & Van Kerm (2024). *The Progression of Achievement Gap between Immigrant and Native-Born Students from Primary to Secondary Education*. Research in Social Stratification and Mobility 92:100961. https://doi.org/10.1016/j.rssm.2024.100961 — WEBSITE GECONTROLEERD.
- **L14**: Scheeren & Bol (2022). *Gender Inequality in Educational Performance over the School Career: The Role of Tracking*. Research in Social Stratification and Mobility 77:100661. https://doi.org/10.1016/j.rssm.2021.100661 — WEBSITE GECONTROLEERD.
- **L15**: Strello, Strietholt & Steinmann et al. (2022). *Does Tracking Increase Segregation? International Evidence on between-School Tracking and Social Segregation*. Research in Social Stratification and Mobility 78:100689. https://doi.org/10.1016/j.rssm.2022.100689 — WEBSITE GECONTROLEERD; VOLLEDIGE AUTEURSLIJST TE VERIFIËREN.
- **L16**: Salchegger & Hirczy (2026). *Does between-school tracking really result in more achievement homogeneous schools? Evidence from 40 countries*. Research in Social Stratification and Mobility 102:101131. https://doi.org/10.1016/j.rssm.2026.101131 — WEBSITE GECONTROLEERD.
- **L17**: Reardon & Firebaugh (2002). *Measures of Multigroup Segregation*. Sociological Methodology 32:33–67. https://doi.org/10.1111/1467-9531.00110 — WEBSITE GECONTROLEERD.
- **L18**: Reardon & Owens (2014). *60 Years After Brown: Trends and Consequences of School Segregation*. Annual Review of Sociology 40:199–218. https://doi.org/10.1146/annurev-soc-071913-043152 — WEBSITE GECONTROLEERD.
- **L19**: Owens, Reardon & Jencks (2016). *Income Segregation Between Schools and School Districts*. American Educational Research Journal 53(4):1159–1197. https://doi.org/10.3102/0002831216652722 — WEBSITE GECONTROLEERD.
- **L20**: Gilleece, Karakolidis & Clerkin (2026). *The Validity of School Socio-Economic Status Measures: TIMSS and PISA vs Administrative Data*. Large-scale Assessments in Education 14:45. https://doi.org/10.1186/s40536-026-00305-x — WEBSITE GECONTROLEERD.
- **L21**: OECD (2023). *PISA 2022 Results (Volume I): Equity in Education*. OECD PISA 2022. https://www.oecd.org/en/publications/pisa-2022-results-volume-i_53f23881-en/full-report/equity-in-education-in-pisa-2022_4008c06e.html — WEBSITE GECONTROLEERD.
- **L22**: OECD (2026). *PISA 2025 Results (Volume I): Technical Notes on Analyses*. OECD technical notes. https://www.oecd.org/en/publications/pisa-2025-results-volume-i_73451bc5-en/full-report/technical-notes-on-analyses-in-this-volume_46a7001c.html — WEBSITE GECONTROLEERD.
- **L23**: Auteurs niet volledig vastgelegd in inventaris (2024). *Does between-school tracking increase school segregation among migrant students?*. Compare 55(6), DOI 10.1080/03057925.2024.2370294. https://doi.org/10.1080/03057925.2024.2370294 — ABSTRACT GECONTROLEERD; AUTEURS TE VERIFIËREN.
- **L24**: Glassow & Jerrim (2022). *Is inequitable teacher sorting on the rise? Cross-national evidence from 20 years of TIMSS*. Large-scale Assessments in Education 10:6. https://doi.org/10.1186/s40536-022-00125-9 — WEBSITE GECONTROLEERD.
- **L25**: Verstraten, Lemmens & Non (2022). *A look at the Dutch position in international student assessments*. CPB report. https://www.cpb.nl/en/a-look-at-the-dutch-position-in-international-student-assessments — OVERGENOMEN UIT LITERATUURMATRIX; BIBLIO DETAILS TE VERIFIËREN.

## Wetenschappelijke grenzen / novelty
De eerdere literatuurinventarisatie bevat al 30 bronnen. Gemiddelde trends, percentielen, proficiency, SES-gaps, twee leeftijdsstadia en tracking zijn niet op zichzelf nieuw. De mogelijk onderscheidende bijdrage is een transparant, volledig reproduceerbaar en actueel multi-domein dashboard met *peer exposure in directe leeromgeving*, groepen in twee richtingen en geldig onzekere trendcontrasten. Dat is een **onderzoeksvermoeden**, geen geverifieerde claim van literatuurnovelty.
De studie van Claes et al. (2026) gebruikt individueel longitudinaal Nederlandse leerlingdata, sterker voor individuele groei dan onze internationale repeated cross-sections. De studie van Alieva et al. (2024) gebruikt een rankbrug over assessments; onze scorepunten mogen niet van PISA en PIRLS worden afgetrokken. Cobreros et al. (2026) is een methodologische bron die we repliceren, niet een eigen ontdekking.

## Proces / volgende stap
1. Leg deze beslissingen in de canonieke productcontracten vast door de juiste 138 historische IDs te taggen, niet te verwijderen. Geef een nieuwe productversie, en actualiseer slides 6, 9, 10 en 20 consistent zonder gebruikerswijzigingen te wissen.
2. Ontwerp eerst een **cloud-runner met nul C:-output** op een remote rekenomgeving. Voorlopig geen `START.R` meer lokaal starten.
3. Koppel statistische bouwstenen per juiste versie/covariantie aan figuren; hergebruik bestaande gevalideerde resultaten; voer alleen ontbrekende wetenschappelijke taken uit.
4. Na de wetenschappelijke release de 21/50 slides, notitie, paper, 42-landendashboard en replicatiepad afleveren. Geen publieke data vóór licentiechecks.

## Drempelbenaming op basis van officiële documentatie (aanvulling)

IEA PIRLS/TIMSS gebruikt officieel *Low* 400, *Intermediate* 475, *High* 550 en *Advanced* 625. De historische projectspecificatie die 475 als 'basisniveau' hanteert, selecteert dus feitelijk **onder de Intermediate International Benchmark**. Dit is niet identiek aan 'onder het Low Benchmark' (<400), evenmin aan PISA onder niveau 2. Besluit 12 oktober: projectgrens 475 niet stil wijzigen; in figuren, dashboard en methode de feitelijke scoregrens en officiële naam expliciet opnemen en de inhoudelijke keuze 400 versus 475 zo nodig als aparte wetenschappelijke vergelijking behandelen. Source L26: https://nces.ed.gov/timss/technotes-2023.asp en https://nces.ed.gov/surveys/pirls/pirls2021/technotes.asp.

**Tweede drempellabelcheck:** IEA *High International Benchmark* is 550 en *Advanced International Benchmark* is 625; het in oudere scripts/decks als 'high proficiency' aangeduide ≥625 moet inhoudelijk als **Advanced/geavanceerd** worden gelabeld, tenzij expliciet een afzonderlijke ≥550 High-variant wordt gedefinieerd. Geen verandering van scores door herlabelen; officiële grens en naam op elke figuur.
