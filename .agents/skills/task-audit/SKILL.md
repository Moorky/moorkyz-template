---
name: task-audit
description: Write a task audit with phase evidence, tests, quality and security self-review, final reference checks and remaining risks, then prepare the focused local commit. Use after changing repository files and before committing.
---

# Task Audit

Follow [AGENTS.md](../../../AGENTS.md) and the work queue in [AGENT_SCHEDULER.md](../../../AGENT_SCHEDULER.md).
Consult the [template-tool catalog](../../../.template/README.md) when an existing tool
may fit the task; read its README and use it when appropriate, not automatically.

## Analyzing and Reading

Inspect the real task-owned diff, request, acceptance criteria and affected
source, consumers, docs and tests. Exclude unrelated or other agents' changes
from scope and staging; record the initial Git state.

## Researching and Planning

Record the chosen approach, reused tools/helpers, supported-version references,
assumptions, affected outputs, checks and required approvals. Do not invent
research that was not performed.

## Developing

Summarize implemented behavior, related tests/docs, intentional exclusions and
deviations from the plan. Check the result against the acceptance criteria.

## Clean Up

1. Run the applicable checks (`pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause` with Node.js 24 LTS on PATH, plus any product checks). Record exact commands and observed results as `PASS`, `FAIL`, `NOT RUN` (with reason) or `N/A`. Checkups stay read-only; action-level regression checks use disposable fixtures.
2. Review every task-owned change for correctness, project best practices, redundancies/dead code, unnecessary complexity, compatibility, secrets, input validation, dependencies, error handling, data loss and missing tests as relevant. Fix task-caused findings and rerun affected checks. Label self-review honestly; record independent review and human approval separately.
3. Validate final changed code and consumers: imports/exports/symbols, paths/casing, assets, commands, configuration, supported APIs/dependencies and referenced content. Check local links/anchors and changed external references against authoritative sources; record unreachable/unverifiable content and its impact rather than claiming availability.
4. Synchronize affected docs, examples, generated outputs and queue evidence. Remove only task-created temporary files. Repeat affected tests, quality review and reference checks after corrections or regeneration so evidence covers the final state.
5. Create the report with `node moorkyz audit "task title"` (written to `.audits/` from `docs/AUDIT_TEMPLATE.md`) and fill it with real phase evidence, exact results, review findings, reference availability, remaining risks and approval status.
6. If a required check or approval is missing, fix it or report the blocker; never record a successful completion. Optional unrequested review is not approval.
7. When required gates pass, stage only the task's files and its audit, review the staged diff and `git diff --cached --check`, commit locally and report the hash. Record completion or handoff in the queue. Never push, merge or deploy without approval.

A self-audit is not an independent security review.
