"""Explain the frozen rich-country pool and current Dutch mean references.

Read-only scientific audit: no source production, changed admission or new panel.
Use the exact balanced export behind the current release, not a live GDP revision.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path


def read_csv(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_csv(path, rows):
    with path.open("w", encoding="utf-8-sig", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def run(repo, reference_export, public_reference, out):
    audit = repo / "06_pipeline/review_20261013"
    inputs = {
        "income": audit / "VERIFIED_PPP_MEMBERSHIP_2024.csv",
        "combinations": audit / "scientific_review/VERIFIED_COUNTRY_COMBINATIONS.csv",
        "phases": audit / "release47_20261020/COUNTRY_PHASES.csv",
        "qualifications": audit / "POPULATION_CORRECTIONS.json",
        "current_references": audit / "release47_20261020/NLD_CURRENT47_STANDARD_MEAN_REFERENCES.csv",
        "balanced_export": reference_export,
        "public_reference": public_reference,
    }
    income = read_csv(inputs["income"])
    threshold = float(next(r for r in income if r["country"] == "CZE")["gdp_per_capita_ppp_value"])
    rich = {r["country"] for r in income if float(r["gdp_per_capita_ppp_value"]) > threshold}
    assert rich == {r["country"] for r in income if r["strictly_above_czechia"] == "TRUE"}
    phases = {r["country"]: r for r in read_csv(inputs["phases"])}
    combinations = {(r["country"], r["survey"], r["domain"]): r for r in read_csv(inputs["combinations"])}
    corrections = json.loads(inputs["qualifications"].read_text())["corrections"]
    export = json.loads(reference_export.read_text())
    current = {r["figure_id"]: r for r in read_csv(inputs["current_references"])}
    public = {r["figure_id"]: r for r in json.loads(public_reference.read_text())["figures"]}
    assert set(export["rich_candidates"]) == rich
    support = {}
    for cell in export["cells"]:
        # The export's columns 2..16 are the complete canonical balance key.
        key = "|".join(str(x) for x in cell[2:17])
        support.setdefault(cell[1], set()).add(key)
    details, summary = [], []
    for view in export["views"]:
        fid = view["figure_id"]
        if view["focus"] != "NLD" or not fid.startswith("TR_MEAN_"):
            continue
        age, domain = fid.removeprefix("TR_MEAN_").split("_", 1)
        survey = "PISA" if age == "age15" else "PIRLS" if domain == "reading" else "TIMSS"
        required = {export["key_dictionary"][int(i)-1] for i in view["required_keys"]}
        years = {int(y) for y in view["required_years"]}
        options = {r["country"]: r for r in view["options"]}
        members = set(view["default_members"])
        assert members == set(current[fid]["default_countries"].split(";")) == set(public[fid]["default_members"])
        assert members == rich.intersection(r["country"] for r in view["options"] if r["eligible"])
        source_complete = []
        for country in sorted(rich - {"NLD"}):
            combo = combinations[(country, survey, domain)]
            observed = {int(y) for y in combo["years"].split(";") if y}
            missing_source = years - observed
            if not missing_source and combo["combination_pass"] == "TRUE":
                source_complete.append(country)
            option = options.get(country)
            missing = required - support.get(country, set())
            if option:
                assert len(missing) == int(option["missing_cells"]), (country, fid)
            selected = country in export["scope_countries"]
            reason = ("INCLUDED" if country in members else "PRODUCTION_DEFERRED" if not selected
                      else "FEWER_THAN_THREE_COMPARABLE_WAVES" if combo["combination_pass"] != "TRUE"
                      else "INCOMPLETE_FULL_FOCUS_SUPPORT")
            qualifications = [r["review_id"] for r in corrections if r["country"] == country
                and r["survey"] == survey and int(r["year"]) in years
                and r.get("domain", "all") in ("all", domain)]
            details.append(dict(country=country, country_name=phases.get(country, {}).get("name_nl", country),
                figure_id=fid, survey=survey, age_group=age, domain=domain,
                in_current_release=selected, in_default_reference=country in members,
                comparable_waves=int(combo["verified_comparable_cycles"]),
                required_years=";".join(map(str, sorted(years))),
                verified_source_years=combo["years"],
                missing_comparable_source_years=";".join(map(str, sorted(missing_source))),
                missing_current_certified_support_years=";".join(sorted({k.split("|")[3] for k in missing})),
                reason=reason, qualification_ids=";".join(qualifications)))
        summary.append(dict(figure_id=fid, income_pool_including_NLD=len(rich),
            income_candidates_excluding_NLD=len(rich)-1,
            candidates_in_current_release_excluding_NLD=len((rich-{"NLD"}) & set(export["scope_countries"])),
            default_reference_count=len(members), default_countries=";".join(sorted(members)),
            all_eligible_checkbox_countries=len(public[fid]["eligible_members"]),
            source_complete_rich_candidates_including_deferred=len(source_complete),
            source_complete_candidates=";".join(source_complete)))
    assert len(summary) == 6 and len(details) == 6 * (len(rich)-1)
    out.mkdir(parents=True, exist_ok=True)
    write_csv(out / "RICH_REFERENCE_CANDIDATES.csv", details)
    write_csv(out / "RICH_REFERENCE_COUNTS.csv", summary)
    receipt = dict(status="CURRENT_MEAN_MEMBERSHIP_EXPLAINED_AND_MATCHED", focus="NLD",
        income_rule="OECD as of 2024-12-31; GDP per capita PPP 2024 strictly above Czechia; pinned snapshot",
        threshold=threshold, income_snapshot_lastupdated=income[0]["source_lastupdated"],
        rich_candidates=sorted(rich), deferred_rich_candidates=sorted(rich-set(export["scope_countries"])),
        checked_country_figure_pairs=len(details), figure_counts=summary,
        source_complete_count_is_not_certified_membership=True,
        notes=["Source coverage, usable certified results and production phase are separate requirements.",
               "Missing support does not establish nonparticipation or physical source unavailability.",
               "No new scientific decision, pupil calculation, shorter anchor or product modification."],
        input_sha256={k:sha(p) for k,p in inputs.items()}, code_sha256=sha(Path(__file__)))
    (out / "RICH_REFERENCE_AUDIT.json").write_text(json.dumps(receipt, indent=2)+"\n", encoding="utf-8")
    print(json.dumps({"status":receipt["status"], "pairs":len(details), "summary":summary}, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("repo", "reference-export", "public-reference", "out"):
        parser.add_argument("--"+name, required=True, type=Path)
    args = parser.parse_args()
    run(args.repo, args.reference_export, args.public_reference, args.out)
