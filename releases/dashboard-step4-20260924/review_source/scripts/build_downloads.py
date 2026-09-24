#!/usr/bin/env python3
from pathlib import Path
import html,json
ROOT=Path(__file__).resolve().parents[1]
e=html.escape
rows=[]
allowed={p.name for p in (ROOT/'source_snapshot').glob('*.csv')}|{p.name for p in (ROOT/'addenda').glob('*.csv')}
for f in sorted(p for p in (ROOT/'data/csv').glob('*.csv') if p.name in allowed):
 rows.append(f'<tr><td><a href="data/csv/{e(f.name)}" download>{e(f.name)}</a></td><td>{f.stat().st_size:,} bytes</td></tr>')
figs=[]
for f in sorted((ROOT/'figures/png').glob('*.png')):
 stem=f.stem
 links=' · '.join(f'<a href="figures/{ext}/{stem}.{ext}" download>{ext.upper()}</a>' for ext in ['png','svg','pdf'] if (ROOT/f'figures/{ext}/{stem}.{ext}').exists())
 csv=ROOT/'figures/plotting_data'/f'{stem}.csv'
 if not csv.exists():csv=ROOT/'figures/plotting_data'/f'{stem}_plotting_data.csv'
 if csv.exists():links+=f' · <a href="{csv.relative_to(ROOT).as_posix()}" download>Data CSV</a>'
 figs.append(f'<article class="card span6"><h3>{e(stem)}</h3><a href="figures/png/{stem}.png"><img style="width:100%;height:auto" loading="lazy" alt="{e(stem)}" src="figures/png/{stem}.png"></a><p>{links}</p></article>')
(ROOT/'downloads.html').write_text('<!doctype html><html lang="nl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Downloads · PISA/PIRLS</title><link rel="stylesheet" href="assets/styles.css"></head><body><main><p><a href="index.html">← Dashboard</a></p><h1>Tabellen, figuren en methoden / Tables, figures and methods</h1><p>Private review · 24-09-2026. Deze downloads behouden de kwaliteitsbeperkingen van hun bron; geen openbare herpublicatievrijgave.</p><p><a href="DASHBOARD_VALIDATION.md">Validatie / Validation</a> · <a href="docs/SCIENTIFIC_BOUNDARIES.md">Methoden / Methods</a> · <a href="docs/PUBLICATION_STATUS.md">Publicatiestatus / Publication status</a></p><div class="grid">'+''.join(figs)+'</div><div class="table-wrap"><table><thead><tr><th>Bestand / File</th><th>Omvang / Size</th></tr></thead><tbody>'+''.join(rows)+'</tbody></table></div></main></body></html>',encoding='utf-8')
(ROOT/'data/json/figures.json').write_text(json.dumps([{'figure_id':p.stem,'png':p.relative_to(ROOT).as_posix()} for p in sorted((ROOT/'figures/png').glob('*.png'))],ensure_ascii=False,indent=2)+'\n')
print(f'Download index: {len(rows)} aggregate tables, {len(figs)} figures')
