# Moorkyz Template

Reusable repository baseline for Moorkyz projects: a portable local CLI, recoverable storage, agent workflow, documentation and CI. No application, database, Docker runtime or deployment target is chosen.

## Get started

Use Node.js 24 LTS (pinned in `.node-version`) and PowerShell for the shared template tooling, not necessarily the product runtime. The baseline is stack-neutral: no package manager, manifest or lockfile is required.

```sh
node --check moorkyz
node moorkyz help
node moorkyz doctor
```

Run `.\.template\maintenance\RunCheckups.ps1` to check the template tools and documentation without applying changes. It runs each checkup, logs results in the terminal and ends with **Press any key to exit...**. Use `-NoPause` for automation. See the [maintenance guide](.template/maintenance/README.md).

## Start a new project

Copy the template, then use [Claim Template (use once)](.template/claim-template/README.md) for one-time adoption. Fill in [.template/claim-template/helpers/setup.config.json](.template/claim-template/helpers/setup.config.json): `projectName` (lowercase, e.g. `my-app`), `displayName`, `githubOwner`, the `projectTypes` to add and the template-only paths to `remove`. Set `projectTypes` to `[]` for no stack. For example, `["node", "web"]` selects Node tooling and browser assets without Docker. Only the explicitly listed `remove` paths are deleted; retain maintenance checkups and never use existing runtime data for verification.

Run [CreateProject.ps1](.template/claim-template/CreateProject.ps1) (right-click, Run with PowerShell, or `powershell -ExecutionPolicy Bypass -File ".template\claim-template\CreateProject.ps1"`); add `-WhatIf` to preview. Until the config is valid it lists what to fill in and changes nothing. It then shows its plan and asks before it copies selected project types, permanently removes the listed paths, fills in the project name and owner, sets the README title and regenerates `README.html`. It always ends with "Press any key to continue", and rerunning is safe. Add `".template/claim-template"` to `remove` to delete only the adoption tool afterwards. The former `overlay` config key is replaced by `projectTypes`.

Then document the stack and add its manifest, scripts and lockfile. A missing application fails explicitly instead of starting a fabricated server.

## Layout

Reusable template tooling lives in [.template/](.template/README.md), separate from application code and project-owned tooling. Each tool keeps its entrypoint(s) and README together, with supporting files under `helpers/`. The self-contained [moorkyz](moorkyz) CLI is the exception and must stay at the repository root. Check the catalog when a task may need an existing tool; read its README and use it when appropriate, rather than running every tool automatically.

[moorkyz](moorkyz) remains a self-contained CLI and storage library with no third-party packages. Run `node moorkyz <command>` on any platform, or `./moorkyz <command>` on Unix after `chmod +x moorkyz`. See the [CLI guide](docs/INFRASTRUCTURE.md).

[AGENTS.md](AGENTS.md) is the agent contract and [AGENT_SCHEDULER.md](AGENT_SCHEDULER.md) the serial work queue. `.agents/skills/` holds portable agent skills such as the [task audit](.agents/skills/task-audit/SKILL.md). [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md) and [dependency maintenance](docs/dependency-security.md) cover contributions, private vulnerability reports and updates. Task reports live in [audits](.audits/README.md).

For other repositories, [Copilot settings](.template/copilot-settings/README.md) includes a portable [agent template](.template/copilot-settings/helpers/AGENTS.template.md); it creates a guide only when none exists and preserves existing project instructions. Setup ends with **ALL SET** or **FAILED** with a list of failed steps, then waits for a key; use `-NoPause` for automation. Previews are labeled **PREVIEW ONLY**, not success. This confirms local configuration, not Copilot sign-in or model availability.

Project-specific files live in [.template/project-types/helpers/types/](.template/project-types/helpers/types/), grouped by type at root-relative paths; see the [project types guide](.template/project-types/README.md):

| Type | Contents |
|---|---|
| `node` | npm manifest and optional multi-project CLI configuration |
| `web` | Browser icons and web manifest in `public/` |
| `docker` | Optional Dockerfile starter and Docker ignore rules |
| `typescript` | Strict TypeScript checks for Node-style modules |
| `eslint` | JavaScript lint rules |
| `prettier` | Formatter configuration and ignores |
| `stylelint` | Standard CSS lint configuration |
| `markdownlint` | Markdown lint configuration and ignores |
| `vscode` | Optional editor extension recommendations |

On Windows, double-click [SetProjectType.cmd](.template/project-types/SetProjectType.cmd) for the numbered multi-select menu; [SetProjectType.ps1](.template/project-types/SetProjectType.ps1) remains the PowerShell implementation. Types appear in two columns with one controls row below. Up/Down moves, Space toggles types, and Enter reviews the selection for explicit Y confirmation. Type a number then Space/Enter to toggle it; Esc/Q quits the menu. Or preview with `.\.template\project-types\SetProjectType.cmd node typescript eslint prettier -WhatIf`, then rerun without `-WhatIf` to add them. Selected files are copied, identical existing files are left unchanged, and different existing files, cross-type conflicts and links stop the whole selection before any copies. The entire `.template/project-types/` folder stays intact: nothing is deleted or archived, and you can add more types later. Nothing automatically enables all types.

Tool presets add configuration only: no packages, extensions or application runtimes are installed. Review and install the selected tools separately in the adopted project; see the [package checklist](.template/project-types/README.md#tool-packages). Docker is packaging, not the current project type: its starter is not deployable until a real application and deployment contract exist.

Shared tooling in `.template/`, the root Node pin and tooling CI support every template type. Package-script/lifecycle commands are Node-specific; storage, audits and README generation do not require a Node application. CI remains under `.github/workflows/` for platform discovery.

Root `.logs/`, `.archive/` and `.moorkyz/` are local and ignored; the CLI creates only these runtime folders. Trash staging has been removed: use `node moorkyz archive <path>` to archive selected data directly. Dot prefixes do not set Windows' Hidden attribute. Reports in [.audits/](.audits/README.md) remain tracked; their [template](docs/AUDIT_TEMPLATE.md) lives directly in `docs/`.

## Starts, logs and archives

`node moorkyz start` and `restart` stop only their own verified instance, wait for its port and launch a fresh process with a new log on the same configured port. A busy port fails instead of switching ports or killing another process.

Logs are named `.logs/log_yyyy-mm-dd-hh-mm-ss-mmm.log` (UTC), capped at 50. Managed ZIP archives default to a **100 GB (100,000,000,000 compressed bytes)** total cap and a **30-day** lifetime. Set `storage.maxArchiveBytes`, `storage.maxArchiveAgeDays` (`0` disables expiry) and `storage.archivePruneOrder` (`"oldest"` or `"largest"`) in `moorkyz.config.json`. Expired archives are deleted first; if still over the cap, the chosen order determines what is deleted next.

Maintenance compresses malformed/oldest excess logs into one verified `.archive/log_yyyy-mm-dd-hh-mm-ss-mmm.zip` per pass. It runs before managed starts, every 30 seconds while managed services run, and explicitly with `node moorkyz maintain`. The existing CLI enforces retention; no script belongs inside the archive directory. When no service is running, cleanup waits for the next CLI operation or an independently configured scheduler. Classic ZIP size limits fail clearly while preserving sources.

The existing low-disk-space safeguard can prune earlier using the same chosen order (defaults: trigger below 1 GiB or 5% free, target both 2 GiB and 10% free). Protected/new ZIPs are not deleted during their creation pass; unmet limits produce explicit warnings. Retention permanently deletes archives, not their original source paths. Keep durable backups elsewhere. See the [storage guide](docs/INFRASTRUCTURE.md) for configuration and safety limits.

## Verification

CI runs `.template/maintenance/RunCheckups.ps1 -NoPause` with PowerShell on Linux and Windows using the pinned Node version, pinned actions and a read-only token. Checkups cover runnable syntax, no-op entrypoints, documentation links/current names, icons/CI references, `README.html` freshness and preset configuration syntax; the bundled example tests have been removed. Selector, Copilot setup and storage/audit action checks run only in newly created disposable copies, with isolated user profiles for setup, preserving existing user files and source bytes. Storage checks exercise byte/age boundaries, pruning order, archive protections, warnings and report generation. No application, live-repository setup, live storage cleanup or package script is executed. All PowerShell scripts accept `-DryRun`; the CLI accepts `--dry-run`, and the CMD selector forwards `-DryRun`. These no-op modes do not validate real action behavior; use the setup scripts' existing `-WhatIf` for input-aware previews. Regenerate `README.html` with `node moorkyz readme`.
