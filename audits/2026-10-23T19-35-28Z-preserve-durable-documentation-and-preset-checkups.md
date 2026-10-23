# Preserve durable documentation and preset checkups

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T19-35-28Z-preserve-durable-documentation-and-preset-checkups` |
| Created (UTC) | 2026-10-23T19:35:28.558Z |
| Auditor | AI assistant using Copilot SDK in VS Code; self-audit |
| Baseline commit | None: unborn `master`, existing baseline wholly untracked, no staged files |
| Outcome | `PASS WITH RISKS`; implementation verified, focused commit blocked by unborn baseline |

## Request and outcome

- Requested: preserve durable documentation and preset verification after removal
  of the example test suite. Cover exact-case links across Markdown/HTML including
  audits and agent/setup docs, current script names, icon/CI references, preset
  JSON/ESM validity and all nine opt-in selections through PowerShell and CMD.
  Preserve preview/apply/rerun/failure behavior, source bytes and existing files.
- Implemented: extended documentation safeguards and a third maintenance checkup
  for preset configuration and selector behavior. Selector actions execute only
  copies in newly created disposable directories, never the live repository.
  `-DryRun` returns before validation, fixture creation or child execution.
- Preserved existing fixes: first-match Node lookup, exact-case per-component path
  enumeration, generated HTML, the relocated optional manifest under
  `.projecttypes/types/node/`, maintenance package scripts and updated audit-template
  verification row. No source starter was removed, no dependencies were added,
  and no example tests were restored.
- Preserved unrelated work: all nine presets, CMD forwarding, two-column selector
  rendering, portable agent template consolidation and root-guide improvements.
  Historical 107/107 results remain historical, not claimed as current coverage.
- Exclusions: no application/package execution, real setup, storage cleanup,
  downloads or changes to existing runtime data. The former lifecycle/storage
  action suite remains retired. The old "only root script" filename-list invariant
  is not restored because selecting configuration presets intentionally adds root
  `.mjs` files; the CLI's self-contained-helper safeguard is retained instead.

## Changes

| Path | Change | Risk |
|---|---|---|
| [02-documentation.ps1](../.template/maintenance/helpers/checkups/02-documentation.ps1) | Retain exact-case all-document links and README freshness; add current script names, icon/CI references, duplicate-edition rejection, portable CLI/ignore boundaries, private reporting and renderer escaping assertions | Read-only; no modules or actions executed beyond the existing pure README renderer |
| [03-project-types.ps1](../.template/maintenance/helpers/checkups/03-project-types.ps1) | Durable JSON/ESM syntax and manifest checks; every preset individually and combined, preview/apply/rerun and failure cases on available PowerShell hosts and Windows CMD | Real selector actions restricted to owned disposable copies; rejects source links; cleans fixtures in `finally` |
| [maintenance guide](../.template/maintenance/README.md), [README Markdown](../README.md), [README HTML](../README.html), [CLI guide](../docs/INFRASTRUCTURE.md), [audit index](README.md) | Explain expanded coverage and the disposable-fixture boundary without replacing unrelated guide content | Explicitly distinguish from retired lifecycle/storage coverage |
| [scheduler](../AGENT_SCHEDULER.md), this audit | Follow-up ownership, actual results, review status and baseline blocker | No unrelated queue claims changed |

## Verification

All successful runtime checks used already-cached Node.js **24.21.0** prepended
to PATH. No package/runtime was installed. `<session-files>` denotes disposable
verification probes outside the repository; they were removed after validation
and their source/results remain in the tool transcript.

| Check | Result | Command / evidence |
|---|---|---|
| Complete runner, PowerShell 7 | PASS | `pwsh -NoProfile -File .\maintenance\RunCheckups.ps1 -NoPause`; 3/3 checkups; measured 11 runnable sources and 20 CLI safe-mode commands |
| Complete runner, Windows PowerShell 5.1 | PASS | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\maintenance\RunCheckups.ps1 -NoPause`; 3/3 checkups |
| Durable preset behavior | PASS | Both full runs exercised nine individual selections plus combined preview/apply/rerun, unknown/traversal rejection and differing-file preflight through pwsh, powershell.exe and CMD: 45 selector invocations per project-type checkup |
| Source/user-file preservation | PASS | SHA-256 and path snapshots compare source payloads, selected copies and user sentinels; preview, rerun and failed selections leave fixtures unchanged; actual copies match the complete selected file/directory shape, including rejecting unselected empty directories |
| Fault/safety probes | PASS | `node --test "<session-files>\checkup-coverage-verification.cjs"`; final 18/18 passed, zero skipped |
| Exact output-shape probe | PASS | `node "<session-files>\verify-preset-output-shape.cjs"`; injecting an otherwise-working selector that adds an unselected empty directory fails explicitly, retains original source bytes and cleans all fixtures |
| Fault cases | PASS | Wrong filename/icon/CI pin case; broken audit/hidden agent/Copilot links; retired names; stale CI/Node test commands; invalid JSON, dependency declarations and ESM; a false-success selector; linked preset root |
| No-op and cleanup probes | PASS | Both hosts' documentation checks preserve all copied source/runtime sentinels; `03 -DryRun` creates no fixtures; redirected child TEMP/TMP directories are empty after successful and failing probes |
| ESM/config boundary | PASS | JSON objects parsed without execution; ESM files checked by `node --check`, not imported; Node/tooling presets remain dependency-free/configuration-only |
| README edition | PASS | `node moorkyz readme`; both full runs subsequently confirmed exact Markdown/HTML freshness |
| Actual untracked-file whitespace | PASS | `git -c core.safecrlf=false --no-pager diff --no-index --check -- NUL <file>` for each of eight task-related source/doc/ledger files and the completed audit |
| Tracked whitespace/index | PASS, limited | `git --no-pager diff --check`; empty tracked baseline means actual untracked files were checked separately; `git --no-pager diff --cached --stat` empty |
| Dependency restore/audit | N/A | No root manifest/lockfile and no new dependencies; do not fabricate an npm install or package audit |
| Linux execution | NOT RUN | Local OS is Windows. Existing Linux/Windows CI matrix invokes the runner; Linux checks available PowerShell hosts and explicitly skips CMD |

## Review

- Secret review: focused review and private-key/GitHub-token/AWS-key pattern scan
  of maintenance sources found no credentials. New fixture content consists of
  template payloads and synthetic user-file sentinels, not existing runtime data.
- Safety: normal source validation is read-only. All selector executions receive
  paths inside the fresh temporary workspace and never target the live selector.
  Cleanup removes only the exact workspace created by `mkdtempSync`, in `finally`.
  No storage-maintenance or package commands run.
- Error handling: native child error/signal/nonzero statuses and assertion failures
  propagate to the runner; timeouts fail rather than silently pass. Optional
  unavailable extra PowerShell hosts are logged as SKIP; CMD is explicitly skipped
  outside Windows. Windows validation exercised both hosts and CMD.
- Input boundaries: reject linked preset roots/files before copying or selector
  actions; preset names must match the selector's safe-name format; encoded
  PowerShell command invocation preserves spaced fixture paths for the batch
  wrapper. Invalid dependency declarations fail explicitly rather than receiving
  an empty-object success fallback.
- Trust limits: checkups and copied selectors are trusted code, not a sandbox.
  Parsing config syntax does not prove compatibility with separately installed
  tool versions, and this does not restore lifecycle/storage behavioral coverage.
- Review found and addressed linked-root traversal and invalid dependency-object
  acceptance in the new checkup, and tightened output assertions to compare
  directories as well as file bytes. The 18-case suite, focused output-shape
  regression and both final full runner invocations passed. No remaining
  task-caused failures were observed.
- Human review remains pending. No independent agent/security review was requested.
- Commit blocker: shared files have no tracked baseline, so an isolated commit
  cannot represent the task without absorbing unrelated owners' untracked work.

## Completion

- Commit: `BLOCKED` by unborn/untracked baseline; nothing staged or committed.
- Human review: pending.
- External actions: none; no push, PR, deployment, network requests or installs.

A generated draft is not verification evidence and a self-audit is not an
independent security review.
