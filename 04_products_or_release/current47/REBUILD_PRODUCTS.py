"""Reconstruct the fixed current47 products without reading pupil data."""
import argparse
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path


def sha(path):
    with path.open("rb") as handle:
        return hashlib.file_digest(handle, "sha256").hexdigest()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--output", type=Path, required=True)
    p.add_argument("--render-figures", action="store_true")
    p.add_argument("--rscript", default="Rscript")
    a = p.parse_args()
    product = Path(__file__).resolve().parent
    repo = product.parents[1]
    out = a.output.resolve()
    if out.exists():
        raise ValueError("Use a fresh output directory; existing results are never overwritten")
    manifest = json.loads((product / "PRODUCT_FILE_MANIFEST.json").read_text(encoding="utf-8"))
    for entry in manifest["files"]:
        source = (product / entry["path"]).resolve()
        if not source.is_relative_to(product) or source.is_symlink() or sha(source) != entry["sha256"]:
            raise ValueError("Changed product dependency: " + entry["path"])
    out.mkdir(parents=True)
    shutil.copytree(product / "data", out / "data")
    (out / "deck/final").mkdir(parents=True)
    shutil.copytree(product / "deck/renders", out / "deck/renders")
    shutil.copy2(product / "deck/POLICY_DECK_TRACE.json", out / "deck/POLICY_DECK_TRACE.json")
    if a.render_figures:
        subprocess.run([a.rscript, str(product / "scripts/plot_paper_figures.R"),
                        str(out / "data"), str(product / "fonts"),
                        str(out / "data/paper_figures")], check=True)
    py = sys.executable
    subprocess.run([py, str(product / "scripts/build_paper.py"), "--data", str(out / "data"),
                    "--fonts", str(product / "fonts"), "--out", str(out / "paper")], check=True)
    subprocess.run([py, str(product / "scripts/reproduce_policy_deck.py"),
                    "--template", str(product / "deck/final/Leerprestaties_beleid_current47.pptx"),
                    "--trace", str(out / "deck/POLICY_DECK_TRACE.json"),
                    "--output", str(out / "deck/final/Leerprestaties_beleid_current47.pptx")], check=True)
    subprocess.run([py, str(product / "scripts/render_deck_pdf.py"), str(out / "deck")], check=True)
    subprocess.run([py, str(product / "scripts/verify_research_products.py"),
                    "--repo", str(repo), "--products", str(out)], check=True)
    print("CURRENT47_PRODUCTS_RECONSTRUCTED; no pupil data or new statistics used")


if __name__ == "__main__":
    main()
