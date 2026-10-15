# GitHub, resultaatversies en rekentijd — 15 oktober 2026

Het directe gebruikersbesluit is dat RStudio de versiebeheerste scripts uit GitHub ophaalt en de resultaatwaarden, instellingen en fingerprints terugplaatst. Dit wordt uitgevoerd op de bestaande ontwikkelbranch en PR #5. Het is geen opdracht om het dashboard te deployen of ontbrekend wetenschappelijk bewijs te vervangen.

`START.R` met `LO_START_ACTION=produce-approved` haalt vóór een gewone run een veilige fast-forward op. Daarna worden audit, productie en status op één vaste commit uitgevoerd. Pas na die fasen plaatst `LO_GITHUB_RESULTS.R` de gecertificeerde nationale aggregaten onder `04_results/review/<scope>/` terug op dezelfde branch. Expliciete `LO_REPRODUCE_COMMIT` behoudt de gekozen historische versie en slaat de update over. Geen force-push, automatische merge of overschrijving van lokale code. Bij mislukte upload blijven berekeningen en een voorbereide kopie behouden; de runner meldt dat GitHub nog niet bijgewerkt is.

Een gewone samengestelde run voert de private Drive-overdracht eenmaal na de GitHub-depositie uit. De eerdere twee overdrachten tussen audit/productie en na productie veroorzaakten onnodige wachttijd. Historische replicatie met expliciete commit deponeert standaard niet naar GitHub; daarvoor is een expliciete keuze `LO_GITHUB_RESULTS=review` vereist. Exacte manifestbytes zijn met `.gitattributes` beschermd tegen automatische CRLF/LF-omzetting.

De reviewmap bevat:

- `results.csv`: waarden, SE, N, exacte celidentiteit en bron/input/producer/resultaat/certificaathashes, zonder afronding van wetenschappelijke invoer.
- `target_status.csv`: ook de aantoonbaar ontbrekende en onopgeloste doelen.
- `scripts.csv`: rollen van producenten, controlecode en exportcode. De bestandsversie op exportmoment is uitdrukkelijk niet de oorspronkelijke producentversie.
- `run_provenance.json` en `result_run_links.csv`: koppeling aan historische codecommits, pakketversies, instellingen en resultaatversies. Herhaalde waarnemingen van dezelfde resultaatversie worden niet steeds opnieuw gekopieerd.
- `execution_receipts.csv` en `derivations.csv`: daadwerkelijke berekenreceipts en exacte oudercellen van afleidingen. Een hergebruikt gemeten proefresultaat krijgt geen verzonnen controllerreceipt.
- `manifest.json`: aantal cellen, status, configuratie en SHA256 per bestand.

De volledige private runrecords, leerlingbestanden, schoolrecords en lokale paden worden niet naar GitHub gekopieerd. De gecertificeerde resultaatwaarden worden wel opgenomen; de private bron-/replicatiebewijzen blijven herstelbaar op Drive. De afzonderlijke productvrijgave blijft herkenbaar als nog niet verleend.

Ook de 24 onderliggende historische R-bestanden zijn onder `06_pipeline/archive_or_superseded/LO05_CODE_LOCK_20261010/` beschikbaar, met een manifest van originele en eventuele privacybewerkte hashes. De actieve runner blijft de gecontroleerde originele lokale bundle gebruiken; dit codearchief geeft geen vrijbrief voor de oude brede launchers en vervangt niet de nog vereiste schone externe replicatie.

## Rekentijd en omvang

De 2.373 beschikbare Nederlandse cellen zijn al berekend en gecontroleerd. Een identieke herhaling berekent nul nieuwe cellen; audit, bestandscontrole en upload kosten wel tijd. De eerder geplakte run controleerde circa zes minuten en besteedde daarnaast tijd aan Drive. Dit is geen tijdmeting van nieuwe leerlingberekeningen.

De daadwerkelijk uitgevoerde samengestelde route met één Drive-overdracht duurde **422,23 seconden (7,04 minuten)**. Audit en productie behielden 2.373 geldige uitkomsten, 281 aangetoonde ontbrekende doelen en 24 open bronvragen. Daarna zijn 13 private rapportbestanden teruggelezen en gecontroleerd. Een tweede identieke GitHub-depositie veranderde geen bestand en maakte geen nieuwe commit. De Windows/Linux-codechecks zijn groen op `d2d6350961286188d601a88fa7299c746574bace`; de resultaatcommit is afzonderlijk in het depositiebewijs vastgelegd. De voorgaande route met twee Drive-overdrachten duurde 779,45 seconden; dit zijn twee afzonderlijke lokale metingen, geen gegarandeerde netwerksnelheid.

Gemeten proefblokken: oude PISA 57 cellen/21,81 s; moderne PISA 48/65,19 s; IEA 24/33,96 s; boeken 40/32,04 s; prestatiepeers PISA 30/31,38 s en IEA 20/15,80 s; achtergrond PISA 34/25,16 s en IEA 52/61,03 s; gekozen SES 48/45,20 s. Dit betreft de producer op voorbereide bronnen. De orde van grootte voor 2.373 vergelijkbare cellen is circa 15–60 minuten uitsluitend schatten. Reserveer voorlopig 1–3 uur voor een Nederlandse herberekening inclusief bronlezen, certificaatcontrole en voorbereiding, zonder nieuwe downloads. Dit is een planningsmarge uit proefmetingen, geen gemeten volledige koude run of garantie.

De huidige compacte wetenschappelijke gzip-CSV is 142.742 bytes, de presentatie-export 101.179 bytes, SQLite met numerieke historie 4.481.024 bytes en het private bewijsarchief 19.854.844 bytes. De leesbare GitHub-CSV en herkomsttabellen zijn groter dan gzip; de GitHub-manifesten meten hun werkelijke bytes. Dubbele afronding bespaart geen ruimte in native doubles: alle 17 significante cijfers blijven beschikbaar.

De daadwerkelijke GitHub-resultaatcommit `117550e373d0c3fa04225c30ffaaa9665b0c1b10` bevat een `results.csv` van 2.625.730 bytes. Het hele openbare snapshot met herkomst en status telt 4.300.920 bytes. Alle zeven manifestbestanden en alle 24 R-codekopieën zijn ook rechtstreeks als Git-blobs gehasht; de remote branch wees op dezelfde commit. Zie [het depositiebewijs](GITHUB_RESULT_DEPOSIT_PROOF_20261015.json). Dit bewijs onderscheidt de actuele exportcode van de historische producentcommits en vervangt geen schone externe replicatie.

Voor twintig landen met ongeveer dezelfde hoeveelheid uitkomsten is alleen de compacte resultatentabel ruwweg 20 × 143 kB ≈ 2,9 MB. Dat is een schaalvoorbeeld, geen toelating van twintig landen en geen raming van bronbestanden of gezamenlijke replicatiebewijzen. Definitieve internationale rekentijd vereist de goedgekeurde landenlijst, aantallen bronrecords/golven en benodigde cellen; die wordt niet uit de bestandsomvang afgeleid.

## Gender en steekproefmethode

De PISA-2025-vragenlijst bevat ST430 met drie antwoordopties. Een vragenlijst is geen bewijs dat een veld ook in iedere public-use editie aanwezig en gevuld is. In de oorspronkelijke NLD-bron is ST004D01T daadwerkelijk 99 voor alle 6.636 leerlingen, ondanks de labels 1=Female/2=Male. ST004D01D, ST004, ST430Q01DA en FEMALE ontbreken. MALE=1 identificeert 3.397 jongens; MALE=0 omvat 3.237 Female / Other; twee records hebben 99. Het bronbestand is opnieuw gecontroleerd, inclusief SHA256; zie `PISA2025_USER_GENDER_FIELDS_RECHECK.json`. Publicaties over 2022 bewijzen geen Nederlandse beschikbaarheid in 2025. De 24 onopgeloste doelen blijven ongewijzigd.

De huidige PISA-producent gebruikt W_FSTUWT, alle 80 replicatiegewichten, Fay-BRR-factor 1/20 en alle vijf of tien cyclusgebonden plausible values. Schattingen worden per PV en replicaat gemaakt; de totale variantie combineert gemiddelde steekproefvariantie met (1+1/M) maal tussen-PV-variantie. PIRLS/TIMSS gebruiken hun eigen cyclusgebonden JRR-ontwerp. Dit is reeds onafhankelijk gecontroleerd. Gewogen percentages en peeruitkomsten gebruiken hun exacte gevalideerde noemers.

`BIFIEsurvey` en `intsvy` ondersteunen analyses met surveygewichten/PV's. Zij kunnen nuttig zijn als aanvullende controle, maar een pakketkeuze vervangt geen controle van bronlabels, ontwerpinstellingen, missings, drempels en de specifieke peer-/SES-definities. Een overstap van de gevalideerde producent is voor dit doel niet nodig.

Bronnen: [PISA-2025-vragenlijst, p. 6](https://www.oecd.org/content/dam/oecd/en/data/datasets/pisa/pisa-2025-datasets/questionnaires/STUDENT%20QUESTIONNAIRE%20PISA%202025.pdf), [OESO analysemethode](https://www.oecd.org/en/about/programmes/pisa/how-to-prepare-and-analyse-the-pisa-database.html), [BIFIEsurvey-documentatie](https://search.r-project.org/CRAN/refmans/BIFIEsurvey/html/BIFIE.data.html), [intsvy-documentatie](https://search.r-project.org/CRAN/refmans/intsvy/html/intsvy.log.pv.html).
