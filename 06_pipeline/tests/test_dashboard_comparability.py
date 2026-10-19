"""Evidence reuse must fail closed after any dependency or policy change."""
import contextlib
import csv
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

FILE=Path(__file__).resolve().parents[1]/'LO_DASHBOARD_COMPARABILITY.py'
spec=importlib.util.spec_from_file_location('comparison_review',FILE)
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

class ComparisonReview(unittest.TestCase):
    def test_complement_retains_primitive_identity_and_checks_values(self):
        row=dict(result_hash='parent',estimate='0.75',standard_error='0.02',n_unweighted='100')
        task=dict(stat='q1_basic',unit='proportion')
        product=dict(result_hash='display',figure_id='GP_SES_BASIC_age10_reading',
            source_id='GRID:SHA256:parent',estimate='25',se='2',n_unweighted='100')
        binding=m.product_binding(product,row,task)
        self.assertEqual(binding['result_hash'],'parent')
        self.assertEqual(binding['source_record_id'],'parent')
        self.assertEqual(binding['product_result_hash'],'display')
        self.assertEqual(binding['product_multiplier'],-100)
        self.assertEqual(binding['product_unit'],'percent')
        for changed in [dict(estimate='75'),dict(se='0.02'),dict(n_unweighted='99')]:
            with self.assertRaisesRegex(ValueError,'PRODUCT_NUMERIC_PARENT_BINDING'):
                m.product_binding(dict(product,**changed),row,task)
        identity=dict(product,result_hash='parent',estimate='0.75',se='0.02')
        self.assertEqual(m.product_binding(identity,row,task)['product_transform'],'IDENTITY')
        with self.assertRaisesRegex(ValueError,'PRODUCT_NUMERIC_PARENT_BINDING'):
            m.product_binding(dict(identity,estimate='0.8'),row,task)
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)
        self.code=self.root/'06_pipeline/LO_DASHBOARD_COMPARABILITY.py'
        self.code.parent.mkdir();self.code.write_text('fixed implementation')
        self.old=m.__file__;m.__file__=str(self.code)
        self.policy=self.code.parent/'review_20261013';self.policy.mkdir()
        m.put(self.policy/'POPULATION_CORRECTIONS.json',{'corrections':[]})
        self.projection_code=self.code.parent/'LO_SOURCE_PROJECTION_REVIEW.R'
        self.projection_code.write_text('fixed reviewed projection')
        m.checked.cache_clear()
    def tearDown(self):
        m.__file__=self.old;self.temp.cleanup();m.checked.cache_clear()
    def test_projection_requires_exact_method_context_and_code(self):
        p=dict(status='EXACT_COHORT_DESIGN_PV_PROJECTION_VERIFIED',
            country='NLD',survey='PISA',year='2025',n=10,
            allowed_method='BOYS_ONLY',child_sha256='a'*64,parent_sha256='b'*64,
            changed_columns=['GENDER','DEMO_GENDER'],all_other_columns_identical=True,
            original_order_and_identifiers_identical=True)
        m.put(self.policy/'SOURCE_PROJECTION_REVIEWS.json',
            dict(projections=[p],review_code_sha256=m.sha(self.projection_code)))
        row=dict(country='NLD',survey='PISA',year='2025',method_version='BOYS_ONLY',source_edition_sha256='a'*64)
        supports=[(dict(canonical_sha256='b'*64,n=10),'c'*64)]
        self.assertEqual(len(m.reviewed_gender_projection(row,supports)),1)
        self.assertEqual(m.reviewed_gender_projection(dict(row,method_version='GIRLS'),supports),[])
        self.assertEqual(m.reviewed_gender_projection(dict(row,year='2022'),supports),[])
        self.assertEqual(m.reviewed_gender_projection(row,[(dict(canonical_sha256='b'*64,n=11),'c'*64)]),[])
        self.projection_code.write_text('changed')
        with self.assertRaisesRegex(ValueError,'IMPLEMENTATION_CHANGED'):m.reviewed_gender_projection(row,supports)
    def fixture(self):
        snap=self.root/'snapshot'
        for d in ['public_inputs','master_reconciliation','product_export']:(snap/d).mkdir(parents=True)
        self.attachment=self.root/'source-proof.json';m.put(self.attachment,dict(status='checked'))
        self.row=dict(cell_id='cell',country='NLD',survey='PISA',year='2025',domain='reading',result_hash='value')
        self.task=dict(metric_key='cell',country='NLD',module='core',stat='mean',choice='first')
        m.writecsv(snap/'master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv',[self.row])
        m.writecsv(snap/'master_reconciliation/SOURCE_SUPPORT_CONTRACTS.csv',[dict(country='NLD',survey='PISA',year='2025',domain='reading')])
        m.writecsv(snap/'public_inputs/dashboard_cells.csv',[dict(cell_id='cell',result_hash='value')])
        m.writecsv(snap/'product_export/PRIVATE_TASKS.csv',[self.task])
        self.seal(snap)
        return snap
    def seal(self,snap):
        names=['master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv','master_reconciliation/SOURCE_SUPPORT_CONTRACTS.csv','product_export/PRIVATE_TASKS.csv']
        m.put(snap/'SNAPSHOT.json',dict(inputs={n:m.sha(snap/n) for n in names}))
        m.put(snap/'product_export/SNAPSHOT_EXPORT_EVIDENCE.json',dict(export_sha256=m.sha(snap/'public_inputs/dashboard_cells.csv')))
    def mapped(self,*args):
        m.checked(str(self.attachment),m.sha(self.attachment))
        return dict(cell_id='cell',country='NLD',estimate='0')
    def run_build(self,snap,name,previous=None):
        out=self.root/name
        with contextlib.redirect_stdout(io.StringIO()):m.build(snap,out,previous)
        return out,json.loads((out/'BALANCE_MAPPING_REVIEW.json').read_text())
    def test_resume_second_run_changed_target_and_evidence(self):
        snap=self.fixture()
        with patch.object(m,'map_cell',side_effect=self.mapped) as mapper:
            first,_=self.run_build(snap,'first');self.assertEqual(mapper.call_count,1)
            second,proof=self.run_build(snap,'second',first)
            self.assertEqual(mapper.call_count,1);self.assertEqual(proof['reused_mapping_cells'],1)
            self.task['choice']='changed';m.writecsv(snap/'product_export/PRIVATE_TASKS.csv',[self.task]);self.seal(snap)
            third,proof=self.run_build(snap,'third',second)
            self.assertEqual(mapper.call_count,2);self.assertEqual(proof['reused_mapping_cells'],0)
            self.attachment.write_text('{}')
            with self.assertRaisesRegex(ValueError,'CHANGED_PREVIOUS_MAPPING_EVIDENCE'):self.run_build(snap,'fourth',third)
    def test_unpinned_task_and_modified_export_rejected(self):
        snap=self.fixture();self.task['choice']='changed'
        m.writecsv(snap/'product_export/PRIVATE_TASKS.csv',[self.task])
        with self.assertRaisesRegex(ValueError,'FROZEN_INPUT_CHANGED'):self.run_build(snap,'bad')
        self.seal(snap)
        with patch.object(m,'map_cell',side_effect=self.mapped):first,_=self.run_build(snap,'valid')
        (first/'BALANCE_AVAILABLE.csv').write_text('changed')
        with self.assertRaisesRegex(ValueError,'CHANGED_PREVIOUS_MAPPING'):self.run_build(snap,'bad_cache',first)

if __name__=='__main__':unittest.main()
