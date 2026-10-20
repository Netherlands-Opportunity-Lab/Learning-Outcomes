"""One public entry point: inspect, reconstruct dashboard, or prepare source run.

No route implicitly starts pupil estimation. The source route delegates to the
existing versioned START.R/RUN.R controller only with --run and private settings.
"""
import argparse, collections, csv, hashlib, json, os, subprocess, sys, time
from pathlib import Path

def sha(path):
    with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()

def verify(root):
    manifest=json.loads((root/'PACKAGE_MANIFEST.json').read_text(encoding='utf-8'))
    from public_distribution import check_names
    check_names(manifest['files'])
    for name,expected in manifest['files'].items():
        p=root/name
        if not p.is_file() or p.is_symlink() or sha(p)!=expected:
            raise ValueError('Missing or modified packaged dependency: '+name)
    return manifest

def inspect(root,manifest):
    rd=root/'04_results/review/all_required'
    m=json.loads((rd/'manifest.json').read_text(encoding='utf-8'))
    for row in m['files']:
        if sha(rd/row['file'])!=row['sha256']:raise ValueError('Sealed result changed')
    with (rd/'target_status.csv').open(encoding='utf-8',newline='') as f:
        rows=list(csv.DictReader(f))
    ids=[r['cell_id'] for r in rows]
    if len(ids)!=len(set(ids)):raise ValueError('Duplicate exact target identity')
    counts=collections.Counter(r['status'] for r in rows)
    allowed=set(m['configuration']['selection']['countries'])
    if {i.split('|')[0] for i in ids}!=allowed:raise ValueError('Country scope differs')
    return dict(status='SEALED_RESULTS_AND_PACKAGE_VERIFIED',targets=len(ids),statuses=dict(counts),
        countries=sorted(allowed),package_source_commit=manifest['source_commit'],
        production_identity='Per-cell fingerprints and result_run_links.csv; not the export commit',
        pupil_calculations=0,full_source_replication='DEFERRED_BY_OWNER')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('route',choices=('inspect','dashboard','source'))
    parser.add_argument('--output',type=Path)
    parser.add_argument('--settings',type=Path,help='Private JSON with repository, code_commit, rscript and environment')
    parser.add_argument('--config',default='all_required',choices=('nld_only','nld_plus_19','all_required'))
    parser.add_argument('--run',action='store_true',help='Explicit future source-run request; never implied by inspect/dashboard')
    a=parser.parse_args();root=Path(__file__).resolve().parent;t=time.perf_counter()
    manifest=verify(root)
    if a.route=='inspect':report=inspect(root,manifest)
    elif a.route=='dashboard':
        if a.output is None or a.output.exists():raise ValueError('Provide --output as a new empty path')
        subprocess.run([sys.executable,str(root/'reproduce_dashboard.py'),'--output',str(a.output)],check=True)
        report=dict(status='DASHBOARD_RECONSTRUCTED',pupil_calculations=0)
    else:
        config=root/'replication/config'/f'{a.config}.json'
        if not a.run:
            report=dict(status='SOURCE_ROUTE_DOCUMENTED_NOT_EXECUTED',configuration=str(config.relative_to(root)),
                instructions='replication/ROUTES.md',pupil_calculations=0,
                execution='Use the pinned Git checkout and private source paths; --run delegates to START.R')
        else:
            if a.settings is None:raise ValueError('--settings required for an explicitly requested source run')
            settings=json.loads(a.settings.read_text(encoding='utf-8'))
            repo=Path(settings['repository']).resolve();env=dict(os.environ,**settings['environment'])
            if not (repo/'.git').exists():raise ValueError('Source estimation requires the pinned Git checkout')
            required=('LO_FIXED_ROOT','LO_SOURCE_BINDINGS','LO_COBREROS_ROOT','LO_DRIVE_SYNC_CONFIG')
            if any(not env.get(k) for k in required):raise ValueError('Private source/author/restore bindings incomplete')
            env.update(LO_REPO_ROOT=str(repo),LO_REPRODUCE_COMMIT=settings['code_commit'],
                LO_RUN_CONFIG=str(config),LO_FRESH_REPLICATION='1',LO_START_ACTION='produce-approved',LO_GITHUB_RESULTS='off')
            # START verifies commit, environment, locks and fingerprints. No second science controller.
            subprocess.run([settings.get('rscript','Rscript'),str(repo/'START.R')],env=env,check=True)
            report=dict(status='SOURCE_CONTROLLER_RETURNED_REVIEW_REQUIRED',configuration=a.config)
    report['elapsed_seconds']=round(time.perf_counter()-t,3)
    print(json.dumps(report,indent=2))

if __name__=='__main__':main()
