"""Explicit interim publication, authorised by the user on 18 October 2026.

This policy verifies displayed aggregates and their exact missing positions.
It does not certify unfinished paper, slide or clean-room replication gates.
The final-release verifier remains separate and unchanged.
"""
from __future__ import annotations
import hashlib, importlib.util, json, math, re, tempfile, zipfile
from collections import Counter
from pathlib import Path

KIND = "PARTIAL_VERIFIED_RESULTS"
PACKAGE = "replication/learning-outcomes-replication.zip"
FORBIDDEN = {".sav", ".zsav", ".dta", ".rds", ".rda", ".rdata", ".parquet",
             ".sqlite", ".db", ".sas7bdat", ".xls", ".xlsx", ".gz"}

def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()

def fail(message):
    raise ValueError("PARTIAL_RELEASE_HOLD: " + message)

def read(path):
    return json.loads(path.read_text(encoding="utf-8"))

def safe_relative(name):
    p = Path(name)
    return bool(name) and not p.is_absolute() and ".." not in p.parts and ":" not in name and "\\" not in name

def verify_package(path):
    """No opaque archive exemption: inspect every member and its manifest."""
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)) or any(not safe_relative(n) for n in names):
            fail("unsafe replication package member")
        if any(Path(n).suffix.lower() in FORBIDDEN | {".zip"} for n in names):
            fail("source/binary archive in replication package")
        if sum(z.file_size for z in archive.infolist()) > 150_000_000:
            fail("unexpected replication package size")
        manifest = json.loads(archive.read("PACKAGE_MANIFEST.json"))
        files = manifest["files"]
        if set(files) != set(names) - {"PACKAGE_MANIFEST.json"}:
            fail("replication package inventory mismatch")
        for name, digest in files.items():
            if hashlib.sha256(archive.read(name)).hexdigest() != digest:
                fail("replication package hash mismatch")
        for needed in ("README.md", "reproduce_dashboard.py", "START.R", "06_pipeline/RUN.R",
                       "release_inputs/dashboard_cells.csv", "release_inputs/PROVENANCE.json"):
            if needed not in files:
                fail("replication entry point missing " + needed)
        return manifest

def verify(site, certificate):
    cert = read(certificate)
    if cert.get("release_kind") != KIND:
        fail("wrong publication policy")
    for field in ("displayed_cell_validation", "rights_boundary", "scope_decisions",
                  "dashboard_6x3", "static_site_QA", "dashboard_reproduction"):
        if cert.get(field) != "PASS":
            fail("missing evidence " + field)
    if cert.get("authorization") != "USER_2026_10_18_PUBLISH_AVAILABLE_LEAVE_MISSING_OPEN":
        fail("interim publication not authorised")
    # An interim result must never masquerade as scientific completion.
    if cert.get("full_scientific_release") is not False:
        fail("interim release must explicitly remain incomplete")
    mf = site / "BUILD_SHA256_MANIFEST.json"
    if cert.get("candidate_manifest_sha256") != sha(mf):
        fail("candidate manifest changed")
    included = set()
    for entry in read(mf):
        name = entry["path"]
        if not safe_relative(name) or name in included:
            fail("unsafe or duplicate candidate path")
        included.add(name)
        p = site / name
        if p.is_symlink() or not p.resolve().is_relative_to(site.resolve()) or not p.is_file():
            fail("unsafe candidate file")
        if p.suffix.lower() in FORBIDDEN or (p.suffix.lower() == ".zip" and name != PACKAGE):
            fail("forbidden public file")
        if p.stat().st_size != entry["bytes"] or sha(p) != entry["sha256"]:
            fail("candidate bytes changed " + name)
    actual = {p.relative_to(site).as_posix() for p in site.rglob("*") if p.is_file() and p != mf}
    if actual != included:
        fail("extra or omitted candidate files")
    for name in (PACKAGE, "info/nl/index.html", "info/en/index.html", "data/snapshot_provenance.json"):
        if name not in included:
            fail("missing documentation " + name)
    package = verify_package(site / PACKAGE)
    qa = read(site / "GUIDED_QA.json")
    release = qa.get("review_release", {})
    if release.get("kind") != KIND or release.get("full_scientific_release") is not False:
        fail("visible interim status missing")
    evidence = read(site / "data/snapshot_provenance.json")
    if evidence.get("displayed_cell_validation") != "FRESH_SOURCE_CERTIFICATE_HASH_AND_NUMERIC_VERIFICATION":
        fail("displayed results lack fresh validation")
    for key in ("scientific_source_sha256", "country_registry_sha256", "figure_contract_sha256", "scope_decisions_sha256"):
        if not re.fullmatch("[a-f0-9]{64}", qa.get(key, "")) or cert.get(key) != qa[key]:
            fail("unbound source/scope fingerprint " + key)
    if package.get("source_commit") != release.get("source_commit"):
        fail("package code version differs")
    if package["files"]["release_inputs/dashboard_cells.csv"] != qa["scientific_source_sha256"]:
        fail("replication data differs from verified public input")
    countries = read(site / "data/common42.json")
    ids = [c["code"] for c in countries]
    figures = read(site / "data/figure_registry.json")["figures"]
    fids = [f["figure_id"] for f in figures]
    if not ids or len(ids) != len(set(ids)) or sorted(ids) != sorted(cert["eligible_countries"]):
        fail("country scope mismatch")
    if len(fids) != len(set(fids)) or sorted(fids) != sorted(cert["approved_figure_ids"]):
        fail("figure scope mismatch")
    if any(fid.startswith(("TR_BASIC", "TR_POSITION", "GP_SES_HIGH", "extension_")) for fid in fids):
        fail("rejected or appendix-only product in dashboard")
    # Reapply the reviewed product mapping, then compare every public point with
    # its package input, including values, uncertainty, labels and fingerprints.
    spec=importlib.util.spec_from_file_location("partial_builder",Path(__file__).with_name("LO_FINAL_GUIDED_DASHBOARD_BUILD.py"))
    builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
    with zipfile.ZipFile(site/PACKAGE) as archive, tempfile.TemporaryDirectory() as td:
        source=Path(td)/"dashboard_cells.csv"
        source.write_bytes(archive.read("release_inputs/dashboard_cells.csv"))
        expected_rows=builder.product_rows(source,ids,figures)
    expected_by_country={c:[r for r in expected_rows if r["country_id"]=="iso3:"+c] for c in ids}
    refs = read(site / "data/explorer_references.json")
    if refs.get("policy") != "FULL_FOCUS_CORE_PLUS_JOINT_VIEW_SUPPORT_6x3":
        fail("reference policy changed")
    reference_keys = {(v["focus"], v["figure_id"]) for v in refs["figures"]}
    if reference_keys != {(c, f) for c in ids for f in fids} or len(reference_keys) != len(refs["figures"]):
        fail("incomplete reference availability")
    # This interim policy intentionally permits no unproved comparisons. A later
    # release with certified balance uses the full verifier or a reviewed policy.
    for ref in refs["figures"]:
        if (ref["status"] != "COMPARABILITY_PENDING" or ref["eligible_members"] or ref["default_members"]
                or ref.get("evidence_sha256") is not None):
            fail("unverified reference/rank enabled in interim release")
    counts = Counter(); total = 0
    for country in ids:
        rows = read(site / f"data/countries/{country}.json")["records"]
        if rows != expected_by_country[country]:
            fail("public points differ from verified package input")
        av = read(site / f"data/availability/{country}.json")["figures"]
        if len(av) != len(fids) or {a["figure_id"] for a in av} != set(fids):
            fail("missing figure availability")
        available = {a["figure_id"]: a for a in av}
        seen = set()
        for row in rows:
            key = (row["figure_id"], row["year"], row["series_id"])
            if key in seen or row["figure_id"] not in fids:
                fail("duplicate or unapproved public point")
            seen.add(key)
            if row.get("quality_status") != "SCIENTIFICALLY_VALIDATED" or row.get("series_role") != "focus":
                fail("unvalidated or comparator row")
            if row.get("country_id") != "iso3:" + country or not row.get("cell_id"):
                fail("incorrect country or missing cell identity")
            for key in ("input_fingerprint", "code_fingerprint", "result_hash"):
                if not re.fullmatch("[a-fA-F0-9]{64}", row.get(key, "")):
                    fail("missing result provenance")
            for key in ("estimate", "se", "n_unweighted"):
                if not isinstance(row.get(key), (float, int)) or not math.isfinite(row[key]):
                    fail("invalid numeric result")
            if row["se"] < 0 or row["n_unweighted"] < 1:
                fail("invalid uncertainty/sample size")
        for f in figures:
            a = available[f["figure_id"]]
            required = {(int(y), g) for y in f["required_years"].split(";") for g in f["expected_series"].split(";")}
            present = {(r["year"], r["series_id"]) for r in rows if r["figure_id"] == f["figure_id"]}
            missing = {(v["year"], v["series_id"]) for v in a["missing_points"]}
            if not present <= required or missing != required - present or len(missing) != len(a["missing_points"]):
                fail("missing points differ from exact grid")
            state = "VALIDATED" if not missing else "PARTIAL" if present else a["display_state"]
            if state != a["display_state"] or (not present and state not in ("PLACEHOLDER", "UNAVAILABLE")):
                fail("misleading availability status")
            if a["available_points"] != len(present) or a["required_points"] != len(required):
                fail("wrong availability counts")
            counts[state] += 1
        total += len(rows)
        for lang in ("nl", "en"):
            for q in ("trends", "distribution", "gaps", "environment"):
                if not (site / lang / "country" / country / q / "index.html").is_file():
                    fail("missing bilingual route")
    if total != qa["scientific_data_rows"] or dict(counts) != qa["availability_counts"]:
        fail("QA counts differ from actual files")
    if total != evidence["public_dashboard_points"]:
        fail("public result count differs from validation evidence")
    return dict(candidate_manifest_sha256=sha(mf), systems=len(ids), active_figures=len(fids),
                scientific_rows=total, release_kind=KIND,
                release_gate="PASS_PARTIAL_DISPLAY_ONLY_FULL_SCIENCE_INCOMPLETE")
