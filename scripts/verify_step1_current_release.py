"""Recheck the sealed current47 evidence without pupil estimation.

This read-only check compares exact identities and existing scientific proofs.
It cannot install Q approvals, replace results, or certify a fresh replication.
Only the separately reviewed publication-only amendment is allowed to differ
from the frozen scientific runtime. Run from either Windows or Linux.
"""
import argparse
import collections
import csv
import datetime
import gzip
import hashlib
import json
import math
from pathlib import Path

# Explicitly reviewed roots, not hashes learned from an arbitrary replacement
# manifest during this run. A later scientific release needs a new review.
SEALED_ROOTS = {
    "06_pipeline/review_20261013/scientific_review/SCIENTIFIC_REVIEW_MANIFEST.json":
        "c205f624793a9d55fc25ced02540f91466e5e0e78a8b69fe8c801b229c928965",
    "06_pipeline/review_20261013/grid_coverage/manifest.json":
        "9259d38f9f9e176f74571c59a2e517f0a0769402e9121b4614902f64ef3b3a77",
    "04_results/review/all_required/manifest.json":
        "5ab441b3036e794bcbc8e590fe2517619f0c5ed1ddae68e6cdd71593ed465122",
    "06_pipeline/review_20261013/release47_20261020/PUBLICATION_GATE_BINDING_AMENDMENT.json":
        "a838f28aba24100967b7ae402bc537331c367609242f833977c2c68ce864d6b7",
    "06_pipeline/review_20261013/release47_20261020/RELEASE_PHASE_DECISION.json":
        "efa86d2a9ebb4a094f1bbd4d4b22978fd52b19af6e839e324aeecbcc4a456f43",
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(path):
    with path.open("rb") as handle:
        return hashlib.file_digest(handle, "sha256").hexdigest()


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def rows(path):
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rt", encoding="utf-8-sig", newline="") as handle:
        yield from csv.DictReader(handle)


def keyed(records, key="cell_id"):
    result = {}
    for row in records:
        require(row[key] not in result, "Duplicate identity: " + row[key])
        result[row[key]] = row
    return result


def checked_file(root, relative, expected):
    target = (root / relative).resolve()
    require(target.is_relative_to(root.resolve()), "Path outside evidence root")
    require(target.is_file() and sha(target) == expected, "Changed evidence: " + relative)


def check_runtime(repo, bindings, amendment, manifest_sha):
    require(amendment["frozen_public_scientific_manifest_sha256"] == manifest_sha,
            "Amendment belongs to a different scientific review")
    changes = amendment["runtime_changes"]
    require(len(changes) == 1
            and changes[0]["path"] == "06_pipeline/LO_PARTIAL_DASHBOARD_RELEASE.py",
            "Only the reviewed publication gate amendment is allowed")
    change = changes[0]
    found = False
    for entry in bindings:
        expected = entry["sha256"]
        if entry["path"] == change["path"]:
            require(expected == change["before_sha256"], "Wrong amendment predecessor")
            expected = change["after_sha256"]
            found = True
        checked_file(repo, entry["path"], expected)
    require(found, "Amended runtime absent from original review")


def check_identities(identities, coverage, target_status, estimates):
    require(identities.keys() == coverage.keys() == target_status.keys(),
            "Target identity set changed")
    validated = {cid for cid, row in identities.items()
                 if row["status"] == "SCIENTIFICALLY_VALIDATED"}
    require(validated == estimates.keys(), "Missing, extra or unapproved result")
    for cid, identity in identities.items():
        row = coverage[cid]
        require(all(identity[k] == row[k] for k in
                    ("country", "status", "target_contract_sha256", "result_hash")),
                "Changed coverage identity: " + cid)
        require(target_status[cid]["status"] == identity["status"], "Changed saved status: " + cid)
        require(bool(row["main_reason"]), "Missing primary reason: " + cid)
        require((row["main_reason"] == "RESULT_AVAILABLE") == (cid in validated),
                "Availability reason disagrees with result: " + cid)
        if cid not in validated:
            require(identity["status"].startswith("UNAVAILABLE_"), "Unresolved target: " + cid)
            continue
        result = estimates[cid]
        for key in ("country", "target_contract_sha256", "result_hash",
                    "source_edition_sha256", "input_fingerprint", "certification_sha256"):
            require(row[key] == result[key] and bool(result[key]), "Result binding changed: " + cid)
        require(row["code_fingerprint"] == result["producer_fingerprint"],
                "Producer fingerprint changed: " + cid)
        values = [float(result[k]) for k in ("estimate", "standard_error", "n_unweighted")]
        require(all(math.isfinite(v) for v in values)
                and values[1] >= 0 and values[2] > 0, "Invalid result numbers: " + cid)
    return len(validated)


def check_claims(claims, evidence, results, dependencies):
    evidence = keyed(evidence, "claim_id")
    require({r["claim_id"] for r in claims} == evidence.keys(), "Claim register changed")
    wanted = {(r["claim_id"], r[k]) for r in claims
              for k in ("parent_a", "parent_b", "gap_cell") if r.get(k)}
    actual = [(r["claim_id"], r["cell_id"]) for r in dependencies]
    require(len(actual) == len(set(actual)) and set(actual) == wanted, "Claim dependencies changed")
    for dep in dependencies:
        result = results[dep["cell_id"]]
        for src, dest in {
            "result_hash": "result_hash", "target_contract_sha256": "target_contract_sha256",
            "source_sha256": "source_edition_sha256", "input_fingerprint": "input_fingerprint",
            "code_fingerprint": "producer_fingerprint",
        }.items():
            require(dep[src] == result[dest], "Claim source/result binding changed")
    formal = []
    for claim in claims:
        row = evidence[claim["claim_id"]]
        a, b = results[claim["parent_a"]], results[claim["parent_b"]]
        estimate = float(b["estimate"]) - float(a["estimate"])
        require(math.isclose(estimate, float(row["estimate"]), abs_tol=1e-9, rel_tol=0),
                "Claim contrast differs from parents")
        if claim["type"] == "LATEST_SES_GAP":
            gap = results[claim["gap_cell"]]
            se = float(gap["standard_error"])
            covariance = float(row["joint_covariance"])
            variance = float(a["standard_error"]) ** 2 + float(b["standard_error"]) ** 2 - 2 * covariance
            require(math.isclose(se ** 2, variance, abs_tol=1e-8, rel_tol=1e-10),
                    "Joint covariance no longer matches gap variance")
            require(bool(row["joint_array_sha256"]), "Missing joint-array evidence")
        else:
            link = claim["linking_se"] or 0.0
            se = math.sqrt(float(a["standard_error"]) ** 2 + float(b["standard_error"]) ** 2 + link ** 2)
        require(math.isclose(se, float(row["standard_error"]), abs_tol=1e-9, rel_tol=0),
                "Claim SE differs from certified uncertainty")
        require(str(claim["test"]).lower() == row["formal_test"].lower(), "Changed test scope")
        if claim["test"]:
            require(row["survey"] == "PISA" and claim["type"] == "LONG_TERM_MEAN_CHANGE"
                    and claim["linking_se"] > 0, "Unapproved formal test or absent linking uncertainty")
            p_value = math.erfc(abs(estimate / se) / math.sqrt(2))
            require(math.isclose(p_value, float(row["p_value"]), abs_tol=1e-12, rel_tol=1e-8),
                    "Formal p-value mismatch")
            formal.append((p_value, row))
    previous = 0.0
    for i, (p_value, row) in enumerate(sorted(formal, key=lambda x: x[0])):
        previous = max(previous, min(1.0, (len(formal) - i) * p_value))
        require(math.isclose(previous, float(row["p_holm"]), abs_tol=1e-12, rel_tol=1e-8),
                "Holm correction mismatch")
    return {"registered_claims": len(claims), "formal_tests": len(formal),
            "joint_ses_gaps": sum(c["type"] == "LATEST_SES_GAP" for c in claims)}


def verify(repo):
    for name, expected in SEALED_ROOTS.items():
        checked_file(repo, name, expected)
    review = repo / "06_pipeline/review_20261013"
    phase = review / "release47_20261020"
    science = review / "scientific_review"
    coverage_dir = review / "grid_coverage"
    result_dir = repo / "04_results/review/all_required"
    phase_decision = read_json(phase / "RELEASE_PHASE_DECISION.json")
    completion = read_json(phase / "SCIENTIFIC_REVIEW_COMPLETION.json")
    manifest = read_json(science / "SCIENTIFIC_REVIEW_MANIFEST.json")
    manifest_sha = sha(science / "SCIENTIFIC_REVIEW_MANIFEST.json")
    require(manifest_sha == completion["scientific_public_manifest_sha256"],
            "Scientific completion no longer matches review")
    amendment = read_json(phase / "PUBLICATION_GATE_BINDING_AMENDMENT.json")
    check_runtime(repo, manifest["runtime_bindings"], amendment, manifest_sha)
    for name, expected in manifest["outputs"].items():
        checked_file(science, name, expected)
    for name, expected in phase_decision["files"].items():
        checked_file(phase, name, expected)
    cover_manifest = read_json(coverage_dir / "manifest.json")
    require(sha(coverage_dir / "manifest.json") == completion["coverage_manifest_sha256"],
            "Coverage proof changed")
    for name, expected in cover_manifest["outputs"].items():
        checked_file(coverage_dir, name, expected)
    result_manifest = read_json(result_dir / "manifest.json")
    for entry in result_manifest["files"]:
        checked_file(result_dir, entry["file"], entry["sha256"])
    require(result_manifest["audited_input_sha256"]["validated"] == manifest["approval_sha256"],
            "Different approval registry")
    selected = set(phase_decision["current_countries"])
    deferred = set(phase_decision["deferred_countries"])
    require(selected.isdisjoint(deferred)
            and selected == set(result_manifest["configuration"]["selection"]["countries"]),
            "Selected/deferred execution scope mismatch")
    identities = keyed(rows(phase / "CURRENT_TARGET_IDENTITIES.csv.gz"))
    coverage = keyed(rows(coverage_dir / "EXACT_CELL_COVERAGE.csv.gz"))
    targets = keyed(rows(result_dir / "target_status.csv"))
    estimates = keyed(rows(result_dir / "results.csv"))
    valid_n = check_identities(identities, coverage, targets, estimates)
    require({r["country"] for r in coverage.values()} == selected, "Coverage selection mismatch")
    require(len(coverage) == manifest["reviewed_target_count"] == cover_manifest["targets"]
            == completion["targets"] == result_manifest["target_rows"], "Target count mismatch")
    require(valid_n == completion["validated_results"] == result_manifest["validated_rows"],
            "Validated count mismatch")
    reason_counts = collections.Counter(r["main_reason"] for r in coverage.values())
    require(dict(reason_counts) == cover_manifest["main_reasons"], "Missing reasons not disjoint/exhaustive")
    # One logical requirement may have several product/figure placements.
    placement = ("requirement_id", "product", "source_locator", "approved_placement", "figure_id")
    trace = collections.defaultdict(set)
    trace_count = 0
    for row in rows(coverage_dir / "PRODUCT_CELL_TRACE.csv.gz"):
        require(row["cell_id"] in coverage and bool(row["derivation"]), "Orphan product requirement")
        trace[tuple(row[k] for k in placement)].add(row["cell_id"])
        trace_count += 1
    requirements = {}
    for row in rows(coverage_dir / "REQUIREMENT_COVERAGE.csv"):
        key = tuple(row[k] for k in placement)
        require(key not in requirements, "Duplicate requirement placement")
        requirements[key] = row
    require(trace.keys() == requirements.keys(), "Requirement register mismatch")
    require(set().union(*trace.values()) == coverage.keys(), "Target without product placement")
    for key, ids in trace.items():
        req = requirements[key]
        n_valid = sum(i in estimates for i in ids)
        require(len(ids) == int(req["targets"]) and n_valid == int(req["validated"])
                and len(ids) - n_valid == int(req["unavailable"]) and int(req["unresolved"]) == 0,
                "Product coverage counts mismatch: " + repr(key))
    ses_bindings = list(rows(science / "SES_REVIEW_TARGET_BINDINGS.csv.gz"))
    chosen_ses = {"ses_national", "ses_harmonized", "extension_ses_gender",
                  "extension_home_ses", "extension_ses_school", "extension_ses_class"}
    require({r["cell_id"] for r in ses_bindings} ==
            {cid for cid, r in estimates.items() if r["module"] in chosen_ses}, "Q01 scope mismatch")
    for binding in ses_bindings:
        parent = estimates[binding["cell_id"]]
        require(all(binding[k] == parent[k] for k in
                    ("result_hash", "target_contract_sha256", "source_edition_sha256"))
                and float(binding["n_unweighted"]) == float(parent["n_unweighted"]),
                "Q01 reviewed result changed")
    combinations = [r for r in rows(science / "VERIFIED_COUNTRY_COMBINATIONS.csv")
                    if r["country"] in selected]
    for row in combinations:
        years = [x for x in row["years"].split(";") if x]
        require(len(set(years)) == int(row["verified_comparable_cycles"]),
                "Comparable-wave count mismatch")
        require((len(years) >= 3) == (row["combination_pass"].lower() == "true"),
                "Wrong combination admission")
    admitted = {r["country"] for r in combinations if r["combination_pass"].lower() == "true"}
    require(admitted == selected, "Selected country has no qualifying combination")
    # The readable current47 table is a projection, not a new admission rule.
    readable = {}
    for row in rows(phase / "CURRENT47_COMBINATION_COVERAGE.csv"):
        key = (row["country"], row["survey"], row["domain"])
        require(key not in readable, "Duplicate readable combination")
        readable[key] = row
    require(readable.keys() == {(r["country"], r["survey"], r["domain"]) for r in combinations},
            "Readable country table selection changed")
    counts_by_combination = collections.defaultdict(collections.Counter)
    for row in coverage.values():
        counts = counts_by_combination[(row["country"], row["survey"], row["domain"])]
        counts["targets"] += 1
        counts["validated" if row["status"] == "SCIENTIFICALLY_VALIDATED" else "unavailable"] += 1
    for row in combinations:
        key = (row["country"], row["survey"], row["domain"])
        projected = readable[key]
        require(projected["comparable_years"] == row["years"]
                and projected["comparable_waves"] == row["verified_comparable_cycles"]
                and projected["admitted"] == row["combination_pass"],
                "Readable country table differs from verified waves")
        require(all(int(projected[k]) == counts_by_combination[key][k]
                    for k in ("targets", "validated", "unavailable", "unresolved")),
                "Readable country coverage differs from exact cells")
    refs = list(rows(science / "REFERENCE_BY_VIEW.csv"))
    require({r["country"] for r in refs} == selected and len(refs) == completion["reference_views"],
            "Reference view scope mismatch")
    for row in refs:
        eligible = set(filter(None, row["eligible_countries"].split(";")))
        default = set(filter(None, row["default_countries"].split(";")))
        require(eligible <= selected - {row["country"]} and default <= eligible,
                "Reference membership not within the selected non-focus countries")
    for field, name in {
        "actual_reference_verification_sha256": "ACTUAL_FINAL_REFERENCE_VERIFICATION.json",
        "actual_audit_receipt_sha256": "PHASE_AUDIT_RECEIPT.json",
        "scientific_quality_summary_sha256": "SCIENTIFIC_QUALITY_SUMMARY.csv",
    }.items():
        checked_file(phase, name, completion[field])
    claim_check = check_claims(read_json(review / "PAPER_CLAIMS.json")["claims"],
                              rows(science / "PAPER_CLAIM_RESULTS.csv"), estimates,
                              list(rows(science / "PAPER_CLAIM_DEPENDENCIES.csv")))
    support = list(rows(coverage_dir / "ANALYSIS_SUPPORT_RESTRICTIONS.csv"))
    require(len(support) == cover_manifest["analysis_support_restricted_results"],
            "Support restriction count mismatch")
    return {
        "status": "EXISTING_CURRENT47_SCIENTIFIC_EVIDENCE_RECHECKED",
        "checked_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "reviewed_result_commit": manifest["result_basis"],
        "scientific_runtime_files_checked": len(manifest["runtime_bindings"]),
        "allowed_publication_only_changes": amendment["runtime_changes"],
        "scientific_outputs_checked": len(manifest["outputs"]),
        "coverage_outputs_checked": len(cover_manifest["outputs"]),
        "result_files_checked": len(result_manifest["files"]),
        "selected_countries": len(selected),
        "deferred_countries_excluded": len(deferred),
        "target_rows": len(coverage),
        "validated_rows": valid_n,
        "unavailable_rows": len(coverage) - valid_n,
        "valid_zero_estimates": sum(float(r["estimate"]) == 0 for r in estimates.values()),
        "primary_reason_counts": dict(sorted(reason_counts.items())),
        "support_restrictions_separate_from_missingness": len(support),
        "requirements": len(requirements),
        "unique_requirement_ids": len({key[0] for key in requirements}),
        "product_cell_links": trace_count,
        "ses_binding_rows": len(ses_bindings),
        "country_combinations": len(combinations),
        "admitted_country_combinations": sum(r["combination_pass"].lower() == "true" for r in combinations),
        "reference_views": len(refs),
        "reference_status_counts": dict(collections.Counter(r["status"] for r in refs)),
        "paper_claim_numerical_recheck": claim_check,
        "input_sha256": {
            str(p.relative_to(repo)).replace("\\", "/"): sha(p) for p in [
                science / "SCIENTIFIC_REVIEW_MANIFEST.json", coverage_dir / "manifest.json",
                result_dir / "manifest.json", phase / "RELEASE_PHASE_DECISION.json",
                phase / "SCIENTIFIC_REVIEW_COMPLETION.json",
                phase / "PUBLICATION_GATE_BINDING_AMENDMENT.json", review / "PAPER_CLAIMS.json",
                phase / "CURRENT47_COMBINATION_COVERAGE.csv",
            ]
        },
        "verifier_sha256": sha(Path(__file__)),
        "pupil_estimations": 0,
        "scientific_approvals_written": 0,
        "fresh_source_replication_certified": False,
        "limits": "Verifies unchanged sealed evidence and selected aggregate derivations; does not repeat source estimators, re-assess unmeasured nonresponse/invariance, or execute the postponed full fresh-source replication.",
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    report = verify(args.repo.resolve())
    text = json.dumps(report, indent=2, ensure_ascii=False) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
    print(text)
