#requires -Version 5.1
[CmdletBinding()]
param([switch]$DryRun)

if ($DryRun) {
    Write-Host '[DRY RUN] Would check runnable syntax and safe preview modes; nothing executed.'
    return
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$engine = (Get-Process -Id $PID).Path
$node = (Get-Command node -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$version = & $node --version
if ($LASTEXITCODE -ne 0 -or $version -notmatch '^v24\.') { throw "Node.js 24 LTS is required; found $version." }
Write-Host "Node.js $version"
$excluded = '.git', '.moorkyz', '.logs', '.archive', '.trash', 'node_modules', 'coverage', 'dist', 'build', 'tmp', '.tmp'
$extensions = '.ps1', '.cmd', '.bat', '.cjs', '.mjs', '.js', '.sh', '.py', '.exe', '.com'

function Get-Runnables([string]$Directory) {
    foreach ($entry in Get-ChildItem -LiteralPath $Directory -Force) {
        if ($excluded -contains $entry.Name) { continue }
        if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Refusing link or junction: $($entry.FullName)" }
        if ($entry.PSIsContainer) { Get-Runnables $entry.FullName }
        elseif ($extensions -contains $entry.Extension -or $entry.FullName -eq (Join-Path $root 'moorkyz')) { $entry }
    }
}

$failed = 0
foreach ($file in @(Get-Runnables $root | Sort-Object FullName)) {
    $relative = $file.FullName.Substring($root.Length + 1).Replace('\', '/')
    Write-Host "`n[CHECK] $relative"
    try {
        if ($file.Extension -eq '.ps1') {
            $tokens = $null
            $errors = $null
            $ast = [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
            if ($errors.Count) { throw ($errors.Message -join '; ') }
            if (-not $ast.ParamBlock -or
                @($ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }) -notcontains 'DryRun') {
                throw 'A side-effect-free -DryRun parameter is required; script was not executed.'
            }
            & $engine -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $file.FullName -DryRun
            if ($LASTEXITCODE -ne 0) { throw "Dry run exited with code $LASTEXITCODE." }
        }
        elseif ($file.Extension -in '.cjs', '.mjs', '.js' -or $relative -eq 'moorkyz') {
            & $node --check $file.FullName
            if ($LASTEXITCODE -ne 0) { throw "Syntax check exited with code $LASTEXITCODE." }
            if ($relative -eq 'moorkyz') {
                $help = & $node $file.FullName help
                if ($LASTEXITCODE -ne 0) { throw 'CLI help failed.' }
                $commands = @($help | ForEach-Object { if ($_ -match '^moorkyz ([a-z]+)') { $Matches[1] } })
                if (-not $commands.Count) { throw 'CLI help did not list any commands.' }
                foreach ($command in $commands) {
                    & $node $file.FullName $command --dry-run
                    if ($LASTEXITCODE -ne 0) { throw "CLI dry run failed for $command." }
                }
            }
            else { Write-Host 'Syntax only; JavaScript modules are not imported or executed.' }
        }
        elseif ($relative -eq '.template/project-types/SetProjectType.cmd') {
            if ($env:OS -eq 'Windows_NT') {
                & $env:ComSpec /d /c ('call "{0}" -DryRun' -f $file.FullName)
                if ($LASTEXITCODE -ne 0) { throw "Batch dry run exited with code $LASTEXITCODE." }
            }
            else { Write-Host '[SKIP] Windows batch execution requires Windows; the Windows CI job covers it.' }
        }
        else { throw 'No safe check is defined for this runnable; it was not executed.' }
        Write-Host "[PASS] $relative"
    }
    catch {
        $failed++
        Write-Host "[FAIL] ${relative}: $($_.Exception.Message)" -ForegroundColor Red
    }
}
if ($failed) { throw "$failed runnable check(s) failed." }
