# Archive retention and hidden audit history

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T21-14-08Z-archive-retention-and-hidden-audit-history` |
| Created (UTC) | 2026-10-23T21:14:08.272Z |
| Auditor | Copilot SDK in VS Code; session 21518141-5024-45f0-a573-796c6b0e0b21; self-audit |
| Baseline commit | `d4eb6965e3ab7ddff9ed660d11bc301476d82519` |
| Outcome | `PASS WITH RISKS` |

## Request and outcome

- Requested behavior and confirmed decisions: move reports to `.audits/`, remove
  the old audit folders, put `AUDIT_TEMPLATE.md` directly in `docs/`, remove trash
  staging and configure archive capacity, oldest/largest pruning and age in days.
- Implemented behavior: preserve report history and move its template; update CLI,
  adoption, checkups and guidance. Archive retention deletes expired eligible ZIPs
  first, then prunes in configured order to the compressed-byte cap while
  preserving existing free-space safeguards and live/new-archive protections.
- Defaults: user unavailable to answer the clarification form; chose 100 decimal
  GB, oldest-first, 30 days and existing automatic/manual cleanup timing. All are
  documented/configurable; age `0` disables expiry. No system scheduler installed.
- Initial Git state and unrelated work preserved: unrelated untracked designs and
  another session's request-ledger row were already present. Keep them unchanged
  and outside this focused commit; selectively stage only task-owned scheduler edits.
- Intentional exclusions: no historic reports deleted, no live archive/log cleanup,
  new dependencies, package installation, deployment or remote Git actions. The
  existing trash folder was verified empty and removed nonrecursively.

## Changes

| Path | Change | Risk |
|---|---|---|
| [.audits/](README.md) and [audit template](../docs/AUDIT_TEMPLATE.md) | Move report history and template, repair links and generation/discovery paths | All 23 historical reports retain non-link evidence; template contents unchanged |
| [moorkyz](../moorkyz) | Replace trash policy/staging with validated archive byte cap, age and oldest/largest order; preserve logs, leases, verification and free-space safeguards | Permanent archive deletion is intentional; warnings expose unmet limits |
| [Storage regressions](../.template/maintenance/helpers/checkups/05-storage.ps1) | Add read-only entrypoint with 11 disposable action-regression groups | No actions target existing user/repository data |
| [Maintenance](../.template/maintenance/README.md), [adoption](../.template/claim-template/CreateProject.ps1), [preset config](../.template/project-types/helpers/types/node/moorkyz.config.example.json) and ignore files | Discover new report/template paths, preserve adopted history, remove trash defaults/ignores and expose archive settings | Retired settings fail explicitly rather than silently changing meaning |
| [README](../README.md), [HTML](../README.html), [CLI guide](../docs/INFRASTRUCTURE.md), [agent guide](../AGENTS.md) and [audit skill](../.agents/skills/task-audit/SKILL.md) | Document current layout, defaults, configuration, triggers and deletion/protection boundaries | HTML regenerated and local links verified |

## Verification

Runtime checks used existing Node.js v24.22.0 by prepending
`%LOCALAPPDATA%\Temp\moorkyz-node24\node-v24.22.0-win-x64` to process PATH.
The first syntax-only `node --check` used existing Node.js v22.18.0; functional
maintenance/regressions use the pinned major 24. No dependencies were installed.

| Check | Result | Command / evidence |
|---|---|---|
| CLI syntax | PASS | `node --check .\moorkyz`, including the Node 24 focused-validation invocation |
| Focused storage/audit regressions | PASS | `pwsh -NoProfile -File .\.template\maintenance\helpers\checkups\05-storage.ps1`: **11 groups** |
| Exact policy behavior | PASS | Defaults and invalid/legacy inputs; at-cap retention and one-byte overflow; oldest versus largest order and oldest tie-breaker; age boundary, UTC-name age despite modified mtime, disabled expiry and expiry before capacity pruning |
| Storage safety and integration | PASS | Protected paths/live leases counted and preserved; canonical non-ZIP data, noncanonical user files and junctions preserved; chosen-order free-space pruning; new archive protected for creation pass then later pruned; log rotation/live log leases; CLI warnings and actual maintenance |
| Audit/adoption integration | PASS | Actual CLI reports go only to `.audits/` using `docs/AUDIT_TEMPLATE.md`; missing template fails clearly; dry-run stays no-op; project adoption preserves historical placeholder text |
| PowerShell 7 full maintenance | PASS | `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause`: **5 passed, 0 failed** |
| Windows PowerShell 5.1 full maintenance | PASS | `powershell -NoProfile -ExecutionPolicy Bypass -File .\.template\maintenance\RunCheckups.ps1 -NoPause`: **5 passed, 0 failed** |
| README generation/documentation | PASS | `node .\moorkyz readme`; `pwsh -NoProfile -File .\.template\maintenance\helpers\checkups\02-documentation.ps1`: exact-case local links, HTML freshness, report/template layout, current names and ignore boundaries |
| History/layout preservation | PASS | Session-only `verify-audit-move.cjs`: **23 reports** retain all non-link evidence; template contents unchanged; obsolete folders absent; `.audits/` not Git-ignored; live archive/log folders remain empty |
| Verification-helper correction | FAIL, corrected | Initial session-only ignore-output assertion did not accept Git's quoted Windows path. Accepted optional quoting; rerun PASS. No production changes required |
| Whitespace | PASS | `git -c core.safecrlf=false --no-pager diff --check` |
| Focused staged review | PASS | `git -c core.safecrlf=false --no-pager diff --cached --check`; 47 task files including 25 renames; shared scheduler equals baseline plus approved link migration/own closure, excluding the other session's row; designs excluded |
| Dependency audit | N/A | Stack-neutral root has no application package manifest/lockfile; no new dependencies |
| Linux execution | NOT RUN | Windows-only local environment; cross-platform maintenance CI remains configured but was not triggered |

## Review

- Secrets and security: reviewed runtime diff for credentials, input validation,
  dependencies, error handling and data loss. No credentials, permissions or
  dependencies added. Sizes/ages are validated safe integers, order is an explicit
  enum, and retired trash inputs fail clearly. Pruning is limited to canonical
  regular ZIP candidates, rejects changed files before unlinking, respects scoped
  paths/live leases and preserves non-ZIP data. Existing archive CRC/SHA verification
  and source rechecks remain intact. All action regressions use disposable copies.
- Docs and user-guide impact: current report/template links, CLI help/doctor,
  adoption exclusions, agent workflow, examples and both README editions agree.
  Historical report prose/results remain historical; only their links are repaired.
- Findings, residual risks and blockers: no task blocker remains. Retention deletes
  archives permanently; durable backups belong elsewhere. Existing low-space
  safeguards may prune before size/age limits. New/live/protected or malformed ZIP
  candidates can prevent compliance; warnings/result flags expose this. Noncanonical
  files are outside the managed budget and never pruned. Cleanup is operation-driven,
  not a folder script or an always-running service; wall-clock expiry while idle
  requires an external scheduler. Classic ZIP size limits and racing-writer caveats
  remain documented. Linux, independent security and human review are not performed.

## Completion

- Commit: `PENDING` (report the hash; do not edit this audit afterwards)
- Human review: pending
- External actions: none unless separately approved

A generated draft is not verification evidence and a self-audit is not an
independent security review.
