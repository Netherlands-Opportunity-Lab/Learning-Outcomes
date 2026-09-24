# Wetenschappelijke grenzen / Scientific boundaries

Deze dashboardversie gebruikt de exacte aggregate tabellen uit `ANALYSIS_RELEASE_RC1_20260922_v3`. Ze vervangt geen scientific freeze. De zichtbare uitkomsten zijn voorwaardelijk waar de bron dat voorschrijft.

- PISA en PIRLS hebben afzonderlijke schalen. Scores, groepskloven en drempels worden niet tussen instrumenten afgetrokken of als dezelfde latente vaardigheid behandeld.
- De maximale laatste gemeenschappelijke SES-set is N=45, zoals de gebruiker vraagt. N=43 sluit Albanië en de VS uit wegens aanvullende vragenlijst-/kwaliteitsbeperkingen. N=44 blijft alleen een exacte-ID-sensitiviteitsdownload. De oorspronkelijke release-rol van N=43 blijft als provenance behouden; de presentatierol van N=45 is expliciet aangepast.
- Kloofrangen en groepsrangen zijn verschillende statistieken. Kloofrang 1 is de kleinste getekende Q4−Q1-kloof; groepsrang 1 is het hoogste groepsniveau. Beide zijn beschrijvend, zonder ranginterval.
- Groepsrangen komen uit het afzonderlijke addendum `reading_group_rank_addendum_20260924_v1`. De browser berekent geen rangen, gaps, gewichten, panels, standaardfouten of referentiegemiddelden.
- Nationale PISA-ESCS-kwartielen, internationale PISA-ESCS-kwartielen en PIRLS-boeken-thuis-groepen zijn afzonderlijke definities. ESCS is geen huishoudinkomen. Internationale ESCS heeft een expliciete vaste 31-landenreferentie exclusief Nederland, geen officieel OECD-gemiddelde.
- Lange rangtrends behouden het vaste panel: PISA 32; PIRLS MAIN13 / ROBUST16, plus MAIN12 zonder Noorwegen als gevoeligheidsanalyse. Ontbrekende rijen worden niet met nul ingevuld.
- Steekproefintervallen zijn de aangeleverde intervallen. Waar alleen SE beschikbaar is, toont de interface alleen die SE. Geen significantieclaim op basis van intervaloverlap. Sommige verschil-SE’s zijn onafhankelijkheidsproxies en zijn expliciet zo gelabeld.
- PIRLS Nederland 2021: IEA-deelname-eisen niet gehaald; schoolrespons 44% vóór en 79% na vervanging; totale uitsluiting 5,1%. Ook PISA-kwaliteitsannotaties blijven zichtbaar. Science-biasranges worden niet gebruikt om reading- of SES-uitkomsten te corrigeren.
- Schoolsorting is beschrijvend. Leeftijdvergelijkingen zijn herhaalde dwarsdoorsneden, geen individuele trajecten en geen causaal effect van tracking. Sociale sorting op SES-rangen is niet de raw-ESCS/multilevelmaat van OECD.
- Taalblootstelling en migratieachtergrond verschillen. De interface toont uitsluitend `release_main_eligible=true` voor demografische sorting; meertalige systemen mogen geen ongestratificeerde hoofdinterpretatie krijgen.
- Voor wiskunde en science zijn slechts 16 Nederlandse totale gemiddelden als beperkte context beschikbaar: 4 PISA-cellen (2018/2022 × 2 domeinen), 12 TIMSS Grade-4-cellen (2003–2023 × 2 domeinen). Gemiddelde én SE passen binnen afronding bij de externe bron. Dit is geen complete RC2-release; er zijn geen nieuwe SES-resultaten, internationale rangen of schoolvergelijkingen vrijgegeven.
- De bronjaarcontrole van stap 4 heeft PISA 2025 bevestigd. Er vindt geen stille herlabeling naar 2022 plaats.

English: this interface preserves instrument-specific scales and source uncertainty, distinguishes maximal and quality panels, and only selects precomputed aggregate statistics. It introduces no scientific estimates in the browser. Mathematics/science are limited Netherlands-only context; no complete RC2 freeze is claimed. The participation and eligibility restrictions above remain binding in both languages.
