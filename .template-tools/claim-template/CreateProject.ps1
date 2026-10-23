#requires -Version 5.1
<#
.SYNOPSIS
Turns this template into a project, driven by helpers/setup.config.json.

.DESCRIPTION
Fill in helpers/setup.config.json first; nothing changes until it is valid. The script
then shows its plan, asks for confirmation and:
  1. copies the selected project types to their root paths (keeping all starters),
  2. permanently removes the listed template-only paths,
  3. replaces the project placeholder and GitHub owner in text files
     (audits/ history and this folder are left as they are),
  4. sets the README title and regenerates README.html when Node.js is available.
Rerunning is safe. It always ends with "Press any key to continue".

.EXAMPLE
powershell -ExecutionPolicy Bypass -File ".template-tools\claim-template\CreateProject.ps1" -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Yes,
    [switch]$NoPause,
    [switch]$DryRun
)

if ($DryRun) {
    Write-Host '[DRY RUN] Project setup loaded; no config changes, copies, removals or prompts.'
    return
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$placeholder = 'moorkyz-project'
$templateOwner = 'Moorky'
$templateRepository = 'moorkyz-template'
$setupDir = [IO.Path]::GetFullPath($PSScriptRoot)
$root = Split-Path -Parent $setupDir
while ($root -and -not (Test-Path -LiteralPath (Join-Path $root 'moorkyz') -PathType Leaf) -and -not (Test-Path -LiteralPath (Join-Path $root '.git'))) {
    $root = Split-Path -Parent $root
}
$configPath = Join-Path (Join-Path $setupDir 'helpers') 'setup.config.json'
$cliPath = if ($root) { Join-Path $root 'moorkyz' } else { $null }
$typesDir = if ($root) { Join-Path $root '.template-tools\project-types\helpers\types' } else { $null }
$typeSelector = if ($root) { Join-Path $root '.template-tools\project-types\SetProjectType.ps1' } else { $null }
$topLevelSkip = '.git', '.moorkyz', '.logs', '.archive', '.trash', 'audits'
$binaryExtensions = '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.woff', '.woff2', '.pdf', '.zip'

function Wait-Key {
    if ($NoPause -or [Console]::IsInputRedirected) { return }
    Write-Host ''
    Write-Host 'Press any key to continue...'
    try {
        $Host.UI.RawUI.FlushInputBuffer()
        [void]$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    } catch { try { [void](Read-Host) } catch { } }
}

function Get-Setting($Config, [string]$Name) {
    $property = $Config.PSObject.Properties[$Name]
    if ($property) { $property.Value } else { $null }
}

function Get-List($Config, [string]$Name) {
    $value = Get-Setting $Config $Name
    if ($null -eq $value) { @() } else { @($value) }
}

function Test-Link([IO.FileSystemInfo]$Entry) {
    [bool]($Entry.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

function Test-ContainsSetup([IO.FileSystemInfo]$Entry) {
    $full = [IO.Path]::GetFullPath($Entry.FullName).TrimEnd('\', '/')
    $setupDir -eq $full -or $setupDir.StartsWith($full + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
}

function Get-RootRelative([string]$FullName) {
    $FullName.Substring($root.Length).TrimStart('\', '/')
}

function Read-Config {
    if (-not $root) { throw "Cannot find the repository root (a folder containing 'moorkyz' or '.git') above $setupDir." }
    if (-not (Test-Path -LiteralPath $configPath)) { throw "Missing $configPath. Restore it from the template and fill it in." }
    try { $config = [IO.File]::ReadAllText($configPath) | ConvertFrom-Json }
    catch { throw "setup.config.json is not valid JSON: $($_.Exception.Message)" }

    $problems = New-Object System.Collections.Generic.List[string]
    $allowed = 'projectName', 'displayName', 'githubOwner', 'projectTypes', 'remove'
    foreach ($name in $config.PSObject.Properties.Name) {
        if ($allowed -notcontains $name) { $problems.Add("Unknown setting '$name'. Allowed: $($allowed -join ', ').") }
    }

    $projectName = Get-Setting $config 'projectName'
    if (-not ($projectName -is [string]) -or $projectName -cnotmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$' -or $projectName.Length -gt 100 -or $projectName -eq $placeholder) {
        $problems.Add("projectName: set the repository/package name, e.g. 'my-app' (lowercase letters, digits and single hyphens).")
    }
    $displayName = Get-Setting $config 'displayName'
    if (-not ($displayName -is [string]) -or -not $displayName.Trim() -or $displayName -match '[\r\n]' -or $displayName.Length -gt 100) {
        $problems.Add("displayName: set the human-readable title for README.md, e.g. 'My App' (one line).")
    }
    $owner = Get-Setting $config 'githubOwner'
    if (-not ($owner -is [string]) -or $owner -notmatch '^[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}$') {
        $problems.Add("githubOwner: set the GitHub user or organization that owns the repository, e.g. '$templateOwner'.")
    }

    $available = @(if (Test-Path -LiteralPath $typesDir) {
        Get-ChildItem -LiteralPath $typesDir -Directory -Force | ForEach-Object { $_.Name }
    })
    $selectedTypes = New-Object System.Collections.Generic.List[string]
    foreach ($item in Get-List $config 'projectTypes') {
        if (-not ($item -is [string]) -or $item -notmatch '^[a-z][a-z0-9-]*$') {
            $problems.Add("projectTypes: '$item' must be a project type name. Available: $($available -join ', ').")
        } elseif ($available -contains $item) {
            if (-not $selectedTypes.Contains($item)) { $selectedTypes.Add($item) }
        } else {
            $problems.Add("projectTypes: '$item' does not exist. Available: $($available -join ', ').")
        }
    }
    if ($selectedTypes.Count -and -not (Test-Path -LiteralPath $typeSelector -PathType Leaf)) {
        $problems.Add('projectTypes: .template-tools/project-types/SetProjectType.ps1 is missing.')
    }

    $removeTargets = New-Object System.Collections.Generic.List[IO.FileSystemInfo]
    foreach ($entry in Get-List $config 'remove') {
        if (-not ($entry -is [string]) -or -not $entry.Trim() -or [IO.Path]::IsPathRooted($entry) -or $entry -match '(^|[\\/])\.\.([\\/]|$)') {
            $problems.Add("remove: '$entry' must be a path relative to the repository root.")
            continue
        }
        foreach ($match in @(Get-Item -Path (Join-Path $root $entry) -Force -ErrorAction SilentlyContinue)) {
            $full = [IO.Path]::GetFullPath($match.FullName)
            $relative = Get-RootRelative $full
            if (-not $full.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -or -not $relative -or $relative -match '^\.git([\\/]|$)') {
                $problems.Add("remove: '$entry' resolves to a protected path ('$relative').")
            } elseif ((Test-Link $match) -or ($match.PSIsContainer -and
                    @(Get-ChildItem -LiteralPath $full -Recurse -Force -Attributes ReparsePoint -ErrorAction SilentlyContinue).Count)) {
                $problems.Add("remove: '$relative' is or contains a link or junction; remove it manually.")
            } elseif (-not @($removeTargets | Where-Object { $_.FullName -eq $match.FullName }).Count) {
                $removeTargets.Add($match)
            }
        }
    }

    if ($problems.Count) {
        throw "Set up $configPath first:`n  - " + ($problems -join "`n  - ")
    }
    [pscustomobject]@{
        ProjectName = $projectName
        DisplayName = $displayName.Trim()
        Owner = $owner
        ProjectTypes = $selectedTypes.ToArray()
        Remove = @($removeTargets | Sort-Object { [int](Test-ContainsSetup $_) })
    }
}

function Get-TextFiles([string]$Directory, [bool]$TopLevel) {
    foreach ($entry in Get-ChildItem -LiteralPath $Directory -Force) {
        if (Test-Link $entry) { continue }
        if ($entry.PSIsContainer) {
            if ($entry.Name -eq 'node_modules' -or $entry.FullName -eq $setupDir -or ($TopLevel -and $topLevelSkip -contains $entry.Name)) { continue }
            Get-TextFiles $entry.FullName $false
        } elseif ($binaryExtensions -notcontains $entry.Extension.ToLowerInvariant() -and $entry.Length -lt 5MB) {
            $entry
        }
    }
}

function Update-TextFile([IO.FileInfo]$File, [scriptblock]$Transform) {
    $bytes = [IO.File]::ReadAllBytes($File.FullName)
    if ([Array]::IndexOf($bytes, [byte]0) -ge 0) { return $false }
    $bom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $skip = if ($bom) { 3 } else { 0 }
    $encoding = New-Object Text.UTF8Encoding($bom, $true)
    try { $text = $encoding.GetString($bytes, $skip, $bytes.Length - $skip) } catch { return $false }
    $updated = & $Transform $text
    if ($updated -ceq $text) { return $false }
    [IO.File]::WriteAllText($File.FullName, $updated, $encoding)
    $true
}

function Invoke-Setup {
    $plan = Read-Config
    $typesText = if ($plan.ProjectTypes.Count) { $plan.ProjectTypes -join ', ' } else { 'nothing' }
    $removeText = if ($plan.Remove.Count) { ($plan.Remove | ForEach-Object { Get-RootRelative $_.FullName }) -join ', ' } else { 'nothing present' }
    Write-Host "Project: $($plan.DisplayName) ($($plan.ProjectName)), GitHub owner $($plan.Owner)"
    Write-Host "Types:   $typesText (copy; keep starters)"
    Write-Host "Remove:  $removeText"
    Write-Host "Replace: '$placeholder' and the template GitHub owner in text files; README title"

    if ($WhatIfPreference) {
        if ($plan.ProjectTypes.Count) { & $typeSelector -ProjectType $plan.ProjectTypes -WhatIf }
        Write-Host 'WhatIf: no changes made.'
        return
    }
    if (-not $Yes) {
        if ([Console]::IsInputRedirected) { throw 'Confirmation required: run interactively or pass -Yes.' }
        if ((Read-Host 'Removal is permanent. Apply these changes? [y/N]') -notmatch '^(y|yes)$') {
            Write-Host 'Cancelled; nothing changed.'
            return
        }
    }

    if ($plan.ProjectTypes.Count) { & $typeSelector -ProjectType $plan.ProjectTypes }

    $deferred = New-Object System.Collections.Generic.List[IO.FileSystemInfo]
    foreach ($target in $plan.Remove) {
        $relative = Get-RootRelative $target.FullName
        if (Test-ContainsSetup $target) { $deferred.Add($target); continue }
        Remove-Item -LiteralPath $target.FullName -Recurse -Force
        Write-Host "Removed $relative"
    }

    $owner = $plan.Owner
    $name = $plan.ProjectName
    $changed = 0
    foreach ($file in @(Get-TextFiles $root $true)) {
        $updated = Update-TextFile $file {
            param($text)
            $updated = $text.Replace("github.com/$templateOwner/$templateRepository", "github.com/$owner/$name")
            $updated.Replace("github.com/$templateOwner/$placeholder", "github.com/$owner/$name").Replace($placeholder, $name)
        }
        if ($updated) { $changed++; Write-Host "Updated $(Get-RootRelative $file.FullName)" }
    }
    Write-Host "Placeholder replaced in $changed file(s)."

    $readme = Join-Path $root 'README.md'
    if (Test-Path -LiteralPath $readme) {
        $heading = '# ' + $plan.DisplayName
        $retitled = Update-TextFile (Get-Item -LiteralPath $readme) {
            param($text)
            ([regex]'(?m)^# [^\r\n]*').Replace($text, $heading.Replace('$', '$$'), 1)
        }
        if ($retitled) { Write-Host "README title set to '$($plan.DisplayName)'." }
        if ((Test-Path -LiteralPath (Join-Path $root 'README.html')) -and (Test-Path -LiteralPath $cliPath)) {
            $node = Get-Command node -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($node) {
                Push-Location $root
                try {
                    & $node.Source $cliPath readme
                    if ($LASTEXITCODE) { throw "README generation failed (exit $LASTEXITCODE)." }
                } finally { Pop-Location }
            } else {
                Write-Warning 'Node.js not found: run "node moorkyz readme" to regenerate README.html.'
            }
        }
    }

    foreach ($target in $deferred) {
        Remove-Item -LiteralPath $target.FullName -Recurse -Force
        Write-Host "Removed $(Get-RootRelative $target.FullName)"
    }
    Write-Host 'Setup complete. Review the result with git status before committing.'
}

$exitCode = 0
try { Invoke-Setup }
catch {
    Write-Host ''
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    $exitCode = 1
}
Wait-Key
exit $exitCode
