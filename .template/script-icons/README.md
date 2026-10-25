# Script icons (Windows)

## When to use

Use [SetScriptIcons.ps1](SetScriptIcons.ps1) to give the template's runnable tools
the supplied Moorkyz icon in Explorer without renaming, moving, recompiling or
editing their source files. See the [template-tool catalog](../README.md).
Windows PowerShell 5.1 and PowerShell 7 on Windows are supported; no packages,
administrator access or registry/file-association changes are needed.

```powershell
# Load only; absolutely no writes or discovery.
pwsh -NoProfile -File .\.template\script-icons\SetScriptIcons.ps1 -DryRun
# Discover and validate the actual plan without writing.
pwsh -NoProfile -File .\.template\script-icons\SetScriptIcons.ps1 -WhatIf
# Create local branded shortcuts without running any target.
pwsh -NoProfile -File .\.template\script-icons\SetScriptIcons.ps1
```

Open the repository's ignored `.moorkyz\script-icons` directory in Explorer.
It mirrors the original relative paths; each runnable has a `.lnk` shortcut
with [the shared icon](helpers/moorkyz.ico). `inventory.json` records every
discovered script, shortcut target/arguments and each skipped file with a reason.
The output is local runtime data, not a portable binary committed to Git.

## Coverage and limitations

- Standalone PowerShell scripts (including maintenance checkups), CMD/batch files,
  executables, Node shebang entrypoints such as the root CLI, `build.mjs`,
  `verify*.mjs` and `*.test.mjs` receive shortcuts.
- Browser scripts, configuration and library modules are inventoried but not
  made executable. PowerShell `helpers` are libraries, except maintenance
  checkups, which are standalone. Other discovered formats (`sh`, Python,
  VBScript, WSF and legacy COM executables) are reported as unsupported instead
  of guessing an interpreter, installing a runtime or changing file associations. Windows
  Script Host refused to save direct COM-target shortcuts in local verification.
- `.git`, dependencies, generated build output and ignored runtime directories
  are excluded. Symlinks/junctions in source or output paths are refused.
- Every shortcut runs from the repository root. PowerShell shortcuts use the
  host that created them with `-NoLogo -NoProfile -NoExit -File`; execution
  policy is not bypassed. Node shortcuts use the installed `node` resolved
  when generated and do not wrap arguments in a command shell. Runtime versions
  and PATH are not changed; maintenance still requires Node.js 24 LTS.
  Console-only Node output may close with its process; use a terminal for logs/arguments.
- Shortcuts pass **no task arguments or approvals**. Opening one runs the same
  tool as invoking its entrypoint directly, with that tool's existing prompts
  and safety rules. Do not run project adoption in this template. Creating
  shortcuts does not run adoption, builds, tests, copying or other targets.
- Windows does not support embedding an individual icon in `.ps1`, `.cmd`,
  `.bat` or JavaScript source files. Their original file icons stay unchanged.
  Existing executables are not patched, preserving signatures and resources.
  This tool brands their shortcuts instead.
- Shortcuts contain absolute local paths. Create them after cloning/moving the
  template and after installing the desired Node/PowerShell host. Existing
  output is deliberately never overwritten: a rerun fails before any write.
  Preserve or explicitly remove only the generated icon output before
  regenerating. Stale shortcuts are never silently removed or replaced.

The ICO is an exact copy of the owner-supplied Moorkyz `favicon.ico`; the other
six supplied favicon/manifest files are unnecessary for Windows script icons
and remain untouched. No third-party icon pack is included.

Shortcut properties follow the
[Microsoft Windows Script Host example](https://learn.microsoft.com/en-us/troubleshoot/windows-client/admin-development/create-desktop-shortcut-with-wsh).
Real COM property, argument/path, source-preservation, conflict and no-write
checks run in disposable fixtures through the
[script-icon checkup](../maintenance/helpers/checkups/08-script-icons.ps1).
