import importlib.util,json,sqlite3,tempfile,unittest,csv,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root))
spec=importlib.util.spec_from_file_location('audit',root/'PRODUCT_EVIDENCE_AUDIT.py')
audit=importlib.util.module_from_spec(spec);spec.loader.exec_module(audit)

class ProductAuditTest(unittest.TestCase):
    def test_source_deck_does_not_approve_substantive_additions(self):
        original=json.loads((root/'review_20261013/PRODUCT_REQUIREMENTS.json').read_text(encoding='utf-8'))
        d=audit.apply_scope_approval(original)
        byid={r['requirement_id']:r for r in d['requirements']}
        self.assertEqual(byid['SCIENCE_24']['approval_items'],['A06'])
        self.assertIn('A01',byid['POLICY_20']['approval_items'])
        self.assertIn('A03',byid['POLICY_20']['approval_items'])
        self.assertNotIn('S_LEGACY_PANELS',byid['POLICY_02']['additional_dependencies'])
        self.assertFalse(d['inventory_is_user_approval'])
        self.assertTrue(all(not r['production_authorized_by_inventory'] for r in d['requirements']))
        self.assertTrue(all('PENDING' in r['role'] for r in d['requirements'] if r['approval_items']))
        self.assertEqual(audit.apply_scope_approval(d),d)

    def test_nonfinite_and_missing_are_never_parity(self):
        for a,b in [('', ''),('NA','NA'),('nan','nan'),('inf','inf'),(None,None)]:
            self.assertFalse(audit.numeric_equal(a,b))
        self.assertFalse(audit.numerical_pair({'estimate':'450','se':'-1'}))
        self.assertTrue(audit.numeric_equal('450.0000000001',450))
        self.assertFalse(audit.numeric_equal('450.01',450))

    def test_exact_scope_members_not_only_counts(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)
            def write(countries):
                audit.write_csv(p/'COMMON42_REGISTER.csv',[{'route_code':c,'common42_member':'TRUE'} for c in countries],['route_code','common42_member'])
            write(audit.COMMON42)
            audit.write_csv(p/'PPP_COMPARATOR_MEMBERSHIP_v2.csv',[{'country':c,'strictly_above_czechia':'TRUE'} for c in audit.REFERENCE],['country','strictly_above_czechia'])
            self.assertEqual([len(v) for v in audit.scopes(p).values()],[1,20,50])
            write(audit.COMMON42-{'ALB'}|{'XXX'})
            with self.assertRaises(ValueError):audit.scopes(p)

    def test_requirements_cover_actual_products_and_no_unknowns(self):
        d=json.loads((root/'review_20261013/PRODUCT_REQUIREMENTS.json').read_text(encoding='utf-8'))
        figures=[{'figure_id':r['source_locator']} for r in d['requirements'] if r['product']=='DASHBOARD']
        audit.validate_definitions(d,figures)
        d['requirements'][0]['additional_dependencies']=['S_NONEXISTENT']
        with self.assertRaises(ValueError):audit.validate_definitions(d,figures)

    def test_new_low_peers_do_not_reuse_high_peer_ids(self):
        t={'country':'NLD','survey':'PISA','year':'2022','domain':'reading','peer_definition':'whole_school','contract_figure_id':'EN_PERFORMANCE_PEER_age15_reading_whole_school'}
        cells=audit.new_low_peer_cells([t,t],{'NLD'})
        self.assertEqual(len(cells),3)
        self.assertEqual(len({r['cell_id'] for r in cells}),3)
        self.assertTrue(all(r['threshold']=='PISA_BELOW_LEVEL2' for r in cells))
        self.assertEqual(audit.new_low_peer_cells([t],{'AUT'}),[])

    def test_source_parity_requires_hash_and_real_standard_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'source.csv'
            audit.write_csv(p,[{'estimate':450,'se':2},{'estimate':460,'se':''}],['estimate','se'])
            rows=[{'metric_key':str(i),'record_version_id':str(i),'source_file':str(p),'evidence_source_row':str(i),'evidence_source_sha256':audit.sha(p),'estimate':v,'se':se} for i,v,se in [(1,'450','2'),(2,'460','')]]
            result=audit.verify_lo01_sources(rows)
            self.assertTrue(result[0]['source_pair_verified'])
            self.assertFalse(result[1]['source_pair_verified'])
            rows[0]['evidence_source_sha256']='0'*64
            self.assertFalse(audit.verify_lo01_sources(rows)[0]['source_pair_verified'])

if __name__=='__main__':unittest.main()
