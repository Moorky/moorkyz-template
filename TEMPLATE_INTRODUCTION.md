# Moorkyz Template: introduction and file guide

This repository is two things at once:

1. **An engineering baseline** for new and existing Moorkyz projects: agent and contributor workflow, a portable dependency-free CLI, recoverable storage, read-only verification, security policy and CI.
2. **A template library**: twenty design directions (landing pages and README editions, five of them compact documentation themes), document and collaboration templates, and opt-in configuration presets.

A product's language, framework, database and deployment destination remain choices for that product. The root is deliberately stack-neutral: Node.js 24 LTS runs the shared CLI and checks; PowerShell runs the template tools. There is no root application manifest, dependency lockfile or deployable product. The only deployment package belongs to this repository's own [template website](#template-website). Use the [tool catalog](.template/README.md) to choose a tool, then read its own guide before using it. Do not run all tools as a setup sequence.

This guide is the map, not the rulebook: for agents, [AGENTS.md](AGENTS.md) is authoritative, and each tool's README holds its detailed contract. It describes the inspected files and their intended effects. It is not a claim that a remote deployment, account connection or verification run has succeeded.

## Start here

### Everyone: first ten minutes

1. Install Git, Node.js 24 LTS (the major version is pinned in `.node-version`) and PowerShell 7 (`pwsh`). Windows PowerShell 5.1 also runs the tools; Linux uses PowerShell 7. The template itself needs no package installation.
2. From the repository root, confirm the toolchain and list the commands:

   ```powershell
   node --version     # the checks require v24.x
   node .\moorkyz help
   node .\moorkyz doctor
   pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -DryRun
   ```

3. Run the full checks once: `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause`. They take several minutes and, on Windows, briefly open and drive the soft-copy window inside disposable fixtures.
4. Open the [template catalog](index.html) or the [design showcase](designs/index.html) in a browser to see the template library.
5. Continue with the section for your role, then [common tasks](#common-tasks).

### Developers

- **Daily loop.** Pull, check the [work queue](AGENT_SCHEDULER.md) for active claims, work in the four phases from the [contributor guide](CONTRIBUTING.md#work-steps), run maintenance plus your product's own checks, record evidence with `node moorkyz audit "task title"` and make one focused local commit.
- **Hand work to an agent.** Fill in a [task brief](docs/TASK_BRIEF_TEMPLATE.md) or the GitHub change request form: outcome, acceptance criteria, scope, constraints and explicit approvals. An unticked approval means the agent must not push, deploy, spend, delete data or add high-impact dependencies. Say which default to apply if you are unavailable.
- **Review agent work.** Read the audit first: every check must say PASS, FAIL, NOT RUN with a reason, or N/A. Then inspect the commit (`git show --stat`, `git show`), rerun maintenance for risky changes and confirm that only task-owned files changed. Passing checks and self-review never imply your approval; you decide on push, merge and deployment.
- **Report and propose.** Use the [issue forms](.github/ISSUE_TEMPLATE/) and the [pull request template](.github/pull_request_template.md). Report vulnerabilities only privately, as described in [SECURITY.md](SECURITY.md).
- **Plan bigger changes.** Use the [design template](docs/DESIGN_TEMPLATE.md) before building and the [decision template](docs/DECISION_TEMPLATE.md) for lasting choices such as the product stack or a deployment contract.

### AI agents

[AGENTS.md](AGENTS.md) is the contract and wins over this guide. In practice:

1. **Read in this order:** AGENTS.md, the [work queue](AGENT_SCHEDULER.md) (picking rules and current rows), the [work steps](CONTRIBUTING.md#work-steps), the [tool catalog](.template/README.md) and only the tool guides your task needs, then the affected source, consumers, documentation and checks.
2. **Inspect shared state first.** Run `git status --short` and `git log -5`. Other sessions may own uncommitted files. The queue records claims but is not a lock, and claims can be stale. Never take over, stage, revert or reformat someone else's work without a recorded handoff or owner direction.
3. **Record, then claim.** Add the owner request to the ledger, claim one item with your session ID, UTC time and file scope, and keep every table cell on one line.
4. **Use the required toolchain.** Put Node.js 24 first on `PATH` (`node --version`); older Node versions fail the checks. While iterating, run a single checkup directly, for example `pwsh -NoProfile -File .\.template\maintenance\helpers\checkups\06-design-collection.ps1`; run the full runner before completion.
5. **Never hand-edit generated files.** Regenerate them from their sources; see [generated files](#generated-files-and-their-sources).
6. **Stage only your own changes.** In a shared tree, stage the files you own; for shared files such as the queue, stage only your hunks (`git add -p`, or an index blob built from `HEAD` plus your rows). Run `git diff --cached --check` before committing.
7. **Finish with evidence.** Fill the audit with the actual commands and results, release or hand off the claim, commit locally and report the commit hash and remaining risks. Pushing, deploying and other external actions need explicit owner approval.
8. **If the owner cannot answer,** proceed only with the safest choice inside the approved scope and record it as an assumption in the ledger and audit; otherwise report the blocker.

## Common tasks

| I want to… | Do this | Details |
|---|---|---|
| Start a new product from the template | Clone the repository, fill in `setup.config.json`, preview `CreateProject.ps1 -WhatIf`, then apply once in the clone; commit with its adoption record | [Adoption route](#choose-the-appropriate-adoption-route) |
| Bring selected files into an existing repository | `CopyTemplate.ps1` (GUI, or `-NoGui -TargetDirectory … -File … -WhatIf`); undo with `-Revert` | [Soft copy](.template/soft-copy/README.md) |
| Add a stack or tooling preset later | `SetProjectType.cmd` (menu) or `SetProjectType.ps1 node web -WhatIf` | [Project types](.template/project-types/README.md) |
| Configure VS Code and Copilot for one repository | `Setup-CopilotProject.ps1 -ProjectPath <repo> -Scope Project -WhatIf`, then without `-WhatIf` | [Copilot settings](.template/copilot-settings/README.md) |
| Check everything | `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause` | [Maintenance](.template/maintenance/README.md) |
| Change the README | Edit `README.md`, run `node moorkyz readme` and `node designs/build.mjs`, then maintenance | [Generated files](#generated-files-and-their-sources) |
| Record task evidence | `node moorkyz audit "task title"`, then fill every section with real results | [Audit template](docs/AUDIT_TEMPLATE.md) |
| Delegate work | Task brief or change request form; record the request in the ledger | [Task brief](docs/TASK_BRIEF_TEMPLATE.md) |
| Plan a larger change or record a lasting choice | Design and decision templates | [Design](docs/DESIGN_TEMPLATE.md), [decision](docs/DECISION_TEMPLATE.md) |
| Build a landing page from a design | Copy `designs/NN-name/` together with `designs/assets/`, keep their relative layout, then replace copy, links and branding | [Design templates](#design-templates) |
| Publish Markdown documentation in one style | `node designs/build.mjs docs --theme paper --out html-docs README.md docs\INFRASTRUCTURE.md` | [Collection guide](designs/README.md) |
| Browse all templates | Open `index.html` or `designs/index.html`; `pwsh -NoProfile -File .\designs\OpenAll.ps1 -DryRun` lists every page | [Template website](#template-website) |
| Archive files recoverably | `node moorkyz archive <path> [path ...]` | [CLI guide](docs/INFRASTRUCTURE.md) |
| Run a Node application with managed ports and logs | Select the `node` preset, add real scripts, then `node moorkyz start`, `logs` and `stop` | [CLI reference](#cli-command-reference) |
| Give the tools the Moorkyz icon in Explorer | `SetScriptIcons.ps1 -WhatIf`, then without `-WhatIf` | [Script icons](.template/script-icons/README.md) |
| Report a bug or a vulnerability | Bug report form; vulnerabilities only through private reporting | [SECURITY.md](SECURITY.md) |
| Release or deploy | Not automated: obtain explicit owner approval first; the template website follows its own contract | [Deployment contract](website/deploy/README.md) |

## Generated files and their sources

Edit the source, then regenerate; checks fail when outputs are stale.

| Generated output | Sources | Regenerate | Freshness check |
|---|---|---|---|
| `README.html` | `README.md` | `node moorkyz readme` | `02-documentation.ps1` |
| `designs/*/README.html`, `designs/*/landing.html`, `designs/index.html`, `designs/assets/search-index.js` | `README.md`, `designs/catalog.mjs`, `designs/build.mjs`, `designs/search-dictionary.json` | `node designs/build.mjs` | `node designs/build.mjs --check`, run by `06-design-collection.ps1` |
| `index.html`, `website/viewer.html` | `designs/catalog.mjs`, `website/build.mjs` | `node website/build.mjs` | `node website/verify.mjs`, run by the website workflow |
| Themed documentation exports | Any selected Markdown files | `node designs/build.mjs docs --theme <theme> --out <folder> <files>` | Same command with `--check` |

## Template library

Everything below is reusable. Copy only what a project needs, together with each item's adjacent guide.

### Design templates

| Template | What you get | How to use it |
|---|---|---|
| Twenty landing pages | `designs/01-aether/landing.html` to `designs/20-continuum/landing.html`: original layouts, palettes and artwork with verified 4.5:1 text contrast, reduced-motion styles and no third-party assets | Copy the numbered directory and `designs/assets/` with their relative layout, then replace copy, links and branding. The header search and its index describe this collection: remove those scripts and styles or rebuild the index for your content. |
| Twenty README editions | `designs/NN-name/README.html`: the root README presented in each direction | Generated from `README.md` with `node designs/build.mjs`; they intentionally link back into this repository. |
| Five compact documentation themes | `paper`, `glacier`, `mono`, `vector` and `cabinet` | Render any set of Markdown files as self-contained HTML: `node designs/build.mjs docs --theme <theme> --out <folder> <files>`. |
| Showcase, catalog and viewer | `designs/index.html`, `index.html` and `website/viewer.html` | Browse and preview every template locally; see [template website](#template-website). |

The [collection guide](designs/README.md) lists all twenty directions, reference notes and export options.

### Documentation and collaboration templates

| Template | Use it to | Notes |
|---|---|---|
| [Task brief](docs/TASK_BRIEF_TEMPLATE.md) | Hand a task to an agent or developer: outcome, acceptance criteria, scope, constraints, approvals | Same sections as the change request form |
| [Design](docs/DESIGN_TEMPLATE.md) | Plan a non-trivial change before building it | Written during Researching and Planning |
| [Decision record](docs/DECISION_TEMPLATE.md) | Record one lasting choice, such as the stack or a deployment contract | Store accepted records in `docs/decisions/`; supersede instead of rewriting |
| [Audit](docs/AUDIT_TEMPLATE.md) | Record the evidence for one task | Created in `.audits/` by `node moorkyz audit "task title"` |
| [Bug report form](.github/ISSUE_TEMPLATE/bug_report.yml) | Collect versions, exact commands and a disposable reproduction | GitHub issue form; matches the contributor guide's bug-report rules |
| [Change request form](.github/ISSUE_TEMPLATE/change_request.yml) | Propose work that an agent or developer can act on | GitHub version of the task brief |
| [Issue chooser](.github/ISSUE_TEMPLATE/config.yml) | Require a form and route vulnerabilities to private reporting | Adoption rewrites its repository link with `SECURITY.md` |
| [Pull request template](.github/pull_request_template.md) | Summarize scope, verification, audit and approvals | Mirrors the contributor review checklist |
| [Portable agent guide](.template/copilot-settings/helpers/AGENTS.template.md) | Start an `AGENTS.md` in another repository | Copilot settings adds it only when none exists |

A typical flow: task brief or change request, optional design, implementation, audit, optional decision record, and a pull request when publication is approved.

### Configuration and workflow templates

| Template | Purpose |
|---|---|
| [Project-type packs](.template/project-types/README.md) | Nine opt-in starters at root-relative paths: `node`, `web`, `docker`, `typescript`, `eslint`, `prettier`, `stylelint`, `markdownlint` and `vscode` |
| [setup.config.json](.template/claim-template/helpers/setup.config.json) | One-time adoption settings for a template copy |
| [copilot-config.json](.template/copilot-settings/helpers/copilot-config.json) and the [bring-your-own-key example](.template/copilot-settings/helpers/chatLanguageModels.example.json) | Reviewed editor and agent settings; model-provider example without credentials |
| [moorkyz.config.example.json](.template/project-types/helpers/types/node/moorkyz.config.example.json) | Several Node applications with scripts, URLs, ports and storage policy |
| [Project tooling workflow](.github/workflows/project-tooling.yml) and [Dependabot](.github/dependabot.yml) | Maintenance on Ubuntu and Windows with pinned actions and a read-only token; weekly grouped Actions updates |
| [.editorconfig](.editorconfig), [.gitattributes](.gitattributes) and [.gitignore](.gitignore) | Shared formatting, line-ending and ignore conventions |

## Root map

| Path | Exact purpose |
|---|---|
| [TEMPLATE_INTRODUCTION.md](TEMPLATE_INTRODUCTION.md) | This file: role-based start paths, common tasks, the template library, file map, tool contracts, configuration defaults, adoption guidance, deliberate decisions and known pitfalls. |
| [README.md](README.md) | Canonical quick start, adoption, layout, storage and verification guide. |
| [README.html](README.html) | Generated browser edition of the root Markdown; regenerate with `node moorkyz readme`. |
| [moorkyz](moorkyz) | Self-contained, dependency-free CLI and embedded storage library. It must stay at root. |
| [.template/README.md](.template/README.md) | Catalog of versioned reusable tools; entrypoints and guides sit together, support files under `helpers/`. |
| [docs/INFRASTRUCTURE.md](docs/INFRASTRUCTURE.md) | Detailed CLI, configuration, process ownership and storage contract. |
| [docs/dependency-security.md](docs/dependency-security.md) | Dependency and workflow maintenance guidance for the baseline and adopted products. |
| [docs/AUDIT_TEMPLATE.md](docs/AUDIT_TEMPLATE.md) | Source template for task reports; generation does not fill in evidence. |
| [docs/TASK_BRIEF_TEMPLATE.md](docs/TASK_BRIEF_TEMPLATE.md), [docs/DESIGN_TEMPLATE.md](docs/DESIGN_TEMPLATE.md), [docs/DECISION_TEMPLATE.md](docs/DECISION_TEMPLATE.md) | Templates for delegating work, planning non-trivial changes and recording lasting decisions. |
| [.audits/README.md](.audits/README.md) | Guide to tracked task history; dated reports record changes, checks and limitations. |
| [AGENTS.md](AGENTS.md) | Repository agent contract: precedence, focused changes, verification, audit and local commit workflow. |
| [AGENT_SCHEDULER.md](AGENT_SCHEDULER.md) | Shared request ledger and serial queue; coordination text, not a process launcher or atomic lock. |
| [.github/copilot-instructions.md](.github/copilot-instructions.md) | Discovery pointer to the root guide and queue, avoiding duplicated rules. |
| [.agents/skills/task-audit/SKILL.md](.agents/skills/task-audit/SKILL.md) | Portable task-audit procedure for real results, review and a focused local commit. |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution workflow and boundaries between reusable tooling and product code. |
| [SECURITY.md](SECURITY.md) | Private vulnerability reporting and handling of credentials, personal data and recovery archives. |
| [LICENSE](LICENSE) | Apache License 2.0 terms; retain and review the applicable license when adopting files. |
| [.node-version](.node-version) | Major version `24` for shared tooling; CI reads this file. |
| [.editorconfig](.editorconfig) | UTF-8, LF, final newline and two-space conventions; Markdown keeps intentional trailing whitespace and Windows command wrappers use CRLF. |
| [.gitattributes](.gitattributes) | Git text normalization to LF, CRLF for Windows command wrappers, automatic binary detection and explicit binary asset rules. |
| [.gitignore](.gitignore) | Excludes local secrets, runtime data, dependencies, generated output and common scratch/editor files. |
| [.github/workflows/project-tooling.yml](.github/workflows/project-tooling.yml) | Ubuntu/Windows maintenance CI; no application publication or deployment. |
| [.github/workflows/template-website.yml](.github/workflows/template-website.yml) | Template-website CI: catalog/viewer checks, packaging tests, a hardened real container over HTTP and full maintenance; no deployment credentials. |
| [.github/dependabot.yml](.github/dependabot.yml) | Weekly grouped GitHub Actions update proposals. |
| [.github/ISSUE_TEMPLATE/](.github/ISSUE_TEMPLATE/) | Bug report and change request forms, plus a chooser that requires a form and routes vulnerabilities to private reporting. |
| [.github/pull_request_template.md](.github/pull_request_template.md) | Pull request summary, verification table, audit and approvals. |
| [designs/README.md](designs/README.md) | Design collection, theme export, regeneration and verification guide. |
| [index.html](index.html) | Generated root catalog of all forty templates (twenty designs, README and landing each) with page-type and style filters; regenerate with `node website/build.mjs`. |
| [website/README.md](website/README.md) | Catalog and viewer guide: generation, verification and viewer behavior. |
| [website/deploy/README.md](website/deploy/README.md) | Deployment contract for this repository's template website; deploying needs explicit owner approval. |

The local `.logs/`, `.archive/` and `.moorkyz/` directories are ignored runtime data, not required checked-in code. The CLI creates them when needed. `.audits/`, `.agents/` and `.template/` are versioned material with different purposes. A leading dot does not itself set the Windows Hidden attribute or make Git ignore a path. A local `.vscode/settings.json` appears after running Copilot settings with project scope; commit it only if the project wants shared editor settings.

## Choose the appropriate adoption route

For a **new product**, clone the repository, retain its useful conventions, then use [Claim Template](.template/claim-template/README.md) in that clone before pointing its `origin` at the new repository. Do not apply adoption to the template repository itself.

1. Review `.template/claim-template/helpers/setup.config.json`.
2. Fill in `projectName`, `displayName` and `githubOwner`; keep `projectTypes` and `remove` as JSON arrays (`[]` when empty).
3. Preview with `CreateProject.ps1 -WhatIf`, then review the plan before applying it. Add `-TemplateCommit <full SHA>` only for a copy without the template's Git history.
4. Commit the result together with the generated adoption record in `.audits/`.
5. Document the actual product stack; add only the required presets, packages, application scripts and authoritative lockfile.
6. Retain appropriate checkups, regenerate affected documentation, and verify the adopted product separately.

`projectName` uses lowercase letters/digits separated by single hyphens, up to 100 characters; the placeholder name `moorkyz-project` is explicitly refused. `displayName` is a nonempty one-line title, up to 100 characters. `githubOwner` identifies the actual owner. `projectTypes` is `[]` for no presets or an array of existing type names. The shipped config contains no placeholder text: both names are empty, so validation lists them until they are filled in, and both lists are empty arrays. A string where a list belongs is rejected. When no types are configured, an interactive run offers the existing project-type menu (several types or none); the selection is validated like a hand-written configuration and saved to the config once the plan is confirmed.

Adoption copies the selected presets, permanently removes only explicitly listed paths, replaces the project/owner placeholders in eligible text and updates the README title. It regenerates `README.html` and the design README editions when Node and the retained files are available; otherwise review the warning and regenerate separately. A `remove` path is refused while any remaining file links to or mentions it, and `.audits` cannot be removed. Runtime directories, `.audits/`, commit-pinned template links and the adoption folder are excluded from text replacement. Explicit `remove` entries can still delete runtime directories, so review every removal. Differing existing preset targets are refused before copying. Reruns support recovery from an incomplete adoption; filesystem failures can still leave partial work.

**Adopted projects start their own audit trail.** The first adoption does not inherit the template's audit records or work-queue history: the template records stay in the template repository, links to them (such as the evidence in this guide) are pointed to the template commit on GitHub, the request ledger and work queue keep only their example rows, and `.audits/` gets a clean README plus an adoption record. That record preserves the template repository, version (the Git tag, or `untagged`) and commit SHA, read from Git when the clone's `origin` is the template or taken from `-TemplateCommit`. Finally every internal Markdown/HTML link is validated; broken links are listed and the run ends with an error until they are fixed, and the rerun after the fix records the passing result in the adoption record. Reruns keep the project's own trail.

**Keep the tools after claiming.** `.template/claim-template` is used once but should stay: the tool catalog, the project-type guide and the README editions link to it, so deleting it alone breaks those links. The same applies to any linked area, such as `designs/`, `website/` or a tool folder. To drop an optional area, list it in `remove` only after removing or updating every file that references it (find them with `git grep -n "<folder>"`), including its dedicated checkup or workflow; the adoption pre-check lists anything left.

For an **existing product**, use [Soft copy](.template/soft-copy/README.md) to choose individual template files without claiming or renaming the target. For **later stack additions**, use [Project types](.template/project-types/README.md). For **editor settings only**, use [Copilot settings](.template/copilot-settings/README.md).

## Reusable tools and options

Run from the repository root unless the tool guide says otherwise. PowerShell scripts require 5.1 or later; Linux uses PowerShell 7. The maintenance workflow uses `pwsh` and Node.js 24 on PATH.

| Tool | Entrypoint and supporting files | Options and effect |
|---|---|---|
| [Maintenance](.template/maintenance/README.md) | `.template/maintenance/RunCheckups.ps1`; `helpers/checkups/` | `-NoPause` for automation; `-DryRun` lists checkups. Executes ordered checks in separate processes, streams results, continues after failures, returns 0 only when all pass. |
| [Project types](.template/project-types/README.md) | `.template/project-types/SetProjectType.ps1`, `SetProjectType.cmd`; `helpers/types/` | Positional type names; `-WhatIf` previews validated input; `-DryRun` performs no action. Without names, opens the selection menu. |
| [Claim Template](.template/claim-template/README.md) | `.template/claim-template/CreateProject.ps1`; `helpers/setup.config.json` | `-WhatIf`, `-DryRun`, `-NoPause`, `-Yes`. Normal action asks for confirmation; `-Yes` skips that question for an already reviewed plan. |
| [Soft copy](.template/soft-copy/README.md) | `.template/soft-copy/CopyTemplate.ps1`; `helpers/CopyCore.ps1`, `CopyGui.ps1`, `CopyUndo.ps1` | `-TargetDirectory`, `-File`, `-NoGui`, `-ForceCopy`, `-Revert`, `-WhatIf`, `-DryRun`. Windows GUI requires STA; explicit command-line selections also work without the GUI. |
| [Copilot settings](.template/copilot-settings/README.md) | `.template/copilot-settings/Setup-CopilotProject.ps1`; configuration and agent/BYOK examples under `helpers/` | `-ProjectPath`, `-Scope`, `-ConfigPath`, `-VSCode`, `-WhatIf`, `-NoPause`, `-DryRun`. Configures reviewed editor settings, not sign-in or service availability. |
| [Script icons](.template/script-icons/README.md) | `.template/script-icons/SetScriptIcons.ps1`; `helpers/moorkyz.ico` | `-WhatIf` discovers and validates the plan; `-DryRun` loads without discovery. Windows only. Creates local `.lnk` shortcuts with the Moorkyz icon plus `inventory.json` under ignored `.moorkyz/script-icons/`; never edits scripts, executables or file associations, and refuses to overwrite existing output. |

`-DryRun` returns before actions and does not validate a real plan or configuration. Use supported `-WhatIf` previews when input-aware validation is needed. PowerShell also supplies standard confirmation options to entrypoints using `SupportsShouldProcess`. These modes are trusted code, not a security sandbox.

The selector has two columns and one controls row. Up/Down moves, Space toggles, numbers select, Enter reviews, and explicit Y applies; Esc/Q exits. Named selections work in automation. The CMD wrapper forwards options and pauses only when launched without arguments. Before copying, the selector checks all selected targets; identical files are unchanged, differing files/conflicts/links are refused. All preset sources stay available for later additions.

Soft copy starts with no files selected and force disabled. Normal mode exclusively creates missing files and preserves differing existing files; force replacement requires explicit authorization. It saves local content pairs and recovery snapshots before destination writes. Revert restores saved originals and removes only files/empty directories owned by that operation, refusing later edits. Operations are per-file, not transactional; abrupt failures can require manual recovery. Source files remain in the template.

Copilot setup defaults to the current working directory, `-Scope Both`, and `-VSCode Stable`. `Both` can change both the user's VS Code settings and the selected project's settings; choose `Project` or `Global` to narrow that scope. It preserves unrelated keys, adds a missing agent guide when configured, backs up modified JSON and accepts JSONC without retaining comments/formatting in regenerated files. The default MCP server map is empty. Existing guides and provider credentials are not replaced.

Its supporting files are `helpers/copilot-config.json`, `helpers/AGENTS.template.md` and `helpers/chatLanguageModels.example.json`. Configuration keys are `globalSettings`, `projectSettings`, `sandbox`, `createAgentsMd` and `mcpServers`. Sandbox defaults to `auto`; the script handles known Windows baselines conservatively. `ALL SET` means requested local configuration steps completed; `FAILED`, `INCOMPLETE` and `PREVIEW ONLY` distinguish other outcomes. It does not install extensions, authorize accounts, start a task or guarantee a model/sandbox is available.

## Nine optional project packs

Every source below is under `.template/project-types/helpers/types/`; its contents mirror the destination paths at the adopted repository root. They add configuration/assets only: no automatic package installation, dependency merge, downloads or application scaffolding.

| Pack | Exact source files relative to `helpers/types/` | Intended purpose |
|---|---|---|
| `node` | `node/package.json`, `node/moorkyz.config.example.json` | npm/Node tooling starter and optional named-project CLI configuration. Its `test` runs maintenance through `pwsh`; `verify` runs `npm test`. No application start script or lockfile is supplied. |
| `web` | `web/public/` | Browser icons and manifest independent of server language. |
| `docker` | `docker/Dockerfile`, `docker/.dockerignore` | Container packaging starter with required `BASE_IMAGE`; real build/runtime/start/health/non-root contract still needed. |
| `typescript` | `typescript/tsconfig.json` | Strict, no-output ES2023/NodeNext checks with exact file casing. Review for browser/bundler stacks. |
| `eslint` | `eslint/eslint.config.mjs` | JavaScript flat configuration, basic correctness/unused-variable rules and tooling/output ignores. TypeScript needs separate parser configuration. |
| `prettier` | `prettier/.prettierrc.json`, `prettier/.prettierignore` | 100-column, two-space, semicolon/double-quote/LF formatting; excludes local/generated material. |
| `stylelint` | `stylelint/stylelint.config.mjs` | Extends `stylelint-config-standard`; review/install both required packages. |
| `markdownlint` | `markdownlint/.markdownlint.json`, `markdownlint/.markdownlintignore` | Default Markdown lint rules with long lines and inline HTML allowed. |
| `vscode` | `vscode/.vscode/extensions.json` | EditorConfig, ESLint, Prettier and Stylelint extension recommendations; no installation. |

The web pack contains `android-chrome-192x192.png`, `android-chrome-512x512.png`, `apple-touch-icon.png`, `favicon-16x16.png`, `favicon-32x32.png`, `favicon.ico` and `site.webmanifest`. Review the manifest name, paths and icons for the product. The Node pack declares npm 11.5.2 and Node 24; choosing it is separate from installing those tools or creating a deployable Node application.

## CLI command reference

The launcher operates on the shell's current working directory, even when the launcher file lives elsewhere. Use `node moorkyz <command>` on every platform; on Unix, executable permission also permits `./moorkyz`. It uses Node core modules, with no local helper dependency.

| Command | Options/defaults | Exact action |
|---|---|---|
| `help [command]` | Default when omitted; `--help` and `-h` aliases | General or command-specific help. |
| `start [name\|all]` | Optional `--prod` | Validate replacement, stop verified owned instance if present, launch a fresh supervised service/log and open its URL. |
| `restart [name\|all]` | Optional `--prod` | Same replacement lifecycle. |
| `stop [name\|all]` | No production flag | Stop only a verified managed process group/tree and wait for port release. |
| `status [name\|all]` | — | Report tracked process state and URL. |
| `logs [name]` | `--lines N`: 80 default, 1–10000; `--follow` | Read/follow one latest log; Ctrl+C ends viewing. |
| `list` | — | Display configured project names, scripts, directories and URLs. |
| `doctor` | — | Informational runtime, selected manager, scripts, config and audit-template diagnostics. |
| `verify [name]` | — | Existing `verify`; otherwise `validate`; otherwise available format/lint/typecheck/test/build gates, stopping at failure. |
| `build [name]` | — | Run the existing `build` package script. |
| `test [name]` | — | Run the existing `test` package script. |
| `lint [name]` | — | Run the existing `lint` package script. |
| `typecheck [name]` | — | Run the existing `typecheck` package script. |
| `security [name]` | — | Native package-manager vulnerability audit; report its exit status without applying upgrades. |
| `install [name]` | — | Reproducible install using an existing reviewed authoritative lockfile; may run package lifecycle scripts. |
| `run <script> [name]` | Existing script; no arbitrary argument forwarding | Run that package script. |
| `audit "task title"` | Nonempty title | Generate an unfilled report from `docs/AUDIT_TEMPLATE.md` into `.audits/`. |
| `readme` | No arguments | Regenerate `README.html` from root Markdown. |
| `archive <path> [path ...]` | Project-scoped selections | One verified compressed ZIP for the batch, then removal of unchanged selected originals. |
| `maintain` | No arguments | Archive malformed/excess logs and enforce archive age, byte and free-space policy. |

`--dry-run` may appear before or after a public command. It checks the command name and returns before configuration loading, argument validation, package execution, file writes or process management. It is not an action simulation. Only lifecycle/status commands accept `all`. The internal supervisor entry is not a user command.

Package commands select the nearest declared `packageManager`, otherwise detect pnpm/npm/Yarn lockfiles inside the root, otherwise default to pnpm. Competing lockfiles require a declaration. The manager must already exist; version detection does not install or enforce it. Reproducible installs use npm `ci`, pnpm frozen lockfile, Yarn Classic frozen lockfile or modern Yarn immutable mode. Scripts run in the configured project directory; installs run at the manager root.

`verify` fallback order is `format:check`, `lint`, `typecheck`, `test`, `build`. A declared `verify` or `validate` replaces that fallback, rather than running in addition. The stack-neutral baseline has no package scripts: its direct verification entry is maintenance. Product migrations, Git operations and deployment remain separate workflows.

## CLI project configuration

`moorkyz.config.json` is optional. A Node pack includes an example to adapt; copying it unchanged requires the example application directories to exist. Configuration paths must remain inside the current project root.

| Key | Default | Meaning/constraints |
|---|---|---|
| `projects` | One `default` project at `.` | Named-project object. Names start with a letter, use letters/digits/underscore/hyphen, maximum 51 characters. |
| `defaultProject` | Sole project's name; otherwise unset | Must name a configured project; otherwise commands require a name. |
| `projects.<name>.cwd` | `.` | Existing in-scope directory. |
| `projects.<name>.dev` | `dev` | Package script for development mode. |
| `projects.<name>.prod` | `start` | Package script for production mode. |
| `projects.<name>.url` | `http://localhost:3000` | HTTP(S) URL without embedded credentials; determines the configured port. |
| `projects.<name>.portArgs` | Vite/Astro detection, otherwise empty | Safe argument-token array; `{port}` is substituted. Vite gets strict-port behavior. |
| `projects.<name>.startupTimeoutMs` | `20000` | Milliseconds; integer 1000–300000. |
| `storage` | Policy below | Validated policy; unknown storage keys fail explicitly. |

The saved port is reused while its configured URL stays unchanged. A changed URL selects the new configured port. Busy, reserved or managed-conflicting ports fail explicitly: the CLI does not switch to a different port or kill an unrelated listener. Localhost probes check IPv4 and IPv6, with locking/reservations between cooperating launches. A different process can still race the probe-to-bind interval.

Starts/restarts validate the requested script and manager before stopping an existing verified instance. Each launch creates a new process identity and log while preserving project files, caches and preferences. The CLI sets `PORT`; production mode sets `NODE_ENV=production`. The application must honor the port or configured arguments. Startup confirms a fresh matching supervisor heartbeat and TCP listener, not HTTP correctness or application health.

Stop requires matching token, PID and heartbeat. Unix signals the managed process group; Windows uses verified-tree `taskkill /T /F`. Port release is allowed up to five seconds. Alive unverified state and corrupt tracking data are preserved for inspection; abandoned locks require manual review. Daemonized descendants may escape management. This is local development tooling, not a durable production process manager; production mode does not deploy. Interactive successful starts open the URL, except in CI/non-interactive sessions.

## Storage defaults and retention

Logs use `.logs/log_yyyy-mm-dd-hh-mm-ss-mmm.log`; archives use `.archive/log_yyyy-mm-dd-hh-mm-ss-mmm.zip`. Names use UTC and exclusive creation. One archive batch produces one ZIP even for a single file.

| Storage key | Default | Unit and interpretation |
|---|---|---|
| `maxLogs` | `50` | Integer 1–50; count of managed logs. |
| `maxArchiveBytes` | `100000000000` | Compressed bytes: 100 decimal GB; nonnegative safe integer. Zero requests pruning all eligible archives. |
| `maxArchiveAgeDays` | `30` | Nonnegative integer days; zero disables expiry. |
| `archivePruneOrder` | `oldest` | `oldest` or `largest`; largest ties break by oldest filename. |
| `minFreeBytes` | `1073741824` | 1 GiB; minimum free-space trigger component. |
| `targetFreeBytes` | `2147483648` | 2 GiB; recovery target component, at least the minimum. |
| `minFreePercent` | `5` | Percent of archive filesystem capacity, 0–100. |
| `targetFreePercent` | `10` | Percent, 0–100 and at least the minimum. |

Expiry uses creation time encoded in the filename, not access/modification time. Archives exactly at their lifetime or byte cap remain eligible to keep. Older-than-limit archives are considered first, then size/space pruning uses the configured order. Free-space retention triggers below the greater of minimum bytes/percentage and seeks the greater of target bytes/percentage. Set all four free-space values to zero to use only age/size retention.

Maintenance archives malformed and oldest excess logs together before removing them. Active log leases protect running writers; a new launch fails if active logs occupy the cap. `createLog` also refuses to exceed the configured cap. Maintenance runs before managed starts, every 30 seconds during a managed service, explicit archival and `maintain`. No idle daemon or system scheduled task is installed; external writers require cooperative maintenance.

Only canonical regular ZIP candidates in this project's `.archive/` are pruned. Protected/in-progress/new ZIPs are retained, including when a new ZIP alone exceeds the cap. Unrecognized filenames are outside the managed budget. Canonical-looking non-ZIP data is counted but preserved. If protection or non-ZIP data prevents compliance, the CLI warns and library results expose the remaining limits. A later maintenance pass can delete an earlier newly created archive. Retention permanently removes eligible recovery ZIPs; keep durable backups elsewhere.

Archives preserve relative UTF-8 paths, permissions and empty directories, stream compression with bounded buffers, and are decompressed to verify CRC32/SHA-256 before source removal. Sources are checked again before unlinking; directories are removed only when empty. Classic ZIP requires each file/archive below 4 GiB and at most 65534 entries. Root, Git metadata, runtime state, archive storage, links/junctions and special files cannot be selected. Stop other writers first: filesystem races can preserve sources or leave a partly removed batch backed by the verified ZIP. Compression is not encryption, and the helper is not a filesystem security sandbox.

## Storage library and local state

In a CommonJS package, `require("./moorkyz")` exports the embedded API. CLI execution itself also works in an ESM application. Serialize concurrent library calls in the application; CLI operations already use shared locks.

| Export | Purpose |
|---|---|
| `DEFAULTS`, `LOG_RE`, `ARCHIVE_RE` | Default policy and canonical-name expressions. |
| `storagePolicy(value)` | Validate/merge storage options. |
| `scopedPath(root, input, allowMissing)` | Resolve an in-scope path and reject linked components. |
| `ensureDirectories(root)` | Create/check the three managed runtime directories. |
| `timestamp(date)` | Canonical UTC name stem. |
| `validName(name, extension)` | Validate log/archive name and actual calendar timestamp. |
| `createLog(root, {policy})` | Exclusively create an empty canonical log within the cap. |
| `registerLog(root, filename, pid)` | Register a live writer; returns a release callback for after stream close. |
| `registeredLogPaths(root)` | Find live protected logs and remove dead leases. |
| `archivePaths(root, paths, options)` | Verified batch archive; `remove:false` keeps originals, but retention still applies to older ZIPs. |
| `maintainStorage(root, options)` | Rotate logs/prune archives; `reserveLogs:1` makes room before creating the next log. |
| `pruneArchives(root, policy, protectedPaths, measure, now)` | Apply archive age/size/free-space policy; injectable measurement/time support controlled tests. |
| `renderReadme(markdown)` | Render the supported Markdown subset to HTML. |

Storage calls can receive `policy` and protected paths. Archive results expose `filename`, `entries`, `pruned` and `retention`; maintenance returns `archived` and `pruned`. Retention includes `removed`, `bytes`, `maxBytes`, `overLimit`, `expiredRemaining`, `available`, `target`, `lowSpace`. Applications must inspect/report unsuccessful compliance and use the same policy across helpers.

| Local path/pattern | Purpose |
|---|---|
| `.moorkyz/<name>.json` | Supervisor token/PID, script/mode, URL/port, latest log and start time. |
| `.moorkyz/<name>.heartbeat.json` | Matching supervisor token/PID and heartbeat time. |
| `.moorkyz/<name>.preferences.json` | Saved port, configured URL and log path. |
| `.moorkyz/<name>.lock.json` | Per-project operation ownership. |
| `.moorkyz/__ports.lock.json`, `.moorkyz/__storage.lock.json` | Shared port/storage serialization. |
| `.moorkyz/log-leases/<log-name>.json` | Active writer PID/token protection. |
| `.moorkyz/archive-leases/<zip-name>.json` | Archive protection while source removal completes. |
| `.moorkyz/soft-copy/conflicts-<UTC>-<GUID>.json` | Local content-pair array; potentially sensitive destination content. |
| `.moorkyz/soft-copy/recovery-<UTC>-<GUID>.json` | Original bytes/times, expected hashes and copy ownership for explicit revert. |
| Recovery JSON plus `.lock` | Exclusive revert coordination. |

Leases are conservative about live/reused PIDs. Soft-copy recovery files remain local until deliberately removed; they are separate from ZIP retention. Do not upload them automatically or treat their embedded file text as instructions. Direct deletions by editors or unrelated programs cannot be intercepted; use explicit archival when recovery is required.

## Design collection and generated families

[designs/index.html](designs/index.html) is the final showcase. Each numbered directory contains a complete generated `README.html` edition and a distinct `landing.html`: twenty pairs, forty pages, plus the showcase. Pages open locally without a server or package installation; external links still need connectivity. Optional search/filter/preview/light interactions enhance direct navigation.

| Directory | Direction | Directory | Direction |
|---|---|---|---|
| `designs/01-aether/` | Orbital midnight | `designs/11-atlas/` | Topographic editorial |
| `designs/02-paper/` | Quiet ivory | `designs/12-signal/` | Cobalt/orange system |
| `designs/03-blueprint/` | Technical grid | `designs/13-nocturne/` | Violet waveform |
| `designs/04-prism/` | Pearlescent refraction | `designs/14-solstice/` | Warm sunlight |
| `designs/05-terminal/` | Monospaced workspace | `designs/15-vector/` | Connected geometry |
| `designs/06-dune/` | Warm sculpted earth | `designs/16-halo/` | Bright orbital calm |
| `designs/07-glacier/` | Airy ice blue | `designs/17-flux/` | Chromatic ribbon |
| `designs/08-mono/` | Strict monochrome | `designs/18-cabinet/` | Indexed archival paper |
| `designs/09-bloom/` | Lilac modularity | `designs/19-liminal/` | Dimensional architecture |
| `designs/10-obsidian/` | Copper restraint | `designs/20-continuum/` | Eclipse horizon |

`designs/catalog.mjs` defines directions and five compact documentation themes: `paper`, `glacier`, `mono`, `vector`, `cabinet`. `designs/build.mjs` generates the collection using the root renderer; `designs/documentation.mjs` implements themed document exports; `designs/search.mjs` builds the shared header search markup and the generated search index from the catalog, the README chapters and `designs/search-dictionary.json`. Shared assets live under `designs/assets/`: `designs.css` styles the expressive editions and landings, `showcase.css` the gallery, `documentation.css` compact documents and `search.css` the header search; `showcase.js` supplies gallery filter/preview behavior, `interactions.js` page interactions, `predictive-search.js` the local suggestion engine, `site-search.js` the search controller and the generated `search-index.js` its data. Copy numbered pages with their required relative assets and review links before exporting elsewhere.

After changing canonical README content, run `node moorkyz readme` and `node designs/build.mjs`. `node designs/build.mjs --check` checks freshness; `node designs/verify.mjs` checks collection structure/content; `verify-documentation.mjs` exercises themed exports with disposable outputs; `verify-predictive-search.mjs` checks suggestion ranking and the generated index. `designs/OpenAll.ps1` opens every recursive HTML page in the default browser; `-DryRun` lists instead.

For themed documents, use `node designs/build.mjs docs --theme paper --out html-docs README.md docs/INFRASTRUCTURE.md`. Source subdirectories are preserved; selected Markdown links are rewritten to selected HTML outputs. CSS is embedded, assets are not copied, and sources are unchanged. `--check` verifies without writes; `--overwrite` explicitly permits different selected outputs; `--dry-run` performs no source/config reads or writes. Paths remain inside the working root, links/junctions are refused, and the output cannot be the project root. Use `docs --help` for syntax.

The root renderer supports headings, paragraphs, links, inline code and fenced code; it is not a full CommonMark implementation. Lists/tables retain baseline text rendering. Automated design checks do not replace browser, keyboard, visual or accessibility review. If removing the optional collection from an adopted project, update its checkup and documentation references together.

## Template website

The repository publishes its own template library as a static website. This area is specific to the template; an adopted product keeps it only as a showcase or removes it together with its references.

| Path | Purpose |
|---|---|
| [index.html](index.html) | Generated catalog: twenty design cards with README and landing links, page-type and style filters; every link works without JavaScript. |
| [website/viewer.html](website/viewer.html) | Generated viewer: a desktop sidebar with search, template selector and page-type filter beside a live preview; previous/next controls on small screens; Left/Right arrow keys; **Full View**; selection kept in the URL. |
| [website/build.mjs](website/build.mjs) and [website/verify.mjs](website/verify.mjs) | Generate both pages from `designs/catalog.mjs`; verify freshness, coverage, links, filters and viewer navigation. |
| [website/deploy/](website/deploy/README.md) | Static container (Node 24 build stage, unprivileged Nginx on port 8080, `/healthz` and `/version.json`), publication allowlist, HTTP verifier and the Coolify, Hetzner and Cloudflare contract for `template.moorkyz.com`. |
| [template-website.yml](.github/workflows/template-website.yml) | CI for the catalog, viewer, packaging, a hardened real container and full maintenance. It holds no deployment credentials and does not deploy. |

Production activation, DNS, TLS and webhooks need an authorized operator and explicit owner approval. The package and its CI are not evidence of a live deployment; the deployment contract records the current status.

## Verification, agent workflow and present limits

Run `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause` with Node.js 24 on PATH. The runner executes immediate numbered checkups in filename order, each in a separate PowerShell process rooted here, prints RUN/PASS/FAIL and totals, and continues after failures. Normal interactive execution pauses at the end; `-NoPause` or redirected input prevents blocking. It writes terminal output, not log files.

Every checkup lives under `.template/maintenance/helpers/checkups/`:

| Checkup file | Exact scope |
|---|---|
| `01-runnables.ps1` | Discover runnable files, parse/syntax-check them, exercise no-op PowerShell/CLI entrypoints and the Windows selector wrapper. |
| `02-documentation.ps1` | Exact-case Markdown/HTML links, current names/layout, README freshness/escaping, icon paths, CI references, runtime ignore boundaries, and issue-form structure with the private-reporting link. |
| `03-project-types.ps1` | Preset JSON/ESM syntax; individual/combined preview/apply/rerun/conflict/path checks with source preservation. |
| `04-copilot-setup.ps1` | Settings results/exit codes, backups, existing guides, previews, reruns and completion in isolated project/profile fixtures. |
| `05-storage.ps1` | Policy validation, size/age boundaries, pruning order, live/protected archives, space/log warnings and audit report generation. |
| `06-design-collection.ps1` | Generated collection freshness/content/links/contrast and five-theme exports using disposable outputs; browser review remains separate. |
| `07-soft-copy.ps1` | Selected-file copies, conflict pairs, force previews/refusals, path boundaries and recovery, including Windows 8.3 short-path forms; Windows additionally exercises GUI controls. |
| `08-script-icons.ps1` | Branded Windows shortcuts in disposable fixtures on available PowerShell hosts: COM targets, arguments, working directories, icon integrity, source preservation, inventories, safe modes and conflict/link refusal; other platforms check the explicit unsupported-platform error. |
| `09-claim-template.ps1` | One-time adoption in disposable full copies: placeholder-free shipped config, refusals without changes, Git and manual provenance, clean audit trail and example-only work queue, commit-pinned evidence links, regenerated outputs, the adopted copy's own documentation check, broken-link reporting, unchanged reruns, the select-only menu and generated-config validation, on each available PowerShell host. |

Real-action checks use new disposable directories and isolated profiles. They do not run product package scripts or clean live runtime data. New checkups must preserve that boundary.

CI runs this maintenance entry on Ubuntu and Windows with PowerShell, Node from `.node-version`, pinned action revisions and `contents:read`. Checkout does not persist credentials; job timeout is ten minutes and newer runs cancel superseded runs for the same ref. Pushes, pull requests and manual dispatch trigger checks. Dependabot proposes weekly grouped Actions updates. A product must add its actual dependency ecosystem/checks separately after choosing its stack. The separate template-website workflow runs when `index.html`, `website/`, `designs/` or the workflow change.

Agents inspect the real Git state and task, implement only scoped changes, record checks as PASS/FAIL/NOT RUN/N/A, generate and fill an audit, review secrets/risks, and create a focused local commit when permitted. The scheduler coordinates one active queue item, dependencies and handoffs; it does not launch agents or grant external authority. The audit skill supports this workflow. Generated reports and self-audits are not independent security reviews.

After closing a claimed item, agents take the next eligible task within the owner's approved scope. They stop when that scope is complete, the owner pauses it or a concrete blocker remains. The scheduler's Agent Review column is optional and used only when the owner requests a review: record fixes and actual verification, then create or update a deduplicated follow-up with a backlink for every unresolved finding. A follow-up records remaining work; it does not grant permission to implement additional scope.

The template does not install a product, database, cloud resource, deployment destination, secret, system scheduler, editor extension or account connection. Selected tools can deliberately write settings, copy files, remove approved adoption paths, archive originals or permanently prune recovery ZIPs: choose the narrow tool and review its plan. Verify the actual product runtime, Docker build, health checks, credentials and deployment contract before adding production automation. Preserve existing user work and historical evidence when adopting or maintaining the template.

## Deliberate decisions to preserve

These choices were made on purpose; change them only with the owner, and record the change with the [decision template](docs/DECISION_TEMPLATE.md).

| Decision | Reason | Evidence |
|---|---|---|
| The root stays stack-neutral; stack files live in opt-in project-type packs | Every project can adopt the baseline without inheriting another product's runtime | [Stack-neutral baseline](.audits/2026-10-23T18-30-00Z-stack-neutral-baseline-and-readm-removal.md) |
| `moorkyz` stays one dependency-free file at the repository root | `node moorkyz` works everywhere; explicit owner exception to the `.template/` layout | [Root CLI exception](.audits/2026-10-23T20-02-22Z-copilot-setup-results-and-root-launcher.md) |
| Reusable tooling lives in `.template/<tool>/` with its README, entrypoints and `helpers/` | Separates template tooling from project-owned code; the layout is checked | [Tooling separation](.audits/2026-10-23T20-31-27Z-separate-reusable-template-tooling.md), [current names](.audits/2026-10-23T21-00-02Z-rename-template-tooling-and-copilot-settings.md) |
| Every PowerShell entrypoint has a side-effect-free `-DryRun`; checkups are read-only and act only in disposable fixtures | Tools that copy, delete or change settings can be verified safely | [Maintenance checkups](.audits/2026-10-23T19-19-45Z-replace-example-tests-with-safe-maintenance-checkups.md) |
| Project-type selection only adds files and never deletes starters | Owner direction: "add as many as you want, no deletion" | [Additive selection](.audits/2026-10-23T18-59-05Z-additive-project-type-selection-menu.md) |
| Recoverable deletion uses verified ZIP archives, not a trash folder; `.logs/`, `.archive/` and `.moorkyz/` stay ignored; audits stay tracked in `.audits/` | Bounded storage with explicit retention, and evidence that travels with the code | [Archive retention and audit history](.audits/2026-10-23T21-14-08Z-archive-retention-and-hidden-audit-history.md) |
| Soft copy preserves differing files unless forced, and can revert from local snapshots | Existing work is never overwritten silently | [Soft copy](.audits/2026-10-23T21-33-23Z-soft-copy-template-files-with-lightweight-gui.md), [revert](.audits/2026-10-23T21-57-57Z-revert-template-copies-from-saved-originals.md) |
| Adopted projects start their own audit trail with template provenance; the adoption config ships without placeholder text and creation stays configuration-driven | Owner decisions of 2026-10-29: template history stays in the template, the project records repository, version and commit, and no references to removed paths remain | [Adoption decisions](.audits/2026-10-29T02-10-54Z-adoption-audit-trail-and-typed-setup-defaults.md) |
| The public website presents the templates, not tools or services | Owner direction for Moorkyz Templates | [Template-only branding](.audits/2026-10-25T12-51-14Z-template-only-showcase-branding.md) |
| Work follows four phases with ordered Clean Up gates; passing checks never imply approval | Honest evidence and human control of external actions | [Work phases](.audits/2026-10-25T14-48-38Z-clarify-work-phases-and-cleanup-quality-gates.md) |
| Script icons are shortcuts; scripts and executables are never modified | Windows cannot embed icons in scripts, and signatures stay intact | [Script icons](.audits/2026-10-25T15-54-22Z-add-safe-moorkyz-script-icons.md) |

## Known limitations and pitfalls

- **Node version.** The checks require Node.js 24 and `01-runnables.ps1` refuses other versions. Put Node 24 first on `PATH` when the system default differs.
- **Long, interactive checks.** The full runner takes several minutes; on Windows, `07-soft-copy.ps1` drives real windows inside disposable fixtures. Use `-NoPause` in automation and do not interact with the test windows.
- **Windows short paths.** GitHub's Windows runners use an 8.3 short `TEMP` path (`C:\Users\RUNNER~1\...`). `[IO.Path]::GetFullPath` expands short names; PowerShell provider paths and `Split-Path` do not. Normalize both sides before comparing paths in scripts and checks.
- **README rendering.** `node moorkyz readme`, the README editions and themed exports render headings, paragraphs, links and code; tables and lists appear as plain text.
- **Adoption config.** `setup.config.json` ships with empty names and empty lists, so a first run lists what to fill in; see the [adoption route](#choose-the-appropriate-adoption-route). Copies without the template's Git history need `-TemplateCommit`.
- **Removing folders.** The link check covers every Markdown and HTML file, including retained audits and README editions, and adoption refuses to remove a path that remaining files still link to or mention. Remove an area only together with every reference and its checkup or workflow; otherwise keep it.
- **Copilot setup scope.** The default `-Scope Both` also changes your user-level VS Code settings: default model, autopilot, notifications and terminal command auto-approval with deny rules. Use `-Scope Project` for repository-only changes and preview with `-WhatIf`.
- **Coordination.** The queue is text, not a lock, and claims can go stale. Check `git status`, file ages and the owner before touching files that someone else claimed.
- **Sensitive recovery data.** Soft-copy reports and recovery snapshots in `.moorkyz/soft-copy/` contain file contents. ZIP archives are compressed, not encrypted, and retention deletes them permanently.
- **No product runtime.** `moorkyz start`, `verify`, `install` and the other package commands need a Node `package.json`; the template root has none. Without a declaration the CLI assumes pnpm, while the `node` preset declares npm: choose deliberately.
- **Line endings.** Git stores text with LF; `.cmd` and `.bat` keep CRLF. Git's CRLF conversion warnings on Windows are expected.
- **Scope of the checks.** Maintenance is not a security review, product test suite, accessibility audit or deployment check. Browser, screen-reader and production verification remain separate.
