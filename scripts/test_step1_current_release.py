"""Adversarial tests for reuse of already accepted scientific evidence."""
import copy
import hashlib
import tempfile
import unittest
from pathlib import Path

from verify_step1_current_release import check_identities, check_runtime, keyed


class EvidenceReuseTests(unittest.TestCase):
    def fixture(self):
        identity = dict(cell_id="one", country="NLD", status="SCIENTIFICALLY_VALIDATED",
                        target_contract_sha256="task", result_hash="result")
        coverage = dict(identity, source_edition_sha256="source", input_fingerprint="input",
                        certification_sha256="certificate", code_fingerprint="code",
                        main_reason="RESULT_AVAILABLE")
        result = dict(coverage, producer_fingerprint="code",
                      estimate="0", standard_error="0.2", n_unweighted="40")
        return {"one": identity}, {"one": coverage}, {"one": identity.copy()}, {"one": result}

    def test_valid_zero_survives(self):
        self.assertEqual(check_identities(*self.fixture()), 1)

    def test_changed_source_rejected_even_with_unchanged_counts(self):
        args = self.fixture()
        args[3]["one"]["source_edition_sha256"] = "different"
        with self.assertRaisesRegex(ValueError, "Result binding"):
            check_identities(*args)

    def test_removed_approved_target_rejected(self):
        args = self.fixture()
        args[1].clear()
        with self.assertRaisesRegex(ValueError, "identity set"):
            check_identities(*args)

    def test_unavailable_cannot_mask_valid_zero(self):
        args = self.fixture()
        args[1]["one"]["main_reason"] = "ANALYTIC_GROUP_UNUSABLE"
        with self.assertRaisesRegex(ValueError, "reason disagrees"):
            check_identities(*args)

    def test_extra_result_rejected(self):
        args = self.fixture()
        args[3]["unapproved"] = copy.deepcopy(args[3]["one"])
        with self.assertRaisesRegex(ValueError, "unapproved"):
            check_identities(*args)

    def test_duplicate_result_rejected(self):
        with self.assertRaisesRegex(ValueError, "Duplicate"):
            keyed([{"cell_id": "one"}, {"cell_id": "one"}])

    def test_changed_runtime_and_scientific_amendment_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = "06_pipeline/LO_PARTIAL_DASHBOARD_RELEASE.py"
            (root / path).parent.mkdir()
            (root / path).write_bytes(b"approved-publication-code")
            digest = hashlib.sha256(b"approved-publication-code").hexdigest()
            bindings = [dict(path=path, sha256="before")]
            amendment = dict(frozen_public_scientific_manifest_sha256="manifest",
                             runtime_changes=[dict(path=path, before_sha256="before",
                                                   after_sha256=digest)])
            check_runtime(root, bindings, amendment, "manifest")
            (root / path).write_bytes(b"changed-code")
            with self.assertRaisesRegex(ValueError, "Changed evidence"):
                check_runtime(root, bindings, amendment, "manifest")
            amendment["runtime_changes"][0]["path"] = "06_pipeline/LO_EXACT_ESTIMATORS.R"
            with self.assertRaisesRegex(ValueError, "publication gate"):
                check_runtime(root, bindings, amendment, "manifest")


if __name__ == "__main__":
    unittest.main()
