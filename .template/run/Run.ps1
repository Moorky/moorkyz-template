#requires -Version 5.1
<#
.SYNOPSIS
Runs this project in one step: makes sure the pinned Node.js is available, then
lets `moorkyz up` check files, packages and tests (repeating only what changed)
and start the program.

.DESCRIPTION
RUN.cmd at the repository root calls this script. Node.js comes from PATH when
its major version matches .node-version, otherwise from
%LOCALAPPDATA%\Moorkyz\runtimes. When neither exists, the script offers to
download the official Windows build from nodejs.org (or MOORKYZ_NODE_MIRROR),
verifies it against the published SHA-256 checksum and keeps it there. PATH,
the registry and system settings are never changed.

Other arguments go to `moorkyz up`: a project name from moorkyz.config.json,
--no-start, --no-open or --force.

.PARAMETER Yes
Download the pinned Node.js without asking when it is missing.

.PARAMETER RuntimeOnly
Only make sure Node.js is available, then output the path of node.exe.

.EXAMPLE
.\RUN.cmd

.EXAMPLE
.\RUN.cmd --no-start
#>
[CmdletBinding()]
param(
    [switch]$Yes,
    [switch]$NoPause,
    [switch]$DryRun,
    [switch]$RuntimeOnly,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
)

if ($DryRun) {
    Write-Host '[DRY RUN] Run loaded; no runtime, packages, checks or programs were touched.'
    return
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$cli = Join-Path $root 'moorkyz'
$mirror = if ($env:MOORKYZ_NODE_MIRROR) { $env:MOORKYZ_NODE_MIRROR.TrimEnd('/') } else { 'https://nodejs.org/dist' }
$runtimes = if ($env:LOCALAPPDATA) { Join-Path (Join-Path $env:LOCALAPPDATA 'Moorkyz') 'runtimes' } else { $null }

function Get-Pin {
    $file = Join-Path $root '.node-version'
    if ((Test-Path -LiteralPath $file -PathType Leaf) -and ([IO.File]::ReadAllText($file).Trim() -match '^v?(\d+)')) {
        return [int]$Matches[1]
    }
    24
}

function Get-NodeVersion([string]$Path) {
    # Native stderr must not become a terminating error on Windows PowerShell 5.1.
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $Path --version 2>$null
        if ($LASTEXITCODE -eq 0 -and "$output".Trim() -match '^v(\d+\.\d+\.\d+)$') { return [version]$Matches[1] }
    }
    catch { }
    $null
}

function Get-Architecture {
    $name = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
    switch ($name) { 'AMD64' { 'x64' } 'ARM64' { 'arm64' } default { $null } }
}

function Find-Node([int]$Major) {
    $other = $null
    foreach ($command in @(Get-Command node -CommandType Application -All -ErrorAction SilentlyContinue)) {
        $version = Get-NodeVersion $command.Source
        if (-not $version) { continue }
        if ($version.Major -eq $Major) {
            return [pscustomobject]@{ Match = [pscustomobject]@{ Path = $command.Source; Version = $version }; Other = $null }
        }
        if (-not $other) { $other = [pscustomobject]@{ Path = $command.Source; Version = $version } }
    }
    $arch = Get-Architecture
    if ($runtimes -and $arch -and (Test-Path -LiteralPath $runtimes -PathType Container)) {
        $local = @(Get-ChildItem -LiteralPath $runtimes -Directory -Filter "node-v$Major.*-win-$arch" -ErrorAction SilentlyContinue | ForEach-Object {
                $exe = Join-Path $_.FullName 'node.exe'
                $version = if (Test-Path -LiteralPath $exe -PathType Leaf) { Get-NodeVersion $exe } else { $null }
                if ($version -and $version.Major -eq $Major) { [pscustomobject]@{ Path = $exe; Version = $version } }
            } | Sort-Object Version -Descending)
        if ($local.Count) { return [pscustomobject]@{ Match = $local[0]; Other = $other } }
    }
    [pscustomobject]@{ Match = $null; Other = $other }
}

function Install-Node([int]$Major, $Other) {
    $arch = Get-Architecture
    if ($env:OS -ne 'Windows_NT' -or -not $arch -or -not $runtimes) {
        throw "Node.js $Major is required. Install Node.js $Major LTS from https://nodejs.org, then run again."
    }
    if ($PSVersionTable.PSEdition -ne 'Core') {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }
    $ProgressPreference = 'SilentlyContinue'
    $index = "$mirror/latest-v$Major.x/SHASUMS256.txt"
    try { $content = (Invoke-WebRequest -UseBasicParsing -Uri $index).Content }
    catch { throw "Node.js $Major is required, and the download list at $index could not be read: $($_.Exception.Message) Check the connection, or install Node.js $Major LTS." }
    if ($content -is [byte[]]) { $content = [Text.Encoding]::UTF8.GetString($content) }
    $pattern = "^([0-9a-fA-F]{64})\s+(node-v($Major\.\d+\.\d+)-win-$arch\.zip)\s*$"
    $entry = @(([string]$content -split "`n") | Where-Object { $_ -match $pattern } | Select-Object -First 1)
    if (-not $entry.Count) { throw "No Node.js $Major build for Windows $arch is listed at $index." }
    [void]($entry[0] -match $pattern)
    $expected = $Matches[1]
    $file = $Matches[2]
    $version = $Matches[3]
    $found = if ($Other) { "found Node.js $($Other.Version) at $($Other.Path)" } else { 'Node.js was not found' }

    Write-Host ''
    Write-Host '  MOORKYZ  Runtime' -ForegroundColor White
    Write-Host ''
    Write-Host "  This project needs Node.js $Major; $found."
    Write-Host "  Download the official Node.js $version for Windows $arch from $mirror,"
    Write-Host "  verify its SHA-256 checksum and keep it in ${runtimes}?"
    Write-Host '  PATH, the registry and system settings stay unchanged.' -ForegroundColor DarkGray
    if (-not $Yes) {
        if ([Console]::IsInputRedirected -or -not [Environment]::UserInteractive) {
            throw "Node.js $Major is required. Run RUN.cmd in a terminal to download it, pass -Yes, or install Node.js $Major LTS."
        }
        $answer = Read-Host '  Download now? [Y/n]'
        if ($answer -and $answer -notmatch '^(y|yes)$') {
            throw "Cancelled; nothing was downloaded. Install Node.js $Major LTS, or run again and answer Y."
        }
    }

    $staging = Join-Path $runtimes ('.download-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
    [void][IO.Directory]::CreateDirectory($staging)
    try {
        $zip = Join-Path $staging $file
        Write-Host "  Downloading $file ..." -ForegroundColor DarkGray
        try { Invoke-WebRequest -UseBasicParsing -Uri "$mirror/v$version/$file" -OutFile $zip }
        catch { throw "Downloading $file failed: $($_.Exception.Message) Nothing was installed." }
        $stream = [IO.File]::OpenRead($zip)
        try { $actual = -join ([Security.Cryptography.SHA256]::Create().ComputeHash($stream) | ForEach-Object { $_.ToString('x2') }) }
        finally { $stream.Dispose() }
        if ($actual -ne $expected) {
            throw "Checksum mismatch for $file (expected $($expected.ToLowerInvariant()), received $($actual.ToLowerInvariant())). The download was deleted; nothing was installed."
        }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $extracted = Join-Path $staging 'x'
        [IO.Compression.ZipFile]::ExtractToDirectory($zip, $extracted)
        $folder = "node-v$version-win-$arch"
        if (-not (Test-Path -LiteralPath (Join-Path (Join-Path $extracted $folder) 'node.exe') -PathType Leaf)) {
            throw "The verified archive has no $folder\node.exe; nothing was installed."
        }
        $target = Join-Path $runtimes $folder
        if (-not (Test-Path -LiteralPath $target)) { Move-Item -LiteralPath (Join-Path $extracted $folder) -Destination $target }
        $installed = Join-Path $target 'node.exe'
        $actualVersion = Get-NodeVersion $installed
        if (-not $actualVersion -or $actualVersion.ToString() -ne $version) { throw "$installed does not report Node.js $version." }
        Write-Host "  Checksum verified; Node.js $version is ready." -ForegroundColor Green
        [pscustomobject]@{ Path = $installed; Version = $actualVersion }
    }
    finally { Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue }
}

$exitCode = 0
try {
    if (-not (Test-Path -LiteralPath $cli -PathType Leaf)) { throw "The moorkyz CLI is missing at $cli." }
    $pin = Get-Pin
    $search = Find-Node $pin
    $node = if ($search.Match) { $search.Match } else { Install-Node $pin $search.Other }
    if ($RuntimeOnly) {
        Write-Output $node.Path
    }
    else {
        # Child tools such as npm use the same Node.js; PATH changes only for this run.
        $env:PATH = (Split-Path -Parent $node.Path) + [IO.Path]::PathSeparator + $env:PATH
        Push-Location -LiteralPath $root
        try {
            & $node.Path $cli up @Arguments
            $exitCode = $LASTEXITCODE
        }
        finally { Pop-Location }
    }
}
catch {
    Write-Host ''
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    $exitCode = 1
}
if ($exitCode -ne 0 -and -not $NoPause -and -not $RuntimeOnly -and -not [Console]::IsInputRedirected -and [Environment]::UserInteractive) {
    Write-Host ''
    Write-Host '  Press any key to close.'
    try {
        $Host.UI.RawUI.FlushInputBuffer()
        [void]$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
    catch { }
}
exit $exitCode
