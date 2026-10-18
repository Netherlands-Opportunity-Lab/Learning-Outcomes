"""Reproduce real Windows delete-sharing failures, then resume the same write."""
import ctypes
from ctypes import wintypes
import os
from pathlib import Path
import subprocess
import tempfile
import time

rscript = os.environ.get('RSCRIPT', 'Rscript')
helper = Path('06_pipeline/LO_ATOMIC_CHECKPOINT.R').resolve().as_posix()
with tempfile.TemporaryDirectory(prefix='lo_atomic_sharing_') as directory:
    root = Path(directory)
    target, prepared = root / 'index.rds', root / 'prepared.rds'
    script = root / 'replace.R'
    # Arguments avoid shell interpolation of paths and the R dollar operator.
    script.write_text("a<-commandArgs(TRUE);source(a[1]);lo_atomic_replace(a[2],a[3],attempts=as.integer(a[4]),delay_ms=100L)\n", encoding='utf-8')
    def start(attempts):
        return subprocess.Popen([rscript, str(script), helper, str(prepared), str(target), str(attempts)],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    target.write_bytes(b'old-index')
    prepared.write_bytes(b'new-index')
    if os.name == 'nt':
        kernel = ctypes.WinDLL('kernel32', use_last_error=True)
        kernel.CreateFileW.argtypes = [wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD,
                                      wintypes.LPVOID, wintypes.DWORD, wintypes.DWORD, wintypes.HANDLE]
        kernel.CreateFileW.restype = wintypes.HANDLE
        kernel.CloseHandle.argtypes = [wintypes.HANDLE]
        def hold(path):
            # Allow reads/writes but not deletion/rename, like a Windows reader.
            handle = kernel.CreateFileW(str(path), 0x80000000, 3, None, 3, 0, None)
            assert handle != wintypes.HANDLE(-1).value, ctypes.get_last_error()
            return handle
        handle = hold(target)
        process = start(100)
        try:
            time.sleep(2)
            assert process.poll() is None, process.communicate()
            assert target.read_bytes() == b'old-index'
            assert prepared.read_bytes() == b'new-index'
        finally:
            kernel.CloseHandle(handle)
        stdout, stderr = process.communicate(timeout=25)
        assert process.returncode == 0, (stdout, stderr)
        assert target.read_bytes() == b'new-index'
        assert Path(str(target)+'.previous').read_bytes() == b'old-index'
        # A persistent lock on either the index or the previous backup must
        # fail safely; retrying the exact same prepared bytes must then work.
        for locked_path in (target, Path(str(target)+'.previous')):
            prepared.write_bytes(b'next-index')
            before = target.read_bytes()
            handle = hold(locked_path)
            try:
                process = start(2)
                stdout, stderr = process.communicate(timeout=15)
                assert process.returncode != 0, (stdout, stderr)
                assert target.read_bytes() == before
                assert prepared.read_bytes() == b'next-index'
            finally:
                kernel.CloseHandle(handle)
            process = start(2)
            stdout, stderr = process.communicate(timeout=15)
            assert process.returncode == 0, (stdout, stderr)
            assert target.read_bytes() == b'next-index'
        print('PASS real Windows transient and persistent index/backup locks; old bytes retained and same write resumed')
    else:
        process = start(2)
        stdout, stderr = process.communicate(timeout=15)
        assert process.returncode == 0, (stdout, stderr)
        assert target.read_bytes() == b'new-index' and not prepared.exists()
        print('PASS native atomic checkpoint replacement')
