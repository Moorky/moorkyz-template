# Fix adoption cleanup under WhatIf before v1.0.0

| Field | Value |
|---|---|
| Audit ID | `2026-10-29T10-16-10Z-fix-adoption-cleanup-under-whatif-before-v1-0-0` |
| Created (UTC) | 2026-10-29T10:16:10Z |
| Auditor | Copilot SDK session f70a1d9e-0d14-4d9a-94b6-fa8a875a5c54 (AI assistant using Copilot SDK in VS Code); self-audit |
| Baseline commit | `36e199dca42703aa2deb413a9ba9c0943dcd6bf7` (= `origin/master`, release candidate, CI green) |
| Outcome | `PASS` |

## Request and outcome

- Requested behavior and confirmed decisions: part of REQ-TEMPLATE-RELEASE-035 ([release audit](2026-10-29T09-39-12Z-release-v1-0-0-one-step-run-and-verified-provenance.md)). Before tagging v1.0.0, every release check must pass and nothing may silently produce wrong results. The release candidate was pushed; the tag waits for this fix.
- Implemented behavior:
  1. `CreateProject.ps1 -WhatIf` left its temporary template history (a bare clone in TEMP) behind. In a `SupportsShouldProcess` script, `-WhatIf` also reached the internal cleanup `Remove-Item`, which only pretended to delete. The three cleanups now pass `-WhatIf:$false`.
  2. `Run.ps1` sets `$WhatIfPreference = $false`. Called from `CreateProject.ps1 -WhatIf`, a runtime download's `Move-Item` and staging cleanup would otherwise have been simulated, breaking the installation.
  3. `09-template-integrity.ps1` gives adoption processes a dedicated TEMP and fails if any `moorkyz-template-*` history remains, including after `-WhatIf` runs.
  4. The checkup's archive-stamp test accepted only the `$Format:%H$` placeholder, so maintenance would have failed in every GitHub ZIP download of the template, where the stamp holds the commit. It now accepts the placeholder or a 40-character commit.
- Initial Git state and unrelated work preserved: as in the release audit; other sessions' staged entries were neither committed nor unstaged, and this commit was built in a temporary index.
- Intentional exclusions: none.

## Analyzing and Reading

- Guides, affected source/consumers, documentation and tests read: `CreateProject.ps1` and `Run.ps1` (every `ShouldProcess` cmdlet reachable before the `-WhatIf` early return), checkup 09.
- Acceptance criteria and edge cases: no temporary files after any adoption mode; runtime provisioning works when called during `-WhatIf`; checkups pass in Git checkouts and in archive downloads.

## Researching and Planning

- Existing helpers/tools and authoritative, version-specific sources checked: PowerShell's `$WhatIfPreference` propagates to cmdlets in the script and to scripts it calls; `-WhatIf:$false` overrides it per call.
- Chosen approach, affected outputs and verification plan: opt internal housekeeping out of `-WhatIf` instead of restructuring. Prove the regression check fails on the release candidate and passes on the fix, then repeat the release gate.
- Assumptions, dependencies and required approvals: as in the release audit.

## Developing

| Path | Change | Risk |
|---|---|---|
| `.template/claim-template/CreateProject.ps1` | `-WhatIf:$false` on the three temporary-history cleanups | Low |
| `.template/run/Run.ps1` | `$WhatIfPreference = $false` | Low |
| `.template/maintenance/helpers/checkups/09-template-integrity.ps1` | Dedicated TEMP, leftover assertion, archive-stamp acceptance | Low |
| `AGENT_SCHEDULER.md`, this audit | Evidence | Low |

## Clean Up

### Verification

| Check | Result | Command / evidence |
|---|---|---|
| Regression proof | PASS | The new checkup on an export of `36e199d` failed with "Claim Template must remove its temporary template history, also after -WhatIf."; on the fix it passed 11 groups with no leftovers in TEMP |
| Archive-style tree | PASS | A `git archive` export (stamp filled with `36e199d…`) passed the release-metadata group |
| Maintenance, PowerShell 7 host, 8.3 short TEMP, final tree | PASS | 10 passed, 0 failed |
| Maintenance, Windows PowerShell 5.1 host, 112-character TEMP, final tree | PASS | 10 passed, 0 failed |
| `git diff --cached --check` | PASS | On the temporary index |
| Dependency audit | N/A | No dependency changes |
| Final-state rechecks after corrections/regeneration | PASS | Both maintenance runs used the final commit tree |

### Quality and safety review

- Correctness, best practices, redundancy/dead code and unnecessary complexity: the changes are minimal; `-WhatIf` keeps previewing every user-visible change.
- Compatibility, error handling and coverage: Windows PowerShell 5.1 and PowerShell 7; the new assertion covers both adoption hosts.
- Secrets and security: none affected.
- Self-reviewer, scope and findings: this session; every `ShouldProcess` cmdlet in both scripts was reviewed. The apply-phase removals run only after the `-WhatIf` early return.
- Independent review and required approvals (name/status; not implied by tests): not requested; human review pending.
- Findings, residual risks and blockers: none beyond the release audit.

### Final references and documentation

| Reference / content | Availability / validity | Command / source / evidence and impact |
|---|---|---|
| Changed code references, consumers, paths/casing, assets, commands and configuration | PASS | Checkup 09 reference scan on the final tree |
| Supported APIs/dependencies and local links/anchors | PASS | PowerShell common parameter `-WhatIf` |
| Changed external references and version-specific claims | N/A | None |

- Unreachable or unverifiable content, impact and required follow-up: none.
- Docs, examples, generated outputs and queue evidence updated: the scheduler; the guides already describe the intended behavior.
- Task-created temporary files removed (existing data preserved): the leaked `moorkyz-template-*` folders and test exports were removed.
- Final affected tests, quality and reference checks repeated after updates: yes.

### Completion

- Commit: focused local commit; the hash is reported in the session completion.
- Staged diff and `git diff --cached --check`: reviewed; PASS.
- Human review: pending
- Required checks/approvals and completion or handoff status: release checks PASS; this commit receives the `v1.0.0` tag once GitHub CI passes.
- External actions: fast-forward push and the `v1.0.0` tag, as in the release audit.

A generated draft is not verification evidence and a self-audit is not an
independent security review.