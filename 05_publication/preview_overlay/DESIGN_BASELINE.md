# Actueel ontwerpbesluit — 15 oktober 2026

De gebruiker heeft nu expliciet één rustige figuurbouwer met vijf hoofdkeuzes gevraagd. Dit vervangt de verplichte aparte startpagina, zichtbare vier vraagkaarten en losse leeftijd/domeinknoppen uit het onderstaande historische besluit. De visuele basis van 1 oktober blijft: warme achtergrond, horizontale filters, ruime witte figuur, rustige omlijning en responsieve opbouw. De vier vragen zijn uitklapbare snelkoppelingen.

Huisstijl: Kansenlab 1.1.0 van 15 oktober; originele SVG met letteromtrekken, leerling/boek/wereldbol, accent #4D52BF, analytische kleuren afzonderlijk. Zie BRAND_RELEASE.json voor exacte ZIP- en assethashes. Bestaande gelicentieerde lokaal ingebedde Oswald-webfonts blijven beschikbaar; de nieuwe logo’s zijn fontonafhankelijk. Dit is een bewuste voortzetting van de bestaande webfontimplementatie, niet een opnieuw getekend logo.

Uitwerking, acceptatie en toevoer van resultaten: DASHBOARD_UITWERKING_20261015.md.

---

## Historisch ontwerpbesluit (behouden als herkomst)

# Dashboardbasis: archief van 1 oktober

De gebruiker heeft op 14 oktober 2026 expliciet de versie uit
`04_DASHBOARD_BRON_20261001/03_dashboard/app` gekozen als visuele basis.
De actieve bouwlocatie blijft `05_publication/preview_overlay/`; GitHub Pages
hoeft niet naar de oude runtime te worden teruggezet.

Behoud de startpagina met vier vraagkaarten, de aparte figuurpagina met
broodkruimelpad, horizontale filters, de omkaderde figuur en de bestaande mobiele
opbouw. Geen nieuw ontwerp zonder expliciete gebruikerskeuze. De nieuwe
referentiegroepkeuze moet binnen deze opbouw worden geïntegreerd.

Toegepast: originele Leerprestaties/Learning Outcomes-vectorlogo's v06,
Inter 600 voor woordmerken en Oswald 300/400/500/600 volgens variant B.
De vier compacte Latin/Latin-extended fontbestanden zijn lokaal ingebed;
licenties en bronhashes staan naast de assets. De originele SVG-bestanden
zijn bewaard. De pagina gebruikt hun vectorinhoud inline zodat Inter ook
daadwerkelijk voor de woordmerken wordt geladen; alleen het lege SVG-canvas
is in de pagina aangesneden. De merkkleur #5365A3 vervangt niet automatisch
de statistische kleuren. Achtergrond #F7F5F0 en tekst #17242D blijven leidend.

Behouden technische correcties: dynamische y-as, geldige diepe links,
geen nulwaarden voor ontbrekende intervallen, geen referentiegroepinterval,
en een leesbare lege toestand zolang nog geen land volledig is gecertificeerd.
Een gewijzigde frontend, huisstijl of referentie-export krijgt nu een nieuwe
preview-identiteit; een oude preview mag zulke wijzigingen niet verbergen.

De lokale visuele controle gebruikte duidelijk gemarkeerde historische
archiefgegevens, uitsluitend om het ontwerp te vergelijken. Dit bestand
verklaart die oude gegevens niet opnieuw wetenschappelijk geldig. De echte
productbuild blijft alleen de gecontroleerde nieuwe resultaatgrid lezen.

Aanvullend gebruikersbesluit A09: één figuur tegelijk met jaren op de x-as; leeftijd, uitkomst, uitsplitsing en vergelijking zijn instelbaar. Rangontwikkeling mag als tijdreeks; een landenranglijst hoort uitsluitend in de wetenschappelijke paper. De oorspronkelijke vier kaarten blijven ingangen naar de figuurbouwer.

Bij rangweergave is de rang van Nederland (of het gekozen hoofdland) relatief tot de gekozen internationale vergelijkingsgroep. Die groep wordt niet geplot. Gebruik dezelfde referentieselectie; het hoofdland blijft buiten zijn eigen referentiegroep. Alleen het hoofdland en optioneel één ander land krijgen een ranglijn; geen gemiddelde groepsrang of rang van een groepsgemiddelde. De jongere populatie is bevestigd als internationaal vierde leerjaar, dus Nederlandse groep 6.
