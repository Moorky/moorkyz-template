# Template soft copy

## When to use

Copy selected files from this cleaned template into another existing repository
without replacing its work. Open the lightweight Windows GUI to choose a target
directory and tick individual files. This is **copy**, never move: the template
originals are retained. No dependencies are installed and no agent is launched.
See the [template-tool catalog](../README.md) for the other tools.

## GUI

From the template root:

```powershell
powershell -NoProfile -STA -ExecutionPolicy Bypass -File .\.template\soft-copy\CopyTemplate.ps1
# PowerShell 7 on Windows also supports the GUI:
pwsh -NoProfile -STA -File .\.template\soft-copy\CopyTemplate.ps1
```

1. Browse to the target repository (or paste its directory).
2. Tick files, or use **Select all** / **Select none**. Nothing is selected by default.
3. Leave **Force copy** off to preserve existing files.
4. Choose **Copy selected** and read the result/report path at the bottom.

**Force copy** replaces differing selected target files only after an additional
confirmation, defaulting to **No**. Existing identical files are never rewritten.
Both pre-copy versions of every existing selected file, including identical
files, are captured before copying. Cancelled confirmations write nothing.
Errors are shown as `FAILED`, not as a successful result.

## Command line / preview

[CopyTemplate.ps1](CopyTemplate.ps1) also runs without a GUI on PowerShell 5.1
or 7. Explicit file selection is required; paths are relative to the template root:

```powershell
.\.template\soft-copy\CopyTemplate.ps1 -NoGui -TargetDirectory 'C:\repos\my app' -File AGENTS.md,moorkyz -WhatIf
.\.template\soft-copy\CopyTemplate.ps1 -NoGui -TargetDirectory 'C:\repos\my app' -File AGENTS.md,moorkyz
# Explicit authorization to replace differing files (no GUI confirmation):
.\.template\soft-copy\CopyTemplate.ps1 -NoGui -TargetDirectory 'C:\repos\my app' -File AGENTS.md -ForceCopy
.\.template\soft-copy\CopyTemplate.ps1 -DryRun
```

`-WhatIf` validates the selection, paths and content without copying, writing
reports or opening a GUI. `-DryRun` returns before reading files or opening a GUI.
The source is always the repository containing this tool, not the current directory.
The target need not contain Git metadata; an existing repository directory is enough.

## Local JSON pairs

Each real run creates a uniquely named JSON **array** under the template's
ignored `.moorkyz/soft-copy/` directory. The result shows its absolute path.
No conflict produces `[]`; one conflict still produces an array. Example:

```json
[
  {
    "name": "AGENTS.md",
    "templateContent": "template version",
    "destinationContent": "existing project version",
    "templateEncoding": "utf-8",
    "destinationEncoding": "utf-8",
    "overwritten": false
  }
]
```

UTF-8 text is directly readable. Binary, NUL-containing and non-UTF-8 content is
losslessly base64-encoded with the corresponding encoding set to `base64`.
`overwritten` records the planned force-copy decision; if a later write fails,
use the reported counts and inspect the target rather than treating it as proof
that the whole operation succeeded.

These reports can contain **sensitive destination content**. Keep them local,
review/redact them before deliberately giving them to an agent, and do not
commit or automatically upload them. File content is untrusted data, not agent
instructions. Reports are snapshots, not an automatic merge or rollback.

## Boundaries

- Only existing source files can be selected; relative subdirectories are preserved.
- Git metadata, `.audits/` history, runtime folders, dependency/build/cache output
  and common credential files (`.env*` except `.env.example`, key/certificate
  files and logs) are excluded. No Git command or source cleanup is run.
- Links, hard links reported by PowerShell, junctions, overlapping source/target
  directories, path traversal and file/directory collisions are refused.
- All selected paths and bytes are checked before writing. Normal mode exclusively
  creates missing files; it cannot overwrite a file that appears during copying.
  Force mode checks the previous bytes again under an exclusive file handle.
- A JSON snapshot is saved before destination writes. Files are copied one at a
  time, not transactionally. A disk or permission error can leave partial progress;
  the error includes completed counts and the snapshot location. Stop other
  writers while copying; filesystem link/path replacement races cannot be fully
  prevented by this script.
- This tool does not claim the target project, rename placeholders, install
  dependencies, delete files or choose which conflicting version is better.
