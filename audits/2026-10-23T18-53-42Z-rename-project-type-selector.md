# Rename project type selector

Historical report: the original filename and move behavior below document this rename only.
Current entry points are [SetProjectType.ps1](../.scripts/project-types/SetProjectType.ps1) and
[CreateProject.ps1](../.scripts/claim-template/CreateProject.ps1); selection now copies starters.

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T18-53-42Z-rename-project-type-selector` |
| Created (UTC) | 2026-10-23T18:53:42.942Z |
| Auditor | Copilot SDK session d753305c-08ac-4194-844d-336a2e32231a; self-audit |
| Baseline commit | None; unborn branch with an unrelated untracked baseline |
| Outcome | PASS WITH RISKS: rename verified; focused commit blocked by unborn baseline |

## Request and outcome

- Requested behavior and confirmed decisions: owner stopped the earlier menu request, then clarified "It's still called unpack" and "Change name". Scope is the name only.
- Implemented behavior: renamed `.projecttypes/unpack.ps1` to `.projecttypes/SetProjectType.ps1`; updated examples, missing-file diagnostics and both setup invocation paths without changing unpack behavior.
- Initial Git state and unrelated work preserved: all baseline files were untracked; TYPES-005 work was already in progress in another session. Coordinated the new name with its owner without taking its claim or staging unrelated files.
- Intentional exclusions: no CMD wrapper, keyboard menu, stack migration or local-data cleanup.

## Changes

| Path | Change | Risk |
|---|---|---|
| `.projecttypes/SetProjectType.ps1` | Rename and update usage examples | low |
| `setups/Make This Yours/createproject.ps1` | Resolve the new name in validation, preview and apply | low |
| `AGENT_SCHEDULER.md` | Record the owner's scoped clarification and verification | low |
| This audit | Record observed results and limitations | low |

## Verification

| Check | Result | Command / evidence |
|---|---|---|
| Disposable rename regression | PASS | Inline Node assertions via `node -` spawned `pwsh.exe` and `powershell.exe` with `-NoProfile -NonInteractive -ExecutionPolicy Bypass -File`. Asserted the old path is absent and the new path exists. All repository copies and generated configs were in disposable OS temporary directories, removed afterwards. |
| Selector preview and apply, both hosts | PASS | `SetProjectType.ps1 node web docker -WhatIf` did not create root files; `SetProjectType.ps1 node web docker` moved the manifest, web assets and Docker starters; rerun succeeded; unknown type failed. |
| Setup integration, both hosts | PASS | `createproject.ps1 -NoPause -WhatIf` with valid temporary config and `projectTypes: ["node", "web", "docker"]` resolved the renamed selector and made no changes. |
| `node --test` | NOT RUN | Broader project-type test migration belongs to the active TYPES-005 owner; existing tests still target the removed overlay layout. Used focused real-host regression assertions for this rename. |
| `npm ci --ignore-scripts` / `npm run verify` | N/A | The stack-neutral root has no package manifest or lockfile; no dependency changes. |
| Dependency audit | N/A | No dependencies added or changed. |
| `git diff --check` | N/A | The touched baseline files are untracked, so a Git diff cannot validate this rename. |

## Review

- Secrets and security: self-reviewed the task-owned edits; no secrets, credentials, dependencies or external services introduced. No independent security review requested.
- Docs and user-guide impact: script examples and error guidance updated; the active TYPES-005 owner was notified twice to use `SetProjectType.ps1` in the ongoing README, HTML, docs and test migration. Historical audits remain unchanged.
- Findings, residual risks and blockers: runtime checks were driven by installed Node 22.18.0, not baseline Node 24; exercised behavior is PowerShell-only. Full baseline verification remains with TYPES-005. A focused local commit would include unrelated baseline content because there is no initial commit, so no staging or commit was attempted.

## Completion

- Commit: BLOCKED by the unborn, untracked baseline; no files staged
- Human review: pending
- External actions: none unless separately approved

A generated draft is not verification evidence and a self-audit is not an
independent security review.
