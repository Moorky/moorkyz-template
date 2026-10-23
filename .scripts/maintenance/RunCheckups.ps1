#requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$NoPause,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$exitCode = 0
$passed = 0
$failed = 0
try {
    $directory = Join-Path (Join-Path $PSScriptRoot 'helpers') 'checkups'
    $entry = Get-Item -LiteralPath $directory -Force
    if (-not $entry.PSIsContainer -or ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw 'checkups must be a regular directory, not a link or junction.'
    }
    $checkups = @(Get-ChildItem -LiteralPath $directory -File -Filter '*.ps1' -Force | Sort-Object Name)
    if (-not $checkups.Count) { throw 'No PowerShell checkups found in .scripts/maintenance/helpers/checkups.' }
    if ($DryRun) {
        $checkups | ForEach-Object { Write-Host "[DRY RUN] Would run $($_.Name)" }
        return
    }

    $engine = (Get-Process -Id $PID).Path
    Push-Location (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    try {
        foreach ($checkup in $checkups) {
            Write-Host "`n[RUN] $($checkup.Name)"
            try {
                if ($checkup.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                    throw 'Refusing a linked checkup.'
                }
                & $engine -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $checkup.FullName
                if ($LASTEXITCODE -ne 0) { throw "Checkup exited with code $LASTEXITCODE." }
                $passed++
                Write-Host "[PASS] $($checkup.Name)" -ForegroundColor Green
            }
            catch {
                $failed++
                Write-Host "[FAIL] $($checkup.Name): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    finally { Pop-Location }
    Write-Host "`nCheckups finished: $passed passed, $failed failed ($($checkups.Count) total)."
    if ($failed) { $exitCode = 1 }
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    $exitCode = 1
}

if (-not $NoPause -and -not $DryRun) {
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
