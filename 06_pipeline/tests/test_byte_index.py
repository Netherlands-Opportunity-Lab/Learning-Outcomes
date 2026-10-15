import hashlib, importlib.util, json, tempfile
from pathlib import Path
spec=importlib.util.spec_from_file_location('byteindex',Path(__file__).resolve().parents[1]/'LO_BUILD_BYTE_INDEX.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
with tempfile.TemporaryDirectory() as d:
    d=Path(d);raw=d/'raw.txt';control=d/'control.sas';out=d/'index.json'
    raw.write_bytes(b'NLD 001\r\nNLD 002\r\nAUS 003\r\nNLD 004\r\n')
    control.write_text('CNT 1-3\nSTUDENT 5-7\n')
    result=module.build_index(raw,control,2003,sha(raw),sha(control),out)
    assert [(b['country'],b['rows']) for b in result['blocks']]==[('NLD',2),('AUS',1),('NLD',1)]
    with raw.open('rb') as f:
        for b in result['blocks']:
            f.seek(b['byte_offset'])
            assert f.readline().startswith(b['country'].encode())
    original=out.read_bytes()
    module.build_index(raw,control,2003,sha(raw),sha(control),out)
    assert out.read_bytes()==original
    before=sha(raw);raw.write_bytes(raw.read_bytes()+b'NLD 005\r\n')
    try:module.build_index(raw,control,2003,before,sha(control),out)
    except ValueError:pass
    else:raise AssertionError('Changed raw input accepted')
    assert out.read_bytes()==original
print('PASS streaming exact byte offsets, repeat reuse, changed-source rejection and retained checkpoint')
