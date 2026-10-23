# Replace example tests with safe maintenance checkups

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T19-19-45Z-replace-example-tests-with-safe-maintenance-checkups` |
| Created (UTC) | 2026-10-23T19:19:45.639Z |
| Auditor | AI assistant using Copilot SDK in VS Code; self-audit |
| Baseline commit | None: unborn `master`, empty index, existing baseline entirely untracked |
| Outcome | `PASS WITH RISKS` for implementation; focused local commit blocked by unborn baseline |

## Request and outcome

- Requested: remove bundled example tests; add one maintenance runner and a
  checkups directory; execute every checkup, stream terminal results and end with
  "Press any key to exit". Clarification: check all scripts/runnables without
  performing their actions; add safe parameter options where needed.
- Implemented: ordered, isolated PowerShell checkups, per-checkup RUN/PASS/FAIL,
  continued execution after failures, aggregate results, meaningful exit codes,
  any-key exit, redirected-input handling, `-NoPause` and a no-op `-DryRun`.
- Runnable checkup discovers all 10 current runnable sources, parses every
  PowerShell script and invokes only its no-op mode, syntax-checks JavaScript
  without importing modules, and checks all 20 public CLI commands in dry-run
  mode. Documentation checks are read-only.
- Initial Git state: no commits or tracked files. Existing runtime data and all
  unrelated work were preserved. Concurrent owner tasks moved Copilot setup into
  `.github/copilot/` and project type payloads into `.projecttypes/types/`;
  coordinated safe-mode preservation and documentation links with those owners.
- Intentional exclusions: no application runtime, deployment, dependency install,
  real setup, package-script execution, storage cleanup or action-level checks
  against existing data. Former lifecycle/storage regression coverage is retired
  at the owner's request, not claimed as equivalent to these no-op checks.

## Changes

| Path | Change | Risk |
|---|---|---|
| [maintenance/](../.template-tools/maintenance/README.md) | One runner and two read-only checkups; usage and extension contract | Custom checkups are trusted code, not a sandbox |
| `tests/` | Removed all six bundled test files and the now-empty directory | Previous action-level regression coverage is no longer shipped |
| [moorkyz](../moorkyz) | Global `--dry-run` exits before command execution/configuration loading; rejects unknown command names | Checks entrypoint/command name only, not action arguments or behavior |
| [selector](../.template-tools/project-types/SetProjectType.ps1), [project setup](../.template-tools/claim-template/CreateProject.ps1), [Copilot setup](../.template-tools/copilot/Setup-CopilotProject.ps1) | Early no-op `-DryRun`; existing CMD wrapper forwards it unchanged | Existing `-WhatIf` remains the input-aware preview |
| [Copilot setup](../.template-tools/copilot/Setup-CopilotProject.ps1) | Resolve default ConfigPath after no-op guard instead of in parameter binding | Necessary for PowerShell 5.1 `-File` invocation; explicit ConfigPath semantics retained |
| [tooling CI](../.github/workflows/project-tooling.yml), [Node starter](../.template-tools/project-types/helpers/types/node/package.json) | Maintenance runner replaces empty/example test commands; npm scripts require `pwsh` | Linux workflow configured but not executed locally |
| [setup defaults](../.template-tools/claim-template/helpers/setup.config.json), [setup guide](../.template-tools/claim-template/README.md) | Remove obsolete test-removal default; retain maintenance checks after adoption | Setup itself was not applied to this repository |
| [README Markdown](../README.md), [README HTML](../README.html), [CLI guide](../docs/INFRASTRUCTURE.md), [contributing](../CONTRIBUTING.md), [project types](../.template-tools/project-types/README.md), [Copilot guide](../.template-tools/copilot/README.md) | Current checkup commands, safe options and limitations; HTML regenerated | Shared docs integrate concurrent owner work |
| [agent guide](../AGENTS.md), [scheduler](../AGENT_SCHEDULER.md), [audit skill](../.agents/skills/task-audit/SKILL.md), [audit template](../docs/audits/AUDIT-TEMPLATE.md), [audit index](README.md) | Verification guidance and task evidence; explicitly document retired coverage | Self-review only |

## Verification

Verification used the already-cached Node.js **24.21.0** executable, prepended to
PATH for each invocation. System Node is 22.18.0; no runtime/package was downloaded.
`<session-files>` below denotes the private session workspace outside the
repository, not a shipped test directory. Disposable fixtures and session probes
were cleaned up after verification; their source and output remain in the tool
transcript, not the repository.

| Check | Result | Command / evidence |
|---|---|---|
| CLI syntax | PASS | `node --check moorkyz` |
| Full runner, PowerShell 7 | PASS | `pwsh -NoProfile -File .\maintenance\RunCheckups.ps1 -NoPause`; 2/2 checkups, 10 runnable files, 20 CLI commands, documentation links and README freshness |
| Full runner, Windows PowerShell 5.1 | PASS | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\maintenance\RunCheckups.ps1 -NoPause`; 2/2 checkups, same coverage |
| Disposable regressions | PASS | `node --test "<session-files>\maintenance-verification.cjs"`; 19/19 passed, zero skipped; both hosts exercised |
| Existing behavior compatibility | PASS | `node --test --test-name-pattern 'existing selector\|Copilot setup still' "<session-files>\maintenance-verification.cjs"`; 4/4 focused cases passed: selector positional arguments, read-only WhatIf, actual fixture-only copies and unchanged reruns, plus default Copilot config resolution and no-write WhatIf on both hosts |
| Regression assertions | PASS | Ordering, isolated root cwd, streamed output, exit/throw failures with later checks still run, missing/empty folders, no-op runner, redirected input, all PowerShell/CMD safe modes, unsupported/malformed runnable rejection, stale HTML and broken links |
| No-side-effects evidence | PASS | Disposable regression probe compared complete fixture path/mtime/SHA-256 snapshots before and after dry runs and the actual runnable checkup; invalid setup/config JSON was not loaded; recovery-data sentinels unchanged |
| CLI safe-mode placements | PASS | All 20 commands checked with flag before command, after command and after arguments; unknown command rejected, no-command dry run and ordinary help preserved |
| Real any-key exit | PASS | `python "<session-files>\verify-any-key.py"` using the existing Git winpty DLL, no added dependency; 4/4 real-console probes: both hosts wait at prompt, `x` without Enter exits 0 on success and 1 after checkup failure |
| README generation | PASS | `node moorkyz readme`; generated edition subsequently checked by both full runner invocations |
| Example suite removal | PASS | `Test-Path -LiteralPath tests` returned `False` |
| Required Node version | PASS | With system Node 22.18.0 on PATH, `pwsh -NoProfile -File .\maintenance\checkups\01-runnables.ps1` correctly returned 1 with "Node.js 24 LTS is required" before checking any runnable; Node 24 runs passed |
| Tracked whitespace | PASS, limited | `git --no-pager diff --check`; empty tracked/index baseline means this alone is not sufficient |
| Actual task-file whitespace | PASS | `git -c core.safecrlf=false --no-pager diff --no-index --check -- NUL <file>` for each of 22 task-related source/doc/config files, then the completed audit; no whitespace errors |
| Dependency install/audit | N/A | No root manifest or committed lockfile and no dependencies introduced. `npm ci --ignore-scripts` / root `npm run verify` do not apply; existing stack-neutral verification used instead |
| Linux execution | NOT RUN | Local OS is Windows; existing Linux/Windows CI matrix now invokes the same runner with `shell: pwsh` |

## Review

- Secrets: focused source review and private-key/GitHub-token/AWS-key/assigned
  secret-pattern scan of new checkups and affected action entrypoints found no
  credentials. No secrets, user settings, runtime data or environment dumps were
  copied into the repository. No third-party services were used for verification.
- Safety: existing action entrypoints return before any work in their safe modes.
  The runner refuses linked checkup directories/files; source discovery refuses
  links and excludes Git metadata, runtime data, dependencies and generated output.
  Unsupported runnable types and PowerShell scripts without `-DryRun` fail
  explicitly instead of being executed. Native exit codes and exceptions surface
  as failures; no cleanup or success-shaped fallback hides errors.
- Trust boundary: declaring `-DryRun` is not proof that arbitrary future script
  bodies honor it. Review all new checkups and safe-mode implementations before
  running them. JavaScript modules are parsed, not imported; CMD execution is
  explicitly skipped outside Windows and covered by Windows CI.
- During verification, fixed multiple Node application lookup results and a
  PowerShell 5.1 default-parameter evaluation problem; changed documentation
  check transport to stdin to avoid legacy native-argument quote loss. An initial
  fixture-only CMD quoting failure was corrected in the session probe. Final
  regression and full-runner checks passed.
- Concurrent path-move documentation failures were reported to their owner and
  subsequently cleared; final local link and HTML checks passed. Their independent
  work was preserved, not claimed as part of this implementation.
- Remaining risks: retired action-level coverage, unexecuted Linux CI, future
  trusted checkup behavior and a pending human review. No action-level behavior
  change is intended when dry-run switches are absent.
- Commit blocker: an isolated task commit cannot represent edits/deletions to the
  pre-existing wholly untracked baseline without staging other owners' work.
  Do not make an initial repository commit on their behalf.

## Completion

- Commit: `BLOCKED` by unborn/untracked baseline; nothing staged or committed.
- Human review: pending; no independent agent review requested.
- External actions: none; no push, PR, deployment, install or remote communication.

A generated draft is not verification evidence and a self-audit is not an
independent security review.
