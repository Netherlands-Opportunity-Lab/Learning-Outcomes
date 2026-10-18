# Definitieve bedieningskeuzes — 18 oktober 2026, laatste gebruikersbericht

Uitkomst/leeftijd → uitsplitsing → **Weergave / Measure** → hoofdland.
Internationale vergelijking en onzekerheidsmarge staan standaard aan. Expliciete
uit-keuzes in gedeelde links blijven behouden. Onzekerheidsknop, figuurstatus en
alle tijdelijke/voorlopige toelichtingen staan onder de figuur. De losse tekst
“95% · alleen hoofdland” vervalt; de 95%-methode blijft in de toelichting en downloads.

De beschikbare referentiepunten in opeenvolgende meetjaren worden met een
stippellijn verbonden. Landen kunnen per punt verschillen; dat blijft onder de
figuur en in de tabel/download vermeld. Niet verbinden over ontbrekende meetjaren,
definitiewijzigingen of gewijzigde rangbases. De definitieve wetenschappelijke
balansregels veranderen niet door deze bedieningskeuzes.

De oudere keuze voor standaard-uit hieronder is hiermee vervangen.

# Aanvullend actueel besluit — 18 oktober 2026

De vier dropdowns staan als uitkomst/leeftijd → statistiek → uitsplitsing → hoofdland.
De vergelijking blijft de vijfde keuze. De gebruiker vraagt daarnaast een optionele
onzekerheidsschakelaar voor de hoofdlandfiguren en een volledige Engelse vertaling
zonder tweede applicatie. Uitvoering: **Onzekerheidsmarge / Uncertainty range**,
standaard uit, naast de figuurstatus. Toon 95%-intervallen uit de bestaande
gecontroleerde SE, alleen voor het hoofdland. Rangen/referentiegemiddelden krijgen
geen interval. Dezelfde code, data en figuurkeuzes bedienen beide talen; een
 taalwissel bewaart de selectie. Geen nieuwe schattingen of productfamilies.

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
