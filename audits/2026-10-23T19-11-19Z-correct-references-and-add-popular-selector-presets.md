# Correct references and add popular selector presets

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T19-11-19Z-correct-references-and-add-popular-selector-presets` |
| Created (UTC) | 2026-10-23T19:11:19.689Z |
| Auditor | Copilot SDK in VS Code; session 9c442293-ea2a-4643-8d2c-c1c84fdecbe9; self-audit |
| Baseline commit | None: unborn master, unrelated baseline already untracked |
| Outcome | PASS WITH RISKS; current maintenance 2/2 and relocated-preset acceptance pass; focused commit blocked |

## Request and outcome

- Requested: check every source file for incorrect references/names. Follow-up: provide a CMD selector entrypoint, allow multiple selections and add more popular simple packages.
- Corrected current filename casing (`CreateProject.ps1`, `SetProjectType.ps1`), actual repository reporting URL, CLI examples and setup's template-repository URL replacement. Historical audit links now point to current files; removed files are explicitly marked historical, without rewriting prior test results.
- Added `.projecttypes/SetProjectType.cmd` as a Windows companion to the existing PowerShell selector. No-argument use opens the menu and pauses afterwards; argument-based automation forwards the real exit code without pausing.
- Added six opt-in configuration presets: `typescript`, `eslint`, `prettier`, `stylelint`, `markdownlint`, `vscode`. Together with `node`, `web` and `docker`, nine types were verified in one selection. Presets do not install packages/extensions, merge manifests or invent applications.
- Clarification form was unavailable; chose small development-tool configurations instead of speculative framework/application scaffolds. TypeScript uses Node-style modules; ESLint's rules cover JavaScript, not TypeScript parsing. Required packages and local checks are documented.
- Initial Git state: all baseline files untracked, no commits. Preserved unrelated files and coordinated with menu, cleanup, maintenance and agent-setup owners. Did not change the selector's menu/copy implementation or perform local-data cleanup.
- Parallel owner-approved maintenance work removed the bundled tests after this task's 107/107 acceptance. Did not restore them. Updated historical test links and handed durable name/reference/preset checks to the maintenance owner; current acceptance must use maintenance rather than pretending the removed suite still exists.
- Another parallel layout change grouped the starter folders under `.projecttypes/types/`. Preserved that layout and reran all-nine/CMD acceptance against the relocated files; current docs and links use the new paths.

## Changes

| Path | Change | Risk |
|---|---|---|
| `README.md`, `README.html`, `.projecttypes/README.md`, setup README | Exact current names, CMD instructions, nine-type list, package prerequisites and copy-only/no-install warnings | low |
| `.projecttypes/SetProjectType.cmd` | Windows entrypoint; forwards arguments, preserves exit status, pauses only with no arguments; CRLF | low |
| `.projecttypes/types/{typescript,eslint,prettier,stylelint,markdownlint,vscode}/` | Independent, composable tooling configuration; no package installation or runtime; relocated by the parallel layout change | low |
| `SECURITY.md`, `setups/Make This Yours/CreateProject.ps1` | Correct actual template repository URL and rewrite it correctly for adopted projects; replace misleading Unpack naming with ProjectTypes/copy | low |
| `AGENTS.md`, `AGENT_SCHEDULER.md`, `moorkyz`, `docs/` | Correct identity/path examples and document current entrypoints | low |
| `audits/` | Repair moved-file links; mark obsolete paths and removed tests as historical; provide current-location map | low |
| Former `tests/documentation.test.cjs`, `tests/template.test.cjs`, `tests/project-type-presets.test.cjs` | Expanded and executed regression checks; later removed by the separate maintenance request, not recreated | historical evidence only |

## Verification

Acceptance used the cached Node.js v24.21.0 executable, not the system Node 22:
`C:\Users\marvi\AppData\Local\npm-cache\_npx\387698761821791d\node_modules\node\bin\node.exe`.
All copy/application tests used disposable OS temporary directories.

| Check | Result | Command / evidence |
|---|---|---|
| Initial reference reproduction | FAIL as expected | Expanded documentation suite: 5/8 pass; found eight broken/case-mismatched links, obsolete examples and the placeholder security URL |
| Corrected references and setup integration | PASS | `node --test tests\documentation.test.cjs tests\template.test.cjs`: 20/20, both PowerShell hosts; adopted security URL rewritten correctly |
| New presets and real CMD | PASS | `node --test tests\project-type-presets.test.cjs`: 4/4; all nine types preview/apply/rerun on PowerShell 7 and Windows PowerShell 5.1, invalid type nonzero, source bytes preserved; CMD invoked from a different working directory with spaces in the script path |
| CMD test harness correction | PASS after fix | First harness run failed because Node escaped the CMD command's quotes; `windowsVerbatimArguments: true` corrected the harness; real CMD forwarding then passed |
| Full regression before maintenance migration | PASS, historical | `node --check moorkyz`; `node --test`: 107/107, zero skipped; subsequently superseded by owner-approved removal of the bundled tests |
| Post-removal targeted suite invocation | NOT APPLICABLE | Test files were removed concurrently before the final targeted command; it failed on missing paths. No current test-suite success is claimed from that invocation |
| Current maintenance | PASS | Node 24.21.0 first in PATH; `pwsh -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File maintenance\RunCheckups.ps1 -NoPause`: 2/2 checkups, 10 runnables, all local Markdown/HTML links with exact casing, README freshness |
| Maintenance integration issues | RESOLVED | Reported multiple Node paths from `Get-Command node`; owner selected the first application. Regenerated README HTML after the parallel layout/doc changes; final runner is green |
| Relocated all-nine/CMD acceptance | PASS | Disposable inline Node assertions after test removal: all nine types under `.projecttypes/types/`, real pwsh/powershell.exe/cmd.exe preview/apply/rerun, invalid/conflicting inputs nonzero, user file preserved, source bytes preserved, JSON/webmanifest parse; temp paths contain spaces |
| Real Prettier configuration | PASS | Cached Prettier 3.9.10 resolved the new preset and formatted a sample exactly as asserted; no install |
| Configuration shape/syntax | PASS | JSON presets parse; ESLint and Stylelint configs import as ESM; both PowerShell hosts selected all types without conflicts |
| Formatting and markers | PASS | Explicit scan of 40 existing task source files: no trailing whitespace or merge markers; CMD has CRLF; `git check-attr eol` reports crlf |
| Secret scan | PASS, limited | Bounded private-key/GitHub-token/AWS-key pattern scan of current affected sources and audits returned no matches; no ignored local data scanned |
| `git diff --check` | PASS, limited | No tracked diff because baseline is entirely untracked; supplemented by the explicit source scan |
| Starter ignore status | PASS | New CMD, TypeScript config and VS Code recommendations are not Git-ignored |
| npm install / dependency audit | N/A | No root application manifest or authoritative lockfile; no dependency installation or new baseline dependencies |

## Review

- Secrets and security: no credentials or external systems introduced; only public tool documentation was fetched. Self-review and a bounded token-pattern scan are not an independent security audit.
- Docs and user-guide impact: exact-case link validation originally covered every Markdown/HTML file, including historical audits and new hidden source directories; active script examples were checked for current spelling/case. The maintenance owner received those requirements after test removal. README HTML was regenerated.
- Current tooling formats were checked against official TypeScript module, ESLint flat-config, Prettier config, Stylelint config and VS Code extension-recommendation documentation, plus markdownlint-cli configuration documentation. Stylelint uses the modern `stylelint.config.mjs` form.
- Residual limits: no real product or framework was selected. Tools other than cached Prettier were not installed; full product lint/type checks require the chosen packages and actual product source. A real double-click/physical keyboard session was not automated by this task; argument-based CMD behavior and the existing menu regressions were exercised.
- Concurrent migration: maintenance owns runner/checkups, DryRun modes, current verification wiring and test removal. Did not recreate bundled tests or overwrite that work. Final current maintenance is green, recorded separately from the earlier successful suite. Read-only checkups do not replace the removed lifecycle/storage-action regression coverage.
- Commit blocker: no initial commit and all pre-existing content untracked; staging a focused task-only diff would import unrelated baseline work. Nothing staged, committed or pushed.

## Completion

- Commit: BLOCKED by unborn/untracked baseline; no commit hash.
- Human review: pending; no independent agent/security review requested.
- External actions: public documentation reads only; no package installation, upload, push, PR or deployment.

A generated draft is not verification evidence and a self-audit is not an
independent security review.
