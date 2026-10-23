#requires -Version 5.1
[CmdletBinding()]
param([switch]$DryRun)
if ($DryRun) { Write-Host '[DRY RUN] Copy helpers loaded; no files accessed.'; return }

function Assert-CopyPath([string]$Path) {
    $current = [IO.Path]::GetFullPath($Path)
    while ($current) {
        $attributes = $null
        try { $attributes = [IO.File]::GetAttributes($current) }
        catch [IO.FileNotFoundException] { }
        catch [IO.DirectoryNotFoundException] { }
        if ($null -ne $attributes) {
            if ($attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Refusing link or junction: $current"
            }
            $entry = Get-Item -LiteralPath $current -Force
            $linkType = $entry.PSObject.Properties['LinkType']
            if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
                ($linkType -and $linkType.Value)) {
                throw "Refusing link, hard link or junction: $current"
            }
        }
        $current = Split-Path -Parent $current
    }
}

function Get-TemplateCopyFiles([string]$Root) {
    Assert-CopyPath $Root
    $excluded = '.git', '.moorkyz', '.logs', '.archive', '.audits', 'node_modules',
        'coverage', 'dist', 'build', 'tmp', '.tmp', '.idea', '.vs', '.venv', '__pycache__'
    function Get-CopyFiles([string]$Directory) {
        foreach ($entry in Get-ChildItem -LiteralPath $Directory -Force | Sort-Object Name) {
            if ($excluded -contains $entry.Name) { continue }
            if (($entry.Name -like '.env*' -and $entry.Name -ne '.env.example') -or
                $entry.Extension -in '.key', '.pem', '.p12', '.pfx', '.log') { continue }
            Assert-CopyPath $entry.FullName
            if ($entry.PSIsContainer) { Get-CopyFiles $entry.FullName }
            else { $entry.FullName.Substring($Root.Length).TrimStart('\', '/') }
        }
    }
    Get-CopyFiles $Root
}

function ConvertTo-CopyContent([byte[]]$Bytes) {
    $utf8 = New-Object Text.UTF8Encoding($false, $true)
    try {
        $text = $utf8.GetString($Bytes)
        if ($text.IndexOf([char]0) -lt 0) {
            return [pscustomobject]@{ Content = $text; Encoding = 'utf-8' }
        }
    }
    catch [Text.DecoderFallbackException] {
        # Binary or non-UTF-8 bytes are preserved losslessly for later review.
    }
    [pscustomobject]@{ Content = [Convert]::ToBase64String($Bytes); Encoding = 'base64' }
}

function New-TemplateCopyPlan {
    param(
        [string]$Root,
        [string]$TargetDirectory,
        [string[]]$File,
        [switch]$ForceCopy
    )
    if ([string]::IsNullOrWhiteSpace($TargetDirectory)) { throw 'Choose an existing target repository directory.' }
    if (-not $File -or -not $File.Count) { throw 'Select at least one file.' }
    $rootPath = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $target = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TargetDirectory)
    $target = [IO.Path]::GetFullPath($target).TrimEnd('\', '/')
    $comparison = if ($env:OS -eq 'Windows_NT') { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    $separator = [IO.Path]::DirectorySeparatorChar
    if ($rootPath.Equals($target, $comparison) -or
        $target.StartsWith($rootPath + $separator, $comparison) -or
        $rootPath.StartsWith($target + $separator, $comparison)) {
        throw 'Source and target must be separate, non-overlapping directories.'
    }
    Assert-CopyPath $rootPath
    Assert-CopyPath $target
    if (-not (Test-Path -LiteralPath $target -PathType Container)) { throw "Target directory does not exist: $target" }
    $comparer = if ($env:OS -eq 'Windows_NT') { [StringComparer]::OrdinalIgnoreCase } else { [StringComparer]::Ordinal }
    $available = New-Object 'System.Collections.Generic.Dictionary[string,string]' $comparer
    foreach ($name in @(Get-TemplateCopyFiles $rootPath)) {
        $available.Add($name.Replace('\', '/'), $name)
    }
    $selected = New-Object 'System.Collections.Generic.HashSet[string]' $comparer
    $copies = New-Object 'System.Collections.Generic.List[object]'
    $conflicts = New-Object 'System.Collections.Generic.List[object]'
    $entries = New-Object 'System.Collections.Generic.List[object]'
    foreach ($requested in $File) {
        if ([string]::IsNullOrWhiteSpace($requested)) { throw 'File selection contains an empty path.' }
        $key = $requested.Replace('\', '/')
        if (-not $available.ContainsKey($key)) { throw "Not an available template file: $requested" }
        if (-not $selected.Add($key)) { continue }
        $name = $available[$key]
        $source = Join-Path $rootPath $name
        $destination = Join-Path $target $name
        Assert-CopyPath $source
        Assert-CopyPath $destination
        $parent = Split-Path -Parent $destination
        while ($parent -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
            if (Test-Path -LiteralPath $parent) { throw "A file blocks a destination directory: $parent" }
            $parent = Split-Path -Parent $parent
        }
        $bytes = [IO.File]::ReadAllBytes($source)
        $existing = Test-Path -LiteralPath $destination
        $previous = $null
        $replace = $false
        if ($existing) {
            if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) {
                throw "A directory blocks a destination file: $destination"
            }
            $previous = [IO.File]::ReadAllBytes($destination)
            $identical = [Convert]::ToBase64String($bytes) -ceq [Convert]::ToBase64String($previous)
            $replace = $ForceCopy -and -not $identical
            if ($replace -and ((Get-Item -LiteralPath $destination -Force).Attributes -band [IO.FileAttributes]::ReadOnly)) {
                throw "Cannot force-copy a read-only file: $destination"
            }
            $templateContent = ConvertTo-CopyContent $bytes
            $destinationContent = ConvertTo-CopyContent $previous
            $conflicts.Add([pscustomobject][ordered]@{
                name = $name.Replace('\', '/')
                templateContent = $templateContent.Content
                destinationContent = $destinationContent.Content
                templateEncoding = $templateContent.Encoding
                destinationEncoding = $destinationContent.Encoding
                overwritten = [bool]$replace
            })
        }
        $entry = [pscustomobject]@{
            Source = $source; Destination = $destination; Bytes = $bytes
            Previous = $previous; Existing = $existing; Replace = $replace
        }
        $entries.Add($entry)
        if (-not $existing -or $replace) { $copies.Add($entry) }
    }
    $reportDirectory = Join-Path $rootPath '.moorkyz\soft-copy'
    Assert-CopyPath $reportDirectory
    $reportParent = $reportDirectory
    while ($reportParent) {
        if ((Test-Path -LiteralPath $reportParent) -and
            -not (Test-Path -LiteralPath $reportParent -PathType Container)) {
            throw "A file blocks the report directory: $reportParent"
        }
        $reportParent = Split-Path -Parent $reportParent
    }
    [pscustomobject]@{
        Target = $target; Entries = $entries; Copies = $copies; Conflicts = $conflicts
        ReportDirectory = $reportDirectory
    }
}

function Invoke-TemplateCopyPlan($Plan) {
    # Revalidate the complete snapshot before the report or any destination writes.
    foreach ($entry in $Plan.Entries) {
        Assert-CopyPath $entry.Source
        Assert-CopyPath $entry.Destination
        if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($entry.Source)) -cne [Convert]::ToBase64String($entry.Bytes)) {
            throw "Source changed after selection; retry: $($entry.Source)"
        }
        if ($entry.Existing) {
            if (-not (Test-Path -LiteralPath $entry.Destination -PathType Leaf) -or
                [Convert]::ToBase64String([IO.File]::ReadAllBytes($entry.Destination)) -cne [Convert]::ToBase64String($entry.Previous)) {
                throw "Destination changed after selection; retry: $($entry.Destination)"
            }
        }
        elseif (Test-Path -LiteralPath $entry.Destination) {
            throw "Destination appeared after selection; retry: $($entry.Destination)"
        }
    }
    Assert-CopyPath $Plan.ReportDirectory
    [void][IO.Directory]::CreateDirectory($Plan.ReportDirectory)
    $filename = 'conflicts-{0}-{1}.json' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'), [Guid]::NewGuid().ToString('N')
    $report = Join-Path $Plan.ReportDirectory $filename
    $json = ConvertTo-Json -InputObject @($Plan.Conflicts.ToArray()) -Depth 4
    $reportBytes = (New-Object Text.UTF8Encoding($false)).GetBytes($json)
    $stream = [IO.File]::Open($report, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.Write($reportBytes, 0, $reportBytes.Length) }
    finally { $stream.Dispose() }
    Write-Host "Content-pair snapshot saved before copying: $report"
    $copied = 0
    $replaced = 0
    try {
        foreach ($entry in $Plan.Copies) {
            Assert-CopyPath $entry.Destination
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $entry.Destination))
            $mode = if ($entry.Replace) { [IO.FileMode]::Open } else { [IO.FileMode]::CreateNew }
            $stream = [IO.File]::Open($entry.Destination, $mode, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
            try {
                if ($entry.Replace) {
                    $previous = New-Object byte[] $stream.Length
                    $offset = 0
                    while ($offset -lt $previous.Length) {
                        $read = $stream.Read($previous, $offset, $previous.Length - $offset)
                        if (-not $read) { throw "Unexpected end of destination: $($entry.Destination)" }
                        $offset += $read
                    }
                    if ([Convert]::ToBase64String($previous) -cne [Convert]::ToBase64String($entry.Previous)) {
                        throw "Destination changed before replacement: $($entry.Destination)"
                    }
                    $stream.Position = 0
                }
                $stream.Write($entry.Bytes, 0, $entry.Bytes.Length)
                $stream.SetLength($entry.Bytes.Length)
                $stream.Flush()
            }
            finally { $stream.Dispose() }
            if ($entry.Replace) { $replaced++ } else { $copied++ }
        }
    }
    catch {
        throw "Copy failed after $copied new and $replaced replaced files. Snapshot: $report. $($_.Exception.Message)"
    }
    [pscustomobject]@{
        Copied = $copied; Replaced = $replaced
        Preserved = $Plan.Conflicts.Count - $replaced; ReportPath = $report
    }
}
