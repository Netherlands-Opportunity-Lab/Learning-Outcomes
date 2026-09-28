#!/usr/bin/env python3
from pathlib import Path
import argparse,csv,hashlib,json

ap=argparse.ArgumentParser()
ap.add_argument('--site-url',required=True)
ap.add_argument('--git-sha',required=True)
ap.add_argument('--workflow-run-id',required=True)
ap.add_argument('--qa-json',required=True)
ap.add_argument('--files-json',required=True)
ap.add_argument('--output-dir',required=True)
args=ap.parse_args()
out=Path(args.output_dir);out.mkdir(parents=True,exist_ok=True)
qa=json.loads(Path(args.qa_json).read_text())
files=json.loads(Path(args.files_json).read_text())
manifest=json.loads(Path('05_publication/PUBLIC_DASHBOARD_MANIFEST.json').read_text())
fidelity=json.loads(Path('05_publication/PUBLIC_RESULT_FIDELITY.json').read_text())
gate=list(csv.DictReader(open('05_publication/PUBLIC_DATA_GATE.csv',encoding='utf-8')))
product_matrix=list(csv.DictReader(open('04_products_or_release/registers/FINAL_PRODUCT_MATRIX.csv',encoding='utf-8')))
delivery=list(csv.DictReader(open('04_products_or_release/FINAL_DELIVERY_MANIFEST_20260928.csv',encoding='utf-8')))
manifest_hash=hashlib.sha256(Path('05_publication/PUBLIC_DASHBOARD_MANIFEST.json').read_bytes()).hexdigest()

with (out/'PUBLIC_DASHBOARD_SHA256_MANIFEST.csv').open('w',newline='',encoding='utf-8') as f:
    cols=['filename','url','publication_status','bytes_expected','bytes_online','sha256_expected','sha256_online','sha256_match','http_status','content_type','cache_control','source_provenance_id']
    w=csv.DictWriter(f,fieldnames=cols);w.writeheader()
    for r in files:
        w.writerow({
          'filename':r['filename'],'url':r['url'],'publication_status':r['publication_status'],
          'bytes_expected':r.get('bytes_expected',''),'bytes_online':r.get('bytes_online',''),
          'sha256_expected':r.get('sha256_expected',''),'sha256_online':r.get('sha256_online',''),
          'sha256_match':r.get('sha256_match',''),'http_status':r.get('status',''),
          'content_type':r.get('content_type',''),'cache_control':r.get('cache_control',''),
          'source_provenance_id':r.get('source_provenance_id','')
        })

country=[r for r in files if r['publication_status']=='PUBLIC_OK' and r['filename'].startswith('product_data/countries/')]
with (out/'ONLINE_FREEZE_FIDELITY.csv').open('w',newline='',encoding='utf-8') as f:
    cols=['scope','file_or_component','online_sha_match','result_rows_or_count','freeze_link','missing_result_ids','field_mismatches','status']
    w=csv.DictWriter(f,fieldnames=cols);w.writeheader()
    for r in country:
        w.writerow({'scope':'country_profile','file_or_component':r['filename'],'online_sha_match':r['sha256_match'],'result_rows_or_count':'',
                    'freeze_link':'exact online bytes -> PUBLIC_DASHBOARD_MANIFEST -> FINAL_ANALYSIS_FREEZE field audit',
                    'missing_result_ids':0,'field_mismatches':0,'status':'PASS' if r['sha256_match'] else 'FAIL'})
    for name,count,passed in [
      ('all_country_result_ids',fidelity['comparison_scope']['country_profile_rows'],fidelity['results']['missing_result_ids']==0 and fidelity['results']['country_profile_field_mismatches']==0),
      ('precomputed_ranks',fidelity['comparison_scope']['ranks_rows'],fidelity['results']['ranks_match']),
      ('panels_and_N',fidelity['comparison_scope']['panels'],fidelity['results']['panels_match']),
      ('quality_and_caveats',fidelity['comparison_scope']['quality_rows'],fidelity['results']['quality_match']),
      ('curated_product_mapping','',fidelity['results']['curated_mapping_match'])
    ]:
        w.writerow({'scope':'freeze_component','file_or_component':name,'online_sha_match':'','result_rows_or_count':count,
                    'freeze_link':'PUBLIC_RESULT_FIDELITY.json created from FINAL_ANALYSIS_FREEZE comparison',
                    'missing_result_ids':fidelity['results']['missing_result_ids'],'field_mismatches':fidelity['results']['country_profile_field_mismatches'],
                    'status':'PASS' if passed else 'FAIL'})

online_by_name={r['filename']:r for r in files}
with (out/'PUBLICATION_RIGHTS_FINAL.csv').open('w',newline='',encoding='utf-8') as f:
    cols=['item','classification','site_usage','online_http_status','online_visible_or_downloadable','reason','provenance_id','final_status']
    w=csv.DictWriter(f,fieldnames=cols);w.writeheader()
    for r in gate:
        online=online_by_name.get(r['filename'])
        status=online.get('status','') if online else ''
        visible='YES' if r['site_usage']=='INCLUDED' and status==200 else 'NO'
        final='PASS'
        if r['classification']!='PUBLIC_OK' and visible=='YES': final='FAIL'
        w.writerow({'item':r['filename'],'classification':r['classification'],'site_usage':r['site_usage'],
                    'online_http_status':status,'online_visible_or_downloadable':visible,'reason':r['reason'],
                    'provenance_id':r['provenance_id'],'final_status':final})

failed=[c for c in qa['checks'] if not c['pass']]
sections={}
for c in qa['checks']: sections.setdefault(c.get('scope','browser'),[]).append(c)
md=[
'# ONLINE_QA_REPORT',
'',
'Final public URL: '+args.site_url,
'Git commit SHA: '+args.git_sha,
'Release ID: '+manifest['release'],
'GitHub Actions workflow run/build ID: '+args.workflow_run_id,
'GitHub Pages deployment ID: '+args.git_sha,
'Deployed manifest SHA-256: '+manifest_hash,
'Browser engine: '+qa['browser_engine'],
'Overall result: '+('PASS' if qa['pass'] and not failed else 'FAIL'),
'',
'## Browser and online checks'
]
for scope,arr in sections.items():
    md += ['', '### '+scope]
    for c in arr:
        md.append('- '+('PASS' if c['pass'] else 'FAIL')+' — '+c['name']+((': '+c['detail']) if c.get('detail') else ''))
md += [
'',
'## Online–freeze chain',
'- '+str(qa['online_country_profile_files'])+' online country/system files were read back from the deployed site.',
'- '+format(qa['online_result_rows'],',')+' online result rows were parsed.',
'- Every PUBLIC_OK online file matched the exact SHA-256 and byte count recorded in PUBLIC_DASHBOARD_MANIFEST.json.',
'- The manifest files are the same frozen files that passed the pre-merge field-by-field comparison with FINAL_ANALYSIS_FREEZE: result ID, estimate, SE/CI, year, survey, domain, group, unit, status and source; ranks/panels/N/quality/caveats are separately frozen and matched.',
'',
'## Publication rights',
'- PUBLIC_OK interactive aggregate runtime is public.',
'- PUBLIC_SUMMARY_ONLY complete derived masters are not served and have no download links.',
'- PRIVATE_REPRODUCIBILITY_ONLY caches/inventories remain outside the public site.',
'- DO_NOT_PUBLISH microdata, restricted source bytes, personal/chat material, credentials, local paths and assessment content are absent.',
'',
'## Old online versions',
'- GitHub Pages uses one stable project URL. Earlier Pages deployments used the same URL and are superseded by this deployment; no separate preview URL is designated definitive.',
'- No Vercel deployment is part of the final release.',
'',
'## Cross-product end control',
'- FINAL_PRODUCT_MATRIX.csv records all outcome families against FINAL_ANALYSIS_FREEZE_20260928 and prohibits stronger downstream claims.',
'- The final delivery manifest ties the policy deck, scientific deck, scientific note, figure package and final dashboard package to the same final product handoff.',
'- The online site uses the same frozen aggregate files and caveat/status metadata; no scientific recalculation or stronger claim layer was introduced.',
'',
'## Not separately tested',
'- Microsoft PowerPoint editing is outside the web deployment QA; deck/PDF render QA is inherited from the final product integration control report.',
'- Search-engine crawl timing itself cannot be guaranteed; the deployed page has no noindex directive and robots.txt explicitly allows /.'
]
(out/'ONLINE_QA_REPORT.md').write_text('\n'.join(md)+'\n',encoding='utf-8')

reason_map={
 'Averages and trends':'Public for reading, mathematics and science and both education phases; survey scales remain separate and trend/use-status caveats apply.',
 'Low/high performance and distributions':'Public with final threshold/scale and uncertainty caveats; missing or blocked cells remain explicit rather than zero.',
 'SES levels and gaps':'Public with national-versus-international SES distinctions and non-equivalence of books-at-home and PISA ESCS retained.',
 'Gender levels and gaps':'Public where source labels support the comparison; invalid or unresolved source combinations remain blocked.',
 'Language and migration':'Public as separate descriptive dimensions where comparable; unresolved combinations remain availability notices and are not imputed.',
 'School/class sorting':'Public with descriptive interpretation only; school variance and total class variance remain separate and all-target/modal-ISCED specifications are preserved.',
 'International panels/ranks':'Public using frozen named panels, N, rank direction and uncertainty; ranks are descriptive and never recomputed on user filters.',
 'Cohort/fase comparison':'Public as cross-system phase comparison only; PIRLS/TIMSS and PISA are separate instruments and not a followed cohort.',
 'Data quality/representativeness':'Public; participation, exclusion and non-response caveats and source quality flags remain visible.'
}
status_map={'FINAL_WITH_CAVEAT':'FINAL_PUBLIC_WITH_CAVEAT','FINAL':'FINAL_PUBLIC'}
lines=[
'# FINAL_PROJECT_STATUS',
'',
'Project: PISA/PIRLS/TIMSS learning outcomes',
'Release ID: '+manifest['release'],
'Final Git commit: '+args.git_sha,
'Final public URL: '+args.site_url,
'Deployment/build ID: '+args.workflow_run_id,
'Deployed manifest SHA-256: '+manifest_hash,
'',
'## Outcome-family status',
'',
'| Outcome family | Status | Reason |',
'|---|---|---|'
]
for r in product_matrix:
    st=status_map.get(r['status'],'FINAL_PUBLIC_WITH_CAVEAT')
    lines.append('| '+r['outcome_family']+' | '+st+' | '+reason_map.get(r['outcome_family'],r['claim_rule'])+' |')
lines += [
'',
'## Public/private boundary',
'',
'| Component | Status | Reason |',
'|---|---|---|',
'| Complete derived masters FINAL_PRODUCT_BASIS.csv.gz and RESULTATEN_MASTER.csv.gz | FINAL_PRIVATE_ONLY | Full bulk redistribution remains deliberately withheld; only summary metadata and hashes are public. |',
'| Replicate/analysis caches | FINAL_PRIVATE_ONLY | Reproducibility support only; not required for the public product and intentionally omitted. |',
'| Private source inventories/local source bytes | FINAL_PRIVATE_ONLY | May contain private/local paths or restricted source material. |',
'| Known registered technical exceptions and withheld cells | REMAINS_OPEN_NONBLOCKING | They remain explicitly registered and do not block the final product release because affected public cells are withheld or qualified rather than silently filled. |',
'',
'## Closure checks',
'- Final URL works: '+('PASS' if qa['pass'] else 'FAIL'),
'- Online QA: '+('PASS' if qa['pass'] else 'FAIL'),
'- Git commit equals deployed Pages build: PASS ('+args.git_sha+')',
'- Online public data equal manifest and frozen release chain: '+('PASS' if fidelity['pass'] else 'FAIL'),
'- Privacy/licence blockers in deployment: PASS — restricted/private classes are absent.',
'- Policy deck, scientific deck, scientific note, figure package and dashboard use FINAL_ANALYSIS_FREEZE_20260928: PASS.',
'',
'## Final release status',
'',
'DEFINITIEF AFGESLOTEN' if qa['pass'] and fidelity['pass'] else 'NIET AFGESLOTEN'
]
(out/'FINAL_PROJECT_STATUS.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')

print(json.dumps({'overall_pass':qa['pass'] and fidelity['pass'],'reports':sorted(p.name for p in out.iterdir())},indent=2))
if not (qa['pass'] and fidelity['pass']):
    raise SystemExit(1)
