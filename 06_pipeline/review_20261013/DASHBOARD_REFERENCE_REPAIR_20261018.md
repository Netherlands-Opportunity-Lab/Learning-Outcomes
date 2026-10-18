# Landenkeuze — reparatie van 18 oktober 2026

De gepubliceerde tussenstand bevatte gecontroleerde punten, maar de export had nog geen onafhankelijke vergelijkbaarheidskoppeling. Daardoor stond iedere vergelijkingsgroep op `COMPARABILITY_PENDING`. De interface toonde daarvoor ten onrechte uitsluitend de melding dat dekking ontbrak. Dit was geen probleem met aanraken van vinkjes op de iPhone.

De reparatie gebruikt dezelfde vastgelegde snapshot en verandert geen schattingen. `LO_DASHBOARD_COMPARABILITY.py` verbindt iedere productcel aan de gecertificeerde resultaat-, bron-, steekproef- en methode-identiteit. `LO_DASHBOARD_REFERENCE_EXPORT.R` past de bestaande `LO_BALANCED_MEMBERSHIP.R` toe. `LO_DASHBOARD_REFERENCE_VERIFY.py` berekent de toelating opnieuw, onafhankelijk van de R-uitvoer. De publicatiecontrole vergelijkt die uitkomst met alle daadwerkelijk aangeboden opties.

De volledige Nederlandse basis van 40 survey–jaar–domeincellen blijft verplicht, plus alle jaren en samen geplotte groepen van de gekozen figuur. Minimaal drie geldige golven in elk van de zes combinaties, zelfuitsluiting, gelijke landgewichten en constante samenstelling blijven gelden. De gekozen rijke kandidaten worden alleen als standaard gebruikt waar ze daadwerkelijk passen. Meisjes en meisjes + other krijgen verschillende constructidentiteiten. Ontbrekende celkoppelingen worden niet als afwezigheid van de oorspronkelijke data gepresenteerd.

Van de 51.304 gepubliceerde punten hebben 51.301 een bewezen vergelijkbaarheidskoppeling. Drie Nederlandse jongensgemiddelden van PISA 2025 hebben nog een oude, niet sluitende bronprojectiekoppeling. Hun individuele waarden blijven gepubliceerd op hun bestaande resultaatcertificaat, maar de drie betrokken gendervergelijkingen blijven dicht. Deze reparatie maakt 2.098 land–figuurvergelijkingen mogelijk, waaronder 128 voor Nederland. Andere figuren houden hun expliciete ontbrekende jaren/groepen. Dit is geen wetenschappelijke eindvrijgave.

Bij de Nederlandse leesfiguur voor groep 6 zijn Hongarije, Hongkong, Italië en Nieuw-Zeeland selecteerbaar. Alleen Italië behoort tevens tot de vastgelegde rijke kandidaten. De standaardgroep bevat daarom één land; er worden geen negentien landen geforceerd. Dit zijn uitkomsten van de huidige snapshot, geen permanent vastgelegde ledenlijsten.

De interface zet selecteerbare landen bovenaan, benoemt ontbrekende dekking met concrete surveyjaren, bewaart de keuze in de URL en blokkeert Toepassen bij een lege of ongeldige selectie. Opties worden per hoofdland geladen. De mobiele lijst kan afzonderlijk scrollen en de actieknop blijft in beeld. Rangen gebruiken de gekozen landen als basis en tekenen geen groepsrang.

## Uitvoering en herhaling

De invoer is een onveranderlijke export van de bestaande wetenschappelijk gecontroleerde snapshot; dit script is geen leerlingproducent. Een nieuwe snapshot vereist opnieuw bron-/resultaatcontrole. Voor een al gecontroleerde snapshot:

1. Voer `LO_DASHBOARD_COMPARABILITY.py --snapshot <snapshot> --output <audit>` uit. Het optionele `--previous` hergebruikt uitsluitend de hashgebonden vorige koppeling voor dezelfde resultaatbytes.
2. Maak `FIGURES.json` in de auditmap met `LO_FINAL_GUIDED_DASHBOARD_BUILD.figure_contract(snapshot/public_inputs, False, read_scope_decisions(snapshot/public_inputs/SCOPE_APPROVALS.csv))`, onder de sleutel `figures`. Gebruik exact het actieve contract, niet een handmatige figuurlijst.
3. Voer `Rscript 06_pipeline/LO_DASHBOARD_REFERENCE_EXPORT.R <repo> <snapshot> <audit>` uit. Geef het resulterende `BALANCED_REFERENCE_EXPORT.json` mee aan de gewone dashboardbuilder met `--balanced-references`.
4. Bouw en controleer het openbare replicatiepakket. Daarin zit de exacte export, zodat `python reproduce_dashboard.py` alle openbare bestanden inclusief landenopties opnieuw opbouwt. Een volgende publicatie verandert de website pas na de bestaande publicatiecontrole en GitHub Pages-uitrol.

De uitvoer bevat uitsluitend geaggregeerde identiteit en hashes. Leerlingdata en lokale paden blijven privé. De actieve RStudio-checkout en het productiemaster worden niet gewijzigd. Test- en publicatiebewijzen staan in `DASHBOARD_REFERENCE_REPAIR_20261018.json` zodra de uitvoering is vastgelegd.
