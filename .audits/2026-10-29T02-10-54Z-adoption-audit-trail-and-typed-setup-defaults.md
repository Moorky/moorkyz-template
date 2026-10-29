# Adoption audit trail and typed setup defaults

| Field | Value |
|---|---|
| Audit ID | `2026-10-29T02-10-54Z-adoption-audit-trail-and-typed-setup-defaults` |
| Created (UTC) | 2026-10-29T02:10:54Z |
| Auditor | Copilot SDK session f70a1d9e-0d14-4d9a-94b6-fa8a875a5c54 (AI assistant using Copilot SDK in VS Code); self-audit |
| Baseline commit | `43734985a6fcea70991ebac3d6844569e08d0e1c` (three local commits on `origin/master` `297a932`) |
| Outcome | `PASS WITH RISKS` |

## Request and outcome

- Owner decisions (2026-10-29T01:42Z, REQ-TEMPLATE-ADOPTION-034) on the open REQ-TEMPLATE-READY-032 questions: (1) push the three local commits once they pass the existing checks, without force-push, history rewriting or unrelated changes, and only after fixing and validating; (2) ship `"projectTypes": []`, let `CreateProject.ps1` optionally prompt for types (several or none), keep generated configuration valid, never ship placeholder text in a typed configuration field, and keep creation configuration-driven instead of adding a second selection workflow; (3) adopted projects do not inherit audit history: keep template records in the template, start a clean project trail, preserve provenance (source repository, version, commit SHA), retain no references to removed template-only folders and validate all internal links after adoption; (4) leave unrelated stale claims unchanged.
- Implemented behavior:
  1. `setup.config.json` ships `"projectName": ""`, `"displayName": ""`, `"githubOwner": "Moorky"`, `"projectTypes": []` and `"remove": []`. Validation now rejects any non-array list, so placeholder text in a typed field fails with a clear message.
  2. The optional prompt reuses the existing menu: `SetProjectType.ps1 -SelectOnly` shows the same keyboard menu and only returns the confirmed names (none when quit). With no configured types, an interactive `CreateProject.ps1` run (never with `-Yes`, `-WhatIf` or redirected input) offers it; the selection goes through the same `Test-SetupConfig` validation as a hand-written file and is saved to `setup.config.json` only after the plan is confirmed, then re-read and compared.
  3. On the first adoption (no `*-adopted-from-moorkyz-template.md` record yet) `CreateProject.ps1` reads provenance from Git when the clone's `origin` is `Moorky/moorkyz-template` (commit, `git describe --tags` version or `untagged`, commit date, clean/dirty tree) or from `-TemplateCommit <full SHA>`, and refuses to start without it. It points links to template audit records at `https://github.com/Moorky/moorkyz-template/blob/<commit>/...`, resets the request ledger and work queue to their example rows, removes the template's audit records, writes a clean `.audits/README.md` (the template's general guidance plus a provenance section) and an adoption record with repository, version, commit, date, source, types, removals, counts and the link-validation result. Reruns detect the record and leave `.audits/` and the work queue unchanged.
  4. Before any change, a `remove` path is refused while a remaining file links to it or mentions its root-relative path (also with `./`, `../` or backslashes); `.audits` cannot be removed. Owner/name replacement leaves commit-pinned template links intact.
  5. After applying, adoption regenerates `README.html` and the design README editions (previously the five compact editions went stale after the title change), then validates every internal Markdown/HTML link with exact casing; broken links are listed in the record and the run ends with an error until they are fixed. Until a run passes, each rerun writes its result into the adoption record's validation row, so the committed record matches the committed files; a passing record is never changed.
  6. New `09-claim-template.ps1` checkup; the obsolete "adoption preserves .audits history" group and its unused engine argument were removed from `05-storage.ps1`. Guides updated; the work queue's stale sentence about an owner-approved initial commit was removed.
- Initial Git state and unrelated work preserved: `HEAD` `4373498`, three commits ahead of `origin/master` `297a932`. The shared index already contained staged changes this session did not make (six `designs/` viewer files, the publication audit, `.vscode/settings.json` and two other sessions' scheduler rows), staged at 2026-10-29T01:16Z, consistent with an automated `git add -A` checkpoint after the previous turn. They were neither committed nor unstaged: this commit was built in a temporary index.
- Intentional exclusions: no second selection workflow; no change to other sessions' rows, files or staged state; no tags or releases (`untagged` is reported until the owner tags template releases).

## Analyzing and Reading

- Read: the owner decisions, `CreateProject.ps1`, `SetProjectType.ps1`, `setup.config.json`, the claim/project-type/maintenance guides, `05-storage.ps1`, `02-documentation.ps1`, the scheduler, `.audits/README.md` and every file linking to audit records (only `TEMPLATE_INTRODUCTION.md` outside the scheduler and `.audits/`).
- Acceptance criteria: as in the owner decisions above, plus unchanged behavior for `-DryRun`, `-Yes`, `-NoPause`, preset copying, owner replacement and README title; the adopted copy must pass its own documentation check and design freshness check; reruns must be safe.

## Researching and Planning

- Placeholder history: `The Project` appears nowhere else and no owner request asked for it, so both names ship empty (validation already lists empty names).
- Provenance: Git is authoritative for the documented clone flow; copies without template history need an explicit SHA, because GitHub's *Use this template* and archive downloads do not carry the source commit into the working tree. `version` uses tags so it becomes meaningful once releases are tagged.
- Reconciling decision (2): an optional prompt that reuses the one existing menu and persists into the configuration keeps creation configuration-driven without a second workflow.
- Root cause found by the new checkup: returning a property value from a PowerShell function unwraps one-element arrays, so the first type check rejected `["designs"]`; the check now reads the property directly.

## Developing

| Path | Change | Risk |
|---|---|---|
| `.template/claim-template/CreateProject.ps1` | Validation split (`Test-SetupConfig`), typed lists, optional select-only prompt and config writer, provenance, audit-trail initialization, scheduler reset, removed-path pre-check, commit-pinned link protection, design regeneration, link validation, adoption record | Medium: one-time destructive tool; covered by disposable-copy checkup on both hosts |
| `.template/claim-template/helpers/setup.config.json` | Empty names, empty typed lists | Low |
| `.template/project-types/SetProjectType.ps1` | `-SelectOnly` mode and wording | Low; default menu unchanged |
| `.template/maintenance/helpers/checkups/09-claim-template.ps1` | New adoption checkup | Low; disposable copies only |
| `.template/maintenance/helpers/checkups/05-storage.ps1` | Obsolete adoption group and unused engine argument removed | Low |
| `README.md`, `README.html`, `designs/*/README.html`, `designs/assets/search-index.js`, `TEMPLATE_INTRODUCTION.md`, claim/project-type/maintenance guides, `.audits/README.md`, `AGENT_SCHEDULER.md` | Documentation, regenerated outputs, this request's rows, stale sentence | Low |

## Clean Up

### Verification

Node.js `v24.22.0` was first on `PATH`; PowerShell `7.6.9` ran the runner and the checkups also exercised Windows PowerShell 5.1. Unless labelled otherwise, checks ran on a `git checkout-index -a` export of the exact commit tree (a temporary index built from `HEAD` plus the 34 task files), so other sessions' staged and unstaged files were excluded.

| Check | Result | Command / evidence |
|---|---|---|
| Maintenance checkups (`pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause`), normal TEMP | PASS | Runner of the export: "Checkups finished: 9 passed, 0 failed (9 total)", about 240 s |
| Same, GitHub-style 8.3 short TEMP | PASS | `TEMP`/`TMP` = `C:\Users\marvi\AppData\Local\Temp\MZSHOR~1` (expands to 44 characters; the GitHub runner's TEMP expands to 40): 9 passed, 0 failed. A first attempt with an alias expanding to a 97-character folder failed only `08-script-icons.ps1` ("The specified file name or path is too long"); see residual risks |
| Adoption checkup hosted by Windows PowerShell 5.1 | PASS | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\.template\maintenance\helpers\checkups\09-claim-template.ps1`: "PASS: 8 adoption regression groups" (the runner hosts it with PowerShell 7; its clone and menu groups use both hosts either way) |
| Interactive project-type prompt, end to end | PASS | Disposable copies in a hidden console (input not redirected, `UserInteractive` true) on PowerShell 7.6.9 and Windows PowerShell 5.1; `Read-Host` answered `y` twice and a selector stub returned `node, web` for `-SelectOnly` and delegated copying to the real selector. The plan was shown again with `Types: node, web`, the config was saved as `"projectTypes": ["node", "web"]`, both types were copied, the record lists them, links PASS (2186 in 72 files), exit 0, no unanswered prompt; a fresh `-NonInteractive -WhatIf` run accepted the saved config |
| Parse checks | PASS | `[Management.Automation.Language.Parser]::ParseFile` on `CreateProject.ps1`, `SetProjectType.ps1` and `09-claim-template.ps1` in both hosts; the changed scripts are ASCII-only |
| Template website workflow steps | PASS | On the export: `node website/verify.mjs` (catalog, viewer and keyboard PASS); `node --test website/deploy/build.test.mjs`: 2 pass, 1 skipped (the symbolic-link case needs privileges on Windows; Linux CI runs it) |
| Production container build | NOT RUN | The Docker engine is not running locally; the Template website workflow builds and verifies it on GitHub after the push (this change only regenerates design README editions) |
| Development smoke run (before the final edits) | PASS | Disposable Git clone with origin `Moorky/moorkyz-template`: 42 template records not inherited, 44 work-queue rows dropped, 12 evidence links pinned, 2225 links PASS, the copy's own documentation check PASS, a rerun kept a project audit. Superseded by checkup 09 on the final tree |
| Dependency audit | N/A | No dependency, manifest or lockfile changed |
| `git diff --cached --check` | PASS | On the temporary index with exactly the 34 task files (exit 0) |
| Final-state rechecks after corrections/regeneration | PASS | Both maintenance runs were repeated on the export of the final commit tree after the last evidence edit; the other rows ran on identical code (only this audit and the scheduler text changed afterwards) |

### Quality and safety review

- Correctness, best practices, redundancy/dead code and unnecessary complexity: refusals happen before any change; the generated configuration is validated twice; template history is identified only on the first adoption (no adoption record) and reruns never touch `.audits/` or the work queue except to record a not-yet-passing link validation; provenance links survive owner replacement through a negative lookahead for `blob|tree|commit/<40-hex>`. The optional prompt reuses the existing menu, so there is one selection workflow; the obsolete 05 adoption group and its unused engine argument were removed; no dependency was added.
- Compatibility, error handling and coverage: Windows PowerShell 5.1 and PowerShell 7 (native Git stderr handled with a local `Continue` preference); Linux paths through `Join-Path`/`GetFullPath`; exact-case link checks match `02-documentation.ps1`. Checkup 09 covers refusals, both provenance sources, the clean trail, reruns, the menu and the generated configuration; the interactive glue is covered by the smoke runs above.
- Secrets and security: deletes only template audit records on the first adoption (owner decision) and explicitly listed paths; refuses links/junctions in audit records and removal targets; no credentials; provenance contains only public repository data.
- Self-reviewer, scope and findings: this session reviewed the complete task diff (34 files). Fixed: one-element array unwrapping; stale compact README editions after adoption; template-only guidance leaking into the adopted audit README (moved into its own section); an adoption record that kept `FAIL` after the broken links were fixed and the script rerun (reruns now record the result until it passes; covered by checkup 09); a provenance error that blamed the Git origin for copies without Git history.
- Independent review and required approvals: independent review not requested; human review pending. Push approved by the owner on 2026-10-29 (fast-forward only, no force-push, no history rewrite, no unrelated changes).
- Findings, residual risks and blockers: (1) the template version reads `untagged` until template releases are tagged; (2) the removed-path scan is best effort: it finds links and literal root-relative mentions, not computed paths; (3) `-TemplateCommit` is not checked against GitHub, so a wrong SHA yields wrong provenance links (the record marks it as supplied); (4) GitHub *Use this template* copies need `-TemplateCommit`; (5) pre-existing and unchanged: `08-script-icons.ps1` exceeds Windows path limits when TEMP expands to about 97 characters; GitHub's TEMP passes; (6) the container build and GitHub CI run only after the push. No blockers.

### Final references and documentation

| Reference / content | Availability / validity | Command / source / evidence and impact |
|---|---|---|
| Changed code references, consumers, paths/casing, assets, commands and configuration | PASS | `SetProjectType.ps1 -SelectOnly` is the only new interface used by `CreateProject.ps1`; checkups 01, 02 and 09 cover syntax, `-DryRun`, links and the adoption flow |
| Supported APIs/dependencies and local links/anchors | PASS | No dependency added; link checks pass in the repository and in adopted copies |
| Changed external references and version-specific claims | PASS | Only `https://github.com/Moorky/moorkyz-template` and its commit/tree/blob URLs are referenced; no new external services |

- Unreachable or unverifiable content, impact and required follow-up: none in the repository. Adopted copies link to template commits on GitHub; those resolve once the commit is pushed, which the clone flow guarantees.
- Docs, examples, generated outputs and queue evidence updated: README, `README.html`, the 20 design README editions, `TEMPLATE_INTRODUCTION.md`, the claim, project-type and maintenance guides, `.audits/README.md` and the scheduler.
- Task-created temporary files removed (existing data preserved): exports, smoke copies, the temporary index, logs and helper scripts are outside the repository and are removed after the commit; checkup fixtures delete themselves.
- Final affected tests, quality and reference checks repeated after updates: yes; see the verification table.

### Completion

- Commit: focused local commit; the hash is reported in the session completion.
- Staged diff and `git diff --cached --check`: reviewed on the temporary index (exactly the 34 task files; the scheduler blob holds only this request's rows and the stale-sentence removal); PASS.
- Human review: pending
- Required checks/approvals and completion or handoff status: required local checks PASS; push approved; TEMPLATE-ADOPTION-034 completed and its claim released; stale foreign claims (TEMPLATE-VIEWER-025, TEMPLATE-DEPLOY-026, REPO-PUBLISH-031) and other sessions' staged changes untouched.
- External actions: owner-approved fast-forward push of `master` to `origin` after this commit, together with the three earlier local commits; the push and GitHub Actions results are reported in the session completion. No deployment, release, pull request or credential change.

A generated draft is not verification evidence and a self-audit is not an
independent security review.
