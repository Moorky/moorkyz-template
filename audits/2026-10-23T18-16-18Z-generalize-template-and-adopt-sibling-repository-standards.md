# Generalize template and adopt sibling repository standards

Historical report: commands, placeholder names and results describe this task's original state.
See [current names and locations](README.md#current-names-and-locations) for later moves and removals.

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T18-16-18Z-generalize-template-and-adopt-sibling-repository-standards` |
| Created (UTC) | 2026-10-23T18:16:18.809Z |
| Auditor | AI assistant (Copilot SDK in VS Code); self-audit |
| Baseline commit | None (unborn `master`, entire tree untracked) |
| Outcome | `PASS WITH RISKS` |

## Request and outcome

- Requested: keep files clean and generic while repositories are mixed; compare shared files with all local `moorkyz-*` repositories, adopt better generic practices, use `moorkyz-project` where a project name is needed, exclude project-specific code, and make every file short and clear.
- Compared `.editorconfig`, `.gitattributes`, `.gitignore`, `.dockerignore`, `AGENTS.md`, `SECURITY.md`, `CONTRIBUTING.md`, `.github/copilot-instructions.md`, Dependabot, CI, dependency docs, audit templates, PR template and Definition of Done across ai, cards, core, evidence, site, the-dot, the-dot-docs, toolbar and video-transcriptor.
- Implemented: Evidence-specific `AGENT_SCHEDULER.md` replaced by a generic serial queue (old copy archived in ignored `archive/`; original remains in moorkyz-evidence). Adopted instruction precedence, execution loop, approval boundaries and PASS/FAIL/NOT RUN/N/A reporting; Copilot pointer file; CONTRIBUTING; private security advisories; structured audit template; CRLF for `.cmd`/`.bat` and binary attributes; broader ignores; Dependabot settings note and PR limit; CI production audit; generic Docker starter requiring an explicit base image. README HTML title now comes from the first heading. Docs condensed; regenerated missing `READM.html`.
- Excluded: stack-specific configs, deployment workflows, Dependabot auto-merge and all product code.

## Changes

| Path | Change | Risk |
|---|---|---|
| `AGENT_SCHEDULER.md`, `AGENTS.md`, `CONTRIBUTING.md`, `SECURITY.md`, `.github/copilot-instructions.md` | Generic agent/contribution/security contracts | low |
| `.editorconfig`, `.gitattributes`, `.gitignore`, `.optional/root/*` | Shared conventions | low |
| `.github/dependabot.yml`, `.github/workflows/project-tooling.yml` | PR limit; `npm audit --omit=dev --audit-level=high` | low |
| `README.md`, `README.html`, `READM.html`, `docs/*.md`, `docs/audits/AUDIT-TEMPLATE.md`, `audits/README.md` | Condensed, consistent docs | low |
| `moorkyz`, `tests/documentation.test.cjs` | HTML title from H1; wider link check | low |
| `public/site.webmanifest` | `moorkyz-project` placeholder names | low |

## Verification

| Check | Result | Command / evidence |
|---|---|---|
| `npm run verify` (Node 22.18.0, npm 11.5.2) | PASS | 40 pass, 0 fail |
| `node --check moorkyz` + `node --test` (Node 24.22.0) | PASS | 40 pass, 0 fail, 0 skipped |
| Dependency audit | PASS | `npm audit --omit=dev --audit-level=high`: 0 vulnerabilities |
| `.gitattributes` patterns | PASS | `git check-attr` reports crlf for `.cmd`/`.bat`, binary for `.ico` |
| `git diff --check` | N/A | No commit baseline |
| CI on GitHub | NOT RUN | Not pushed |

## Review

- Secrets and security: no credentials added; sweep for sibling names, user paths and project terms found none outside historical audit. Security link uses the `moorkyz-project` placeholder.
- Docs: README, CLI guide and both HTML editions consistent; link test now covers all root docs.
- Risks: system `node` on PATH is 22 (engines require 24); Node 24 was run from a temporary runtime. Ignored local `.moorkyz/scripts/initial-setup.cmd`, `SetupSettings.ps1` and `config/` are Evidence task-entry leftovers with a user-specific path; the CLI protects `.moorkyz/`, so they were left for the owner to delete.

## Completion

- Commit: none; baseline is entirely untracked and needs owner review first
- Human review: pending
- External actions: none
