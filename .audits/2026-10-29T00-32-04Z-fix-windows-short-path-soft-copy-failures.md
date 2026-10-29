# Fix Windows short-path soft-copy failures

| Field | Value |
|---|---|
| Audit ID | `2026-10-29T00-32-04Z-fix-windows-short-path-soft-copy-failures` |
| Created (UTC) | 2026-10-29T00:32:04.213Z |
| Auditor | Copilot SDK session f70a1d9e-0d14-4d9a-94b6-fa8a875a5c54 (AI assistant using Copilot SDK in VS Code); self-audit |
| Baseline commit | `e11c1e78611b2bd42fb53b825b404f43a1e1b7f0` (this session's catalog closure on top of `297a932`, which equals `origin/master`) |
| Outcome | `PASS WITH RISKS`: local and CI-simulated checks pass; GitHub confirmation needs an approved push |

## Request and outcome

- Requested behavior and confirmed decisions: part of REQ-TEMPLATE-READY-032. On 2026-10-29T00:01Z the owner asked whether the template is complete, "everything that needs to be known for an agent and normal worker to work to their max". The preceding read-only discovery found the GitHub "Project tooling" workflow failing on `windows-latest` for the last two pushes (runs 40202314094 and 40418994717) in `07-soft-copy.ps1`, while Ubuntu and local runs passed. A red quality gate undermines both agents and developers, so with the owner unavailable (autopilot) this session fixed it as WINDOWS-CI-PATHS-033.
- Implemented behavior: soft copy treats 8.3 short and long Windows paths as the same location. Revert accepts a recovery snapshot path in either form, and the template file list is identical for short and long template roots. The checkup's injected-failure hooks compare normalized paths, and a new regression exercises short recovery, target and template-root paths on any Windows machine with 8.3 names.
- Initial Git state and unrelated work preserved: `HEAD` was `297a932` = `origin/master` plus this session's `e11c1e7`. Other sessions' uncommitted `designs/` viewer wiring, scheduler rows and untracked files were neither touched nor staged.
- Intentional exclusions: no change to the soft-copy UI, copy semantics, report formats, messages or other checkups; no push.

## Analyzing and Reading

- Guides, affected source/consumers, documentation and tests read: AGENTS.md, AGENT_SCHEDULER.md, CONTRIBUTING.md, the maintenance and soft-copy guides, `CopyTemplate.ps1`, `helpers/CopyCore.ps1`, `helpers/CopyUndo.ps1`, `helpers/CopyGui.ps1`, `07-soft-copy.ps1`, and the GitHub Actions log of job 121908361287.
- Acceptance criteria and edge cases: (1) the reproduced GitHub failure passes; (2) the new regression fails without the fix on an ordinary Windows machine and passes with it; (3) full maintenance passes on the exact staged tree with normal and GitHub-style short `TEMP`; (4) Linux behavior is unchanged (alias checks skip off Windows); (5) no live data is touched.
- Scope, constraints and preserved unrelated work: three soft-copy/checkup files, this audit and this session's scheduler rows.

## Researching and Planning

- Root cause, verified locally: GitHub's Windows runners use an 8.3 short `TEMP` (`C:\Users\RUNNER~1\...`). `[IO.Path]::GetFullPath` expands short names on PowerShell 7.6.9 and Windows PowerShell 5.1 (`C:\PROGRA~1` became `C:\Program Files`, also for a not-yet-existing tail), while PowerShell provider paths (`GetUnresolvedProviderPathFromPSPath`, `Split-Path`) keep them. `New-TemplateRevertPlan` compared the provider-form recovery path with the expanded template root, so every revert was refused with "Recovery must be an original recovery-*.json snapshot ...".
- Reproduction: setting `TEMP`/`TMP` to the 8.3 alias of a new temporary directory reproduced the CI assertion exactly (`at success ([stdin]:64:35)`, `[stdin]:109:5`).
- After the first fix, the same environment exposed two more mismatches with the same cause: `Get-TemplateCopyFiles` subtracted an unexpanded root length from expanded `FullName` values (the GUI passes its root unchanged, so its list lost `conflict.txt`), and three checkup hooks compared raw Node paths with expanded PowerShell paths, so injected failures never fired.
- Chosen approach: normalize every compared path with the same `GetFullPath` call already used for the root and target, instead of adding a new canonicalization helper. No dependency or approval needed.

## Developing

- Implemented behavior and related tests/docs: see the table. The regression helper `shortAlias()` obtains a real 8.3 alias with `cmd`'s `%~sI` expansion and prints a SKIP line where no alias exists (Linux, or volumes without 8.3 names).
- Deviations from the plan and intentional exclusions: the two additional short-path defects were fixed in the same item because they produced the same CI failure.

| Path | Change | Risk |
|---|---|---|
| `.template/soft-copy/helpers/CopyUndo.ps1` | Normalize the requested recovery path with `GetFullPath` before comparing it with the template's `.moorkyz\soft-copy` directory | Low: normalization before unchanged validation |
| `.template/soft-copy/helpers/CopyCore.ps1` | Normalize the root in `Get-TemplateCopyFiles` so relative names come from the same expanded path as the enumerated files | Low: plan callers already passed expanded roots |
| `.template/maintenance/helpers/checkups/07-soft-copy.ps1` | Short-path regression for recovery, target and template root; normalized injected-failure hooks; reports how many short-path reverts ran | Low: test-only |

## Clean Up

### Verification

Node.js `v24.22.0` was first on `PATH` for every run; PowerShell `7.6.9` ran the runner, and the checkups also exercised Windows PowerShell 5.1.

| Check | Result | Command / evidence |
|---|---|---|
| Reproduce the CI failure before the fix | PASS (failure reproduced) | `07-soft-copy.ps1` with `TEMP`/`TMP` set to an 8.3 alias: exit 1 with the CI assertion |
| New regression against the old code | PASS (fails as intended) | `HEAD` version of `CopyUndo.ps1` restored temporarily, new checkup, normal `TEMP`: exit 1 with the same refusal; the fixed file was restored and its hash verified |
| Soft-copy checkup, normal and short `TEMP` | PASS | `pwsh -NoProfile -File .\.template\maintenance\helpers\checkups\07-soft-copy.ps1`: 54 groups on pwsh and powershell.exe, "2 revert(s) accepted 8.3 short recovery and target paths", exit 0 in both modes |
| Full maintenance on the exact staged tree, normal `TEMP` | PASS | `git checkout-index -a` export of the staged tree (184 files), then `RunCheckups.ps1 -NoPause`: 8 passed, 0 failed |
| Full maintenance on the exact staged tree, GitHub-style short `TEMP` | PASS | Same export, `TEMP`/`TMP` set to an 8.3 alias (`...\Temp\MO1694~1`) as on GitHub's Windows runners: 8 passed, 0 failed, including "2 revert(s) accepted 8.3 short recovery and target paths" |
| Dependency audit | N/A | No dependency, manifest or lockfile changed |
| `git diff --cached --check` | PASS | Exit 0 on the staged diff |
| GitHub Actions on `windows-latest` | NOT RUN | Needs a push, which requires explicit owner approval |

### Quality and safety review

- Correctness, best practices, redundancy/dead code and unnecessary complexity: three normalizations at the comparison points; no new helper or behavior. `GetFullPath` already normalizes the root and target in the same files.
- Compatibility, error handling and coverage: PowerShell 5.1 and 7 both expand short names in `GetFullPath`; Linux paths are unaffected and the alias checks skip there. Error messages are unchanged. The regression covers revert, target and root paths on any Windows machine with 8.3 names; GitHub's short `TEMP` covers the whole suite.
- Secrets and security: no credentials or data. Validation is not loosened: the snapshot must still be a canonical `recovery-*.json` in the template's own `.moorkyz\soft-copy` directory, and link/junction refusal is unchanged; only equivalent spellings of the same path are now recognized.
- Self-reviewer, scope and findings: this session reviewed the complete staged diff; no further findings. Other path comparisons were checked (`CopyCore.ps1` target root, `CreateProject.ps1`) and already normalize both sides.
- Independent review and required approvals: not requested; human review pending.
- Findings, residual risks and blockers: GitHub confirmation is pending an approved push.

### Final references and documentation

| Reference / content | Availability / validity | Command / source / evidence and impact |
|---|---|---|
| Changed code references, consumers, paths/casing, assets, commands and configuration | PASS | Signatures unchanged; callers of `Get-TemplateCopyFiles` (`CopyCore.ps1` plan, `CopyGui.ps1` list) and `New-TemplateRevertPlan` (`CopyTemplate.ps1`, `CopyGui.ps1`) need no change |
| Supported APIs/dependencies and local links/anchors | PASS | Short-name expansion observed on both hosts; maintenance link checks pass |
| Changed external references and version-specific claims | PASS | GitHub Actions logs for runs 40418994717 and 40202314094 read through the GitHub API |

- Unreachable or unverifiable content, impact and required follow-up: remote CI confirmation needs an approved push.
- Docs, examples, generated outputs and queue evidence updated: no command, option or behavior visible to users changed, so the tool guides remain accurate. The REQ-TEMPLATE-READY-032 ledger row records this item; the template guide work under the same request documents the short-path rule.
- Task-created temporary files removed (existing data preserved): every temporary directory, export, log and backup created for these runs was removed.
- Final affected tests, quality and reference checks repeated after updates: yes, on the exact staged tree.

### Completion

- Commit: focused local commit; the hash is reported in the session completion.
- Staged diff and `git diff --cached --check`: reviewed; PASS.
- Human review: pending
- Required checks/approvals and completion or handoff status: required checks PASS; WINDOWS-CI-PATHS-033 completed and removed from the queue; no push.
- External actions: none

A generated draft is not verification evidence and a self-audit is not an
independent security review.