# Copilot setup results and root launcher

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T20-02-22Z-copilot-setup-results-and-root-launcher` |
| Created (UTC) | 2026-10-23T20:02:22.534Z |
| Auditor | Copilot SDK in VS Code, session a8a12d5f-6531-4d46-9aa1-825e25a46bc4; self-audit |
| Baseline commit | None: unborn master; all baseline files already untracked |
| Outcome | `PASS WITH RISKS`; implementation verified, focused commit blocked by baseline |

## Request and outcome

- Requested behavior: Copilot setup must say whether configuration succeeded,
  report everything set or list what failed, and keep `moorkyz` at the root.
- Restored the byte-identical CLI from `.scripts/moorkyz/moorkyz` to root
  [moorkyz](../moorkyz). The newer root exception was coordinated with the active
  script-consolidation owner; the other four tools remain under `.scripts/`.
- Setup now reports `ALL SET` only for successful requested configuration steps,
  or `FAILED` with each step/error and exit code 1. Independent steps continue
  after failures; successful changes remain for an idempotent retry.
  Invalid configuration stops before any writes. `-WhatIf` reports `PREVIEW ONLY`;
  declined changes report `INCOMPLETE` and a nonzero status.
- Success, preview and failure end with a visible key prompt. `-NoPause` disables
  it, redirected input never blocks, and `-DryRun` returns before reads or prompts.
  The success message explicitly distinguishes configuration from installed
  extensions, sign-in, model availability and effective sandbox protection.
- Initial Git state: unborn branch with all files untracked, not a clean
  committed baseline. Preserved other agents' layout/guidance edits and local
  runtime folders. No files staged, no initial-baseline commit manufactured.
- Exclusions: no actual VS Code/user settings changes, no credential installation,
  no model-provider changes, no storage cleanup, no dependency installation,
  no application stack or deployment work.

## Changes

| Path | Change | Risk |
|---|---|---|
| [Copilot setup](../.template-tools/copilot/Setup-CopilotProject.ps1) | Per-step failure collection, final result/exit status, validation before writes, visible completion and NoPause | Successful partial writes are retained, not rolled back; reported explicitly |
| [Copilot guide](../.template-tools/copilot/README.md) | Result semantics, automation option, manual verification boundary | ALL SET is not Copilot service-health verification |
| [Root CLI](../moorkyz), [project setup](../.template-tools/claim-template/CreateProject.ps1), [runnable check](../.template-tools/maintenance/helpers/checkups/01-runnables.ps1), [documentation check](../.template-tools/maintenance/helpers/checkups/02-documentation.ps1) | Root entry restored, callers fixed, root-location regression guard | CLI logic unchanged |
| [Copilot regression check](../.template-tools/maintenance/helpers/checkups/04-copilot-setup.ps1) | Disposable project/profile tests on available PowerShell hosts | Only newly created fixture directories are removed |
| [README](../README.md), [HTML](../README.html), [CLI guide](../docs/INFRASTRUCTURE.md), [maintenance guide](../.template-tools/maintenance/README.md), [project-types guide](../.template-tools/project-types/README.md), [contribution guide](../CONTRIBUTING.md), [agent guide](../AGENTS.md), [task-audit skill](../.agents/skills/task-audit/SKILL.md), [audit index](README.md) and historical audit links | Current root path, status behavior and verification documentation; generated HTML kept fresh | Historical observed test results unchanged; concurrent discovery guidance retained |
| [Scheduler](../AGENT_SCHEDULER.md) | Record newer root exception, coordination, evidence and commit blocker | Existing claims preserved |

## Verification

Node.js was the existing local **v24.22.0** distribution under
`%TEMP%\moorkyz-node24\node-v24.22.0-win-x64`, prepended to PATH in each validation
process. System-default Node is v22.18.0 and was not used for baseline checks.

| Check | Result | Command / evidence |
|---|---|---|
| Full maintenance, PowerShell 7 | PASS | `pwsh -NoLogo -NoProfile -File .\.scripts\maintenance\RunCheckups.ps1 -NoPause`: **4 passed, 0 failed** |
| Full maintenance, Windows PowerShell 5.1 | PASS | `powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\.scripts\maintenance\RunCheckups.ps1 -NoPause`: **4 passed, 0 failed** |
| Focused Copilot action checks | PASS | `pwsh -NoLogo -NoProfile -NonInteractive -File .\.scripts\maintenance\helpers\checkups\04-copilot-setup.ps1`: both hosts pass success/rerun, JSONC backups/unrelated settings and instructions preserved, WhatIf/DryRun snapshots, four validation errors without writes, three failures aggregated with independent success, missing template, redirected prompt success/failure/preview, Stable/Both and Insiders/Global isolated profiles |
| Runnable/CLI coverage | PASS | Full runner parses/checks **12 runnable sources**, including the new checkup and root entry, and exercises all **20** public CLI no-op commands |
| Existing preset coverage | PASS | All nine presets individually/combined through both PowerShell hosts and CMD; disposable preview/apply/rerun/conflict/source-preservation checks |
| Root CLI and HTML generation | PASS | `node --check moorkyz`; `node moorkyz readme`; `node moorkyz doctor`. Doctor correctly reports no root package.json; audit template and root runtime location detected |
| Root setup consumers | PASS | PowerShell here-string piped to `node -`: disposable copies without `.git`; both hosts run `CreateProject.ps1 -Yes -NoPause -WhatIf`, apply and rerun; root CLI found, README title and generated HTML correct; CommonJS API and ESM CLI help work |
| Final documentation after README/ledger edits | PASS | `node moorkyz readme`; `pwsh -NoLogo -NoProfile -File .\.scripts\maintenance\helpers\checkups\02-documentation.ps1`: exact-case local links, fresh HTML, root exception, catalog/guidance and safety assertions |
| `git diff --check` | PASS, limited | No tracked diff errors; all baseline files are untracked, so this cannot certify a task-only patch |
| Runtime ignore boundaries | PASS | `git check-ignore .trash .logs .archive .moorkyz`: all four remain ignored |
| Secret-pattern scan | PASS, limited | Targeted scan of changed setup/checkup, root CLI and related docs for private-key headers, GitHub token formats and secret-key patterns: no matches |
| `npm ci --ignore-scripts`, `npm run verify`, dependency audit | N/A | Current stack-neutral root intentionally has neither package.json nor lockfile; no new dependency or manifest. Used the documented maintenance entrypoint instead of inventing an application baseline |
| Linux/macOS and physical console-key interaction | NOT RUN | Windows environment only; redirected-input and NoPause behavior tested. CI was not invoked |

## Review

- Secrets/security self-review: no credentials, provider settings, new external
  commands, third-party dependencies or changed approval permissions introduced.
  Failure paths are surfaced rather than replaced with success. JSON backups,
  unrelated settings, existing instructions and empty optional MCP behavior remain.
  New tests isolate APPDATA per child process and do not invoke configured MCP
  commands. Source snapshots verify the setup files remain unchanged by tests.
  Only each test's newly created temporary workspace is removed in finally.
- The original CLI content was moved without behavior edits; safety/retention
  behavior and ignored user data were not exercised destructively. Current
  root consumers and links are covered by documentation/runnable checks.
- Reviewed implementation against the original setup code and observed regression
  outcomes. There is no committed original to obtain a trustworthy task-only Git
  diff; staging whole untracked files would capture unrelated baseline work.
- Initial harness run failed because its invocation duplicated ProjectPath/Scope.
  Corrected the fixture argument defaults; the focused check then passed on both
  hosts, followed by both full successful runners. This was a test-harness error,
  not hidden as a product pass.
- Residual risks: settings write success does not prove Copilot sign-in, model
  access or sandbox protection. Users must verify these in VS Code. A partial
  failure retains successful configuration, explicitly disclosed for retry.
  Interactive key handling and non-Windows behavior remain unverified locally.
- Commit blocker: `git rev-parse --verify HEAD` fails because the branch has no
  commit. No narrow task commit can separate these edits from other owners'
  untracked baseline files. Owner-controlled baseline establishment/review is
  required before a focused commit; do not auto-stage the repository.

## Completion

- Commit: `NOT CREATED` (unborn/untracked baseline blocker; index left untouched).
- Human review: pending; implementation self-reviewed, not independently approved.
- External actions: none; no push, PR, deployment, package download or user-settings change.

A generated draft is not verification evidence and a self-audit is not an
independent security review.
