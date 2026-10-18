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
    builder.build(root, inputs, args.output, inputs / "dashboard_cells.csv",
                  country_registry=inputs / "COUNTRY_SOURCE_ELIGIBILITY.csv",
                  scope_decisions=inputs / "SCOPE_APPROVALS.csv")
    expected = json.loads((inputs / "DASHBOARD_REBUILD_MANIFEST.json").read_text(encoding="utf-8"))
    for entry in expected:
        path = args.output / entry["path"]
        if not path.is_file() or digest(path) != entry["sha256"]:
            raise SystemExit("Dashboard reproduction differs: " + entry["path"])
    print(json.dumps({"status": "DASHBOARD_REPRODUCED_BYTE_FOR_BYTE", "files": len(expected),
                      "source_commit": manifest["source_commit"],
                      "pupil_level_replication": "NOT_RUN_SOURCE_ACCESS_AND_RETAINED_BUNDLE_REQUIRED"}))
    print("Preview: python -m http.server 8769 --directory " + str(args.output))

if __name__ == "__main__":
    main()
