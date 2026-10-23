# Setup automation

Historical report: paths, commands and results below describe this task's original state.
The current setup is [CreateProject.ps1](../.template-tools/claim-template/CreateProject.ps1);
type selection uses [SetProjectType.ps1](../.template-tools/project-types/SetProjectType.ps1) and copies starters.

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T18-45-00Z-setup-automation` |
| Created (UTC) | 2026-10-23T18:45:00Z |
| Auditor | AI assistant (Copilot SDK in VS Code); self-audit |
| Baseline commit | None (unborn `master`, entire tree untracked) |
| Outcome | `PASS WITH RISKS` |

## Request and outcome

- Requested: a template automation of one script and one config file; the script errors until the config is set up, removes template-only content such as trash, archive, audits and tests, and always ends with "press any key to continue".
- Added `setups/Make This Yours/createproject.ps1` and `setups/Make This Yours/setup.config.json` (outside the root, so `moorkyz` stays the only root script). `projectName` and `displayName` ship empty, so the first run lists every missing or invalid setting and changes nothing. Unknown settings, bad overlay names, absolute or `..` paths, `.git`, the root itself and links/junctions are rejected.
- With a valid config it prints the plan, asks for `y` (or `-Yes`; `-WhatIf` previews), unpacks overlay items through `overlay/unpack.ps1` (all conflicts checked first), permanently removes the configured paths (default: `.trash`, `.archive`, `.logs`, `trash`, `archive`, `logs`, `audits/20*`, `tests`), replaces the project placeholder and template GitHub owner in UTF-8 text files (keeping BOMs and line endings; skipping binaries, `.git`, runtime folders, `audits/` and `setups/`), sets the README title, regenerates `README.html` when Node is available, and optionally deletes `setups/` last. It always pauses unless `-NoPause` or input is redirected. Reruns are idempotent.
- Template-only checks moved to `tests/template.test.cjs` so projects can drop them and keep the CLI tests. Docs avoid the literal placeholder and link-checked paths to folders a project may delete.
- The owner moved the files during the task to `setups/Make This Yours/` and renamed the script `createproject.ps1`. The script now finds the repository root by walking up to the folder containing `moorkyz` or `.git`, always skips its own folder during replacement, and deletes any `remove` target containing itself last. Tests locate the folder through `setup.config.json`, so later renames keep working.
- Fixed in both scripts: `ForEach-Object Name` (member form) and `Where-Object Name` return nothing under `-WhatIf`; replaced with script blocks.

## Verification

| Check | Result | Command / evidence |
|---|---|---|
| `node --test tests/template.test.cjs` (Node 24.22.0) | PASS | 8 pass on PowerShell 7.6.6 and Windows PowerShell 5.1: refusal, invalid settings, `-WhatIf`, missing confirmation, apply, BOM/CRLF preservation, rerun, self-removal, unpack |
| Pause after error | PASS | Unconfigured script in its own hidden console stayed open waiting for a key, 3 runs on each host; pending input is flushed first. Visible-window runs could be ended by stray keystrokes while the owner was typing |
| Repository root not found | PASS | Script copied outside any repository reports the missing root and still pauses; `moorkyz` must be a file, so an unrelated `Moorkyz` folder in `%TEMP%` is ignored |
| Full suite (Node 24.22.0) | PASS, then superseded | 59/59 passed at 20:49 UTC+2. At 20:52 a concurrent scheduler item (TYPES-005, session 9c442293) moved `overlay/` to `.projecttypes/{node,web,docker}` and renamed the config key to `projectTypes`. The next run had 54/59 passing: the 5 overlay and setup template tests now await that in-progress item. |
| Interactive `y/N` prompt | NOT RUN | covered only through `-Yes` and the redirected-input refusal |

## Review

- Removal is permanent by design; mitigated by the empty default config, plan output, explicit confirmation, `-WhatIf`, root/`.git`/link guards and a default list of disposable or template-only paths.
- `node --test` passes with zero test files, so removing `tests/` keeps CI green; CI then only checks launcher syntax.
- No secrets or dependencies added.

## Handoff

- TYPES-005 is `IN_PROGRESS` and owns `.projecttypes/`, `unpack.ps1`, the setup script, template tests and docs. This task stopped editing them to respect the single-active-item rule. Its acceptance should keep the setup's verified behavior: refuse until configured, find the root via the `moorkyz` file or `.git`, flush input and pause at the end, defer self-removal, and keep BOMs and line endings.

## Completion

- Commit: none; blocked until the owner approves an initial baseline commit
- Human review: pending
