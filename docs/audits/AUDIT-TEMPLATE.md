# {{TITLE}}

| Field | Value |
|---|---|
| Audit ID | `{{AUDIT_ID}}` |
| Created (UTC) | {{DATE}} |
| Auditor | Agent/person and tool (self-audit unless stated) |
| Baseline commit | |
| Outcome | `PASS / PASS WITH RISKS / BLOCKED / FAIL` |

## Request and outcome

- Requested behavior and confirmed decisions:
- Implemented behavior:
- Initial Git state and unrelated work preserved:
- Intentional exclusions:

## Changes

| Path | Change | Risk |
|---|---|---|
| | | |

## Verification

Use `PASS`, `FAIL`, `NOT RUN` (with reason) or `N/A`; record exact commands.

| Check | Result | Command / evidence |
|---|---|---|
| Maintenance checkups (`pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause`) | | |
| Dependency audit | | |
| `git diff --check` | | |

## Review

- Secrets and security:
- Docs and user-guide impact:
- Findings, residual risks and blockers:

## Completion

- Commit: `PENDING` (report the hash; do not edit this audit afterwards)
- Human review: pending
- External actions: none unless separately approved

A generated draft is not verification evidence and a self-audit is not an
independent security review.
