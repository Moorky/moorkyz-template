---
name: task-audit
description: Write a task audit with real verification evidence, a security review and remaining risks, then prepare the focused local commit. Use after changing repository files and before committing.
---

# Task Audit

Follow [AGENTS.md](../../../AGENTS.md) and the work queue in [AGENT_SCHEDULER.md](../../../AGENT_SCHEDULER.md).
Consult the [template-tool catalog](../../../.template/README.md) when an existing tool
may fit the task; read its README and use it when appropriate, not automatically.

1. Inspect the real diff. Exclude unrelated or other agents' changes from scope and staging.
2. Check the result against the request, acceptance criteria and affected docs and tests.
3. Run the applicable checks (`pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause` with Node.js 24 LTS on PATH, plus any product checks). Record exact commands and observed results as `PASS`, `FAIL`, `NOT RUN` (with reason) or `N/A`. Checkups stay read-only; action-level regression checks use disposable fixtures.
4. Review secrets, input validation, dependencies, error handling, data loss and missing tests as relevant.
5. Create the report with `node moorkyz audit "task title"` (written to `audits/` from `docs/audits/AUDIT-TEMPLATE.md`) and fill it with real evidence, findings and remaining risks.
6. If a required check fails because of the task, fix it or report the blocker; never record a successful completion.
7. When checks pass, stage only the task's files and its audit, review the staged diff, commit locally and report the hash. Never push, merge or deploy without approval.

A self-audit is not an independent security review.
