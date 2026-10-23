# Separate project-specific starter types

Historical report: the move behavior and 63-test result below predate the menu/copy follow-up.
Use the [current project types guide](../.template/project-types/README.md) for present behavior.

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T18-54-54Z-separate-project-specific-starter-types` |
| Created (UTC) | 2026-10-23T18:54:54.581Z |
| Auditor | Copilot SDK in VS Code; session 9c442293-ea2a-4643-8d2c-c1c84fdecbe9; self-audit |
| Baseline commit | None: unborn master; baseline files were already untracked |
| Outcome | `PASS WITH RISKS` (implementation verified; focused commit blocked) |

## Request and outcome

- Requested behavior: separate all project-specific starters by type rather than treating the template as a Node or Docker application.
- Existing Node manifest and Node-specific multi-project example now live in `.projecttypes/node/`; existing browser assets live in `.projecttypes/web/public/`; Docker starters live in `.projecttypes/docker/`. Each type mirrors root-relative destination paths.
- Setup now accepts `projectTypes` (default `[]`), not the obsolete `overlay` setting. Type selection is explicit and composable, preflights the whole selection, refuses overwrites, conflicting target/parent paths and links, and supports preview and reruns.
- Coordinated owner clarification with parallel session d753305c-08ac-4194-844d-336a2e32231a: it renamed the selector to `SetProjectType.ps1` and updated its internal examples and setup invocations; this task migrated docs/tests to that name. No menu was added.
- Initial Git state: no commits or tracked files; all baseline source was untracked. Preserved unrelated files, local runtime data and the parallel rename audit/ledger entry. No staging or commit attempted.
- Intentional exclusions: no fabricated Python/.NET starters, application, base image, deployment destination, secrets, dependency installation or deployment workflow. Shared CLI, tests, Node runtime pin and tooling CI remain at root because they serve every product type. Package/lifecycle commands are still Node-specific, not generic language runners.

## Changes

| Path | Change | Risk |
|---|---|---|
| `.projecttypes/node/` | Move npm manifest and multi-project configuration example out of the mixed/root layout | low |
| `.projecttypes/web/public/` | Move all seven existing browser assets; SHA-256 verified before/after | low |
| `.projecttypes/docker/` | Move existing optional Dockerfile/ignore rules; exclude `.projecttypes` from container context | low |
| `.projecttypes/SetProjectType.ps1` | Explicit selected-type unpacking with whole-selection preflight and no overwrites; coordinated rename | medium (moves selected starter files) |
| `setups/Make This Yours/` | Replace `overlay` with `projectTypes`; wire preview, selection and reruns | medium (existing confirmed setup removal behavior remains) |
| `tests/template.test.cjs` | Type layout, opt-in selection, dry runs, conflicts, junctions, invalid types, neutral setup and rerun regressions | low |
| `tests/documentation.test.cjs` | Validate the type guide's links, including URL-encoded spaces | low |
| `README.md`, `README.html`, `.projecttypes/README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `docs/` | Document type grouping, shared tooling, renamed selector, setup migration and Docker limitations; regenerate HTML | low |
| `moorkyz` | Update multi-project help to locate the moved Node example | low |
| `AGENT_SCHEDULER.md`, `audits/README.md` | Record request, actual acceptance results and commit blocker | low |

## Verification

All Node commands below used the already-cached Node.js v24.21.0 executable:
`C:\Users\marvi\AppData\Local\npm-cache\_npx\387698761821791d\node_modules\node\bin\node.exe`.
The system default is v22.18.0 and was not used for acceptance.

| Check | Result | Command / evidence |
|---|---|---|
| CLI syntax | PASS | `node --check moorkyz` |
| Focused regression | PASS | `node --test tests\template.test.cjs tests\documentation.test.cjs`: 17/17, no skips; PowerShell 7 and Windows PowerShell 5.1 |
| Full regression | PASS | `node --test`: 63/63, no skips; lifecycle/storage tests use disposable temporary directories |
| README generation/freshness | PASS | `node moorkyz readme`; full tests compare generated HTML exactly with Markdown |
| Asset preservation | PASS | `Get-FileHash` SHA-256 comparison for all seven moved browser assets |
| Ignore status | PASS | `git check-ignore -- .projecttypes\node\package.json .projecttypes\web\public\favicon.ico .projecttypes\docker\Dockerfile` returned 1 (not ignored) |
| `git diff --check` | PASS, limited | Empty diff because the baseline is untracked; supplemented by explicit trailing-whitespace/merge-marker scan over 19 affected source/generated files |
| Secret-pattern scan | PASS, limited | `rg` scan of affected starter/setup/test/README/CLI files found no private-key blocks, GitHub token patterns or AWS access-key patterns |
| npm install/verify/dependency audit | N/A | No root manifest or committed lockfile exists; do not create an application manifest merely to run `npm ci --ignore-scripts` / `npm run verify`. Used the repository's configured direct Node checks; no dependencies were added or installed |
| Container build/deployment | NOT RUN | Dockerfile remains an explicitly unfinished optional starter, without a product runtime or deployment contract |

## Review

- Secrets and security: no credentials or external systems introduced. Self-review plus a bounded pattern scan is not an independent security audit. Selector preflight and junction regressions preserve the no-overwrite/no-link boundary; no cleanup ran on existing user data.
- Docs and user-guide impact: current guides use `.projecttypes` and `SetProjectType.ps1`; historical audits retain their original paths as historical evidence. Markdown and the existing README HTML edition agree. The obsolete `overlay` setup key now fails explicitly instead of silently applying a stack.
- Residual risks: filesystem failures during moves can leave a partial selection; this is documented. Setup removal is permanent and retains its existing confirmation and preview behavior. Docker still needs a real pinned base image, non-root runtime, application command and health check before use.
- Commit blocker: the repository has no initial commit and all baseline files are untracked. A task-only commit cannot represent edits to that pre-existing baseline without importing unrelated work; establish/approve the initial baseline before a focused commit. No push was requested or performed.

## Completion

- Commit: `BLOCKED` by the unborn/untracked baseline; no commit hash.
- Human review: pending; no independent agent review requested.
- External actions: none; no push, PR, network install or deployment.

A generated draft is not verification evidence and a self-audit is not an
independent security review.
