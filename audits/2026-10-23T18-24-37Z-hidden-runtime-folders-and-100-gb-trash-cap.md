# Hidden runtime folders and 100 GB trash cap

Historical report: commands and results describe this task's original state.
See [current names and locations](README.md#current-names-and-locations) for later moves and removals.
The bundled test files cited below were later removed; current checks use
[maintenance](../.scripts/maintenance/RunCheckups.ps1).

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T18-24-37Z-hidden-runtime-folders-and-100-gb-trash-cap` |
| Created (UTC) | 2026-10-23T18:24:37.445Z |
| Auditor | Copilot SDK in VS Code, self-audit |
| Baseline commit | None: unborn `master`, entire baseline untracked |
| Outcome | PASS WITH RISKS; focused commit blocked by unrelated untracked baseline |

## Request and outcome

- Requested behavior: a 100 GB trash holding limit, dot-prefixed archive naming,
  advice about audit visibility, and an explanation of duplicate trash folders.
  The duplicate came from pre-existing dot folders plus initialization using
  non-dot names. The explanation and recommended layout were provided.
- Implemented behavior: new runtime storage uses `.trash/`, `.logs/`, `.archive/`
  and `.moorkyz/`. `audits/` remains visible and tracked for review history.
  With the owner unavailable to clarify, use decimal GB and preserve all existing
  data rather than assuming permission to migrate or delete it.
- Trash defaults to 100,000,000,000 bytes, recursively counting regular file
  sizes. Normal maintenance archives oldest top-level items until the remainder
  fits. Directories move as one batch item, ordered by top-level modification
  time with path tie-breaking. Exactly-at-cap contents remain staged. A lower
  whole-byte `storage.maxTrashBytes` is allowed, including zero; larger values
  and invalid numbers fail explicitly.
- Normal passes combine overflow and log rotation in one verified ZIP. Explicit
  `maintain` retains its prior behavior of archiving all staged trash. Source
  removal still requires archive verification and unchanged source identities
  and content.
- Initial Git state: unborn branch, all baseline content untracked. Existing
  hidden and visible runtime directories were left untouched, and unrelated
  prior documentation/template changes were integrated rather than reverted.
- Intentional exclusions: no automatic migration or deletion of old runtime
  folders, no rename of audit history, no Windows Hidden attribute changes,
  no independent daemon, application, deployment or ZIP64 implementation.

## Changes

| Path | Change | Risk |
|---|---|---|
| [moorkyz](../moorkyz) | Hidden runtime paths, trash policy validation, recursive sizing and oldest-item overflow selection; legacy saved log paths stay readable | External writes are only checked during maintenance; classic ZIP limits still apply |
| [config example](../.scripts/project-types/helpers/types/node/moorkyz.config.example.json) | Added `maxTrashBytes: 100000000000`; example later moved into the Node type | Existing configurations inherit the new default |
| [.gitignore](../.gitignore), [Docker ignore starter](../.scripts/project-types/helpers/types/docker/.dockerignore) | Exclude dot-prefixed runtime folders; starter later moved into the Docker type | Existing recovery data stays local |
| `tests/storage.test.cjs` (since removed) | Exact default/cap boundaries, nested sizing, overflow batches, hidden initialization, legacy preservation and failure safety | Large boundary simulated through metadata, not 100 GB disk allocation |
| `tests/moorkyz.test.cjs`, `tests/documentation.test.cjs` (since removed) | Hidden paths, legacy log reading, Git/Docker exclusions, visible audits | Existing lifecycle tests retained at that time |
| [README](../README.md), [README.html](../README.html), `READM.html` (since removed), [CLI guide](../docs/INFRASTRUCTURE.md) | Consistent names, exact cap, scheduling, no automatic migration and ZIP limits | HTML regenerated from Markdown |
| [agent guide](../AGENTS.md), [contribution guide](../CONTRIBUTING.md), [scheduler](../AGENT_SCHEDULER.md), [audit index](README.md) | Align runtime naming and record this scope/status | No unrelated agent workflow changes |

## Verification

Use `PASS`, `FAIL`, `NOT RUN` (with reason) or `N/A`; record exact commands.

| Check | Result | Command / evidence |
|---|---|---|
| Original symptom | FAIL as expected, before changes | Node 24 `--test --test-name-pattern 'trash defaults&#124;runtime initialization&#124;trash keeps data at its cap' tests/storage.test.cjs`: all 3 failed on missing cap/hidden initialization |
| Focused storage suite | PASS | Node 24 `--test tests/storage.test.cjs`: 30 passed, 0 failed |
| Lockfile baseline | PASS | Node.js 24.21.0, npm 11.5.2: `npm ci --ignore-scripts` |
| `npm run verify` | PASS | Same runtime: 51 passed, 0 failed, 0 skipped; launcher syntax, 30 storage tests/subtests, 16 lifecycle tests and 5 documentation tests |
| Dependency audit | PASS | `npm ci --ignore-scripts` reported 0 vulnerabilities; no new dependencies |
| Editor diagnostics | PASS | No errors in the launcher, config example or three test files |
| Final documentation and layout | PASS | Node 24 `--test tests/documentation.test.cjs`: 5 passed after audit/index updates; all four dot runtime directories present, task audit not Git-ignored |
| Runtime ignore rules | PASS | `git check-ignore -v -- .trash\ .logs\ .archive\ .moorkyz\ trash\ logs\ archive\` matched every current and legacy path |
| `git diff --check` | N/A | Entire worktree is untracked; a tracked diff cannot validate task-owned changes against a baseline |
| Existing-data cleanup | NOT RUN, intentionally | All cleanup, cap and archival regressions used disposable temporary directories; no real project maintenance was run |

## Review

- Secrets and security: no credentials, packages, external services or deployment
  settings were introduced. Targeted common private-key, GitHub-token and AWS-key
  pattern checks of the modified runtime, config, tests, root/storage guides,
  generated HTML, ignore files and audit files found no matches. This is a
  limited self-check, not an independent security review.
- Docs and user-guide impact: guides distinguish ignored local runtime folders
  from tracked audit history. A dot prefix neither sets Windows' Hidden attribute
  nor automatically excludes data from Git. Legacy visible folders are not used
  for new maintenance, but saved legacy logs are still readable.
- Residual risks: arbitrary external writes can temporarily exceed the cap.
  Checks occur before managed starts, every 30 seconds while a managed service
  runs, or on explicit/API maintenance. With all services stopped there is no
  independent watcher. Stop writers before archival and serialize library calls.
- The existing classic ZIP limit is under 4 GiB per file/batch and 65534 entries.
  Oversized overflow cannot be reclaimed automatically: maintenance reports the
  error and preserves sources. Tests cover this limitation and compression failure
  without allocating huge files. Large data must be split into supported operations.
- Linux/macOS and remote CI were not executed locally. Existing CI remains the
  cross-platform gate.
- Commit blocker: adding the pre-existing untracked runtime/docs/tests would
  include unrelated baseline work. No safe focused commit can be created without
  first establishing or approving that baseline. Nothing was staged or pushed.

## Completion

- Commit: none; blocked by the untracked, unborn baseline described above
- Human review: pending
- External actions: none unless separately approved

A generated draft is not verification evidence and a self-audit is not an
independent security review.
