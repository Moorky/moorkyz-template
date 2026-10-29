# Complete template guidance and reusable templates

| Field | Value |
|---|---|
| Audit ID | `2026-10-29T00-47-54Z-complete-template-guidance-and-reusable-templates` |
| Created (UTC) | 2026-10-29T00:47:54.698Z |
| Auditor | Copilot SDK session f70a1d9e-0d14-4d9a-94b6-fa8a875a5c54 (AI assistant using Copilot SDK in VS Code); self-audit |
| Baseline commit | `8552c372519b505dc1f1079b48109c567118d8cd` |
| Outcome | `PASS WITH RISKS`: local and CI-simulated checks pass; GitHub rendering, container checks and human review need an approved push or the owner |

## Request and outcome

- Requested behavior and confirmed decisions: REQ-TEMPLATE-READY-032. After the read-only purpose discovery, the owner asked (2026-10-29T00:01Z): "Are you done with the whole template, everything that needs to be known for an agent and normal worker to work to their max? Also some Design Templates or other Templates as this is also a template repo", tagging `TEMPLATE_INTRODUCTION.md`. With the owner unavailable (autopilot), this was interpreted as finishing the template's working knowledge and template library without redesigning its architecture. It also answers the discovery's main open question: the design collection belongs to the template, because this is also a template repository.
- Implemented behavior:
  1. Template library additions: GitHub bug report and change request issue forms, an issue chooser that requires a form and links private vulnerability reporting, a pull request template, and task-brief, design and decision-record document templates. `02-documentation.ps1` checks the issue forms' required keys, unique field ids and the chooser's reporting link.
  2. The owner-tagged guide (TEMPLATE-INTRO-020, taken over by owner direction) now has role-based start paths for everyone, developers and AI agents, a common-tasks table, generated files and their sources, a template library (design, documentation/collaboration, configuration/workflow), an updated root map, corrected adoption guidance, the script-icon tool, a template-website section, current design assets, all eight checkups, ten deliberate decisions with their evidence, and twelve known pitfalls. It is tracked for the first time.
  3. Entry points: README (summary, start pointer, placeholder note, corrected claim-tool advice and a Template library chapter), AGENTS.md (complete tool list and the guide pointer), CONTRIBUTING.md (forms and templates), the Copilot pointer, the claim-tool guide and the maintenance guide.
  4. Regenerated `README.html`, the twenty README editions and the search index.
- Initial Git state and unrelated work preserved: `HEAD` `8552c37` (this session's two earlier commits on `297a932` = `origin/master`). The idle viewer session's uncommitted edits to six `designs/` files, the publication session's audit and scheduler rows, and `.vscode/settings.json` were neither changed nor staged; the six design files were hash-checked before and after regeneration.
- Intentional exclusions: no new design directions (twenty exist; the request is met by documenting them as templates and adding a design-document template); no interactive project-type prompt in `CreateProject.ps1` (the shipped placeholder text is documented instead, see the open question below); no change to template-only areas or audit history; no push or deployment.

## Analyzing and Reading

- Guides, affected source/consumers, documentation and tests read: AGENTS.md, AGENT_SCHEDULER.md, CONTRIBUTING.md, README.md, SECURITY.md, `docs/`, `.audits/README.md`, every tool README and entrypoint parameter block, all eight checkups, `moorkyz` (help, exports, defaults, limits, state paths), `designs/build.mjs`, `website/deploy/build.mjs`, both workflows, the unfilled introduction draft and its empty audit, and the sibling Moorkyz repositories (none has issue or pull request templates to align with).
- Acceptance criteria and edge cases: (1) one tracked, current guide that answers what a developer and an agent need first, which tool to use for which task, what each template is and how to use it, what is generated, which decisions must be preserved and which pitfalls exist; (2) useful collaboration and document templates that link the canonical rules instead of duplicating them; (3) every statement checked against the current files; (4) entry points link the guide; (5) all checks pass on the exact staged tree, including GitHub's Windows short-path environment.
- Scope, constraints and preserved unrelated work: as listed above.

## Researching and Planning

- Existing helpers/tools and authoritative sources checked: GitHub Docs "Syntax for issue forms" and "Configuring issue templates for your repository" (fetched 2026-10-29) for required keys, field types, `blank_issues_enabled` and `contact_links`. The forms were parsed with the existing local `js-yaml` 4.3.2 from the sibling site repository's `node_modules` (read-only; nothing installed).
- Chosen approach: put new document templates directly in `docs/` beside `AUDIT_TEMPLATE.md`, and GitHub templates in their platform-required locations. The pull request template, forms and brief refer to `CONTRIBUTING.md` and `AGENTS.md` instead of restating rules; the change request form mirrors the task brief's sections. The structural check is skipped when an adopted project deletes the issue template folder.
- Evidence behind corrected guidance: in a disposable `git archive HEAD` copy, removing only `.template/claim-template` (as README and the claim guide used to suggest) made `02-documentation.ps1` fail with 261 broken-link findings (retained audits, tool catalog, project-type guide, README editions). The guides now say to keep it, or remove an area together with every reference. The shipped `setup.config.json` `projectTypes` text `selected at CreateProject.ps1` is rejected by validation, which is now documented.
- Assumptions, dependencies and required approvals: no dependency; no external action.

## Developing

| Path | Change | Risk |
|---|---|---|
| `.github/ISSUE_TEMPLATE/bug_report.yml`, `change_request.yml`, `config.yml` | New issue forms and chooser; private reporting link rewritten on adoption with `SECURITY.md` | Low; GitHub-only behavior |
| `.github/pull_request_template.md` | New: summary, scope, verification table, evidence/approvals, checklist | Low |
| `docs/TASK_BRIEF_TEMPLATE.md`, `docs/DESIGN_TEMPLATE.md`, `docs/DECISION_TEMPLATE.md` | New document templates | Low |
| `.template/maintenance/helpers/checkups/02-documentation.ps1` | Issue-form structure and reporting-link check | Low; skipped when the folder is absent |
| `TEMPLATE_INTRODUCTION.md` | Completed, corrected and tracked guide | Low; documentation |
| `README.md`, `README.html`, `designs/*/README.html`, `designs/assets/search-index.js` | Entry-point text, Template library chapter; regenerated outputs | Low; generated by existing tools |
| `AGENTS.md`, `CONTRIBUTING.md`, `.github/copilot-instructions.md`, `.template/claim-template/README.md`, `.template/maintenance/README.md` | Pointers, complete tool list, corrected claim-tool advice and checkup descriptions | Low |
| `AGENT_SCHEDULER.md`, two audits | This request's rows and evidence | Low |

## Clean Up

### Verification

Node.js `v24.22.0` was first on `PATH`; PowerShell `7.6.9` ran the runner, and the checkups also exercised Windows PowerShell 5.1. Unless noted, checks ran on a `git checkout-index -a` export of the exact staged tree, so other sessions' uncommitted files were excluded.

| Check | Result | Command / evidence |
|---|---|---|
| Issue forms against GitHub's documented schema | PASS | One-off parse with `js-yaml` 4.3.2: both forms have `name`, `description`, `body`, valid field types and labels, and unique ids; the chooser disables blank issues and has one contact link |
| Full maintenance, normal `TEMP` | PASS | `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause` on the export (195 files): 8 passed, 0 failed, including "2 issue forms have required keys and unique ids; the chooser points to private vulnerability reporting" and "9 complete chapters per README" |
| Full maintenance, GitHub-style short `TEMP` | PASS on rerun | First run with `TEMP`/`TMP` set to an 8.3 alias: 7 passed, 1 failed (`04-copilot-setup.ps1`; its log was deleted by this session's cleanup before it was inspected). In the same short-path setup, two separate runs of that checkup and a full rerun all passed (8/8). This task changes neither the checkup nor the Copilot tool. The cause is unexplained; it may be transient, since each setup call has a 30-second spawn limit and this was the second back-to-back full run |
| Catalog and viewer | PASS | `node website/verify.mjs` on the export: fresh catalog (20 designs, 40 templates, 48 local links, 18 filter combinations), fresh viewer and keyboard navigation |
| Website packaging tests | PASS | `node --test --test-reporter=tap website/deploy/build.test.mjs`: 3 tests, 2 pass, 0 fail, 1 Windows symlink-privilege skip covered by Linux CI |
| Website packaging of the staged tree (Docker build-stage Node step) | PASS | `node website/deploy/build.mjs` on the export with a 40-character test `SOURCE_COMMIT`: 56 public files, 923 repository links rewritten to GitHub; all 20 README editions link the new guide there. The output was removed |
| Generated outputs | PASS | `node moorkyz readme` and `node designs/build.mjs` regenerated `README.html`, twenty README editions and the search index; `node designs/build.mjs --check` passes in the working tree and inside `06-design-collection.ps1` on the staged tree. The six foreign `designs/` files kept identical hashes |
| Production container build and HTTP verification | NOT RUN | The Docker Desktop engine was not running and this session did not start it; the Template website workflow runs these after an approved push |
| GitHub rendering of the forms and pull request template | NOT RUN | Needs a push, which requires owner approval |
| Visual review of the new README chapter | NOT RUN | The integrated browser tool was unavailable in this session; chapter structure and links are covered by `designs/verify.mjs` |
| Dependency audit | N/A | No dependency, manifest or lockfile changed |
| `git diff --cached --check` | PASS | Exit 0 |

### Quality and safety review

- Correctness, best practices, redundancy/dead code and unnecessary complexity: the templates are short and point to the canonical guides instead of copying their rules. The guide adds orientation that did not exist (roles, tasks, generated outputs, decisions, pitfalls) and keeps the detailed contracts in the tool READMEs. The new check is a few assertions with a clear message.
- Compatibility, error handling and coverage: forms use only documented keys. The check tolerates a project without issue forms and validates whichever forms exist. README rendering limits (tables and lists as text) are unchanged; the new README chapter uses prose so it renders cleanly in `README.html` and the editions.
- Secrets and security: no credentials, personal data or live settings. The chooser and bug form steer vulnerability reports to private reporting; the forms require confirming that secrets, personal data and private paths were removed.
- Self-reviewer, scope and findings: this session reviewed the complete staged diff and corrected its own findings before committing (wrapped list lines, an outdated asset list and missing checkup coverage).
- Independent review and required approvals: not requested; human review pending.
- Findings, residual risks and blockers: see the open questions in Completion.

### Final references and documentation

| Reference / content | Availability / validity | Command / source / evidence and impact |
|---|---|---|
| Changed code references, consumers, paths/casing, assets, commands and configuration | PASS | Every command and option cited in the guide was compared with the tool parameter blocks, `moorkyz help`, `designs/build.mjs`, both workflows and `website/deploy/build.mjs`; links are covered by `02-documentation.ps1` and the design checks |
| Supported APIs/dependencies and local links/anchors | PASS | Exact-case local link checks across Markdown and HTML, including retained audits and README editions |
| Changed external references and version-specific claims | PASS | GitHub Docs pages for issue forms and template configuration fetched 2026-10-29; no new external links were added to the repository |

- Unreachable or unverifiable content, impact and required follow-up: GitHub rendering and the container workflow need an approved push.
- Docs, examples, generated outputs and queue evidence updated: yes, see Developing; REQ-TEMPLATE-READY-032 and REQ-TEMPLATE-INTRO-020 ledger rows updated and both queue items removed.
- Task-created temporary files removed (existing data preserved): exports, short-path directories, logs and packaging output were removed; the session-local staging helper lives outside the repository.
- Final affected tests, quality and reference checks repeated after updates: yes, on the exact staged tree.

### Completion

- Commit: focused local commit; the hash is reported in the session completion.
- Staged diff and `git diff --cached --check`: reviewed; PASS.
- Human review: pending
- Required checks/approvals and completion or handoff status: required local checks PASS; TEMPLATE-READY-032 and TEMPLATE-INTRO-020 completed. Open owner questions: (1) should `CreateProject.ps1` prompt for project types, as the shipped placeholder text suggests, or should the placeholder become `[]`? (2) should adopted projects inherit the template's audit history, which links to template-only areas? (3) push approval, which would let GitHub confirm the Windows CI fix, the issue forms and the website workflow. Stale foreign claims (TEMPLATE-VIEWER-025, TEMPLATE-DEPLOY-026, REPO-PUBLISH-031) were left untouched.
- External actions: none

A generated draft is not verification evidence and a self-audit is not an
independent security review.