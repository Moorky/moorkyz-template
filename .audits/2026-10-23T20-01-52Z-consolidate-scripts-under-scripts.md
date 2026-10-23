# Consolidate scripts under .scripts

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T20-01-52Z-consolidate-scripts-under-scripts` |
| Created (UTC) | 2026-10-23T20:01:52.115Z |
| Auditor | Copilot SDK in VS Code, session e8efba40-e5dd-47c9-8b13-4bb454921d80; self-audit |
| Baseline commit | Unborn `master`; existing repository content is untracked |
| Outcome | `PASS WITH RISKS`: implementation verified; empty legacy directory is OS-locked and focused commit requires an owner-approved baseline |

## Request and outcome

- Owner requested one consistently named parent for all script folders, with
  entry script(s) and README together and supporting files in a helper subfolder.
  Owner then explicitly selected `.scripts/` and requested guidance in AGENTS
  and relevant docs to use fitting existing tools when needed.
- A newer owner instruction in the coordinated Copilot-status session explicitly
  keeps `moorkyz` at the repository root. Preserved that exception; the four
  tool folders are consolidated, not the root CLI. GitHub workflows and
  agent-discovery files remain in their platform-required locations.
- Added a tool catalog and usage guidance, corrected executable/resource/root
  resolution, updated consumers and preset ignores, and remapped documentation
  links. Historical audits retain their executed commands and results; their
  local links now resolve to the current files.
- Initial state: unborn branch, all baseline files untracked, empty index.
  Preserved existing configuration values, assets, ignored runtime data and
  concurrent Copilot-status changes. Did not recreate removed example tests.
- Exclusions: no product runtime, dependencies, deployment, cleanup of existing
  local data, settings changes to the real user/project, or history rewriting.

## Changes

| Path | Change | Risk |
|---|---|---|
| [.template/README.md](../.template/README.md) | Catalog of all four tools plus the root CLI; explains when tools may fit, no-op/preview modes and consistent folder layout | Guidance only |
| [.template/maintenance/](../.template/maintenance/README.md) | Entry runner/README together; checkups nested under `helpers/checkups/`; root discovery and safe runnable/document/preset checks follow the new locations | Both PowerShell hosts exercised |
| [.template/project-types/](../.template/project-types/README.md) | Selector entrypoints/README together; all nine type resources under `helpers/types/`; repository root remains the copy destination | Disposable per-type/combined checks on PowerShell 7, 5.1 and CMD |
| [SetProjectType.ps1](../.template/project-types/SetProjectType.ps1) | Protect the entire shared `.scripts/` tree from preset writes and reject linked parent/helper directories | New shared-tool protection tested without partial copies |
| [.template/claim-template/](../.template/claim-template/README.md) | Adoption entrypoint/README together; configuration under `helpers/`; updated preset/config/CLI references | Preview/apply/rerun from unrelated CWD tested |
| [.template/copilot-settings/](../.template/copilot-settings/README.md) | Installer/README together; config, agent template and BYOK example under `helpers/` | Helper lookups, guide preservation and write-free preview tested; status work belongs to its separate owner |
| [AGENTS.md](../AGENTS.md), [portable guide](../.template/copilot-settings/helpers/AGENTS.template.md), [task-audit skill](../.agents/skills/task-audit/SKILL.md) | Tool-discovery guidance: consult existing tools when appropriate, not automatically; use the relocated maintenance entrypoint | No unconditional setup actions |
| [README.md](../README.md), [README.html](../README.html), [CONTRIBUTING.md](../CONTRIBUTING.md), [docs](../docs/INFRASTRUCTURE.md), [audit index](README.md) | Current tool names/locations, adoption/helper paths, usage guidance and valid current links, including historical reports | HTML regenerated; exact-case links verified |
| [CI](../.github/workflows/project-tooling.yml), [Node preset](../.template/project-types/helpers/types/node/package.json) | Invoke consolidated maintenance runner; formatting/lint/Docker presets exclude shared `.scripts/` tooling | No installs or dependency changes |
| [moorkyz](../moorkyz) | Root CLI retained byte-identical under the newer owner instruction; obsolete relocated copy/folder removed | 20 no-op modes and fixture-only actions verified |
| Old source directories | Removed emptied maintenance, project-type, setup and `.important_scripts` folders; old `.github/copilot` has no files but remains locked by another process | No recursive deletion of user data or forced process closure |

## Verification

Use `PASS`, `FAIL`, `NOT RUN` (with reason) or `N/A`; record exact commands.

| Check | Result | Command / evidence |
|---|---|---|
| Pre-change baseline | PASS, 3/3 | `pwsh -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\maintenance\RunCheckups.ps1 -NoPause`, Node.js v24.21.0 |
| Final PowerShell 7 maintenance | PASS, 4/4 | `pwsh -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\.scripts\maintenance\RunCheckups.ps1 -NoPause`, Node.js v24.21.0 |
| Final Windows PowerShell 5.1 maintenance | PASS, 4/4 | `powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\.scripts\maintenance\RunCheckups.ps1 -NoPause`, Node.js v24.21.0 |
| Focused layout/action regressions | PASS, 14 groups | Node.js v24.21.0 `node <session-files>\Validate-ScriptLayout.cjs <repo> <session-files>\scripts-before.json`; both PowerShell hosts, disposable spaced-path fixtures only |
| Asset/config preservation | PASS, 17 files | SHA-256 comparison with a pre-move snapshot: root CLI, setup/Copilot/BYOK configuration and unchanged preset assets are byte-identical |
| CLI safety and CWD behavior | PASS | All 20 public commands with `--dry-run` preserve the fixture snapshot; actual README/audit generation writes only to the disposable current directory |
| Adopted product source behavior | PASS, both hosts | A throwing JavaScript fixture outside `.scripts/` is syntax-checked, never imported/executed or rejected merely for being product source |
| Preset/action behavior | PASS | Each of nine presets and combined preview/apply/rerun/invalid/conflict cases on PowerShell 7, 5.1 and CMD; source bytes and user sentinels preserved |
| Copilot compatibility | PASS | Final runner includes the coordinated owner's `04-copilot-setup.ps1`; both hosts cover helper inputs, success/rerun, JSONC/backups, previews/no-op, validation/aggregated failures and isolated scopes |
| README and links | PASS | `node .\moorkyz readme`; maintenance verifies byte-identical generated HTML, exact-case local Markdown/HTML links, tool layout, icons, CI references and existing safety invariants |
| Dependency installation/audit | N/A | No root package manifest or committed lockfile; no dependencies changed or installed. Used configured direct maintenance, not fabricated `npm ci --ignore-scripts` / `npm run verify` prerequisites. |
| Diff/whitespace | PASS, 55 task text files | Six runtime path diffs inspected against pre-move source; `git -c core.safecrlf=false diff --no-index --check -- NUL <path>` passed. Suppression of line-ending conversion notices was process-only; no Git settings changed. Ordinary Git diff cannot cover an untracked baseline. |

Final focused checks also cover selector root discovery from an unrelated shell
directory, refusal to write into shared tooling, adoption preview/apply/rerun,
helper configuration, preset copies, README regeneration, preservation of user
files/history, installer template lookup and preservation of an existing guide.
All action fixtures and fake `APPDATA` locations are freshly generated under
the system temporary directory and removed in `finally`.
All pre-move baseline files were accounted for at their final locations. Removed
the migration script, fixture harness and preimage snapshot after verification.

The first move attempt hit the legacy directory lock after moving the files;
resumed documentation remapping from the saved pre-move snapshot without
replacing live data. An intermediate runner failed while another session
restored the CLI to root under the newer owner instruction; coordinated the
exception and its pointer updates, then both final runners passed.
The owner subsequently named the adoption tool `.scripts/claim-template` in a
separate session. Preserved that newer name and adapted disposable verification
paths without rewriting historical commands or taking over its owner's rename.
Final verification also caught the unchanged CLI unexpectedly moved into
`.scripts/project-types/`. Verified its SHA-256 against the pre-task source and
restored only its required root location with no-overwrite guards; no content
or unrelated file was replaced. Current layout/documentation checks then passed.

Self-review removed an initially added overly broad `.scripts` location guard:
it would have incorrectly rejected a future adopted application's JavaScript
source. The final checks enforce the known tool-folder structure without
changing the existing syntax-only behavior for product modules. Both new
disposable regressions passed.

## Review

- Secrets/security self-review: no credentials or secret values introduced;
  configuration values and binary assets preserved. No external calls/uploads,
  packages, deployment actions or real-user settings writes. Source/root/helper
  link guards remain active. New protection covers all shared tooling, not only
  the selector's own source. A self-audit is not an independent security review.
- Documentation: root Markdown/HTML agree, current names consistently use
  `.scripts/`, and tool/agent guides explain when to reuse existing scripts.
  Historical audit command text remains historical evidence, not instructions;
  current links are repaired rather than test history rewritten.
- Remaining local directory: `.github/copilot` is verified empty, but Windows
  reports that another process holds it open. Node and PowerShell deletion
  attempts both reported the lock. Did not kill unrelated processes or force
  removal. Once the owning process releases it, remove only that empty directory.
  It contains no scripts, settings or helper files and is not tracked.
- Other limits: action checks ran on Windows PowerShell 5.1 and PowerShell 7;
  Linux execution is delegated to the existing CI matrix, not claimed as run.
  Real adoption configuration was preserved; its owner must supply valid project
  values before applying adoption outside disposable fixtures.
- Commit blocker: no initial baseline commit exists. Shared task edits are in
  otherwise unrelated untracked files, so an initial commit would capture other
  owners' content. Leave the index empty; an owner-approved baseline is required
  before a focused task commit can be created safely.

## Completion

- Commit: `BLOCKED` by the unborn/shared untracked baseline; no commit created.
- Human review: pending
- External actions: none unless separately approved

A generated draft is not verification evidence and a self-audit is not an
independent security review.
