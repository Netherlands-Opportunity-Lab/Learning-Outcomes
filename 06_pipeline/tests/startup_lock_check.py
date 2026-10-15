"""Reject a second bootstrap before Git update; release after real process death."""
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import time

rscript = os.environ.get('LO_TEST_RSCRIPT') or shutil.which('Rscript')
if not rscript:
    raise RuntimeError('Rscript is required')
fixture = Path('06_pipeline/tests/startup_lock_fixture.R').resolve()
for scenario in ('hold', 'legacy'):
    with tempfile.TemporaryDirectory(prefix='lo_startup_') as td:
        work = Path(td)
        def command(mode):
            return [rscript, '--vanilla', str(fixture), str(work), mode]
        with (work / 'worker.log').open('w', encoding='utf-8') as log:
            worker = subprocess.Popen(command(scenario), stdout=log, stderr=log)
            owner = None
            try:
                deadline = time.monotonic() + 60
                while not (work / 'ready.json').exists():
                    if worker.poll() is not None or time.monotonic() > deadline:
                        raise AssertionError((work / 'worker.log').read_text())
                    time.sleep(.05)
                owner = json.loads((work / 'ready.json').read_text())['pid']
                rejected = subprocess.run(command('try'), capture_output=True, text=True)
                assert rejected.returncode != 0, rejected.stdout
                assert 'PRODUCTION_WRITER_ALREADY_ACTIVE' in rejected.stderr, rejected.stderr
                assert not (work / 'checkout-updated').exists()
            finally:
                if owner is not None:
                    os.kill(owner, signal.SIGKILL if os.name != 'nt' else signal.SIGTERM)
                elif worker.poll() is None:
                    worker.kill()
                worker.wait(timeout=15)
        resumed = subprocess.run(command('try'), capture_output=True, text=True)
        assert resumed.returncode == 0, resumed.stdout + resumed.stderr
        assert (work / 'checkout-updated').exists()
        print('PASS bootstrap lock before Git mutation, crash release:', scenario)
