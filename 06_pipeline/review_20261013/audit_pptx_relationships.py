"""Audit slides in presentation order, including nonstandard part names.

Usage: python audit_pptx_relationships.py deck.pptx
Read-only. No Office installation or third-party packages required.
"""
import argparse
import hashlib
import json
import posixpath
import zipfile
from pathlib import Path
import xml.etree.ElementTree as ET

P = 'http://schemas.openxmlformats.org/presentationml/2006/main'
R = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
A = 'http://schemas.openxmlformats.org/drawingml/2006/main'

def audit(path):
    with zipfile.ZipFile(path) as z:
        names = set(z.namelist())
        def resolve(part, target):
            return target.lstrip('/') if target.startswith('/') else posixpath.normpath(posixpath.join(posixpath.dirname(part), target))
        def rels(part):
            p = posixpath.join(posixpath.dirname(part), '_rels', posixpath.basename(part)+'.rels')
            return {r.attrib['Id']:r.attrib for r in ET.fromstring(z.read(p))} if p in names else {}
        presentation = 'ppt/presentation.xml'
        links = rels(presentation)
        ordered = ET.fromstring(z.read(presentation)).findall(f'.//{{{P}}}sldId')
        slides, missing, charts = [], [], set()
        for i, node in enumerate(ordered, 1):
            target = resolve(presentation, links[node.attrib[f'{{{R}}}id']]['Target'])
            if target not in names:
                missing.append(target)
                continue
            root = ET.fromstring(z.read(target))
            texts = [e.text or '' for e in root.iter(f'{{{A}}}t')]
            linked_charts = []
            for link in rels(target).values():
                if link.get('TargetMode') == 'External': continue
                part = resolve(target, link['Target'])
                if part not in names: missing.append(part)
                if link['Type'].endswith('/chart'):
                    linked_charts.append(part)
                    charts.add(part)
            slides.append(dict(number=i,part=target,title=texts[0] if texts else '',chart_parts=linked_charts))
        return dict(file=Path(path).name,sha256=hashlib.sha256(Path(path).read_bytes()).hexdigest(),
                    ordered_slide_count=len(ordered),resolved_slide_count=len(slides),
                    unique_linked_charts=len(charts),missing_targets=missing,slides=slides,
                    validation_scope='Package relationship audit, not visual or scientific validation')

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('pptx',type=Path)
    args=parser.parse_args()
    result=audit(args.pptx)
    print(json.dumps(result,ensure_ascii=True,indent=2))
    raise SystemExit(1 if result['missing_targets'] else 0)
