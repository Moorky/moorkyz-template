#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param([switch]$DryRun)

if ($DryRun) {
    Write-Host '[DRY RUN] Script icons loaded; no inventory, shortcuts or settings changed.'
    return
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($env:OS -ne 'Windows_NT') { throw 'Script icon shortcuts require Windows. No files changed.' }
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$icon = Join-Path $PSScriptRoot 'helpers\moorkyz.ico'
$output = Join-Path $root '.moorkyz\script-icons'
$excluded = '.git', '.moorkyz', '.logs', '.archive', 'node_modules', 'coverage', 'dist', 'build', 'tmp', '.tmp'
$extensions = '.ps1', '.cmd', '.bat', '.exe', '.com', '.js', '.cjs', '.mjs', '.sh', '.py', '.vbs', '.wsf'

function Assert-RegularPath([string]$Path) {
    $current = [IO.Path]::GetFullPath($Path)
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            $entry = Get-Item -LiteralPath $current -Force
            if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Refusing link or junction: $current" }
        }
        $current = Split-Path -Parent $current
    }
}

function Get-ScriptFiles([string]$Directory) {
    foreach ($entry in Get-ChildItem -LiteralPath $Directory -Force | Sort-Object Name) {
        if ($excluded -contains $entry.Name) { continue }
        if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Refusing link or junction: $($entry.FullName)" }
        if ($entry.PSIsContainer) { Get-ScriptFiles $entry.FullName }
        elseif ($extensions -contains $entry.Extension -or
            ($entry.Extension -eq '' -and (Get-Content -LiteralPath $entry.FullName -TotalCount 1) -match '^#!')) {
            $entry
        }
    }
}

Assert-RegularPath $root
Assert-RegularPath $icon
Assert-RegularPath $output
if (-not (Test-Path -LiteralPath $icon -PathType Leaf)) { throw "Missing shortcut icon: $icon" }
$bytes = [IO.File]::ReadAllBytes($icon)
if ($bytes.Length -lt 6 -or [BitConverter]::ToUInt32($bytes, 0) -ne 65536 -or
    [BitConverter]::ToUInt16($bytes, 4) -eq 0) { throw "Not a valid ICO header: $icon" }
$engine = (Get-Process -Id $PID).Path
$node = $null
$inventory = @(
    foreach ($file in @(Get-ScriptFiles $root)) {
        $relative = $file.FullName.Substring($root.Length + 1)
        $target = $null
        $arguments = ''
        $reason = ''
        if ($file.Extension -eq '.ps1') {
            if ($relative -match '\\helpers\\' -and $relative -notmatch '\\maintenance\\helpers\\checkups\\') {
                $reason = 'Supporting PowerShell module; run its owning entrypoint instead.'
            }
            else {
                $target = $engine
                $arguments = '-NoLogo -NoProfile -NoExit -File "{0}"' -f $file.FullName
            }
        }
        elseif ($file.Extension -in '.cmd', '.bat', '.exe') {
            $target = $file.FullName
        }
        elseif ($file.Extension -in '.js', '.cjs', '.mjs', '' -and
            ($file.Name -match '^(build|verify(?:-[^.]+)?)\.mjs$' -or $file.Name -match '\.test\.mjs$' -or
            (Get-Content -LiteralPath $file.FullName -TotalCount 1) -match '^#!.*\bnode\b')) {
            if (-not $node) {
                $node = (Get-Command node -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
            }
            $target = $node
            $arguments = '"{0}"' -f $file.FullName
        }
        else {
            $reason = 'Browser/configuration/library source or no supported standalone launcher; left unchanged.'
        }
        [pscustomobject]@{
            File = $relative
            Status = if ($target) { 'Shortcut' } else { 'Skipped' }
            Reason = $reason
            Target = $target
            Arguments = $arguments
            Shortcut = if ($target) { Join-Path $output ($relative + '.lnk') } else { $null }
        }
    }
)
if (-not $inventory.Count) { throw "No scripts or executables found under $root." }

$manifest = Join-Path $output 'inventory.json'
foreach ($path in @($manifest) + @($inventory | Where-Object Target | ForEach-Object Shortcut)) {
    Assert-RegularPath $path
    if (Test-Path -LiteralPath $path) { throw "Existing icon output would be overwritten: $path. Preserve it or use a fresh template copy." }
    $parent = Split-Path -Parent $path
    while ($parent -and $parent.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
        if ((Test-Path -LiteralPath $parent) -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
            throw "Output parent is not a directory: $parent"
        }
        $parent = Split-Path -Parent $parent
    }
}

$launchers = @($inventory | Where-Object Target)
if (-not $PSCmdlet.ShouldProcess($output, "Create $($launchers.Count) Moorkyz icon shortcuts and a script inventory")) { return }
$shell = New-Object -ComObject WScript.Shell
try {
    foreach ($item in $launchers) {
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $item.Shortcut))
        $shortcut = $shell.CreateShortcut($item.Shortcut)
        try {
            $shortcut.TargetPath = $item.Target
            $shortcut.Arguments = $item.Arguments
            $shortcut.WorkingDirectory = $root
            $shortcut.Description = "Moorkyz: $($item.File)"
            $shortcut.IconLocation = "$icon,0"
            $shortcut.Save()
            if (-not (Test-Path -LiteralPath $item.Shortcut -PathType Leaf)) {
                throw "Windows did not save the shortcut: $($item.Shortcut)"
            }
        }
        finally { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut) }
        Write-Host "[ICON] $($item.File)"
    }
    [void][IO.Directory]::CreateDirectory($output)
    ConvertTo-Json -InputObject $inventory -Depth 3 | Set-Content -LiteralPath $manifest -Encoding UTF8
}
finally { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell) }
foreach ($item in @($inventory | Where-Object { -not $_.Target })) { Write-Host "[SKIP] $($item.File): $($item.Reason)" }
Write-Host "Created $($launchers.Count) branded shortcuts in $output"
Write-Host "Inventory: $manifest. Original files and file associations are unchanged; no targets were executed."
