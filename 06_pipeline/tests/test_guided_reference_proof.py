"""Country selection must fail closed on changed identities or shortened panels."""
import copy, importlib.util, unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
s=importlib.util.spec_from_file_location('verify',ROOT/'06_pipeline/LO_DASHBOARD_REFERENCE_VERIFY.py')
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)

class ReferenceProof(unittest.TestCase):
    def fixture(self):
        countries=['NLD','AAA','BBB'];cells=[];rows=[];targets=[]
        f=dict(figure_id='TR_MEAN_age10_reading',required_years='2001;2006;2011;2016;2021',expected_series='total')
        for country in countries:
            for (survey,domain),years in m.ANCHOR.items():
                for year in years:
                    cid=f'{country}|{survey}|{year}|{domain}|core|mean|total|total|||score_points|'
                    r=dict(zip(m.COLS,[survey,'age15' if survey=='PISA' else 'age10',domain,str(year),
                        'mean_score','none','total',survey+'_DOMAIN_MEAN','none','none','none','none',
                        'score_points',survey+'_POPULATION',survey+'_LINKED_SCALE']))
                    r.update(country=country,cell_id=cid,result_hash='a'*64,verification_id='b'*64,
                        source_certificate_sha256='c'*64,result_certificate_sha256='d'*64)
                    cells.append(r);targets.append(dict(country=country,cell_id=cid))
                    rows.append(dict(cell_id=cid,country_id='iso3:'+country,year=year,result_hash='a'*64,
                        figure_id=f['figure_id'] if survey=='PIRLS' else survey+'_'+domain,series_id='total'))
        cols=list(cells[0]);views=[]
        for country in countries:
            ids=[r['cell_id'] for r in rows if r['country_id']=='iso3:'+country and r['figure_id']==f['figure_id']]
            keys=sorted({m.key(c) for c in cells if c['country']==country})
            views.append(dict(focus=country,figure_id=f['figure_id'],view_cell_ids=ids,
                status='BALANCED_REFERENCE_AVAILABLE',required_keys=keys,
                default_members=['AAA'] if country!='AAA' else [],
                options=[dict(country=c,eligible=c!=country,dashboard_eligible=True,
                    required_cells=len(keys),missing_cells=0,missing_keys='') for c in countries]))
        evidence=dict(schema_version=3,policy=m.POLICY,dashboard_input_sha256='e'*64,
            mapping_evidence=dict(status='EXACT_SOURCE_RESULT_METHOD_COMPARABILITY_BINDINGS',mapped_cells=len(cells)),
            cell_columns=cols,cells=[[c[k] for k in cols] for c in cells],core_targets=targets,
            rich_candidates=['AAA'],admission=[dict(country=c,dashboard_eligible=True) for c in countries],views=views)
        return evidence,rows,countries,[f]

    def test_exact_mapping_and_fixed_full_anchor(self):
        e,r,c,f=self.fixture();self.assertEqual(m.verify(e,r,c,f,'e'*64)['status'],'PASS')
        e['core_targets']=[t for t in e['core_targets'] if t['cell_id']!='NLD|TIMSS|2003|science|core|mean|total|total|||score_points|']
        with self.assertRaisesRegex(ValueError,'Dutch anchor'):m.verify(e,r,c,f)

    def test_changed_result_or_input_rejected(self):
        e,r,c,f=self.fixture();r[0]['result_hash']='f'*64
        with self.assertRaisesRegex(ValueError,'result binding'):m.verify(e,r,c,f)
        e,r,c,f=self.fixture()
        with self.assertRaisesRegex(ValueError,'dashboard input'):m.verify(e,r,c,f,'f'*64)

    def test_no_manual_enabling_or_shortened_keys(self):
        e,r,c,f=self.fixture();e['views'][0]['options'][0]['eligible']=True
        with self.assertRaisesRegex(ValueError,'membership'):m.verify(e,r,c,f)
        e,r,c,f=self.fixture();e['views'][0]['required_keys'].pop()
        with self.assertRaisesRegex(ValueError,'focus requirements'):m.verify(e,r,c,f)

    def test_population_difference_excludes_whole_candidate(self):
        e,r,c,f=self.fixture();i=e['cell_columns'].index('population_comparison_id')
        target=next(a for a in e['cells'] if a[e['cell_columns'].index('country')]=='BBB')
        target[i]='DIFFERENT_POPULATION'
        with self.assertRaisesRegex(ValueError,'membership'):m.verify(e,r,c,f)

    def test_missing_one_focus_group_cannot_be_ignored(self):
        e,r,c,f=self.fixture();f[0]['expected_series']='total;missing_group'
        with self.assertRaisesRegex(ValueError,'unproved view'):m.verify(e,r,c,f)

if __name__=='__main__':unittest.main()
