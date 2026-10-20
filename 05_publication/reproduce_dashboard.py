"""Verify the downloaded package and reconstruct its exact dashboard payloads.

Python 3.11+; standard library only. This does not run pupil-level estimators.
Run from the extracted replication package: python reproduce_dashboard.py
"""
import argparse, hashlib, importlib.util, json
from pathlib import Path

def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("rebuilt_dashboard"))
    args = parser.parse_args()
    root = Path(__file__).resolve().parent
    manifest = json.loads((root / "PACKAGE_MANIFEST.json").read_text(encoding="utf-8"))
    for name, expected in manifest["files"].items():
        path = root / name
        if not path.is_file() or digest(path) != expected:
            raise SystemExit("Changed or missing package file: " + name)
    spec = importlib.util.spec_from_file_location("builder", root / "06_pipeline/LO_FINAL_GUIDED_DASHBOARD_BUILD.py")
    builder = importlib.util.module_from_spec(spec); spec.loader.exec_module(builder)
    inputs = root / "release_inputs"
    balance=inputs/'BALANCED_REFERENCE_EXPORT.json'
    reference_policy=inputs/'REFERENCE_POLICY.json'
    builder.build(root, inputs, args.output, inputs / "dashboard_cells.csv",
                  country_registry=inputs / "COUNTRY_SOURCE_ELIGIBILITY.csv",
                  scope_decisions=inputs / "SCOPE_APPROVALS.csv",
                  balance_export=balance if balance.is_file() else None,
                  reference_policy=reference_policy if reference_policy.is_file() else None)
    coverage=inputs/'EXACT_CELL_COVERAGE.csv.gz'
    trace=inputs/'PRODUCT_CELL_TRACE.csv.gz'
    if coverage.exists() or trace.exists():
        if not coverage.is_file() or not trace.is_file():
            raise SystemExit('Incomplete exact missing-point review inputs')
        spec=importlib.util.spec_from_file_location('availability_review',root/'05_publication/review_final_availability.py')
        availability=importlib.util.module_from_spec(spec);spec.loader.exec_module(availability)
        availability.review(args.output,coverage,trace)
    expected = json.loads((inputs / "DASHBOARD_REBUILD_MANIFEST.json").read_text(encoding="utf-8"))
    for entry in expected:
        path = args.output / entry["path"]
        if not path.is_file() or digest(path) != entry["sha256"]:
            raise SystemExit("Dashboard reproduction differs: " + entry["path"])
    print(json.dumps({"status": "DASHBOARD_REPRODUCED_BYTE_FOR_BYTE", "files": len(expected),
                      "source_commit": manifest["source_commit"],
                      "pupil_level_replication": "NOT_RUN_BY_AGGREGATE_RECONSTRUCTION",
                      "fresh_source_route": "02_analysis/scientific_dependencies/README.md"}))
    print("Preview: python -m http.server 8769 --directory " + str(args.output))

if __name__ == "__main__":
    main()
