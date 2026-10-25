# Add safe Moorkyz script icons

| Field | Value |
|---|---|
| Audit ID | `2026-10-25T15-54-22Z-add-safe-moorkyz-script-icons` |
| Created (UTC) | 2026-10-25T15:54:22.933Z |
| Auditor | Copilot SDK in VS Code, session 4173e5d1-4458-4c68-a030-e31967a15fcb; self-audit |
| Baseline commit | `7e5f3f8` |
| Outcome | `PASS WITH RISKS` |

## Request and outcome

- Requested behavior: find scripts, CMD files and executables; apply the supplied Moorkyz icon wherever possible without breaking structure.
- Implemented: 41 sources inventoried; 26 runnable entrypoints receive local Windows shortcuts with the exact supplied ICO. Fifteen browser/configuration/library sources are explicitly skipped. No target was executed by icon generation.
- Initial Git state: scheduler and six design files were modified; two earlier audits, editor settings and the introduction were untracked. All unrelated work is preserved and excluded from this commit, including other owners' scheduler rows.
- Windows source scripts cannot embed per-file Explorer icons. Shortcuts are the non-invasive alternative; no registry changes, global associations, recompilation, executable-resource/signature changes, source renames or folder moves.

## Analyzing and Reading

- Read the authoritative agent contract, contributor checklist, shared queue, tool catalog, maintenance runner/runnable/documentation/soft-copy checks and affected launcher examples.
- Acceptance: use the owner-supplied icon; cover all current standalone entrypoints; keep source bytes and command semantics; record exclusions; prove real icon/target/argument/working-directory properties rather than merely checking file existence.
- Edge cases: quoted/spaced/ampersand paths, safe modes, existing output, invalid output parents, source/output junctions, missing icon and single-entry inventory shape.
- Coordination question returned owner unavailable with direction to choose pragmatically. Chose disjoint template-tool scope; did not take over active website/deployment/introduction claims.

## Researching and Planning

- Reused the template tool layout, ignored `.moorkyz/` boundary, side-effect-free `-DryRun`, `SupportsShouldProcess`, maintenance runner and audit entrypoint.
- Verified the Windows Script Host `CreateShortcut`, `TargetPath`, `Arguments`, `WorkingDirectory`, `IconLocation` and `Save` contract against [Microsoft's example](https://learn.microsoft.com/en-us/troubleshoot/windows-client/admin-development/create-desktop-shortcut-with-wsh), retrieved successfully during this task.
- Chose local `.lnk` files under ignored `.moorkyz/script-icons/`, mirroring source paths. Only the supplied ICO is copied into tracked tool helpers; the six other supplied assets remain untouched.
- No dependencies, administrator privileges or external services are introduced. No push/deployment/publication approval is implied.

## Developing

- Added [SetScriptIcons.ps1](../.template/script-icons/SetScriptIcons.ps1), [usage/limitations](../.template/script-icons/README.md), the exact [ICO](../.template/script-icons/helpers/moorkyz.ico), and [disposable regressions](../.template/maintenance/helpers/checkups/08-script-icons.ps1).
- Registered the tool in the catalog and documentation-layout check; documented its maintenance coverage. No root README content changed, so root HTML/design README regeneration is N/A.
- PowerShell shortcuts use the generating host, no execution-policy bypass, and `-NoExit`; native shortcuts target their source; Node shortcuts resolve the installed runtime without a command-shell wrapper. All run from the repository root with no task arguments or implicit approvals.
- Initial COM regression failed for legacy COM executable targets, including a real Windows PE renamed to `.com`; an isolated three-name COM probe confirmed Windows Script Host refused saving those direct targets. Changed classification to explicit unsupported/skipped instead of adding a shell workaround. There are no COM/EXE/BAT files in the current repository.
- Fixed single-source JSON output to remain an array and added its regression. Review also wired the new tool into the existing documentation check's explicit registry.

| Path | Change | Risk |
|---|---|---|
| [.template/script-icons/](../.template/script-icons/README.md) | Windows-only branded launcher generator, guide and owner ICO | Local absolute paths; source icons remain unchanged |
| [08-script-icons.ps1](../.template/maintenance/helpers/checkups/08-script-icons.ps1) | Real COM assertions and disposable safety cases on both hosts | No real tools are launched |
| [02-documentation.ps1](../.template/maintenance/helpers/checkups/02-documentation.ps1) | Include new tool in entrypoint/README/helpers layout checks | Read-only assertion only |
| [Catalog](../.template/README.md) and [maintenance guide](../.template/maintenance/README.md) | Discovery, commands, coverage and limitations | Documentation only |
| [Queue](../AGENT_SCHEDULER.md) | Only this request's ledger/closure | Other claims and dirty rows preserved |

## Clean Up

### Verification

Use `PASS`, `FAIL`, `NOT RUN` (with reason) or `N/A`; record exact commands.

| Check | Result | Command / evidence |
|---|---|---|
| Full maintenance | PASS | `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause` with verified cached Node 24.22.0 prepended to this command's PATH: 8 passed, 0 failed. |
| Final shortcut regressions | PASS | `pwsh -NoProfile -File .\.template\maintenance\helpers\checkups\08-script-icons.ps1`: 20 groups, PowerShell 7.6.6 and Windows PowerShell 5.1. Covers safe modes, actual properties, eleven fixture targets, six skips, source hashes, rerun refusal, invalid parent, both junction directions, singleton JSON and missing ICO. |
| Final runnable syntax/safe modes | PASS | `pwsh -NoProfile -File .\.template\maintenance\helpers\checkups\01-runnables.ps1`, Node 24.22.0, after final generator/test changes. |
| Documentation, layout and references | PASS | `pwsh -NoProfile -File .\.template\maintenance\helpers\checkups\02-documentation.ps1`: exact-case local links and root HTML freshness; rerun after final registry/audit/queue updates before commit. |
| Actual icon installation | PASS | `pwsh -NoProfile -File .\.template\script-icons\SetScriptIcons.ps1`: 26 shortcuts, 15 explicit skips. Reopened every shortcut through COM and checked icon, target, arguments and working directory. |
| Source preservation | PASS | Compared all 39 initially tracked runnable SHA-256 values immediately before/after icon generation; no bytes changed by that action. Only the intentionally updated documentation check and newly added scripts are implementation changes. |
| Icon integrity | PASS | Source/copy SHA-256 both `C9C32C267A070B05DF0DBF9D8653FA6C2772AF34ED08FC0EDE807B121402BBCB`; `System.Drawing.Icon` decoding and dimensions checked on both hosts. |
| Runtime-output exclusion | PASS | `git check-ignore .moorkyz\script-icons\inventory.json`; generated shortcuts/inventory remain ignored. |
| Dependency audit / application build | N/A | No manifests, third-party packages or application runtime changed. Existing product regressions are included in required maintenance. |
| Whitespace / staged scope | PASS | Scoped `git diff --check`; final `git diff --cached --check` and staged diff inspected before the focused local commit. |
| Final-state rechecks | PASS | Full suite followed by affected shortcut/runnable/documentation rechecks after corrections; final installed shortcut metadata checked again after regeneration against the permanent installed Node path. |

### Quality and safety review

- Self-review by this session covered all owned source, tests, docs, binary provenance and staged queue hunks. No independent security-review claim is made.
- No source target is imported/executed during discovery. Existing output and source/output links are refused; errors terminate explicitly. No shell string wrapper is used for Node arguments. No execution policy, credentials, settings or file associations are changed.
- No secrets or private source/runtime content added to tracked files. Generated inventory contains local absolute paths and remains ignored. The ICO is owner-supplied, not a third-party asset download.
- Rerunning intentionally fails before writes if any generated file already exists. Partial failures remain visible rather than being silently overwritten or cleaned up.
- Tests use unique disposable fixtures; cleanup removes only task-owned fixture directories. Replaced the first task-generated launcher set only after proving every contained file belonged to its inventory; regenerated using the persistent installed runtime, not the temporary validation runtime.
- Human/Explorer visual review is pending and not required by an existing gate; independent agent review was not requested. COM metadata and actual ICO decoding are verified, not a claim that Explorer caching has been visually inspected.
- Residual risk: absolute local paths need regeneration after a move/runtime removal. Console-only Node output can close immediately. Native source file icons remain unchanged. Legacy COM shortcuts are intentionally unsupported.
- Pre-existing environment limitation: default installed Node is 22.18.0; maintenance requires Node 24.22.0 and passed with a per-command PATH override. Final local Node shortcuts point to the permanent installed Node path, preserving runtime selection instead of depending on a temporary cache. No global runtime installation/PATH changes were authorized or made.

### Final references and documentation

| Reference / content | Availability / validity | Command / source / evidence and impact |
|---|---|---|
| Entry scripts, helper ICO, registry entry, guides and queue audit link | PASS | Real files and exact casing checked by final documentation check; COM properties point to existing local files. |
| PowerShell 5.1/7, Windows Script Host, System.Drawing and Node discovery | PASS | Actual two-host fixture execution; no new APIs/packages installed. Non-Windows refusal exists, but a Linux host was NOT RUN because unavailable. |
| Windows Script Host example | PASS | Microsoft Learn page fetched successfully; documented properties match exercised COM API. |

- No changed external reference was unreachable. Explorer's on-screen cache appearance and Linux execution are not verified.
- Catalog, tool guide, maintenance coverage and this request's queue evidence updated. Root README/HTML and design pages left untouched.
- Disposable test/probe directories removed. Existing data and unrelated user work preserved. Local launchers/inventory intentionally remain as requested deliverables.
- Final tests and reference checks cover all final implementation changes; post-audit documentation check and staged review are completion gates.

### Completion

- Commit: focused local commit includes this audit; hash reported in the final response (do not edit audit afterwards).
- Staged diff and `git diff --cached --check`: required and inspected before committing; only owned files and the owned scheduler request hunk are staged.
- Human review: pending
- Required checks/approvals: required maintenance and affected final checks PASS; no missing required approval. Scoped claim released with closure evidence in the commit; other sessions' work remains untouched.
- External actions: none; no push, deployment, publishing or settings changes.

A generated draft is not verification evidence and a self-audit is not an
independent security review.
