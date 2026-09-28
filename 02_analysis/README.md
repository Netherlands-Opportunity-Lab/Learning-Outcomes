# 02 — Analysis

## Current production

`current/EXECUTED_COMPLETION_SCRIPT_SANITISED.R` is the canonical analysis implementation for this release. It is the executed final completion script with only a user-specific fallback path sanitised.

The final product basis contains 283,284 estimates. The scientific release uses explicit status fields; it does not promote blocked/unavailable cells to zero or silently change specifications.

## Release registers

`release_registers/` contains the compact final status, validation, use-status, impact, change/loss and task-status files used downstream.

## Archived code

`archive_or_superseded/` contains earlier RC1 normalisation, results-factory and sorting scripts. They remain for reproducibility/history and are not current entry points.
