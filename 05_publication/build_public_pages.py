from pathlib import Path
import hashlib
import html
import json
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PUB = ROOT / "05_publication"
APP = ROOT / "03_dashboard" / "app"
DOCS = ROOT / "03_dashboard" / "docs"
MANIFEST = PUB / "PUBLIC_DASHBOARD_MANIFEST.json"
BUNDLE = PUB / "public_dashboard_runtime_20260928.zip"
OUT = ROOT / "public_site_dist"

def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest()

def fail(msg):
    raise SystemExit("PUBLIC BUILD FAIL: " + msg)

m = json.loads(MANIFEST.read_text(encoding="utf-8"))
if not BUNDLE.exists():
    fail("missing controlled public runtime ZIP")
if len(BUNDLE.read_bytes()) != m["runtime_transport_bytes"]:
    fail("public runtime ZIP byte-size mismatch")
if sha256_bytes(BUNDLE.read_bytes()) != m["runtime_transport_sha256"]:
    fail("public runtime ZIP SHA-256 mismatch")

expected = {
    r["filename"]: (int(r["bytes"]), r["sha256"].lower())
    for r in m["files"] if r["publication_status"] == "PUBLIC_OK"
}

with zipfile.ZipFile(BUNDLE) as zf:
    files = [n for n in zf.namelist() if not n.endswith("/")]
    if any(Path(n).is_absolute() or ".." in Path(n).parts for n in files):
        fail("unsafe path in runtime ZIP")
    if set(files) != set(expected):
        missing = sorted(set(expected) - set(files))
        extra = sorted(set(files) - set(expected))
        fail(f"runtime inventory mismatch; missing={missing[:10]} extra={extra[:10]}")
    for name in files:
        data = zf.read(name)
        exp_bytes, exp_sha = expected[name]
        if len(data) != exp_bytes:
            fail(f"byte mismatch: {name}")
        if sha256_bytes(data) != exp_sha:
            fail(f"SHA-256 mismatch: {name}")

if OUT.exists():
    shutil.rmtree(OUT)
OUT.mkdir()

shutil.copy2(APP / "index.html", OUT / "index.html")
shutil.copytree(APP / "assets", OUT / "assets")

# Public-only accessibility color correction: the original muted token was
# marginally below WCAG AA for normal text on the page background. This does
# not affect scientific content or data.
styles_path = OUT / "assets" / "styles.css"
styles = styles_path.read_text(encoding="utf-8")
styles = styles.replace("--muted:#63707a", "--muted:#606c75")
styles_path.write_text(styles, encoding="utf-8")
(OUT / "docs").mkdir()
for name in ["SCIENTIFIC_BOUNDARIES.md", "DATA_CONTRACT.md"]:
    shutil.copy2(DOCS / name, OUT / "docs" / name)

with zipfile.ZipFile(BUNDLE) as zf:
    zf.extractall(OUT)

index = (OUT / "index.html").read_text(encoding="utf-8")
index = index.replace("Privéversie · 28-09-2026", "Publieke onderzoeksversie · 28-09-2026")
index = index.replace(
    "Finale productrelease · Lokale caveats blijven zichtbaar",
    "Finale productrelease · Geaggregeerde resultaten · Code en replicatie openbaar",
)
(OUT / "index.html").write_text(index, encoding="utf-8")

public_status = """# Publicatiestatus

Publieke onderzoeksversie van de finale productrelease van 28 september 2026.

De website toont project-berekende geaggregeerde resultaten en project-authored figures. Zij bevat geen leerling- of schoolmicrodata en geen OECD/IEA-bronbestanden.

De complete bulkbestanden FINAL_PRODUCT_BASIS.csv.gz en RESULTATEN_MASTER.csv.gz worden niet als publieke downloads gespiegeld. De publicatiegrens staat in PUBLICATION_RIGHTS_REVIEW.md en PUBLIC_DASHBOARD_MANIFEST.json in de repository.

De wetenschappelijke/product source lock is Git commit 749a0de8e6ab707f4ecd887247ea8fde82f55656. De browser rekent geen wetenschappelijke schattingen, onzekerheid of rangen opnieuw uit.
"""
(OUT / "docs" / "PUBLICATION_STATUS.md").write_text(public_status, encoding="utf-8")
shutil.copy2(PUB / "PUBLICATION_RIGHTS_REVIEW.md", OUT / "docs" / "PUBLICATION_RIGHTS_REVIEW.md")
shutil.copy2(PUB / "REPLICATION_GUIDE.md", OUT / "docs" / "REPLICATION_GUIDE.md")

figs = sorted(p.stem for p in (OUT / "product_figures").glob("G*.svg"))
figure_rows = []
for stem in figs:
    csv_name = f"{stem}_data.csv"
    csv_link = (
        f' · <a href="product_figures/{html.escape(csv_name)}">CSV</a>'
        if (OUT / "product_figures" / csv_name).exists()
        else ""
    )
    figure_rows.append(
        f'<li>{html.escape(stem)}: <a href="product_figures/{html.escape(stem)}.svg">SVG</a>{csv_link}</li>'
    )

downloads = f"""<!doctype html>
<html lang="nl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Gegevens, figuren en replicatie</title><link rel="stylesheet" href="assets/styles.css"></head>
<body><main style="max-width:1050px;margin:auto;padding:32px">
<p><a href="index.html">← Dashboard</a></p>
<h1>Gegevens, figuren en replicatie</h1>
<p>Deze publieke versie is een onderzoeks- en beleidsproduct, geen spiegel van de OECD/IEA-brondatabases. De interactieve pagina gebruikt alleen geaggregeerde projectresultaten. Er staan geen leerling- of schoolmicrodata op deze site.</p>
<h2>Wat kan wel worden gedownload?</h2>
<p>De knop <em>Download getoonde gegevens (CSV)</em> exporteert uitsluitend de geaggregeerde records die op dat moment in de geselecteerde weergave worden gebruikt. Hieronder staan project-authored figures en hun kleine figuurdata.</p>
<ul>{''.join(figure_rows)}</ul>
<h2>Volledige bulkbestanden</h2>
<p>De volledige afgeleide masters <code>FINAL_PRODUCT_BASIS.csv.gz</code> en <code>RESULTATEN_MASTER.csv.gz</code> worden niet als publieke downloads aangeboden zolang de redistributiepositie voor de volledige IEA-afgeleide downloadlaag niet expliciet is bevestigd.</p>
<h2>Volledig reproduceerbare code</h2>
<p>Alle analyse-, dashboard- en publicatiecode staat in de GitHub-repository. Een onafhankelijke onderzoeker kan de officiële OECD/IEA-bronbestanden bij de data-eigenaren ophalen en de analyse opnieuw uitvoeren.</p>
<ul>
<li><a href="https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes">Publieke GitHub-repository</a></li>
<li><a href="docs/REPLICATION_GUIDE.md">Replication guide</a></li>
<li><a href="docs/PUBLICATION_RIGHTS_REVIEW.md">Publicatie- en rechtenafbakening</a></li>
<li><a href="docs/SCIENTIFIC_BOUNDARIES.md">Wetenschappelijke grenzen en definities</a></li>
</ul>
<h2>Bronnen</h2>
<p>PISA: Programme for International Student Assessment (PISA), Organisation for Economic Co-operation and Development (OECD), Paris. PIRLS/TIMSS: International Association for the Evaluation of Educational Achievement (IEA); specifieke studie/cyclusbronnen en DOI's staan in de replicatie- en bronbestanden.</p>
</main></body></html>"""
(OUT / "downloads.html").write_text(downloads, encoding="utf-8")
(OUT / ".nojekyll").write_text("", encoding="utf-8")
(OUT / "robots.txt").write_text("User-agent: *\nAllow: /\n", encoding="utf-8")

print(f"Public Pages build complete: {len(expected)} minimal frozen runtime files.")
