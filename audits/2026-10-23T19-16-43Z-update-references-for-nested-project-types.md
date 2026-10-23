# Update references for nested project types

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T19-16-43Z-update-references-for-nested-project-types` |
| Created (UTC) | 2026-10-23T19:16:43.743Z |
| Auditor | Copilot SDK session `9b9fd353-7950-4653-9113-e2dfdeaf52e6`; self-audit |
| Baseline commit | None: unborn `master`, with the entire baseline untracked |
| Outcome | `PASS WITH RISKS`: implementation verified; focused commit blocked by the unborn, unrelated baseline |

## Request and outcome

- Requested behavior: update references after the owner moved all nine starter folders into `.projecttypes/types/`.
- Implemented behavior: selector menu discovery and explicit selections use the nested folder; setup validates those same presets while invoking the unchanged `.projecttypes/SetProjectType.ps1` entrypoint. Files still copy to the repository root, not `.projecttypes/`.
- Initial Git state: no commits, no staged changes and all baseline files untracked. Preserved the existing maintenance session's changes, including all no-op modes, checkups, CI wiring, optional npm scripts and removal of bundled tests.
- Intentional exclusions: no new product stack, package installation, dependency/lockfile changes, folder moves, user-data cleanup or bundled test suite. Historical audit commands and descriptions retain their original paths; live links and the current-location index point to the moved files.

## Changes

| Path | Change | Risk |
|---|---|---|
| [.projecttypes/SetProjectType.ps1](../.template-tools/project-types/SetProjectType.ps1) | Resolve sources under `types/`; retain the repository root destination and protection of the entire `.projecttypes/` parent; reject junctions at both source levels | Low; action-level checks passed |
| [CreateProject.ps1](../.template-tools/claim-template/CreateProject.ps1) | Separate nested preset discovery from the unchanged selector entrypoint for validation, preview and apply | Low; preview, apply and rerun checked on both hosts |
| [Project types guide](../.template-tools/project-types/README.md), [setup guide](../.template-tools/claim-template/README.md), [README.md](../README.md), [README.html](../README.html) | Update paths and preset links; regenerate HTML with the existing CLI | Low; all local links and generated HTML checked |
| [AGENTS.md](../AGENTS.md), [CONTRIBUTING.md](../CONTRIBUTING.md), [dependency maintenance](../docs/dependency-security.md) | Document `.projecttypes/types/<type>/` as the current source layout | Documentation only |
| [Audit index](README.md), [launcher audit](2026-10-23-launcher-consolidation.md), [storage audit](2026-10-23T18-24-37Z-hidden-runtime-folders-and-100-gb-trash-cap.md) | Repair live starter links without changing recorded commands or results | Documentation only |
| [Scheduler](../AGENT_SCHEDULER.md), this report | Record request, scope, actual results and commit blocker without replacing the active maintenance claim | Coordination only |

## Verification

Use `PASS`, `FAIL`, `NOT RUN` (with reason) or `N/A`; record exact commands.

| Check | Result | Command / evidence |
|---|---|---|
| Node runtime | PASS | Cached Node.js `v24.21.0`; prepended `C:\Users\marvi\AppData\Local\npm-cache\_npx\387698761821791d\node_modules\node\bin` to PATH for validation, without changing machine configuration |
| Maintenance checkups | PASS | `pwsh -NoProfile -File .\maintenance\RunCheckups.ps1 -NoPause`: 2 passed, 0 failed; 10 runnable checks plus exact-case Markdown/HTML links and HTML freshness |
| HTML regeneration | PASS | `node moorkyz readme`; generated edition matches the Markdown source |
| Action-level regression harness | PASS | `node 'C:\Users\marvi\.copilot\session-state\9b9fd353-7950-4653-9113-e2dfdeaf52e6\files\verify-type-paths.cjs' 'C:\Users\marvi\source\repos\moorkyz-template'`: 26 checks passed using `powershell.exe`, `pwsh.exe` and the CMD entrypoint |
| Source/destination behavior | PASS | All nine presets preview without writes, copy byte-for-byte into the fixture repository root and rerun unchanged. Starter hashes are preserved. Setup validates, previews, applies and reruns with nested Node/web/TypeScript selections |
| Rejection/safety behavior | PASS | Container name `types`, invalid names, differing root files, protected `.projecttypes/` destinations and a source-directory junction are rejected without copies; CMD forwards failure |
| Menu discovery | PASS | Simulated Q key with mocked terminal input lists exactly the nine nested presets and cancels without writes; an unrelated sibling directory is not offered |
| Stale live references | PASS | Repository search found no links to old direct preset paths or old `.projecttypes/<type>/` guidance; historical literal paths are retained intentionally |
| Secret review | PASS | No private-key, GitHub-token or AWS-access-key pattern matches in the task-owned files; manual self-review found no added credentials, external destinations or dependencies |
| Whitespace | PASS | `git diff --check`; because the baseline is untracked, also ran `git diff --no-index --check -- NUL <file>` for each task-owned implementation/documentation file; no whitespace defects |
| Dependency audit / npm baseline | N/A | There is no root package manifest or committed lockfile. `npm ci --ignore-scripts` and `npm run verify` cannot be run at root; did not invent them or install optional presets |
| Focused local commit | BLOCKED | `git log -1 --oneline` confirms unborn `master`; staging whole untracked files would include unrelated baseline and maintenance work |

The disposable harness initially failed on its own menu-output regex and Windows
command-line quoting; both were corrected before the final complete PASS.
The initial credential scan also needed `--` before its pattern. These were
verification-harness issues, not product failures. All generated fixture
directories were removed, including on failed runs. The harness stays in session
storage outside this repository; no bundled tests were restored.

## Review

- Secrets and security: self-reviewed input validation, no-overwrite preflight, root destination calculation, protected parent boundaries and source link rejection. The new `types/` level does not narrow protection to only the nested source folder. No dependencies, secrets, remote actions or data-cleanup behavior were added.
- Docs and user-guide impact: current paths are consistent across root docs, setup/preset guides, live historical links and the generated HTML. Launcher commands remain unchanged. The maintenance additions are preserved.
- Findings and residual risks: no task-related correctness issues remain. Interactive key handling was not exercised in a real terminal; only discovery/cancellation was simulated. Linux action-level behavior was not run locally. Existing copy-time filesystem failures can still leave partial additions, as already documented.
- Blocker: a focused commit cannot be isolated from an unborn, wholly untracked baseline. Owner-approved initialization is needed first; no unrelated files were staged.

## Completion

- Commit: `BLOCKED` by the unborn baseline; no commit or staging performed.
- Human review: pending; no independent agent/security review requested.
- External actions: none; no push, publication or deployment.

A generated draft is not verification evidence and a self-audit is not an
independent security review.
