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
With an empty list, an interactive claim offers this same menu through
`SetProjectType.ps1 -SelectOnly`, which only returns the confirmed names (none when
quit) and copies nothing; the claim validates and saves them in its configuration.
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

## Complete the selected presets

These are the remaining project decisions, not missing template runtime code.
Complete only the rows for types actually selected. Keep real credentials out
of copied files, examples and Git history.

| Type | Required review before product use |
|---|---|
| `node` | Replace `moorkyz-project`, review the Node engine and exact package-manager version, generate one lockfile and add the product's real scripts. Keep the maintenance scripts only if the corresponding tooling is retained. |
| `web` | Replace the manifest name and icons with product branding. Set `start_url`, `scope`, theme and display behavior only for the real deployment path; test installed-browser behavior separately. |
| `docker` | Supply a reviewed `BASE_IMAGE`, preferably digest-pinned. Define actual build/runtime stages, a non-root user, start command and health check. Review the build context and ignore rules before building; do not infer a runtime from the template. |
| `typescript` | Install the reviewed compiler, supply actual source files and required runtime types, and adjust include paths/module settings to the application. The current preset checks types without emitting files; it does not build an application. |
| `eslint` | Install ESLint and review the intentionally small built-in rule set. Configure actual browser/Node globals and any framework or TypeScript parser/plugins explicitly. |
| `prettier` | Install the formatter, review the shared two-space/LF conventions and ignores, then check the intended source files before applying formatting. |
| `stylelint` | Install both Stylelint and `stylelint-config-standard`; add processors or syntax configuration only for the actual stylesheet language. |
| `markdownlint` | Install `markdownlint-cli` and review rules/ignores. Long-line and inline-HTML rules are disabled intentionally for the existing documentation style. |
| `vscode` | Review extension publishers and the workspace trust model. Recommendations do not install extensions, grant tool permissions or establish account access. |

The optional `moorkyz.config.example.json` illustrates two local projects and
storage defaults. Copy and edit it only when those application directories and
scripts exist; selecting `node` alone does not create them. Do not rename this
example to live configuration merely to make lifecycle commands appear ready.

### Preset references

- [npm package manifest](https://docs.npmjs.com/cli/v11/configuring-npm/package-json/)
- [Web app manifest](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Manifest)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [TypeScript compiler options](https://www.typescriptlang.org/tsconfig/)
- [ESLint configuration](https://eslint.org/docs/latest/use/configure/configuration-files)
- [Prettier configuration](https://prettier.io/docs/configuration)
- [Stylelint configuration](https://stylelint.io/user-guide/configure/)
- [markdownlint rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md)
- [VS Code extension recommendations](https://code.visualstudio.com/docs/configure/extensions/extension-marketplace#_workspace-recommended-extensions)

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
