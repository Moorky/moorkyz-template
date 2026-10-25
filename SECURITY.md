# Security policy

## Supported versions

| Version | Supported |
|---|---|
| Current default-branch template | Best-effort fixes |
| Older snapshots, adopted copies and forks | Update or assess in the owning project |

This is a reusable template, not a hosted product or a promise of long-term
support for a versioned application. Adopted projects maintain their own
dependencies, credentials, deployment and security policy. See
[dependency maintenance](docs/dependency-security.md) for update responsibilities.

## Reporting a vulnerability

Do not open a public issue, pull request or discussion. Report privately through
[GitHub private vulnerability reporting](https://github.com/Moorky/moorkyz-template/security/advisories/new).
If that form is unavailable, ask the owner for a private channel through their
GitHub profile without sharing any details.

The private form requires the repository owner to enable
[private vulnerability reporting](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository).
The presence of this policy is not evidence that the remote setting is enabled.
After adopting the template, verify that the reporting link names the new
repository and works before publishing the project.

Include:

- affected version, commit or path;
- reproduction steps or proof of concept;
- impact and the conditions required;
- any suggested mitigation and your intended disclosure timeline.

Do not attach credentials, private repositories, production records or full log
and archive dumps. Use a minimal sanitized reproduction and explain which
information is omitted.

Use only your own accounts and test data. Do not access other people's data,
disrupt services or use social engineering.

## What to expect

- Reports are acknowledged and assessed as soon as possible, on a best-effort basis
  without a guaranteed response time or bug bounty.
- You are kept informed and may be asked to help verify the fix.
- Fixes are released as soon as practical and published as a GitHub security
  advisory, marked as a security fix and crediting you unless you prefer otherwise.
- Please wait for the fix before disclosing publicly.

## Scope

This repository's code, scripts and workflows. Report third-party dependency
vulnerabilities upstream; updates here are tracked through Dependabot.

Never commit secrets, personal data or logs. Deployment credentials belong, with
least privilege, in the protected deployment environment. Local archives are
compressed, not encrypted, and may be pruned; keep confidential data and backups
elsewhere.

## If a credential is exposed

Revoke or rotate it through its provider immediately; deleting the visible file
or adding an ignore rule does not invalidate a secret already shared. Notify
the owner privately, assess where it was used and preserve only sanitized
incident evidence. Coordinate any history cleanup separately; never rewrite
shared Git history or delete another person's data without approval.

## Verification limits

Maintenance checks syntax, documentation and selected safety regressions using
disposable fixtures. It is not a penetration test, dependency audit of an
adopted application, proof of sandbox isolation or verification of a production
deployment. Review new packages, workflows and tool permissions before use.
