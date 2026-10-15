"""Exercise real process death, SQLite recovery and kernel locks on Win/Linux."""
import json
from contextlib import closing
import os
from pathlib import Path
import shutil
import signal
import sqlite3
import subprocess
import tempfile
import time


def main():
    rscript = os.environ.get('LO_TEST_RSCRIPT') or shutil.which('Rscript')
    if not rscript:
        raise RuntimeError('Rscript is required; this test must not silently skip')
    fixture = Path('06_pipeline/tests/crash_resume_fixture.R').resolve()
    proofs = []
    for scenario in ('kill_during_estimate', 'kill_during_transaction'):
        with tempfile.TemporaryDirectory(prefix='lo_crash_') as td:
            work = Path(td)
            def command(mode):
                return [rscript, str(fixture), str(work), mode]
            subprocess.run(command('setup'), check=True, capture_output=True, text=True)
            with (work / 'worker.log').open('w', encoding='utf-8') as log:
                worker = subprocess.Popen(command(scenario), stdout=log, stderr=log)
                try:
                    deadline = time.monotonic() + 60
                    while not (work / 'kill.ready').exists():
                        if worker.poll() is not None or time.monotonic() > deadline:
                            raise AssertionError((work / 'worker.log').read_text())
                        time.sleep(0.05)
                    competitor = subprocess.run(command('competitor'), capture_output=True, text=True)
                    assert competitor.returncode != 0
                    assert 'PRODUCTION_WRITER_ALREADY_ACTIVE' in competitor.stderr
                    # Rscript.exe can be a launcher for a separate Rterm.exe.
                    # Kill the PID that holds the lock, not only its launcher.
                    owner_pid = json.loads((work / 'kill.ready').read_text())['pid']
                    os.kill(owner_pid, signal.SIGKILL if os.name != 'nt' else signal.SIGTERM)
                    worker.wait(timeout=15)
                finally:
                    if worker.poll() is None:
                        worker.kill()
                        worker.wait(timeout=15)
            db = work / 'compact' / 'COMPACT_MASTER_GRID.sqlite'
            with closing(sqlite3.connect(db)) as con:
                assert con.execute('pragma integrity_check').fetchone()[0] == 'ok'
                assert con.execute('select cell_id from grid').fetchall() == [('first',)]
                assert con.execute('select count(*) from execution_receipts').fetchone()[0] == 1
            resumed_process = subprocess.run(command('resume'), capture_output=True, text=True)
            assert resumed_process.returncode == 0, resumed_process.stdout + resumed_process.stderr
            resumed = json.loads((work / 'resume.json').read_text())[0]
            assert resumed['new_rows_written'] == 1 and resumed['reused_rows'] == 1, resumed
            subprocess.run(command('again'), check=True, capture_output=True, text=True)
            again = json.loads((work / 'again.json').read_text())[0]
            assert again['new_rows_written'] == 0 and again['reused_rows'] == 2, again
            calls = (work / 'calculations.txt').read_text().splitlines()
            assert calls.count('first') == 1 and calls.count('second') == 2, calls
            with closing(sqlite3.connect(db)) as con:
                assert con.execute('pragma integrity_check').fetchone()[0] == 'ok'
                assert con.execute('select count(*) from grid').fetchone()[0] == 2
                assert con.execute('select count(*) from execution_receipts').fetchone()[0] == 2
            proofs.append(dict(scenario=scenario, committed_rows_preserved=1,
                               uncommitted_rows_recomputed=1, repeated_run_new_rows=0,
                               concurrent_writer_rejected=True, integrity='ok'))
    print(json.dumps(dict(status='PASS', platform=os.name, scenarios=proofs), indent=2))


if __name__ == '__main__':
    main()
