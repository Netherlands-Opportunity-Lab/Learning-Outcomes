"""Report saved, audited grid coverage; never calculate or approve statistics.

Usage: python scripts/report_grid_coverage.py --state <private nld_only folder>
       --output 06_pipeline/review_20261013/grid_coverage
Only allowlisted aggregate metadata leave the private state. No pupil data,
local paths, estimates or private certificate contents are copied.
"""
import argparse
import gzip
import io
import collections
import csv
import hashlib
import json
import re
import sys
from pathlib import Path

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'06_pipeline'))
from LO_DASHBOARD_COMPARABILITY import population_review_index, population_review_for


def read(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


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
    if path.suffix == ".gz":
        raw = path.open("wb")
        stream = io.TextIOWrapper(gzip.GzipFile(filename="", fileobj=raw, mode="wb", mtime=0), encoding="utf-8", newline="")
    else:
        raw = None
        stream = path.open("w", encoding="utf-8", newline="")
    with stream:
        writer = csv.DictWriter(stream, fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    if raw is not None:
        raw.close()


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


def main_reason(row):
    """One disjoint accounting reason; qualifications belong in other columns."""
    if row["status"] == "SCIENTIFICALLY_VALIDATED":
        return "RESULT_AVAILABLE"
    reason = row.get("hold_reason", "").lower()
    if "official_trend_comparability_qualification" in reason:
        return "OFFICIAL_TREND_NOT_COMPARABLE"
    if "not administered" in reason or "did not administer" in reason:
        return "QUESTIONNAIRE_NOT_ADMINISTERED"
    if "older home resources" in reason or "did not exist" in reason:
        return "SCALE_NOT_DEFINED_IN_CYCLE"
    if row["status"] == "UNAVAILABLE_VERIFIED_ANALYTIC_SAMPLE":
        return "ANALYTIC_GROUP_UNUSABLE"
    if "domain absent or officially invalid" in reason:
        return "DOMAIN_NOT_VALID_IN_SOURCE"
    if "class identifier" in reason or "classroom" in reason or "peer environment" in reason:
        return "LEARNING_ENVIRONMENT_NOT_OBSERVED"
    if "always/sometimes/never" in reason or "always / sometimes / never" in reason:
        return "GROUP_DEFINITION_NOT_OBSERVED"
    if row["status"].startswith("UNAVAILABLE_"):
        return "REQUIRED_FIELD_NOT_OBSERVED"
    if not row.get("source_edition_sha256"):
        return "SOURCE_LINK_MISSING"
    return "VALIDATION_OR_CALCULATION_PENDING"


def project_exact_reuse(grid,links,reuse):
    original={r['cell_id']:r for r in grid};selected={r['cell_id']:r for r in reuse}
    if len(original)!=len(grid) or len(selected)!=len(reuse):raise ValueError('Duplicate reuse/grid target')
    if not selected or not selected.keys()<=original.keys():raise ValueError('Unreviewed projection target')
    if any(r['cell_id'] not in original for r in links):raise ValueError('Uncontracted product link')
    for cid,r in selected.items():
        prior=original[cid]
        if any(r[k]!=prior[k] for k in ['status','target_contract_sha256']) or r['prior_result_hash']!=prior['result_hash']:
            raise ValueError('Changed projected target/status/result')
    return [r for r in grid if r['cell_id'] in selected],[r for r in links if r['cell_id'] in selected]


def build(state, output, review_path=None, trace_state=None, projection_root=None):
    files = ["PRIVATE_MASTER_GRID.csv", "PRIVATE_ACTIVE_PRODUCT_CELL_TRACE.csv",
             "COUNTRY_SOURCE_ELIGIBILITY.csv", "ACTIVE_REQUIREMENT_REGISTER.csv"]
    paths = {name: (trace_state if trace_state and name in
        ["PRIVATE_ACTIVE_PRODUCT_CELL_TRACE.csv", "ACTIVE_REQUIREMENT_REGISTER.csv"] else state) / name for name in files}
    if projection_root:
        paths['PRIVATE_MASTER_GRID.csv']=projection_root.parent/'REVIEWED_MASTER_GRID.csv'
        paths['COUNTRY_SOURCE_ELIGIBILITY.csv']=projection_root/state.name/'COUNTRY_SOURCE_ELIGIBILITY.csv'
    inputs = {name: sha(path) for name, path in paths.items()}
    if projection_root:
        reuse_path=projection_root/(state.name+'_TARGET_REUSE.csv')
        impact_path=projection_root/'COMBINATION_SCOPE_IMPACT.json'
        impact=json.loads(impact_path.read_text(encoding='utf-8'))
        if (impact['historical_review_grid_sha256']!=inputs['PRIVATE_MASTER_GRID.csv'] or
            impact['modes'][state.name]['target_reuse_sha256']!=sha(reuse_path)):
            raise ValueError('Changed scope reuse evidence')
        inputs.update(scope_reuse=sha(reuse_path),scope_impact=sha(impact_path))
    inputs["generator"] = sha(Path(__file__))
    inputs["population_lookup_code"] = sha(Path(__file__).resolve().parents[1]/'06_pipeline/LO_DASHBOARD_COMPARABILITY.py')
    review = json.loads(review_path.read_text(encoding="utf-8-sig")) if review_path else {"corrections": []}
    if review_path:
        inputs["population_review"] = sha(review_path)
    output.mkdir(parents=True, exist_ok=True)
    manifest_path = output / "manifest.json"
    if manifest_path.exists():
        previous = json.loads(manifest_path.read_text(encoding="utf-8"))
        if previous.get("inputs") == inputs and all((output / k).exists() and sha(output / k) == v
                for k, v in previous.get("outputs", {}).items()) and previous.get("outputs"):
            return dict(previous, cache="EXACT_INPUT_AND_OUTPUT_HASH_REUSE")
    grid, links, countries, requirements = [read(paths[name]) for name in files]
    if projection_root:grid,links=project_exact_reuse(grid,links,read(reuse_path))
    by_id = {r["cell_id"]: r for r in grid}
    if len(by_id) != len(grid):
        raise ValueError("Duplicate grid cell")
    if any(not r["age"] or not r["population_id"] for r in grid):
        raise ValueError("Population metadata missing; run updated fixed-audit")
    trace = collections.defaultdict(set)
    product_counts = collections.defaultdict(set)
    exact_links = set()
    for r in links:
        if r["cell_id"] not in by_id:
            raise ValueError("Uncontracted product link")
        trace[r["cell_id"]].add(r["requirement_id"])
        product_counts[(r["requirement_id"], r["product"], r["source_locator"], r.get("approved_placement", ""), r["figure_id"])].add(r["cell_id"])
        exact_links.add(tuple(r.get(k, "") for k in ["requirement_id", "product", "source_locator", "approved_placement", "figure_id", "cell_id", "derivation"]))
    if by_id.keys() - trace.keys():
        raise ValueError("Active grid cells without product trace")
    corrections = population_review_index(review['corrections'])
    counts = collections.Counter(category(r) for r in grid)
    for k in ["validated", "unavailable", "unresolved"]:
        counts.setdefault(k, 0)
    cols = ["cell_id", "country", "survey", "year", "age", "population_id", "sample_id", "domain",
        "subgroup_variable", "subgroup_level", "statistic", "outcome_id", "ses_construct_id", "threshold_id",
        "peer_environment", "peer_target_group", "peer_own_group", "status", "hold_reason", "target_contract_sha256",
        "source_edition_sha256", "method_version", "weight_design", "pv_rule", "variance_rule", "linking_rule",
        "input_fingerprint", "code_fingerprint", "result_hash", "certification_sha256"]
    cells = []
    for r in sorted(grid, key=lambda z: z["cell_id"]):
        correction = population_review_for(corrections,r['country'],r['survey'],r['year'],r['domain'])
        cell = {k: r.get(k, "") for k in cols}
        cell.update(main_reason=main_reason(r), product_requirements=";".join(sorted(trace[r["cell_id"]])),
            population_review_id=correction["review_id"] if correction else "",
            national_use=correction["disposition"] if correction else "NO_REGISTERED_POPULATION_CORRECTION",
            quality_notes=correction["actual_population"] if correction else "SEE_Q02_AND_SOURCE_DOSSIER")
        cells.append(cell)
    extra = ["main_reason", "product_requirements", "population_review_id", "national_use", "quality_notes"]
    write(output / "EXACT_CELL_COVERAGE.csv.gz", cells, cols + extra)
    write(output / "MISSING_CELLS.csv", [r for r in cells if r["main_reason"] != "RESULT_AVAILABLE"], cols + extra)
    write(output / "PRODUCT_CELL_TRACE.csv.gz", [dict(zip(["requirement_id", "product", "source_locator", "approved_placement", "figure_id", "cell_id", "derivation"], r)) for r in sorted(exact_links)],
        ["requirement_id", "product", "source_locator", "approved_placement", "figure_id", "cell_id", "derivation"])
    summaries = {}
    for name, keys in [("BY_COUNTRY", ["country"]), ("BY_WAVE", ["country", "survey", "year", "age", "domain"]),
        ("BY_FAMILY", ["subgroup_variable"]), ("BY_EXACT_COMBINATION", ["country", "survey", "year", "age", "domain", "subgroup_variable", "subgroup_level", "statistic", "threshold_id", "peer_environment"]),
        ("BY_MISSING_REASON", ["main_reason"])]:
        rows = summarize(cells, keys)
        write(output / (name + ".csv"), rows, keys + ["targets", "validated", "unavailable", "unresolved"])
        summaries[name] = rows
    prows = []
    for key, ids in sorted(product_counts.items()):
        c = collections.Counter(category(by_id[i]) for i in ids)
        prows.append(dict(zip(["requirement_id", "product", "source_locator", "approved_placement", "figure_id"], key), targets=len(ids),
            validated=c["validated"], unavailable=c["unavailable"], unresolved=c["unresolved"]))
    write(output / "REQUIREMENT_COVERAGE.csv", prows, ["requirement_id", "product", "source_locator", "approved_placement", "figure_id", "targets", "validated", "unavailable", "unresolved"])
    write(output / "COUNTRY_CANDIDATES.csv", countries, list(countries[0]))
    years = collections.defaultdict(set)
    for r in grid:
        if r["country"] == "NLD" and r["subgroup_variable"] == "core":
            years[(r["survey"], r["age"], r["domain"])].add(int(r["year"]))
    lines = ["# Actuele resultaatdekking", "", f"Scope `{state.name}`: {len(grid):,} doelen; {counts['validated']:,} geregistreerd gevalideerd, {counts['unavailable']:,} gedocumenteerd onbeschikbaar, {counts['unresolved']:,} nog niet afgehandeld.", "",
        "Dit rapport beschrijft de opgeslagen run. Een latere populatiecorrectie staat afzonderlijk bij ieder getroffen doel; historische certificaten worden niet herschreven. Rekenkundige afhandeling is geen wetenschappelijke vrijgave. De landselectie en Q01-Q08 worden afzonderlijk inhoudelijk beoordeeld.", "",
        "## Nederlands jaaranker", "", "| Bron | Populatie | Domein | Meetgolven |", "|---|---|---|---|"]
    for (survey, age, domain), y in sorted(years.items()):
        lines.append(f"| {survey} | {age} | {domain} | {', '.join(map(str, sorted(y)))} |")
    lines += ["", "Meetgolven zijn geen jaarlijkse observaties. Internationaal leerjaar 4 is Nederlandse groep 6; PISA betreft 15-jarigen. Het volledige hoofdlandanker blijft behouden, ook als geen passende referentie bestaat.", "",
        "## Landen", "", "| Land/stelsel | Doelen | Gevalideerd | Onbeschikbaar | Open |", "|---|---:|---:|---:|---:|"]
    for r in summaries["BY_COUNTRY"]:
        lines.append('| ' + ' | '.join(str(r[k]) for k in ["country", "targets", "validated", "unavailable", "unresolved"]) + ' |')
    lines += ["", "COUNTRY_CANDIDATES.csv bewaart de toenmalige toelatingsstand. Nieuwe broncorrecties staan in POPULATION_CORRECTIONS.json en de inhoudelijke landentabel; de historische 34 is geen geforceerde definitieve omvang.", "",
        "## Families", "", "| Familie | Doelen | Gevalideerd | Onbeschikbaar | Open |", "|---|---:|---:|---:|---:|"]
    for r in summaries["BY_FAMILY"]:
        lines.append('| ' + ' | '.join(str(r[k]) for k in ["subgroup_variable", "targets", "validated", "unavailable", "unresolved"]) + ' |')
    lines += ["", "De gekozen scope is geen volledig kruisproduct van alle splits en maten. A02/A04/A06 en A14 behouden hun appendixplaatsing; A11/A12/A13 zijn wetenschappelijke uitbreidingen. Geen nieuwe absolute SES, taal x migratie, oude rangpanels, cross-age/cohortanalyse of Theil-H. SCOPE_APPROVALS.csv blijft beslissend.", "",
        "## Onderling uitsluitende hoofdredenen", "", "| Reden | Doelen |", "|---|---:|"]
    for r in summaries["BY_MISSING_REASON"]:
        lines.append(f"| {r['main_reason']} | {r['targets']} |")
    lines += ["", "Deze hoofdredenen tellen precies tot alle doelen op. Niet-afgenomen vragenlijsten zijn iets anders dan niet-geobserveerde velden, niet-bestaande schalen of lege analysegroepen. Een geldige schatting nul blijft RESULT_AVAILABLE. Populatie-, respons-, modus- en vergelijkbaarheidsnotities staan afzonderlijk; ze zijn geen extra ontbrekende cellen.", "",
        "## Volledige herleidbaarheid", "",
        "- BY_WAVE.csv en BY_EXACT_COMBINATION.csv: alle landen, leeftijden, domeinen, jaren en splits.",
        "- REQUIREMENT_COVERAGE.csv: product/slide/figuur en aantallen unieke doelcellen.",
        "- PRODUCT_CELL_TRACE.csv.gz: iedere exacte product-celverbinding en geregistreerde afleiding.",
        "- EXACT_CELL_COVERAGE.csv.gz: broneditie, populatie, methode, onzekerheidsregel, bewijs- en codehashes per cel. Schattingen en SE staan in de gepinde 04_results/review/<scope>/results.csv, gekoppeld via cell_id en result_hash.",
        "- MISSING_CELLS.csv: alle onbeschikbare en onafgehandelde doelen; geen doel is verwijderd om deze tabel te maken.", "",
        "Er is pas een definitieve dashboardvergelijking als de toegelaten landen het hele hoofdlandanker en alle gezamenlijk getoonde groepen/leeromgevingen dekken. Gewichten zijn gelijk per land, hoofdland uitgesloten. Rang gebruikt diezelfde vaste groep plus het hoofdland, zonder groepslijn of rang-CI. De tijdelijke available-cases-publicatie vormt geen bewijs van definitieve balans.", "",
        "Herhaal deze generator met dezelfde --state en --output. Alle input- en outputbytes worden gehasht; alleen een exact identieke controle wordt hergebruikt. De generator berekent geen leerlingstatistieken en verleent geen wetenschappelijke goedkeuring.", ""]
    if projection_root:
        lines[4]='Deze dekkingsprojectie past het expliciete besluit van 19 oktober toe op exact dezelfde historische doel- en resultaathashes. Zij is geen nieuwe productierun of resultaatdepositie. Er is geen leerlingstatistiek herberekend. Alleen combinaties met minstens drie vergelijkbare golven zijn opgenomen; het volledige hoofdlandanker en alle gezamenlijke groepen gelden binnen iedere figuur. De aanvullende bronkandidaten blijven afzonderlijk te certificeren.'
    (output / "README.md").write_text("\n".join(lines), encoding="utf-8")
    # Remove only superseded files emitted by this same report, inside output.
    # Original results and audit sources are never deleted or moved.
    for name in ["EXACT_CELL_COVERAGE.csv", "PRODUCT_CELL_TRACE.csv"]:
        stale = output / name
        if stale.exists():
            stale.unlink()
    manifest = dict(schema_version=2, scope=state.name, targets=len(grid), counts=dict(counts),
        report_kind='CURRENT_COMBINATION_SCOPE_EXACT_HISTORICAL_REUSE' if projection_root else 'SAVED_RUN_COVERAGE',
        main_reasons=dict(collections.Counter(r["main_reason"] for r in cells)), orphan_cells=0,
        population_corrected_cells=sum(bool(r["population_review_id"]) for r in cells),
        complete_international_dashboard=False, completion_reason="SCIENTIFIC_AND_REFERENCE_REVIEW_SEPARATE",
        inputs=inputs, outputs={p.name: sha(p) for p in sorted(output.iterdir()) if p.is_file() and p.name != "manifest.json"})
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return dict(manifest, cache="REBUILT")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--state", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--population-review", type=Path)
    parser.add_argument("--trace-state", type=Path, help="Updated exact product trace without copying the immutable result grid")
    parser.add_argument('--projection-root',type=Path,help='Read-only exact target-reuse report; not a new production run')
    args = parser.parse_args()
    result = build(args.state, args.output, args.population_review, args.trace_state,args.projection_root)
    print(json.dumps({k: result[k] for k in ["targets", "counts", "orphan_cells", "population_corrected_cells", "cache"]}))
