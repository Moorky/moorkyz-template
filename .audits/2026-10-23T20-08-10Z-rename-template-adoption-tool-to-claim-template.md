# Rename template adoption tool to claim-template

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T20-08-10Z-rename-template-adoption-tool-to-claim-template` |
| Created (UTC) | 2026-10-23T20:08:10.327Z |
| Auditor | AI assistant using Copilot SDK in VS Code, session 8348d860-25be-4c44-a05a-ecacba04e5b9; self-audit |
| Baseline commit | None: unborn `master`, empty index, baseline already entirely untracked |
| Outcome | `PASS WITH RISKS`: implementation verified; focused commit blocked by the unrelated unborn baseline |

## Request and outcome

- Requested: rename the adoption script folder to `.scripts/claim-template`,
  label it "use once", then search for mismatched names throughout the repository.
- Renamed the folder, retained `CreateProject.ps1` and configuration bytes, and
  documented one-time adoption while preserving safe retries and existing
  opt-in self-removal. Updated active references, examples, exact-case links,
  maintenance expectations and both root README editions.
- Corrected stale displayed paths in the audit index. Historical reports retain
  their original command text and observed results; live links use current paths.
- Coordinated with layout and Copilot sessions; preserved their root-CLI,
  installer, documentation and checkup changes. The earlier layout claim was
  released while this work was underway.
- Transient blocker: an external operation moved the root CLI into
  `.scripts/project-types/moorkyz` after successful focused verification.
  Left that conflicting move untouched while owner confirmation was unavailable.
  The CLI subsequently reappeared at the root without intervention from this
  session; final full maintenance passed after correcting its stale help path.
- Exclusions: no application stack, packages, lockfile, runtime data cleanup,
  actual adoption of this repository, forced one-shot lock, or undoing other work.

## Changes

| Path | Change | Risk |
|---|---|---|
| [Claim Template](../.template/claim-template/README.md), [CreateProject.ps1](../.template/claim-template/CreateProject.ps1), [configuration](../.template/claim-template/helpers/setup.config.json) | Folder rename, help path and one-time usage wording; script behavior/configuration preserved | Existing confirmation and optional permanent removal behavior unchanged |
| [Script catalog](../.template/README.md), [agent guide](../AGENTS.md), [README Markdown](../README.md), [README HTML](../README.html) | Current name, examples and one-time adoption guidance; HTML regenerated | Integrated concurrent edits without reverting them |
| [Project types](../.template/project-types/README.md), [maintenance guide](../.template/maintenance/README.md), [dependency maintenance](../docs/dependency-security.md) | Current adoption links and commands | Documentation only |
| [Documentation checkup](../.template/maintenance/helpers/checkups/02-documentation.ps1) | Require renamed tool layout; reject retired adoption names and folder | Read-only checks; historical audits remain excluded from retired-name checks |
| [Root CLI](../moorkyz) | Correct one stale project-type selector path in general help; add a documentation-check assertion against the retired directory | Help text only; no lifecycle/storage behavior changed |
| [Audit index](README.md) and six earlier reports | Repair live adoption links and current-reference display names; preserve historical evidence | No prior results rewritten |
| [Scheduler](../AGENT_SCHEDULER.md), this report | Request, coordination, actual evidence and final blocker | No task-owned files staged with the unrelated baseline |

## Verification

Commands used the existing cached Node.js **v24.21.0**, prepending
`C:\Users\marvi\AppData\Local\npm-cache\_npx\387698761821791d\node_modules\node\bin`
to PATH per process. No runtime or dependency was downloaded.

| Check | Result | Command / evidence |
|---|---|---|
| Initial maintenance baseline | PASS, 4/4 | `pwsh -NoProfile -File .\.scripts\maintenance\RunCheckups.ps1 -NoPause`, Node 24.21.0, before the rename |
| Post-rename maintenance | FAIL, then repaired targeted check | Same runner: runnable, all nine presets through both PowerShell hosts/CMD, and Copilot checkups passed; documentation failed on two concurrently created audit links. Both links were corrected. |
| Repaired documentation | PASS | `pwsh -NoProfile -File .\.scripts\maintenance\helpers\checkups\02-documentation.ps1`: all exact-case links, generated HTML, tool layout, retired names and existing safeguards passed before the external CLI move |
| Focused adoption checks | PASS, 10/10 | `node <session-files>\verify-claim-template.cjs <repo>` using `pwsh.exe` and `powershell.exe`: dry-run/invalid configuration, write-free preview, apply/identity/HTML/presets, unchanged rerun, unknown-setting refusal and explicitly configured self-removal |
| Disposable test safety | PASS | Every adoption action targeted a freshly created spaced-path OS temporary fixture, with preserved user sentinels; fixtures removed in `finally`. No real project or user settings changed. |
| Harness correction | PASS after correction | Initial fixture assertion incorrectly expected identity-bearing starter JSON to remain unchanged during adoption. Updated the expected Node manifest/web-manifest identity replacement, without changing repository implementation; all ten checks then passed. |
| Configuration integrity | PASS | SHA-256 comparison with the pre-move snapshot: moved `helpers/setup.config.json` is byte-identical |
| README generation | PASS | `node moorkyz readme`; repaired documentation check verified generated HTML matches Markdown |
| Name search | PASS | Broad search including hidden tools and the extensionless CLI found no retired adoption or old directory paths outside historical reports. Corrected the one stale project-type path in general CLI help after its root location was restored externally. |
| CLI help output | PASS | Inline Node assertions run `node moorkyz help` and require both current `.scripts\project-types\SetProjectType.cmd` and `.ps1` examples and no retired folder. Snapshot diff confirms a single help-string change. |
| Transient concurrent move | FAIL, resolved externally | Documentation check reported `ENOENT` while the root CLI was absent. No file was restored or moved by this session. When it reappeared at root, resumed verification rather than leaving the earlier blocked result as the final outcome. |
| Final repository verification | PASS, 4/4 | `pwsh -NoProfile -File .\.scripts\maintenance\RunCheckups.ps1 -NoPause`, Node 24.21.0: all four checkups passed after the CLI help fix |
| Dependency install/audit | N/A | No root manifest or committed npm lockfile and no dependency changes; `npm ci --ignore-scripts` / `npm run verify` do not apply to this stack-neutral root |
| Diff review | PASS, scoped | Compared changed files against a private pre-edit snapshot; the adoption script differs only in its example path. Preserved concurrent README, scheduler and maintenance updates. Ordinary Git diff cannot isolate an untracked baseline. |
| `git diff --check` | PASS, limited | No tracked whitespace errors; baseline files are all untracked |
| Task-file whitespace | PASS | `git diff --no-index --check -- NUL <file>` for the 20 task files present at that point; no whitespace defects. The later root CLI change is one help-text line. |
| Secret-pattern scan | PASS, limited | No private-key headers, GitHub token patterns or AWS access-key patterns in task-owned tooling/docs and audit files |
| Linux execution / physical console interactions | NOT RUN | Windows host only; focused action checks used both Windows PowerShell hosts with noninteractive/NoPause invocation |

## Review

- Self-review: no added credentials, dependencies, external services, execution
  privileges or runtime behavior. Existing config validation, confirmation,
  preview, overwrite refusal and deferred self-removal remain unchanged.
  Secret-pattern scanning is not a guarantee that every secret format is absent.
- Documentation consistently uses Claim Template (use once) for current usage.
  Historical literal names remain only as review history and explicit mappings.
- No remaining live name mismatch was found in the final search. Historical
  literal names and paths are retained deliberately as prior evidence.
- The transient CLI move is resolved and final maintenance passed; existing
  user data was never used as an action-level fixture or cleaned.
- Remaining blocker: the repository still has no initial committed baseline.
  Staging complete untracked files would include unrelated owner/agent work.
- No independent security or human review has been performed.

## Completion

- Commit: `BLOCKED`; an unborn, unrelated untracked baseline prevents a trustworthy
  focused local commit. Nothing staged; no initial-baseline commit manufactured.
- Human review: pending.
- External actions: no push, publication, deployment, installs or existing-data cleanup.

A generated draft is not verification evidence and a self-audit is not an
independent security review.
