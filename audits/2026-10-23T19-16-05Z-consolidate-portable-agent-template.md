# Consolidate portable agent template

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T19-16-05Z-consolidate-portable-agent-template` |
| Created (UTC) | 2026-10-23T19:16:05.810Z |
| Auditor | Copilot SDK in VS Code, session e8efba40-e5dd-47c9-8b13-4bb454921d80; self-audit |
| Baseline commit | Unborn `master`; the entire existing baseline is untracked |
| Outcome | `PASS WITH RISKS`: implementation verified; focused commit blocked by the uncommitted shared baseline |

## Request and outcome

- Requested behavior: compare the supplied agent template with the current guide,
  retain useful improvements in a reusable template, adjust the current guide,
  then delete the obsolete parent folder. After an initial coordination wait, the
  owner explicitly directed continuing autonomously.
- Comparison: the root guide already had stronger repository-specific workflow,
  instruction precedence, approval gates and audits. The supplied template added
  explicit evidence honesty, protection against credentials in logs/MCP config,
  public-API preservation and actionable blocker reporting. Retained those rules
  in the root guide without replacing its existing contract.
- Moved and improved the portable template beside its existing setup consumer.
  It now also carries the root guide's useful stack-neutral, instruction-trust,
  installed-version and unrelated-work protections, without assuming Moorkyz
  scripts, a scheduler or a particular application stack.
- Initial Git state: no commits, all baseline files untracked, index empty.
  Preserved concurrent maintenance/checkup, preset, selector, reference and
  documentation work. Narrow shared-document edits only; no files staged.
- Exclusions: no new framework, dependencies, MCP installation, deployment,
  settings migration, test-suite recreation or cleanup of existing runtime data.

## Changes

| Path | Change | Risk |
|---|---|---|
| [AGENTS.md](../AGENTS.md) | Explicit evidence honesty, secret/log protection, API preservation and blocker reporting; preserves the maintenance owner's verification command | Guidance only |
| [AGENTS.template.md](../.scripts/copilot/helpers/AGENTS.template.md) | Move the former single-file setup template into the location already consumed by setup; preserve portable rules and add useful root-guide protections | New projects only; existing guides are not replaced |
| [Setup-CopilotProject.ps1](../.scripts/copilot/Setup-CopilotProject.ps1) | Wrap MCP property enumeration in `@(...)` before counting, fixing the next default-setup failure exposed by action testing | Empty, single-server and multiple-server cases tested |
| [.github/copilot/README.md](../.scripts/copilot/README.md) | Correct repository-root quick start; explain portable template, project context and existing-guide preservation | Documentation only |
| [README.md](../README.md), [README.html](../README.html) | Add the setup/template links and regenerate the HTML edition without replacing other owners' content | Generated HTML follows current Markdown |
| [AGENT_SCHEDULER.md](../AGENT_SCHEDULER.md) | Record owner scope, continuation, verification and commit blocker; release implementation claim | Coordination only |
| `moorkyz-copilot-setup/` | Remove the obsolete directory only after moving its sole file and verifying that the resolved directory is regular and empty | No recursive deletion or unrelated data removal |
| This audit | Record comparison, actual verification, self-review and blockers | No secrets or fabricated evidence |

## Verification

Use `PASS`, `FAIL`, `NOT RUN` (with reason) or `N/A`; record exact commands.

| Check | Result | Command / evidence |
|---|---|---|
| Original symptom | PASS (reproduced, then fixed) | Project-only setup in a disposable directory originally exited 1 because adjacent `AGENTS.template.md` was missing. After moving the template, default setup reached and exposed the empty-MCP `Count` failure. Both failures are fixed and final action checks pass. |
| Focused PowerShell 7 action checks | PASS, 7/7 | `pwsh -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File <session-files>\Validate-AgentTemplate.ps1 -Repository <repo> -Engine "C:\Program Files\PowerShell\7\pwsh.exe"` |
| Focused Windows PowerShell 5.1 action checks | PASS, 7/7 | `powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File <session-files>\Validate-AgentTemplate.ps1 -Repository <repo> -Engine "C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe"` |
| Maintenance checkups | PASS, 2/2 | `pwsh -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\maintenance\RunCheckups.ps1 -NoPause`, with Node.js v24.21.0 on PATH; runnable syntax/no-op checks, all local Markdown/HTML links and exact filename casing, README HTML freshness |
| CLI syntax | PASS | Node.js v24.21.0 `node --check .\moorkyz`; also covered by maintenance |
| README generation | PASS | Node.js v24.21.0 `node .\moorkyz readme`; maintenance confirms byte-for-byte freshness |
| `npm ci --ignore-scripts`, `npm run verify`, dependency audit | N/A | No root package manifest or lockfile exists in the stack-neutral baseline. No dependency changes or installation; used the configured maintenance checks instead. |
| Bundled `node --test` suite | N/A | Removed by the separate owner-directed maintenance task; not recreated. Focused action regression checks ran only in disposable fixtures. |
| Whitespace review | PASS, 8/8 task files | `git diff --no-index --check -- NUL <path>` produced no diagnostics for each task file; exit 1 indicates the untracked-file difference, not a whitespace finding. Ordinary `git diff --check` also passed but cannot cover untracked content. |

The seven focused checks cover: template location/obsolete-folder absence/adopted
rules; byte-identical creation; idempotent rerun without redundant backups;
preservation of an existing owner guide; write-free `-WhatIf`; disabled guide
creation plus untouched user settings; and empty/one/two MCP server configurations.
MCP fixtures are configuration only: no servers are started. Every project and
the test `APPDATA` location are disposable and removed in `finally`. The
session-local action-check harness was removed after the final successful runs.

Final focused runs reject both nonzero child exit codes and captured child error
records. During verification, corrected a multiline-text assertion in the
temporary harness and improved Windows PowerShell stderr capture after an
initial failing run; both hosts then passed the complete checks. The ordinary
shell's signed-script policy required the documented process-only
`-ExecutionPolicy Bypass`; no persistent execution policy was changed.

Documentation checks caught stale HTML during concurrent maintenance edits and
a later menu-prose update. Regenerated HTML from the current Markdown without
replacing other owners' prose; the final documentation check verifies freshness.
All Node checks use the existing cached Node.js v24.21.0 executable, not the
default Node.js v22.18.0. No runtime or packages were downloaded.

## Review

- Secrets and security: self-review of the template, added guidance and exact
  script change found no added credentials or secret values. MCP object type
  validation and explicit errors remain intact; array wrapping fixes enumeration,
  not validation policy. No permissions, auto-approval, sandbox or model settings
  changed. No external uploads, server launches or user-settings writes.
- Data safety: checked the exact old directory for reparse-point attributes,
  moved its only file, then refused deletion unless it was empty. Used
  non-recursive deletion for that directory. Existing runtime folders and
  unrelated work were not cleaned or modified.
- Docs and user-guide impact: setup/template links use exact filename casing.
  README Markdown and generated HTML agree. The existing project guide is never
  overwritten or automatically merged by setup.
- Findings and residual risks: the template's project-specific section still
  intentionally needs the adopter's real architecture and checks. Instructions
  guide agent behavior; they are not a security boundary. This self-review is not
  an independent security review. Linux action-level setup was not exercised;
  documented Windows PowerShell 5.1 and PowerShell 7 behavior was exercised.
- Commit blocker: no initial baseline commit exists, and task edits share
  untracked files with other owners' work. Creating an initial commit would
  capture unrelated content. Left everything unstaged; an owner-approved
  baseline is required before a focused task commit can be made safely.

## Completion

- Commit: `BLOCKED` by the unrelated unborn/untracked baseline; no commit created.
- Human review: pending
- External actions: none unless separately approved

A generated draft is not verification evidence and a self-audit is not an
independent security review.
