-- Proposed canonical data contract for a future journal/AER replication release.
-- Schema alone is NOT evidence that historical result rows were migrated.
PRAGMA foreign_keys=ON;
CREATE TABLE IF NOT EXISTS sources(
 source_sha256 TEXT PRIMARY KEY NOT NULL,
 provider TEXT, survey TEXT, edition TEXT, country TEXT, wave TEXT,
 raw_redistribution_allowed INTEGER NOT NULL DEFAULT 0,
 recovered_from TEXT, recorded_at_utc TEXT
);
CREATE TABLE IF NOT EXISTS producers(
 producer_id TEXT PRIMARY KEY NOT NULL,
 exact_code_sha256 TEXT NOT NULL,
 git_commit TEXT, entrypoint TEXT, estimator_version TEXT,
 survey_design TEXT, pv_method TEXT, replicate_method TEXT,
 environment_lock_sha256 TEXT,
 verified_source_identity INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS analysis_contracts(
 contract_id TEXT PRIMARY KEY NOT NULL,
 survey TEXT NOT NULL, wave TEXT NOT NULL, country TEXT NOT NULL,
 domain TEXT NOT NULL, statistic TEXT NOT NULL, group_definition TEXT,
 ses_construction TEXT, peer_unit TEXT, method_id TEXT,
 scientific_contract_sha256 TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS result_versions(
 result_version_id TEXT PRIMARY KEY NOT NULL,
 contract_id TEXT NOT NULL REFERENCES analysis_contracts(contract_id),
 source_sha256 TEXT REFERENCES sources(source_sha256),
 producer_id TEXT REFERENCES producers(producer_id),
 numeric_artifact_sha256 TEXT NOT NULL,
 numeric_row_id TEXT,
 point_estimate REAL, se REAL, ci_low REAL, ci_high REAL,
 n_unweighted INTEGER, n_effective REAL,
 variance_method TEXT,
 validation_status TEXT NOT NULL CHECK(validation_status IN (
  'HISTORIC_CANDIDATE','COMPUTED_PENDING_VALIDATION',
  'VALIDATED_CONDITIONAL','VALIDATED_RELEASE','BLOCKED','SUPERSEDED')),
 predecessor_result_version_id TEXT REFERENCES result_versions(result_version_id),
 created_utc TEXT NOT NULL,
 UNIQUE(contract_id,numeric_artifact_sha256,numeric_row_id)
);
CREATE TABLE IF NOT EXISTS files(
 sha256 TEXT PRIMARY KEY NOT NULL, bytes INTEGER NOT NULL,
 type TEXT NOT NULL, cloud_object TEXT, privacy_status TEXT,
 original_path_local_only TEXT,
 status TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS file_copies(
 sha256 TEXT NOT NULL REFERENCES files(sha256),
 storage_id TEXT NOT NULL,
 remote_object_id TEXT NOT NULL,
 readback_sha256_verified INTEGER NOT NULL DEFAULT 0,
 full_restore_tested INTEGER NOT NULL DEFAULT 0,
 verified_utc TEXT,
 PRIMARY KEY(sha256,storage_id,remote_object_id)
);
CREATE TABLE IF NOT EXISTS product_releases(
 product_release_id TEXT PRIMARY KEY NOT NULL,
 product_kind TEXT NOT NULL,
 product_source_sha256 TEXT NOT NULL,
 status TEXT NOT NULL,
 published_git_commit TEXT
);
CREATE TABLE IF NOT EXISTS product_result_dependencies(
 product_release_id TEXT NOT NULL REFERENCES product_releases(product_release_id),
 exhibit_id TEXT NOT NULL,
 result_version_id TEXT NOT NULL REFERENCES result_versions(result_version_id),
 PRIMARY KEY(product_release_id,exhibit_id,result_version_id)
);
CREATE TABLE IF NOT EXISTS gc_audit(
 entry_id TEXT PRIMARY KEY,
 original_local_path TEXT NOT NULL,
 artifact_sha256 TEXT NOT NULL REFERENCES files(sha256),
 product_dependency_closure_sha256 TEXT,
 tested_independent_restore_receipt_sha256 TEXT,
 last_usage_checked_utc TEXT,
 action TEXT NOT NULL,
 approval TEXT NOT NULL,
 executed_utc TEXT
);
-- Deletion eligibility must be computed from BOTH independent restorable
-- copies, complete product closure, and a clean-source replicability receipt.
-- Do NOT infer a VALIDATED_RELEASE from presence in a historical CURRENT file.
