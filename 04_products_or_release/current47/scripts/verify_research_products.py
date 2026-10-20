"""Verify research products against sealed aggregates, not matching labels alone."""
import argparse
import csv
import hashlib
import json
import math
import zipfile
from collections import defaultdict
from pathlib import Path
import xml.etree.ElementTree as ET

from reproduce_policy_deck import NS, relationships, tag


def sha(path):
    with path.open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def close(a, b, context):
    if not math.isclose(float(a), float(b), rel_tol=0, abs_tol=1e-9):
        raise ValueError(f"Changed product value: {context}: {a} versus {b}")


def verify(repo, products):
    data = products / "data"
    model = read(data / "RESEARCH_PRODUCT_DATA.json")
    tables = read(data / "RESEARCH_TABLES.json")
    lineage = read(data / "PRODUCT_POINT_LINEAGE.json")
    trace = read(products / "deck/POLICY_DECK_TRACE.json")
    paper = read(products / "paper/PAPER_PRODUCT_TRACE.json")
    assert trace["provenance"] == model["provenance"] == lineage["provenance"]
    assert paper["figures_provenance"] == model["provenance"]
    assert paper["provenance"] == tables["provenance"]
    scientific_hash = sha(repo / "06_pipeline/review_20261013/scientific_review/SCIENTIFIC_REVIEW_MANIFEST.json")
    for p in [model["provenance"], tables["provenance"]]:
        assert p["scientific_manifest_sha256"] == scientific_hash
        assert p["result_manifest_sha256"] == sha(repo / "04_results/review/all_required/manifest.json")
    with (repo / "04_results/review/all_required/results.csv").open(encoding="utf-8-sig", newline="") as f:
        results = {r["cell_id"]: r for r in csv.DictReader(f)}
    assert len(results) == 82142
    deps = {(r["product_figure_id"], r["series_id"], int(r["year"])): r
            for r in lineage["dependencies"]}
    assert len(deps) == len(lineage["dependencies"])
    point_count = 0
    for panel in model["panels"]:
        for row in panel["rows"]:
            dependency = deps[(panel["id"], row["series_id"], int(row["year"]))]
            parents = [results[k] for k in dependency["cell_ids"]]
            assert parents
            factor = 100 if parents[0]["unit"] == "proportion" else 1
            complement = panel["id"].startswith("GP_SES_BASIC_")
            expected = sum((1-float(p["estimate"]) if complement else float(p["estimate"])) * factor
                           for p in parents) / len(parents)
            close(row["estimate"], expected, panel["id"])
            if row["series_role"] == "comparator":
                assert len(parents) == len(row["members"]) and "NLD" not in row["members"]
                assert row.get("standard_error") is None and "ci_low" not in row
            else:
                assert len(parents) == 1 and row["cell_id"] == parents[0]["cell_id"]
                close(row["standard_error"], factor * float(parents[0]["standard_error"]), panel["id"] + " SE")
                assert int(row["n_unweighted"]) == int(float(parents[0]["n_unweighted"]))
                close(row["ci_low"], expected - 1.96*float(row["standard_error"]), "lower interval")
                close(row["ci_high"], expected + 1.96*float(row["standard_error"]), "upper interval")
            point_count += 1
    # Rank tables order actual country values on one fixed basis. No group rank.
    rank_count = 0
    for table in model["rankTables"]:
        grouped = defaultdict(list)
        for row in table["rows"]:
            grouped[(row["year"], row.get("parent_series_id"))].append(row)
        rules = table.get("rules", {})
        for rows in grouped.values():
            assert len(rows) == len(table["basis"])
            values = [abs(float(r["source_estimate"])) if rules.get("transform") == "absolute"
                      else float(r["source_estimate"]) for r in rows]
            ascending = rules.get("direction") == "ascending" or rules.get("transform") == "absolute"
            for row, value in zip(rows, values):
                better = sum(v < value if ascending else v > value for v in values)
                equal = sum(v == value for v in values)
                close(row["estimate"], better + (equal+1)/2, "rank with average ties")
                rank_count += 1
    # Native chart caches must match their trace, and every trace value must be
    # an actual product point or its existing pointwise interval endpoint.
    panels = {p["id"]: p for p in model["panels"] + tables["high_ses_panels"]}
    pptx = products / "deck/final/Leerprestaties_beleid_current47.pptx"
    with zipfile.ZipFile(pptx) as z:
        parts = {n: z.read(n) for n in z.namelist()}
    pres = ET.fromstring(parts["ppt/presentation.xml"])
    rels = relationships(parts, "ppt/presentation.xml")
    slide_paths = [rels[s.attrib[tag("r", "id")]] for s in pres.findall("p:sldIdLst/p:sldId", NS)]
    assert len(slide_paths) == len(trace["slides"]) == 22
    charts = coordinates = 0
    for owner, spec in zip(slide_paths, trace["slides"]):
        rels = relationships(parts, owner)
        chart_paths = [rels[c.attrib[tag("r", "id")]] for c in ET.fromstring(parts[owner]).findall(".//c:chart", NS)]
        owned = [p for p in spec["panels"] if p.get("native_series")]
        assert len(chart_paths) == len(owned)
        for chart_path, panel in zip(chart_paths, owned):
            allowed = [r for fid in panel["figure_ids"] for r in panels[fid]["rows"]]
            actual = ET.fromstring(parts[chart_path]).findall(".//c:scatterChart/c:ser", NS)
            assert len(actual) == len(panel["native_series"])
            for series, expected in zip(actual, panel["native_series"]):
                for field, key in [("xVal", "xValues"), ("yVal", "values")]:
                    cached = [float(e.text) for e in series.findall(f"c:{field}//c:pt/c:v", NS)]
                    assert len(cached) == len(expected[key])
                    for a, b in zip(cached, expected[key]):
                        close(a, b, "native PowerPoint cache")
                interval = expected["name"].startswith("95%-interval ")
                for x, y in zip(expected["xValues"], expected["values"]):
                    candidates = [r for r in allowed if float(r["year"]) == x]
                    candidates_y = []
                    for r in candidates:
                        if interval:
                            if r["series_role"] != "comparator" and r.get("standard_error") is not None:
                                candidates_y.extend([float(r["estimate"])-1.96*float(r["standard_error"]),
                                                     float(r["estimate"])+1.96*float(r["standard_error"])])
                        else:
                            candidates_y.append(float(r["estimate"]))
                    assert any(math.isclose(y, v, rel_tol=0, abs_tol=1e-9) for v in candidates_y), (spec["slide"], x, y)
                    coordinates += 1
            charts += 1
    assert paper["pdf_sha256"] == sha(products / "paper/Leerprestaties_paper_current47.pdf")
    manuscript = (products / "paper/Leerprestaties_paper_current47.md").read_text(encoding="utf-8")
    for entry in paper["sections"]:
        assert entry.get("claim_id")
        if "table" in entry:
            assert entry["table"] in manuscript
            for row in entry["displayed_rows"]:
                assert "| " + " | ".join(str(v).replace("|", "/") for v in row) + " |" in manuscript
        else:
            assert entry["image_sha256"] == sha(products / "paper/paper_figures" / (entry["figure"] + ".png"))
    claims = tables["claims"]
    assert len(claims) == 12 and sum(c["formal_test"] == "TRUE" for c in claims) == 3
    proof = dict(status="PRODUCT_VALUES_AND_WRITTEN_CLAIMS_VERIFIED",
                 scientific_manifest_sha256=scientific_hash,
                 product_provenance=model["provenance"], figure_contracts=len(model["panels"]),
                 display_points_checked=point_count, country_ranks_checked=rank_count,
                 native_charts_checked=charts, native_chart_coordinates_checked=coordinates,
                 slides=22, registered_paper_claims=12, formal_tests=3,
                 new_formal_tests=0, pupil_estimations=0,
                 original_template_sha256=model["provenance"]["source_deck_sha256"],
                 paper_trace_sha256=sha(products / "paper/PAPER_PRODUCT_TRACE.json"),
                 deck_trace_sha256=sha(products / "deck/POLICY_DECK_TRACE.json"),
                 pptx_sha256=sha(pptx), verifier_sha256=sha(Path(__file__)),
                 scope="Numerical product reconstruction and written Q08 claims; visual and browser QA are separate.")
    output = products / "PRODUCT_VALUES_AND_CLAIMS_REVIEW.json"
    output.write_text(json.dumps(proof, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(proof))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--repo", type=Path, required=True)
    p.add_argument("--products", type=Path, required=True)
    a = p.parse_args()
    verify(a.repo, a.products)
