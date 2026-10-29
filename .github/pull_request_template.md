## Summary

<!-- What changed and why. Link the issue, task brief or queue item. -->

## Scope

- Request or queue item:
- Out of scope and preserved work:

## Verification

Report each check as PASS, FAIL, NOT RUN (with reason) or N/A.

| Check | Result | Command / evidence |
|---|---|---|
| Maintenance (`pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause`, Node.js 24 LTS) | | |
| Product tests, build, lint and type checks | | |
| Generated outputs current (for example `node moorkyz readme`) | | |
| Manual, browser or accessibility review | | |

## Evidence and approvals

- Audit report (`.audits/...`):
- Self-review (correctness, security, secrets, documentation):
- Independent review or human approval still required:
- Remaining risks and follow-ups:

## Checklist

- [ ] Only task-owned changes; no secrets, personal data, logs or runtime data.
- [ ] Documentation, examples and generated outputs are updated.
- [ ] The review checklist in `CONTRIBUTING.md` is satisfied.
- [ ] Deployments, publications and other external actions are separately approved or not part of this change.
