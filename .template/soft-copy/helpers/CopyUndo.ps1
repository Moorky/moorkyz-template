#requires -Version 5.1
[CmdletBinding()]
param([switch]$DryRun)
if ($DryRun) { Write-Host '[DRY RUN] Recovery helpers loaded; no snapshots or files accessed.'; return }

function Get-CopyByteHash([byte[]]$Bytes) {
    $hash = [Security.Cryptography.SHA256]::Create()
    try { [BitConverter]::ToString($hash.ComputeHash($Bytes)).Replace('-', '') }
    finally { $hash.Dispose() }
}

function Read-CopyStream([IO.Stream]$Stream) {
    $bytes = New-Object byte[] $Stream.Length
    $offset = 0
    while ($offset -lt $bytes.Length) {
        $read = $Stream.Read($bytes, $offset, $bytes.Length - $offset)
        if (-not $read) { throw 'Unexpected end of file while checking recovery bytes.' }
        $offset += $read
    }
    ,$bytes
}

function Write-CopyJson([string]$Path, $Value, [switch]$New) {
    Assert-CopyPath $Path
    $temporary = "$Path.$([Guid]::NewGuid().ToString('N')).tmp"
    $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes((ConvertTo-Json -InputObject $Value -Depth 6))
    try {
        $stream = [IO.File]::Open($temporary, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush() }
        finally { $stream.Dispose() }
        Assert-CopyPath $Path
        if ($New) { [IO.File]::Move($temporary, $Path) }
        else { [IO.File]::Replace($temporary, $Path, [NullString]::Value) }
    }
    finally { if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) } }
}

function Open-CopyRecoveryLock([string]$Path) {
    $lock = "$Path.lock"
    Assert-CopyPath $lock
    [IO.File]::Open($lock, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
}

function Get-CopyRecoveryTarget([string]$Target, [string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name) -or $Name -match '\\|:|^/|//|/$|(^|/)\.\.?(/|$)' -or
        ($Name.Split('/') | Where-Object {
            $_ -in '.git', '.moorkyz', '.logs', '.archive', '.audits' -or
            $_ -match '[. ]$' -or $_.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0
        })) {
        throw "Invalid recovery relative path: $Name"
    }
    $path = [IO.Path]::GetFullPath((Join-Path $Target $Name))
    $comparison = if ($env:OS -eq 'Windows_NT') { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    if (-not $path.StartsWith($Target + [IO.Path]::DirectorySeparatorChar, $comparison)) {
        throw "Recovery path escapes its target: $Name"
    }
    Assert-CopyPath $path
    $path
}

function New-TemplateRevertPlan([string]$Root, [string]$TargetDirectory, [string]$RecoveryPath) {
    $target = Get-CopyTargetRoot $Root $TargetDirectory
    $rootPath = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    if ([string]::IsNullOrWhiteSpace($RecoveryPath)) { throw 'Choose a recovery snapshot.' }
    $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RecoveryPath)
    $directory = Join-Path $rootPath '.moorkyz\soft-copy'
    if ((Split-Path -Parent $path) -ne $directory -or
        [IO.Path]::GetFileName($path) -notmatch '^recovery-\d{8}T\d{9}Z-[a-f0-9]{32}\.json$') {
        throw 'Recovery must be an original recovery-*.json snapshot in this template .moorkyz\soft-copy directory.'
    }
    Assert-CopyPath $path
    $journal = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($path))
    if ($journal.version -ne 1 -or $journal.source -cne $rootPath -or $journal.target -cne $target) {
        throw 'Recovery snapshot source or target does not match this request.'
    }
    if ($journal.status -notin 'ready', 'failed', 'reverting') { throw "Recovery is not available (state: $($journal.status))." }
    if ($journal.files -isnot [array] -or $journal.directories -isnot [array]) { throw 'Invalid recovery file/directory lists.' }
    $comparer = if ($env:OS -eq 'Windows_NT') { [StringComparer]::OrdinalIgnoreCase } else { [StringComparer]::Ordinal }
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' $comparer
    $actions = New-Object 'System.Collections.Generic.List[object]'
    foreach ($file in $journal.files) {
        $destination = Get-CopyRecoveryTarget $target $file.name
        if (-not $seen.Add($destination) -or $file.existed -isnot [bool] -or
            $file.state -notin 'pending', 'applied', 'reverted' -or $file.afterHash -notmatch '^[A-F0-9]{64}$') {
            throw "Invalid recovery file record: $($file.name)"
        }
        $before = $null
        $lastWrite = $null
        if ($file.existed) {
            $before = [Convert]::FromBase64String($file.before)
            if ((Get-CopyByteHash $before) -cne $file.beforeHash) { throw "Corrupt recovery backup: $($file.name)" }
            $lastWrite = if ($file.lastWrite -is [DateTime]) { $file.lastWrite.ToUniversalTime() }
                else { [DateTime]::Parse($file.lastWrite, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind) }
        }
        elseif ($null -ne $file.before -or $null -ne $file.beforeHash -or $null -ne $file.lastWrite) { throw "Invalid new-file recovery record: $($file.name)" }
        if ($file.state -ne 'applied') { continue }
        $exists = Test-Path -LiteralPath $destination
        $alreadyRestored = -not $exists -and -not $file.existed
        if ($exists) {
            if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) { throw "Recovery target is not a file: $destination" }
            $currentHash = Get-CopyByteHash ([IO.File]::ReadAllBytes($destination))
            $alreadyRestored = $file.existed -and $currentHash -ceq (Get-CopyByteHash $before)
            if (-not $alreadyRestored -and $currentHash -cne $file.afterHash) {
                throw "File changed since copy; refusing to revert: $destination"
            }
            if (-not $alreadyRestored -and ((Get-Item -LiteralPath $destination -Force).Attributes -band [IO.FileAttributes]::ReadOnly)) {
                throw "Cannot revert a read-only file: $destination"
            }
        }
        elseif ($file.existed) { throw "File removed since copy; refusing to revert: $destination" }
        $actions.Add([pscustomobject]@{ File = $file; Path = $destination; Before = $before; LastWrite = $lastWrite; AlreadyRestored = $alreadyRestored })
    }
    $directories = @(foreach ($name in $journal.directories) { Get-CopyRecoveryTarget $target $name })
    [pscustomobject]@{ Root = $rootPath; Target = $target; Path = $path; Journal = $journal; Actions = $actions; Directories = $directories }
}

function Invoke-TemplateRevertPlan($Plan) {
    $lock = Open-CopyRecoveryLock $Plan.Path
    try {
        # Rebuild under the lock so a second caller cannot reuse stale ownership.
        $Plan = New-TemplateRevertPlan $Plan.Root $Plan.Target $Plan.Path
        $Plan.Journal.status = 'reverting'
        Write-CopyJson -Path $Plan.Path -Value $Plan.Journal
        $restored = 0
        $removed = 0
        foreach ($action in $Plan.Actions) {
            Assert-CopyPath $action.Path
            if (-not $action.AlreadyRestored) {
                $stream = [IO.File]::Open($action.Path, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
                try {
                    if ((Get-CopyByteHash (Read-CopyStream $stream)) -cne $action.File.afterHash) {
                        throw "File changed before revert: $($action.Path)"
                    }
                    if ($action.File.existed) {
                        $stream.Position = 0
                        $stream.Write($action.Before, 0, $action.Before.Length)
                        $stream.SetLength($action.Before.Length)
                        $stream.Flush()
                    }
                }
                finally { $stream.Dispose() }
                if ($action.File.existed) {
                    [IO.File]::SetLastWriteTimeUtc($action.Path, $action.LastWrite)
                    $restored++
                }
                else {
                    Assert-CopyPath $action.Path
                    [IO.File]::Delete($action.Path)
                    $removed++
                }
            }
            $action.File.state = 'reverted'
            Write-CopyJson -Path $Plan.Path -Value $Plan.Journal
        }
        foreach ($directory in $Plan.Directories | Sort-Object -Unique | Sort-Object Length -Descending) {
            Assert-CopyPath $directory
            if (Test-Path -LiteralPath $directory -PathType Container) {
                if (-not @(Get-ChildItem -LiteralPath $directory -Force).Count) { [IO.Directory]::Delete($directory, $false) }
            }
        }
        $Plan.Journal.status = 'reverted'
        Write-CopyJson -Path $Plan.Path -Value $Plan.Journal
        [pscustomobject]@{ Restored = $restored; Removed = $removed; RecoveryPath = $Plan.Path }
    }
    catch { throw "Revert failed; keep the recovery snapshot and retry only after resolving the error. Snapshot: $($Plan.Path). $($_.Exception.Message)" }
    finally { $lock.Dispose() }
}
