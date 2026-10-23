# Security policy

## Supported versions

| Version | Supported |
|---|---|
| Default branch and latest release | Yes |
| Older releases and forks | No |

## Reporting a vulnerability

Do not open a public issue, pull request or discussion. Report privately through
[GitHub private vulnerability reporting](https://github.com/Moorky/moorkyz-template/security/advisories/new).
If that form is unavailable, ask the owner for a private channel through their
GitHub profile without sharing any details.

Include:

- affected version, commit or path;
- reproduction steps or proof of concept;
- impact and the conditions required;
- any suggested mitigation and your intended disclosure timeline.

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
