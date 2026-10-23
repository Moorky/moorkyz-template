# Claim Template (use once)

Turns a copy of this template into a new project. Run it once in the new copy,
never in the template repository itself.

## When to use

Use this tool only when adopting a template copy for a real project. Consult the
[template-tool catalog](../README.md) for later maintenance, presets and editor setup;
these tools may be useful at different stages, not all at once. Review the
configuration and use `-WhatIf` before authorizing changes.

## 1. Fill in [helpers/setup.config.json](helpers/setup.config.json)

| Setting | Meaning |
|---|---|
| `projectName` | Repository/package name: lowercase letters, digits and single hyphens, e.g. `my-app`. Replaces the template placeholder everywhere. |
| `displayName` | Human-readable title for `README.md`, e.g. `My App`. |
| `githubOwner` | GitHub user or organization that owns the repository. |
| `projectTypes` | Starters to copy from `.template/project-types/helpers/types/`, e.g. `["node", "web"]`. Leave empty for none; more can be added later. |
| `remove` | Explicit template-only paths to delete permanently. Nothing unlisted is removed. Retain maintenance checkups and never use existing runtime data as a test fixture. |

The script refuses to change anything until `projectName` and `displayName` are
set and every value is valid; it lists what is missing.

See the [preset guide](../project-types/README.md) for all available types and
tool-package requirements. On Windows, [SetProjectType.cmd](../project-types/SetProjectType.cmd)
also lets you select and add more types later without removing any starters.

## 2. Run `CreateProject.ps1`

Right-click it and choose Run with PowerShell, or:

```powershell
powershell -ExecutionPolicy Bypass -File ".template\claim-template\CreateProject.ps1" -WhatIf
powershell -ExecutionPolicy Bypass -File ".template\claim-template\CreateProject.ps1"
```

For a no-op entrypoint check without valid setup configuration or any prompts,
pass `-DryRun`. See [maintenance checkups](../maintenance/README.md).

`-WhatIf` only previews. Otherwise the script shows its plan and asks before it:

1. copies the selected project types to the repository root, never overwriting different files;
2. deletes the `remove` paths;
3. replaces the project placeholder and template GitHub owner in text files (`audits/` history and this folder stay unchanged);
4. sets the README title and regenerates `README.html` (needs Node.js).

It always ends with "Press any key to continue". This is a one-time adoption
tool, not routine maintenance; rerunning is safe if adoption needs to be retried.
Add `.template/claim-template` to `remove` to delete the setup files when you are done.
