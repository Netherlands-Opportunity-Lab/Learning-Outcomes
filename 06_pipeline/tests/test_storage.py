"""Behavioral tests. No access to restricted data is required."""
import json
from pathlib import Path
import tempfile
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import storage_manager as s

class StorageTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        root=Path(self.tmp.name)
        self.inp=root/"old_runs"
        self.archive=root/"archive"
        self.backup=root/"backup"
        self.inp.mkdir();self.backup.mkdir()
        self.cfg={"scan_roots":[self.inp],"archive_root":self.archive,
                  "backup_root":self.backup,"minimum_age_days":-1,
                  "required_product_pins":["slides","dashboard","paper"],
                  "automatic_cleanup_enabled":False}
        self.result=self.inp/"legacy_results.csv"
        self.result.write_text("metric_key,estimate\nPISA.NLD.2025,490\n",encoding="utf-8")
        (self.inp/"protected.sav").write_text("SOURCE DO NOT DISTRIBUTE")
        self.db=s.connect(self.archive)
    def tearDown(self):
        self.db.close(); self.tmp.cleanup()
    def test_migration_deduplicates_and_never_copies_source(self):
        other=self.inp/"old_copy.csv"
        other.write_bytes(self.result.read_bytes())
        r=s.migrate(self.db,self.cfg)
        self.assertEqual(r["new_unique_objects"],1)
        self.assertEqual(r["origins_indexed"],2)
        self.assertEqual(s.status(self.db)["unique_artifacts"],1)
        self.assertFalse(any(p.name=="protected.sav" for p in self.archive.rglob("*")))
        self.assertEqual(s.index_result_csv(self.db,self.result)["indexed_metric_rows"],1)
        self.assertEqual(s.status(self.db)["review_required_metric_versions"],1)
    def test_cleanup_is_safe_by_default(self):
        s.migrate(self.db,self.cfg)
        self.assertEqual(s.cleanup(self.db,self.cfg)["deleted"],0)
        with self.assertRaises(RuntimeError):
            s.cleanup(self.db,self.cfg,apply=True)
        self.assertTrue(self.result.exists())
    def test_pin_prevents_deletion(self):
        s.migrate(self.db,self.cfg)
        digest=s.sha256(self.result)
        pins=self.inp.parent/"pins.json"
        pins.write_text(json.dumps({"product":"slides","release_id":"v1",
                                    "artifact_sha256":[digest]}),encoding="utf-8")
        s.pin(self.db,pins)
        with patch.object(s,"independent",return_value=True):
            s.verify_backup(self.db,self.cfg)
            decisions=s.cleanup_plan(self.db,self.cfg)
        self.assertTrue(any(x["decision"]=="PRODUCT_PIN" for x in decisions))
        self.assertTrue(self.result.exists())
    def test_removal_only_after_full_product_pins_and_restore(self):
        s.migrate(self.db,self.cfg)
        digest=s.sha256(self.result)
        # A second unpinned historical result is eligible only after all gates.
        surplus=self.inp/"retired_export.csv"
        surplus.write_text("metric_key,estimate\nOLD_ONLY,23\n",encoding="utf-8")
        s.migrate(self.db,self.cfg)
        pinfile=self.inp.parent/"pins.json"
        for product in ("slides","dashboard","paper"):
            pinfile.write_text(json.dumps({"product":product,"release_id":"v1",
                "artifact_sha256":[digest]}),encoding="utf-8")
            s.pin(self.db,pinfile)
        self.cfg["automatic_cleanup_enabled"]=True
        with patch.object(s,"independent",return_value=True):
            s.verify_backup(self.db,self.cfg)
            plan={v["path"]:v["decision"] for v in s.cleanup_plan(self.db,self.cfg)}
            self.assertEqual(plan[str(self.result)],"PRODUCT_PIN")
            self.assertEqual(plan[str(surplus)],"ELIGIBLE_AFTER_GATES")
            output=s.cleanup(self.db,self.cfg,apply=True)
        self.assertEqual(output["deleted"],1)
        self.assertTrue(self.result.exists())
        self.assertFalse(surplus.exists())
        self.assertTrue(s.object_path(self.archive,digest).is_file())
        self.assertEqual(s.status(self.db)["historical_origin_versions"],2)

    def test_without_verified_product_contract_no_cleanup(self):
        s.migrate(self.db,self.cfg)
        with patch.object(s,"independent",return_value=True):
            s.verify_backup(self.db,self.cfg)
            self.cfg["automatic_cleanup_enabled"]=True
            self.assertEqual(s.cleanup(self.db,self.cfg,apply=True)["deleted"],0)
        self.assertTrue(self.result.exists())

if __name__=="__main__":
    unittest.main()
