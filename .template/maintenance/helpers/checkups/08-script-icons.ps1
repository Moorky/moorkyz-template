#requires -Version 5.1
[CmdletBinding()]
param([switch]$DryRun)
if ($DryRun) { Write-Host '[DRY RUN] Would verify script icons in disposable fixtures; no shortcuts or files changed.'; return }

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$tool = Join-Path $root '.template\script-icons'
$engines = @((Get-Process -Id $PID).Path)
if ($env:OS -eq 'Windows_NT') {
    foreach ($name in 'pwsh', 'powershell.exe') {
        $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command -and $engines -notcontains $command.Source) { $engines += $command.Source }
    }
}
$workspace = Join-Path ([IO.Path]::GetTempPath()) ('moorkyz script icons ' + [Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($workspace)
$groups = 0

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Get-Snapshot([string]$Directory, [switch]$SkipOutput) {
    @(Get-ChildItem -LiteralPath $Directory -Recurse -Force | Where-Object {
        -not $SkipOutput -or $_.FullName -notmatch '\\\.moorkyz(?:\\|$)'
    } | ForEach-Object {
        $relative = $_.FullName.Substring($Directory.Length)
        if ($_.PSIsContainer) { "DIR $relative" }
        else { "$relative $((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)" }
    } | Sort-Object) -join "`n"
}

function Invoke-Tool([string]$Engine, [string]$Directory, [string]$Flags = '') {
    $entry = (Join-Path $Directory '.template\script-icons\SetScriptIcons.ps1').Replace("'", "''")
    $script = "try { & '$entry' $Flags; exit 0 } catch { Write-Host ('ERROR: ' + `$_.Exception.Message); exit 1 }"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))
    $text = & $Engine -NoLogo -NoProfile -NonInteractive -EncodedCommand $encoded 2>&1
    [pscustomobject]@{ Code = $LASTEXITCODE; Text = $text -join "`n" }
}

try {
    foreach ($engine in $engines) {
        $fixture = Join-Path $workspace ([Guid]::NewGuid().ToString('N') + " repo's & spaces")
        $fixtureTool = Join-Path $fixture '.template\script-icons'
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $fixtureTool))
        Copy-Item -LiteralPath $tool -Destination $fixtureTool -Recurse
        $files = @{
            "run space's & name.ps1" = 'throw "Fixture must never execute"'
            '.template\maintenance\helpers\checkups\01-example.ps1' = 'throw "Never execute"'
            '.template\example\helpers\Library.ps1' = 'function Get-Example {}'
            'selector.cmd' = '@exit /b 99'
            'other.bat' = '@exit /b 99'
            'do not execute.exe' = 'Disposable placeholder, not executable'
            'legacy.com' = 'Disposable placeholder, not executable'
            'build.mjs' = 'throw new Error("Never execute");'
            'verify-report.mjs' = 'throw new Error("Never execute");'
            'example.test.mjs' = 'throw new Error("Never execute");'
            'node-tool.cjs' = "#!/usr/bin/env node`nthrow new Error('Never execute');"
            'moorkyz' = "#!/usr/bin/env node`nthrow new Error('Never execute');"
            'browser.js' = 'document.title = "Browser only";'
            'library.mjs' = 'export const example = true;'
            'eslint.config.mjs' = 'export default [];'
            'unsupported.py' = 'raise RuntimeError("Never execute")'
            'node_modules\ignored.ps1' = 'throw "Ignore dependency"'
            '.logs\ignored.ps1' = 'throw "Ignore runtime data"'
        }
        foreach ($name in $files.Keys) {
            $path = Join-Path $fixture $name
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $path))
            [IO.File]::WriteAllText($path, $files[$name])
        }
        if ($env:OS -eq 'Windows_NT') {
            foreach ($name in 'do not execute.exe', 'legacy.com') {
                Copy-Item -LiteralPath (Join-Path $env:SystemRoot 'System32\where.exe') -Destination (Join-Path $fixture $name)
            }
        }
        $before = Get-Snapshot $fixture
        $result = Invoke-Tool $engine $fixture '-DryRun'
        Assert-True ($result.Code -eq 0) $result.Text
        Assert-True ((Get-Snapshot $fixture) -ceq $before) 'DryRun changed the fixture.'
        $groups++

        if ($env:OS -ne 'Windows_NT') {
            $result = Invoke-Tool $engine $fixture
            Assert-True ($result.Code -ne 0 -and $result.Text -match 'require Windows') $result.Text
            Assert-True ((Get-Snapshot $fixture) -ceq $before) 'Unsupported platform changed the fixture.'
            Write-Host '[SKIP] Windows COM shortcut assertions require Windows.'
            $groups++
            continue
        }
        $result = Invoke-Tool $engine $fixture '-WhatIf'
        Assert-True ($result.Code -eq 0) $result.Text
        Assert-True ((Get-Snapshot $fixture) -ceq $before) 'WhatIf changed the fixture.'
        $groups++

        $result = Invoke-Tool $engine $fixture
        Assert-True ($result.Code -eq 0) $result.Text
        Assert-True ((Get-Snapshot $fixture -SkipOutput) -ceq $before) 'Icon generation modified original source.'
        $output = Join-Path $fixture '.moorkyz\script-icons'
        $inventory = @(Get-Content -LiteralPath (Join-Path $output 'inventory.json') -Raw | ConvertFrom-Json)
        $launchers = @($inventory | Where-Object Status -eq 'Shortcut')
        $skipped = @($inventory | Where-Object Status -eq 'Skipped')
        Assert-True ($launchers.Count -eq 11) "Expected 11 runnable shortcuts; found $($launchers.Count)."
        Assert-True ($skipped.Count -eq 6) "Expected 6 supporting/unsupported sources; found $($skipped.Count)."
        Assert-True (@($skipped | Where-Object { -not $_.Reason }).Count -eq 0) 'Skipped source lacks a reason.'
        Assert-True (@(Get-ChildItem -LiteralPath $output -Filter '*.lnk' -Recurse).Count -eq 11) 'Shortcut count differs from inventory.'
        $groups++

        Add-Type -AssemblyName System.Drawing
        $iconPath = Join-Path $fixtureTool 'helpers\moorkyz.ico'
        $icon = New-Object Drawing.Icon($iconPath)
        try { Assert-True ($icon.Width -gt 0 -and $icon.Height -gt 0) 'Icon cannot be decoded.' }
        finally { $icon.Dispose() }
        Assert-True ((Get-FileHash -LiteralPath $iconPath).Hash -ceq
            (Get-FileHash -LiteralPath (Join-Path $tool 'helpers\moorkyz.ico')).Hash) 'Icon bytes changed.'
        $shell = New-Object -ComObject WScript.Shell
        try {
            foreach ($item in $launchers) {
                $shortcut = $shell.CreateShortcut($item.Shortcut)
                try {
                    Assert-True ($shortcut.TargetPath -ieq $item.Target) "Wrong target: $($item.File)"
                    Assert-True ($shortcut.Arguments -ceq $item.Arguments) "Wrong arguments: $($item.File)"
                    Assert-True ($shortcut.WorkingDirectory -ieq $fixture) "Wrong working directory: $($item.File)"
                    Assert-True ($shortcut.IconLocation -ieq "$iconPath,0") "Wrong icon: $($item.File)"
                    Assert-True ($shortcut.Description -ceq "Moorkyz: $($item.File)") "Wrong description: $($item.File)"
                    if ($item.File -like '*.ps1') {
                        Assert-True ($item.Target -ieq $engine) 'PowerShell shortcut uses the wrong host.'
                        Assert-True ($item.Arguments -ceq ('-NoLogo -NoProfile -NoExit -File "{0}"' -f (Join-Path $fixture $item.File))) 'PowerShell argument quoting changed.'
                    }
                    elseif ($item.File -match '\.(cmd|bat|exe)$') {
                        Assert-True ($item.Target -ieq (Join-Path $fixture $item.File) -and $item.Arguments -eq '') 'Native shortcut changes invocation.'
                    }
                    else {
                        $node = (Get-Command node -CommandType Application | Select-Object -First 1).Source
                        Assert-True ($item.Target -ieq $node -and
                            $item.Arguments -ceq ('"{0}"' -f (Join-Path $fixture $item.File))) 'Node shortcut changes invocation.'
                    }
                }
                finally { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut) }
            }
        }
        finally { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell) }
        $groups++

        $after = Get-Snapshot $fixture
        $result = Invoke-Tool $engine $fixture
        Assert-True ($result.Code -ne 0 -and $result.Text -match 'would be overwritten') $result.Text
        Assert-True ((Get-Snapshot $fixture) -ceq $after) 'Rerun overwrote existing output.'
        $groups++

        $blocked = Join-Path $workspace ([Guid]::NewGuid().ToString('N') + ' blocked')
        [void][IO.Directory]::CreateDirectory((Join-Path $blocked '.template'))
        Copy-Item -LiteralPath $tool -Destination (Join-Path $blocked '.template\script-icons') -Recurse
        [IO.File]::WriteAllText((Join-Path $blocked '.moorkyz'), 'existing user file')
        $beforeBlocked = Get-Snapshot $blocked
        $result = Invoke-Tool $engine $blocked
        Assert-True ($result.Code -ne 0 -and $result.Text -match 'not a directory') $result.Text
        Assert-True ((Get-Snapshot $blocked) -ceq $beforeBlocked) 'Output conflict changed user data.'
        $groups++

        $linked = Join-Path $workspace ([Guid]::NewGuid().ToString('N') + ' linked')
        $outside = Join-Path $workspace ([Guid]::NewGuid().ToString('N') + ' outside')
        [void][IO.Directory]::CreateDirectory((Join-Path $linked '.template'))
        [void][IO.Directory]::CreateDirectory($outside)
        Copy-Item -LiteralPath $tool -Destination (Join-Path $linked '.template\script-icons') -Recurse
        $junction = Join-Path $linked '.moorkyz'
        [void](New-Item -ItemType Junction -Path $junction -Target $outside)
        try {
            $result = Invoke-Tool $engine $linked
            Assert-True ($result.Code -ne 0 -and $result.Text -match 'Refusing link or junction') $result.Text
            Assert-True (@(Get-ChildItem -LiteralPath $outside -Force).Count -eq 0) 'Output followed a junction.'
        }
        finally { [IO.Directory]::Delete($junction) }
        $groups++

        $sourceJunction = Join-Path $linked 'linked-source'
        [void](New-Item -ItemType Junction -Path $sourceJunction -Target $outside)
        try {
            $result = Invoke-Tool $engine $linked
            Assert-True ($result.Code -ne 0 -and $result.Text -match 'Refusing link or junction') $result.Text
            Assert-True (-not (Test-Path -LiteralPath (Join-Path $linked '.moorkyz'))) 'Source junction refusal created output.'
        }
        finally { [IO.Directory]::Delete($sourceJunction) }
        $groups++

        $result = Invoke-Tool $engine $linked
        Assert-True ($result.Code -eq 0) $result.Text
        $singletonJson = Get-Content -LiteralPath (Join-Path $linked '.moorkyz\script-icons\inventory.json') -Raw
        Assert-True ($singletonJson -match '^\s*\[' -and @($singletonJson | ConvertFrom-Json).Count -eq 1) 'Single-script inventory must remain a JSON array.'
        $groups++

        $missingIcon = Join-Path $blocked '.template\script-icons\helpers\moorkyz.ico'
        Remove-Item -LiteralPath $missingIcon
        $beforeMissingIcon = Get-Snapshot $blocked
        $result = Invoke-Tool $engine $blocked
        Assert-True ($result.Code -ne 0 -and $result.Text -match 'Missing shortcut icon') $result.Text
        Assert-True ((Get-Snapshot $blocked) -ceq $beforeMissingIcon) 'Missing icon caused writes.'
        $groups++
        Write-Host "[PASS] Script icon properties and safety on $engine"
    }
    Write-Host "[PASS] $groups script-icon regression groups; original scripts never executed."
}
finally { Remove-Item -LiteralPath $workspace -Recurse -Force }
