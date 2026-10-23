# Project types

## When to use

Use this tool when a project needs explicitly selected stack/tooling starters,
including later additions. Consult the [template-tool catalog](../README.md), read this
guide and preview with `-WhatIf` first. Never select every type just because the
tool is available.

Opt-in starters in [helpers/types/](helpers/types/), grouped by what they are for. Each type mirrors
its destination paths in the repository root. Types can be combined; none is selected by default.
This directory is versioned, not an ignored runtime folder.

| Type | Files | Use |
|---|---|---|
| `node` | [package.json](helpers/types/node/package.json), [moorkyz.config.example.json](helpers/types/node/moorkyz.config.example.json) | Node.js/npm project tooling and an optional multi-project script configuration |
| `web` | [public/](helpers/types/web/public/) | Existing browser icons and web manifest; independent of the server language |
| `docker` | [Dockerfile](helpers/types/docker/Dockerfile), [.dockerignore](helpers/types/docker/.dockerignore) | Optional container packaging; not a runtime or a complete deployment |
| `typescript` | [tsconfig.json](helpers/types/typescript/tsconfig.json) | Strict, no-output TypeScript checks with modern Node module resolution |
| `eslint` | [eslint.config.mjs](helpers/types/eslint/eslint.config.mjs) | JavaScript linting with a small set of built-in rules |
| `prettier` | [.prettierrc.json](helpers/types/prettier/.prettierrc.json), [.prettierignore](helpers/types/prettier/.prettierignore) | Consistent formatting without touching generated HTML or local data |
| `stylelint` | [stylelint.config.mjs](helpers/types/stylelint/stylelint.config.mjs) | Standard CSS linting |
| `markdownlint` | [.markdownlint.json](helpers/types/markdownlint/.markdownlint.json), [.markdownlintignore](helpers/types/markdownlint/.markdownlintignore) | Markdown linting with long lines and inline HTML allowed |
| `vscode` | [.vscode/extensions.json](helpers/types/vscode/.vscode/extensions.json) | Optional editor extension recommendations; nothing installs automatically |

The current template has no application stack. Docker can package Node, Python,
.NET or other applications; selecting Docker does not select a language.
Add other folders under `helpers/types/` only when their real stack and conventions are known.

## Select and add

On Windows, double-click [SetProjectType.cmd](SetProjectType.cmd), or run it
without arguments, for the numbered menu. It launches the PowerShell selector
beside it and pauses afterwards so results stay visible. Types appear in two
columns, with a single controls row below the list. With arguments it
returns the selector's exit code without pausing, so automation still works.

```bat
.\.template\project-types\SetProjectType.cmd
.\.template\project-types\SetProjectType.cmd node typescript eslint prettier -WhatIf
```

[SetProjectType.ps1](SetProjectType.ps1) is the implementation and remains
available directly on Windows or other platforms with PowerShell:

```powershell
.\.template\project-types\SetProjectType.ps1
```

- Up/Down moves the focus; Space toggles as many types as you want.
- Type a number, then Space or Enter to toggle that type (including numbers above 9).
- Enter reviews the selection. If none is checked, it reviews the focused type.
- Only **Y** in the confirmation adds files. N, Enter, Space or Esc returns to the menu;
  Q quits. Esc or Q from the menu quits without adding files.

Or preview/add explicitly named types for scripts and setup (no keyboard menu):

```powershell
.\.template\project-types\SetProjectType.ps1 node web -WhatIf
.\.template\project-types\SetProjectType.ps1 node web
```

The selector validates every selected type before copying anything, rejects
conflicting targets and links, and never overwrites different existing files.
Identical files are left unchanged, so you can rerun it or add more types later.
**All starters and this entire folder remain intact. Nothing is deleted, moved
or archived by the selector.** Filesystem errors during copying can still leave
partial additions; resolve the reported error before retrying.

Alternatively set `"projectTypes": ["node", "web"]` in
[setup.config.json](../claim-template/helpers/setup.config.json) and run
[CreateProject.ps1](../claim-template/CreateProject.ps1) when claiming a template copy.
The old `overlay` setting is no longer accepted.

## Tool packages

These are configuration presets, not package installers or application
scaffolds. Select as many as fit the project, review the preview and confirmation,
then install only the tools you actually chose using the product's package manager.
There is no automatic download, manifest merge, dependency change or script execution.

| Preset | Packages to review and install | Example check after local installation |
|---|---|---|
| `typescript` | `typescript` | `npx --no-install tsc --noEmit` |
| `eslint` | `eslint` | `npx --no-install eslint .` |
| `prettier` | `prettier` | `npx --no-install prettier . --check` |
| `stylelint` | `stylelint`, `stylelint-config-standard` | `npx --no-install stylelint "**/*.css"` |
| `markdownlint` | `markdownlint-cli` | `npx --no-install markdownlint "**/*.md"` |
| `vscode` | No npm package | Review extension recommendations in VS Code |

The commands above assume an adopted npm project with the reviewed tools already
installed; `--no-install` prevents an on-demand download. Pin tool versions and
commit the authoritative lockfile. TypeScript's preset targets Node-style
modules; adjust it for a real browser/bundler stack. ESLint's preset handles
JavaScript only; TypeScript linting needs an explicitly configured parser/plugin.
The VS Code preset does not install extensions or change editor settings.

For Node projects, review the package manager and add the product's real scripts.
Only select `docker` after documenting the runtime, build and deployment
contract. Its existing Dockerfile is an unfinished starter: it still needs a
pinned base image, non-root runtime, real start command and health check.
It is not a deployable application and no deployment workflow is supplied.

## Shared tooling is not a product stack

The [moorkyz](../../moorkyz) CLI, [maintenance checkups](../maintenance/README.md),
[.node-version](../../.node-version) and
[tooling CI](../../.github/workflows/project-tooling.yml) use Node.js 24 to verify
the template itself, including for non-Node products. No root package manifest
or application dependencies are required. CLI storage, audit and README commands
work without a Node application; its package-script/lifecycle commands require
a configured Node project and are not universal application runners.

All PowerShell scripts and the CMD selector accept `-DryRun` for a no-op
entrypoint check without menus, copies or changes. Use the existing `-WhatIf`
with named types for a detailed, input-aware preview. The Node starter's
`npm test` and `npm run verify` invoke the maintenance runner and require
PowerShell 7 (`pwsh`).
