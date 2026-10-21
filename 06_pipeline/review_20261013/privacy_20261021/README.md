# Private documenten en historieopschoning 21 oktober 2026

De gebruiker heeft verwijdering uit alle GitHub-versies expliciet toegestaan.
Alle elf branches en de releasetag zijn gecontroleerd en opgeschoond: 75 exacte
document-/pakketpaden en 113 historische blobs zijn verwijderd. Alle 636
onderzoekscommits zijn als afzonderlijke commits behouden. De actuele boom was
vóór de visuele wijziging bytegelijk aan de vorige gecontroleerde versie.

De private volledige Git-bundel en eigen documenten zijn behouden. Het
[commitregister](COMMIT_REWRITE_MAP.txt) verbindt oorspronkelijke productie-ID's
met de opgeschoonde commits. Oorspronkelijke productie-ID's in wetenschappelijk
bewijs blijven historische herkomst; ze worden niet vervangen door export-ID's.
Gebruik bij een nieuwe checkout de bijbehorende nieuwe commit uit dit register;
controleer vervolgens de oorspronkelijke bestands- en configuratiehashes.
Importeer geen oude branches uit andere checkouts: daarmee kunnen ingetrokken
documenten opnieuw gepubliceerd worden. De actieve RStudio-checkout is aangepast
zonder de werkbestanden te resetten.

GitHub kan oude PR-verwijzingen en gecachete commitpagina's blijven bewaren.
Verificatie daarvan staat apart; force-push alleen bewijst geen serverbrede
verwijdering. Zie de officiële GitHub-documentatie over removing sensitive data.

De huidige figuren gebruiken rechte segmenten, miter-hoeken en vlakke
lijneinden. Cijfers, onzekerheid, selectie en lijnonderbrekingen veranderen niet.
Word, paper-PDF, PPTX, slide-PDF en het historische 50-slide-deck blijven privé.

De aanvullende artifactcontrole heeft alle 21 resterende CI-pakketten geopend.
Eén oudere Pages-artifact bevatte nog de drie documenten; die is privé bewaard,
verwijderd en met HTTP 404 gecontroleerd. De gecontroleerde oude raw-commitlink,
PR-5-documentlink en live paper-URL geven eveneens HTTP 404. Dit bewijst de
gecontroleerde routes; het is geen uitspraak over niet-publieke serverback-ups
van GitHub of kopieën die derden eerder hebben gedownload.
Zie REMOTE_DOCUMENT_RESIDUE.json voor de exacte controles.
