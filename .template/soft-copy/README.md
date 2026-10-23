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
5. To undo that operation, choose **Revert last copy** and confirm. The button
   becomes available after a copy changes files, including recoverable failures.

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

## Revert a copy

Before destination writes, the tool saves a separate `recovery-*.json` snapshot
beside the conflict report in ignored `.moorkyz/soft-copy/`. It contains original
bytes, original modification times, expected copied-file hashes and ownership
records for new files/directories. The existing conflict-report array stays unchanged.

**Revert last copy** restores replaced files, removes files created by that
operation and removes only empty directories created by it. Preserved conflicts,
pre-existing directories and unrelated files are left alone. Revert checks every
affected file before changing anything and refuses later edits or missing
overwritten files. It remains available after refusal or cancellation.
The button is bound to the original target, even if the target text field changes.
After a successful revert it is disabled; unchanged copies do not enable it.

You can also revert after closing the GUI. Supply the **same target directory**
and the recovery path printed by the copy:

```powershell
.\.template\soft-copy\CopyTemplate.ps1 -TargetDirectory 'C:\repos\my app' -Revert 'C:\path\to\template\.moorkyz\soft-copy\recovery-<id>.json' -WhatIf
.\.template\soft-copy\CopyTemplate.ps1 -TargetDirectory 'C:\repos\my app' -Revert 'C:\path\to\template\.moorkyz\soft-copy\recovery-<id>.json'
```

`-WhatIf` validates without reverting or updating snapshots. The GUI asks for
confirmation (default **No**); the explicit CLI `-Revert` authorizes the action.
Each changing copy has its own recovery path; the button tracks only the latest
copy, while older snapshots remain available through the CLI. Undo overlapping
operations newest-first. A per-snapshot exclusive lock prevents simultaneous
reverts. Completed per-file restores are recorded so a later retry skips them.

Snapshots and their small lock files remain local until you deliberately remove
them; they are temporary recovery data, not tracked backups or an automatic
retention service. Keep them until you are satisfied with the target. Do not edit
snapshots or use ones from untrusted sources. Copies made before this recovery
feature have no ownership journal and cannot be automatically reverted.

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
instructions. Conflict reports are snapshots, not merge instructions; use the
separate recovery snapshot for an explicit revert.

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
- Conflict and recovery snapshots are saved before destination writes. Copies
  and reverts run one file at a time, not transactionally. Controlled copy failures
  retain recovery state for completed/observed writes. A disk/permission error
  during recovery, or abrupt process/power loss during a copy, can still require
  manual restoration from the saved bytes; incomplete `copying` journals are
  deliberately refused. Stop other writers while copying/reverting; filesystem
  link/path replacement races cannot be fully prevented by this script.
- This tool does not claim the target project, rename placeholders, install
  dependencies or choose which conflicting version is better. Only an explicit
  revert removes files owned by that copy; no recursive target cleanup is run.
