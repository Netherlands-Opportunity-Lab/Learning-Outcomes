# Aflevering current47 — 20 oktober 2026

Het dashboard en openbare replicatiepakket zijn gepubliceerd en gecontroleerd.
Paper en slides zijn privé bewaard. Eén terugtrekkingspunt blijft open: oude
Git-commits kunnen documenten bevatten. De afzonderlijke beslissing over
destructieve historieopschoning is niet ontvangen. Volledige privacyafronding
wordt daarom niet als klaar gemarkeerd.

- [Dashboard NL](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/nl/) · [EN](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/en/).
- [Vaste GitHub-release en replicatiepakket](https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes/releases/tag/v2026.10.20-current47-dashboard.1) · [PR #5, samengevoegd](https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes/pull/5).
- [Bronregister](../international/SOURCE_CATALOG.csv) · [Dekkingsrapport](../grid_coverage/README.md) · [Combinatiedekking](CURRENT47_COMBINATION_COVERAGE.csv) · [Nederlandse standaardreferenties](NLD_CURRENT47_STANDARD_MEAN_REFERENCES.csv).
- [FAIR-review](STEP3_FAIR_REVIEW.md) · [Windows/Linux](STEP3_PLATFORM_VERIFICATION.json) · [554 live hashes en document-404's](LIVE_PUBLIC_READBACK.json) · [Browserproeven](STEP3_BROWSER_RECHECK.json).

47 landen/onderwijsstelsels; 90.829 doelen = 82.142 gevalideerde resultaten en
8.687 onderbouwd onbeschikbare doelen; nul open huidige berekeningen. Q01–Q08,
174 figuurcontracten en 8.178 land-figuurkeuzes zijn gecontroleerd. Toelating
blijft per leeftijd/domein; referenties behouden alle hoofdlandjaren en samen
getoonde groepen. Onderzoeksprecisie en oorspronkelijke productieherkomst zijn intact.

De branches zijn zonder historieherschrijving samengebracht; onafhankelijke
resultaatcommits zijn behouden. Drie oude documentroutes geven 404; 21 eerdere
openbare CI-documentpakketten zijn teruggetrokken. Het nieuwe pakket bevat geen
manuscript, slides, bewerkbare documenttekst of leerling-/schoolmicrodata.

De private paper heeft 29 pagina's; de presentatie 22 slides met 90 bewerkbare
grafieken. Bewerkbare tekst, bibliografie, figuurbronnen en private herbouwscript
zijn behouden. Alle 145 oorspronkelijke bestanden zijn via private Drive echt
teruggehaald en op hash gecontroleerd. De private herbouw slaagt; 53 tekst-ID's,
twaalf claims en drie formele toetsen blijven numeriek aangesloten. Eigen
documenten zijn na opruiming opnieuw op de oorspronkelijke hashes gecontroleerd.

## Replicatieroutes en gemeten middelen

Eén pakketingang: `python REPLICATE.py inspect`, `dashboard --output nieuwe_map`
of de gedocumenteerde toekomstige `source`-route. Bronproductie blijft in de
bestaande START.R/RUN.R-keten. [De configuraties](../../../replication/ROUTES.md)
ondersteunen nld_only, nld_plus_19 en all_required, begrensd tot deze fase.
nld_plus_19 is een historische naam en garandeert geen negentien referentielanden.
Het [script-naar-resultaatoverzicht](../../../05_publication/REPLICATION_PACKAGE_README.md)
verbindt producenten, exact grid, checkpoints, exports en dashboard.

Vanuit de lokale Git-checkout kan RStudio alleen de release controleren:

```r
source("replication/INSPECT_RELEASE.R", encoding = "UTF-8")
```

Stel zo nodig `options(lo.python = "/pad/naar/python")` in. De vastgelegde R-omgeving
levert digest. De controle downloadt de vaste release, verifieert hashes en ruimt
de tijdelijke extractie op. Geen leerlinganalyse; geen verplichte handeling nu.

| Route | Werkelijk gemeten |
|---|---|
| Pakketinspectie Windows | 5,856 s; 92,4 MB piekwerkgeheugen |
| Dashboardherbouw Windows | 117,04 s; 720,1 MB piekwerkgeheugen; twee herbouwmappen gelijk aan 551 kernbestanden |
| RStudio-controle na opruiming | 18,677 s inclusief publieke download; tijdelijke extractie verwijderd |
| Openbaar pakket | 71.470.480 bytes gecomprimeerd; 418.876.603 bytes uitgepakt |
| Eerdere volledige checkpointrestore | 2.037 pakketten; 83.540 celversies; 3.773,14 s; 171,9 MB piekbatch |
| Nieuwe herstelcontrole | Alle oude pakketten identiek; één toegevoegd metadatapakket met elf bestanden hersteld; beide grote bewijs-CSV's volledig teruggelezen |

Alle zes GitHub-workflows slagen. Windows/Linux-bewijs dekt omgeving, software
en aggregaatherbouw. De eerdere echte Windows-bronproeven dekken 58 cellen.
De 36 landen en volledige nieuwe leerlingbronreplicatie zijn uitgesteld en niet
uitgevoerd. Er is geen volledige bronheruitvoertijd verzonnen, geen DOI uitgegeven
en geen AEA-certificering geclaimd.

## Opslag en terugval

Na externe herstelcontrole zijn 3.057 tijdelijke bestanden verwijderd: gemeten
2.412.154.880 bytes extra vrije ruimte, daarna 9.355.059.200 bytes vrij op C:.
De [exacte selectie](STEP3_CLEANUP_RECEIPT.json) heeft verse hashes. Bronnen,
eigen producten, persoonlijke bestanden en noodzakelijke herstelstaat blijven
behouden. LO05/master-mappen zijn niet integraal verwijderd. De controle
[na opruiming](STEP3_AFTER_CLEANUP_INSPECTION.json) slaagt.

Veilige terugval: voer de bestaande pages.yml uit op tag
v2026.10.20-current47-dashboard.1 met kandidaat 2878cafc157c71414e51.
De [septemberwebsite](https://netherlands-opportunity-lab.github.io/Learning-Outcomes/archive/2026-09-28/)
blijft beschikbaar. Herpubliceer de ingetrokken oktoberkandidaat met documenten
niet. Oude Git-commits/caches zijn niet gewist door actuele bestanden te vervangen.
Het private volledige Git-bundle is teruggelezen vóór eventuele historieopschoning.

Bron- en methodebeperkingen blijven zichtbaar: verschillende studieschalen,
ontbrekende vragenlijsten/velden/schalen, onvoldoende analysegroepen en definitiebreuken
bij gepoold geslacht. Geen causale of individuele cohortinterpretatie.
