"""Repair duplicate chains into disjoint stars; never delete or move a file.

Only explicitly supplied project roots are considered. Current byte hashes,
two restored off-C copies, quarantine age and human approval remain separate.
"""
import argparse,csv,json,os
from pathlib import Path

def norm(p):return os.path.normcase(os.path.abspath(p))
def inside(p,roots):
    return any(os.path.commonpath([norm(p),norm(r)])==norm(r) for r in roots)
def repair(rows,roots):
    groups={};excluded=0
    for r in rows:
        a,b=r['target_path'],r['keeper_path'];h=r['expected_sha256']
        if not h or len(h)!=64 or not inside(a,roots) or not inside(b,roots):
            excluded+=1;continue
        key=(h,int(r['expected_size_bytes']))
        groups.setdefault(key,set()).update((a,b))
    out=[];keepers=set()
    for (h,size),paths in sorted(groups.items()):
        paths=sorted(paths,key=lambda p:(len(Path(p).parts),norm(p)))
        keeper=paths[0];keepers.add(norm(keeper))
        for target in paths[1:]:
            out.append(dict(target_path=target,keeper_path=keeper,
                expected_size_bytes=size,expected_sha256=h,
                current_decision='REVIEW_ONLY_CURRENT_HASH_AND_RETENTION_PROOFS_REQUIRED'))
    if keepers & {norm(r['target_path']) for r in out}:
        raise ValueError('Conflicting hash groups: a permanent keeper is a target')
    return out,dict(input_rows=len(rows),excluded_outside_roots_or_without_hash=excluded,
        repaired_targets=len(out),keeper_target_conflicts=0,
        candidate_bytes=sum(r['expected_size_bytes'] for r in out),
        deletion_authorized=False,bytes_freed=0)
def main():
    p=argparse.ArgumentParser();p.add_argument('--input',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--project-root',action='append',required=True)
    a=p.parse_args()
    with a.input.open(encoding='utf-8-sig',newline='') as f:rows=list(csv.DictReader(f))
    rows,report=repair(rows,a.project_root)
    a.output.parent.mkdir(parents=True,exist_ok=True)
    with a.output.open('w',encoding='utf-8',newline='') as f:
        w=csv.DictWriter(f,fieldnames=['target_path','keeper_path','expected_size_bytes',
            'expected_sha256','current_decision']);w.writeheader();w.writerows(rows)
    a.output.with_suffix('.summary.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report))
if __name__=='__main__':main()
