#requires -Version 5.1
<#
.SYNOPSIS
    Configure VS Code Copilot for one project, the current user, or both.
.DESCRIPTION
    Reads helpers/copilot-config.json, merges settings without dropping
    unrelated keys, creates backups, and optionally adds AGENTS.md / MCP servers.
.EXAMPLE
    .\Setup-CopilotProject.ps1 -ProjectPath 'C:\Code\my-repo'
.EXAMPLE
    .\Setup-CopilotProject.ps1 -ProjectPath . -Scope Project -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [Parameter(Position = 0)] [string] $ProjectPath = (Get-Location).Path,
    [ValidateSet('Both', 'Project', 'Global')] [string] $Scope = 'Both',
    [string] $ConfigPath,
    [ValidateSet('Stable', 'Insiders')] [string] $VSCode = 'Stable',
    [switch] $NoPause,
    [switch] $DryRun
)

if ($DryRun) {
    Write-Host '[DRY RUN] Copilot setup loaded; no settings, backups, files or external commands changed.'
    return
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $PSBoundParameters.ContainsKey('ConfigPath')) {
    $ConfigPath = Join-Path (Join-Path $PSScriptRoot 'helpers') 'copilot-config.json'
}
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$script:Updated = 0
$script:Unchanged = 0
$script:Skipped = 0
$script:Failures = New-Object System.Collections.Generic.List[string]

function Invoke-SetupStep {
    param([string] $Name, [scriptblock] $Action)
    try { & $Action }
    catch {
        $failure = "${Name}: $($_.Exception.Message)"
        $script:Failures.Add($failure)
        Write-Host "[FAIL] $failure" -ForegroundColor Red
    }
}

function Read-JsonC {
    param([string] $Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [pscustomobject]@{}
    }
    $raw = [System.IO.File]::ReadAllText($Path)
    if ([string]::IsNullOrWhiteSpace($raw)) { return [pscustomobject]@{} }

    # Remove comments outside strings; preserve newlines to aid diagnostics.
    $sb = New-Object System.Text.StringBuilder
    $inString = $false; $escaped = $false; $lineComment = $false; $blockComment = $false
    for ($i = 0; $i -lt $raw.Length; $i++) {
        $c = $raw[$i]
        $next = if ($i + 1 -lt $raw.Length) { $raw[$i + 1] } else { [char]0 }
        if ($lineComment) {
            if ($c -eq "`n" -or $c -eq "`r") {
                $lineComment = $false
                [void]$sb.Append($c)
            }
            continue
        }
        if ($blockComment) {
            if ($c -eq '*' -and $next -eq '/') { $blockComment = $false; $i++; continue }
            if ($c -eq "`n" -or $c -eq "`r") { [void]$sb.Append($c) }
            continue
        }
        if ($inString) {
            [void]$sb.Append($c)
            if ($escaped) { $escaped = $false }
            elseif ($c -eq '\') { $escaped = $true }
            elseif ($c -eq '"') { $inString = $false }
            continue
        }
        if ($c -eq '"') { $inString = $true; [void]$sb.Append($c); continue }
        if ($c -eq '/' -and $next -eq '/') { $lineComment = $true; $i++; continue }
        if ($c -eq '/' -and $next -eq '*') { $blockComment = $true; $i++; continue }
        [void]$sb.Append($c)
    }
    if ($blockComment -or $inString) { throw "Unterminated comment or string in $Path" }

    # Remove trailing commas outside strings, without touching string contents.
    $clean = $sb.ToString()
    $result = New-Object System.Text.StringBuilder
    $inString = $false; $escaped = $false
    for ($i = 0; $i -lt $clean.Length; $i++) {
        $c = $clean[$i]
        if ($inString) {
            [void]$result.Append($c)
            if ($escaped) { $escaped = $false }
            elseif ($c -eq '\') { $escaped = $true }
            elseif ($c -eq '"') { $inString = $false }
            continue
        }
        if ($c -eq '"') { $inString = $true; [void]$result.Append($c); continue }
        if ($c -eq ',') {
            $j = $i + 1
            while ($j -lt $clean.Length -and [char]::IsWhiteSpace($clean[$j])) { $j++ }
            if ($j -lt $clean.Length -and ($clean[$j] -eq '}' -or $clean[$j] -eq ']')) { continue }
        }
        [void]$result.Append($c)
    }
    try {
        $parsed = ConvertFrom-Json -InputObject $result.ToString() -ErrorAction Stop
    }
    catch { throw "Cannot parse JSON/JSONC '$Path': $($_.Exception.Message)" }
    if ($null -eq $parsed -or $parsed -isnot [pscustomobject]) {
        throw "Expected a JSON object at the root of '$Path'."
    }
    return $parsed
}

function Merge-Objects {
    param([pscustomobject] $Target, [pscustomobject] $Patch)
    foreach ($entry in $Patch.PSObject.Properties) {
        $old = $Target.PSObject.Properties[$entry.Name]
        if ($null -eq $old) {
            $Target | Add-Member -MemberType NoteProperty -Name $entry.Name -Value $entry.Value
        }
        elseif ($old.Value -is [pscustomobject] -and $entry.Value -is [pscustomobject]) {
            Merge-Objects -Target $old.Value -Patch $entry.Value
        }
        else {
            $old.Value = $entry.Value
        }
    }
}

function Write-MergedJson {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string] $Path, [pscustomobject] $Patch)
    $existing = Read-JsonC -Path $Path
    Merge-Objects -Target $existing -Patch $Patch
    $rendered = (ConvertTo-Json -InputObject $existing -Depth 100) + "`n"
    $hadFile = Test-Path -LiteralPath $Path -PathType Leaf
    if ($hadFile -and [System.IO.File]::ReadAllText($Path) -ceq $rendered) {
        $script:Unchanged++
        Write-Host "UNCHANGED $Path"
        return
    }
    if ($PSCmdlet.ShouldProcess($Path, 'Merge Copilot settings')) {
        $dir = Split-Path -Parent $Path
        if (-not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Force -Path $dir) }
        if ($hadFile) {
            $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss-fffffff'
            Copy-Item -LiteralPath $Path -Destination "$Path.bak.$timestamp" -ErrorAction Stop
        }
        [System.IO.File]::WriteAllText($Path, $rendered, $script:Utf8NoBom)
        $script:Updated++
        Write-Host "UPDATED   $Path"
    }
    else { $script:Skipped++ }
}

function Add-NewFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string] $Source, [string] $Destination)
    if (Test-Path -LiteralPath $Destination) {
        $script:Unchanged++
        Write-Host "EXISTS    $Destination (preserved)"
        return
    }
    if ($PSCmdlet.ShouldProcess($Destination, 'Create file')) {
        $parent = Split-Path -Parent $Destination
        if (-not (Test-Path -LiteralPath $parent)) {
            [void](New-Item -ItemType Directory -Path $parent -Force)
        }
        Copy-Item -LiteralPath $Source -Destination $Destination
        $script:Updated++
        Write-Host "CREATED   $Destination"
    }
    else { $script:Skipped++ }
}

try {
# Resolve inputs before writing anything.
if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    throw "Configuration not found: $ConfigPath"
}
$config = Read-JsonC -Path (Resolve-Path -LiteralPath $ConfigPath).Path
if (-not $config.PSObject.Properties['globalSettings'] -or
    -not $config.PSObject.Properties['projectSettings']) {
    throw 'Config must contain globalSettings and projectSettings JSON objects.'
}
if ($config.globalSettings -isnot [pscustomobject] -or
    $config.projectSettings -isnot [pscustomobject]) {
    throw 'globalSettings and projectSettings must be JSON objects.'
}
if ($config.PSObject.Properties['mcpServers'] -and $null -ne $config.mcpServers -and
    $config.mcpServers -isnot [pscustomobject]) {
    throw 'mcpServers must be a JSON object.'
}

if ($Scope -ne 'Global') {
    if (-not (Test-Path -LiteralPath $ProjectPath -PathType Container)) {
        throw "Project folder does not exist: $ProjectPath"
    }
    $ProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path
}

# Sandbox auto mode only enables on known supported Windows build baselines.
$sandboxMode = 'auto'
if ($config.PSObject.Properties['sandbox']) { $sandboxMode = [string]$config.sandbox }
if ($sandboxMode -notin @('auto', 'on', 'off')) { throw 'sandbox must be auto, on, or off.' }
$sandboxValue = 'off'
if ($sandboxMode -eq 'on') { $sandboxValue = 'on' }
elseif ($sandboxMode -eq 'auto') {
    if ($env:OS -eq 'Windows_NT') {
        try {
            $os = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
            $build = [int]$os.CurrentBuildNumber
            $ubr = [int]$os.UBR
            if (($build -eq 26200 -and $ubr -ge 9550) -or
                ($build -eq 28000 -and $ubr -ge 3086)) { $sandboxValue = 'on' }
        }
        catch { Write-Warning 'Windows build unknown: leaving sandbox off.' }
    }
    else {
        Write-Warning 'Sandbox auto: only Windows build baselines are auto-detected. Enable manually after checking requirements.'
    }
}
if ($sandboxMode -eq 'auto') { Write-Host "SANDBOX   $sandboxValue (detected; update/configure if needed)" }
$config.globalSettings | Add-Member -NotePropertyName 'chat.agent.sandbox.enabled' -NotePropertyValue $sandboxValue -Force

if ($Scope -in @('Both', 'Global')) {
    Invoke-SetupStep 'Global settings' {
        if ($env:OS -ne 'Windows_NT') { throw 'Global mode currently supports Windows VS Code user settings only.' }
        $codeDir = if ($VSCode -eq 'Insiders') { 'Code - Insiders' } else { 'Code' }
        $userDir = Join-Path $env:APPDATA "$codeDir\User"
        $userFile = Join-Path $userDir 'settings.json'
        Write-MergedJson -Path $userFile -Patch $config.globalSettings
    }
}

if ($Scope -in @('Both', 'Project')) {
    Invoke-SetupStep 'Project settings' {
        $workspaceFile = Join-Path $ProjectPath '.vscode\settings.json'
        Write-MergedJson -Path $workspaceFile -Patch $config.projectSettings
    }

    $makeAgents = $true
    if ($config.PSObject.Properties['createAgentsMd']) { $makeAgents = [bool]$config.createAgentsMd }
    if ($makeAgents) {
        Invoke-SetupStep 'AGENTS.md' {
            Add-NewFile -Source (Join-Path (Join-Path $PSScriptRoot 'helpers') 'AGENTS.template.md') -Destination (Join-Path $ProjectPath 'AGENTS.md')
        }
    }

    if ($config.PSObject.Properties['mcpServers'] -and $null -ne $config.mcpServers) {
        if (@($config.mcpServers.PSObject.Properties).Count -gt 0) {
            Invoke-SetupStep 'MCP settings' {
                $mcpPatch = [pscustomobject]@{ servers = $config.mcpServers }
                Write-MergedJson -Path (Join-Path $ProjectPath '.vscode\mcp.json') -Patch $mcpPatch
            }
            Write-Warning 'MCP servers require manual review and trust before use. No credentials were installed.'
        }
    }
}
}
catch {
    $script:Failures.Add("Setup validation: $($_.Exception.Message)")
}

$exitCode = 0
Write-Host "`nUpdated: $script:Updated; unchanged/preserved: $script:Unchanged; skipped: $script:Skipped; scope: $Scope"
if ($script:Failures.Count) {
    $exitCode = 1
    Write-Host "FAILED - Copilot setup has $($script:Failures.Count) failed step(s):" -ForegroundColor Red
    foreach ($failure in $script:Failures) { Write-Host "  - $failure" -ForegroundColor Red }
    Write-Host 'Successful changes were kept. Fix the listed failures and rerun setup.'
}
elseif ($WhatIfPreference) {
    Write-Host 'PREVIEW ONLY - no changes were applied. Rerun without -WhatIf to configure Copilot.'
}
elseif ($script:Skipped) {
    $exitCode = 1
    Write-Host 'INCOMPLETE - one or more changes were declined; not everything was configured.' -ForegroundColor Yellow
}
else {
    Write-Host 'ALL SET - Copilot configuration completed successfully.' -ForegroundColor Green
    Write-Host 'Start a new Copilot session. Select Autopilot manually if you want autonomous continuation.'
    Write-Host 'Settings were configured; extension installation, sign-in and model availability were not verified.'
    Write-Host 'For sandboxed Copilot sessions, type /sandbox policy to confirm effective protection.'
    Write-Host 'Managed Copilot model max-output tokens cannot be forced via settings.json.'
}

if (-not $NoPause) {
    Write-Host "`nPress any key to exit..."
    if ([Console]::IsInputRedirected) {
        Write-Host 'Input is redirected; exiting without waiting.'
    }
    else {
        try {
            $Host.UI.RawUI.FlushInputBuffer()
            [void]$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
        catch {
            Write-Host "[ERROR] Cannot read a key: $($_.Exception.Message) Use -NoPause for automation." -ForegroundColor Red
            $exitCode = 1
        }
    }
}
exit $exitCode
