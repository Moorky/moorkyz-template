# Stack-neutral baseline and READM.html removal

Historical report: commands and results describe this task's original state.
See [current names and locations](README.md#current-names-and-locations) for later moves and removals.

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T18-30-00Z-stack-neutral-baseline-and-readm-removal` |
| Created (UTC) | 2026-10-23T18:30:00Z |
| Auditor | AI assistant (Copilot SDK in VS Code); self-audit |
| Baseline commit | None (unborn `master`, entire tree untracked) |
| Outcome | `PASS WITH RISKS` |

## Request and outcome

- Requested: explain `READM.html`; confirm small-number and oldest-first storage tests; decide whether a package manifest and lockfile belong in every project type, keeping the baseline general with stack files in `.optional/`.
- Owner was unavailable for the follow-up choice; chose the option matching the request.
- `READM.html` came from an earlier cross-repository owner request ("Both requested `READM.html` and conventional `README.html`"), most likely a typo, and duplicated `README.html`. Removed from the template only; sibling repositories are unchanged.
- Root `package.json` moved to `.optional/root/package.json` as a Node starter (`moorkyz-project` name). The dependency-free `package-lock.json` was dropped. `.node-version` pins Node 24 for `setup-node` and version managers.
- Initial Git state: the parallel STORAGE-002 changes (dot-prefixed runtime folders, 100 GB trash cap) were finished and preserved.

## Changes

| Path | Change | Risk |
|---|---|---|
| `moorkyz` | `readme` writes only `README.html`; help updated | low |
| `.github/workflows/project-tooling.yml` | `node-version-file: .node-version`; runs `node --check moorkyz` and `node --test`; npm install, cache and empty audit removed | low |
| `.node-version`, `.optional/root/package.json` | New; root `package.json`, `package-lock.json`, `READM.html` archived to `.archive/log_2026-10-23-18-27-34-773.zip` | low |
| `tests/documentation.test.cjs` | No duplicate HTML edition; no root manifest or lockfile; Node pin; optional manifest parses | low |
| `tests/storage.test.cjs` | Cap-2 maintenance test asserts the newest log is kept and the two oldest are archived, with modification times reversed so ordering must come from filenames | low |
| `README.md`, `README.html`, `AGENTS.md`, `CONTRIBUTING.md`, `docs/INFRASTRUCTURE.md`, `docs/dependency-security.md`, `docs/audits/AUDIT-TEMPLATE.md`, `AGENT_SCHEDULER.md` | Commands and stack guidance updated; request recorded | low |

## Verification

| Check | Result | Command / evidence |
|---|---|---|
| `node --check moorkyz` (Node 24.22.0) | PASS | exit 0 |
| `node --test` (Node 24.22.0) | PASS | 52 pass, 0 fail, 0 skipped |
| CLI without root manifest | PASS | `help` works; `doctor` reports `package.json MISSING` |
| `node moorkyz readme` | PASS | Regenerated `README.html` only |
| CI on GitHub | NOT RUN | Not pushed |
| `git diff --check` | N/A | No commit baseline |

## Review

- Secrets and security: no credentials or dependencies added; archived files are recoverable from the verified ZIP.
- Docs: README, CLI guide, contribution and dependency guidance consistent with the stack-neutral baseline.
- Risks: projects adopting Node must copy the optional manifest and add install/audit steps to CI. The system `node` on PATH is 22; verification used a temporary Node 24 runtime. Sibling repositories still carry `READM.html`.

## Completion

- Commit: none; blocked until the owner approves an initial baseline commit
- Human review: pending
- External actions: none
