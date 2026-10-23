#requires -Version 5.1
<#
.SYNOPSIS
Adds selected project types to their root-relative paths without overwriting.

.DESCRIPTION
Run without arguments for a keyboard menu, or name one or more project types.
Space toggles types; Enter reviews the selection and asks for confirmation.
All selected files are checked before anything is copied. Different existing
targets, conflicting types, links and junctions are refused. Identical targets
are left unchanged. The entire .template-tools/project-types folder is kept: nothing is deleted,
moved or archived, and more types can be added later.

.EXAMPLE
.\.template-tools\project-types\SetProjectType.ps1
.\.template-tools\project-types\SetProjectType.ps1 node web -WhatIf
.\.template-tools\project-types\SetProjectType.ps1 docker
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$DryRun,
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$ProjectType
)

if ($DryRun) {
    Write-Host '[DRY RUN] Project type selector loaded; no menu, copies or changes.'
    return
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectTypesRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$helpers = Join-Path $projectTypesRoot 'helpers'
$types = Join-Path $helpers 'types'
$templateToolsRoot = Split-Path -Parent $projectTypesRoot
$root = Split-Path -Parent $templateToolsRoot
$separator = [IO.Path]::DirectorySeparatorChar

function Assert-NoLink([IO.FileSystemInfo]$Entry) {
    if ($Entry.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Refusing link or junction: $($Entry.FullName)"
    }
}

function Get-TypeFiles([string]$Directory) {
    foreach ($entry in Get-ChildItem -LiteralPath $Directory -Force) {
        Assert-NoLink $entry
        if ($entry.PSIsContainer) { Get-TypeFiles $entry.FullName } else { $entry }
    }
}

function Get-ContentHash([string]$Path) {
    $hash = [Security.Cryptography.SHA256]::Create()
    try {
        $stream = [IO.File]::OpenRead($Path)
        try { [BitConverter]::ToString($hash.ComputeHash($stream)) }
        finally { $stream.Dispose() }
    } finally { $hash.Dispose() }
}

function Read-SelectorKey {
    try { $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') }
    catch { throw "This host cannot read menu keys. Run in a terminal or pass project type names: $($_.Exception.Message)" }
}

function Read-ProjectTypeSelection([string[]]$Names) {
    if (-not $Names.Count) { throw 'No project types are available in .template-tools/project-types/helpers/types.' }
    $checked = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $index = 0
    $number = ''
    $notice = ''
    while ($true) {
        Clear-Host
        Write-Host 'Select project types'
        Write-Host ''
        $rows = [int][Math]::Ceiling($Names.Count / 2.0)
        $numberWidth = $Names.Count.ToString().Length
        $columnWidth = ($Names | Measure-Object -Property Length -Maximum).Maximum + $numberWidth + 10
        for ($row = 0; $row -lt $rows; $row++) {
            $line = ''
            for ($column = 0; $column -lt 2; $column++) {
                $i = $row + $column * $rows
                if ($i -ge $Names.Count) { continue }
                $cursor = if ($i -eq $index) { '>' } else { ' ' }
                $mark = if ($checked.Contains($Names[$i])) { 'x' } else { ' ' }
                $cell = "{0} [{1}] [{2}] {3}" -f $cursor, ($i + 1).ToString().PadLeft($numberWidth), $mark, $Names[$i]
                $line += if ($column -eq 0) { $cell.PadRight($columnWidth) } else { $cell }
            }
            Write-Host $line.TrimEnd()
        }
        Write-Host ''
        Write-Host 'Up/Down: move | Space: toggle | Enter: review | #: select | Esc/Q: quit'
        if ($number) { Write-Host "Number: $number" }
        if ($notice) { Write-Host $notice }
        $key = Read-SelectorKey
        $notice = ''
        if ($key.VirtualKeyCode -eq 27 -or $key.Character -match '^[qQ]$') { return }
        if ($key.Character -match '^[0-9]$') {
            $number += [string]$key.Character
            $value = 0
            if ([int]::TryParse($number, [ref]$value) -and $value -ge 1 -and $value -le $Names.Count) {
                $index = $value - 1
            }
            continue
        }
        if ($key.VirtualKeyCode -eq 8) {
            if ($number.Length) { $number = $number.Substring(0, $number.Length - 1) }
            continue
        }
        if ($key.VirtualKeyCode -eq 38 -or $key.VirtualKeyCode -eq 40) {
            $step = if ($key.VirtualKeyCode -eq 38) { -1 } else { 1 }
            $index = ($index + $step + $Names.Count) % $Names.Count
            $number = ''
            continue
        }
        if ($key.VirtualKeyCode -ne 32 -and $key.VirtualKeyCode -ne 13) { continue }
        if ($number) {
            $value = 0
            if (-not [int]::TryParse($number, [ref]$value) -or $value -lt 1 -or $value -gt $Names.Count) {
                $notice = "Choose a number from 1 to $($Names.Count)."
                $number = ''
                continue
            }
            $index = $value - 1
        }
        if ($key.VirtualKeyCode -eq 32 -or $number) {
            if (-not $checked.Remove($Names[$index])) { [void]$checked.Add($Names[$index]) }
            $number = ''
            continue
        }
        if (-not $checked.Count) { [void]$checked.Add($Names[$index]) }
        $choice = @($Names | Where-Object { $checked.Contains($_) })
        Write-Host ''
        Write-Host "Are you sure you want to add: $($choice -join ', ')?"
        Write-Host 'Files will be copied into the repository. Different existing files will not be overwritten.'
        Write-Host 'The entire .template-tools/project-types folder stays available. Nothing will be deleted or archived.'
        Write-Host 'Y: confirm | N/Enter/Space/Esc: back | Q: quit'
        while ($true) {
            $answer = Read-SelectorKey
            if ($answer.Character -match '^[yY]$') { return $choice }
            if ($answer.Character -match '^[qQ]$') { return }
            if ($answer.Character -match '^[nN]$' -or $answer.VirtualKeyCode -in 13, 27, 32) { break }
            Write-Host 'Press Y to confirm, N/Esc to go back, or Q to quit.'
        }
    }
}

Assert-NoLink (Get-Item -LiteralPath $templateToolsRoot -Force)
Assert-NoLink (Get-Item -LiteralPath $projectTypesRoot -Force)
Assert-NoLink (Get-Item -LiteralPath $helpers -Force)
Assert-NoLink (Get-Item -LiteralPath $types -Force)
if (-not $ProjectType) {
    if ([Console]::IsInputRedirected -or -not [Environment]::UserInteractive) {
        throw 'The menu requires an interactive terminal. Pass project type names instead, for example: .\.template-tools\project-types\SetProjectType.ps1 node web -WhatIf'
    }
    $available = @(Get-ChildItem -LiteralPath $types -Directory -Force | Sort-Object Name | ForEach-Object { $_.Name })
    $ProjectType = @(Read-ProjectTypeSelection $available)
    if (-not $ProjectType.Count) { Write-Host 'Cancelled; no files changed.'; return }
}

$selected = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$targets = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$copies = @(foreach ($name in $ProjectType) {
    if ($name -notmatch '^[a-z][a-z0-9-]*$') { throw "Invalid project type '$name'." }
    $profile = Join-Path $types $name
    if (-not (Test-Path -LiteralPath $profile -PathType Container)) { throw "Unknown project type '$name'." }
    if (-not $selected.Add($name)) { continue }
    Assert-NoLink (Get-Item -LiteralPath $profile -Force)
    foreach ($file in Get-TypeFiles $profile) {
        $relative = $file.FullName.Substring($profile.Length).TrimStart('\', '/')
        $target = [IO.Path]::GetFullPath((Join-Path $root $relative))
        if (-not $target.StartsWith($root + $separator, [StringComparison]::OrdinalIgnoreCase) -or
            $target.StartsWith($templateToolsRoot + $separator, [StringComparison]::OrdinalIgnoreCase) -or
            $relative -match '^\.git([\\/]|$)') {
            throw "Protected target: $relative"
        }
        if (-not $targets.Add($target)) { throw "Selected project types conflict at '$relative'; nothing was copied." }
        $parent = Split-Path -Parent $target
        while ($parent -ne $root) {
            if (Test-Path -LiteralPath $parent) {
                $entry = Get-Item -LiteralPath $parent -Force
                Assert-NoLink $entry
                if (-not $entry.PSIsContainer) { throw "Target parent is not a directory: $parent; nothing was copied." }
            }
            $parent = Split-Path -Parent $parent
        }
        if (Test-Path -LiteralPath $target) {
            $existing = Get-Item -LiteralPath $target -Force
            Assert-NoLink $existing
            if ($existing.PSIsContainer -or $existing.Length -ne $file.Length -or
                (Get-ContentHash $target) -ne (Get-ContentHash $file.FullName)) {
                throw "Already present with different content in the root: $relative; nothing was copied."
            }
            Write-Host "Already present and unchanged: $relative"
            continue
        }
        [pscustomobject]@{ Source = $file.FullName; Target = $target; Relative = $relative }
    }
})

foreach ($copy in $copies) {
    $parent = Split-Path -Parent $copy.Target
    while ($parent -ne $root) {
        if ($targets.Contains($parent)) { throw "Selected project types conflict at '$parent'; nothing was copied." }
        $parent = Split-Path -Parent $parent
    }
}
if (-not $copies.Count) { Write-Host 'Nothing to add; selected project types are already present and unchanged, or empty.'; return }

foreach ($copy in $copies) {
    if ($PSCmdlet.ShouldProcess($copy.Relative, 'Copy to repository root')) {
        $folder = Split-Path -Parent $copy.Target
        if (-not (Test-Path -LiteralPath $folder)) { New-Item -ItemType Directory -Path $folder | Out-Null }
        [IO.File]::Copy($copy.Source, $copy.Target, $false)
        Write-Host "Added $($copy.Relative)"
    }
}
