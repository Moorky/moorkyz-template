# Maintenance checkups

## When to use

Use this tool to verify repository scripts, documentation and presets before
completing a task. Consult the [template-tool catalog](../README.md) for other tools that
may fit the task; do not invoke unrelated tools automatically. Supporting
checkups live under `helpers/checkups/`, not alongside the entry script.

Run [RunCheckups.ps1](RunCheckups.ps1) from any working directory:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.template\maintenance\RunCheckups.ps1
pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause
```

Windows PowerShell 5.1 and PowerShell 7 are supported. Use PowerShell 7 on Linux.
Node.js 24 LTS must be on PATH; no npm install or application is required.
Right-click the runner and choose **Run with PowerShell** for an interactive run.

The runner executes every immediate `*.ps1` file in [helpers/checkups/](helpers/checkups/) in
filename order, in a separate PowerShell process rooted at the repository.
It streams each checkup's output, logs RUN/PASS/FAIL, continues after failures
and prints a total. Exit code 0 means every checkup passed; 1 means a checkup or
the runner failed. A missing or empty checkups directory is an error.

It ends with **Press any key to exit...**, including after failures.
`-NoPause` disables the wait for CI; redirected input is detected and never blocks.
`-DryRun` lists the checkups without executing them or waiting for input.
Nothing is written to log files.

## Included checks

- [01-runnables.ps1](helpers/checkups/01-runnables.ps1) discovers scripts recursively,
  excluding Git metadata, local runtime data, dependencies and generated output.
  It parses every PowerShell script, requires its `-DryRun` parameter and invokes
  that no-op mode in a separate process. It syntax-checks JavaScript modules
  without importing them, checks every public CLI command with `--dry-run`, and
  exercises the Windows CMD selector with `-DryRun` on Windows. Linux explicitly
  skips the CMD execution; the Windows CI job covers it. Unknown runnable formats
  or batch entrypoints fail rather than being executed speculatively.
- [02-documentation.ps1](helpers/checkups/02-documentation.ps1) checks local Markdown/HTML
  links with exact filename casing, including audits and agent/setup docs, and
  compares the generated README HTML with Markdown without rewriting either.
  It also rejects retired script names in active docs/examples and verifies
  manifest icon filenames, the shared CI Node pin and maintenance command,
  runtime ignore boundaries, private reporting and README escaping safeguards.
  When `.github/ISSUE_TEMPLATE/` exists, each issue form needs `name`,
  `description` and `body` with unique field ids, and the chooser must link the
  same private reporting address as `SECURITY.md`.
- [03-project-types.ps1](helpers/checkups/03-project-types.ps1) validates JSON and ESM
  syntax without importing modules or installing packages. It verifies that the
  Node starter runs maintenance checks and that tooling presets remain
  configuration-only. It exercises every preset individually and all presets
  together through available PowerShell hosts and, on Windows, the CMD wrapper:
  preview, apply, unchanged rerun, unknown/traversal rejection and differing-file
  conflict refusal. All selector actions target **new disposable copies under
  the system temporary directory**, including spaced paths and user-file
  sentinels. SHA-256 snapshots verify copied bytes, opt-in selection, unchanged
  previews/reruns/failures and retained originals; the fixtures are removed.
- [04-copilot-setup.ps1](helpers/checkups/04-copilot-setup.ps1) exercises Copilot
  setup in disposable project and user-profile directories on available PowerShell
  hosts. It checks `ALL SET`, aggregated failure lists and exit codes, unchanged
  reruns, JSONC backups, preserved instructions, preview/dry-run behavior and
  redirected-input completion. No real VS Code settings or credentials are used.
- [05-storage.ps1](helpers/checkups/05-storage.ps1) verifies archive policy
  validation, exact byte/age boundaries, oldest/largest ordering, protected/live
  archives, non-ZIP/link preservation, disk-space safeguards, log rotation and
  explicit CLI warnings using disposable archives. It also checks the root
  `docs/AUDIT_TEMPLATE.md` template and report generation in `.audits/`.
  No cleanup targets existing data.
- [06-design-collection.ps1](helpers/checkups/06-design-collection.ps1) verifies
  exactly twenty complete README editions, twenty distinct landings and the
  final showcase, including generated freshness, unchanged README text, local
  links/anchors, semantic landmarks, local-only assets and palette contrast.
  It also verifies five compact documentation themes against twenty Markdown
  files each, using disposable outputs and unchanged-source snapshots. It never
  regenerates repository pages. Browser/keyboard review remains separate; see
  the [collection guide](../../designs/README.md). Remove this checkup with the
  optional collection if an adopted project does not retain it.

- [07-soft-copy.ps1](helpers/checkups/07-soft-copy.ps1) verifies selected-file
  copies, preserved existing files, exact JSON content pairs (including empty,
  Unicode and binary data), opt-in force replacements, previews and path/link
  refusal in disposable template/target directories. On Windows it also drives
  the actual GUI controls and launcher, including force cancellation and
  confirmation, plus recovery previews, exact restoration, safe removal of
  copy-created files/directories, later-edit refusal and partial-copy recovery.
  Where Windows provides 8.3 short names, revert and file listing are also
  exercised with short recovery, target and template paths, as created by the
  short `TEMP` path on GitHub's Windows runners.
  It never copies into or reverts an existing user repository.

- [08-script-icons.ps1](helpers/checkups/08-script-icons.ps1) verifies branded
Windows shortcuts in disposable fixtures using both available PowerShell hosts:
real COM targets, arguments, working directories and icon properties, supplied
ICO integrity, source preservation, inventories, safe modes and conflict/link
refusal. Non-Windows hosts check the explicit unsupported-platform error and
skip Windows COM assertions. No existing launchers or file associations change.

- [09-claim-template.ps1](helpers/checkups/09-claim-template.ps1) verifies one-time
  adoption in disposable full copies of the template: the shipped configuration has
  no placeholder text and typed lists; invalid values, missing provenance, short
  commit SHAs, still-referenced removals and removing `.audits` are refused without
  changes. A Git clone flow on each available PowerShell host checks provenance
  detection, the clean audit trail (no template records, example-only work queue,
  adoption record, clean audit README), commit-pinned evidence links, owner and
  title replacement, regenerated README editions, the adopted copy's own
  documentation check, and unchanged reruns. It also covers manual `-TemplateCommit`
  provenance, broken-link reporting and its passing rerun in the adoption record,
  the select-only project-type menu with simulated keys, and that a generated
  configuration passes validation.

## Safe modes

Every PowerShell entrypoint, including the runner and checkups, accepts `-DryRun`.
The CMD selector forwards that option. The CLI accepts `--dry-run` before or
after its command. These modes return before actions, prompts, configuration
loading, package commands, process management, copies, deletions or settings
changes. They verify that an entrypoint loads, **not** that its real actions work
or its configuration is valid.

```powershell
node .\moorkyz maintain --dry-run
.\.template\project-types\SetProjectType.cmd -DryRun
.\.template\project-types\SetProjectType.ps1 -DryRun
& '.\.template\claim-template\CreateProject.ps1' -DryRun
.\.template\copilot-settings\Setup-CopilotProject.ps1 -DryRun
```

Existing `-WhatIf` options remain available on setup and selector scripts for a
more detailed preview that validates their inputs. Unlike `-WhatIf`, `-DryRun`
does not require an adopted project's configuration.

Checkups never apply changes to this repository or existing local data. The
project-type, Copilot and storage checkups create and remove only their own
disposable fixtures; the focused storage checks do not replace the former full
lifecycle/storage suite.

Add checkups as more `*.ps1` files (numeric prefixes control ordering), keeping
all existing data read-only. Each must accept `-DryRun` and return without performing its check
when that switch is present. Throw or exit nonzero on failure. Checkups and
their dry-run implementations are trusted code, not a sandbox: review additions
before running them. Do not invoke `node moorkyz maintain` without `--dry-run`
from a checkup; that separate storage command archives and prunes runtime data.
Action-level regression checks belong in disposable fixtures, never existing
project data.
