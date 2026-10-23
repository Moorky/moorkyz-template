# Scheduler cleanup, dot-only runtime folders and setup README

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T19-02-00Z-scheduler-cleanup-dot-only-runtime` |
| Created (UTC) | 2026-10-23T19:02:00Z |
| Auditor | AI assistant (Copilot SDK in VS Code); self-audit |
| Baseline commit | None (unborn `master`, entire tree untracked) |
| Outcome | `PASS` |

## Request and outcome

- Scheduler: removed every completed entry (storage, stack-neutral, overlay, project types and the selector rename); their evidence stays in `audits/`. Kept the examples and the active TYPES-005 menu item owned by session d753305c, and added REQ-CLEANUP-006.
- Logs: no log files existed anywhere; `.logs/` was already empty.
- Non-dot duplicates: removed the empty `logs/` and `archive/` folders (`trash/` did not exist). Removed every active reference so only `.logs/`, `.archive/` and `.trash/` are used: `.gitignore` legacy block, CLI archive guard and legacy log-path compatibility (`moorkyz`), the legacy log test and legacy-preservation storage test (replaced by a test that no non-dot folder is created), documentation/template test lists, Docker ignore, README and CLI guide notes, setup skip list and default `remove` list. Historical audits keep their original wording.
- `.agents/`: it is the vendor-neutral skill location (`.agents/skills/<name>/SKILL.md`, loaded by Copilot in VS Code and other agents). Siblings keep a `task-audit` skill there; the template's folder was empty, and Git does not track empty folders. Added a generalized `task-audit` skill and a README mention.
- Added `setups/Make This Yours/README.md` (settings table, run commands, behavior). No folders were renamed.

## Verification

| Check | Result | Command / evidence |
|---|---|---|
| `node --check moorkyz` (Node 24.22.0) | PASS | exit 0 |
| `node --test` (Node 24.22.0) | PASS | 100 pass, 0 fail, 0 skipped (includes the concurrent agent's new tests) |
| Remaining non-dot references | PASS | Repository search finds only CLI command names (`archive`, `logs`) and the new absence assertion |

## Review

- Removing log-path compatibility means a preference saved by an older CLI pointing at `logs/...` falls back to `.moorkyz/<name>.log`; no such data exists here.
- Concurrent agent activity: edits were exact text replacements that fail when the text has changed; the other agent's in-progress files were not rewritten.

## Completion

- Commit: none; blocked until the owner approves an initial baseline commit
- Human review: pending
