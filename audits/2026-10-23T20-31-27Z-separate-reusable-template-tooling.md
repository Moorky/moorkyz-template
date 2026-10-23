# Separate reusable template tooling

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T20-31-27Z-separate-reusable-template-tooling` |
| Created (UTC) | 2026-10-23T20:31:27.906Z |
| Auditor | Copilot SDK in VS Code, session e8efba40-e5dd-47c9-8b13-4bb454921d80; self-audit |
| Baseline commit | `4def315a0eef0f4ba2a3a65dfe698788b00d6c88` |
| Outcome | `PASS WITH RISKS` |

## Request and outcome

- Requested behavior and confirmed decisions: reusable template tooling must not
  be named as project-owned scripts. Use the announced `.template-tools/` parent.
  Preserve the root CLI, one-time `claim-template` name and completed setup behavior.
- Implemented behavior: all four tools now live under
  [.template/](../.template/README.md), retaining entrypoints, adjacent
  READMEs and nested helpers. The old parent was removed; current consumers and
  guidance distinguish template tools from application code and project-owned tooling.
- Initial Git state and unrelated work preserved: the repository was initially
  unborn/untracked. An external initial commit appeared during implementation.
  Compared every blob and path with the captured pre-move snapshot: its 78 files
  exactly match, allowing Git's newline normalization. Only this task's changes
  and report are eligible for the focused commit; no baseline initialization by
  this session, no unrelated content discarded.
- Intentional exclusions: no product runtime, dependency installation, settings
  changes, live storage actions, root CLI relocation or restored bundled tests.
  Historical report commands, results and owner decisions remain historical;
  only their current Markdown links/labels were remapped.

## Changes

| Path | Change | Risk |
|---|---|---|
| [.template/](../.template/README.md) | Rename shared parent and clarify template-only purpose; preserve all four tools and helpers | All 78 original files accounted for; 32 byte-identical and 46 scoped text edits before this report |
| [Project types](../.template/project-types/SetProjectType.ps1) and [Claim Template](../.template/claim-template/CreateProject.ps1) | Update parent paths, preserve shared-parent write protection and one-time adoption | Disposable preview/apply/rerun and protected-target checks |
| [Maintenance](../.template/maintenance/README.md), [CI](../.github/workflows/project-tooling.yml), preset configs | Update entrypoint, fixture, ignore and package-command paths; assert template catalog title | Both-host full checks and all nine presets through both PowerShell hosts and CMD |
| [Agent guide](../AGENTS.md), [task-audit skill](../.agents/skills/task-audit/SKILL.md), root docs and [audit template](../docs/audits/AUDIT-TEMPLATE.md) | Update current paths and appropriate tool-discovery guidance; regenerate HTML | Exact-case links and HTML freshness checked |
| [moorkyz](../moorkyz) | Keep at root; update only the project-type selector guidance string | Exact comparison proves runtime code unchanged |
| [Prior audits](README.md) and [scheduler](../AGENT_SCHEDULER.md) | Repair current links, preserve historical evidence, record superseding name | Historical report prose/commands independently compared outside Markdown links |

## Verification

All Node checks used existing Node.js v24.21.0 on PATH. No packages were installed.
The two full-run commands used the existing PowerShell 7 and Windows PowerShell
5.1 executables respectively, with `-NoLogo -NoProfile -NonInteractive
-ExecutionPolicy Bypass`; the bypass was process-only, not a persistent policy change.

| Check | Result | Command / evidence |
|---|---|---|
| README generation and CLI syntax | PASS | `node .\moorkyz readme`; `node --check .\moorkyz` |
| First complete run, both hosts | FAIL, corrected | Each reported 3 passed / 1 failed: a mechanical rename touched JavaScript `.scripts` property access. Restored npm property names in the CLI and preset checkup; no such changes remain in the final runtime diff |
| Focused preset rerun | PASS | `pwsh -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\.template-tools\maintenance\helpers\checkups\03-project-types.ps1`: all nine presets on pwsh, powershell.exe and CMD, plus combined preview/apply/rerun and failure preservation |
| Full PowerShell 7 maintenance | PASS | `pwsh -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\.template-tools\maintenance\RunCheckups.ps1 -NoPause`: **4 passed, 0 failed** |
| Full Windows PowerShell 5.1 maintenance | PASS | `powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\.template-tools\maintenance\RunCheckups.ps1 -NoPause`: **4 passed, 0 failed** |
| Focused rename regressions | PASS | Session-only `Verify-TemplateTools.cjs`: **10 checks**. On each host: outside-CWD adoption preview/apply/rerun, node+web/helper paths, HTML regeneration, existing guide preservation and rejection of writes into another shared tool. Actual CLI doctor/npm-test behavior also passed |
| Fixture harness corrections | FAIL, corrected | Initial fixture omitted the pre-existing HTML edition required by adoption's regeneration condition, then assumed backslashes in the cross-platform preset command. Seeded stale HTML and accepted either separator; no production behavior changed for these fixture mistakes |
| Preservation and active-name scan | PASS | All 78 pre-move files found; 32 byte-identical, including existing setup/configuration and assets. No active old-parent paths across dotfiles, extensionless CLI, presets, sources or either README edition. Root CLI comparison permits only the selector-help path update |
| Actual diff and baseline review | PASS | Session-only `Review-TemplateTools.cjs`: baseline matches 78 pre-move files; reviewed 46 changed-file diffs, with 38 mechanical path/link transformations independently asserted and eight manual/generated/ledger diffs inspected |
| Dependency audit / npm baseline verification | N/A | Root intentionally has no package manifest or lockfile and this task adds no dependencies; configured verification is maintenance, not an invented npm application |
| Whitespace and focused index | PASS | `git -c core.safecrlf=false --no-pager diff --check`; all 38 new/moved files also checked individually with `git -c core.safecrlf=false --no-pager diff --no-index --check -- NUL <file>` (no diagnostics; exit 0/1 accepted for no-index differences). `git -c core.safecrlf=false --no-pager diff --cached --check` passed; staged content matched reviewed worktree, 37 renames recognized across 65 task files |
| Final documentation links and HTML | PASS | `pwsh -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\.template-tools\maintenance\helpers\checkups\02-documentation.ps1`: exact-case links across reports, fresh HTML, catalog/layout, active names, icons/CI and existing safeguards passed |

## Review

- Secrets and security: reviewed task diffs for credentials, logging, input
  validation, dependencies, failures and data loss. No secrets, private settings,
  new packages, external requests or permissions changes introduced. Existing
  configuration values and asset bytes were preserved. Preset link/junction and
  whole-template-parent protections remain; explicit malicious-target fixtures
  reject before copying. Copilot final status, safe modes and existing-guide
  preservation remain covered by checkup 04.
- Docs and user-guide impact: catalog, main guide, contribution/agent guidance,
  CI, preset commands/ignores, audit template and current historical links use the
  new parent. The generated HTML matches Markdown. Historical commands and owner
  choices are not rewritten as if they ran under today's name.
- Findings, residual risks and blockers: direct parent rename was denied by both
  Node and native PowerShell. Moved hash-verified files with no overwrite or
  permission changes, then removed only verified-empty old directories; no old
  tooling parent remains. The previously empty legacy `.github/copilot` directory
  is still present and untouched; it has no files or Git content. Independent
  security review and human review have not been performed. Linux execution and
  manual keyboard interaction were not run locally; the existing CI matrix and
  unchanged menu logic remain. No task implementation or verification blocker.
- Data safety: all action-level regressions used uniquely named disposable
  project/user/cache directories and removed those fixtures. No cleanup,
  adoption, setup or retention action targeted existing repository/user data.
  Session-only migration, verification and diff scratch files are removed after
  recording their results; no temporary tooling is committed.

## Completion

- Commit: `PENDING` (report the hash; do not edit this audit afterwards)
- Human review: pending
- External actions: none unless separately approved

A generated draft is not verification evidence and a self-audit is not an
independent security review.
