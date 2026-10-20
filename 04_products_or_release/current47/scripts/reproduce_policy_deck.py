"""Rebuild native PowerPoint chart data using only public Python dependencies.

The reviewed PPTX supplies layout, approved logos/fonts and narrative text.
POLICY_DECK_TRACE.json supplies exact full-precision series reconstructed from
the certified aggregates. This path needs no private authoring application.
Unexpected chart, series or workbook structure fails rather than guessing.
"""
import argparse
import copy
import hashlib
import io
import json
import math
import posixpath
import re
import zipfile
from pathlib import Path
import xml.etree.ElementTree as ET

import openpyxl

NS = {
    "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
    "c": "http://schemas.openxmlformats.org/drawingml/2006/chart",
    "p": "http://schemas.openxmlformats.org/presentationml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    "rel": "http://schemas.openxmlformats.org/package/2006/relationships",
}
for prefix, uri in NS.items():
    ET.register_namespace(prefix, uri)


def tag(ns, name):
    return "{" + NS[ns] + "}" + name


def digest(path):
    with path.open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()


def relationships(parts, owner):
    rel = posixpath.join(posixpath.dirname(owner), "_rels", posixpath.basename(owner) + ".rels")
    if rel not in parts:
        return {}
    return {
        # OOXML permits package-absolute targets as well as part-relative ones.
        # ZIP member names themselves never begin with a slash.
        r.attrib["Id"]: posixpath.normpath(posixpath.join(posixpath.dirname(owner), r.attrib["Target"])).lstrip("/")
        for r in ET.fromstring(parts[rel])
        if r.attrib.get("TargetMode") != "External"
    }


def update_cache(container, values, kind="num"):
    ref = container.find("c:" + kind + "Ref", NS)
    cache = ref.find("c:" + kind + "Cache", NS) if ref is not None else container.find("c:" + kind + "Lit", NS)
    if cache is None:
        raise ValueError("Unsupported chart cache")
    for child in list(cache):
        if child.tag in [tag("c", "pt"), tag("c", "ptCount")]:
            cache.remove(child)
    ET.SubElement(cache, tag("c", "ptCount"), {"val": str(len(values))})
    for i, value in enumerate(values):
        if kind == "num" and not math.isfinite(float(value)):
            raise ValueError("Nonfinite chart point")
        point = ET.SubElement(cache, tag("c", "pt"), {"idx": str(i)})
        ET.SubElement(point, tag("c", "v")).text = str(value) if kind != "num" else format(float(value), ".17g")
    return ref.findtext("c:f", namespaces=NS) if ref is not None else None


def set_workbook_range(workbook, formula, values):
    if not formula:
        return
    m = re.fullmatch(r"(?:'([^']+)'|([^!]+))!\$([A-Z]+)\$(\d+)(?::\$([A-Z]+)\$(\d+))?", formula)
    if not m:
        raise ValueError("Unsupported chart formula: " + formula)
    sheet, col, first, last_col, last = m.group(1) or m.group(2), m.group(3), int(m.group(4)), m.group(5), m.group(6)
    if sheet not in workbook.sheetnames or last_col not in [None, col] or int(last or first) - first + 1 != len(values):
        raise ValueError("Changed chart data dimensions")
    for i, value in enumerate(values):
        workbook[sheet][f"{col}{first+i}"] = value


def reproduce(template, trace_file, output):
    if output.exists() or output.resolve() == template.resolve():
        raise ValueError("Choose a new output file")
    trace = json.loads(trace_file.read_text(encoding="utf-8"))
    if not trace.get("slides") or not trace.get("provenance"):
        raise ValueError("Missing certified product trace")
    with zipfile.ZipFile(template) as z:
        parts = {name: z.read(name) for name in z.namelist()}
        infos = {info.filename: copy.copy(info) for info in z.infolist()}
    rels = relationships(parts, "ppt/presentation.xml")
    presentation = ET.fromstring(parts["ppt/presentation.xml"])
    slide_paths = [rels[s.attrib[tag("r", "id")]] for s in presentation.findall("p:sldIdLst/p:sldId", NS)]
    if len(slide_paths) != len(trace["slides"]):
        raise ValueError("Slide count differs from reviewed design")
    chart_count = point_count = 0
    for owner, spec in zip(slide_paths, trace["slides"]):
        slide = ET.fromstring(parts[owner])
        rels = relationships(parts, owner)
        charts = [rels[c.attrib[tag("r", "id")]] for c in slide.findall(".//c:chart", NS)]
        panels = [p for p in spec["panels"] if p.get("native_series")]
        if len(charts) != len(panels):
            raise ValueError(f"Native chart count differs on slide {spec['slide']}")
        for chart_path, panel in zip(charts, panels):
            root = ET.fromstring(parts[chart_path])
            series = root.findall(".//c:scatterChart/c:ser", NS)
            if len(series) != len(panel["native_series"]):
                raise ValueError("Series count differs; review the new layout before release")
            external = root.find(".//c:externalData", NS)
            workbook_path = None
            workbook = None
            if external is not None:
                workbook_path = relationships(parts, chart_path)[external.attrib[tag("r", "id")]]
                workbook = openpyxl.load_workbook(io.BytesIO(parts[workbook_path]))
            for actual, expected in zip(series, panel["native_series"]):
                tx = actual.find("c:tx", NS)
                name = tx.find("c:v", NS) if tx is not None else None
                if name is not None:
                    name.text = expected["name"]
                elif tx is not None:
                    formula = update_cache(tx, [expected["name"]], "str")
                    if workbook is not None:
                        set_workbook_range(workbook, formula, [expected["name"]])
                else:
                    raise ValueError("Missing editable series name")
                for field, key in [("xVal", "xValues"), ("yVal", "values")]:
                    formula = update_cache(actual.find("c:" + field, NS), expected[key])
                    if formula and workbook is None:
                        raise ValueError("Workbook reference without embedded workbook")
                    if workbook is not None:
                        set_workbook_range(workbook, formula, expected[key])
                point_count += len(expected["values"])
            parts[chart_path] = ET.tostring(root, encoding="utf-8", xml_declaration=True)
            if workbook is not None:
                buffer = io.BytesIO()
                workbook.save(buffer)
                parts[workbook_path] = buffer.getvalue()
            chart_count += 1
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as z:
        for name, content in parts.items():
            z.writestr(infos[name], content)
    receipt = {
        "status": "NATIVE_CHARTS_REBUILT_FROM_PUBLIC_AGGREGATE_TRACE",
        "template_sha256": digest(template), "trace_sha256": digest(trace_file),
        "output_sha256": digest(output), "charts": chart_count,
        "series_points_including_interval_endpoints": point_count,
        "slides": len(slide_paths), "builder_sha256": digest(Path(__file__)),
        "scope": "Aggregate product reconstruction, not pupil-source estimation",
    }
    output.with_suffix(".rebuild.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps(receipt))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template", type=Path, required=True)
    parser.add_argument("--trace", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    reproduce(args.template, args.trace, args.output)
