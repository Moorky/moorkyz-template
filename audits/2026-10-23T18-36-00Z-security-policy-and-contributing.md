# Security policy and contributing update

Historical report: the placeholder URL and overlay references below describe this task's original state.
Use the current [security policy](../SECURITY.md) and [project types guide](../.template/project-types/README.md).

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T18-36-00Z-security-policy-and-contributing` |
| Created (UTC) | 2026-10-23T18:36:00Z |
| Auditor | AI assistant (Copilot SDK in VS Code); self-audit |
| Baseline commit | None (unborn `master`, entire tree untracked) |
| Outcome | `PASS` |

## Request and outcome

- Requested: update `CONTRIBUTING.md`; review `SECURITY.md` against best practice.
- Sources: GitHub [security policy](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/add-security-policy), [private vulnerability reporting](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository) and [coordinated disclosure](https://docs.github.com/en/code-security/concepts/vulnerability-reporting-and-management/coordinated-disclosure) guidance.
- `SECURITY.md` now has supported versions, a private channel with a no-details fallback, a report checklist including the reporter's disclosure timeline, good-faith testing rules, honest best-effort expectations (no SLA or bounty), coordinated disclosure through a credited GitHub advisory marked as a security fix, and scope (upstream dependencies, secrets, archives).
- The maintainer step (enable private vulnerability reporting; public repositories only) is in the setup list in `docs/dependency-security.md`.
- `CONTRIBUTING.md` no longer mentions a lockfile; it links the work queue and the stack-neutral root with `overlay/`.

## Verification

| Check | Result | Command / evidence |
|---|---|---|
| Documentation links (now including `SECURITY.md`) | PASS | `node --test tests/documentation.test.cjs` |
| Private reporting form | NOT RUN | `moorkyz-project` placeholder; requires the real repository with the setting enabled |

## Completion

- Commit: none; blocked until the owner approves an initial baseline commit
- Human review: pending
