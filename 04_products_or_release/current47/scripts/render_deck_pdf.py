"""Create the policy-deck PDF from individually reviewed high-resolution renders.

The accompanying PowerPoint remains native/editable. This PDF is an archival
view of exactly those slide renders; it does not alter their data or geometry.
"""
import argparse
import hashlib
import json
from pathlib import Path
from reportlab.pdfgen.canvas import Canvas
from reportlab.lib.utils import ImageReader


def sha(p):
    with p.open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()


def build(root):
    trace = json.loads((root / "POLICY_DECK_TRACE.json").read_text(encoding="utf-8"))
    paths = [root / "renders" / f"slide-{r['slide']:02}.png" for r in trace["slides"]]
    if any(not p.exists() for p in paths):
        raise ValueError("Missing reviewed slide render")
    dest = root / "final" / "Leerprestaties_beleid_current47.pdf"
    pdf = Canvas(str(dest), pagesize=(960, 540), invariant=1)
    pdf.setTitle("Nederlandse leerprestaties — Kansenlab")
    pdf.setAuthor("Kansenlab / Netherlands Opportunity Lab")
    for p in paths:
        pdf.drawImage(ImageReader(str(p)), 0, 0, width=960, height=540)
        pdf.showPage()
    pdf.save()
    (root / "final" / "POLICY_PDF_PROVENANCE.json").write_text(json.dumps({
        "pdf_sha256": sha(dest), "trace_sha256": sha(root / "POLICY_DECK_TRACE.json"),
        "renders": [{"slide": i + 1, "sha256": sha(p)} for i, p in enumerate(paths)],
        "format": "Rendered PDF; editable native charts in accompanying PPTX",
    }, indent=2) + "\n")
    print("POLICY_DECK_PDF_BUILT", len(paths))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path)
    build(parser.parse_args().root)
