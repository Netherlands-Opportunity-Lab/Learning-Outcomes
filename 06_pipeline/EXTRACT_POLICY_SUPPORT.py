"""Extract the pinned policy deck's year anchors; never certify its estimates.

Usage: python EXTRACT_POLICY_SUPPORT.py --deck path/to/deck.pptx --out metadata
The first charts are vector shapes. Their ordered axis labels specify the core
year anchor; native charts provide cached point support for later group slides.
"""
import argparse,csv,hashlib,json,math,posixpath,re,zipfile
from pathlib import Path
import xml.etree.ElementTree as ET

SHA='cea8dc8a42c3e63e435c16ef13ea6cc1b634f5ca4d95af8c29dafba7397631ac'
NS={k:v for k,v in (
 ('p','http://schemas.openxmlformats.org/presentationml/2006/main'),
 ('a','http://schemas.openxmlformats.org/drawingml/2006/main'),
 ('c','http://schemas.openxmlformats.org/drawingml/2006/chart'),
 ('r','http://schemas.openxmlformats.org/officeDocument/2006/relationships'))}
def resolve(base,target):
    return target.lstrip('/') if target.startswith('/') else posixpath.normpath(posixpath.join(posixpath.dirname(base),target))
def write(path,rows):
    with path.open('w',encoding='utf-8',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
def extract(deck,out):
    deck=Path(deck);out=Path(out)
    if hashlib.sha256(deck.read_bytes()).hexdigest()!=SHA:raise ValueError('Policy deck SHA changed')
    core=[];charts=[];chart_count=0
    with zipfile.ZipFile(deck) as z:
        rels={r.get('Id'):r.get('Target') for r in ET.fromstring(z.read('ppt/_rels/presentation.xml.rels'))}
        slides=ET.fromstring(z.read('ppt/presentation.xml')).findall('p:sldIdLst/p:sldId',NS)
        if len(slides)!=21:raise ValueError('Expected the actual 21-slide presentation order')
        for i,s in enumerate(slides,1):
            name=resolve('ppt/presentation.xml',rels[s.get('{'+NS['r']+'}id')])
            tree=ET.fromstring(z.read(name));texts=[x.text or '' for x in tree.findall('.//a:t',NS)]
            if i==2:
                starts=[j for j,t in enumerate(texts) if t in ('PISA','PIRLS','TIMSS')]
                if len(starts)!=6:raise ValueError('Mean chart blocks changed')
                domains=['reading','reading','mathematics','mathematics','science','science']
                for panel,j in enumerate(starts):
                    end=starts[panel+1] if panel<5 else len(texts)
                    years=[t for t in texts[j+1:end] if re.fullmatch(r'(19|20)\d{2}',t)]
                    core.append(dict(slide_number=2,survey=texts[j],age_group='age15' if texts[j]=='PISA' else 'age10',domain=domains[panel],years=';'.join(years),source_kind='PINNED_VECTOR_CHART_AXIS_YEAR_ANCHOR',deck_sha256=SHA,scientific_validation='NOT_GRANTED_BY_DECK'))
            rp=posixpath.join(posixpath.dirname(name),'_rels',posixpath.basename(name)+'.rels')
            rr={r.get('Id'):r.get('Target') for r in ET.fromstring(z.read(rp))} if rp in z.namelist() else {}
            for ch in tree.findall('.//c:chart',NS):
                chart_count+=1
                cn=resolve(name,rr[ch.get('{'+NS['r']+'}id')]);ct=ET.fromstring(z.read(cn))
                for si,ser in enumerate(ct.findall('.//c:ser',NS),1):
                    def points(kind):
                        return {p.get('idx'):p.find('c:v',NS).text for p in ser.findall('c:'+kind+'//c:pt',NS) if p.find('c:v',NS) is not None}
                    cats=points('cat') or points('xVal');values=points('val') or points('yVal')
                    def finite(v):
                        try:return math.isfinite(float(v))
                        except (ValueError,TypeError):return False
                    years={k:v for k,v in cats.items() if re.fullmatch(r'(19|20)\d{2}',v or '')}
                    charts.append(dict(slide_number=i,slide_title=texts[0],chart_part=cn,series_number=si,
                        series_label=';'.join(x.text or '' for x in ser.findall('c:tx//c:v',NS)),
                        axis_years=';'.join(years.values()),cached_point_years=';'.join(v for k,v in years.items() if finite(values.get(k))),
                        other_categories=';'.join(v or '' for k,v in cats.items() if k not in years),
                        finite_cached_points=sum(finite(v) for v in values.values()),
                        source_status='DECK_CACHE_NOT_SCIENTIFIC_CERTIFICATE'))
    if chart_count!=48:raise ValueError('Expected 48 linked native charts')
    out.mkdir(parents=True,exist_ok=True)
    write(out/'NLD_POLICY_CORE_YEAR_ANCHOR.csv',core)
    write(out/'NLD_POLICY_CHART_SUPPORT.csv',charts)
    receipt={'deck_sha256':SHA,'slides':21,'native_charts':chart_count,'native_series':len(charts),'core_year_cells':sum(len(r['years'].split(';')) for r in core),'status':'SOURCE_PRESENTATION_SUPPORT_ONLY','limits':['The deck fixes requested support, not scientific availability.','Native chart cached values and vector-axis labels require source-record validation.','Absent or placeholder focus outcomes do not imply zero observations or universal reference eligibility.','Do not activate excluded/pending analyses merely because they occur in this source deck.']}
    (out/'NLD_POLICY_SUPPORT_PROVENANCE.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    return receipt
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--deck',required=True);p.add_argument('--out',required=True)
    a=p.parse_args();print(json.dumps(extract(a.deck,a.out)))
