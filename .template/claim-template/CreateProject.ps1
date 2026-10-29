#requires -Version 5.1
<#
.SYNOPSIS
Turns a copy of this template into a project, driven by helpers/setup.config.json.

.DESCRIPTION
Fill in helpers/setup.config.json first; nothing changes until it is valid. The script
then shows its plan, asks for confirmation and:
  1. copies the selected project types to their root paths (keeping all starters),
  2. permanently removes the listed template-only paths; remaining files must not
     link to or mention them,
  3. on the first adoption, starts the project's own audit trail: the template's
     audit records and work-queue history are not inherited, links to those records
     point to the template commit, and an adoption record in .audits/ preserves the
     template provenance (repository, version and commit SHA),
  4. replaces the project placeholder and template GitHub owner in text files
     (.audits/, commit-pinned template links and this folder are left as they are),
  5. sets the README title, regenerates README.html when Node.js is available and
     validates every internal Markdown/HTML link.
Interactive runs without configured project types can choose them in the existing
project-type menu; the selection is validated and saved to setup.config.json.
Rerunning is safe. It always ends with "Press any key to continue".

.PARAMETER TemplateCommit
Full SHA of the template commit this copy was made from. Needed only for the first
adoption when Git cannot provide it (the copy's origin is not Moorky/moorkyz-template).

.EXAMPLE
powershell -ExecutionPolicy Bypass -File ".template\claim-template\CreateProject.ps1" -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Yes,
    [switch]$NoPause,
    [switch]$DryRun,
    [string]$TemplateCommit
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
$templateUrl = "https://github.com/$templateOwner/$templateRepository"
$adoptionSuffix = '-adopted-from-moorkyz-template.md'
$setupDir = [IO.Path]::GetFullPath($PSScriptRoot)
$root = Split-Path -Parent $setupDir
while ($root -and -not (Test-Path -LiteralPath (Join-Path $root 'moorkyz') -PathType Leaf) -and -not (Test-Path -LiteralPath (Join-Path $root '.git'))) {
    $root = Split-Path -Parent $root
}
$configPath = Join-Path (Join-Path $setupDir 'helpers') 'setup.config.json'
$cliPath = if ($root) { Join-Path $root 'moorkyz' } else { $null }
$typesDir = if ($root) { Join-Path $root '.template\project-types\helpers\types' } else { $null }
$typeSelector = if ($root) { Join-Path $root '.template\project-types\SetProjectType.ps1' } else { $null }
$auditsDir = if ($root) { Join-Path $root '.audits' } else { $null }
$schedulerPath = if ($root) { Join-Path $root 'AGENT_SCHEDULER.md' } else { $null }
$topLevelSkip = '.git', '.moorkyz', '.logs', '.archive', '.audits'
$scanSkip = '.git', '.moorkyz', '.logs', '.archive', 'node_modules', 'coverage', 'dist', 'build', 'tmp', '.tmp'
$binaryExtensions = '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.woff', '.woff2', '.pdf', '.zip'
$markdownLink = [regex]'!?\[[^\]]*\]\((?:<([^>]+)>|([^)\s]+))(?:\s+"[^"]*")?\)'
$htmlLink = [regex]'(?:href|src)=["'']([^"'']+)["'']'
# Commit-pinned links to the template are provenance and must keep pointing at the template.
$templateLink = [regex]('github\.com/' + [regex]::Escape($templateOwner) + '/' + [regex]::Escape($templateRepository) + '(?!/(?:blob|tree|commit)/[0-9a-f]{40})')
$utf8 = New-Object Text.UTF8Encoding($false)
$nameCache = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([StringComparer]::Ordinal)

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

function Get-RootPath([string]$FullName) {
    (Get-RootRelative $FullName).Replace('\', '/')
}

function Test-Under([string]$Path, [string]$Parent) {
    $comparison = [StringComparison]::OrdinalIgnoreCase
    $Path = $Path.TrimEnd('\', '/')
    $Parent = $Parent.TrimEnd('\', '/')
    $Path.Equals($Parent, $comparison) -or $Path.StartsWith($Parent + [IO.Path]::DirectorySeparatorChar, $comparison)
}

function Read-Config {
    if (-not $root) { throw "Cannot find the repository root (a folder containing 'moorkyz' or '.git') above $setupDir." }
    if (-not (Test-Path -LiteralPath $configPath)) { throw "Missing $configPath. Restore it from the template and fill it in." }
    try { $config = [IO.File]::ReadAllText($configPath) | ConvertFrom-Json }
    catch { throw "setup.config.json is not valid JSON: $($_.Exception.Message)" }
    Test-SetupConfig $config
}

function Test-SetupConfig($Config) {
    $config = $Config
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
    foreach ($listName in 'projectTypes', 'remove') {
        # Read the property directly: returning it from a function would unwrap one-element arrays.
        $listProperty = $config.PSObject.Properties[$listName]
        if ($listProperty -and $null -ne $listProperty.Value -and $listProperty.Value -isnot [array]) {
            $problems.Add("${listName}: must be a JSON array, for example [] or [""node"", ""web""]; placeholder text is not a value.")
        }
    }
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
        $problems.Add('projectTypes: .template/project-types/SetProjectType.ps1 is missing.')
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
            } elseif ($relative -match '^\.audits([\\/]|$)') {
                $problems.Add("remove: '$entry' would delete the audit trail. Adoption already replaces the template's audit history with the project's own.")
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
        RemoveEntries = @(Get-List $config 'remove')
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

function ConvertTo-JsonText([string]$Value) {
    ConvertTo-Json -InputObject $Value -Compress
}

function ConvertTo-SetupJson($Plan) {
    $list = {
        param($Items)
        $values = @($Items | Where-Object { $null -ne $_ } | ForEach-Object { ConvertTo-JsonText $_ })
        if ($values.Count) { '[' + ($values -join ', ') + ']' } else { '[]' }
    }
    $lines = @(
        '{',
        "  ""projectName"": $(ConvertTo-JsonText $Plan.ProjectName),",
        "  ""displayName"": $(ConvertTo-JsonText $Plan.DisplayName),",
        "  ""githubOwner"": $(ConvertTo-JsonText $Plan.Owner),",
        "  ""projectTypes"": $(& $list $Plan.ProjectTypes),",
        "  ""remove"": $(& $list $Plan.RemoveEntries)",
        '}'
    )
    ($lines -join "`n") + "`n"
}

function Invoke-Git([string[]]$Arguments) {
    # Native stderr must not become a terminating error on Windows PowerShell 5.1.
    $ErrorActionPreference = 'Continue'
    $git = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $git) { return $null }
    $output = @(& $git.Source -C $root @Arguments 2>$null)
    if ($LASTEXITCODE) { return $null }
    , $output
}

function Get-TemplateProvenance {
    if ($TemplateCommit) {
        if ($TemplateCommit -notmatch '^[0-9a-fA-F]{40}$') { throw '-TemplateCommit must be the full 40-character template commit SHA.' }
        return [pscustomobject]@{
            Commit = $TemplateCommit.ToLowerInvariant()
            Version = 'not detected (commit supplied with -TemplateCommit)'
            Committed = 'not detected'
            Source = 'supplied with -TemplateCommit'
        }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) { return $null }
    $origin = Invoke-Git @('remote', 'get-url', 'origin')
    $expected = '^(?:https://github\.com/|git@github\.com:|ssh://git@github\.com/)' + [regex]::Escape($templateOwner) + '/' + [regex]::Escape($templateRepository) + '(?:\.git)?/?$'
    if (-not $origin -or $origin[0] -notmatch $expected) { return $null }
    $commit = Invoke-Git @('rev-parse', 'HEAD')
    if (-not $commit -or $commit[0] -notmatch '^[0-9a-f]{40}$') { return $null }
    $committed = Invoke-Git @('show', '-s', '--format=%cI', 'HEAD')
    $version = Invoke-Git @('describe', '--tags', '--exact-match', 'HEAD')
    if (-not $version) { $version = Invoke-Git @('describe', '--tags', 'HEAD') }
    $changes = Invoke-Git @('status', '--porcelain', '--untracked-files=no')
    $tree = if ($null -eq $changes) { 'not checked' } elseif ($changes.Count) { "$($changes.Count) uncommitted tracked change(s)" } else { 'clean' }
    [pscustomobject]@{
        Commit = $commit[0]
        Version = if ($version) { $version[0] } else { 'untagged' }
        Committed = if ($committed) { $committed[0] } else { 'not detected' }
        Source = "Git origin $templateOwner/$templateRepository; working tree $tree"
    }
}

function Get-AuditHistory {
    if (-not (Test-Path -LiteralPath $auditsDir -PathType Container)) {
        return [pscustomobject]@{ Initialized = $false; Records = @(); Record = $null }
    }
    $entries = @(Get-ChildItem -LiteralPath $auditsDir -Force)
    $adoption = @($entries | Where-Object { -not $_.PSIsContainer -and $_.Name.EndsWith($adoptionSuffix, [StringComparison]::OrdinalIgnoreCase) } | Sort-Object Name)
    if ($adoption.Count) {
        return [pscustomobject]@{ Initialized = $true; Records = @(); Record = $adoption[-1].FullName }
    }
    $records = @($entries | Where-Object { $_.Name -ne 'README.md' })
    foreach ($record in $records) {
        if ((Test-Link $record) -or ($record.PSIsContainer -and
                @(Get-ChildItem -LiteralPath $record.FullName -Recurse -Force -Attributes ReparsePoint -ErrorAction SilentlyContinue).Count)) {
            throw "Template audit record '$(Get-RootRelative $record.FullName)' is or contains a link or junction; remove it manually."
        }
    }
    [pscustomobject]@{ Initialized = $false; Records = $records; Record = $null }
}

function Get-ScanFiles([string]$Directory, [string[]]$Extensions) {
    foreach ($entry in Get-ChildItem -LiteralPath $Directory -Force) {
        if ($scanSkip -contains $entry.Name -or (Test-Link $entry)) { continue }
        if ($entry.PSIsContainer) { Get-ScanFiles $entry.FullName $Extensions }
        elseif (-not $Extensions -or $Extensions -contains $entry.Extension.ToLowerInvariant()) { $entry }
    }
}

function Resolve-LinkTarget([string]$Directory, [string]$Target) {
    if ($Target -match '^[a-zA-Z][a-zA-Z0-9+.-]*:|^#|^//') { return $null }
    $local = ($Target -split '[?#]', 2)[0]
    if (-not $local) { return $null }
    try { $local = [Uri]::UnescapeDataString($local) } catch { }
    [IO.Path]::GetFullPath((Join-Path $Directory $local)).TrimEnd('\', '/')
}

function Get-FileLinks([IO.FileInfo]$File, [string]$Text) {
    # Same link syntax as the maintenance documentation check.
    $directory = Split-Path -Parent $File.FullName
    $pattern = if ($File.Extension -ieq '.html') { $htmlLink } else { $markdownLink }
    foreach ($match in $pattern.Matches($Text)) {
        $group = if ($match.Groups[1].Success) { $match.Groups[1] } else { $match.Groups[2] }
        $resolved = Resolve-LinkTarget $directory $group.Value
        if ($resolved) { [pscustomobject]@{ Target = $group.Value; Path = $resolved } }
    }
}

function Test-ExactPath([string]$FullName) {
    if (-not (Test-Under $FullName $root)) { return $false }
    $directory = $root
    foreach ($part in @($FullName.Substring($root.Length) -split '[\\/]' | Where-Object { $_ })) {
        if (-not $nameCache.ContainsKey($directory)) {
            $nameCache[$directory] = @(if (Test-Path -LiteralPath $directory -PathType Container) { Get-ChildItem -LiteralPath $directory -Force -Name })
        }
        if ($nameCache[$directory] -cnotcontains $part) { return $false }
        $directory = Join-Path $directory $part
    }
    $true
}

function Test-InternalLinks {
    $nameCache.Clear()
    $files = @(Get-ScanFiles $root @('.md', '.html'))
    $broken = New-Object System.Collections.Generic.List[string]
    $count = 0
    foreach ($file in $files) {
        foreach ($link in @(Get-FileLinks $file ([IO.File]::ReadAllText($file.FullName)))) {
            $count++
            if (-not (Test-ExactPath $link.Path)) { $broken.Add("$(Get-RootPath $file.FullName): $($link.Target)") }
        }
    }
    [pscustomobject]@{ Files = $files.Count; Links = $count; Broken = $broken.ToArray() }
}

function Find-RemovedReferences($Plan) {
    if (-not $Plan.Remove.Count) { return @() }
    $targets = @($Plan.Remove | ForEach-Object { [IO.Path]::GetFullPath($_.FullName).TrimEnd('\', '/') })
    # Root-relative path mentions, optionally prefixed with ./ or ../ segments.
    $mentions = @(foreach ($target in $Plan.Remove) {
        $path = (@((Get-RootPath $target.FullName) -split '/' | ForEach-Object { [regex]::Escape($_) }) -join '[/\\]')
        $end = if ($target.PSIsContainer) { '[/\\]' } else { '(?![\w.\-])' }
        [regex]('(?<![\w.\-/\\])(?:\.{1,2}[/\\])*' + $path + $end)
    })
    $found = New-Object System.Collections.Generic.List[string]
    foreach ($file in @(Get-ScanFiles $root $null)) {
        $full = $file.FullName
        if ($binaryExtensions -contains $file.Extension.ToLowerInvariant() -or $file.Length -ge 5MB) { continue }
        # Template history is replaced on adoption; project history may describe removed paths.
        if ((Test-Under $full $auditsDir) -or (Test-Under $full $schedulerPath)) { continue }
        if (@($targets | Where-Object { Test-Under $full $_ }).Count) { continue }
        $text = [IO.File]::ReadAllText($full)
        $label = Get-RootPath $full
        if ($file.Extension -in '.md', '.html') {
            foreach ($link in @(Get-FileLinks $file $text)) {
                if (@($targets | Where-Object { Test-Under $link.Path $_ }).Count) { $found.Add("$label links to $($link.Target)") }
            }
        }
        if (Test-Under $full $setupDir) { continue }
        foreach ($pattern in $mentions) {
            foreach ($match in $pattern.Matches($text)) { $found.Add("$label mentions $($match.Value)") }
        }
    }
    @($found | Select-Object -Unique)
}

function Reset-SchedulerTables([string]$Text) {
    $examples = @{
        ledger = '| REQ-001 | _Example: describe the owner request and any confirmed decisions._ | READY |'
        queue = '| EXAMPLE-01 | P1 | READY | | None | _Example: bounded scope, acceptance criteria and next action (REQ-001)._ | Not requested |'
    }
    $result = New-Object System.Collections.Generic.List[string]
    $table = $null
    $state = $null
    $kept = $false
    $dropped = 0
    foreach ($line in ($Text -split "`n")) {
        $bare = $line.TrimEnd("`r")
        if ($state -eq 'header') { $result.Add($line); $state = 'body'; continue }
        if ($state -eq 'body') {
            if ($bare.StartsWith('|')) {
                if ($bare -match '^\| (REQ-001|EXAMPLE-01) \|') { $result.Add($line); $kept = $true } else { $dropped++ }
                continue
            }
            if (-not $kept) { $result.Add($examples[$table]) }
            $state = $null
        }
        $result.Add($line)
        if ($bare -like '| Request | Requested outcome*') { $table = 'ledger'; $state = 'header'; $kept = $false }
        elseif ($bare -like '| Item | Priority | State |*') { $table = 'queue'; $state = 'header'; $kept = $false }
    }
    if ($state -eq 'body' -and -not $kept) { $result.Add($examples[$table]) }
    [pscustomobject]@{ Text = $result -join "`n"; Dropped = $dropped }
}

function New-AuditReadme($Provenance, [string]$RecordName) {
    $intro = "# Audits`n`nOne report per task, named ``YYYY-MM-DDTHH-MM-SSZ-task-slug.md`` (UTC). Create a draft with ``node moorkyz audit `"task title`"`` and fill it with the actual results."
    $readme = Join-Path $auditsDir 'README.md'
    if (Test-Path -LiteralPath $readme -PathType Leaf) {
        # Keep the template's generic guidance; its history sections are template-specific.
        $head = ([IO.File]::ReadAllText($readme).Replace("`r`n", "`n") -split '(?m)^## ', 2)[0].TrimEnd()
        if ($head) { $intro = $head }
    }
    @(
        $intro, '',
        '## Template provenance', '',
        "This project started from [$templateOwner/$templateRepository]($templateUrl/tree/$($Provenance.Commit)),",
        "commit ``$($Provenance.Commit)`` (version: $($Provenance.Version)). Its own audit trail",
        "starts with [the adoption record]($RecordName). The template's task reports and work-queue",
        'history were not inherited; they remain in the template repository at that commit.', ''
    ) -join "`n"
}

function Initialize-AuditTrail($History, $Provenance) {
    $records = @($History.Records | ForEach-Object { [IO.Path]::GetFullPath($_.FullName).TrimEnd('\', '/') })
    $rewrite = @{ Links = 0; Files = 0; Rows = 0 }
    if ($records.Count) {
        foreach ($file in @(Get-ScanFiles $root @('.md', '.html'))) {
            if ((Test-Under $file.FullName $auditsDir) -or (Test-Under $file.FullName $schedulerPath)) { continue }
            $directory = Split-Path -Parent $file.FullName
            $pattern = if ($file.Extension -ieq '.html') { $htmlLink } else { $markdownLink }
            $changed = Update-TextFile $file {
                param($text)
                $pattern.Replace($text, [Text.RegularExpressions.MatchEvaluator] {
                    param($match)
                    $group = if ($match.Groups[1].Success) { $match.Groups[1] } else { $match.Groups[2] }
                    $resolved = Resolve-LinkTarget $directory $group.Value
                    if (-not $resolved -or -not @($records | Where-Object { Test-Under $resolved $_ }).Count) { return $match.Value }
                    $suffix = if ($group.Value -match '[?#].*$') { $Matches[0] } else { '' }
                    $rewrite.Links++
                    $offset = $group.Index - $match.Index
                    $match.Value.Substring(0, $offset) + "$templateUrl/blob/$($Provenance.Commit)/$(Get-RootPath $resolved)$suffix" +
                        $match.Value.Substring($offset + $group.Length)
                })
            }
            if ($changed) { $rewrite.Files++; Write-Host "Pointed template audit links to the template commit: $(Get-RootPath $file.FullName)" }
        }
    }
    if (Test-Path -LiteralPath $schedulerPath -PathType Leaf) {
        [void](Update-TextFile (Get-Item -LiteralPath $schedulerPath) {
            param($text)
            $reset = Reset-SchedulerTables $text
            $rewrite.Rows = $reset.Dropped
            $reset.Text
        })
        Write-Host "Work queue reset: $($rewrite.Rows) template request/queue row(s) not inherited."
    }
    foreach ($record in $History.Records) { Remove-Item -LiteralPath $record.FullName -Recurse -Force }
    Write-Host "Audit history: $($History.Records.Count) template record(s) not inherited; they remain at $templateUrl/tree/$($Provenance.Commit)/.audits"
    if (-not (Test-Path -LiteralPath $auditsDir)) { [void](New-Item -ItemType Directory -Path $auditsDir) }
    $created = (Get-Date).ToUniversalTime()
    $recordName = $created.ToString("yyyy-MM-dd'T'HH-mm-ss'Z'", [Globalization.CultureInfo]::InvariantCulture) + $adoptionSuffix
    [IO.File]::WriteAllText((Join-Path $auditsDir 'README.md'), (New-AuditReadme $Provenance $recordName), $utf8)
    [pscustomobject]@{
        Created = $created.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", [Globalization.CultureInfo]::InvariantCulture)
        RecordPath = Join-Path $auditsDir $recordName
        Records = $History.Records.Count
        Links = $rewrite.Links
        Files = $rewrite.Files
        Rows = $rewrite.Rows
    }
}

function ConvertTo-Cell([string]$Value) {
    $Value.Replace('|', '\|').Replace("`r", ' ').Replace("`n", ' ')
}

function New-AdoptionRecord($Plan, $Provenance, $Trail, $Summary) {
    $code = { param($items) if (@($items).Count) { (@($items) | ForEach-Object { '`' + $_ + '`' }) -join ', ' } else { 'none' } }
    @(
        '# Adopted from moorkyz-template', '',
        "Created by ``.template/claim-template/CreateProject.ps1`` at $($Trail.Created). This is the first",
        "record of this project's own audit trail; the template's audit records and work-queue history",
        'were not inherited. Review the changes with `git status` and `git diff`, then commit them',
        'together with this record. This record does not verify the adopted product itself.', '',
        '| Field | Value |', '|---|---|',
        "| Project | $(ConvertTo-Cell $Plan.DisplayName) (``$($Plan.ProjectName)``), GitHub owner ``$($Plan.Owner)`` |",
        "| Template repository | [$templateOwner/$templateRepository]($templateUrl) |",
        "| Template version | $(ConvertTo-Cell $Provenance.Version) |",
        "| Template commit | [``$($Provenance.Commit)``]($templateUrl/tree/$($Provenance.Commit)) |",
        "| Template commit date | $(ConvertTo-Cell $Provenance.Committed) |",
        "| Provenance source | $(ConvertTo-Cell $Provenance.Source) |",
        "| Project types added | $(& $code $Plan.ProjectTypes) |",
        "| Paths removed | $(& $code $Summary.Removed) |",
        "| Template audit records not inherited | $($Trail.Records), kept in the template repository at the commit above |",
        "| Work-queue rows not inherited | $($Trail.Rows); the request ledger and work queue start with their example rows |",
        "| Template audit links | $($Trail.Links) in $($Trail.Files) file(s) now point to the template commit |",
        "| Placeholder and owner replacements | $($Summary.Replaced) file(s) |",
        "| README | $(ConvertTo-Cell $Summary.Readme) |",
        '| Internal link validation | PENDING |', ''
    ) -join "`n"
}

function Show-Plan($Plan, $History, $Provenance) {
    $typesText = if ($Plan.ProjectTypes.Count) { $Plan.ProjectTypes -join ', ' } else { 'nothing' }
    $removeText = if ($Plan.Remove.Count) { ($Plan.Remove | ForEach-Object { Get-RootRelative $_.FullName }) -join ', ' } else { 'nothing present' }
    Write-Host "Project: $($Plan.DisplayName) ($($Plan.ProjectName)), GitHub owner $($Plan.Owner)"
    Write-Host "Types:   $typesText (copy; keep starters)"
    Write-Host "Remove:  $removeText"
    Write-Host "Replace: '$placeholder' and the template GitHub owner in text files; README title"
    if ($History.Initialized) {
        Write-Host 'Audits:  this project already has its own audit trail; .audits/ and AGENT_SCHEDULER.md stay as they are'
    } else {
        Write-Host "Audits:  start the project's own trail; $($History.Records.Count) template audit record(s) and the work-queue history are not inherited"
        Write-Host "Source:  $templateUrl at $($Provenance.Commit) (version: $($Provenance.Version); $($Provenance.Source))"
    }
    Write-Host 'Links:   every internal Markdown/HTML link is validated afterwards'
}

function Invoke-Setup {
    $plan = Read-Config
    $history = Get-AuditHistory
    $provenance = $null
    if (-not $history.Initialized) {
        $provenance = Get-TemplateProvenance
        if (-not $provenance) {
            throw "Cannot tell which template commit this copy came from: it is not a Git clone with origin $templateOwner/$templateRepository. Pass -TemplateCommit with the full SHA of the template commit you copied (see $templateUrl/commits), or claim a fresh clone of the template before changing its origin."
        }
    }
    $references = @(Find-RemovedReferences $plan)
    if ($references.Count) {
        $shown = @($references | Select-Object -First 40)
        $more = if ($references.Count -gt $shown.Count) { "`n  - ... and $($references.Count - $shown.Count) more" } else { '' }
        throw "Paths listed in remove are still referenced; nothing changed. Update or also remove these files first:`n  - $($shown -join "`n  - ")$more"
    }
    Show-Plan $plan $history $provenance

    $selected = $false
    if (-not $plan.ProjectTypes.Count -and -not $WhatIfPreference -and -not $Yes -and
            -not [Console]::IsInputRedirected -and [Environment]::UserInteractive) {
        if ((Read-Host 'No project types configured. Choose them now in the project-type menu? [y/N]') -match '^(y|yes)$') {
            $choice = @(& $typeSelector -SelectOnly)
            if ($choice.Count) {
                # The selection must pass the same validation as a hand-written configuration.
                $plan = Test-SetupConfig ([pscustomobject]@{
                    projectName = $plan.ProjectName; displayName = $plan.DisplayName; githubOwner = $plan.Owner
                    projectTypes = $choice; remove = $plan.RemoveEntries
                })
                $selected = $true
            }
            Show-Plan $plan $history $provenance
        }
    }

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
    if ($selected) {
        [IO.File]::WriteAllText($configPath, (ConvertTo-SetupJson $plan), $utf8)
        $saved = Read-Config
        if (($saved.ProjectTypes -join ',') -cne ($plan.ProjectTypes -join ',')) { throw 'The saved setup.config.json does not match the selected project types.' }
        Write-Host "Saved project types to setup.config.json: $($plan.ProjectTypes -join ', ')"
    }

    if ($plan.ProjectTypes.Count) { & $typeSelector -ProjectType $plan.ProjectTypes }

    $summary = @{ Removed = @(); Replaced = 0; Readme = 'not present' }
    $deferred = New-Object System.Collections.Generic.List[IO.FileSystemInfo]
    foreach ($target in $plan.Remove) {
        $relative = Get-RootRelative $target.FullName
        $summary.Removed += $relative.Replace('\', '/')
        if (Test-ContainsSetup $target) { $deferred.Add($target); continue }
        Remove-Item -LiteralPath $target.FullName -Recurse -Force
        Write-Host "Removed $relative"
    }
    $trail = if ($history.Initialized) { $null } else { Initialize-AuditTrail $history $provenance }

    $owner = $plan.Owner
    $name = $plan.ProjectName
    $changed = 0
    foreach ($file in @(Get-TextFiles $root $true)) {
        $updated = Update-TextFile $file {
            param($text)
            $updated = $templateLink.Replace($text, "github.com/$owner/$name")
            $updated.Replace("github.com/$templateOwner/$placeholder", "github.com/$owner/$name").Replace($placeholder, $name)
        }
        if ($updated) { $changed++; Write-Host "Updated $(Get-RootRelative $file.FullName)" }
    }
    $summary.Replaced = $changed
    Write-Host "Placeholder replaced in $changed file(s)."

    $readme = Join-Path $root 'README.md'
    if (Test-Path -LiteralPath $readme) {
        $heading = '# ' + $plan.DisplayName
        $retitled = Update-TextFile (Get-Item -LiteralPath $readme) {
            param($text)
            ([regex]'(?m)^# [^\r\n]*').Replace($text, $heading.Replace('$', '$$'), 1)
        }
        if ($retitled) { Write-Host "README title set to '$($plan.DisplayName)'." }
        $summary.Readme = "title set to '$($plan.DisplayName)'"
        $node = Get-Command node -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ((Test-Path -LiteralPath (Join-Path $root 'README.html')) -and (Test-Path -LiteralPath $cliPath)) {
            if ($node) {
                Push-Location $root
                try {
                    & $node.Source $cliPath readme
                    if ($LASTEXITCODE) { throw "README generation failed (exit $LASTEXITCODE)." }
                } finally { Pop-Location }
                $summary.Readme += '; README.html regenerated'
            } else {
                Write-Warning 'Node.js not found: run "node moorkyz readme" to regenerate README.html.'
                $summary.Readme += '; README.html not regenerated (Node.js not found)'
            }
        }
        # The design collection's README editions are generated from README.md as well.
        $designBuilder = Join-Path (Join-Path $root 'designs') 'build.mjs'
        if (Test-Path -LiteralPath $designBuilder -PathType Leaf) {
            if ($node) {
                Push-Location $root
                try {
                    & $node.Source $designBuilder
                    if ($LASTEXITCODE) { throw "Design collection generation failed (exit $LASTEXITCODE)." }
                } finally { Pop-Location }
                $summary.Readme += '; design README editions regenerated'
            } else {
                Write-Warning 'Node.js not found: run "node designs/build.mjs" to regenerate the README editions.'
                $summary.Readme += '; design README editions not regenerated (Node.js not found)'
            }
        }
    }

    foreach ($target in $deferred) {
        Remove-Item -LiteralPath $target.FullName -Recurse -Force
        Write-Host "Removed $(Get-RootRelative $target.FullName)"
    }
    if ($trail) {
        [IO.File]::WriteAllText($trail.RecordPath, (New-AdoptionRecord $plan $provenance $trail $summary), $utf8)
        Write-Host "Adoption record: $(Get-RootPath $trail.RecordPath)"
    }

    $validation = Test-InternalLinks
    $result = if ($validation.Broken.Count) {
        "FAIL: $($validation.Broken.Count) of $($validation.Links) local links in $($validation.Files) Markdown/HTML files are broken: " +
            ((@($validation.Broken | Select-Object -First 20) | ForEach-Object { '`' + (ConvertTo-Cell $_) + '`' }) -join ', ')
    } else {
        "PASS: $($validation.Links) local links in $($validation.Files) Markdown/HTML files resolve with exact casing"
    }
    $recordPath = if ($trail) { $trail.RecordPath } else { $history.Record }
    if ($recordPath -and (Test-Path -LiteralPath $recordPath -PathType Leaf)) {
        # Until links pass, every run records its result, so the committed record matches the committed tree.
        if (-not $trail) {
            $result += " (rerun at $((Get-Date).ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", [Globalization.CultureInfo]::InvariantCulture)) after the first validation did not pass)"
        }
        $recordText = [IO.File]::ReadAllText($recordPath)
        $recordUpdate = ([regex]'(?m)^\| Internal link validation \| (?!PASS)[^\r\n]*').Replace($recordText, "| Internal link validation | $result |".Replace('$', '$$'), 1)
        if ($recordUpdate -cne $recordText) { [IO.File]::WriteAllText($recordPath, $recordUpdate, $utf8) }
    }
    if ($validation.Broken.Count) {
        $shown = @($validation.Broken | Select-Object -First 40)
        throw "Adoption applied, but $($validation.Broken.Count) internal link(s) are broken:`n  - $($shown -join "`n  - ")`nFix them, then run this script again; it validates again and updates the adoption record."
    }
    Write-Host "Links:   PASS - $($validation.Links) local links in $($validation.Files) Markdown/HTML files"
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
