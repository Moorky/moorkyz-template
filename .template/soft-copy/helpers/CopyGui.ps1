#requires -Version 5.1
[CmdletBinding()]
param([switch]$DryRun)
if ($DryRun) { Write-Host '[DRY RUN] GUI helpers loaded; no windows opened.'; return }

function Confirm-TemplateOverwrite([string]$Target, [int]$Count) {
    $answer = [Windows.Forms.MessageBox]::Show(
        "Replace $Count differing file(s) in:`r`n$Target`r`n`r`nBoth versions will be saved in a local JSON report first. Source files stay unchanged.",
        'Confirm force copy', [Windows.Forms.MessageBoxButtons]::YesNo,
        [Windows.Forms.MessageBoxIcon]::Warning, [Windows.Forms.MessageBoxDefaultButton]::Button2)
    $answer -eq [Windows.Forms.DialogResult]::Yes
}

function Confirm-TemplateRevert([string]$Target) {
    [Windows.Forms.MessageBox]::Show(
        "Revert the last copy into:`r`n$Target`r`n`r`nOverwritten files will be restored. Files created by that copy will be removed. Later edits are protected.",
        'Confirm revert', [Windows.Forms.MessageBoxButtons]::YesNo,
        [Windows.Forms.MessageBoxIcon]::Warning, [Windows.Forms.MessageBoxDefaultButton]::Button2) -eq [Windows.Forms.DialogResult]::Yes
}

function New-TemplateCopyForm {
    param([string]$Root, [string]$TargetDirectory, [string[]]$File, [switch]$ForceCopy)
    $corePath = Join-Path $PSScriptRoot 'CopyCore.ps1'
    $confirmOverwrite = ${function:Confirm-TemplateOverwrite}
    $confirmRevert = ${function:Confirm-TemplateRevert}
    $form = New-Object Windows.Forms.Form
    $form.Text = 'Template soft copy'
    $form.ClientSize = New-Object Drawing.Size(820, 650)
    $form.MinimumSize = New-Object Drawing.Size(650, 520)
    $form.StartPosition = 'CenterScreen'
    $form.Font = New-Object Drawing.Font('Segoe UI', 9)

    $targetLabel = New-Object Windows.Forms.Label
    $targetLabel.Text = 'Target repository (existing directory)'
    $targetLabel.SetBounds(16, 16, 600, 22)
    $target = New-Object Windows.Forms.TextBox
    $target.Name = 'TargetDirectory'
    $target.Text = $TargetDirectory
    $target.SetBounds(16, 42, 680, 26)
    $target.Anchor = 'Top,Left,Right'
    $browse = New-Object Windows.Forms.Button
    $browse.Name = 'BrowseTarget'
    $browse.Text = 'Browse...'
    $browse.SetBounds(706, 40, 98, 29)
    $browse.Anchor = 'Top,Right'
    $instruction = New-Object Windows.Forms.Label
    $instruction.Text = 'Select files to COPY. Originals stay here. Existing target files are preserved unless force is enabled.'
    $instruction.SetBounds(16, 82, 788, 36)
    $instruction.Anchor = 'Top,Left,Right'
    $list = New-Object Windows.Forms.CheckedListBox
    $list.Name = 'TemplateFiles'
    $list.CheckOnClick = $true
    $list.HorizontalScrollbar = $true
    $list.SetBounds(16, 122, 788, 306)
    $list.Anchor = 'Top,Bottom,Left,Right'
    $available = @(Get-TemplateCopyFiles $Root)
    foreach ($name in $available) { [void]$list.Items.Add($name) }
    foreach ($name in $File) {
        $index = $list.Items.IndexOf($name.Replace('/', '\'))
        if ($index -lt 0) { $form.Dispose(); throw "Not an available template file: $name" }
        $list.SetItemChecked($index, $true)
    }

    $all = New-Object Windows.Forms.Button
    $all.Text = 'Select all'
    $all.SetBounds(16, 438, 100, 28)
    $all.Anchor = 'Bottom,Left'
    $all.Add_Click(({ for ($i = 0; $i -lt $list.Items.Count; $i++) { $list.SetItemChecked($i, $true) } }).GetNewClosure())
    $none = New-Object Windows.Forms.Button
    $none.Text = 'Select none'
    $none.SetBounds(124, 438, 100, 28)
    $none.Anchor = 'Bottom,Left'
    $none.Add_Click(({ for ($i = 0; $i -lt $list.Items.Count; $i++) { $list.SetItemChecked($i, $false) } }).GetNewClosure())
    $force = New-Object Windows.Forms.CheckBox
    $force.Name = 'ForceCopy'
    $force.Text = 'Force copy: replace differing target files (asks for confirmation)'
    $force.Checked = [bool]$ForceCopy
    $force.SetBounds(16, 478, 788, 26)
    $force.Anchor = 'Bottom,Left,Right'
    $copy = New-Object Windows.Forms.Button
    $copy.Name = 'CopySelected'
    $copy.Text = 'Copy selected'
    $copy.SetBounds(16, 514, 140, 32)
    $copy.Anchor = 'Bottom,Left'
    $revert = New-Object Windows.Forms.Button
    $revert.Name = 'RevertLastCopy'
    $revert.Text = 'Revert last copy'
    $revert.Enabled = $false
    $revert.SetBounds(166, 514, 150, 32)
    $revert.Anchor = 'Bottom,Left'
    $status = New-Object Windows.Forms.TextBox
    $status.Name = 'CopyStatus'
    $status.Multiline = $true
    $status.ReadOnly = $true
    $status.ScrollBars = 'Vertical'
    $status.Text = 'No files selected by default. Reports stay in the template .moorkyz\soft-copy folder and may contain sensitive target content. Review locally; do not upload automatically.'
    $status.SetBounds(16, 558, 788, 76)
    $status.Anchor = 'Bottom,Left,Right'
    $browse.Add_Click(({
        $dialog = New-Object Windows.Forms.FolderBrowserDialog
        $dialog.Description = 'Choose the repository to receive template files'
        $dialog.ShowNewFolderButton = $false
        try {
            if (-not [string]::IsNullOrWhiteSpace($target.Text) -and
                (Test-Path -LiteralPath $target.Text -PathType Container)) {
                $dialog.SelectedPath = $target.Text
            }
            if ($dialog.ShowDialog($form) -eq [Windows.Forms.DialogResult]::OK) { $target.Text = $dialog.SelectedPath }
        }
        catch { $status.Text = "FAILED - Could not open folder picker: $($_.Exception.Message)" }
        finally { $dialog.Dispose() }
    }).GetNewClosure())
    $copy.Add_Click(({
        $copy.Enabled = $false
        $revert.Enabled = $false
        try {
            # WinForms closures cannot resolve the launcher's script-local helpers.
            . $corePath
            $selection = @($list.CheckedItems | ForEach-Object { [string]$_ })
            $plan = New-TemplateCopyPlan -Root $Root -TargetDirectory $target.Text -File $selection -ForceCopy:$force.Checked
            $replacementCount = @($plan.Copies | Where-Object Replace).Count
            if ($replacementCount -and -not (& $confirmOverwrite $plan.Target $replacementCount)) {
                $status.Text = 'Cancelled; no files or reports changed.'
                return
            }
            $result = Invoke-TemplateCopyPlan $plan
            $revert.Tag = if ($result.RecoveryPath) {
                [pscustomobject]@{ Path = $result.RecoveryPath; Target = $result.TargetDirectory }
            } else { $null }
            $status.Text = "DONE - Copied: $($result.Copied); replaced: $($result.Replaced); preserved: $($result.Preserved).`r`nLocal content pairs: $($result.ReportPath)`r`nRevert snapshot: $($result.RecoveryPath)"
        }
        catch {
            if ($_.Exception.Data.Contains('RecoveryPath')) {
                $revert.Tag = [pscustomobject]@{ Path = $_.Exception.Data['RecoveryPath']; Target = $_.Exception.Data['TargetDirectory'] }
            }
            $status.Text = "FAILED - $($_.Exception.Message)"
        }
        finally { $copy.Enabled = $true; $revert.Enabled = $null -ne $revert.Tag }
    }).GetNewClosure())
    $revert.Add_Click(({
        $copy.Enabled = $false
        $revert.Enabled = $false
        try {
            . $corePath
            $plan = New-TemplateRevertPlan -Root $Root -TargetDirectory $revert.Tag.Target -RecoveryPath $revert.Tag.Path
            if (-not (& $confirmRevert $plan.Target)) {
                $status.Text = 'Revert cancelled; no files changed.'
                return
            }
            $result = Invoke-TemplateRevertPlan $plan
            $revert.Tag = $null
            $status.Text = "REVERTED - Restored: $($result.Restored); removed: $($result.Removed). Local snapshots retained: $($result.RecoveryPath)"
        }
        catch { $status.Text = "FAILED - $($_.Exception.Message)" }
        finally { $copy.Enabled = $true; $revert.Enabled = $null -ne $revert.Tag }
    }).GetNewClosure())
    $form.Controls.AddRange(@($targetLabel, $target, $browse, $instruction, $list, $all, $none, $force, $copy, $revert, $status))
    [pscustomobject]@{
        Form = $form; Target = $target; Files = $list; Force = $force
        Copy = $copy; Revert = $revert; Status = $status; All = $all; None = $none
    }
}
