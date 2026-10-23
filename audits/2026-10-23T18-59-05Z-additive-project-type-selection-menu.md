# Additive project type selection menu

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T18-59-05Z-additive-project-type-selection-menu` |
| Created (UTC) | 2026-10-23T18:59:05.061Z |
| Auditor | Copilot SDK session d753305c-08ac-4194-844d-336a2e32231a; self-audit |
| Baseline commit | None; unborn branch with untracked baseline |
| Outcome | PASS WITH RISKS; 103/103 regression checks pass; focused commit blocked by unborn baseline |

## Request and outcome

- Requested behavior and confirmed decisions: numbered keyboard selection with arrows, Space/Enter and Esc/Q; review/confirmation before applying. The owner explicitly superseded the archive/deletion request: "you can add as many as you want, no deletion".
- Implemented behavior: multi-select menu, explicit Y confirmation, non-destructive copies in interactive and explicit-name modes, unchanged-file no-ops for reruns, and refusal to overwrite different content. All source types and selector files remain intact, allowing more types to be added later.
- Initial Git state and unrelated work preserved: all baseline files untracked. The original TYPES-005 owner handed off selector/tests/docs. Another session is performing owner-directed runtime-folder/documentation cleanup; its changes are preserved and not part of this task.
- Intentional exclusions: no archive creation, no source deletion, no CMD wrapper, no product/runtime/deployment changes. The separate adoption script retains its existing explicitly configured template-removal behavior.

## Changes

| Path | Change | Risk |
|---|---|---|
| `.projecttypes/SetProjectType.ps1` | Keyboard menu, confirmation, copy-only behavior, streaming content comparison and repeat-safe preflight | medium |
| `tests/project-type-menu.test.cjs` | 38 real-PowerShell menu/copy regression cases in disposable directories | low |
| `tests/template.test.cjs` | Update copy/source-preservation, conflict and rerun expectations | low |
| `.projecttypes/README.md`, `README.md`, `README.html` | Document controls, confirmation, no deletion and later additions | low |
| `setups/Make This Yours/CreateProject.ps1` | Align help text with source-preserving copies | low |
| `AGENT_SCHEDULER.md`, `audits/README.md`, this audit | Record final owner clarification, handoff, evidence and limits | low |

## Verification

Used the already-installed Node.js 24.21.0 runtime, not the Node 22 executable
on PATH. No packages were installed. Tests never run the selector or adoption
script against the real repository.

| Check | Result | Command / evidence |
|---|---|---|
| `node --check moorkyz` | PASS | Node 24.21.0; baseline CLI syntax unchanged. |
| `node --test tests\project-type-menu.test.cjs tests\template.test.cjs tests\documentation.test.cjs` | PASS | 55/55 on the focused rerun. Both available PowerShell hosts exercised; this run predates the parallel session's expansion of documentation tests. |
| Menu controls and confirmation | PASS | Actual selection function with injected key events: arrows/wrap, Space toggle/deselect, Enter, numeric/multi-digit input beyond 9, invalid/overflow input, Backspace, N/Esc/back and Q cancellation. Only Y accepts confirmation. Raw terminal painting and physical key capture still need human review. |
| Additive copying and source preservation | PASS | Confirm node+web, add Docker later, repeat identical types, refuse same-length different content. Compare every starter file byte-for-byte after each flow; assert no archive/trash directories are created. |
| Safety and setup integration | PASS | Existing tests cover all-selection preflight, conflicting destinations, unknown/traversal types, file/directory conflicts, source/target junctions, preview, setup apply and rerun. No real user data is cleaned or migrated. |
| Initial focused run | FAIL, resolved | PowerShell 5.1 could not resolve `Get-FileHash` in this host environment. Replaced the module dependency with streaming .NET SHA-256 and reran successfully on both hosts. A concurrent README edit also required regenerating HTML. |
| `node --test` | PASS | Final full run 103/103, zero failures/skips on Node 24.21.0. Initial full run 100/103 hit concurrent exact-case/history/security documentation changes; fixed the selector README's `CreateProject.ps1` link casing, coordinated the unrelated fixes with their owner, regenerated HTML and reran the complete suite successfully. |
| `node moorkyz readme` | PASS | Regenerated HTML from final merged Markdown before the passing full suite. |
| `npm ci --ignore-scripts` / `npm run verify` | N/A | Stack-neutral root has no package manifest or committed lockfile; use the direct Node baseline checks. |
| Dependency audit | N/A | No dependency changes. |
| `git diff --check` | PASS, limited | Exit 0; untracked files are not covered because there is no initial baseline commit. |

## Review

- Secrets and security: task-owned changes introduce no credentials, secrets, external services or dependencies. Self-reviewed confirmation and cancellation, preflight ordering, source retention, no-overwrite copy behavior, and explicit error propagation. No independent security review requested.
- Docs and user-guide impact: root Markdown/HTML and selector guidance describe the same additive workflow. Explicit project-type arguments remain usable by setup without invoking the menu.
- Findings, residual risks and blockers: interactive console rendering/physical key input require human review. Copy I/O failures can leave partial additions (explicitly documented); originals remain intact and reruns skip identical copies. Concurrent documentation fixes were integrated in the passing final suite. A focused commit is blocked by the unborn, wholly untracked baseline.

## Completion

- Commit: BLOCKED by unborn/untracked baseline; no staging or commit attempted
- Human review: pending
- External actions: none unless separately approved

A generated draft is not verification evidence and a self-audit is not an
independent security review.
