# Add script to open all design HTML files

| Field | Value |
|---|---|
| Audit ID | `2026-10-24T16-48-14Z-add-script-to-open-all-design-html-files` |
| Created (UTC) | 2026-10-24T16:48:14.035Z |
| Auditor | Agent/person and tool (self-audit unless stated) |
| Baseline commit | `bf6fd8e` |
| Outcome | `PASS WITH RISKS` |

## Request and outcome

- Requested behavior and confirmed decisions: a script that opens all HTML files under `designs/` recursively.
- Implemented behavior: `designs/OpenAll.ps1` finds every `*.html` under its folder (sorted), opens each with the default handler via `Start-Process`; `-DryRun` only lists them.
- Initial Git state and unrelated work preserved: clean tree at `bf6fd8e`; no unrelated files touched.
- Intentional exclusions: no browser selection or batching; no new checkup.

## Changes

| Path | Change | Risk |
|---|---|---|
| `designs/OpenAll.ps1` | New script | Low; opens ~41 browser tabs when run without `-DryRun` |
| `designs/README.md` | Usage note | None |

## Verification

Use `PASS`, `FAIL`, `NOT RUN` (with reason) or `N/A`; record exact commands.

| Check | Result | Command / evidence |
|---|---|---|
| Maintenance checkups (`pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause`) | PASS | 7 passed, 0 failed, using portable Node v24.22.1 prepended to PATH (system Node is v22.18.0, which fails the Node 24 gate) |
| Dependency audit | N/A | No dependency changes |
| `git diff --check` | PASS | exit 0 |

## Review

- Secrets and security: no secrets; script only opens local files found under its own folder. `OpenAll.ps1 -DryRun` listed 41 files on pwsh and powershell.exe.
- Docs and user-guide impact: `designs/README.md` documents usage.
- Findings, residual risks and blockers: non-dry-run (actually opening tabs) not executed to avoid flooding the browser; machine Node is 22, not 24.

## Completion

- Commit: `PENDING` (report the hash; do not edit this audit afterwards)
- Human review: pending
- External actions: none unless separately approved

A generated draft is not verification evidence and a self-audit is not an
independent security review.
