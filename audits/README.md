# Audits

One report per task, named `YYYY-MM-DDTHH-MM-SSZ-task-slug.md` (UTC). Create a
draft from [the template](../docs/audits/AUDIT-TEMPLATE.md) with
`node moorkyz audit "task title"`, then record scope, changed files, actual
validation results, security review, remaining blockers and human-review status.
A generated draft is not verification. Commit it with the task's changes.

## Current names and locations

Historical reports preserve their original commands, filenames and observed test
results; those are not current setup instructions. Links point to current files.
Use the [template-tool catalog](../.template-tools/README.md) when a task needs existing tooling;
read the relevant guide and use that tool only when appropriate.

| Historical reference | Current reference |
|---|---|
| Former `.scripts/` shared parent | [.template-tools/](../.template-tools/README.md) is reusable template tooling, separate from project-owned code; see [rename audit](2026-10-23T20-31-27Z-separate-reusable-template-tooling.md) |
| `overlay/unpack.ps1` or `.projecttypes/unpack.ps1` | [SetProjectType.cmd](../.template-tools/project-types/SetProjectType.cmd) on Windows; [SetProjectType.ps1](../.template-tools/project-types/SetProjectType.ps1) is the implementation; selected files are copied and starters retained |
| `.optional/root/` or `overlay/` starters | [.template-tools/project-types/helpers/types/](../.template-tools/project-types/helpers/types/), grouped by core type and optional tooling preset; see the [project types guide](../.template-tools/project-types/README.md) |
| Root `package.json` | [.template-tools/project-types/helpers/types/node/package.json](../.template-tools/project-types/helpers/types/node/package.json) |
| Root `moorkyz.config.example.json` | [.template-tools/project-types/helpers/types/node/moorkyz.config.example.json](../.template-tools/project-types/helpers/types/node/moorkyz.config.example.json) |
| Root `public/` | [.template-tools/project-types/helpers/types/web/public/](../.template-tools/project-types/helpers/types/web/public/) |
| Root `Dockerfile` / `.dockerignore` | [.template-tools/project-types/helpers/types/docker/](../.template-tools/project-types/helpers/types/docker/) |
| `createproject.ps1` and former `setups/Make This Yours/` / `.scripts/make-this-yours/` folder | [CreateProject.ps1](../.template-tools/claim-template/CreateProject.ps1) in [Claim Template (use once)](../.template-tools/claim-template/README.md); exact case matters on Linux |
| `READM.html` | Removed duplicate; [README.html](../README.html) is the generated edition |
| Root `package-lock.json` | Removed with the dependency-free root manifest; no baseline npm install step |
| Bundled `tests/`, including `overlay.test.cjs`, `template.test.cjs` and `project-type-menu.test.cjs` | Removed by a later owner request; current checks run through [.template-tools/maintenance/RunCheckups.ps1](../.template-tools/maintenance/RunCheckups.ps1) |

## Retired test suite

The bundled `tests/` suite was removed when maintenance checkups were introduced.
Historical references retain their original results; the removed files are not
current verification instructions. The new [maintenance checkups](../.template-tools/maintenance/README.md)
cover runnable syntax, safe no-op entrypoints, documentation and preset selection
in disposable fixtures; they do not replace the former lifecycle/storage action
coverage. Existing repository data remains read-only.

Project layout reports:

- [Separate reusable template tooling](2026-10-23T20-31-27Z-separate-reusable-template-tooling.md).
- [Update references for nested project types](2026-10-23T19-16-43Z-update-references-for-nested-project-types.md).
- [Correct references and add popular selector presets](2026-10-23T19-11-19Z-correct-references-and-add-popular-selector-presets.md).
- [Separate project-specific starter types](2026-10-23T18-54-54Z-separate-project-specific-starter-types.md).
- [Additive project type selection menu](2026-10-23T18-59-05Z-additive-project-type-selection-menu.md).

Storage reports:

- [Hidden runtime folders and 100 GB trash cap](2026-10-23T18-24-37Z-hidden-runtime-folders-and-100-gb-trash-cap.md).
- [Log naming, capped retention and compressed project archives](2026-10-23T18-11-13Z-logs-archive-retention.md).
