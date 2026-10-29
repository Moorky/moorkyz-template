# Release v1.0.0: one-step RUN and verified provenance

| Field | Value |
|---|---|
| Audit ID | `2026-10-29T09-39-12Z-release-v1-0-0-one-step-run-and-verified-provenance` |
| Created (UTC) | 2026-10-29T09:39:12.587Z |
| Auditor | Copilot SDK session f70a1d9e-0d14-4d9a-94b6-fa8a875a5c54 (AI assistant using Copilot SDK in VS Code); self-audit |
| Baseline commit | `39ddda754f08f325c65f4473e4f45973d96b7e02` (= `origin/master`) |
| Outcome | `PASS WITH RISKS` |

## Request and outcome

- Requested behavior and confirmed decisions (REQ-TEMPLATE-RELEASE-035, owner 2026-10-29T08:41Z): one-run launchers, requested as "RUN.com" (shipped as `RUN.cmd`: a `.com` file is a binary executable, so a script cannot use that extension). The first run checks files and installs, runs tests and loads the program; later runs repeat only what is needed; several launchers are possible. Adopt the forwarded v1.0.0 plan where it fits: resolve risks instead of documenting them; v1.0.0 as the first release with commit identifiers for development builds; reference validation across Markdown, JSON, YAML, PowerShell, configuration and source with dynamic references reported as limitations; verify `-TemplateCommit` in the real upstream; automatic provenance for GitHub template copies without guessing; fix checkup 08 for long paths with >100 and >260 character regressions; keep `%TEMP%\moorkyz-node24` outside the repository; release acceptance criteria; a consolidated Template Integrity checkup. The owner values complexity packed as simplicity and careful UI/UX. Publishing: the owner was unavailable when asked; the host asked for the pragmatic option, so the commits are pushed and `v1.0.0` is tagged only after every release check, including GitHub CI, passes.
- Implemented behavior:
  1. **RUN.** [RUN.cmd](../RUN.cmd) (CRLF, clears the inherited `PSModulePath`) runs [.template/run/Run.ps1](../.template/run/Run.ps1). It uses Node.js from PATH when it matches the `.node-version` major, else one kept in `%LOCALAPPDATA%\Moorkyz\runtimes`. Otherwise it explains the situation, asks (or `-Yes`), downloads the official build from nodejs.org (or `MOORKYZ_NODE_MIRROR`), verifies the SHA-256 against the published list with .NET (no module dependency), extracts through a staging folder that is removed on any failure, checks the reported version, and never changes PATH, the registry or system settings. It then runs `node moorkyz up`. `-RuntimeOnly` prints node.exe for other tools, `-DryRun` only loads, and failures pause only in interactive sessions.
  2. **`moorkyz up`** shows one line per step and repeats each only when its inputs changed (`.moorkyz/<name>.up.json`):
     - runtime: the pin is a minimum; a newer major is noted;
     - files: the static start page with exact casing, or `package.json` and its `dev` script;
     - packages: a reproducible install when the lockfile/manifest hash changed or `node_modules` is missing; a missing lockfile stops the run;
     - checks: run when the path/size/mtime fingerprint of all non-ignored files or the Node.js version changed; references are scanned too and broken ones are shown as a warning;
     - start: a loopback static preview (GET/HEAD only, hidden segments, traversal and symlink escape refused, case-mismatch 404 with a hint, `no-store`, next free port when busy), or the `dev` script in the foreground with `PORT` and `NODE_ENV`; a program already started with `moorkyz start` is reused; the browser opens once the port answers.
     Failures stop before starting and print the last 30 lines of output. `--no-start`, `--no-open` and `--force` are available.
  3. **Static programs.** `moorkyz.config.json` accepts `static`, `open` and `checks`. The new root [moorkyz.config.json](../moorkyz.config.json) makes the template website the default program, checked by `website/verify.mjs` and `designs/verify.mjs`. `verify` runs configured checks, `start` explains that static programs use `up`, `list`/`doctor` describe them, and `install` shares `installPlan` with `up`.
  4. **`moorkyz references`.** One engine for maintenance, adoption and `up`:
     - Markdown/HTML links use the same rules as before;
     - also covered: CSS `url()`/`@import`, ES/CommonJS module references (`import`, `require`, `new URL(…, import.meta.url)`, `createRequire`), literal paths in scripts, PowerShell, JSON, YAML and batch files (`%~dp0`), and Dockerfile `COPY`/`ADD`;
     - `path.join`/`Join-Path` are checked against the repository root or the script folder;
     - other bases, run-time paths and relative literals in scripts are listed as not verified (`--unverified`); literals in test files count as fixtures;
     - `--removing` adds mentions and bare names, excluding history and the adoption tool's own optional references;
     - `--json` gives machine-readable output.
  5. **`moorkyz version`.** Prints a release tag such as `v1.0.0`, otherwise `development build <sha7>` with the distance from the last release and local changes.
  6. **Claim Template.** The template commit is found from:
     - the newest template commit in the copy's history, with local commits and changes noted;
     - for GitHub template copies, the template commit whose tree equals the copy's first commit (tagged commits are preferred among equal trees, and the count is recorded);
     - for GitHub ZIP downloads, the new `helpers/template-commit.txt` `export-subst` stamp;
     - or `-TemplateCommit`.
     Every candidate is verified in a commits-and-tags-only bare clone of the real template (explicit `--git-dir`); unknown or unpublished commits are refused. The version label comes from the upstream tags. Node.js comes from `Run.ps1 -RuntimeOnly`. The removal pre-check and the final validation use the reference engine, recorded as "Reference validation".
  7. **Releases.** [.template/CHANGELOG.md](../.template/CHANGELOG.md) contains the v1.0.0 entry; the release procedure is in [TEMPLATE_INTRODUCTION.md](../TEMPLATE_INTRODUCTION.md#release-the-template).
  8. **Script icons.** Shortcuts are planned before anything is written. Shortcut, target, root or icon paths over 259 characters are skipped with the length they would need, instead of crashing midway with partial output or silently truncating targets.
  9. **Checkups.**
     - 01 dry-runs `RUN.cmd`.
     - 02 drops its duplicate link loop and checks the RUN.cmd launcher (CRLF) and the run tool layout.
     - 08 uses shorter fixture names, adds a group with a 160-character root and a shortcut beyond the limit, and unrolls JSON arrays for Windows PowerShell 5.1 hosts.
     - `09-template-integrity.ps1` replaces `09-claim-template.ps1`. It covers release metadata, repository references with rule units, a mutated copy and removal checks, and adoption against a disposable upstream reached through Git's own `url.insteadOf`.
     - `10-run.ps1` covers the bootstrap through a local mirror plus `up`, the script program and the preview server.
  10. **Guides.** README, TEMPLATE_INTRODUCTION (start paths, tasks, root map, adoption, tools, CLI, configuration, checkups, release procedure, decisions, pitfalls), AGENTS (root exceptions; agents use `up --no-start`), the tool catalog, INFRASTRUCTURE, and the claim, maintenance, script-icons, website and run guides. `README.html`, the 20 README editions and the search index were regenerated.
- Initial Git state and unrelated work preserved: `HEAD` = `origin/master` = `39ddda7`. Another session's staged entries (six `designs/` viewer files, the publication audit, `.vscode/settings.json` and two scheduler rows) were neither committed nor unstaged; regeneration left their six design files byte-identical. This commit was built in a temporary index. The stale claims TEMPLATE-VIEWER-025, TEMPLATE-DEPLOY-026 and REPO-PUBLISH-031 are untouched.
- Intentional exclusions:
  - no separate `RUN-Designs.cmd`: the website already opens every design, and the guide documents a two-line `RUN-<Name>.cmd` per extra program;
  - no change to `SetProjectType.cmd` or other unrelated tools;
  - the template repository's GitHub "Template repository" setting is not changed; that is an owner action;
  - no deployment.

## Analyzing and Reading

- Guides, affected source/consumers, documentation and tests read: AGENTS, the scheduler, the CLI (config, start/worker, install, verify, doctor, help), CreateProject, SetScriptIcons and their guides, checkups 01/02/08/09, the workflows, the Dockerfile, the website guide and the node preset.
- Acceptance criteria and edge cases:
  - the owner's release criteria;
  - a first run from nothing, later runs only on change;
  - consent before downloads, checksum mismatches, Windows PowerShell 5.1 under PowerShell 7;
  - hardened Git (`safe.bareRepository=explicit` is set in this environment);
  - 8.3 and >100-character TEMP paths, spaces and parentheses in paths;
  - clones with local commits, GitHub template copies, ZIP downloads, unknown/unpublished SHAs;
  - false positives from generators, outputs and fixtures.

## Researching and Planning

- Existing helpers/tools and authoritative, version-specific sources checked:
  - the CLI already had reproducible installs, verify, managed start and browser opening, so RUN orchestrates it instead of duplicating it;
  - empirical checks:
    - a GitHub archive of `pypa/setuptools-scm` expanded its `export-subst` placeholders (commit 4fee59d…), although a web answer claimed otherwise;
    - Windows Script Host cannot save shortcuts at 260+ characters even with `\\?\`, silently truncates long targets to 259, and Explorer cannot launch a shortcut stored beyond the limit (0xfffffffe);
    - Windows PowerShell 5.1 handles long paths otherwise (LongPathsEnabled=1);
    - nodejs.org `latest-v24.x/SHASUMS256.txt` lists `node-v24.22.2-win-x64.zip`;
  - `Moorky/moorkyz-template` reports `is_template: false` in the GitHub API, so "Use this template" is not offered until the owner enables it.
- Chosen approach, affected outputs and verification plan: keep the logic in the CLI (testable, cross-platform), keep RUN.cmd thin, and make the Windows bootstrap its only extra; build one reference engine; verify provenance only against upstream history (never guess); add a release gate (three full maintenance configurations, a clean install, CI, then the tag).
- Assumptions, dependencies and required approvals: publication follows the host's pragmatic-option instruction; tree matching relies on Git content addressing (identical files give the identical tree). No new dependencies.

## Developing

| Path | Change | Risk |
|---|---|---|
| `moorkyz` | `up`, static preview, `references`, `version`, static config keys, shared install plan | Medium: central CLI; covered by checkups 01, 05, 09, 10 |
| `RUN.cmd`, `.template/run/` | Launcher, verified runtime bootstrap, guide | Medium: downloads executables only with consent and a verified checksum |
| `.template/claim-template/CreateProject.ps1`, `helpers/template-commit.txt`, `.gitattributes` | Verified provenance, version labels, shared reference checks | Medium: one-time adoption; checkup 09 on both hosts |
| `.template/script-icons/SetScriptIcons.ps1` | Long-path planning | Low |
| `moorkyz.config.json`, `.template/CHANGELOG.md` | Website program, v1.0.0 notes | Low |
| Checkups 01, 02, 08, 09 (renamed), 10 | Coverage described above | Low |
| Guides and regenerated outputs | Documentation | Low |

## Clean Up

### Verification

Node.js `v24.22.0` was first on `PATH`. Checks ran on `git checkout-index -a` exports of a temporary index (`HEAD` plus the 49 task changes), so other sessions' files were excluded. The checkups exercise PowerShell 7.6.9 and Windows PowerShell 5.1 hosts.

| Check | Result | Command / evidence |
|---|---|---|
| Maintenance, Windows PowerShell 5.1 host, TEMP of 112 characters | PASS | `powershell.exe -File <export>\.template\maintenance\RunCheckups.ps1 -NoPause`: 10 passed, 0 failed (306 s) |
| Maintenance, PowerShell 7 host, normal TEMP | PASS | `pwsh -File … -NoPause`: 10 passed (288 s) |
| Maintenance, PowerShell 7 host, 8.3 short TEMP (`MZSHOR~1`, as on GitHub's runners) | FAIL, then PASS | First run 9/10: `10-run.ps1` compared node.exe paths textually and got the long form; it now compares canonical paths, and `10-run.ps1` passed with the 8.3 TEMP |
| Final gate on the final commit tree (after this audit and the scheduler edits) | PASS | Full maintenance with PowerShell 7 and the 8.3 TEMP: 10 passed; `10-run.ps1` hosted by Windows PowerShell 5.1 with the 112-character TEMP: PASS |
| Clean installation with RUN.cmd | PASS | Fresh copy of the export at a path with spaces and parentheses, system Node v22.18.0 on PATH, empty runtime folder: `RUN.cmd -Yes --no-start` downloaded Node.js 24.22.2 from nodejs.org, verified it, ran 2 checks (2795 references) and exited 0 in 11 s. `RUN.cmd --no-open` then skipped the unchanged checks and served on port 4174 (4173 was in use): `/index.html`, the viewer, `/designs/index.html`, a README edition and an asset returned 200; `/.template/run/Run.ps1` returned 404 |
| Reference engine on the repository | PASS | Commit tree: 2,801 references in 187 files resolve; 119 dynamic or base-relative expressions reported as not verifiable; mutation and unit tests in checkup 09 |
| Real nodejs.org bootstrap during development | PASS | Non-interactive refusal without `-Yes`, then a verified install of 24.22.2 and reuse on the next run |
| `git diff --cached --check` | PASS | On the temporary index |
| Dependency audit | N/A | No dependency, manifest or lockfile changed |
| Production container build | NOT RUN locally | The Docker engine is not running; the Template website workflow builds it before the tag |
| Linux | NOT RUN locally | Ubuntu CI must pass before the tag |
| Final-state rechecks after corrections/regeneration | PASS | See "Final gate" |

### Quality and safety review

- Correctness, best practices, redundancy/dead code and unnecessary complexity:
  - one reference engine replaces three link implementations (checkup 02, CreateProject's PowerShell scanner, ad-hoc mentions);
  - the shared `installPlan` replaced duplicated lockfile logic, and `portArguments` is shared by `worker` and `up`;
  - RUN.cmd is 8 lines; the bootstrap is the only Windows-specific logic.
- Compatibility, error handling and coverage:
  - Windows PowerShell 5.1 and PowerShell 7 on Windows; PowerShell 7 and Node on Linux, covered by CI;
  - 8.3 and long TEMP paths, spaces and parentheses;
  - hardened Git configuration (`safe.bareRepository=explicit`, present in this environment) and inherited PowerShell 7 module paths;
  - every failure path prints a cause and the next action.
- Secrets and security:
  - downloads need consent and a matching published SHA-256; staging is removed on failure;
  - the preview server binds to loopback and never serves hidden files;
  - no credentials, no PATH or registry changes, no telemetry.
- Self-reviewer, scope and findings: this session reviewed the complete diff. Findings fixed during the work:
  - `$runtimes?` parsed as a variable name;
  - `Get-FileHash` missing in Windows PowerShell 5.1 started from PowerShell 7;
  - a clone with local commits recorded its unpublished HEAD as the template commit (the previous behaviour);
  - bare-repository queries broke under `safe.bareRepository=explicit`;
  - `@(…)` re-wrapped helper output, so a multi-commit history looked empty;
  - scanner false positives (generator-relative links, other projects' output paths, URL prefixes);
  - non-ASCII text in checkups broke Windows PowerShell 5.1 hosts;
  - checkup 08 assumed PowerShell 7's `ConvertFrom-Json` array unrolling (a pre-existing line);
  - checkup 10 failed under the 8.3 TEMP;
  - Linux process-group cleanup in checkup 10;
  - script icons crashed on long paths and silently truncated targets (pre-existing).
- Independent review and required approvals: independent review not requested; human review pending. Publication follows the pragmatic option the host requested while the owner was unavailable.
- Findings, residual risks and blockers:
  1. GitHub template-copy detection rests on Git content addressing, verified with simulated copies but not yet with a real GitHub-generated repository. The repository's "Template repository" setting is off.
  2. `MOORKYZ_NODE_MIRROR` is trusted like nodejs.org: its own checksum list is used.
  3. Dynamic and base-relative paths cannot be checked statically (reported as counts); path literals in tests are fixtures.
  4. After Ctrl+C, cmd may ask "Terminate batch job (Y/N)?".
  5. Shortcuts beyond 259 characters stay a Windows limit (skipped explicitly).
  6. The runtime download is Windows-only.
  7. `SetProjectType.cmd` does not clear `PSModulePath`, as RUN.cmd now does; it currently uses no affected command (documented pitfall).
  No blockers.

### Final references and documentation

| Reference / content | Availability / validity | Command / source / evidence and impact |
|---|---|---|
| Changed code references, consumers, paths/casing, assets, commands and configuration | PASS | Checkup 09 (repository references with exact casing), 01 (syntax, dry runs, every CLI command), 02 (layout and launcher) |
| Supported APIs/dependencies and local links/anchors | PASS | Node core modules only; `fs.realpathSync.native`, `server.closeAllConnections` (Node 18.2+) on the pinned Node 24; `#release-the-template` exists |
| Changed external references and version-specific claims | PASS | nodejs.org download list and archive layout verified live; GitHub archive `export-subst` verified empirically; template URLs unchanged |

- Unreachable or unverifiable content, impact and required follow-up: a real GitHub-generated copy cannot be tested until the owner enables the template setting; the guide states it.
- Docs, examples, generated outputs and queue evidence updated: yes (see Implemented behavior 10).
- Task-created temporary files removed (existing data preserved): exports, fresh copies, fake LOCALAPPDATA folders, logs, the probe archives and helper scripts are outside the repository and removed after the commit. `%TEMP%\moorkyz-node24` stays as the owner asked.
- Final affected tests, quality and reference checks repeated after updates: yes; see the verification table.

### Completion

- Commit: focused local commit; the hash is reported in the session completion.
- Staged diff and `git diff --cached --check`: reviewed on the temporary index (exactly the task's files; the scheduler blob holds only this request's rows); PASS.
- Human review: pending
- Required checks/approvals and completion or handoff status: local release checks PASS. Publication follows the order of the release procedure: push fast-forward, GitHub CI green on Ubuntu and Windows, then tag `v1.0.0` and push it; results are reported in the session completion. TEMPLATE-RELEASE-035 is complete and its claim released.
- External actions: the fast-forward push of `master` and the `v1.0.0` tag (pragmatic option per the host's instruction while the owner was unavailable). No deployment, GitHub Release, pull request, repository-setting or credential change.

A generated draft is not verification evidence and a self-audit is not an
independent security review.