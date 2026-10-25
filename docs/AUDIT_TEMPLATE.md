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

## Analyzing and Reading

- Guides, affected source/consumers, documentation and tests read:
- Acceptance criteria and edge cases:
- Scope, constraints and preserved unrelated work:

## Researching and Planning

- Existing helpers/tools and authoritative, version-specific sources checked:
- Chosen approach, affected outputs and verification plan:
- Assumptions, dependencies and required approvals:

## Developing

- Implemented behavior and related tests/docs:
- Deviations from the plan and intentional exclusions:

| Path | Change | Risk |
|---|---|---|
| | | |

## Clean Up

### Verification

Use `PASS`, `FAIL`, `NOT RUN` (with reason) or `N/A`; record exact commands.

| Check | Result | Command / evidence |
|---|---|---|
| Maintenance checkups (`pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause`) | | |
| Dependency audit | | |
| `git diff --check` | | |
| Final-state rechecks after corrections/regeneration | | |

### Quality and safety review

- Correctness, best practices, redundancy/dead code and unnecessary complexity:
- Compatibility, error handling and coverage:
- Secrets and security:
- Self-reviewer, scope and findings:
- Independent review and required approvals (name/status; not implied by tests):
- Findings, residual risks and blockers:

### Final references and documentation

| Reference / content | Availability / validity | Command / source / evidence and impact |
|---|---|---|
| Changed code references, consumers, paths/casing, assets, commands and configuration | | |
| Supported APIs/dependencies and local links/anchors | | |
| Changed external references and version-specific claims | | |

- Unreachable or unverifiable content, impact and required follow-up:
- Docs, examples, generated outputs and queue evidence updated:
- Task-created temporary files removed (existing data preserved):
- Final affected tests, quality and reference checks repeated after updates:

### Completion

- Commit: `PENDING` (report the hash; do not edit this audit afterwards)
- Staged diff and `git diff --cached --check`:
- Human review: pending
- Required checks/approvals and completion or handoff status:
- External actions: none unless separately approved

A generated draft is not verification evidence and a self-audit is not an
independent security review.
