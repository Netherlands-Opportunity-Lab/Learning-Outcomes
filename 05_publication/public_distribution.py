"""Public distribution boundary: no private manuscript, presentation or pupil data.

This check is independent of scientific approval. A historical certificate cannot
authorize distribution after the owner's later private-only instruction.
"""
import hashlib, json, zipfile
from pathlib import Path, PurePosixPath

DOCUMENT_FORMATS={'.pdf','.pptx','.ppt','.docx','.doc','.odp','.odt'}
RAW_FORMATS={'.sav','.zsav','.dta','.rds','.rda','.rdata','.sas7bdat','.parquet','.sqlite'}
PRIVATE_PREFIXES=('04_products_or_release/current47/','products/','private_products/')

def check_names(names):
    for name in names:
        if not name or '\\' in name or ':' in name or name.startswith('/') or '..' in PurePosixPath(name).parts:
            raise ValueError('Unsafe public path: '+name)
        low=name.lower()
        if low.startswith(PRIVATE_PREFIXES) or PurePosixPath(low).suffix in DOCUMENT_FORMATS|RAW_FORMATS:
            raise ValueError('Private document or source data in public distribution: '+name)

def verify_archive(path):
    with zipfile.ZipFile(path) as z:
        names=z.namelist();check_names(names)
        if any(n.lower().endswith('.zip') for n in names):
            raise ValueError('Nested public archive requires explicit review')
        manifest=json.loads(z.read('PACKAGE_MANIFEST.json'))
        if manifest.get('private_documents_included') is not False:
            raise ValueError('Package lacks the current private-document boundary')
        if set(names)-{'PACKAGE_MANIFEST.json'}!=set(manifest['files']):
            raise ValueError('Package inventory mismatch')
        for name,expected in manifest['files'].items():
            with z.open(name) as f: actual=hashlib.file_digest(f,'sha256').hexdigest()
            if actual!=expected:raise ValueError('Package bytes changed: '+name)
    return {'status':'PUBLIC_PACKAGE_EXCLUDES_PRIVATE_DOCUMENTS','files':len(names)}

def verify_tree(root):
    root=Path(root);files=[p for p in root.rglob('*') if p.is_file()]
    check_names([p.relative_to(root).as_posix() for p in files])
    packages=[]
    for p in files:
        if p.is_symlink():raise ValueError('Symlink in public distribution')
        if p.suffix.lower()=='.zip':packages.append(verify_archive(p))
        if p.suffix.lower()=='.html' and '../../products/' in p.read_text(encoding='utf-8'):
            raise ValueError('Withdrawn product link in public HTML')
    return {'status':'PUBLIC_TREE_EXCLUDES_PRIVATE_DOCUMENTS','files':len(files),'packages':packages}
