"""Cloud sync safety tests; neither a Google account nor rclone required."""
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import drive_sync as ds

class DriveSyncTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory()
        self.root=Path(self.temp.name)
        self.results=self.root/"LO05_RESULTATEN"
        (self.results/"runs"/"run_1").mkdir(parents=True)
        (self.results/"candidate_checkpoints").mkdir(parents=True)
        self.output=self.results/"runs"/"run_1"/"STATUS.txt"
        self.output.write_text("NLD_PROGRESS=1\n",encoding="utf-8")
        self.secret=self.results/"runs"/"run_1"/"credential.json"
        self.secret.write_text('{"access_token":"secret"}')
        self.raw=self.results/"candidate_checkpoints"/"students.sav"
        self.raw.write_text("STUDENT MICRODATA")
        self.partial=self.results/"runs"/"run_1"/".partial.txt"
        self.partial.write_text("not completed")
        self.cfg={"local_results_root":self.results,
                  "remote":"lo_private:Learning-Outcomes-Private",
                  "data_visibility":"PRIVATE_ACCOUNT_ONLY",
                  "rclone_binary":"rclone",
                  "min_age_seconds":0,
                  "max_file_bytes":2_000_000,
                  "max_transfers":2}
    def tearDown(self):
        self.temp.cleanup()
    def test_only_allowlisted_stable_completed_output(self):
        items=ds.eligible(self.results,0,2_000_000)
        self.assertEqual([x[1] for x in items],["runs/run_1/STATUS.txt"])
        self.assertIsNone(ds.safe_relative(self.raw,self.results))
        self.assertIsNone(ds.safe_relative(self.secret,self.results))
        self.assertIsNone(ds.safe_relative(self.partial,self.results))
    def test_manifest_contains_no_absolute_paths_or_credentials(self):
        result=ds.publish(self.cfg,dry_run=True)
        self.assertEqual(result["files_selected"],1)
        self.assertFalse((self.results/".cloud_sync"/"LATEST.json").exists())
        items=ds.eligible(self.results,0,2_000_000)
        manifest=ds.manifest_for(items,self.results)
        data=json.dumps(manifest)
        self.assertNotIn(str(self.results),data)
        self.assertNotIn("access_token",data)
        self.assertEqual(manifest["files"][0]["scientific_status"],
                         "NOT_AUTOMATICALLY_VALIDATED")
    def test_successful_upload_publishes_manifest_last(self):
        calls=[]
        def mocked_run(command):
            calls.append(command)
            if command[1]=="md5sum":
                payload=(self.results/".cloud_sync"/"LATEST.json").read_bytes()
                return hashlib.md5(payload).hexdigest()+"  LATEST.json\n"
            return ""
        with patch.object(ds,"run",side_effect=mocked_run):
            result=ds.publish(self.cfg)
        self.assertEqual(result["checksum_check"],"PASS")
        stages=[c[1] for c in calls]
        self.assertEqual(stages,["copy","check","copyto","md5sum","copyto"])
        manifest=json.loads((self.results/".cloud_sync"/"LATEST.json").read_text())
        obj=manifest["files"][0]["cloud_object"]
        local=self.results/".cloud_sync"/"objects"/obj
        self.assertTrue(local.is_file())
        self.assertEqual(ds.sha256(local),manifest["files"][0]["sha256"])
    def test_failure_never_writes_remote_latest_pointer(self):
        calls=[]
        def fail_check(c):
            calls.append(c[1])
            if c[1]=="check":
                raise ds.SyncError("bad cloud copy")
            return ""
        with patch.object(ds,"run",side_effect=fail_check):
            with self.assertRaises(ds.SyncError):
                ds.publish(self.cfg)
        self.assertNotIn("copyto",calls)
    def test_changed_run_file_preserves_previous_content_addressed_object(self):
        with patch.object(ds,"run",side_effect=lambda c:
            hashlib.md5((self.results/".cloud_sync"/"LATEST.json").read_bytes()).hexdigest()+" x"
            if c[1]=="md5sum" else ""):
            ds.publish(self.cfg)
            old=next((self.results/".cloud_sync"/"objects").rglob("*.txt"))
            old_hash=ds.sha256(old)
            self.output.write_text("NLD_PROGRESS=2\n")
            ds.publish(self.cfg)
        self.assertEqual(ds.sha256(old),old_hash)
        self.assertEqual(len(list((self.results/".cloud_sync"/"objects").rglob("*.txt"))),2)
    def test_private_account_configuration_required(self):
        self.cfg["data_visibility"]="PUBLIC"
        p=self.root/"bad.json"
        payload={**self.cfg,"local_results_root":str(self.results)}
        p.write_text(json.dumps(payload))
        with self.assertRaises(ds.SyncError):
            ds.config_load(p)

if __name__=="__main__":
    unittest.main()
