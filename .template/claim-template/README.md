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
| `projectName` | Repository/package name: lowercase letters, digits and single hyphens, e.g. `my-app`. Replaces the template placeholder everywhere. Ships empty. |
| `displayName` | Human-readable title for `README.md`, e.g. `My App`. Ships empty. |
| `githubOwner` | GitHub user or organization that owns the repository. |
| `projectTypes` | JSON array of starters to copy from `.template/project-types/helpers/types/`, e.g. `["node", "web"]`. Ships as `[]` (none); more can be added later. |
| `remove` | JSON array of template-only paths to delete permanently. Nothing unlisted is removed. A path is refused while a remaining file links to, mentions or names it (Markdown, HTML, CSS, scripts, JSON, YAML, PowerShell, batch files and Dockerfiles are checked), and `.audits` cannot be removed. Retain maintenance checkups and never use existing runtime data as a test fixture. |

The script refuses to change anything until `projectName` and `displayName` are
set and every value is valid; it lists what is missing. Lists must be JSON arrays:
placeholder text in a typed field is rejected.

With `projectTypes` empty, an interactive run asks whether to choose types in the
existing project-type menu (`SetProjectType.ps1 -SelectOnly`): select several or
none. The choice is validated like a hand-written configuration and saved to
`setup.config.json` when you confirm the plan, so creation stays
configuration-driven. `-Yes`, `-WhatIf` and redirected input never prompt.

See the [preset guide](../project-types/README.md) for all available types and
tool-package requirements. On Windows, [SetProjectType.cmd](../project-types/SetProjectType.cmd)
also lets you select and add more types later without removing any starters.

## 2. Run `CreateProject.ps1`

Right-click it and choose Run with PowerShell, or:

```powershell
powershell -ExecutionPolicy Bypass -File ".template\claim-template\CreateProject.ps1" -WhatIf
powershell -ExecutionPolicy Bypass -File ".template\claim-template\CreateProject.ps1"
```

The first adoption finds the template commit the copy started from and verifies it
in the [template repository](https://github.com/Moorky/moorkyz-template); it never
guesses. Git and network access are needed for this one step:

| Copy | How the commit is found |
|---|---|
| Clone of the template, also after changing `origin` or adding commits | The newest template commit in the copy's Git history |
| Repository created with GitHub's *Use this template* | The template commit whose files equal the copy's first commit |
| ZIP download from GitHub | The commit GitHub writes into `helpers/template-commit.txt` |
| Anything else | Pass `-TemplateCommit <full SHA>`; it must exist in the template repository |

The version is the release tag (for example `v1.0.0`) or, for other commits, the
development build with its distance from the last release. Node.js comes from the
[run tool](../run/README.md), which may offer a verified download once. For a no-op
entrypoint check without valid setup configuration or any prompts, pass `-DryRun`.
See [maintenance checkups](../maintenance/README.md).

`-WhatIf` only previews. Otherwise the script shows its plan and asks before it:

1. copies the selected project types to the repository root, never overwriting different files;
2. deletes the `remove` paths;
3. on the first adoption, starts the project's own audit trail: the template's
   audit records are not inherited, the request ledger and work queue keep only
   their example rows, links to template audit records point to the template commit
   on GitHub, and `.audits/` gets a clean README plus an adoption record with the
   template repository, version, commit SHA and the results below;
4. replaces the project placeholder and template GitHub owner in text files
   (`.audits/`, commit-pinned template links and this folder stay unchanged);
5. sets the README title and regenerates `README.html` and the design README
   editions;
6. validates links and literal paths in docs, configuration and source files.
   Broken references are listed and the run ends with an error; fix them and run
   the script again. Until a run passes, each rerun records its result in the
   adoption record, so the committed record matches the committed files.

It always ends with "Press any key to continue". This is a one-time adoption
tool, not routine maintenance; rerunning is safe if adoption needs to be retried.
Reruns leave an existing project audit trail and work queue unchanged. Keep this
folder after adoption: guides and the README editions link to it, so deleting it
alone fails the reference checks. The [template integrity checkup](../maintenance/helpers/checkups/09-template-integrity.ps1)
exercises all of this in disposable copies, against a disposable upstream.
