#Requires -Version 5.1
<#
.SYNOPSIS
  Opens every HTML file under the designs folder in the default browser.
.PARAMETER DryRun
  Lists the files that would be opened without opening anything.
.EXAMPLE
  pwsh -NoProfile -File .\designs\OpenAll.ps1 -DryRun
#>
[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$files = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter *.html -File -Recurse |
    Sort-Object FullName)

if ($files.Count -eq 0) {
    Write-Host "No HTML files found under $PSScriptRoot."
    return
}

foreach ($file in $files) {
    $relative = $file.FullName.Substring($PSScriptRoot.Length).TrimStart('\', '/')
    if ($DryRun) {
        Write-Host "Would open: $relative"
        continue
    }
    Write-Host "Opening: $relative"
    Start-Process -FilePath $file.FullName
    # Short pause so the browser does not drop tabs when flooded with requests.
    Start-Sleep -Milliseconds 150
}

$verb = if ($DryRun) { 'Would open' } else { 'Opened' }
Write-Host "$verb $($files.Count) HTML file(s)."
