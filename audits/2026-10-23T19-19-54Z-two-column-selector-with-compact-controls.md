# Two-column selector with compact controls

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T19-19-54Z-two-column-selector-with-compact-controls` |
| Created (UTC) | 2026-10-23T19:19:54.139Z |
| Auditor | Copilot SDK in VS Code; session 9c442293-ea2a-4643-8d2c-c1c84fdecbe9; self-audit |
| Baseline commit | None: unborn branch; pre-existing baseline entirely untracked |
| Outcome | PASS WITH RISKS; implementation verified, focused commit blocked |

## Request and outcome

- Requested: keep controls simple in one row below the list; display the project types in two columns.
- Implemented: balanced columns numbered down the left then down the right, with aligned cursor/selection markers and one compact controls footer. Up/Down navigation, Space toggles, multi-digit selection, explicit Y confirmation and cancellation are unchanged.
- Preserved the current `.projecttypes/types/` layout, CMD entrypoint, source-copy policy and early `-DryRun` return. Coordinated the bounded render block and documentation edits with the active type-path and maintenance owners.
- Initial Git state: all baseline files untracked with no initial commit. Did not stage unrelated work, restore removed tests, modify maintenance checkups or agent-template work, or touch ignored local data.
- Intentional exclusions: no new controls, dependencies, installations, action-level maintenance tests or folder renames.

## Changes

| Path | Change | Risk |
|---|---|---|
| `.projecttypes/SetProjectType.ps1` | Render two balanced columns and move the single controls row below them; no selection/copy/path changes | low |
| `.projecttypes/README.md`, `README.md`, `README.html` | Document the two-column layout and single footer; regenerate HTML | low |
| `AGENT_SCHEDULER.md` | Record the scoped request, coordination and actual acceptance | low |
| This audit | Verification evidence and commit/review limitations | low |

## Verification

Menu assertions extracted only `Read-ProjectTypeSelection` via PowerShell's AST
and mocked terminal output/key input. They did not execute top-level selector
actions or copy/remove files. The disposable session-local check script was
removed after both hosts completed.

| Check | Result | Command / evidence |
|---|---|---|
| Menu layout and behavior | PASS | `pwsh -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File <session-check> -Selector .projecttypes\SetProjectType.ps1`, then the same with `powershell.exe`: 1, 2, 9 and 12 entries; exact balanced row counts, both column numbers, one footer after the last row, footer within 80 columns, multi-selection, multi-digit selection, rejected confirmation and cancellation |
| Maintenance checkups | PASS | Node v24.21.0 first on PATH; `pwsh -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File maintenance\RunCheckups.ps1 -NoPause`: 2 passed, 0 failed; all 10 runnables checked without actions |
| README generation and links | PASS | `node moorkyz readme`; maintenance checks all local Markdown/HTML links with exact casing and verifies HTML freshness |
| Dependency audit | N/A | No dependencies changed or installed; root has no package manifest/lockfile |
| `git diff --check` | PASS, limited | No tracked diff because baseline is untracked; scoped source whitespace/conflict-marker and secret-pattern checks supplement it |
| Real keyboard / terminal screenshot | NOT RUN | Output and key transitions asserted on real PowerShell 7 and Windows PowerShell 5.1 with mocked input; physical terminal interaction was not claimed |

## Review

- Secrets and security: render-only change; no input execution, new external commands, credentials or dependencies. Existing validation and no-overwrite boundaries unchanged. Bounded secret-pattern scan found no matches. This is a self-audit, not an independent security review.
- Docs and user-guide impact: root and project-type guides describe the same two-column/footer behavior; generated HTML is current.
- Remaining limits: exceptionally long future type names or very narrow terminals can wrap; normal current type names and the compact footer fit an 80-column terminal.
- Commit blocker: no initial commit and all unrelated baseline files are untracked. A safe focused commit cannot be represented without importing pre-existing work. No staging or commit attempted.

## Completion

- Commit: BLOCKED by the unborn/untracked baseline; no hash.
- Human review: pending; no independent review requested.
- External actions: none; no push, installation or deployment.

A generated draft is not verification evidence and a self-audit is not an
independent security review.
