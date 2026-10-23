# Overlay for stack-specific files and unpack script

Historical report: the overlay layout, selector name and move behavior below have been superseded.
Use [SetProjectType.ps1](../.template/project-types/SetProjectType.ps1) and the
[current project types guide](../.template/project-types/README.md), not the old commands below.

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T18-33-00Z-overlay-for-stack-specific-files` |
| Created (UTC) | 2026-10-23T18:33:00Z |
| Auditor | AI assistant (Copilot SDK in VS Code); self-audit |
| Baseline commit | None (unborn `master`, entire tree untracked) |
| Outcome | `PASS WITH RISKS` |

## Request and outcome

- Requested: move everything too framework-specific into the optional folder with the same inner layout as the root, rename it if a better name exists, and add an unpack script that moves the files into place.
- `.optional/root/` became non-dot `overlay/`: dot prefixes in this template mean ignored local runtime data, and "overlay" says the files map 1:1 onto root paths. The extra `root/` level is gone.
- Moved `Dockerfile`, `.dockerignore`, `package.json` and the web-only `public/` icons and manifest. Dropped TypeScript `*.tsbuildinfo` from the generic `.gitignore`. `overlay` is excluded from the Docker context.
- Added `overlay/unpack.ps1` (PowerShell 5.1+): moves all or named top-level items, supports `-WhatIf`, checks every target first and stops before moving if one exists, refuses links and root escapes, skips itself and removes emptied folders. It lives in the overlay, so `moorkyz` stays the only root script.
- Kept in the root as stack-neutral: the `moorkyz` CLI, `moorkyz.config.example.json`, `.node-version` (the CLI needs Node), docs, audits, tests and GitHub settings.

## Changes

| Path | Change | Risk |
|---|---|---|
| `overlay/**` | Moved starters at root-relative paths; `.dockerignore` excludes `overlay` | low |
| `overlay/unpack.ps1` | New non-overwriting unpacker | medium (moves files) |
| `tests/overlay.test.cjs` | Runs the unpacker in temporary copies on every available PowerShell host | low |
| `tests/documentation.test.cjs` | New paths; overlay files must not already exist in the root | low |
| `.gitignore`, `README.md`, `README.html`, `AGENTS.md`, `docs/dependency-security.md`, `AGENT_SCHEDULER.md` | Updated | low |

## Verification

| Check | Result | Command / evidence |
|---|---|---|
| `node --check moorkyz` (Node 24.22.0) | PASS | exit 0 |
| `node --test` (Node 24.22.0) | PASS | 56 pass, 0 fail, 0 skipped (both PowerShell hosts) |
| Unpacker on PowerShell 7.6.6 and Windows PowerShell 5.1 | PASS | `-WhatIf` moves nothing; conflict exits 1 with nothing moved and the existing file intact; named items; unknown item fails; full unpack leaves only `unpack.ps1` |
| CI on GitHub | NOT RUN | Not pushed; Ubuntu runners need `pwsh`, which GitHub-hosted images include |

## Review

- A first manual 5.1 run looked wrong. My command cut the output with `Select -First`, which killed the process mid-run, and my cleanup then deleted the moved file. Reruns without that truncation confirmed correct behavior. `-Item a, b` via `powershell -File` passed only the first name, so items now also bind as plain trailing arguments.
- Moves are not atomic across files: an I/O failure mid-run leaves earlier files moved. Every target is checked first; rerunning is safe because existing targets stop the run.
- No secrets or dependencies added. Historical audits keep their original `.optional/` and `public/` paths as history.

## Completion

- Commit: none; blocked until the owner approves an initial baseline commit
- Human review: pending
