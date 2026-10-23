# Rename template tooling and Copilot settings

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T21-00-02Z-rename-template-tooling-and-copilot-settings` |
| Created (UTC) | 2026-10-23T21:00:02.365Z |
| Auditor | Copilot SDK in VS Code; session 21518141-5024-45f0-a573-796c6b0e0b21; self-audit |
| Baseline commit | `79c6b8bc60705bd52610466bcfd82945b198cc78` |
| Outcome | `PASS WITH RISKS` |

## Request and outcome

- Requested behavior and confirmed decisions: rename `.template-tools/` to
  `.template/`; follow-up: rename its `copilot` tool folder to `copilot-settings`.
- Implemented behavior: both directory renames, all active consumers and current
  historical links updated; root CLI, tool entrypoint names and behavior preserved.
- Initial Git state and unrelated work preserved: initially clean at the baseline.
  Another session subsequently added an unrelated designs collection and request
  ledger row. Coordinated via the session messaging tool; preserve both and exclude
  them from this commit, including selective staging of the shared scheduler.
- Intentional exclusions: no settings application, dependency installation, product
  runtime, deployment, remote Git actions or rewriting historical commands/results.

## Changes

| Path | Change | Risk |
|---|---|---|
| [Template tools](../.template/README.md) | Rename parent; preserve all 37 tool files and helpers | Existing relative depths unchanged |
| [Copilot settings](../.template/copilot-settings/README.md) | Rename folder and update catalog, links, examples and disposable fixtures | Script and settings configuration unchanged |
| [Maintenance](../.template/maintenance/README.md), [CI](../.github/workflows/project-tooling.yml) and [presets](../.template/project-types/README.md) | Update runnable paths, package command, fixture roots and tooling exclusions; guard against retired directories | Full checks on both Windows hosts |
| [Agent guide](../AGENTS.md), [task audit skill](../.agents/skills/task-audit/SKILL.md), [README](../README.md) and [CLI guide](../docs/INFRASTRUCTURE.md) | Update current paths; regenerate [HTML](../README.html) | Exact-case links and generated output verified |
| [Historical audits](README.md) and [scheduler](../AGENT_SCHEDULER.md) | Repair current links, record superseding names and task evidence | Historical non-link prose and commands preserved |
| [moorkyz](../moorkyz) | Only selector help paths changed; keep self-contained CLI at root | Exact transformation comparison |

## Verification

All runtime checks used the existing Node.js v24.22.0 installation by prepending
`%LOCALAPPDATA%\Temp\moorkyz-node24\node-v24.22.0-win-x64` to this process's PATH.
The default Node.js v22.18.0 was not used for maintenance; no tools were installed.

| Check | Result | Command / evidence |
|---|---|---|
| README generation | PASS | `node .\moorkyz readme`; initial parent-only generation and final generation succeeded |
| Transient HTML write | FAIL, corrected | One final-generation attempt returned `UNKNOWN` opening README.html; standard generator retry succeeded without permission changes or source workarounds |
| Parent-only maintenance | PASS | `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause`: 4 passed, 0 failed before follow-up folder rename |
| Final PowerShell 7 maintenance | PASS | `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause`: **4 passed, 0 failed** |
| Final Windows PowerShell 5.1 maintenance | PASS | `powershell -NoProfile -ExecutionPolicy Bypass -File .\.template\maintenance\RunCheckups.ps1 -NoPause`: **4 passed, 0 failed** |
| Preset and Copilot action coverage | PASS | Full suites exercise all nine presets individually/combined through both PowerShell hosts and CMD, plus success/rerun, backups, previews, validation/aggregated failures and isolated user scopes for the renamed Copilot tool |
| Preservation and retired paths | PASS | Session-only `verify-template.cjs`: all 37 moved files present, 18 byte-identical; all 22 historical reports retain non-link evidence; no retired active paths or old tool directories |
| Adoption action regressions | PASS | `node <session-files>\verify-template.cjs`: preview writes nothing, node+web adoption from an outside CWD, HTML regeneration, guide/user preservation and byte-identical rerun on pwsh and powershell.exe; disposable fixtures removed |
| Mechanical diff review | PASS | Session-only `review-rename.cjs`: 71 tracked files exactly match approved path/link transformations, original binary bytes or generated HTML; eight manual documentation/ledger/regression diffs reviewed separately |
| Dependency audit | N/A | Stack-neutral root has no package manifest/lockfile; no dependencies added |
| Linux execution | NOT RUN | Windows environment; cross-platform CI entrypoint updated but CI not triggered |
| `git diff --check` | PASS | `git -c core.safecrlf=false --no-pager diff --check`; no whitespace errors |
| Final documentation and index | PASS | `pwsh -NoProfile -File .\.template\maintenance\helpers\checkups\02-documentation.ps1`; exact-case links, fresh HTML and current names PASS. `git -c core.safecrlf=false --no-pager diff --cached --check` PASS; 66 task files including 37 detected renames; unrelated designs and request row excluded |

## Review

- Secrets and security: direct self-review of the scoped changes found no added
  credentials, private settings, packages, permissions or external runtime requests.
  CLI runtime, setup implementation and settings configuration remain unchanged;
  only discovery/help strings and test fixture paths changed. Binary assets are
  preserved. Existing selector traversal/link/overwrite protection and Copilot
  explicit failure handling remain covered by the maintenance fixtures.
- Docs and user-guide impact: current tooling, CI, presets, catalog, contribution/
  agent guidance and both README editions use the final names. Historical audits
  retain their observed commands/results while their links resolve to current files.
- Findings, residual risks and blockers: no implementation blocker remains.
  Existing consumers outside this repository must update old paths themselves.
  Unrelated concurrent design work is excluded from scope. Human/independent
  security review and Linux execution have not been performed.

## Completion

- Commit: `PENDING` (report the hash; do not edit this audit afterwards)
- Human review: pending
- External actions: none unless separately approved

A generated draft is not verification evidence and a self-audit is not an
independent security review.
