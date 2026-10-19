"""Exercise the actual publication verifier on the complete private Q06 export."""
import argparse
import csv
import hashlib
import importlib.util
import json
from pathlib import Path


def sha(path):
    with path.open('rb') as handle:
        return hashlib.file_digest(handle, 'sha256').hexdigest()


def verify(repo, work):
    audit = work / 'Q06_mapping_final'
    export_path = audit / 'BALANCED_REFERENCE_EXPORT.json'
    evidence = json.loads(export_path.read_text(encoding='utf-8-sig'))
    figure_path = audit / 'FIGURES.json'
    figures = json.loads(figure_path.read_text(encoding='utf-8-sig'))['figures']
    if sha(figure_path) != evidence['figure_registry_sha256']:
        raise ValueError('Changed figure registry')
    source = work / 'snapshot/public_inputs/dashboard_cells.csv'
    with source.open(encoding='utf-8-sig', newline='') as handle:
        all_source_countries = sorted({r['country'] for r in csv.DictReader(handle)})
    modules = {}
    for name in ['LO_FINAL_GUIDED_DASHBOARD_BUILD', 'LO_DASHBOARD_REFERENCE_VERIFY']:
        spec = importlib.util.spec_from_file_location(name, repo / '06_pipeline' / (name + '.py'))
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        modules[name] = module
    rows = modules['LO_FINAL_GUIDED_DASHBOARD_BUILD'].product_rows(source, all_source_countries, figures)
    result = modules['LO_DASHBOARD_REFERENCE_VERIFY'].verify(
        evidence, rows, evidence['scope_countries'], figures, sha(source))
    result.update(reference_export_sha256=sha(export_path), figure_registry_sha256=sha(figure_path),
                  original_product_export_sha256=sha(source),
                  code_sha256={name + '.py': sha(repo / '06_pipeline' / (name + '.py')) for name in modules},
                  verification_script_sha256=sha(Path(__file__)),
                  no_pupil_recalculation=True, public_deployment=False)
    (work / 'Q06/PUBLICATION_REFERENCE_VERIFICATION.json').write_text(
        json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, required=True)
    parser.add_argument('--work', type=Path, required=True)
    args = parser.parse_args()
    verify(args.repo, args.work)
