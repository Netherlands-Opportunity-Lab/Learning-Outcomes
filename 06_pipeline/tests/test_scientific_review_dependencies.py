import importlib.util
from pathlib import Path
import unittest

path=Path(__file__).resolve().parents[2]/'scripts/freeze_scientific_review.py'
spec=importlib.util.spec_from_file_location('freeze_review',path)
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

class ScientificDependencies(unittest.TestCase):
    def test_changed_results_sources_and_claim_registration_are_rejected(self):
        row=dict(cell_id='cell',status='SCIENTIFICALLY_VALIDATED',survey='PISA',subgroup_variable='ses_harmonized',
            result_hash='result',target_contract_sha256='target',source_edition_sha256='source',n_unweighted='2',
            input_fingerprint='input',code_fingerprint='code')
        ses=[{k:row[k] for k in ('cell_id','result_hash','target_contract_sha256','source_edition_sha256','n_unweighted')}]
        sources=[dict(source_sha256='source')]
        deps=[dict(row,claim_id='claim',source_sha256='source')]
        claims=[dict(claim_id='claim',parent_a='cell',parent_b='cell')]
        m.verify_review_bindings({'cell':row},ses,sources,deps,claims)
        for field in ('result_hash','target_contract_sha256','source_edition_sha256','n_unweighted'):
            with self.assertRaises(ValueError):
                m.verify_review_bindings({'cell':dict(row,**{field:'3'})},ses,sources,deps,claims)
        for changed_ses,changed_sources,changed_deps,changed_claims in [
            ([],sources,deps,claims),(ses,[],deps,claims),(ses,sources,[],claims),
            (ses,sources,deps+deps,claims),(ses,sources,deps,claims+[dict(claim_id='new',parent_a='cell')])]:
            with self.assertRaises(ValueError):
                m.verify_review_bindings({'cell':row},changed_ses,changed_sources,changed_deps,changed_claims)

if __name__=='__main__':unittest.main()
