# Voorbereide bronreplicatie — uitvoering uitgesteld

**Gebruikersbesluit 20 oktober:** deze volledige nieuwe bronreplicatie wordt later gedaan. De huidige controle van de drie stappen sluit haar en deferred36 uit. Het onderstaande is een bewaarde uitvoeringshandleiding voor een latere expliciete hervatting, geen opdracht om nu te starten.

Stap 1 en de producten van stap 2 zijn afgerond. De al geslaagde pakketbouw,
Windows/Linux-productherbouw, volledige Drive-herstelcontrole en live publicatie
hoeven niet opnieuw. De volledige nieuwe leerlingbronreplicatie van current47
blijft een afzonderlijke, nu uitgestelde controle. De 36 uitgestelde landen blijven uitgesloten.

`scripts/START_FRESH_SOURCE_REPLICATION.R` configureert uitsluitend de bestaande
`START.R` / `RUN.R`-keten. Het is geen tweede rekenmethode. Het leest een private
instellingenfile met exacte codecommit, huidige landenconfiguratie, bronpaden en
hashes, een lege uitvoermap, de gepinde auteursrepository en een aparte private
Drive-bestemming. Die instellingenfile wordt niet op GitHub geplaatst.

```r
source("scripts/START_FRESH_SOURCE_REPLICATION.R")
lo_start_fresh_source_replication("/absoluut/pad/SETTINGS.local.json")
```

Met `preview=TRUE` controleert dezelfde functie paden, instellingen, gepinde code,
landenselectie en vrije ruimte zonder een productiemap te maken of leerlingen te
analyseren. Een geslaagde preview is geen uitgevoerde bronreplicatie.

De bronbestanden worden zonder kopieën hergebruikt; oude resultaten worden niet
voor schatting gelezen. Na afloop vergelijkt het commando het nieuwe grid met
het verzegelde grid: dezelfde doelidentiteiten, status en ontbrekendheidsreden,
exact dezelfde N en maximaal 1e-9 verschil in schattingen en standaardfouten.
Een geldig nulpunt blijft een resultaat. Afwijkingen worden gerapporteerd en
overschrijven geen eerdere resultaten.

Hetzelfde commando hervat alleen de ontbrekende blokken uit deze aparte run.
Wijzig de gepinde code, bronkoppeling, uitvoermap of instellingen tijdens een
lopende run niet. De reguliere schrijfvergrendeling en de bron-, configuratie-
en checkpointcontroles blijven actief. Een gewijzigde run vraagt om een nieuwe
gecontroleerde configuratie.

De lokale voorbereiding hanteert een conservatieve beginreserve van 8 GiB;
de bestaande ruimtecontroles per bron- en rekenfase blijven bovendien actief.
Dit is geen gemeten maximale ruimtebehoefte voor de volledige herberekening.
Bronnen blijven behouden; gecomprimeerde lokale werkmappen sparen ruimte zonder
waarden of hashes te wijzigen. Volledige nieuwe looptijd en piekruimte worden
pas door de werkelijke uitvoering bekend. Reken op uren, geen korte statusrun.

Nieuwe resultaten gaan naar een afzonderlijk private Drive-checkpoint.
Automatische vervanging van de beoordeelde GitHub-resultaatbasis staat uit.
Na numerieke overeenstemming moeten de gezamenlijke afleidingen en
wetenschappelijke/productbewijzen nog op de nieuwe run worden aangesloten.
`FULL_SOURCE_REPLICATION_PARITY.json` benoemt dat expliciet. Pas na die beoordeling mag volledige bronreplicatie worden geclaimd. De huidige
controle van stap 3 heeft op gebruikersverzoek een beperktere scope. Ook de
uitgestelde landenrun begint alleen na een latere expliciete hervatting.
