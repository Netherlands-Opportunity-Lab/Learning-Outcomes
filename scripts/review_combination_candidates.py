"""Screen retained source indices beyond COMMON42; never certify or estimate.

One observed country code is not proof of released scores or a national target
population. Every proposed context still passes the exact source and Q02 review.
No archives are extracted and no production manifest is modified.
"""
import argparse
import csv
import hashlib
import json
from collections import defaultdict
from pathlib import Path


def read(path):
    with path.open(encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))


def sha(path):
    with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()


# Additional national/participant identities absent from the old IEA-driven
# candidate catalogue. These names do not approve sample comparability.
EXTRA = {'BLR':'Belarus','BRN':'Brunei Darussalam','DOM':'Dominican Republic',
    'ECU':'Ecuador','GTM':'Guatemala','JAM':'Jamaica','KEN':'Kenya','KGZ':'Kyrgyzstan',
    'KHM':'Cambodia','KSV':'Kosovo','LBN':'Lebanon','LIE':'Liechtenstein',
    'MUS':'Mauritius','MYS':'Malaysia','PAN':'Panama','PER':'Peru','PRY':'Paraguay',
    'PSE':'Palestinian Authority','RWA':'Rwanda','URY':'Uruguay','VNM':'Viet Nam','ZMB':'Zambia'}


def build(repo,root,output):
    private=root/'international';public=repo/'06_pipeline/review_20261013/scientific_review'
    files=[public/'COUNTRY_REVIEW.csv',repo/'06_pipeline/review_20261013/POPULATION_CORRECTIONS.json',
        private/'IEA_POPULATION_REVIEW.csv',private/'SOURCE_RUN_MANIFEST.csv']
    countries=read(files[0]);known={r['country'] for r in countries}
    national={r['country'] for r in countries if r['entity_kind'] in ('NATIONAL_CANDIDATE','CONSISTENT_PARTICIPATING_EDUCATION_SYSTEM')}
    national.update(EXTRA);national.update(('BEL','GBR','CHE','ISL','KOR','LUX'))
    national.discard('MAC')  # No new regional system silently made a country.
    corrections=json.loads(files[1].read_text(encoding='utf-8'))['corrections']
    excluded={(r['country'],r['survey'],str(r['year'])) for r in corrections}
    waves=defaultdict(set);raw_codes=set()
    for r in read(files[2]):
        raw_codes.add(r['country'])
        if r['country'] in national and r['source_context_status']=='CORE_POPULATION_CHECKED' and (r['country'],r['survey'],r['year']) not in excluded:
            for d in (['reading'] if r['survey']=='PIRLS' else ['mathematics','science']):
                waves[r['country'],r['survey'],d].add(int(r['year']))
    for year in [2003,2006,2009,2012,2015,2018,2022,2025]:
        path=private/(f'PISA_{year}_BYTE_INDEX.json' if year<2015 else f'PISA_{year}_COUNTRY_COUNTS.csv')
        files.append(path)
        codes={r['country'] for r in json.loads(path.read_text())['blocks']} if year<2015 else {r['selector'] for r in read(path)}
        raw_codes.update(codes)
        for code in codes:
            country='TWN' if code=='TAP' else code
            if country not in national or (country,'PISA',str(year)) in excluded:continue
            if country=='AZE' and year in (2018,2022):continue  # Baku is not national Azerbaijan.
            for d in (['reading','mathematics'] if year==2003 else ['reading','mathematics','science']):
                if country=='USA' and year==2006 and d=='reading':continue
                waves[country,'PISA',d].add(year)
    passed={k:sorted(v) for k,v in waves.items() if len(v)>=3}
    verified={r['country'] for r in read(files[3])}
    new=sorted({k[0] for k in passed}-verified)
    result=dict(schema_version=1,status='INVENTORY_SCREEN_ONLY_NOT_SOURCE_CERTIFICATION',
        candidate_countries_with_one_or_more_three_wave_combinations=len({k[0] for k in passed}),
        candidate_combinations=len(passed),new_candidate_countries=new,new_country_count=len(new),
        existing_source_registry_countries=len(verified),
        additional_named_participants=EXTRA,
        newly_screened_outside_old_country_catalogue=sorted(set(new)-known),
        codes_needing_separate_population_identity_review=sorted(raw_codes-national-{'TAP'}),
        participant_identity_source='https://www.oecd.org/en/about/programmes/pisa/pisa-participants.html',
        combinations=[dict(country=k[0],survey=k[1],domain=k[2],years=v,prior_source_registry=k[0] in verified)
            for k,v in sorted(passed.items())],
        input_sha256={p.name:sha(p) for p in files},review_script_sha256=sha(Path(__file__)),
        limitations=['Indices can contain questionnaire records without valid released domain scores. Exact PV/source verification determines final eligibility.',
            'Historical national coverage, mode, scale linkage and official qualifications require Q02 review for every newly used wave.',
            'No regional system has been renamed or substituted. Official participation can exceed locally available files (e.g. Maltese PIRLS).',
            'This inventory neither modifies the production manifest nor schedules or certifies estimates.'])
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print(json.dumps({k:result[k] for k in ['status','candidate_countries_with_one_or_more_three_wave_combinations',
        'candidate_combinations','new_candidate_countries','new_country_count']}))
    return result


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--repo',type=Path,required=True)
    p.add_argument('--root',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
    a=p.parse_args();build(a.repo,a.root,a.output)
