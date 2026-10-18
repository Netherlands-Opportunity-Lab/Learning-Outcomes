# Start hier — actuele besluiten en resterend werk

Bijgewerkt: 18 oktober 2026. Dit is het ingangspunt voor de nieuwe oktoberproductie in `Netherlands-Opportunity-Lab/Learning-Outcomes`, branch `feat/reproducible-storage-and-cleanup-20261010`, PR #5. Het beschrijft besluiten en bewijs; het verleent geen wetenschappelijke vrijgave. De release van 28 september blijft een afzonderlijke historische versie.

## Hervathulp na afgesloten internationale run — 18 oktober 2026

De oude run is afgesloten met **69.437 geregistreerd gevalideerde resultaten,
7.739 onderbouwd niet-berekenbare cellen en 435 resterende doelen**. GitHub-depositie:
`da2ffead1b05af2efdbc9b8adf75d8d549b1ebfd`; de uitvoer bevestigt 69.437 private
Drive-resultaatversies. Het opgeslagen grid is stabiel teruggelezen en telt
dezelfde aantallen. De 435 bestaan uit de 401 eerder op brondata geteste
probleemcellen en 34 Zweedse cellen met een checkpointvergrendeling.

De eerste poging met `RESUME_WITH_FINAL_CHECKS.R` stopte vóór de merge: de
single-branch-clone had geen `origin/codex/problem-blocks-final-checks-20261018`.
De bestaande installatiehulp gebruikt nu `LO_PREPARED_FETCH.R` met expliciete
bron- én doelverwijzingen voor beide branches; de persoonlijke Git-configuratie
en alle resultaten blijven behouden. Hetzelfde RStudio-commando blijft gelden.
De native integratieproeven controleren ook behoud van een tussentijdse
resultaatcommit en veilig herhalen. Zie
`review_20261013/MAINTENANCE_FETCH_REPAIR_20261018.json`. De dashboardbediening en
publieke gegevens veranderen door deze reparatie niet.

De gebruiker heeft de hulp inmiddels succesvol herhaald. Beide schrijverslocks
bewaakten de merge van resultaatcommit `da2ffead` met de geteste reparatie;
`331349ec64cc23ba71c2f7221d52e32b0baaf681` is op GitHub bevestigd. Om **20:45:33
Nederlandse tijd** startte `fixed-audit` voor `all_required` op die commit.
De actieve checkout blijft ongewijzigd. De fetchregressie en opslag-/manifestchecks
zijn op Windows en Linux geslaagd; latere documentatie-/validatoraanvullingen
blijven op de voorbereidingsbranch tot de actieve run is afgelopen.

## Laatste bedieningsbesluit — instellingen definitief, gegevens nog in productie

De laatste telefoonscreenshot en gebruikersopdracht vervangen de eerdere
standaard-uit- en dropdownkeuzes: **uitkomst/leeftijd → uitsplitsing → Weergave →
hoofdland**. Vergelijking en onzekerheidsmarge staan standaard aan. De
onzekerheidsknop en alle voorlopige toelichtingen staan onder de figuur; de losse
tekst “95% · alleen hoofdland” vervalt. Engels gebruikt **Measure**.

De stippellijn van de referentie verbindt opeenvolgende beschikbare meetjaren.
De wisselende landenbasis blijft expliciet per punt en onder de figuur vermeld;
ontbrekende jaren/definitiewijzigingen worden niet overbrugd. Voor rangen blijft
een veranderende rangbasis een lijnonderbreking. Deze definitieve UI-instellingen
maken de nog onvolledige resultaten niet definitief en vervangen de strenge
wetenschappelijke balansregel niet.

Deze bediening staat live als kandidaat `ea0632b132508dff805d`. Alle 408 runtimebestanden zijn op Windows en Linux exact gereconstrueerd; alle 411 gepubliceerde bestanden zijn via HTTPS op SHA256 gecontroleerd. Het pakket bevat 179 bestanden (13.128.299 bytes), inclusief de uitvoeringsinventaris. De 34 landbestanden zijn byte-identiek gebleven. Mobiele NL/EN-bediening, begininstellingen, lijnverbinding, ranguitzondering en eigen landenkeuze zijn daadwerkelijk getest. Zie `review_20261013/DASHBOARD_FINAL_SETTINGS_20261018.json`.

De actuele scriptinventaris staat in `RUN_COMPLETION_INVENTORY_20261018.md`.
Voer de laatste hervathulp pas uit nadat de bestaande R-run klaar of gestopt is;
wijzig geen actieve checkout en start geen tweede schrijver.

## Eerder weergavebesluit — onzekerheid en één tweetalige applicatie

De gebruiker vraagt op 18 oktober een aan/uit-schakelaar voor betrouwbaarheidsintervallen
van het hoofdland en een volledige Engelse versie waarbij alleen teksten veranderen.
De gekozen eenvoudige naam is **Onzekerheidsmarge**, Engels **Uncertainty range**.
De schakelaar staat standaard uit, behoudt de rustige vier-dropdowns-opzet en toont
95%-intervallen (schatting ± 1,96 × gecontroleerde SE) alleen voor hoofdlandreeksen.
Geen interval voor vergelijkingsgemiddelden of rangen; geen extra leerlingberekeningen.
Dit is een weergavekeuze, geen nieuwe scopebeslissing of wetenschappelijke certificering.

Beide talen delen renderer, keuzelogica, stijl en data. Groepsnamen, hulpteksten en
toegankelijkheidslabels zijn vertaald; taalwissel en downloads bewaren de selectie.
Bij de controle bleek dat TR_BELOW/TR_HIGH-fracties ten onrechte onder een procentlabel
werden getoond. De presentatie schaalt uitsluitend die families én hun SE met 100;
SES/peerpercentages blijven onaangetast. Broncellen en hashes veranderen niet.
Herkomst en afleiding staan expliciet in de download. Normale 95%-grenzen worden niet
stilzwijgend afgeknipt op 0–100. De versie staat live als kandidaat `4cdac912f6b0de90c6d6`. Het pakket bevat 174 bestanden (13.113.350 bytes); 408 runtimebestanden zijn op Windows en Linux exact gereconstrueerd, en alle 411 online bestanden zijn op SHA256 gecontroleerd. Beide talen, de mobiele bediening en de echte SVG-download zijn getest. De actieve RStudio-checkout is ongewijzigd. Bewijs: `review_20261013/DASHBOARD_UNCERTAINTY_I18N_20261018.json`.

## Laatste besluit — tijdelijk vergelijken met beschikbare resultaten

Op 18 oktober zegt de gebruiker: **“Doe tijdelijk maar even met wat beschikbaar is, volledigheid en check komt als alle resultaten klaar zijn.”** Dit vervangt uitsluitend voor de tijdelijke website de volledige dekkingsvoorwaarde voor vergelijkingen en rangen. `05_publication/REFERENCE_POLICY.json` legt dit expliciet vast; `--reference-policy` activeert de stand in de bestaande bouwer. De wetenschappelijke R-productie, definitieve balansregel, brongetoetste landen en gekozen figuren veranderen niet.

Een land is tijdelijk selecteerbaar zodra het gecontroleerde punten heeft voor de gekozen figuur. Standaard worden de beschikbare rijke kandidaten geselecteerd, zonder hoofdland. Ieder jaar–groeppunt gebruikt het gelijke gemiddelde van de daadwerkelijk beschikbare geselecteerde landen. Tooltip, tabel en download bewaren de gebruikte en ontbrekende leden; bij veranderende samenstelling onderbreekt de lijn. Rangen gebruiken het hoofdland plus de op dat punt beschikbare geselecteerde landen, met zichtbare noemer en zonder groepsranglijn. Ontbrekende punten blijven open. Bekende verschillen tussen meisjes en meisjes + other worden niet stilzwijgend samengevoegd.

Deze stand heet `AVAILABLE_CASES_PROVISIONAL`, niet een geslaagde balanscontrole. Het bestaande strenge vergelijkingsbewijs blijft bewaard voor de eindcontrole. Na complete resultaten en review wordt zonder tijdelijke beleidsoptie opnieuw gebouwd. Zie [uitvoeringsbewijs](review_20261013/DASHBOARD_PROVISIONAL_20261018.json). Oudere beschrijvingen van blokkades hieronder zijn historische uitvoeringsmomenten.

De tijdelijke versie staat live als kandidaat `05c0b4552abcfaa8f072`. Het pakket bevat 174 bestanden (13.108.350 bytes); alle 408 runtimebestanden zijn op Windows en Linux exact gereconstrueerd. Alle 411 gepubliceerde bestanden zijn via HTTPS op SHA256 gecontroleerd. De mobiele en live landenkiezer zijn getest, inclusief aanpassen en standaard herstellen. De actieve RStudio-checkout bleef schoon en ongewijzigd.

De latere expliciete UI-keuze plaatst de vier dropdowns in deze volgorde: uitkomst en leeftijd → statistiek → uitsplitsing → hoofdland. De vergelijking blijft de vijfde keuze.

## Eerder direct besluit — beschikbare resultaten nu op het dashboard

Op 18 oktober vraagt de gebruiker: **“alles wat we hebben op het dashboard zetten”**, ontbrekende dingen **“even open”** laten en de scripts, README, uitleg en het replicatiepakket afmaken. Dit autoriseert een expliciet gemarkeerde tussenpublicatie met al gecertificeerde dashboardpunten. Het vervangt voor die tussenpublicatie de eerdere eis dat eerst de volledige paper, presentatie en Q01–Q08 gereed zijn. Het is geen wijziging van de gekozen statistieken, productplaatsing, bron-/celvalidatie, privacygrens of balansregel.

`PARTIAL_VERIFIED_RESULTS` is een afzonderlijk geteste publicatiecontrole. Een figuur toont alle gecontroleerde punten; ontbrekende jaar–groepparen worden benoemd, krijgen geen nulwaarde en worden niet met een lijn overbrugd. Appendix- en wetenschappelijke uitbreidingen blijven buiten het dashboard. Referenties en rangen blijven open zolang de exacte onafhankelijke vergelijkbaarheidskoppeling ontbreekt; de code creëert daarvoor geen fictief PASS. De strenge uiteindelijke wetenschappelijke vrijgave blijft bestaan.

De publicatie krijgt bron-/code-/resultaathashes, een deterministisch replicatiepakket, tweetalige uitleg en een reconstructietest van de openbare figuren. Volledige herberekening vanaf een schone computer heeft nog de vastgelegde oorspronkelijke bronbundel nodig en wordt niet als voltooid gecertificeerd. De septemberrelease blijft als archief bereikbaar. Nieuwe publicatie gebeurt vanuit de voorbereidingsbranch, zonder de actieve R-checkout te wijzigen. Zie `review_20261013/DASHBOARD_INTERIM_20261018.json` voor het feitelijke vrijgavebewijs zodra de controles afgerond zijn.

**Runconfiguratie en replicatie:** zie [de actuele uitvoeringshandleiding](REPLICATION_CURRENT.md) en `RUN_CONFIG.example.json`. `LO_RUN_CONFIG` legt keuzes expliciet vast; de selectie verkleint uitsluitend het goedgekeurde grid. Iedere muterende fixed-fase bewaart configuratie, inputmanifest, code-/resultaathashes en R/pakketversies. De compacte database bewaart gewijzigde numerieke resultaatversies eenmaal. Volledige rekenprecisie blijft behouden; presentatie wordt apart afgerond. De hele gekozen wetenschappelijke productie is nog niet gereed: de actuele aantallen staan in het uitvoeringsbewijs hieronder; niet alle gekozen modules en landen zijn al gecertificeerd.


## Landenkeuze hersteld — 18 oktober 2026

De fout uit de telefoonscreenshot kwam doordat iedere referentie nog op een generieke wachtstatus stond. De nieuwe publicatieadapter koppelt 51.301 van de 51.304 punten aan exacte bron-/steekproef-/methodebewijzen. De bestaande R-balanscontrole en een onafhankelijke Python-controle bevestigen alle opties. 2.098 land–figuurvergelijkingen zijn mogelijk, waaronder 128 voor Nederland. De Nederlandse leesfiguur biedt Hongarije, Hongkong, Italië en Nieuw-Zeeland; de rijke standaardselectie is hier alleen Italië. Alle 40 Nederlandse basiscellen en alle figuurjaren en groepen blijven verplicht. Drie oude jongensgemiddelde-koppelingen blijven expliciet open voor vergelijking.

Kandidaat `b4b8af52c36aa1bdf238`; code `6c7f404c99f52935b7ee8b213815f7d75f0b15f2`; pakket: 173 bestanden, 13.103.954 bytes. De 407 runtimebestanden zijn op Windows en Linux byte voor byte gereconstrueerd; alle 410 gepubliceerde bestanden zijn via HTTPS teruggelezen en SHA256-gecontroleerd. De mobiele bediening, aangepaste groepsgemiddelden, rangbasis, zoeken en standaard herstellen zijn getest. Publicatie- en Windows/Linux-status staan in [het uitvoeringsbewijs](review_20261013/DASHBOARD_REFERENCE_REPAIR_20261018.json). De actieve RStudio-checkout is ongewijzigd. [Technische uitleg en herhaling](review_20261013/DASHBOARD_REFERENCE_REPAIR_20261018.md).

## Eerdere tussenpublicatie — 18 oktober 2026

De gecontroleerde snapshot van **09:59:58 UTC** staat nu op [GitHub Pages](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/nl/): **51.304 dashboardpunten, 34 brongetoetste landen en 174 gekozen figuurcontracten**. 2.115 landfiguren zijn volledig, 3.443 gedeeltelijk en 358 hebben nog geen vrijgegeven punten. De 14.191 appendix-/wetenschappelijke productcellen blijven apart volgens de gekozen plaatsing. Een dashboardpunt telt een land/figuur/jaar/reeks, niet noodzakelijk één unieke primitieve schatting.

De 169 bestanden in het pakket (6.735.752 bytes) reconstrueren de publieke runtime en data byte voor byte op Windows en Linux. De 375 daadwerkelijk gepubliceerde bestanden zijn over HTTPS teruggelezen en hebben exact de verwachte SHA256-hashes. Publicatiecommit: `ddb0081fc086287eb9135d2007b3d905a106cd4f`; kandidaat: `624ff991ed5a4bacbfe0`. Het septemberarchief is behouden. Zie [uitvoeringsbewijs](review_20261013/DASHBOARD_INTERIM_20261018.json).

Bij deze eerdere publicatie stonden internationale referenties/rangen nog open wegens de ontbrekende onafhankelijke vergelijkbaarheidskoppeling; de reparatie hierboven vervangt die algemene blokkade. Volledige wetenschappelijke bronreplicatie, papercontroles en decks zijn hiermee niet afgerond. De openbare website is een vastgelegde tussenstand en verandert pas bij een volgende gecontroleerde export/publicatie.

De publicatie is afzonderlijk naar main gebracht; de geteste R-reparaties en deze registers staan op de voorbereidingsbranch. De actieve R-checkout is niet veranderd. Na afloop van de oude run kan de bestaande lokale installatiehulp de gecontroleerde geschiedenis in de ontwikkelbranch/PR #5 opnemen, met behoud van eigen resultaatcommits.

## Probleemblokken en eindcontroles voorbereid — 18 oktober 2026

De lopende internationale productie blijft op haar eigen codecommit. Reparaties staan tijdelijk op `codex/problem-blocks-final-checks-20261018`, vanuit dezelfde ontwikkelbranch. Integreer ze in PR #5 zodra de oude run is beëindigd of onderbroken en beide bestaande schrijverslocks vrij zijn; verander de actieve checkout niet tijdens berekeningen. De lokale `RESUME_WITH_FINAL_CHECKS.R` doet uitsluitend die gecontroleerde Git-integratie en roept daarna de bestaande `RUN_CURRENT_NLD.R`/`START.R` aan. Eventuele inmiddels gemaakte resultaatcommits blijven behouden. Na productie volgt de normale resultaatdepositie. Dit is een eenmalige installatiehulp, geen nieuwe wetenschappelijke runner.

Vijftien vastgelopen bron-/familieblokken zijn op echte brondata onderzocht: **401 open cellen, 304 berekenbaar en 97 met een ontbrekende gevraagde subgroep of noemer**. De 304 schattingen, standaardfouten en steekproefaantallen zijn afzonderlijk met de bestaande onafhankelijke referenties vergeleken. Alle verschillen blijven onder 1e-9; tweede uitvoering: nul nieuwe berekeningen. Dit zijn geïsoleerde reparatieproeven, nog geen nieuwe certificeringen in het actieve mastergrid. Zie [uitvoeringsbewijs](review_20261013/PROBLEM_BLOCK_REPAIR_20261018.json).

De bestaande producent behandelt onbeschikbaarheid nu per exacte cel. Bewijs bevat bron-, code-, taak- en diagnosehashes en de betrokken PV/replicatieposities. Ontbrekende doelen blijven in het grid en de volledige balansvoorwaarden. Een geldige nul blijft een resultaat; een lege noemer wordt geen nul. Bij Polen/PISA/2009 blokkeert een afwezige tweede generatie niet langer de wel geobserveerde groepen. Oude migratiecode eiste ten onrechte alle drie categorieën voor iedere geselecteerde berekening.

De nieuwe `LO_COMPLETION_PREFLIGHT.R` maakt een alleen-lezen, op onveranderde inputhashes gecontroleerd overzicht voor `fixed-finalize`. Hij controleert exacte celidentiteit, dubbele resultaten, eindige waarden/SE/N, bewezen afwezigheden en de bestaande Drive-index. Gewone en lage-peeruitkomsten gebruiken dezelfde afwezigheidsregels. Ook afwezigheidsbewijzen worden door de bestaande externe checkpointfunctie overgebracht en werkelijk teruggelezen/hersteld.

Q01–Q08 worden beoordeeld volgens [het actuele paperbeleid](review_20261013/PAPER_QA_CURRENT.json), met de oude broncriteria zichtbaar als geschiedenis. Oude aantallen 34/36 zijn methodereplicatiecontext, geen nieuwe landenvereiste. Q07 verplicht geen afgewezen officiële PISA-ESCS-analyses; de goedgekeurde IEA Home-SES-appendix blijft controleplichtig. Q06 introduceert geen onzekerheidsinterval voor de internationale groep. Q08 geldt alleen voor noodzakelijke geregistreerde paperclaims. Een PASS vereist bewijsbestanden met gecontroleerde hashes, gekoppeld aan de exacte taken, resultaatversie en dit beleid; een losse statusregel is onvoldoende.

Na veilige integratie gebruikt de gebruiker dezelfde `produce-approved`-opdracht. Die voert nu automatisch `fixed-audit` → `fixed-produce` → `fixed-finalize` → `fixed-status` uit op één vastgezette codecommit. Zij pakt ook eerder vastgelopen blokken op, behoudt bestaande geldige resultaten en voert de gebalanceerde referenties, rangen, dashboardkoppeling en wetenschappelijke/productcontroles uit. Daarna volgen de laatste private checkpoint en GitHub-depositie. Geen nieuwe brede runner, scope-uitbreiding of publieke deploy. Een fout tijdens productie stopt de vervolgfasen; wetenschappelijke aandachtspunten blijven zichtbaar in het eindrapport.

De volledige controle van de bevroren momentopname met **64.362 gecertificeerde cellen** is afgerond in 1.423 seconden. Alle geregistreerde certificaten/bestanden en exacte resultaatvelden zijn gecontroleerd. Er waren in die momentopname nog **5.827 open actieve cellen** en geen afgeronde Q01–Q08-papertoetsen. Dit is bewijs dat de bestaande resultaten de controle doorstaan, geen volledige wetenschappelijke vrijgave.

De onderbreking `REMOTE_CHECKPOINT_INDEX_ATOMIC_REPLACE` bij Zweden betrof Windows-bestandsdeling. `LO_ATOMIC_CHECKPOINT.R` probeert uitsluitend tijdelijke sharing/lock-fouten begrensd opnieuw; de oude index blijft behouden. Ook een vergrendelde `.previous`-kopie is getest. Bij een blijvende blokkade stopt de overdracht veilig en blijft hervatten mogelijk. Op 18 oktober om 08:47 UTC bevatte de actuele Drive-index alle 64.362 lokaal gecertificeerde resultaatversies: nul open overdrachten. De toen opnieuw actieve R-run bleef ongemoeid; integreer alleen onder de bestaande checkout-/masterlocks. Zie [herstel- en testbewijs](review_20261013/CHECKPOINT_RESUME_20261018.json).

**Migratieachtergrond blijft drie gekozen weergaven kennen:** minstens één ouder buiten het toetsland geboren; beide ouders buiten het toetsland geboren; en de eerste/tweede generatie afzonderlijk. De eerste generatie is zelf buiten het toetsland geboren, de tweede daarbinnen; beide vereisen twee buiten het toetsland geboren ouders. Bij de generatie-indeling is de referentie minstens één ouder geboren in het toetsland. De twee generaties samen vallen inhoudelijk onder de beide-oudersdefinitie, maar de feitelijke noemer kan verschillen als de geboorteplaats van het kind ontbreekt. De minstens-één-ouderdefinitie omvat daarnaast gemengde ouderparen. Er is geen afzonderlijke derde-generatiecel: onze geharmoniseerde bronnen bevatten daarvoor geen geverifieerde grootoudergeboorteplaatsen. Dit verduidelijkt de bestaande scope en voegt niets toe. Zie `LO_BACKGROUND_SOURCE.R`, `LO_EXACT_ESTIMATORS.R` en de drie migratiekeuzes in `assets/app-shell.js` van het dashboard.

## Productieonderbreking en herstelpunt — 17 oktober 2026

De internationale run stopte bij een verlopen/ingetrokken Google-aanmelding,
na certificering van 49.992 unieke cellen. De laatst bevestigde private
Drive-index bevat 49.972 daarvan; 20 PRT/TIMSS/2023-cellen zijn lokaal behouden
met opnieuw gecontroleerde certificaathash. Na Google-heraanmelding is de
bestaande externe index bevestigd en zijn de laatste 20 cellen overgebracht,
teruggelezen en volledig hersteld met hashcontrole. Alle 49.992 cellen zijn nu
extern bevestigd. De tweede opslagpoging schreef niets nieuws; het lokale
wetenschappelijke masterbestand bleef byte-identiek en geen schatting is herhaald. Zie [herstelbewijs](review_20261013/DRIVE_INTERRUPTION_20261017.json)
en [herstelprocedure](REPLICATION_CURRENT.md). Dezelfde productieopdracht probeert
de openstaande overdracht vóór nieuwe berekeningen opnieuw. Twaalf afzonderlijke
bron-/steekproef-/schattingsmeldingen blijven geregistreerd; zij zijn niet door
de Drive-fout veroorzaakt en gelden niet als gecertificeerde resultaten.
Onderstaande oudere aantallen blijven historische uitvoeringsmomenten.

## Dashboard: vijf hoofdkeuzes en definitieve huisstijl — 15 oktober 2026

De nieuwste gebruikersopdracht vervangt de losse knoppen/startpagina door één rustige figuurbouwer. Hoofdland, zes uitkomst-leeftijdcombinaties, statistiek, uitsplitsing en internationale vergelijking vormen de vijf keuzes. Zie [uitwerking en koppeling met R-uitvoer](../05_publication/preview_overlay/DASHBOARD_UITWERKING_20261015.md). Alle 174 actieve figuurcontracten zijn bereikbaar. De huisstijl is nu Kansenlab 1.1.0 met originele outline-logo’s en accent #4D52BF. Referenties/rangen gebruiken uitsluitend exact gekoppelde gecertificeerde balansviews; ontbrekende gegevens blijven meldingen. De bestaande fixed-finalize-route bouwt de frontend opnieuw met nieuwe resultaten. Dit is frontendafronding, geen internationale wetenschappelijke vrijgave. Desktop, mobiel, werkelijke SVG/CSV-downloads en de R-koppeling zijn gecontroleerd. Windows/Linux CI is geslaagd; zie [acceptatiebewijs](review_20261013/DASHBOARD_UI_ACCEPTANCE_20261015.json). Het oude dekkingsrapport is bijgewerkt naar de 2.397 gevalideerde Nederlandse cellen en 281 gedocumenteerde afwezigheden.

## Actueel besluit: gepoold geslacht en externe checkpoints — 15 oktober 2026

De gebruiker heeft nu expliciet besloten: **“pool meisjes met other in landen waar meisjes niet apart is.”** Dit vervangt de eerdere open constructkeuze. De exacte bronresolver blijft afzonderlijke meisjes herkennen; een aparte, brongecontroleerde productielaag gebruikt alleen bij ontbrekende afzonderlijke meisjes de officiële categorie `Female / Other`. Resultaten heten zichtbaar **Meisjes + other**, inclusief verschillen en SES-appendix. Hun metric-key en calculation-policy veranderen; bestaande exacte meisjesresultaten kunnen niet als deze nieuwe definitie worden hergebruikt. De code controleert bronlabels, waarnemingen, leerling-ID's en gewichten. Onbekend/non-response blijft ontbrekend; dit is geen imputatie van afzonderlijke meisjes.

De huidige broneditie vereist deze wijziging voor PISA 2025 in AUS, CAN, DEU, DNK, ESP, IRL, NLD en NZL: 24 doelen per land. Andere jaren/landen behouden hun geobserveerde definitie. De Nederlandse echte proef van alle 24 doelen komt overeen met onafhankelijke gewogen PV/replicatieberekeningen; de identieke tweede proef berekent niets opnieuw. Zie `review_20261013/POOLED_GENDER_EXECUTION_EVIDENCE.json`. De beschikbare groepsdefinitie kan over landen/jaren verschillen; toon die definitie bij de figuur en presenteer dit niet als een overal identiek afzonderlijk meisjesconstruct. Alle bestaande balansvoorwaarden blijven gelden.

De productiefase betekent lokale R-berekeningen op de computer van de gebruiker. De scripts roepen geen taalmodel aan. RStudio of Rscript kan dezelfde vastgelegde route zonder doorlopende chatbegeleiding uitvoeren. Codex-gebruik betreft begeleiding, codewerk en gelezen uitvoer; de lokale rekentijd is geen taalmodeltokenverbruik.

`LO_REMOTE_CHECKPOINT.R` bewaart afgesloten gecertificeerde blokken tijdens productie op de bestaande private Drive. Het pakket bevat resultaatwaarden, fingerprints, certificaten en gezamenlijke PV/replicatieaggregaten. De overdracht wordt teruggelezen en alle opgenomen bestanden worden werkelijk hersteld en gehasht. De index wordt pas daarna bijgewerkt; een mislukte overdracht stopt nieuwe productie en blijft hervatbaar zonder herberekening. De volgende run probeert het nog niet extern bevestigde blok opnieuw over te dragen. Canonieke leerlingbestanden en andere binaire bronafhankelijkheden worden alleen met hun bronhash geregistreerd en blijven lokaal beschikbaar/herbouwbaar; dit is geen volledige back-up van alle bronnen. Alleen minimale lokale werk- en hervatbestanden zijn tijdens rekenen nodig. GitHub krijgt de gecertificeerde openbare aggregaten na een begrensde run, zodat de uitvoeringscommit gedurende rekenen vast blijft.

**VS-bronbesluit:** NCES vermeldt dat de ouder-/thuisvragenlijst niet is afgenomen bij [TIMSS 2023](https://nces.ed.gov/timss/technotes-2023.asp), [PIRLS 2021](https://nces.ed.gov/surveys/pirls/pirls2021/technotes.asp) en [PISA 2025](https://nces.ed.gov/surveys/pisa/pisa2025/technical-notes/index.asp). Een national add-on of restricted-use bestand kan niet-verzamelde antwoorden niet herstellen. Officiële Home-SES blijft voor die IEA-cellen expliciet onbeschikbaar. Studentantwoorden en de gekozen boeken-SES zijn afzonderlijke bronnen/constructen. Bij PISA 2025 beschrijft NCES bovendien meer dan 40% niet-afgenomen studentvragenlijsten; die dekking blijft een afzonderlijke kwaliteitsvoorwaarde voor Amerikaanse subgroepen.

Onderstaande aantallen en opmerkingen over een nog ontbrekend poolingbesluit zijn historische uitvoeringsmomenten. Ze zijn geen actuele afwijzing van dit nieuwe gebruikersbesluit. Volledige internationale productie en productvrijgave blijven afzonderlijk te bewijzen.

## Leesvolgorde en gezag

Het [volledige dekkingsrapport van 15 oktober](review_20261013/grid_coverage/README.md) geeft alle gekozen jaren, populaties, domeinen, statistieken, splits en kandidaatlanden, met filterbare exacte cellen en redenen voor afwezigheid. Het huidige Nederlandse grid telt 2.678 doelen: 2.373 gecontroleerd, 281 gedocumenteerd onbeschikbaar en 24 open wegens het afzonderlijke PISA-2025-meisjesveld. Alle doelen hebben productkoppelingen. Dit is geen compleet internationaal dashboard: buitenlandse reeksen en de uiteindelijke gebalanceerde referentie-/rangafleidingen ontbreken nog. De aangepaste gridcode bewaart leeftijd en doelpopulatie ook bij hergebruik van oudere certificaten. De genderresolver kiest expliciet ST004D01T (1=Female; 2=Male), controleert de echte waarden en tegenstrijdige velden, en gebruikt nooit Female / Other als meisjes. De werkelijke Nederlandse bron heeft in ST004D01T uitsluitend code 99; de nieuwe code verandert dat bronfeit niet.

Aanvulling 15 oktober: RStudio haalt scripts vóór een gewone `produce-approved`-run uit GitHub en deponeert daarna gecertificeerde nationale resultaatwaarden, instellingen, berekenreceipts en fingerprints in `04_results/review/<scope>/` op dezelfde ontwikkelbranch. De uitvoeringscommit blijft binnen de run vast. Zie [GitHub-resultaatbeheer, gendercontrole en gemeten rekentijd](review_20261013/GITHUB_RESULTS_AND_RUNTIME_20261015.md). Dit is een onderzoeksversie met open doelen zichtbaar, geen dashboarddeploy of definitieve productvrijgave.

De volledige route is daadwerkelijk uitgevoerd: 422,23 seconden inclusief één gecontroleerde private Drive-overdracht. De tweede identieke GitHub-depositie maakte geen nieuwe commit. Alle openbare resultaatmanifesten en 24 historische R-codekopieën zijn vanuit Git-blobs geverifieerd; Windows/Linux-checks zijn groen. Zie [het uitvoerings- en depositiebewijs](review_20261013/GITHUB_RESULT_DEPOSIT_PROOF_20261015.json). De resultaat-CSV telt 2.625.730 bytes; het openbare resultaat-/herkomstpakket 4.300.920 bytes.

1. De laatste rechtstreekse gebruikersinstructies, daarna dit besluitregister.
2. [De vier resterende opdrachten](VIER_RESTERENDE_OPDRACHTEN_20261014.md) en [acceptatie/voortgang](ACCEPTATIE_EN_VOORTGANG.csv).
3. [Afzonderlijke inhoudelijke besluiten A01–A17](SCOPE_APPROVALS.csv), met toelichting in [de scopecorrectie](review_20261013/USER_SCOPE_AMENDMENT_20261014.md).
4. [De balansregel](review_20261013/BALANCED_REFERENCE_RULE_20261014.md), het [machinebeleid](review_20261013/BALANCED_REFERENCE_POLICY.json) en het [Nederlandse jaaranker](review_20261013/NLD_POLICY_CORE_YEAR_ANCHOR.csv).
5. [De afgeronde bewijsaudit](review_20261013/AUDIT_CLOSURE_20261013.md), [productvereisten](review_20261013/PRODUCT_REQUIREMENTS.json), [productafhankelijkheden](review_20261013/PRODUCT_GRID_DEPENDENCIES.csv) en [resultaatbewijs](review_20261013/EVIDENCE_AUDIT_SUMMARY.json).
6. [Het bestaande protocol met drie R-fasen](FROZEN_3_STAGE_PRODUCTION_PLAN_20261013.md), daarna de betrokken code en tests.

Oudere plannen, chats, slides en tabellen zijn bronmateriaal. Hun opdrachten, aantallen en assistentvoorstellen gelden niet automatisch als actuele gebruikersbesluiten. Bij tegenspraak wint de meest recente expliciete menselijke keuze. Bewaar de oorspronkelijke bron; corrigeer actieve code en afgeleide instructies. Iedere nieuwe keuze krijgt datum, herkomst, getroffen besluit-/product-/cel-ID's en een Git-commit. Een technisch voorstel blijft als voorstel herkenbaar. Een inhoudelijk akkoord en een wetenschappelijk bewijs zijn afzonderlijke voorwaarden.

## Definitieve gebruikerskeuzes

| ID | Vastgelegde keuze | Gevolg / bron |
|---|---|---|
| D01 | Werk hoofdzakelijk in GitHub; echte leerlingberekeningen lokaal in Windows RStudio. | Eén `START.R`/`RUN.R`, annotaties en reproduceerbare configuratie; synthetische CI op Windows en Linux. Gebruikersopdracht en bestaand uitvoeringsprotocol. |
| D02 | Lever dashboard, resultaatproducerende scripts, definitief beleidsdeck en paper over Nederland. Een langer wetenschappelijk deck is optioneel. | Het langere product autoriseert geen extra analyses. Geen extra publicatieproducten verplicht stellen. |
| D03 | Het bewerkte deck met 20261001 en 21 slides is de inhoudelijke presentatiebasis. | SHA256 `cea8dc8a42c3e63e435c16ef13ea6cc1b634f5ca4d95af8c29dafba7397631ac`; behouden met latere gebruikerscorrecties. 48 native grafieken zijn broninhoud, geen gecertificeerde resultaten. |
| D04 | Minimaal drie onderscheiden geldige meetgolven in ieder van zes leeftijd-domeincombinaties voor dashboardtoelating. | Rond 10: PIRLS lezen, TIMSS wiskunde/natuurwetenschappen; rond 15: PISA alle drie. Geen jaarlijkse eis, geen som van drie over domeinen, geen uitzondering voor rijke kandidaten. |
| D05 | De PPP20 is een kandidatenpool. | Gepinde OESO-lidmaatschapsafbakening en PPP-2024-inkomen strikt boven Tsjechië; niet vervangen door een Wereldbank-inkomenscategorie. Geen vast eindtotaal 19/20/42/50 afdwingen. |
| D06 | Nederlandse standaardreferentie moet de Nederlandse leeftijden, uitkomsten en jaren uit het 21-slide-deck volledig dekken. | Het jaaranker heeft 40 basiscombinaties. Het bevat ook 2025; een deckpunt bewijst geen vrijgegeven PISA-bron. Een ongeldige broncel blijft een gemeld bronprobleem; verwijder haar niet stilzwijgend om landen te laten passen. |
| D07 | Bij ieder gekozen hoofdland mogen alleen ten minste even volledig geobserveerde landen in de referentie. | Volledige vereiste uitkomsten, leeftijden en jaren; extra jaren bij referentielanden mogen. Niet beperken tot de oude COMMON42 bij het zoeken naar kandidaten. |
| D08 | Dezelfde balans geldt voor geslacht, SES, taal, migratie en klas-/schoolcompositie. | Eén vast panel voor alle samen vergeleken groepen, golven en peer-eenheden. Ontbrekende jongensdata sluit het land ook uit de gekoppelde meisjesvergelijking. Geen categorieën, populaties of omgevingen stilzwijgend vervangen. |
| D09 | De gebruiker stelt de referentiegroep samen met vinkjes en kan de standaard herstellen. | Standaard: passende rijke kandidaten minus hoofdland. Vinkjes bepalen echt het groepsgemiddelde. Ongeschiktheid, lege selectie en gewijzigde dekking zichtbaar; geen automatische wisselende leden of kortere periode. Exports en deelbare toestand bewaren alle keuzes en resultaatversie. |
| D10 | Landen tellen gelijk mee; het hoofdland zit nooit in zijn eigen referentie. | Geen SE/CI/foutbalk op de samengestelde referentielijn. Geldige nationale onzekerheid blijft behouden. Een toets tegen de referentie vraagt eigen correcte contrastvariantie. |
| D11 | Drie productiemodi blijven beschikbaar. | `nld_only`; `nld_plus_19` als bestaande naam voor NL + rijke kandidaten; `all_required` voor die pool plus overige toegelaten landen. De naam garandeert geen 19 toegelaten referentielanden. NL-only rekent geen buitenlandse cellen; buitenlandse lijnen kunnen uitsluitend uit reeds gecertificeerde aggregaten komen. |
| D12 | Schrap apart figuurtype 3; vervang 12 en 13 door onder basisniveau naar SES. | Letterlijke teruggevonden gebruikerskeuze van 12 oktober. Geen afzonderlijke complementfiguur, geen hoog-SES-prestaties als standaard terugzetten. |
| D13 | SES- en genderkloven afleiden uit de gekozen groepsniveaus. | Figuurtypen 11 uit 10 en 15 uit 14; correcte gezamenlijke replicaties/covariantie vereist. Twee marginale SE's zijn niet automatisch genoeg. |
| D14 | Substantiële aanvullingen uit het wetenschappelijke deck afzonderlijk laten beoordelen. | De afzonderlijke actuele statussen staan in SCOPE_APPROVALS.csv; A01–A17 zijn afzonderlijk beantwoord; A09 betreft landenrangen relatief tot de gekozen internationale vergelijkingsgroep; die groep wordt niet geplot. Stilte, een aanbeveling, een technisch werkende estimator of de wens voor een langer deck is geen akkoord. |
| D15 | Gebruik zowel het resultaatgrid als het vormgevingsgrid. | Iedere getoonde waarde en paperclaim herleidbaar tot exact resultaat, afleiding en bron. Consistente compositie volgens de stijlgids; bestaande 12-kolomsindeling en 16:9-slides toepassen waar voorgeschreven. |
| D16 | Laatste Kansenlab-huisstijl v05 en logo-assets v06 zijn leidend. | Document `2026-10-12_Kansenlab_huisstijl_v05_definitief.docx`, registry/CSS v05, logo-master/rebuild v06 en typografievariant B. Oudere PISA/PIRLS-figuurregels blijven aanvullend waar verenigbaar. |
| D17 | Bronnen mogen op C:, tussenresultaten op private Google Drive, definitieve vrijgegeven resultaten op GitHub. | Kleine codecheckout en noodzakelijke tijdelijke bestanden lokaal; geen groeiende kopieën van volledige historische caches. Overdracht vereist echte byte-/hashcontrole en herstelbaarheid. |
| D18 | Zeer goed geannoteerd, repliceerbaar en FAIR, met AER/AEA als kwaliteitsambitie. | Complete code en methoden, metadata, versies, licenties/toegangsroute, gecontroleerde heruitvoering en duurzame release. FAIR betekent niet dat beperkte leerlingdata openbaar moeten. Claim geen tijdschriftcertificering zonder externe beoordeling. |
| D19 | Kritisch beoordelen wat gebruiker én assistent voorstellen; gevonden problemen direct oplossen. | Repareer binnen de goedgekeurde scope, test de foutconditie en leg bewijs vast. Alleen ontbrekend inhoudelijk besluit of externe bron/toegang kan afhankelijk werk laten wachten; werk aan onafhankelijke onderdelen gaat door. |

## Bestaande methodische afspraken en kwaliteitsvoorwaarden

Deze eisen bewaken de gekozen analyses; ze autoriseren geen nieuwe onderzoeksfamilies.

- **M01 — exacte identiteit:** survey, land/stelsel, golf, leeftijd/doelpopulatie, steekproef, domein, uitkomst, groep, SES/peerconstruct, drempel, eenheid, inputeditie en methode/variantie-editie horen bij de cel. Bewaar oorspronkelijke metric-key én nieuwe exacte identiteit. Hashes van bestanden zijn geen methodevalidatie.
- **M02 — onzekerheid:** surveygewichten, alle vereiste plausible values, juiste replicatie/factoren en eventuele linking-onzekerheid; N, missings en noemers per resultaat. Gezamenlijke variantie voor afhankelijke verschillen. Geen geschatte SE/N fabriceren of nul als ontbrekend gebruiken.
- **M03 — constructen:** officiële ESCS, Cobreros-harmonisatie en boekenkwartielen afzonderlijk; vooraf vastgelegde kwartiel-/missingregels. PISA onder niveau 2 verschilt van IEA onder intermediate 475. Hoge IEA-drempels 550/625 niet met elkaar verwisselen. Broneditie en officiële definitie per uitkomst verifiëren.
- **M04 — peers:** leerling zelf uit peergroep; juiste gewogen noemer en doelgroep per PV/replicatie. Directe klas/school×programma en hele school niet verwisselen. Beide peeruitkomsten zijn gekozen (A01 en A03): onder basisniveau én hoog/gevorderd, met afzonderlijke drempels en exacte cellen. Een compositiemaat is geen causaal peereffect.
- **M05 — vergelijkbaarheid:** geen regio/land- of leeftijdsubstituties; taalgebruikfrequentie is geen taalidentiteit, migratiegeneraties zijn geen willekeurig samenvoegbare groepen. Toetsmodus, uitsluitingen, respons en doelpopulatie bij trendinterpretatie vermelden. Geen ruwe punten tussen PISA en IEA aftrekken; geen individueel cohortverloop uit twee dwarsdoorsneden concluderen.
- **M06 — Q01–Q08:** dekking, steekproefkwaliteit, exacte auteur-replicaties met eigen 34-/36-panels, projectspecifieke uitbreiding, referentie/N, officiële-SES-robuustheid en correcte onzekerheid bij behouden trendclaims afzonderlijk sluiten. Auteurpanels zijn geen dashboardlandenlijst. Nieuwe systematische trendtoetsen vallen onder A17.
- **M07 — scopebeperking:** rangveranderingen, causale tracking-/institutiemodellen, leraren-/middelenverklaringen, prestatie-op-sorteringregressies en losse causale landenassociaties komen niet automatisch terug. Absolute SES, kruisingen, sortering en Theil-H alleen volgens afzonderlijke A-besluiten. Historische 138 figuurcontracten en 79.448 keys blijven voor herkomst bewaard, niet als verplichte rekenvoorraad.
- **M08 — hergebruik:** kies `REUSE_VERIFIED`, `DERIVE`, `COMPUTE_REQUIRED`, `UNAVAILABLE` of `HOLD` op daadwerkelijk bewijs. Geen resultaat goedkeuren omdat een oud label VALIDATED zegt of de nieuwste bestandsdatum wint. Reconcileer numerieke verschillen voordat ze in producten belanden.

## Huisstijlcontract

Woordmerken: Inter Semibold 600. Grafiektitels/paginakoppen: Oswald Medium 500; lopende tekst/uitleg: Oswald Regular 400; korte labels/hulptekst: Oswald Light 300; geselecteerde filters/tabs en tabelkoppen: Medium 500; tabelcellen: Regular 400. Tekst `#17242D`, achtergrond `#F7F5F0`. Ringkleuren: `#D9833C`, `#EBC45A`, `#82A85B`, `#5EA6A7`, `#4C77A8`, `#6B5A8E`. Ringkleuren zijn niet automatisch de grafiekcategorieën. Gebruik voorgeschreven semantische figuurkleuren, leesbaar contrast en aanvullende lijn-/symboolcodering. Gebruik de geleverde vectorlogo's, juiste woordmerken en licentieerbare fontbestanden; controleer SVG-titels/metadata ook op de juiste productnaam. Geen logo opnieuw tekenen als originele assets beschikbaar zijn. Controleer werkelijk gerenderde slides, paperpagina's en dashboard op overlap, schaal en leesbaarheid.

## Wat al vaststaat, en wat nog niet af is

De kritische bronnenaudit is afgerond. De ZIP is al uitgepakt en gelezen; herhaal dat niet zonder gewijzigde hash. Alle 247 bronvereisten zijn aan figuren/cellen of expliciete aanvullende specificaties gekoppeld. Dat aantal is geen gebruikersgoedkeuring. In de historische 50-kandidatenscope hebben 19.050 cellen een exacte archiefkandidaat, 18.775 een eindige schatting/SE en 11.192 gecontroleerde bronhash/rijpariteit. **Geen daarvan is door deze audit wetenschappelijk vrijgegeven.** De 811 numerieke versieverschillen vragen gerichte reconciliatie; 59.036 niet-gematchte historische keys zijn geen opdracht tot 59.036 nieuwe berekeningen.

De dynamische bronregistry, volledige-focus-balansadapter, exacte dispatcher en export-/publicatiecontroles zijn nu verbonden met de bestaande controller. De dispatcher controleert bron-, methode-, input- en codehashes vóór hergebruik of uitvoering en slaat hervatbare celreceipts op. De tests behandelen gewijzigde invoer, bronidentiteit, extra resultaten, hervatten en een identieke tweede run. Er is geen automatische wetenschappelijke goedkeuring. Het dashboard moet de nieuwe referentie-export nog in de bestaande vinkjesinterface verwerken (opdracht 3).

De actuele Nederlandse `fixed-audit` bevat **2.678 doelcellen**, waarvan **2.373 wetenschappelijk gevalideerd**, **281 met aangetoonde ontbrekende bronvelden/constructen** en **24 nog niet gecertificeerd**. Er staan nul reeds gecertificeerde rekenbatches open; dat betekent niet dat alle inhoudelijke werkzaamheden klaar zijn. De 400 gekozen prestatiepeeruitkomsten zijn gecontroleerd, inclusief alle 240 lage-peercellen. De volledige Nederlandse basisjaaranker van 40 combinaties is met officiële bronbestanden onderbouwd. De controller heeft de gecertificeerde batches uitgevoerd en bij een identieke tweede run zonder herberekening hergebruikt. Nieuwe goedgekeurde uitbreidingen hebben afzonderlijke celcontracten, producentfuncties en een appendix/science-export. Bestaande registerlabels bewijzen geen wetenschappelijke geldigheid. De actuele bewijs- en bestandsmaten staan in `review_20261013/STEP1_EXECUTION_EVIDENCE_20261014.json`.

De besluiten van 14 oktober voegen toe: beide prestatiepeeruitkomsten (A01/A03), hoog/gevorderd naar SES in de appendix (A02), Home-SES in de appendix met consistente definitie en ontbrekende-jarenrapport (A04), SES × geslacht in de appendix (A06), prestatievariantie tussen scholen/vergelijkbare klassen (A11/A12), SES-variantie tussen scholen (A13) en tussen vergelijkbare klassen in de appendix (A14). A05/A07/A08 zijn afgewezen; A10 wordt na de vier opdrachten heroverwogen; A15/A16 zijn uitgesteld. A17 autoriseert alleen noodzakelijke paperclaimtoetsen, geen systematische toetsensuite. A09 is goedgekeurd: rangontwikkeling in het dashboard en een ranglijst uitsluitend in de wetenschappelijke paper. Geen appendixuitbreiding automatisch op het beleidsdeck plaatsen.

Op 15 oktober heeft de gebruiker rechtstreeks opgedragen: **“doe alle landen en alle benodigde resultaten”**. Dit vervangt de eerdere eis van een afzonderlijk akkoord op de concrete landenlijst. Alle landen die aan de bestaande bron-, populatie- en 6×3-regels voldoen zijn nu voor productie geautoriseerd; de rijke pool is nog steeds geen automatische eindlijst. Volledige referentiebalans en alle afzonderlijke A01–A17-besluiten blijven gelden. Zie `COUNTRY_PRODUCTION_APPROVALS.csv`, beleidsrij `ALL_SOURCE_ELIGIBLE`. De PISA-SES-bronvoorkeur is de opgegeven Innovamat-repository/paper; de 34-/36-landen auteurpanels en verschillende codeprotocollen blijven onderscheiden van dashboardlanden.

De actieve bouwlocatie is `05_publication/preview_overlay/`, met `.github/workflows/pages.yml`. De vormgeving uit `04_DASHBOARD_BRON_20261001/03_dashboard/app` is daarin teruggezet op expliciet gebruikersbesluit. Behoud die opzet voor GitHub Pages; een ChatGPT-websiteproduct is hiervoor geen vereiste. Nieuwe producten gebruiken één gevalideerde resultaatversie. Uitbreidingen die niet zijn gekozen verschijnen niet als ontbrekend verplicht resultaat.

## Opslag en opruiming

De acute ruimtebeperking is praktisch verholpen: gerichte verwijdering van herberekenbare projectbestanden en SHA256-gecontroleerde deduplicatie maakten samen **26.008.379.325 fysieke bytes** vrij. Daarvan is op 15 oktober 9.532.709.229 bytes vrijgemaakt door 367 gecontroleerde buitenlandse, herberekenbare PISA-tussencaches te verwijderen. Direct daarna was 20.501.639.168 bytes vrij. Zes grote byte-identieke SAV-kopieën delen nu NTFS-opslag met hun behouden bron; alle oorspronkelijke paden blijven werken. Bronbestanden blijven onveranderlijk. De actuele vrije ruimte en hersteltest staan in het uitvoeringsbewijs; ze worden vóór iedere batch opnieuw gecontroleerd.

**LO05_RESULTATEN** en **PISA_PIRLS_MASTER_PIPELINE** worden niet integraal verwijderd. De laatste toestemming staat gerichte verwijdering van aantoonbaar herberekenbare projecttussenbestanden toe zonder twee externe back-ups of 30 dagen wachttijd. Unieke bronnen, bewijs, codeafhankelijkheden en niet-projectmateriaal blijven behouden. Een groot archief met een PIRLS-cachenaam bevat ook niet-projectmateriaal en is daarom niet verwijderd. Exacte inventarissen, hashes en verwijderreceipts blijven privé.

Gemeten pilots begrenzen pupilomvang, PV/replicatieontwerp en tijdelijk werk voor de gecertificeerde bronfamilies. De controle houdt 2 GiB werkreserve aan; zij is geen harde OS-quota. Een teruggehaald en gecontroleerd Drive-bewijspakket is een herstelbare kopie van dat pakket, geen volledige back-up van alle brondata.

## Afronding en wijzigingsbeheer

Er zijn vier resterende werkopdrachten, maar drie bestaande R-uitvoeringsfasen: opdracht 1 bereidt `fixed-audit` voor en sluit deze af; opdracht 2 gebruikt `fixed-produce`; opdracht 3 gebruikt `fixed-finalize` voor private producten; opdracht 4 verzorgt onafhankelijke replicatie, gecontroleerde release en opslagafsluiting. `fixed-status` blijft alleen-lezen, `fixed-cleanup-plan` is een apart reviewhulpmiddel. Geen vierde wetenschappelijke runner.

Werk [ACCEPTATIE_EN_VOORTGANG.csv](ACCEPTATIE_EN_VOORTGANG.csv) bij met werkelijke bewijslinks en commit/resultaatversies. Voor A-besluiten is [SCOPE_APPROVALS.csv](SCOPE_APPROVALS.csv) de machineleesbare actuele status; de eerdere beslisbladtabel is de gedateerde toelichting. Bij een echt gebruikersbesluit worden code, productregister, scope-overlay, benodigde celcontracten en tests samen aangepast. Een CSV-status alleen maakt een niet-geïmplementeerde uitbreiding niet uitvoerbaar. Voer bij elke opdracht een kritische eindreview uit van juistheid, onnodige complexiteit, bron-/scopeafwijkingen en productkwaliteit. Een groene softwaretest is geen wetenschappelijke vrijgave, een manifest is geen hersteltest, en een plan is geen opgeleverd product.

## Actuele uitvoeringsreview

De controller is op echte Nederlandse PISA-, PIRLS- en TIMSS-bronnen uitgevoerd. Broneditie, populatie, gewichten, alle plausible values, replicatiefactor, schatting, standaardfout en N zijn per gekozen blok onafhankelijk gecontroleerd. Zie het actuele [uitvoeringsbewijs](review_20261013/STEP1_EXECUTION_EVIDENCE_20261014.json), [probleemregister](review_20261013/IMPLEMENTATION_ISSUES.csv) en [uitvoeringshandleiding](REPLICATION_CURRENT.md). De oorspronkelijke negen PISA-2022-cellen blijven als historische eerste ketentoets herkenbaar; zij zijn niet de actuele omvang.

Het Nederlandse kernjaaranker is nu met 40 broncombinaties gedekt: PIRLS lezen 5 golven; TIMSS wiskunde en natuurwetenschappen elk 6; PISA lezen en wiskunde elk 8 en natuurwetenschappen 7. Nederland voldoet daarmee aan 6×3 voor de kernreeksen. Dit certificeert niet automatisch alle groepsuitsplitsingen, referentielanden of trendclaims. Buitenlandse productie is nu geautoriseerd voor alle brongetoetste toegelaten landen; de feitelijke internationale bron- en resultaatcertificering wordt uitgevoerd.

Concrete broncorrecties: PISA-2003-migratiegeneraties zijn tegen geboortelanden gecontroleerd; PISA-2012-programmacodes behouden hun voorloopnullen; onbekende programma's vormen geen fictieve klas. PISA 2025 is officieel beschikbaar en lokaal op de ruwe public-use bron gecontroleerd. De eerdere algemene uitsluiting van Nederlandse geslachtsuitkomsten is gecorrigeerd: ST004D01T bevat voor alle 6.636 leerlingen code 99, maar MALE bevat 3.397 jongens. Hun drie domeingemiddelden en SE zijn onafhankelijk berekend en komen overeen met de officiële tabellen. MALE=0 omvat Female / Other en mag niet als meisjes worden gelabeld; de gepubliceerde meisjescijfers wijken aantoonbaar af. De officiële recode verwijst naar ST004D01D, dat in deze lokale broneditie ontbreekt. Daarom blijven 24 exact meisje-afhankelijke doelen een open bronmappingvraag; 18 jongens-SES-doelen zijn met de gekozen SES-kalibratie gecertificeerd. Zie het actuele bronregister. PIRLS 2021 behoudt de officiële vertraagd afgenomen vierdejaarscohort, inclusief de in het najaar geregistreerde leerlingen. Officiële Home-SES, boekenkwartielen en Cobreros-SES blijven gescheiden constructen.

De keten gebruikt één audit → produce → finalize-protocol. Exacte tweede runs schrijven geen dubbele berekeningen. Een echte gedeeltelijk mislukte run is hervat met behoud van 128 voltooide uitkomsten; alleen 24 ontbrekende taaluitkomsten zijn daarna berekend en getoetst. Resultaat en uitvoeringsreceipt worden atomair opgeslagen. Op 15 oktober is bovendien een echt R-proces abrupt beëindigd tijdens een berekening en tijdens een nog niet gecommitteerde transactie. Beide herstelgevallen slagen op Windows en Linux: de eerste cel blijft behouden, alleen het onderbroken blok wordt opnieuw berekend, en een derde identieke run rekent niets nieuws. Proceslocks worden door het besturingssysteem vrijgegeven; configuratie en codeherkomst worden vóór de eerste berekening vastgelegd. Het vastgelegde R 4.6.1-milieu met 41 pakketten is op schone Windows- en Linux-runners hersteld en getest.

Het dashboard behoudt de expliciet gekozen vormgeving uit het archief van 1 oktober, met originele v06-vectorlogo's, lokaal ingebedde Inter/Oswald-fonts en v05-kleuren. [De vormgevingsbasis](../05_publication/preview_overlay/DESIGN_BASELINE.md) blijft leidend. De nieuwe volledige wetenschappelijke resultaatrelease, referentiebediening, paper en decks zijn nog geen afgeronde producten.


De resterende bron- en methodecontroles zijn op 15 oktober uitgevoerd: 667 nieuwe schattingen onafhankelijk gecontroleerd, 80 nationale baselines uit exacte gecertificeerde oudercellen afgeleid en 130 extra bronafwezigheden bewezen. De enige 24 nog open Nederlandse primitieve doelen vereisen het afzonderlijke PISA-2025-meisjesveld. De volledige afsluiting, identieke tweede runs, export en actuele Drive-hersteltest staan in [het afsluitbewijs](review_20261013/REMAINING_CHECKS_CLOSURE_20261015.json). De 281 onbeschikbare doelen blijven zichtbaar in het grid. Dit sluit de losse paper-, landen- en productreleasevoorwaarden niet af.

## Definitief productbesluit A09 — 14 oktober 2026

De gebruiker kiest rangontwikkeling van het hoofdland en eventueel één ander land als tijdreeks in het dashboard. De gekozen internationale vergelijkingsgroep bepaalt de rang van Nederland (of het gekozen hoofdland), maar wordt zelf niet geplot. Dit is dezelfde referentiegroep als bij de gekozen vergelijking, geen afzonderlijk te kiezen rangpanel. Het hoofdland hoeft niet aan zijn eigen referentiegroep te worden toegevoegd. De dashboardbouwer draait steeds om één figuur met jaren op de x-as, voor de gekozen uitkomst, leeftijd/doelpopulatie, uitsplitsing en vergelijking. Een ranglijst van landen komt uitsluitend in de wetenschappelijke paper. De vormgeving uit het archief van 1 oktober blijft leidend. De vier vraagkaarten zijn ingangen naar die ene figuur, geen opdracht voor vier gelijktijdige grafieken.

A09 is hiermee inhoudelijk goedgekeurd; de oude vaste 13-/32-/45-landenpanels zijn niet opnieuw gekozen. Rangen zijn afleidingen van exact gecertificeerde uitkomsten (waaronder SES-kloven), met expliciete constante landenbasis en herleidbare oudercellen. De trace registreert kandidaat-oudercellen; de uiteindelijke selectie volgt de gekozen uitkomst en vergelijking. Dit voegt geen aparte leerlingberekeningen toe en geeft geen gegevens vrij. Een rangnummer is niet automatisch een statistisch significant verschil; score-SE's worden geen rang-SE's.

Nadere gebruikersbesluiten: geen groepsrang; wel eventueel één ander land naast het hoofdland, met rangen relatief tot dezelfde gekozen internationale vergelijkingsgroep; die groep krijgt geen lijn. ‘Groep 4’ is bevestigd als internationaal vierde leerjaar, dus Nederlandse groep 6 (rond tien jaar). Alle A-besluiten zijn hiermee beantwoord. De numerieke rangafleiding en dashboardbediening zijn nog niet gebouwd. Zie `review_20261013/RANK_PRODUCT_CONTRACT.json`.


## Internationale productie — uitvoering 15 oktober

De bronlezers en de certificeringsbibliotheek zijn uitgebreid van uitsluitend Nederland naar expliciete landenidentiteiten. `LO_COUNTRY_TASKS.R` past de gekozen statistiekcontracten toe op de werkelijke broncontexten, inclusief toegelaten landen buiten het historische takenbestand. `LO_PISA_PARTITION.R` leest per moderne golf eenmaal de benodigde kolommen en bewaart gecontroleerde nationale partities. `LO_ATOMIC_CHECKPOINT.R` vervangt checkpoints op Windows atomair met behoud van de vorige versie. De internationale broncontrole loopt; aantallen kandidaatlanden zijn nog geen gevalideerde resultaten of dashboardvrijgave. De bestaande Nederlandse certificaten blijven behouden. De volledige internationale productie, aanvullende familievoorbereiding en productafleidingen zijn pas klaar na daadwerkelijke verificatie.

De volledige internationale bronronde is afgerond: 34 landen voldoen aan de 6×3-bronregel; 544 broncontexten en 77.611 gekozen doelen zijn geregistreerd. Tien bronproblemen zijn hersteld (waaronder officiële jackknife-zones met één waargenomen helft, de geldige VS-2006-domeinen, en drie populatiecontroles). De gekozen SES is voor 129 landgolven voorbereid met de vaste kalibratie; de Nederlandse scores blijven exact gelijk. Er zijn vóór de volledige run 2.516 gecertificeerde cellen, waaronder 143 buitenlandse pilotcellen. Zie [actueel uitvoeringsbewijs](review_20261013/international/PREPARATION_EVIDENCE.json) en de bijbehorende landen-, bron- en voortgangstabellen. Dit is nog geen voltooid internationaal dashboard. Dezelfde START.R-route ondersteunt nu alle gekozen families en hergebruikt gecertificeerde resultaten tussen scopes; high-peer-baselines worden uit hun gecertificeerde kerntotaal afgeleid.

Uitvoeringsaanvulling 15 oktober: de volledige internationale run is gestart. Bij een gecontroleerde herstart voor numeriek geteste versnelling waren 2.607 cellen duurzaam gecertificeerd (91 nieuwe cellen in deze poging). Alle afgewerkte blokken blijven behouden. Kern- en SES-controles zijn versneld met behoud van alle PV-/replicatie-uitkomsten; er zijn expliciete overdraagbare bronkoppelingen en toetsen per complete figuur toegevoegd. Zie [het uitvoeringsbewijs](review_20261013/international/EXECUTION_PROGRESS.json). Volledige internationale productie en internationale dashboardvrijgave zijn nog niet afgerond.

Uitvoeringsreview 15 oktober, tweede versnelling: 2.850 van 77.611 exacte doelen zijn duurzaam gecertificeerd en 3.597 hebben specifieke bronafwezigheid. De resterende 71.164 doelen zijn nog geen voltooide productie. De producent gebruikt begrensde matrices en hergebruik van vaste PV-transformaties; alle PV- en replicatiewaarden zijn op acht echte blokken vergeleken. Een lock beschermt nu ook Git-updates voor de start. Zie [snelheid, hervatten en bronkwaliteit](review_20261013/PERFORMANCE_REVIEW_20261015.md) en [concrete gendervoorbeelden en gecontroleerde toegangsroute](review_20261013/PISA2025_GENDER_REVIEW.md). De gebruiker heeft geen keuze gemaakt om Female / Other als meisjes te behandelen.

Uitvoering pooling: alle 24 Nederlandse nieuwe cellen zijn via de bestaande certificeringsbibliotheek geregistreerd. De nationale audit telt 2397 gecertificeerde cellen en 281 onderbouwde bronafwezigheden; geen overige open primitieve doelen. De hervatcontrole produceerde nul nieuwe berekeningen. Alle 3434 tot dan gecertificeerde nationale/internationale cellen zijn naar private Drive overgebracht met herstelcontrole. Paper-, balans- en productvrijgave blijven afzonderlijk. Ook code-, instellingen- en runregistraties worden incrementeel extern bewaard, inclusief een laatste checkpoint na afloop van START.R. De uitvoeringsstatus is geen claim dat alle internationale landen of dashboardproducten klaar zijn.
