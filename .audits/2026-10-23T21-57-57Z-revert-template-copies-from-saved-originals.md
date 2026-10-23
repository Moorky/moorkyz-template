# Revert template copies from saved originals

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T21-57-57Z-revert-template-copies-from-saved-originals` |
| Created (UTC) | 2026-10-23T21:57:57.874Z |
| Auditor | Copilot SDK in VS Code; self-audit, session 536eac24-7671-4dea-ab6b-e2dada701955 |
| Baseline commit | Initial `8a1de7d`; unrelated compact-design work committed independently as `eff201a` before this task's staging |
| Outcome | `PASS WITH RISKS` |

## Request and outcome

- Requested behavior and confirmed decisions: add an option to revert a copy by temporarily saving what existed beforehand.
- Implemented behavior: every changing copy saves original bytes, SHA-256 hashes, original modification times and file/directory ownership in a separate local recovery journal before destination writes. The GUI enables **Revert last copy**, with a default-No confirmation. Revert restores replaced files, removes copy-created files and only empty copy-created directories, and refuses later edits before making changes. CLI `-Revert <snapshot> -TargetDirectory <original target>` also works after closing the GUI, with `-WhatIf` support.
- Initial Git state and unrelated work preserved: only the other agent's compact-design scheduler request was dirty at initial inspection. That work subsequently landed as `eff201a`; no design assets, generator, canonical README/HTML, root CLI or unrelated agent rows were changed by this task.
- Intentional exclusions: no automatic revert, recursive target cleanup, agent execution, network activity, package installation, automatic cache expiry or retroactive recovery of older copies without ownership records. Existing conflict-report arrays retain their schema and contents. Source originals are never removed.

## Changes

| Path | Change | Risk |
|---|---|---|
| [CopyCore.ps1](../.template/soft-copy/helpers/CopyCore.ps1) | Save recovery ownership and byte snapshots; record successful/observed writes and controlled failures; share target-root validation | Extra local disk/memory use; copying remains non-transactional |
| [CopyUndo.ps1](../.template/soft-copy/helpers/CopyUndo.ps1) | Atomic journal replacement, recovery hashes/schema/path checks, per-snapshot locks and explicit restore/removal | Deliberately refuses changed files, unsafe paths and incomplete copy journals |
| [CopyGui.ps1](../.template/soft-copy/helpers/CopyGui.ps1) and [launcher](../.template/soft-copy/CopyTemplate.ps1) | Last-copy revert button bound to its original target; cancellation/error states; CLI parameter set and preview | GUI tracks the latest copy in that window; older snapshots require CLI |
| [Regression checkup](../.template/maintenance/helpers/checkups/07-soft-copy.ps1) | Preserve existing copy tests and add restoration, ownership, failure, concurrency, retry, invalid-journal and GUI-revert checks | All actions target new disposable fixtures |
| [Tool guide](../.template/soft-copy/README.md), [catalog](../.template/README.md), [maintenance guide](../.template/maintenance/README.md) | Explain recovery, sensitive snapshots, CLI examples, retention and failure boundaries | Manual visual review remains pending |
| [Scheduler](../AGENT_SCHEDULER.md) | Record request, scoped claim, final evidence and release | Other agents' requests preserved |

## Verification

Use `PASS`, `FAIL`, `NOT RUN` (with reason) or `N/A`; record exact commands.

| Check | Result | Command / evidence |
|---|---|---|
| PowerShell 7 maintenance | PASS | With pre-existing `C:\Users\marvi\AppData\Local\Temp\moorkyz-node24\node-v24.22.0-win-x64` prefixed to PATH: `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause`; final output `Checkups finished: 7 passed, 0 failed (7 total).` |
| Windows PowerShell 5.1 maintenance | PASS | Same Node 24.22.0 PATH prefix: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\.template\maintenance\RunCheckups.ps1 -NoPause`; final output `Checkups finished: 7 passed, 0 failed (7 total).` |
| Focused copy/revert checks | PASS | `pwsh -NoProfile -File .\.template\maintenance\helpers\checkups\07-soft-copy.ps1`; final focused and full-suite runs each report **54 regression groups across PowerShell 7 and Windows PowerShell 5.1**. Fixtures and GUI windows/timers are removed/disposed in `finally`. No live user directory is a fixture. |
| Exact restoration and preservation | PASS | Normal and force-copy undo restore original target SHA snapshots, original modification time and arbitrary binary/non-UTF-8/empty content; remove newly copied files and empty new sibling directories; retain pre-existing directories, preserved conflicts, unrelated files and later directory contents. Source files and original conflict reports stay unchanged. |
| Preview and invalid recovery | PASS | Revert dry run and preview leave all fixture bytes/paths unchanged. Reject repeated revert, changed/missing overwritten files, wrong target, traversal, Git/runtime paths including trailing-space variants, corrupt backups, duplicates, malformed hashes/states and unsupported versions. Windows junction/hard-link/read-only refusal leaves targets and outside sentinels unchanged. |
| Failure, concurrency and retry | PASS | Deterministically inject a newly appeared conflicting file after the first copied file: undo removes only its own completed file and retains the other writer's file. Inject a journal failure after creation of an empty new file: recorded observed bytes permit safe removal. Failed directory creation never claims ownership, so a later user-created directory survives revert. Overlapping operations undo newest-first. An exclusive snapshot lock refuses simultaneous reverts. An edit just before a second restore stops progress; retry skips the recorded first restore and preserves a later edit to that already-restored file. |
| GUI and actual launcher | PASS | Windows Forms controls test default-disabled revert, unchanged-copy behavior, force-copy enablement, revert cancellation, stale-edit refusal, original-target binding despite edited target text, restoration and final disabling. Native confirmation answers are stubbed in control tests. Existing actual modal launcher/working-directory test also passes on both hosts. |
| Manual/native-dialog visual review and Linux | NOT RUN | No human click-through/visual-accessibility review or Linux environment available; Windows workflow is the requested GUI target. |
| Dependency audit / product build / type-check | N/A | No application stack, dependency or manifest changes. Uses existing PowerShell/.NET only. Maintenance parses every PowerShell helper and checks its side-effect-free dry mode. |
| Documentation | PASS | Full maintenance checks all exact-case local links, tool structure and canonical README/HTML freshness. No canonical README regeneration was needed for this task. |
| `git diff --check` | PASS | No whitespace errors; Git prints only line-ending normalization warnings. |

## Review

- Secrets and security: self-reviewed the actual copy/recovery/GUI/CLI diffs and directly related test/documentation changes. Recovery is constrained to the template's local cache, bound to an explicitly supplied original target, and limited to validated relative paths. Backup hashes are verified before any revert. No file content is executed or uploaded. Temporary snapshots contain potentially sensitive original bytes, are ignored by Git and must not be shared or treated as agent instructions.
- Data-loss safeguards: copy-created and replaced records are distinct; pending/failed-to-open files are not claimed. Directory ownership is recorded only after successful directory creation. All active recovery records are checked before target writes, then bytes are checked again under an exclusive handle. Deletes are single-file or non-recursive empty-directory operations, never a recursive repository cleanup. Original snapshots remain after revert. Per-snapshot lock handles serialize copy/revert and are disposed.
- Resolved verification findings: PowerShell converted a null backup filename to an empty string in `File.Replace`; `[NullString]::Value` fixed actual atomic replacement on both hosts. Self-review moved directory ownership recording after successful creation and added a failure regression. The test subprocess now emits unwrapped exception messages and explicit exit codes, avoiding false failures from formatted CLIXML line wrapping/handled-error exit state.
- Docs and user-guide impact: guides describe the GUI button, exact CLI/preview use, separate journal versus conflict-array roles, newest-first undo, later-edit refusal, local snapshot retention and legacy-copy limitations.
- Residual risks and blockers: no blocker for the requested Windows copy/revert workflow. Operations are not fully transactional: disk/permission failures, abrupt process/power loss and filesystem path replacement races can require manual recovery from saved bytes. Incomplete `copying` journals are refused rather than guessed safe. Stop other writers during copy/revert. Snapshots are local unencrypted sensitive data, not authenticated files for exchange, and consume disk/memory until deliberately removed. Legacy copies without journals cannot be automatically reverted. Human/native-dialog visual review remains pending.

## Completion

- Commit: `PENDING` (report the hash; do not edit this audit afterwards)
- Human review: pending
- External actions: none unless separately approved

A generated draft is not verification evidence and a self-audit is not an
independent security review.
