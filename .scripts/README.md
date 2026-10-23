# Repository scripts

Check this catalog when a task may need existing tooling. Read the relevant
tool's README and use it when it fits; do not run every script automatically.
Run commands from the repository root unless a tool's README says otherwise.

| Tool | Entry script(s) | When to use |
|---|---|---|
| [Moorkyz CLI](../docs/INFRASTRUCTURE.md) | [moorkyz](../moorkyz) | CLI help, README generation, task audits, or explicitly authorized project/storage operations |
| [Maintenance](maintenance/README.md) | [RunCheckups.ps1](maintenance/RunCheckups.ps1) | Verify runnable syntax, safe modes, documentation and presets |
| [Project types](project-types/README.md) | [SetProjectType.cmd](project-types/SetProjectType.cmd), [SetProjectType.ps1](project-types/SetProjectType.ps1) | Preview or add explicitly selected stack/tooling presets |
| [Claim Template (use once)](claim-template/README.md) | [CreateProject.ps1](claim-template/CreateProject.ps1) | One-time adoption of a template copy for a real project; never apply in the template itself |
| [Copilot setup](copilot/README.md) | [Setup-CopilotProject.ps1](copilot/Setup-CopilotProject.ps1) | Preview or configure reviewed VS Code/Copilot settings for a specified project or user |

Every tool folder keeps its entry script(s) and `README.md` at that folder's root.
Supporting files live under `helpers/`: maintenance checkups, project-type
starters and setup configuration/templates. By explicit owner instruction,
the self-contained `moorkyz` CLI stays at the repository root with the root
README; it has no helper files and is the only root-script exception.

PowerShell entrypoints accept `-DryRun`; the CLI accepts `--dry-run`.
These modes perform no actions or configuration validation. Use `-WhatIf`
where supported for an input-aware preview. Get explicit approval for settings
changes, destructive actions, publication or other effects outside the task.
Tests of real actions must use disposable fixtures, never existing project data.

`.scripts/` is versioned tooling, not ignored runtime storage. A dot prefix does
not set the Windows Hidden attribute. GitHub workflows and agent-discovery
files remain in their platform-required locations and point here when needed.
