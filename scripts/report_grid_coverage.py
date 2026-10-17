"""Report saved, audited grid coverage; never calculate or approve statistics.

Usage: python scripts/report_grid_coverage.py --state <private nld_only folder>
       --output 06_pipeline/review_20261013/grid_coverage
Only allowlisted aggregate metadata leave the private state. No pupil data,
local paths, estimates or private certificate contents are copied.
"""
import argparse
import collections
import csv
import hashlib
import json
import re
from pathlib import Path


def read(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def category(row):
    if row["status"] == "SCIENTIFICALLY_VALIDATED":
        return "validated"
    if row["status"].startswith("UNAVAILABLE_"):
        return "unavailable"
    return "unresolved"


def write(path, rows, fields):
    for row in rows:
        for value in row.values():
            if re.search(r"[A-Za-z]:[/\\]|/Users/|/home/", str(value)):
                raise ValueError("Private path in public report")
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def summarize(grid, keys):
    grouped = collections.defaultdict(list)
    for row in grid:
        grouped[tuple(row[k] for k in keys)].append(row)
    output = []
    for key, rows in sorted(grouped.items()):
        counts = collections.Counter(category(row) for row in rows)
        output.append(dict(zip(keys, key), targets=len(rows),
            validated=counts["validated"], unavailable=counts["unavailable"],
            unresolved=counts["unresolved"]))
    return output


def build(state, output):
    files = ["PRIVATE_MASTER_GRID.csv", "PRIVATE_ACTIVE_PRODUCT_CELL_TRACE.csv",
             "COUNTRY_SOURCE_ELIGIBILITY.csv", "ACTIVE_REQUIREMENT_REGISTER.csv"]
    grid, links, countries, requirements = [read(state / name) for name in files]
    ids = {row["cell_id"] for row in grid}
    if len(ids) != len(grid):
        raise ValueError("Duplicate grid cell")
    if any(not row["age"] or not row["population_id"] for row in grid):
        raise ValueError("Population metadata missing; run updated fixed-audit")
    trace = collections.defaultdict(set)
    for row in links:
        if row["cell_id"] not in ids:
            raise ValueError("Uncontracted product link")
        trace[row["cell_id"]].add(row["requirement_id"])
    if ids - trace.keys():
        raise ValueError("Active grid cells without product trace")
    counts = collections.Counter(category(row) for row in grid)
    for key in ('validated', 'unavailable', 'unresolved'):
        counts.setdefault(key, 0)
    # Reviewed after the explicitly approved Female / Other overlay. This
    # report must no longer describe the 24 superseded exact-girls targets.
    # Reject changed science before writing anything with outdated prose.
    if {r['country'] for r in grid} != {'NLD'} or dict(counts) != {
            'validated': 2397, 'unavailable': 281, 'unresolved': 0}:
        raise ValueError('Coverage changed: update the reviewed explanations before publishing')
    columns = ["cell_id", "country", "survey", "year", "age", "population_id", "sample_id",
               "domain", "subgroup_variable", "subgroup_level", "statistic",
               "outcome_id", "threshold_id", "peer_environment", "status",
               "hold_reason", "target_contract_sha256", "source_edition_sha256",
               "method_version", "weight_design", "pv_rule", "variance_rule",
               "input_fingerprint", "code_fingerprint", "result_hash", "certification_sha256"]
    cells = [dict({k: row[k] for k in columns},
                  product_requirements=";".join(sorted(trace[row["cell_id"]])))
             for row in sorted(grid, key=lambda x: x["cell_id"])]
    output.mkdir(parents=True, exist_ok=True)
    write(output / "EXACT_CELL_COVERAGE.csv", cells, columns + ["product_requirements"])
    write(output / "MISSING_CELLS.csv", [r for r in cells if r["status"] != "SCIENTIFICALLY_VALIDATED"],
          columns + ["product_requirements"])
    summaries = {}
    for name, keys in [("BY_WAVE", ["country", "survey", "year"]),
                       ("BY_FAMILY", ["subgroup_variable"]),
                       ("BY_EXACT_COMBINATION", ["country", "survey", "year", "age", "domain",
                         "subgroup_variable", "subgroup_level", "statistic", "threshold_id", "peer_environment"])]:
        rows = summarize(grid, keys)
        write(output / (name + ".csv"), rows, keys + ["targets", "validated", "unavailable", "unresolved"])
        summaries[name] = rows
    country_rows = []
    for row in sorted(countries, key=lambda x: x["country"]):
        country_rows.append(dict(row, current_grid_targets=sum(x["country"] == row["country"] for x in grid),
            interpretation="VERIFIED_CURRENT_CORE_ADMISSION" if row["dashboard_eligible"] == "TRUE"
            else "NOT_YET_CERTIFIED_NOT_A_PROVEN_DATA_FAILURE" if row["eligibility_basis"] == "SOURCE_SUPPORT_NOT_YET_VERIFIED"
            else "SEE_EXACT_SUPPORT_EVIDENCE"))
    write(output / "COUNTRY_CANDIDATES.csv", country_rows, list(country_rows[0]))
    # Requirement links are traceability, not proof that a source slide's title
    # is true. Rank rows point to possible parents, not completed derivations.
    write(output / "REQUIREMENT_COVERAGE.csv", requirements, list(requirements[0]))
    manifest = dict(schema_version=1, scope="nld_only", countries_in_grid=sorted({r["country"] for r in grid}),
        targets=len(grid), counts=dict(counts), orphan_cells=0, complete_international_dashboard=False,
        evidence="SAVED_AUDITED_GRID_NOT_A_NEW_SCIENTIFIC_CERTIFICATION",
        source_files={name: sha(state / name) for name in files},
        generator_sha256=sha(Path(__file__)),
        output_files={p.name: sha(p) for p in sorted(output.glob("*.csv"))})
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    text = ["# Resultatengrid: volledige dekking en ontbrekende uitkomsten", "",
        "Dit overzicht is gegenereerd uit het opgeslagen auditgrid. Het telt exacte doelcellen, geen figuren, leerlingen of afzonderlijke R-runs. "
        "De actuele scope is **nld_only**. Productkoppelingen bewijzen herkomst; zij bewijzen niet automatisch een oude slidetitel of paperclaim.", "",
        f"**{len(grid)} doelcellen; {counts['validated']} gecontroleerde uitkomsten; {counts['unavailable']} gedocumenteerd onbeschikbaar; {counts['unresolved']} open.** "
        "Alle doelcellen hebben een productkoppeling. Het volledige internationale dashboard is nog niet gevuld.", "",
        "## Jaren, populaties en domeinen", "",
        "| Bron | Populatie | Domein | Gekozen golven |", "|---|---|---|---|"]
    core = collections.defaultdict(set)
    for row in grid:
        if row["subgroup_variable"] == "core":
            core[(row["survey"], row["domain"])].add(int(row["year"]))
    for (survey, domain), years in sorted(core.items()):
        population = "15-jarigen" if survey == "PISA" else "internationaal vierde leerjaar / Nederlandse groep 6, circa 10 jaar"
        label = {'reading': 'lezen', 'mathematics': 'wiskunde', 'science': 'natuurwetenschappen'}[domain]
        text.append(f"| {survey} | {population} | {label} | {', '.join(map(str, sorted(years)))} |")
    text += ["", "Dit zijn meetgolven, geen jaarlijkse metingen. De 40 domein-jaarcombinaties volgen het vastgelegde Nederlandse anker uit het 21-slide-deck. "
        "Andere historische golven zijn niet automatisch gekozen. Een afwezig jaar buiten dit anker is dus geen bewezen ontbrekende bron. "
        "PISA-wiskunde/lezen beginnen in dit contract in 2003, science in 2006. PIRLS 2021 omvat de officieel vertraagd afgenomen cohort; age10 is een populatieaanduiding, geen exacte individuele leeftijd.", "",
        "## Statistieken en splits", "",
        "De scope is een gekozen familie-matrix, geen kruisproduct van elke statistiek met elke achtergrondgroep. "
        "De exacte combinatie inclusief drempel staat in BY_EXACT_COMBINATION.csv en EXACT_CELL_COVERAGE.csv.", "",
        "- Landelijk totaal: gemiddelde, aandeel onder basisniveau, aandeel hoog/gevorderd, P10, mediaan/P50, P90 en P90−P10.",
        "- SES: nationaal Q1 en Q4, hun gemiddelden en Q4−Q1, onder basisniveau naar Q1/Q4; hoog/gevorderd naar Q1/Q4 alleen appendix (A02). "
        "IEA gebruikt boekenkwartielen in alle gekozen golven; PISA de gekozen Cobreros-harmonisatie uitsluitend 2015, 2018, 2022 en 2025. Dit is niet hetzelfde als officiële ESCS. "
        "Oudere PISA-SES-jaren zijn niet stilzwijgend toegevoegd. De opgeslagen historische q1_basic/q4_basic zijn het complement; de productexport zet ze om naar onder basisniveau met behoud van SE.",
        "- Geslacht: gemiddelde meisjes, gemiddelde jongens en meisjes−jongens. Geen automatisch toegevoegde staartaandelen voor elke geslachtsgroep.",
        "- Thuistaal: IEA altijd/bijna altijd tegenover soms/nooit, PISA toetstaal thuis tegenover andere taal; groepsgemiddelden en kloof. Deze constructen blijven onderscheiden.",
        "- Migratie: twee aparte oudergeboortelanddefinities (ten minste één ouder buiten testland; beide ouders buiten testland), elk groepsgemiddelden en kloof. "
        "Daarnaast native/eerste/tweede generatie en eerste−native/tweede−native.",
        "- Peercompositie, steeds zelf uitgesloten: Q1 met Q4-peers en Q4 met Q1-peers; minder frequente/andere thuistaal met referentietaalpeers; "
        "migratiegroepen met referentie/native peers. Nationale compositie-baselines horen bij de interpretatie en zijn niet nog een aparte peeruitkomst.",
        "- Prestatiepeers: aandeel onder basisniveau voor alle leerlingen, zelf onder basisniveau en zelf minstens basisniveau (A01); "
        "aandeel hoog/gevorderde peers voor zelf hoog en zelf niet hoog (A03). Per domein en voor beide leeromgevingen.",
        "- Leeromgevingen: directe omgeving is bij IEA de klas binnen de school en bij PISA school×programma; daarnaast gehele school. PISA school×programma is geen geobserveerde klas.",
        "- Appendix: SES×geslacht (Q1/Q4 × meisje/jongen; gemiddelde, onder basisniveau, hoog), officiële IEA Home-SES (lower/middle/higher, dezelfde drie uitkomsten). "
        "Home-SES is uitsluitend voor PIRLS 2021 in Nederland beschikbaar; responsselectiviteit blijft zichtbaar.",
        "- Wetenschappelijke uitbreiding: aandeel prestatievariantie tussen scholen en, waar werkelijk vergelijkbaar, klassen; SES-variantie tussen scholen, klasvariantie SES alleen appendix. "
        "domain=all betekent achtergrondcompositie/SES-variantie en is geen vierde prestatiedomein.", "",
        "Alle geselecteerde IEA-staarten gebruiken <475 en ≥625; 550 is hier niet gekozen. PISA gebruikt <niveau 2 en ≥niveau 5: "
        "lezen 407,47 / 625,61; wiskunde 420,07 / 606,99; science 409,54 / 633,33. Er zijn dus twee afkappunten met een middengroep. "
        "Onder basisniveau en hoog zijn geen complementen.", "",
        "| Familie in code | Doelcellen | Gecontroleerd | Onbeschikbaar | Open |", "|---|---:|---:|---:|---:|"]
    for row in summaries["BY_FAMILY"]:
        text.append("| " + " | ".join(str(row[k]) for k in ["subgroup_variable", "targets", "validated", "unavailable", "unresolved"]) + " |")
    text += ["", "## Dekking per golf", "", "| Bron | Jaar | Doelcellen | Gecontroleerd | Onbeschikbaar | Open |", "|---|---:|---:|---:|---:|---:|"]
    for row in summaries["BY_WAVE"]:
        text.append("| " + " | ".join(str(row[k]) for k in ["survey", "year", "targets", "validated", "unavailable", "unresolved"]) + " |")
    text += ["", "## Waarom 281 doelcellen geen uitkomst hebben", "",
        "| Oorzaak | Cellen | Gevolg vanuit de gekozen regels |", "|---|---:|---|",
        "| Officiële Home-SES bestaat nog niet als gekozen construct: PIRLS 2001/2006/2011/2016; TIMSS 2003/2007/2011/2015/2019 | 126 | Geen oudere Home Resources-schaal aan de nieuwe Home-SES-reeks plakken. |",
        "| TIMSS 2023: Nederlandse Home Questionnaire niet afgenomen | 18 | Geen officiële Home-SES uit niet-geobserveerde ouderdata maken. |",
        "| Onvoldoende oudergeboortelandvelden: PIRLS 2011/2016/2021, TIMSS 2011 | 103 | Geen migratiegeneraties of ouderdefinities gokken; dit raakt ook peers en baselines. |",
        "| Geen feitelijke PISA-klasidentificatie | 27 | 23 prestatie- en 4 SES-klasvarianties niet vervangen door school×programma. Schooluitkomsten blijven beschikbaar. |",
        "| PIRLS 2006 heeft always/sometimes/never, niet de gekozen always-or-almost-categorie | 7 | Geen ongemerkte categorie- of constructwissel voor taal en taalpeers. |",
        "", "De 281 onbeschikbare cellen blijven als gedocumenteerde doelen in het grid. De 24 eerder open geslachtscellen zijn na expliciete toestemming vervangen door de brongetrouwe categorie Meisjes + other, met nieuwe celidentiteiten en onafhankelijke certificering. "
        "PIRLS 2021 Home-SES heeft 9 uitkomsten op 2.031 van 4.313 leerlingen; gewogen dekking 47,7027%. Geen claim van volledige ouderrespons.", "",
        "## Landen en productieopties", "",
        "Dit rapport beschrijft uitsluitend het Nederlandse grid. Internationale productie is eveneens goedgekeurd; haar voortgang moet uit de afzonderlijke all_required-uitvoer worden gelezen. "
        "Nederland voldoet voor de kern aan minstens drie geldige golven in elk van zes leeftijd-domeincombinaties. "
        "Dat certificeert niet automatisch alle splits of referentiegroepen.", "",
        "De rijke kandidaten zijn hieronder herkenbaar. Rijk is geen toelatingsbewijs. Voor de Nederlandse standaard moeten kandidaten het volledige 40-combinatie-anker én de samen vergeleken groepen/peerconstructen dekken. "
        "Voor een ander hoofdland geldt diens volledige passende dekking. Er worden geen jaren of groepen ingekort en geen vaste aantallen geforceerd.", "",
        "- nld_only: uitsluitend goedgekeurde Nederlandse cellen.",
        "- nld_plus_19: Nederland plus goedgekeurde, brongetoetste leden van de rijke kandidaatpool; de naam garandeert geen 19.",
        "- all_required: die pool plus andere goedgekeurde, toegelaten landen. Zoeken buiten COMMON42 blijft vereist; deze catalogus is geen volledige wereldinventaris.", "",
        "| Code | Land/stelsel | Rijke kandidaat | Huidig bewijs |", "|---|---|---|---|"]
    for row in country_rows:
        status = "Kerntoelating geverifieerd; resultaatdekking apart toetsen" if row["dashboard_eligible"] == "TRUE" else row["interpretation"]
        text.append(f"| {row['country']} | {row['country_name_en']} | {'ja' if row['rich_candidate']=='TRUE' else 'nee'} | {status} |")
    text += ["", "Lees dashboard_eligible samen met eligibility_basis: ontbrekend verificatiebewijs is iets anders dan aangetoonde ontoereikende dekking. "
        f"Alle {len(country_rows)} catalogusrecords staan in COUNTRY_CANDIDATES.csv; {sum(r['dashboard_eligible']=='TRUE' for r in country_rows)} voldoen aan de opgeslagen brontoelating. Dit certificeert nog geen internationale figuur of referentie.", "",
        "## Zit alles voor het dashboard in het grid?", "",
        "**De gekozen Nederlandse primitieve families staan erin; alle internationale dashboarduitkomsten nog niet.** "
        "Naast de genoemde gaten ontbreken gecertificeerde buitenlandse reeksen, de definitieve gebalanceerde referentieleden per vergelijking, "
        "en de werkelijke afgeleide referentiegemiddelden/rangtijdsreeksen met oudercellen en gekozen leden. "
        "De registratie van kandidaat-ouders voor A09 is geen voltooide rangberekening. De vijfkeuzebediening, referentie- en rangafleiding zijn geïmplementeerd en getest; volledige productvrijgave vereist de gecontroleerde R-uitvoer en vrijgavebewijzen.", "",
        "De gebruiker bouwt één figuur met jaren op de x-as. De rang van het hoofdland is relatief tot de gekozen internationale referentiegroep; "
        "die groep wordt niet als ranglijn geplot. Eventueel komt er één ander individueel land naast. Een ranglijst hoort alleen in de paper. "
        "Bij gewone vergelijkingen wegen referentielanden gelijk en blijft het hoofdland buiten zijn referentie; geen SE/CI op de samengestelde referentielijn.", "",
        "Een complete kernreeks maakt een onvolledige split niet vergelijkbaar. Een combinatie met ontbrekende groepen/jaren moet zichtbaar onbeschikbaar zijn; "
        "geen stilzwijgende verkorting. De toegestane dashboardkeuzes zijn de goedgekeurde families, niet iedere mogelijke statistiek×split. "
        "Appendix- en wetenschappelijke uitbreidingen worden niet vanzelf dashboardopties.", "",
        "## Bewust buiten de berekenvoorraad", "",
        "A05 internationale absolute SES, A07 taal×migratie en A08 oude historische rangpanels zijn afgewezen. "
        "A10 leeftijd/cohortuitbreidingen en A15/A16 Theil-H zijn uitgesteld. A17 geeft alleen toestemming voor noodzakelijke, vooraf gekozen paperclaims, "
        "niet voor een massale reeks trendtoetsen. Het losse complementfiguurtype is geschrapt. Oude 13-/32-/45-landenpanels, alle 79.448 historische keys "
        "en het hele 50-slide-deck zijn geen productieopdracht. Q01–Q08 en paperclaims vragen afzonderlijk bewijs; producttrace alleen sluit ze niet af.", "",
        "## Meisjes bij PISA en herkomst", "",
        "De resolver gebruikt ST004D01T met labelcontrole én Female=1 / Male=2. ST004 en de gedocumenteerde ST004D01D zijn expliciete fallbacks; "
        "tegenstrijdige gevulde velden stoppen de run. Codes 95–99 en ontbrekend blijven ontbrekend. De expliciet goedgekeurde Female / Other-pooling gebruikt uitsluitend gecontroleerde broncodes en krijgt een eigen definitie en label; zij wordt nooit voorgesteld als afzonderlijk geobserveerde meisjes. "
        "De onafhankelijke referentie-implementatie controleert dezelfde brondefinitie afzonderlijk. "
        "In de daadwerkelijk gecontroleerde Nederlandse PISA-2025-bron staan alle 6.636 ST004D01T-waarden op 99. "
        "MALE bevat 3.397 jongens, 3.237 Female / Other en 2 ontbrekend. Het label Female=1 bestaat dus, maar er zijn geen records met code 1. "
        "Die tellingen blijven geldig; de nieuwe keuze staat berekening van de gepoolde categorie toe. Zie de actuele scopebesluiten en het poolingbewijs in het reviewregister.", "",
        "De officiële [OECD-database](https://www.oecd.org/en/data/datasets/pisa-2025-database.html) en "
        "[downloadindex](https://webfs.oecd.org/pisa2022/index.html) zijn geraadpleegd. De index biedt voor deze editie de SPSS-studentbron; "
        "er is daar geen afzonderlijke 2025-SAS-studentdownload aangetoond die dit oplost. Dezelfde bron opnieuw downloaden levert geen bewezen nieuwe meisjesinformatie op.", "",
        "De audit heeft lege leeftijd-/populatievelden hersteld vanuit de gekozen surveycontracten. Oude certificaten mogen die metadata niet meer leeg overschrijven. "
        "Dit verandert geen schatting, SE, N, resultaat-hash of oorspronkelijke wetenschappelijke certificering. "
        "Alle resultaatwaarden behouden hun oorspronkelijke bron-, input-, code- en certificaathashes. manifest.json bindt dit overzicht aan exacte auditbestanden en de rapportgenerator.", "",
        "Reproduceren: `python scripts/report_grid_coverage.py --state <private FIXED_PRODUCTION_V1/nld_only> --output 06_pipeline/review_20261013/grid_coverage`. "
        "Voer na gewijzigde scope eerst de bestaande fixed-audit uit; dit rapport berekent of autoriseert geen nieuwe cel.", ""]
    (output / "README.md").write_text("\n".join(text), encoding="utf-8")
    return manifest


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--state", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = build(args.state, args.output)
    print(json.dumps({k: result[k] for k in ["targets", "counts", "orphan_cells", "complete_international_dashboard"]}))
