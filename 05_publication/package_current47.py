"""Stream a current47 public replication ZIP from explicit reviewed inputs.

No pupil files, private paths, local restore directories or opaque source archives.
The final gate still checks the archive and reconstructs the actual dashboard.
"""
import argparse
import hashlib
import importlib.util
import json
import re
import shutil
import zipfile
from pathlib import Path

from build_release_info import build as build_info


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def put(path, obj):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def package(repo, site, inputs, source_commit, provenance):
    if not re.fullmatch(r"[a-f0-9]{40}", source_commit):
        raise ValueError("Pin a full Git commit")
    target = site / "replication/learning-outcomes-replication.zip"
    if target.exists():
        raise ValueError("Use a fresh release staging directory")
    phase = repo / "06_pipeline/review_20261013/release47_20261020"
    decision = json.loads((phase / "RELEASE_PHASE_DECISION.json").read_text(encoding="utf-8"))
    countries = json.loads((site / "data/common42.json").read_text(encoding="utf-8"))
    if sorted(c["code"] for c in countries) != sorted(decision["current_countries"]):
        raise ValueError("Candidate does not match the explicit current47 decision")
    if (site / "data/reference_policy.json").exists():
        raise ValueError("Current47 products require the reviewed strict references")
    # Save the untouched core build before adding documentation and downloads.
    core_manifest = (site / "BUILD_SHA256_MANIFEST.json").read_bytes()
    files = {}

    def add(path, name=None):
        if not path.is_file() or path.is_symlink():
            raise ValueError("Missing or unsafe public dependency: " + str(path))
        key = name or path.relative_to(repo).as_posix()
        if key in files:
            raise ValueError("Duplicate public dependency: " + key)
        files[key] = path

    for name in ("START.R", "renv.lock", "LICENSE", "DATA_LICENSE.md"):
        add(repo / name)
    add(phase / "CITATION.cff", "CITATION.cff")
    for pattern in ("*.R", "*.py", "*.md", "*.csv", "*.json"):
        for path in sorted((repo / "06_pipeline").glob(pattern)):
            add(path)
    # All these trees are repository-reviewed public dependencies, never private
    # execution roots. Historical raw archives and source data are excluded.
    for directory in ("02_analysis/scientific_dependencies", "05_publication/preview_overlay",
                      "06_pipeline/review_20261013/international",
                      "06_pipeline/review_20261013/release47_20261020",
                      "04_results/review/all_required", "04_products_or_release/current47"):
        for path in sorted((repo / directory).rglob("*")):
            if path.is_file() and "__pycache__" not in path.parts and path.suffix.lower() not in (".gz", ".pyc"):
                add(path)
    for path in sorted((repo / "06_pipeline/archive_or_superseded/LO05_CODE_LOCK_20261010").rglob("*")):
        if path.is_file() and path.suffix.lower() in (".r", ".md", ".csv"):
            add(path)
    for name in ("RANK_PRODUCT_CONTRACT.json", "PAPER_QA_CURRENT.json", "BALANCE_USER_DECISION_20261019.json"):
        add(repo / "06_pipeline/review_20261013" / name)
    # Include the review tables required by prepare_research_tables.py, with
    # their original compressed hashes. Removing them would make the aggregate
    # rebuild depend on an undocumented file outside the downloaded package.
    review = repo / "06_pipeline/review_20261013/scientific_review"
    for path in sorted(review.iterdir()):
        if path.is_file() and (path.suffix.lower() in (".csv", ".json", ".md") or
                              path.name in ("ANALYSIS_SUPPORT.csv.gz", "SES_REVIEW_TARGET_BINDINGS.csv.gz",
                                            "REFERENCE_DEPENDENCIES.csv.gz", "SES_ANALYSIS_SAMPLE_COVERAGE.csv.gz")):
            add(path)
    for name in ("verify_public_raw_probes.R", "verify_final_scientific_candidate.py"):
        add(repo / "scripts" / name)
    for name in ("review_final_availability.py", "build_release_info.py"):
        add(repo / "05_publication" / name)
    add(repo / "05_publication/reproduce_dashboard.py", "reproduce_dashboard.py")
    add(repo / "05_publication/REPLICATION_PACKAGE_README.md", "README.md")
    for name in ("dashboard_cells.csv", "COUNTRY_SOURCE_ELIGIBILITY.csv",
                 "SCOPE_APPROVALS.csv", "FIGURE_SERIES_CONTRACT_20261002.csv"):
        add(inputs / name, "release_inputs/" + name)
    add(site / "data/balanced_references.json", "release_inputs/BALANCED_REFERENCE_EXPORT.json")
    for name in ("EXACT_CELL_COVERAGE.csv.gz", "PRODUCT_CELL_TRACE.csv.gz"):
        add(repo / "06_pipeline/review_20261013/grid_coverage" / name, "release_inputs/" + name)
    generated = {
        "release_inputs/PROVENANCE.json": (json.dumps(provenance, sort_keys=True, indent=2) + "\n").encode(),
        "release_inputs/DASHBOARD_REBUILD_MANIFEST.json": core_manifest,
    }
    if sum(p.stat().st_size for p in files.values()) + sum(map(len, generated.values())) > 750_000_000:
        raise ValueError("Public package exceeds its bounded expanded size")
    private = re.compile(rb"(?:[A-Za-z]:[/\\]+Users[/\\]+(?!<|example|USER|YOUR)[A-Za-z0-9_.-]+|/Users/[A-Za-z0-9_.-]+|-----BEGIN (?:RSA |OPENSSH )?PRIVATE KEY-----)")
    text_suffix = {".r", ".py", ".json", ".csv", ".md", ".html", ".js", ".mjs"}
    for name, path in files.items():
        if path.suffix.lower() in text_suffix:
            with path.open("rb") as stream:
                previous = b""
                while block := stream.read(1024 * 1024):
                    if private.search(previous + block):
                        raise ValueError("Private path or key in public dependency: " + name)
                    previous = block[-256:]
    digests = {name: sha(path) for name, path in sorted(files.items())}
    digests.update({name: hashlib.sha256(data).hexdigest() for name, data in generated.items()})
    manifest = dict(schema_version=2, source_commit=source_commit, pupil_data_included=False,
                    full_scientific_replication_certified=False, selected_countries=47,
                    deferred_countries=36, files=dict(sorted(digests.items())))
    generated["PACKAGE_MANIFEST.json"] = (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode()
    target.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(target, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for name in sorted(set(files) | set(generated)):
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            info.create_system = 3
            if name in generated:
                archive.writestr(info, generated[name])
            else:
                with archive.open(info, "w", force_zip64=True) as dst, files[name].open("rb") as src:
                    shutil.copyfileobj(src, dst, 1024 * 1024)
    build_info(site)
    product = repo / "04_products_or_release/current47"
    (site / "products").mkdir(exist_ok=True)
    for rel in ("deck/final/Leerprestaties_beleid_current47.pptx",
                "deck/final/Leerprestaties_beleid_current47.pdf",
                "paper/Leerprestaties_paper_current47.pdf"):
        shutil.copyfile(product / rel, site / "products" / Path(rel).name)
    put(site / "data/snapshot_provenance.json", provenance)
    qa = json.loads((site / "GUIDED_QA.json").read_text(encoding="utf-8"))
    qa["review_release"] = dict(
        kind="PARTIAL_VERIFIED_RESULTS", date=provenance["snapshot_utc"][:10],
        snapshot_utc=provenance["snapshot_utc"], source_commit=source_commit,
        full_scientific_release=False, scientific_basis_reviewed=True,
        missing_policy="EXACT_REVIEWED_YEAR_GROUP_ABSENCE_NO_INTERPOLATION",
        reference_policy="VERIFIED_FULL_FOCUS_SUPPORT_PER_FIGURE",
        replication_package="replication/learning-outcomes-replication.zip",
        replication_package_sha256=sha(target), replication_package_bytes=target.stat().st_size)
    qa["release_status"] = "CURRENT47_REVIEWED_PRODUCTS_FULL_FRESH_SOURCE_REPLICATION_PENDING"
    put(site / "GUIDED_QA.json", qa)
    spec = importlib.util.spec_from_file_location("public_package", repo / "06_pipeline/LO_DASHBOARD_PUBLIC_PACKAGE.py")
    module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
    module.write_manifest(site)
    return dict(files=len(digests), bytes=target.stat().st_size, sha256=sha(target),
                source_commit=source_commit, pupil_recalculation=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("repo", "site", "inputs", "provenance"):
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--source-commit", required=True)
    a = parser.parse_args()
    print(json.dumps(package(a.repo.resolve(), a.site.resolve(), a.inputs.resolve(), a.source_commit,
                             json.loads(a.provenance.read_text(encoding="utf-8")))))
