# Kritische implementatiereview — bijgewerkt 15 oktober 2026

De bestaande keten is op echte Nederlandse PISA-, PIRLS- en TIMSS-bronnen uitgevoerd. Actuele aantallen, bytes, hersteltest en CI-versies staan in STEP1_EXECUTION_EVIDENCE_20261014.json. De oorspronkelijke negen kerncellen zijn de historische eerste ketentoets; zij zijn niet de actuele productieomvang. De volledige wetenschap en eindproducten zijn nog niet vrijgegeven. De bron-ZIP en eerdere ongewijzigde inventarisatie zijn niet opnieuw uitgepakt of uitgevoerd.

## Architectuur en reparaties

Eén START.R / RUN.R voert audit → produce → finalize uit. JSON-configuratie selecteert binnen de goedgekeurde scope. Alleen exact bron-/methodegecertificeerde cellen worden berekend. De historische 79.448 keys zijn geen verplichte werkvoorraad. Een echte scopefout is hersteld: 152 goedgekeurde PISA-uitbreidingscellen ontbraken; het Nederlandse doelgrid heeft nu 2.678 cellen.

Resultaatrij en uitvoeringsreceipt worden atomair in SQLite opgeslagen. Gewijzigde bron, input, code of methode kan geen oud resultaat ongemerkt hergebruiken. Een gedeeltelijke fout is werkelijk hersteld: 128 voltooide oude-PISA-cellen zijn onafhankelijk gesloten; daarna zijn uitsluitend 24 ontbrekende taalresultaten uitgevoerd. De identieke tweede run berekende nul nieuwe cellen. De inputhash bevatte ten onrechte ongebruikte taalvelden en dataframe-rijnamen.

Gevalideerde proefresultaten worden hergebruikt zonder herberekening of verzonnen controllerreceipt. Het productgrid behoudt product/slide/figuur/claim → exacte cel of afleiding → bron/populatie/jaar/definitie/methode/onzekerheid/bewijs. Rangen, complementen en verschillen krijgen oudercellen; marginale SE's vervangen geen covariantie.

## Bronnen en methoden

Het Nederlandse kernjaaranker heeft 40 onderbouwde combinaties: PIRLS lezen 5 golven; TIMSS wiskunde/natuurwetenschappen elk 6; PISA lezen/wiskunde elk 8 en natuurwetenschappen 7. Dit bewijst 6×3 voor de kernreeksen, niet alle groepsuitsplitsingen of buitenlandse referenties.

PISA gebruikt alle 5 oudere of 10 moderne PV's en 80 Fay-BRR-gewichten, factor 1/20 en passende tussen-PV-term. IEA gebruikt alle 5 PV's en cyclusgebonden JRR. Onafhankelijke schattingen en SE's moeten binnen 1e-9 overeenkomen; N en bronidentiteit exact. Gezamenlijke PV-/replicatie-uitkomsten blijven behouden.

| Bevinding | Behandeling |
|---|---|
| PISA-2003-migratielabels gebruiken oudere terminologie. | Tegen geboortevelden van leerling en ouders gecontroleerd; bronlabels behouden. |
| PISA 2012 heeft nulgevulde programmacodes. | Voorloopnullen behouden. Eén niet-gemapt PISA-2009-programma vormt geen fictieve directe leeromgeving; hele-schoolwaarneming blijft behouden. |
| PISA 2025 is officieel gepubliceerd. | Ruwe Nederlandse public-use bron met 6.636 records en exacte SHA256 gecontroleerd; een deckpunt blijft onvoldoende bronbewijs. |
| ST004D01T bevat voor alle Nederlandse leerlingen code 99 in 2025. | MALE=1 identificeert jongens: drie domeingemiddelden en achttien jongens-SES-cellen zijn gecertificeerd. Alleen 24 meisje-afhankelijke doelen blijven een open bronmappingvraag. MALE=0 Female/Other vervangt meisjes niet. |
| PIRLS 2021 is deels vertraagd afgenomen. | De officiële oorspronkelijke vierdejaarscohort blijft intact, inclusief najaarsregistraties. |
| PIRLS 2006 kent always / sometimes / never. | Niet hernoemen tot always-or-almost; zeven getroffen doelen blijven expliciet onbeschikbaar. |
| Boeken zijn geordende categorieën met veel ties. | Nationale gewogen fractionele kwartielen opnieuw per replicaat, onafhankelijk gecontroleerd. Variantie betreft ordinale boekencategorieën. |
| Lage/hoge peerdoelgroepen verschillen per PV. | Scalar N beschrijft het vaste analytische frame; iedere doelgroep-N staat apart per PV en is onafhankelijk en met hash gecontroleerd. |
| PISA-school×programma is geen echte klas. | Directe omgeving en hele school blijven gescheiden. In de acht gebruikte public-use golven ontbreekt echte klasidentiteit; 27 klasvariantiedoelen zijn met bronbewijs onbeschikbaar, niet vervangen door programmavariantie. |
| Geboorteland van ouders ontbreekt in PIRLS 2011/2016/2021 en TIMSS 2011. | 103 getroffen doelen blijven aantoonbaar onbeschikbaar in de gecontroleerde bronnen. Geboorteland van het kind alleen is geen migratiegeneratie. |
| Oudere taalvragen, ouders/voogden en missingcodes hebben verschillende labels. | Negentien bronblokken zijn op werkelijke labels, exact leerling-ID-set, oorspronkelijke bronhash en expliciete ontbrekende waarden gecontroleerd. Geen onbekende code als nee behandelen. |
| Nationale hoge-prestatiebaselines waren nog niet gesloten. | Tachtig baselines zijn met exacte oudercel, drempel, populatie en factor 100 afgeleid uit reeds gecertificeerde nationale kerncellen. Geen nieuwe leerlingberekening; SE en N correct overgenomen. |

Primaire bronnen: [OESO PISA-data](https://www.oecd.org/en/about/programmes/pisa/pisa-data.html), de bijbehorende officiële cyclusdatabanken, [Nederlandse PIRLS-2021-rapportage, p. 13](https://www.expertisecentrumnederlands.nl/pirls-2021-resultaten/download/PIRLS-2021_Rapportage.pdf). Private bewijsbestanden bewaren exacte broneditie, labels, ID-controles en bevroren onafhankelijke controlecode.

## Kritische beoordeling van de keuzes

6×3 is een toelatingsregel. Volledige jaar- en groepsbalans kan de Nederlandse referentie verder verkleinen of leeg maken. De rijke twintig blijven kandidaten. Geen vast aantal, jaarlijks wisselende leden of stil verkorte periode. Buitenlandse productie vereist nog een concreet brongetoetst landenvoorstel en het afzonderlijke gebruikersbesluit. Gelijkgewogen referenties krijgen geen SE; het hoofdland blijft erbuiten.

Onder basisniveau en hoog/gevorderd hebben twee afkappunten en zijn geen complementen. Onder/boven hetzelfde afkappunt zijn dat wel; gekozen complementen worden afgeleid zonder dubbele leerlingberekening. Rekenkosten hangen ook af van leerlingen, groepen, PV's, replicaten en peeromgevingen. Een klein resultatenbestand zegt weinig over bronruimte of kalibratiekosten.

Home-SES kan geen uniforme lange reeks worden door oudere Home Resources-schalen te hernoemen. Voor PIRLS 2021 zijn negen appendixcellen gecontroleerd: 2.031 van 4.313 leerlingen hebben de officiële schaal, met gewogen dekking 47,7027%. De uitkomsten gelden conditioneel op waargenomen SES; selectieve respons blijft een inhoudelijke beperking. De 144 doelen zonder dezelfde officiële schaal blijven onbeschikbaar. De gekozen PISA-SES is de gepinde Innovamat/Cobreros-viergolvenaanpak. De onafhankelijke kalibratie en de publieke voorbereidingsadapter reproduceren de gekozen auteursmethode; alle 246 beschikbare gekozen SES-cellen zijn gecertificeerd. Officiële ESCS wordt als vervanging geweigerd. Auteurpanels bepalen de kalibratie, niet de dashboardreferentie. Dit autoriseert geen aanvullende auteursanalyses.

School-/klasvariantie en peercompositie zijn beschrijvende maten, geen causale effecten. Trendclaims vereisen juiste linking- en steekproefinterpretatie; dwarsdoorsneden zijn geen gevolgd cohort. Q01–Q08 blijven afzonderlijke bewijsvoorwaarden.

## Opslag en replicatie

Gerichte verwijdering en gecontroleerde NTFS-deduplicatie maakten 26.008.379.325 fysieke bytes vrij. Benodigde bronpaden bleven behouden. Hardlinkaliases delen onveranderlijke bronbytes. Geen complete LO05/mastermap of niet-projectarchief is verwijderd. Gemeten bronfamiliepilots en 2 GiB reserve begrenzen runs; dit is geen OS-quota of universeel budget.

SQLite bewaart volledige doubles; de wetenschappelijke gzip-CSV gebruikt 17 significante cijfers. Alleen presentatie wordt afgerond. Nieuwe numerieke versies worden eenmaal bewaard. Configuratie, bron-/codehashes, methode, softwareversies en resultaatversie staan in private runrecords. De Drive-hersteltest controleert teruggehaalde bytes, manifesthashes en een geopende SQLite-database; exacte omvang staat in het uitvoeringsbewijs. Er wordt geen volledige bronback-up geclaimd.

R 4.6.1 en 41 vastgelegde pakketten zijn op schone Windows/Linux-runners hersteld. LO_REPRODUCE_COMMIT voorkomt fast-forward en vereist juiste commit, ongewijzigde code en vastgelegde omgeving. Het historische bronbundle blijft een expliciete gepinde externe afhankelijkheid. Consolidatie en schone volledige bron-tot-productreplicatie zijn nog nodig voor de uiteindelijke FAIR-release.

Het dashboard behoudt de gekozen 1-oktoberopzet, originele logo's, Inter/Oswald en v05-kleuren. Het bouwt één tijdreeksfiguur. Bij rang bepaalt de referentiegroep de positie van het hoofdland; de groep krijgt geen lijn. Eventueel komt één ander land erbij. Ranglijsten behoren alleen in de paper. Het ontwerp is gerenderd; volledige nieuwe referentiebediening, paper en decks zijn nog geen voltooide producten.

ACCEPTATIE_EN_VOORTGANG.csv en IMPLEMENTATION_ISSUES.csv registreren de resterende voorwaarden. Een groene test, lege geautoriseerde rekenwachtrij of nieuw statuslabel vervangt geen ontbrekend wetenschappelijk bewijs.
