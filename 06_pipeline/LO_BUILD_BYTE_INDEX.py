"""Build a bounded, source-hashed PISA fixed-width index. No pupil statistics."""
import argparse
import hashlib
import json
import os
import re
from pathlib import Path


def build_index(raw, control, year, expected_sha, expected_control_sha, output):
    raw, control, output = map(Path, (raw, control, output))
    control_sha = hashlib.sha256(control.read_bytes()).hexdigest()
    if control_sha != expected_control_sha:
        raise ValueError('PISA_CONTROL_BYTES_CHANGED')
    # SAS is a column dictionary here, never an executable script.
    hit = re.findall(r'^\s*CNT\s+(\d+)\s*-\s*(\d+)\s*;?\s*$',
                     control.read_text(encoding='utf-8-sig'), flags=re.M)
    if len(hit) != 1:
        raise ValueError('PISA_COUNTRY_COLUMN_AMBIGUOUS')
    start, end = map(int, hit[0])
    if start < 1 or end < start:
        raise ValueError('PISA_COUNTRY_COLUMN_INVALID')
    checksum, blocks, offset, previous = hashlib.sha256(), [], 0, None
    with raw.open('rb') as stream:
        for line in stream:
            checksum.update(line)
            country = line[start-1:end].decode('ascii').strip()
            if not re.fullmatch('[A-Z]{3}', country):
                raise ValueError('PISA_COUNTRY_RECORD_INVALID')
            if country != previous:
                blocks.append(dict(country=country, byte_offset=offset, rows=0))
                previous = country
            blocks[-1]['rows'] += 1
            offset += len(line)
    if checksum.hexdigest() != expected_sha or not blocks:
        raise ValueError('PISA_RAW_BYTES_CHANGED_OR_EMPTY')
    result = dict(year=int(year), raw_path=raw.resolve().as_posix(),
                  raw_sha256=expected_sha, bytes=offset,
                  control_path=control.resolve().as_posix(),
                  control_sha256=control_sha, blocks=blocks)
    text = json.dumps(result, indent=2) + '\n'
    if output.exists():
        if json.loads(output.read_text()) != result:
            raise ValueError('PISA_EXISTING_INDEX_CHANGED')
        return result
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_name(output.name + f'.{os.getpid()}.tmp')
    try:
        temporary.write_text(text, encoding='utf-8')
        os.replace(temporary, output)
    finally:
        temporary.unlink(missing_ok=True)
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for key in ('raw', 'control', 'year', 'expected-sha', 'expected-control-sha', 'output'):
        parser.add_argument('--' + key, required=True)
    args = parser.parse_args()
    answer = build_index(args.raw, args.control, args.year, args.expected_sha,
                         args.expected_control_sha, args.output)
    print('PISA_BYTE_INDEX_VERIFIED', answer['year'], sum(b['rows'] for b in answer['blocks']))
