"""Final publication can explain known gaps, never relabel unfinished results."""
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('release',ROOT/'06_pipeline/LO_FINAL_GUIDED_PUBLIC_RELEASE.py')
release=importlib.util.module_from_spec(spec);spec.loader.exec_module(release)


class FinalAbsenceEvidence(unittest.TestCase):
 def check(self,point,changed_binding=False):
  with tempfile.TemporaryDirectory() as tmp:
   site=Path(tmp);(site/'data').mkdir()
   evidence=dict(status='ALL_MISSING_POINTS_HAVE_EXACT_REVIEWED_CAUSES',
     coverage_sha256='a'*64,product_trace_sha256='b'*64,
     points=[point],reviewed_missing_points=1)
   path=site/'data/absence_evidence.json';path.write_text(json.dumps(evidence))
   binding=hashlib.sha256(path.read_bytes()).hexdigest()
   cert=dict(reviewed_absence_evidence_sha256=binding,coverage_sha256='a'*64,product_trace_sha256='b'*64)
   if changed_binding:cert['coverage_sha256']='c'*64
   return release.verify_reviewed_absence(site,cert,dict(reviewed_absence_evidence_sha256=binding))
 def point(self):
  return dict(country='NLD',figure_id='GP_LANGUAGE_LEVELS_age10_reading',year=2006,
   series_id='always_almost',cell_id='EXACT_APPROVED_TARGET',target_contract_sha256='d'*64,
   status='UNAVAILABLE_VERIFIED_SOURCE_FIELD',main_reason='GROUP_DEFINITION_NOT_OBSERVED',
   hold_reason='The wave observes always/sometimes/never, not always-or-almost.',
   analysis_min_component_n='',analysis_min_component_school_n='',population_review_id='')
 def test_reviewed_absence_is_allowed(self):
  self.assertEqual(len(self.check(self.point())),1)
 def test_changed_review_binding_is_rejected(self):
  with self.assertRaises(ValueError):self.check(self.point(),True)
 def test_unfinished_compute_is_not_structural_absence(self):
  point=self.point();point['status']='PENDING_COMPUTE'
  with self.assertRaises(ValueError):self.check(point)
 def test_quality_requires_actual_counts(self):
  point=self.point();point.update(status='SCIENTIFICALLY_VALIDATED',main_reason='ANALYSIS_BELOW_PUBLICATION_THRESHOLD',
    analysis_min_component_n='29',analysis_min_component_school_n='10')
  self.assertEqual(len(self.check(point)),1)
  point['analysis_min_component_n']='30'
  with self.assertRaises(ValueError):self.check(point)

if __name__=='__main__':unittest.main()
