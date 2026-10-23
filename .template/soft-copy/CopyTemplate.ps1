#requires -Version 5.1
<#
.SYNOPSIS
Copies selected template files to another directory, preserving existing files.
.DESCRIPTION
Without -NoGui, opens a lightweight Windows folder/file picker. Force copy is
opt-in and never deletes source files. Content pairs stay in a local JSON report.
Recovery snapshots enable an explicit revert without discarding later edits.
.EXAMPLE
powershell -NoProfile -STA -File .\.template\soft-copy\CopyTemplate.ps1
.EXAMPLE
.\.template\soft-copy\CopyTemplate.ps1 -NoGui -TargetDirectory C:\repos\app -File AGENTS.md,moorkyz -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Copy')]
param(
    [switch]$DryRun,
    [string]$TargetDirectory,
    [Parameter(ParameterSetName = 'Copy')][string[]]$File,
    [Parameter(ParameterSetName = 'Copy')][switch]$ForceCopy,
    [switch]$NoGui,
    [Parameter(ParameterSetName = 'Revert')][string]$Revert
)

if ($DryRun) {
    Write-Host '[DRY RUN] Template copy loaded; no GUI, reads, copies or reports.'
    return
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $PSScriptRoot 'helpers\CopyCore.ps1')

if ($PSCmdlet.ParameterSetName -eq 'Revert') {
    $plan = New-TemplateRevertPlan -Root $root -TargetDirectory $TargetDirectory -RecoveryPath $Revert
    if ($PSCmdlet.ShouldProcess($plan.Target, "Revert copy using $($plan.Path)")) {
        $result = Invoke-TemplateRevertPlan $plan
        Write-Host "Reverted - restored: $($result.Restored); removed: $($result.Removed)."
        $result
    }
    return
}

if ($NoGui -or $WhatIfPreference) {
    $plan = New-TemplateCopyPlan -Root $root -TargetDirectory $TargetDirectory -File $File -ForceCopy:$ForceCopy
    if ($PSCmdlet.ShouldProcess($plan.Target, "Copy $($plan.Copies.Count) files; record $($plan.Conflicts.Count) content pairs")) {
        $result = Invoke-TemplateCopyPlan $plan
        Write-Host "Copied: $($result.Copied); replaced: $($result.Replaced); preserved: $($result.Preserved)."
        Write-Host "Content pairs (local, potentially sensitive): $($result.ReportPath)"
        if ($result.RecoveryPath) { Write-Host "Revert snapshot (keep local): $($result.RecoveryPath)" }
        $result
    }
    return
}

if ($env:OS -ne 'Windows_NT') {
    throw 'The GUI requires Windows. Use -NoGui -TargetDirectory <directory> -File <relative paths> instead.'
}
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    throw 'The GUI requires STA. Relaunch with powershell -NoProfile -STA -File .\.template\soft-copy\CopyTemplate.ps1'
}
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
. (Join-Path $PSScriptRoot 'helpers\CopyGui.ps1')
$ui = New-TemplateCopyForm -Root $root -TargetDirectory $TargetDirectory -File $File -ForceCopy:$ForceCopy
try { [void]$ui.Form.ShowDialog() }
finally { $ui.Form.Dispose() }
