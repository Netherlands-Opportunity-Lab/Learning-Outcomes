"""Actual Git/R regression: a single-branch clone lacks origin/preparation.

No network or credentials. Check explicit ref destinations, repeat execution,
unchanged working results/fetch configuration, and rejection of an unrelated pin.
"""
from pathlib import Path
import json, os, shutil, subprocess, tempfile

REPO=Path(__file__).resolve().parents[2]
GIT=shutil.which('git')
RSCRIPT=os.environ.get('RSCRIPT') or shutil.which('Rscript')
if not GIT or not RSCRIPT:raise SystemExit('Git and Rscript required for this integration test')
def run(args,cwd=None,ok=True):
    p=subprocess.run(args,cwd=cwd,text=True,capture_output=True,encoding='utf-8',errors='replace')
    if ok and p.returncode:raise AssertionError(p.stdout+p.stderr)
    return p
def rquote(value):return json.dumps(str(value).replace('\\','/'))

with tempfile.TemporaryDirectory(prefix='prepared_fetch_') as td:
    base=Path(td);remote=base/'remote.git';seed=base/'seed';checkout=base/'checkout'
    development='feat/development';prepared='codex/prepared'
    run([GIT,'init','--bare',str(remote)])
    run([GIT,'init',str(seed)])
    def sg(*args):return run([GIT,'-C',str(seed),*args]).stdout.strip()
    sg('config','user.name','Fixture');sg('config','user.email','fixture@example.invalid')
    sg('checkout','-b',development)
    (seed/'baseline.txt').write_text('retained source contract\n',encoding='utf-8')
    sg('add','.');sg('commit','-m','baseline');sg('remote','add','origin',remote.as_posix())
    sg('push','origin',development)
    sg('checkout','-b',prepared)
    (seed/'repair.txt').write_text('reviewed\n',encoding='utf-8')
    sg('add','.');sg('commit','-m','repair');expected=sg('rev-parse','HEAD');sg('push','origin',prepared)
    # Another real commit exists remotely, but is not an ancestor of preparation.
    sg('checkout','--orphan','other-history');sg('rm','-rf','.')
    (seed/'other.txt').write_text('unrelated\n',encoding='utf-8')
    sg('add','.');sg('commit','-m','unrelated');unrelated=sg('rev-parse','HEAD');sg('push','origin','other-history')
    run([GIT,'clone','--single-branch','--branch',development,remote.as_posix(),str(checkout)])
    def cg(*args,ok=True):return run([GIT,'-C',str(checkout),*args],ok=ok)
    cg('config','user.name','Fixture');cg('config','user.email','fixture@example.invalid')
    result=checkout/'04_results/review/all_required/results.csv';result.parent.mkdir(parents=True)
    result.write_text('cell,estimate\na,4\n',encoding='utf-8')
    cg('add','.');cg('commit','-m','independent completed results')
    before=cg('rev-parse','HEAD').stdout;fetch_config=cg('config','--get-all','remote.origin.fetch').stdout
    tracking=f'refs/remotes/origin/{prepared}'
    assert cg('show-ref','--verify',tracking,ok=False).returncode
    cg('fetch','origin',development,prepared)
    assert cg('show-ref','--verify',tracking,ok=False).returncode, 'Regression fixture did not reproduce original bug'
    runner=base/'fetch.R'
    runner.write_text('''source(%s)
run <- function(args) {
  output <- suppressWarnings(system2(%s,shQuote(c('-C',%s,args)),stdout=TRUE,stderr=TRUE))
  status <- attr(output,'status')
  if(!is.null(status) && status!=0L)stop(paste(output,collapse='\\n'))
  as.character(output)
}
lo_prepared_fetch(run,%s,%s,commandArgs(TRUE)[1])
cat('PREPARED_FETCH_VERIFIED\\n')
'''%(rquote(REPO/'06_pipeline/LO_PREPARED_FETCH.R'),rquote(GIT),rquote(checkout),rquote(development),rquote(prepared)),encoding='utf-8')
    for _ in range(2):
        p=run([RSCRIPT,'--vanilla',str(runner),expected]);assert 'PREPARED_FETCH_VERIFIED' in p.stdout
        assert cg('rev-parse',tracking).stdout.strip()==expected
        assert cg('rev-parse','HEAD').stdout==before
        assert cg('config','--get-all','remote.origin.fetch').stdout==fetch_config
        assert not cg('status','--porcelain').stdout
        assert result.read_text()=='cell,estimate\na,4\n'
    cg('fetch','origin','other-history')
    assert run([RSCRIPT,'--vanilla',str(runner),unrelated],ok=False).returncode
    assert cg('rev-parse','HEAD').stdout==before
    assert result.read_text()=='cell,estimate\na,4\n'
    print('PASS reproduced missing tracking ref; explicit fetch and second run; unchanged HEAD/results/config; unrelated pin rejected')
