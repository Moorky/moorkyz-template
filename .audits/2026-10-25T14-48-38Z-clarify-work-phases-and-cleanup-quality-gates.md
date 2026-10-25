# Clarify work phases and cleanup quality gates

| Field | Value |
|---|---|
| Audit ID | `2026-10-25T14-48-38Z-clarify-work-phases-and-cleanup-quality-gates` |
| Created (UTC) | 2026-10-25T14:48:38.310Z |
| Auditor | Copilot SDK in VS Code; task self-audit, not an independent review |
| Baseline commit | `1c413a3` |
| Outcome | `PASS WITH RISKS` (optional human review pending; unrelated shared work preserved) |

## Request and outcome

- Requested behavior and confirmed decisions: clearly document Analyzing and Reading, Researching and Planning, Developing, then Clean Up; test and review every change, check final references/unavailable content, synchronize documentation, audit and commit. Suggest useful omissions.
- Implemented behavior: the four ordered phases and cleanup gates are consistent across the main agent guide, contributor guide, portable agent template, task-audit skill and audit template. README summaries and generated editions link to the detailed contributor checklist.
- Initial Git state and unrelated work preserved: the scheduler and six design source/output files were already modified; two unrelated audits, editor configuration and the introduction were untracked. These changes are not owned by this request and must not be staged. The index was empty.
- Intentional exclusions: no application code, dependencies, settings, deployment, live data, historical audits or other agents' request states changed. No push or external publication.

## Analyzing and Reading

- Guides, affected source/consumers, documentation and tests read: root agent contract and scheduler, contributor/README/CLI guides, template-tool catalog, maintenance guide, portable agent template and setup guide, task-audit skill, audit template/index, design generator and audit-generation regression assertions. Bounded read-only inspection of GitHub customizations confirmed that the existing pointer should remain unchanged.
- Acceptance criteria and edge cases: each of five detailed workflow documents has exactly one heading for each phase in order; cleanup covers tests, redundancy/quality/safety review, final references, unavailable content, documentation/regeneration, final-state rechecks, audit and commit. Canonical HTML and exactly twenty README editions contain the phase summary and contributor link. Passing tests must not imply human approval.
- Scope, constraints and preserved unrelated work: shared files contain concurrent edits and active claims. The coordination question returned owner unavailable with direction to choose pragmatically; proceed only with disjoint documentation scope and own scheduler hunks, preserving existing claims and history.

## Researching and Planning

- Existing helpers/tools and authoritative, version-specific sources checked: reuse existing README/design generators, audit command and seven maintenance checkups; inspect the installed customization skill reference. Existing commands are exercised by maintenance or actual generation, rather than introducing unfamiliar APIs. No new external references or version-specific claims were introduced.
- Chosen approach, affected outputs and verification plan: retain the main guide as authority, give contributors a detailed checklist, preserve portability in the setup template, and collect matching evidence in the audit template. Regenerate canonical HTML and twenty README editions; verify phase/gate order, generated text, local links, audit generation and all maintenance checks.
- Assumptions, dependencies and required approvals: this is a documentation workflow change, not a new runtime or mandatory independent review. Use an existing task-local Node.js v24.22.0 installation through process-local PATH; the default Node v22.18.0 is not the supported maintenance runtime. No installation, global PATH change or new dependency was needed. Optional human review remains pending.

## Developing

- Implemented behavior and related tests/docs: explicit phase headings, ordered cleanup, acceptance/edge-case evidence, best-practice/redundancy and secret review, final imports/paths/assets/API/content validation, version-aware reference checks, generated-doc updates, temporary-file ownership, rechecks, honest approvals and focused commit/report requirements.
- Deviations from the plan and intentional exclusions: none in repository implementation. The initial one-off semantic check failed because it searched only for "redundan" while the root guide says "duplicated/dead code"; correct the assertion to accept both equivalent terms, then extend it to verify ordered cleanup gates. The corrected check passed; no document change was needed for that harness mismatch. An index-only scheduler patch initially lacked trailing context and was refused; the contextual retry passed, with an assertion proving that only this request's row was staged.

| Path | Change | Risk |
|---|---|---|
| [AGENTS.md](../AGENTS.md), [CONTRIBUTING.md](../CONTRIBUTING.md) | Authoritative and contributor phases, cleanup gates and review checklist | Low; documentation behavior clarified |
| [Portable guide](../.template/copilot-settings/helpers/AGENTS.template.md), [setup guide](../.template/copilot-settings/README.md) | Same portable phases without assuming Moorkyz tools in another project | Low; existing guides are still preserved by setup |
| [Task-audit skill](../.agents/skills/task-audit/SKILL.md), [audit template](../docs/AUDIT_TEMPLATE.md), [audit guide](README.md) | Phase decisions, quality/safety review, reference evidence, approval status and completion fields | Low; draft generation covered by existing action checks |
| [README.md](../README.md), [README.html](../README.html), twenty generated design README editions | Workflow summary and contributor link propagated by existing generators | Low; generated freshness and content verified |
| [Scheduler](../AGENT_SCHEDULER.md), this audit | Record only this request's claim, actual evidence and closure | Shared-file risk mitigated by staging only owned hunks |

## Clean Up

### Verification

Use `PASS`, `FAIL`, `NOT RUN` (with reason) or `N/A`; record exact commands.

| Check | Result | Command / evidence |
|---|---|---|
| Maintenance checkups | PASS | `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause`, with Node v24.22.0 on process-local PATH: 7 passed, 0 failed; PowerShell 7.6.6 runner. |
| Local documentation and generated freshness | PASS | Included `02-documentation.ps1`: all local Markdown/HTML links exist with exact casing; canonical HTML matches Markdown. Design checkup verified twenty README editions, twenty landings, showcase and 1,649 local links/assets. |
| Safe generation and unrelated output preservation | PASS | `node .\moorkyz readme`; generator preflight `node .\designs\build.mjs --check` identified exactly twenty stale README editions and no other stale output; `node .\designs\build.mjs` regenerated them. Buffer comparisons confirmed showcase, search index and all twenty landings unchanged byte-for-byte. |
| Focused workflow assertions | PASS | `node "$env:USERPROFILE\.copilot\session-state\f89305ec-d66f-45f6-a267-d6c119d02d8b\files\verify-workflow.cjs"`: five documents with unique ordered phase headings and required cleanup coverage, ordered gates, skill frontmatter and twenty-one generated HTML summaries/links. Session-only checker removed after final use. |
| Audit command and template compatibility | PASS | `node .\moorkyz audit "Clarify work phases and cleanup quality gates"` created this draft using the updated template; existing storage checkup also exercised audit generation/error behavior in disposable fixtures. |
| Retired contributor/audit heading references | PASS | Repository Markdown/HTML search found no links to the removed contributor headings or renamed audit-template sections. |
| Dependency audit | N/A | No dependency manifests, locks or packages changed; no product dependency audit was invented. |
| `git diff --check` | PASS | Exit 0; an unrelated pre-existing design script emitted a line-ending warning, not a whitespace error. |
| Final-state rechecks after corrections/regeneration | PASS | Repeated the focused checker and `pwsh -NoProfile -File .\.template\maintenance\helpers\checkups\02-documentation.ps1` after regeneration, this audit and the request closure were filled; all passed. Final evidence-only report edits are followed by another documentation/staged whitespace check before commit. |
| Staged scope, whitespace and added-content screening | PASS | Exactly 31 task-owned files staged. An index assertion proves the scheduler differs from HEAD by exactly this request's ledger row. `git diff --cached --check` and high-confidence private-key/access-token pattern screening passed. |

### Quality and safety review

- Correctness, best practices, redundancy/dead code and unnecessary complexity: reviewed the task-owned source diff and generated-change statistics. Detailed contributor guidance is linked from the main guide and summaries; the portable template remains self-contained by design. No new runtime abstraction, dependency or code duplication was introduced.
- Compatibility, error handling and coverage: unchanged runtime behavior. Required failures/approvals block completion; unavailable content must be recorded with impact rather than replaced by invented success. Existing setup and audit disposable regressions passed.
- Secrets and security: documentation-only self-review; no credentials, private recovery data, executable code, dependency changes or new external endpoints added. Existing approval boundaries, disposable-test policy and unrelated-user-data protections retained. Staged added-content screening for high-confidence private-key/access-token patterns passed; this is not an independent security assessment.
- Self-reviewer, scope and findings: Copilot SDK task self-review across owned source changes, generated summaries and final references. No unresolved task-caused implementation finding. The one-off checker wording mismatch was corrected and verified.
- Independent review and required approvals (name/status; not implied by tests): independent review not requested; human review pending. This task does not require a new external action or human sign-off before a local documentation commit. No approval is inferred from passing checks.
- Findings, residual risks and blockers: documentation guides behavior but does not enforce it. Concurrent shared work remains dirty and outside this commit. An optional future improvement is an explicit rollback/recovery plan for high-risk runtime or data changes; none are made here. No current task blocker.

### Final references and documentation

| Reference / content | Availability / validity | Command / source / evidence and impact |
|---|---|---|
| Changed code references, consumers, paths/casing, assets, commands and configuration | PASS / N/A for executable imports | Changed links and command references are exercised by maintenance, generators and the audit command. No executable imports, exports, API calls, configuration values or assets changed. |
| Supported APIs/dependencies and local links/anchors | PASS / N/A for API changes | Local documentation checkup and design verification passed; new contributor anchor exists. Node v24.22.0 and PowerShell 7.6.6 observed, not assumed. |
| Changed external references and version-specific claims | N/A | No external URLs or API-version claims were added/changed; no broader internet-availability claim is made. |

- Unreachable or unverifiable content, impact and required follow-up: none introduced. Existing unrelated external domains/deployment evidence are outside scope and not re-certified.
- Docs, examples, generated outputs and queue evidence updated: the five detailed workflows, three summaries/guides, canonical HTML, twenty generated editions, this audit and own scheduler rows.
- Task-created temporary files removed (existing data preserved): the session-only assertion runner and source review diff were removed after final verification. The staged review diff is removed before commit. Existing runtime/tool caches, other sessions' files and all unrelated edits remain untouched.
- Final affected tests, quality and reference checks repeated after updates: focused phase assertions, local links/generated freshness and staged whitespace/scope checks passed after updates. Final evidence-only report edits receive another documentation/staged whitespace check before commit.

### Completion

- Commit: `PENDING` (report the hash; do not edit this audit afterwards)
- Staged diff and `git diff --cached --check`: PASS; source changes self-reviewed, generated summaries checked, only owned files/ledger row staged and whitespace check passed. Repeat after final evidence-only staging.
- Human review: pending
- Required checks/approvals and completion or handoff status: full maintenance, focused content, final documentation, staging scope, added-content screening and whitespace checks passed. Focused local commit includes only owned changes, this audit and request closure; hash is reported in the completion response. No required external approval is outstanding; optional human review remains pending.
- External actions: none; no push, merge, PR, deployment or publication.

A generated draft is not verification evidence and a self-audit is not an
independent security review.
