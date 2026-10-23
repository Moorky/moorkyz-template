#requires -Version 5.1
[CmdletBinding()]
param([switch]$DryRun)
if ($DryRun) { Write-Host '[DRY RUN] Would verify soft copy in disposable fixtures; no windows or files changed.'; return }

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$node = (Get-Command node -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$engines = @((Get-Process -Id $PID).Path)
if ($env:OS -eq 'Windows_NT') {
    foreach ($name in 'pwsh', 'powershell.exe') {
        $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command -and $engines -notcontains $command.Source) { $engines += $command.Source }
    }
}
$source = @'
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const crypto = require("node:crypto");
const { spawnSync } = require("node:child_process");
assert.equal(process.versions.node.split(".")[0], "24", "Node.js 24 LTS is required.");
const root = process.argv[2];
const engines = process.argv.slice(3);
const tool = path.join(root, ".template", "soft-copy");
function snapshot(directory, skipReports = false) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    if (skipReports && entry.name === ".moorkyz") return [];
    const filename = path.join(directory, entry.name);
    if (entry.isSymbolicLink()) return [[filename, `link:${fs.readlinkSync(filename)}`]];
    return entry.isDirectory() ? [[filename, null], ...snapshot(filename, skipReports)] :
      [[filename, crypto.createHash("sha256").update(fs.readFileSync(filename)).digest("hex")]];
  }).sort(([a], [b]) => a.localeCompare(b));
}
const originalTool = snapshot(tool);
const workspace = fs.mkdtempSync(path.join(os.tmpdir(), "moorkyz soft copy "));
const quote = (value) => `'${value.replaceAll("'", "''")}'`;
let sequence = 0;
let groups = 0;
function write(filename, content) {
  fs.mkdirSync(path.dirname(filename), { recursive: true });
  fs.writeFileSync(filename, content);
}
function fixture() {
  const directory = path.join(workspace, `fixture ${++sequence}`);
  const source = path.join(directory, "template source");
  const target = path.join(directory, "target repo");
  const entry = path.join(source, ".template", "soft-copy", "CopyTemplate.ps1");
  fs.cpSync(tool, path.dirname(entry), { recursive: true });
  fs.mkdirSync(target);
  write(path.join(source, "fresh.txt"), "fresh template\n");
  write(path.join(source, "conflict.txt"), "new\n");
  write(path.join(source, "nested", "binary.bin"), Buffer.from([0, 255, 1, 128]));
  write(path.join(source, "empty.txt"), "");
  write(path.join(source, "unicode.txt"), "line one\r\n\u2603 \ud83c\udf0a\n\"quoted\"\\path");
  write(path.join(source, "unselected.txt"), "must not copy");
  write(path.join(source, ".env"), "DISPOSABLE_TEST_ONLY=not-a-secret");
  write(path.join(source, ".env.example"), "EXAMPLE=value");
  for (const directory of [".git", ".logs", ".archive", ".moorkyz", ".audits", "node_modules", "dist"]) {
    write(path.join(source, directory, "ignored.txt"), "excluded fixture");
  }
  write(path.join(target, "sentinel.txt"), "keep target work");
  return { directory, source, target, entry };
}
function invoke(engine, f, files, flags = "", target = f.target, custom) {
  const select = files === null ? "" : ` -File @(${files.map(quote).join(",")})`;
  const command = custom || `& ${quote(f.entry)} -NoGui -TargetDirectory ${quote(target)}${select} ${flags}`;
  const script = `$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest; ${command}`;
  const result = spawnSync(engine, [
    "-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
    ...(process.platform === "win32" ? ["-STA"] : []),
    "-EncodedCommand", Buffer.from(script, "utf16le").toString("base64"),
  ], { cwd: workspace, encoding: "utf8", timeout: 60000 });
  if (result.error) throw result.error;
  assert.equal(result.signal, null, `${result.stdout}${result.stderr}`);
  return { code: result.status, output: `${result.stdout}${result.stderr}` };
}
function success(result) { assert.equal(result.code, 0, result.output); }
function failure(result, pattern) {
  assert.notEqual(result.code, 0, result.output);
  if (pattern) assert.match(result.output, pattern);
}
function reports(f) {
  const directory = path.join(f.source, ".moorkyz", "soft-copy");
  if (!fs.existsSync(directory)) return [];
  return fs.readdirSync(directory).map((name) => JSON.parse(fs.readFileSync(path.join(directory, name), "utf8")));
}
function unchangedFailure(engine, f, files, flags, target, pattern) {
  const before = snapshot(f.directory);
  failure(invoke(engine, f, files, flags, target), pattern);
  assert.deepEqual(snapshot(f.directory), before, "Rejected operation changed files.");
}
try {
  for (const engine of engines) {
    const label = path.basename(engine);
    let f = fixture();
    let before = snapshot(f.directory);
    success(invoke(engine, f, null, "-DryRun", "not an existing directory"));
    assert.deepEqual(snapshot(f.directory), before);
    success(invoke(engine, f, ["fresh.txt", "nested/binary.bin"], "-WhatIf"));
    assert.deepEqual(snapshot(f.directory), before);
    groups++;

    f = fixture();
    const sourceBefore = snapshot(f.source, true);
    success(invoke(engine, f, ["fresh.txt", "nested/binary.bin", ".env.example"]));
    for (const name of ["fresh.txt", "nested/binary.bin", ".env.example"]) {
      assert.deepEqual(fs.readFileSync(path.join(f.target, name)), fs.readFileSync(path.join(f.source, name)));
    }
    assert.deepEqual(reports(f), [[]], "Empty conflict report must be a JSON array.");
    assert.ok(!fs.existsSync(path.join(f.target, "unselected.txt")));
    assert.ok(!fs.existsSync(path.join(f.target, ".env")));
    assert.deepEqual(snapshot(f.source, true), sourceBefore);
    assert.equal(fs.readFileSync(path.join(f.target, "sentinel.txt"), "utf8"), "keep target work");
    groups++;

    f = fixture();
    write(path.join(f.target, "conflict.txt"), "keep existing");
    const mixedSource = snapshot(f.source, true);
    const mixed = invoke(engine, f, ["fresh.txt", "conflict.txt", "nested/binary.bin"]);
    success(mixed);
    assert.match(mixed.output, /Copied: 2; replaced: 0; preserved: 1/);
    assert.equal(fs.readFileSync(path.join(f.target, "conflict.txt"), "utf8"), "keep existing");
    for (const name of ["fresh.txt", "nested/binary.bin"]) {
      assert.deepEqual(fs.readFileSync(path.join(f.target, name)), fs.readFileSync(path.join(f.source, name)));
    }
    assert.equal(reports(f)[0].length, 1);
    assert.deepEqual(snapshot(f.source, true), mixedSource);
    groups++;

    f = fixture();
    const names = ["conflict.txt", "empty.txt", "unicode.txt", "nested/binary.bin"];
    write(path.join(f.target, "conflict.txt"), "existing target is much longer\n");
    for (const name of names.slice(1)) write(path.join(f.target, name), fs.readFileSync(path.join(f.source, name)));
    before = snapshot(f.target);
    const originalMtime = fs.statSync(path.join(f.target, "unicode.txt")).mtimeMs;
    const originalSource = snapshot(f.source, true);
    success(invoke(engine, f, names));
    assert.deepEqual(snapshot(f.target), before);
    let pairs = reports(f)[0];
    assert.ok(Array.isArray(pairs));
    assert.equal(pairs.length, names.length);
    const conflict = pairs.find((pair) => pair.name === "conflict.txt");
    assert.deepEqual(conflict, {
      name: "conflict.txt", templateContent: "new\n", destinationContent: "existing target is much longer\n",
      templateEncoding: "utf-8", destinationEncoding: "utf-8", overwritten: false,
    });
    for (const pair of pairs) {
      assert.equal(pair.overwritten, false);
      assert.deepEqual(
        Buffer.from(pair.templateContent, pair.templateEncoding === "base64" ? "base64" : "utf8"),
        fs.readFileSync(path.join(f.source, pair.name)));
      assert.deepEqual(
        Buffer.from(pair.destinationContent, pair.destinationEncoding === "base64" ? "base64" : "utf8"),
        fs.readFileSync(path.join(f.target, pair.name)));
    }
    assert.equal(pairs.find((pair) => pair.name === "nested/binary.bin").templateEncoding, "base64");
    assert.equal(pairs.find((pair) => pair.name === "empty.txt").templateContent, "");
    groups++;

    success(invoke(engine, f, [...names, "fresh.txt"], "-ForceCopy"));
    for (const name of [...names, "fresh.txt"]) {
      assert.deepEqual(fs.readFileSync(path.join(f.target, name)), fs.readFileSync(path.join(f.source, name)));
    }
    pairs = reports(f).flat().filter((pair) => pair.overwritten);
    assert.equal(pairs.length, 1);
    assert.equal(pairs[0].destinationContent, "existing target is much longer\n");
    assert.equal(fs.statSync(path.join(f.target, "unicode.txt")).mtimeMs, originalMtime);
    assert.deepEqual(snapshot(f.source, true), originalSource);
    groups++;

    f = fixture();
    write(path.join(f.target, "fresh.txt"), "");
    write(path.join(f.target, "empty.txt"), "replace with empty");
    write(path.join(f.target, "nested", "binary.bin"), Buffer.from([255, 0, 5, 7, 9]));
    const forceEdges = invoke(engine, f, ["fresh.txt", "empty.txt", "nested/binary.bin"], "-ForceCopy");
    success(forceEdges);
    assert.match(forceEdges.output, /Copied: 0; replaced: 3; preserved: 0/);
    for (const pair of reports(f)[0]) {
      assert.equal(pair.overwritten, true);
      assert.deepEqual(fs.readFileSync(path.join(f.target, pair.name)), fs.readFileSync(path.join(f.source, pair.name)));
    }
    assert.equal(reports(f)[0].find((pair) => pair.name === "fresh.txt").destinationContent, "");
    assert.equal(reports(f)[0].find((pair) => pair.name === "empty.txt").templateContent, "");
    assert.equal(reports(f)[0].find((pair) => pair.name === "nested/binary.bin").destinationContent, "/wAFBwk=");
    groups++;

    f = fixture();
    write(path.join(f.target, "conflict.txt"), "old");
    success(invoke(engine, f, ["conflict.txt", "conflict.txt"]));
    assert.equal(reports(f)[0].length, 1, "Single/duplicate conflict must remain a one-element JSON array.");
    for (const name of ["../escape.txt", path.join(f.source, "fresh.txt"), ".env", ".git/ignored.txt", ".audits/ignored.txt", "*", ""]) {
      unchangedFailure(engine, f, [name], "", f.target, /available template file|empty path|Select at least one/);
    }
    unchangedFailure(engine, f, null, "", f.target, /Select at least one/);
    fs.rmSync(path.join(f.source, ".git"), { recursive: true });
    write(path.join(f.source, ".git"), "gitdir: disposable-worktree-metadata");
    unchangedFailure(engine, f, [".git"], "-ForceCopy", f.target, /available template file/);
    groups++;

    f = fixture();
    for (const target of [f.source, path.join(f.source, "nested"), f.directory, path.join(f.directory, "missing")]) {
      unchangedFailure(engine, f, ["fresh.txt"], "", target, /non-overlapping|does not exist/);
    }
    write(path.join(f.target, "nested"), "blocking parent file");
    unchangedFailure(engine, f, ["fresh.txt", "nested/binary.bin"], "", f.target, /blocks a destination directory/);
    fs.mkdirSync(path.join(f.target, "fresh.txt"));
    unchangedFailure(engine, f, ["fresh.txt"], "-ForceCopy", f.target, /directory blocks/);
    groups++;

    f = fixture();
    write(path.join(f.source, ".moorkyz", "soft-copy"), "blocked report directory");
    unchangedFailure(engine, f, ["fresh.txt"], "", f.target, /blocks the report directory/);
    groups++;

    f = fixture();
    const core = path.join(path.dirname(f.entry), "helpers", "CopyCore.ps1");
    for (const change of ["source", "destination", "appeared"]) {
      const sourceFile = path.join(f.source, "conflict.txt");
      const destination = path.join(f.target, "conflict.txt");
      if (fs.existsSync(destination)) fs.unlinkSync(destination);
      if (change === "destination") write(destination, "before");
      const mutate = change === "source" ? sourceFile : destination;
      const script = `. ${quote(core)}; $plan = New-TemplateCopyPlan -Root ${quote(f.source)} -TargetDirectory ${quote(f.target)} -File conflict.txt -ForceCopy; [IO.File]::WriteAllText(${quote(mutate)},'changed'); Invoke-TemplateCopyPlan $plan`;
      failure(invoke(engine, f, null, "", f.target, script), /changed after selection|appeared after selection/);
      assert.equal(reports(f).length, 0);
      assert.equal(fs.readFileSync(mutate, "utf8"), "changed");
    }
    groups++;

    if (process.platform === "win32") {
      f = fixture();
      write(path.join(f.target, "conflict.txt"), "readonly");
      success(invoke(engine, f, null, "", f.target, `(Get-Item -LiteralPath ${quote(path.join(f.target, "conflict.txt"))}).IsReadOnly=$true`));
      unchangedFailure(engine, f, ["fresh.txt", "conflict.txt"], "-ForceCopy", f.target, /read-only/);
      success(invoke(engine, f, null, "", f.target, `(Get-Item -LiteralPath ${quote(path.join(f.target, "conflict.txt"))}).IsReadOnly=$false`));
      groups++;

      for (const location of ["target", "source", "report", "hardlink"]) {
        f = fixture();
        const outside = path.join(f.directory, "outside");
        fs.mkdirSync(outside);
        const sentinel = path.join(outside, "sentinel.txt");
        write(sentinel, "must stay outside");
        let selected = ["nested/binary.bin"];
        let target = f.target;
        if (location === "target") {
          fs.symlinkSync(outside, path.join(f.target, "nested"), "junction");
        } else if (location === "source") {
          fs.symlinkSync(outside, path.join(f.source, "linked"), "junction");
          selected = ["fresh.txt"];
        } else if (location === "report") {
          fs.symlinkSync(outside, path.join(f.source, ".moorkyz", "soft-copy"), "junction");
          selected = ["fresh.txt"];
        } else {
          fs.linkSync(sentinel, path.join(f.target, "fresh.txt"));
          selected = ["fresh.txt"];
        }
        unchangedFailure(engine, f, selected, "-ForceCopy", target, /link|junction/);
        assert.equal(fs.readFileSync(sentinel, "utf8"), "must stay outside");
      }
      groups++;

      f = fixture();
      const gui = path.join(path.dirname(f.entry), "helpers", "CopyGui.ps1");
      const guiCore = path.join(path.dirname(f.entry), "helpers", "CopyCore.ps1");
      write(path.join(f.target, "conflict.txt"), "GUI old value");
      const script = `
        Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing;
        . ${quote(guiCore)}; . ${quote(gui)};
        function Assert($condition, $message) { if (-not $condition) { throw $message } }
        $global:confirmTestAnswer = $false;
        function global:Confirm-TemplateOverwrite { return $global:confirmTestAnswer }
        $ui = New-TemplateCopyForm -Root ${quote(f.source)};
        try {
          Assert (-not $ui.Force.Checked) 'Force must default off';
          Assert ($ui.Files.CheckedItems.Count -eq 0) 'Files must default unchecked';
          $ui.Form.Show(); [Windows.Forms.Application]::DoEvents();
          $ui.All.PerformClick(); Assert ($ui.Files.CheckedItems.Count -eq $ui.Files.Items.Count) 'Select all';
          $ui.None.PerformClick(); Assert ($ui.Files.CheckedItems.Count -eq 0) 'Select none';
          $ui.Copy.PerformClick(); Assert ($ui.Status.Text -like 'FAILED*') 'Missing target must fail visibly';
          $ui.Target.Text = ${quote(f.target)};
          $ui.Copy.PerformClick(); Assert ($ui.Status.Text -like 'FAILED*') 'Empty selection must fail visibly';
          $ui.Files.SetItemChecked($ui.Files.Items.IndexOf('conflict.txt'), $true);
          $ui.Copy.PerformClick(); Assert ($ui.Status.Text -like 'DONE*preserved: 1*') $ui.Status.Text;
          Assert ([IO.File]::ReadAllText(${quote(path.join(f.target, "conflict.txt"))}) -eq 'GUI old value') 'GUI normal mode overwrote';
          $ui.Force.Checked = $true;
          $ui.Copy.PerformClick(); Assert ($ui.Status.Text -like 'Cancelled*') $ui.Status.Text;
          Assert ([IO.File]::ReadAllText(${quote(path.join(f.target, "conflict.txt"))}) -eq 'GUI old value') 'GUI cancel overwrote';
          $global:confirmTestAnswer = $true;
          $ui.Copy.PerformClick(); Assert ($ui.Status.Text -like 'DONE*replaced: 1*') $ui.Status.Text;
          Assert ([IO.File]::ReadAllText(${quote(path.join(f.target, "conflict.txt"))}) -eq "new\`n") 'GUI force did not replace';
          'PASS: GUI target input, selections, visible errors, normal copy and force cancel/confirm.';
        } finally { $ui.Form.Close(); $ui.Form.Dispose() }
      `;
      const result = invoke(engine, f, null, "", f.target, script);
      success(result);
      assert.match(result.output, /PASS: GUI target input/);
      assert.equal(reports(f).length, 2, "Cancelled GUI must not write a report.");
      groups++;

      f = fixture();
      const launch = `
        Add-Type -AssemblyName System.Windows.Forms;
        $global:launchResult = $null; $global:launchError = $null;
        $timer = New-Object Windows.Forms.Timer; $timer.Interval = 150;
        $timer.Add_Tick({
          $form = [Windows.Forms.Application]::OpenForms | Where-Object Text -eq 'Template soft copy' | Select-Object -First 1;
          if (-not $form) { return }
          $timer.Stop();
          try {
            $form.Controls['TargetDirectory'].Text = ${quote(f.target)};
            $files = $form.Controls['TemplateFiles'];
            $files.SetItemChecked($files.Items.IndexOf('fresh.txt'), $true);
            $form.Controls['CopySelected'].PerformClick();
            $global:launchResult = $form.Controls['CopyStatus'].Text;
          } catch { $global:launchError = $_.Exception.Message }
          finally { $form.Close() }
        });
        try { $timer.Start(); & ${quote(f.entry)} }
        finally { $timer.Stop(); $timer.Dispose() }
        if ($global:launchError) { throw $global:launchError }
        if ($global:launchResult -notlike 'DONE*Copied: 1*') { throw "Real GUI launcher failed: $global:launchResult" }
      `;
      success(invoke(engine, f, null, "", f.target, launch));
      assert.equal(fs.readFileSync(path.join(f.target, "fresh.txt"), "utf8"), "fresh template\n");
      assert.deepEqual(reports(f), [[]]);
      groups++;
    } else {
      console.log("SKIP: Windows GUI/junction/read-only checks require Windows.");
    }
    console.log(`PASS: soft-copy action and GUI regression groups on ${label}.`);
  }
  assert.deepEqual(snapshot(tool), originalTool, "Live tool files changed during checkups.");
  console.log(`PASS: ${groups} soft-copy regression groups; all copies and reports used disposable fixtures.`);
} finally {
  fs.rmSync(workspace, { recursive: true, force: true });
}
'@
$source | & $node - $root @engines
if ($LASTEXITCODE -ne 0) { throw "Soft-copy checkups failed with exit code $LASTEXITCODE." }
