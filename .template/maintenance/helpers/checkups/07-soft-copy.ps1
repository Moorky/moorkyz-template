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
let shortAliases = 0;
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
  const script = `$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest; try { ${command}; exit 0 } catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }`;
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
  return fs.readdirSync(directory).filter((name) => /^conflicts-.*\.json$/.test(name))
    .map((name) => JSON.parse(fs.readFileSync(path.join(directory, name), "utf8")));
}
function recoveryFiles(f) {
  const directory = path.join(f.source, ".moorkyz", "soft-copy");
  return fs.existsSync(directory) ? fs.readdirSync(directory).filter((name) => /^recovery-.*\.json$/.test(name))
    .map((name) => path.join(directory, name)) : [];
}
function revert(engine, f, recovery, flags = "", target = f.target) {
  return invoke(engine, f, null, "", target,
    `& ${quote(f.entry)} -TargetDirectory ${quote(target)} -Revert ${quote(recovery)} ${flags}`);
}
// GitHub's Windows runners use an 8.3 short TEMP path; revert must accept either form.
function shortAlias(filename) {
  if (process.platform !== "win32") return null;
  const result = spawnSync(process.env.ComSpec || "cmd.exe",
    ["/d", "/s", "/c", `"for %I in ("${filename}") do @echo %~sI"`],
    { encoding: "utf8", windowsVerbatimArguments: true });
  const alias = result.status === 0 ? result.stdout.trim() : "";
  return alias && alias.toLowerCase() !== filename.toLowerCase() ? alias : null;
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
    write(path.join(f.target, "conflict.txt"), "preserved conflict");
    const beforeCopy = snapshot(f.target);
    success(invoke(engine, f, ["fresh.txt", "nested/binary.bin", "conflict.txt"]));
    let recovery = recoveryFiles(f)[0];
    let journal = JSON.parse(fs.readFileSync(recovery));
    assert.equal(journal.status, "ready");
    assert.equal(journal.files.length, 2);
    const recoveryAlias = shortAlias(recovery);
    const targetAlias = shortAlias(f.target);
    const sourceAlias = shortAlias(f.source);
    if (recoveryAlias) shortAliases++;
    if (sourceAlias) {
      const core = path.join(path.dirname(f.entry), "helpers", "CopyCore.ps1");
      success(invoke(engine, f, null, "", f.target, `. ${quote(core)};
        $long = @(Get-TemplateCopyFiles ${quote(f.source)}) -join '|'; $short = @(Get-TemplateCopyFiles ${quote(sourceAlias)}) -join '|';
        if (-not $long -or $long -cne $short) { throw "Short template root changed file names: $short" }`));
    }
    before = snapshot(f.directory);
    success(revert(engine, f, recoveryAlias || recovery, "-WhatIf", targetAlias || f.target));
    success(revert(engine, f, "missing-snapshot", "-DryRun", "missing-target"));
    assert.deepEqual(snapshot(f.directory), before, "Revert preview/dry run changed files.");
    success(revert(engine, f, recoveryAlias || recovery, "", targetAlias || f.target));
    assert.deepEqual(snapshot(f.target), beforeCopy);
    assert.equal(JSON.parse(fs.readFileSync(recovery)).status, "reverted");
    assert.equal(reports(f).length, 1, "Revert changed the original conflict report.");
    before = snapshot(f.directory);
    failure(revert(engine, f, recovery), /not available/);
    assert.deepEqual(snapshot(f.directory), before, "Repeated revert changed files.");
    groups++;

    f = fixture();
    for (const [name, bytes] of [
      ["conflict.txt", "original longer contents"], ["empty.txt", "not empty before"],
      ["unicode.txt", Buffer.from([0xff, 0xfe, 65, 0])], ["nested/binary.bin", Buffer.from([255, 5, 0])],
    ]) write(path.join(f.target, name), bytes);
    const oldTime = new Date("2001-02-03T04:05:06.000Z");
    fs.utimesSync(path.join(f.target, "conflict.txt"), oldTime, oldTime);
    const forceBefore = snapshot(f.target);
    success(invoke(engine, f, ["conflict.txt", "empty.txt", "unicode.txt", "nested/binary.bin", "fresh.txt"], "-ForceCopy"));
    recovery = recoveryFiles(f)[0];
    success(revert(engine, f, recovery));
    assert.deepEqual(snapshot(f.target), forceBefore, "Force revert did not restore exact original bytes.");
    assert.equal(fs.statSync(path.join(f.target, "conflict.txt")).mtimeMs, oldTime.getTime());
    assert.equal(fs.readFileSync(path.join(f.source, "empty.txt")).length, 0);
    groups++;

    f = fixture();
    write(path.join(f.target, "conflict.txt"), "old contents");
    success(invoke(engine, f, ["conflict.txt"]));
    assert.equal(recoveryFiles(f).length, 0, "An unchanged copy should not enable recovery.");
    groups++;

    f = fixture();
    write(path.join(f.target, "conflict.txt"), "old contents");
    success(invoke(engine, f, ["conflict.txt", "fresh.txt"], "-ForceCopy"));
    recovery = recoveryFiles(f)[0];
    write(path.join(f.target, "fresh.txt"), "user edited later");
    before = snapshot(f.directory);
    failure(revert(engine, f, recovery), /changed since copy/);
    assert.deepEqual(snapshot(f.directory), before, "Stale revert modified part of the target.");
    write(path.join(f.target, "fresh.txt"), fs.readFileSync(path.join(f.source, "fresh.txt")));
    fs.unlinkSync(path.join(f.target, "conflict.txt"));
    before = snapshot(f.directory);
    failure(revert(engine, f, recovery), /removed since copy/);
    assert.deepEqual(snapshot(f.directory), before);
    write(path.join(f.target, "conflict.txt"), fs.readFileSync(path.join(f.source, "conflict.txt")));
    success(revert(engine, f, recovery));
    assert.equal(fs.readFileSync(path.join(f.target, "conflict.txt"), "utf8"), "old contents");
    groups++;

    f = fixture();
    write(path.join(f.source, "aa", "new.txt"), "a");
    write(path.join(f.source, "bb", "new.txt"), "b");
    fs.mkdirSync(path.join(f.target, "nested"));
    success(invoke(engine, f, ["aa/new.txt", "bb/new.txt", "nested/binary.bin"]));
    recovery = recoveryFiles(f)[0];
    write(path.join(f.target, "aa", "user.txt"), "later unrelated work");
    success(revert(engine, f, recovery));
    assert.equal(fs.readFileSync(path.join(f.target, "aa", "user.txt"), "utf8"), "later unrelated work");
    assert.ok(!fs.existsSync(path.join(f.target, "aa", "new.txt")));
    assert.ok(!fs.existsSync(path.join(f.target, "bb")), "Empty new sibling directory was not removed.");
    assert.ok(fs.statSync(path.join(f.target, "nested")).isDirectory(), "Pre-existing directory was removed.");
    groups++;

    f = fixture();
    write(path.join(f.target, "conflict.txt"), "old contents");
    success(invoke(engine, f, ["conflict.txt", "fresh.txt"], "-ForceCopy"));
    recovery = recoveryFiles(f)[0];
    const originalJournal = fs.readFileSync(recovery);
    for (const mutate of [
      (j) => { j.version = 2; },
      (j) => { j.target = f.directory; },
      (j) => { j.files[0].name = "../sentinel.txt"; },
      (j) => { j.files[0].name = ".git/config"; },
      (j) => { j.files[0].name = ".git /config"; },
      (j) => { j.files[0].state = "writing"; },
      (j) => { j.files[0].before = Buffer.from("corrupt backup").toString("base64"); },
      (j) => { j.files.push({ ...j.files[0] }); },
      (j) => { j.files[0].afterHash = "invalid"; },
    ]) {
      journal = JSON.parse(originalJournal);
      mutate(journal);
      fs.writeFileSync(recovery, JSON.stringify(journal));
      before = snapshot(f.directory);
      failure(revert(engine, f, recovery));
      assert.deepEqual(snapshot(f.directory), before, "Invalid recovery changed files.");
    }
    fs.writeFileSync(recovery, originalJournal);
    const wrongTarget = path.join(f.directory, "other repository");
    fs.mkdirSync(wrongTarget);
    before = snapshot(f.directory);
    failure(revert(engine, f, recovery, "", wrongTarget), /does not match/);
    assert.deepEqual(snapshot(f.directory), before);
    success(revert(engine, f, recovery));
    groups++;

    f = fixture();
    const partialCore = path.join(path.dirname(f.entry), "helpers", "CopyCore.ps1");
    const blockedFile = path.join(f.target, "nested", "binary.bin");
    const partial = `
      . ${quote(partialCore)};
      $plan = New-TemplateCopyPlan -Root ${quote(f.source)} -TargetDirectory ${quote(f.target)} -File @('fresh.txt','nested/binary.bin');
      $global:originalPathCheck = \${function:Assert-CopyPath}; $global:destinationChecks = 0;
      function Assert-CopyPath([string]$Path) {
        & $global:originalPathCheck $Path;
        if ([IO.Path]::GetFullPath($Path) -eq [IO.Path]::GetFullPath(${quote(blockedFile)})) {
          $global:destinationChecks++;
          if ($global:destinationChecks -eq 2) {
            [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path));
            [IO.File]::WriteAllText($Path,'other writer');
          }
        }
      }
      try { Invoke-TemplateCopyPlan $plan; throw 'Expected injected copy failure' }
      catch { if (-not $_.Exception.Data.Contains('RecoveryPath')) { throw }; 'PASS: recoverable partial copy failure' }
    `;
    success(invoke(engine, f, null, "", f.target, partial));
    assert.ok(fs.existsSync(path.join(f.target, "fresh.txt")));
    recovery = recoveryFiles(f)[0];
    assert.equal(JSON.parse(fs.readFileSync(recovery)).status, "failed");
    success(revert(engine, f, recovery));
    assert.ok(!fs.existsSync(path.join(f.target, "fresh.txt")));
    assert.equal(fs.readFileSync(blockedFile, "utf8"), "other writer", "Revert deleted a file it did not create.");
    groups++;

    f = fixture();
    write(path.join(f.target, "conflict.txt"), "original");
    success(invoke(engine, f, ["conflict.txt"], "-ForceCopy"));
    const firstRecovery = recoveryFiles(f)[0];
    write(path.join(f.source, "conflict.txt"), "second version");
    success(invoke(engine, f, ["conflict.txt"], "-ForceCopy"));
    const secondRecovery = recoveryFiles(f).find((filename) => filename !== firstRecovery);
    before = snapshot(f.directory);
    failure(revert(engine, f, firstRecovery), /changed since copy/);
    assert.deepEqual(snapshot(f.directory), before);
    success(revert(engine, f, secondRecovery));
    assert.equal(fs.readFileSync(path.join(f.target, "conflict.txt"), "utf8"), "new\n");
    success(revert(engine, f, firstRecovery));
    assert.equal(fs.readFileSync(path.join(f.target, "conflict.txt"), "utf8"), "original");
    groups++;

    f = fixture();
    success(invoke(engine, f, ["fresh.txt"]));
    recovery = recoveryFiles(f)[0];
    before = snapshot(f.directory);
    const lockCore = path.join(path.dirname(f.entry), "helpers", "CopyCore.ps1");
    const locked = `
      . ${quote(lockCore)}; $lock = Open-CopyRecoveryLock ${quote(recovery)};
      try { Invoke-TemplateRevertPlan (New-TemplateRevertPlan ${quote(f.source)} ${quote(f.target)} ${quote(recovery)}) }
      finally { $lock.Dispose() }
    `;
    failure(invoke(engine, f, null, "", f.target, locked));
    assert.deepEqual(snapshot(f.directory), before, "Concurrent revert changed files.");
    success(revert(engine, f, recovery));
    groups++;

    f = fixture();
    const boundaryCore = path.join(path.dirname(f.entry), "helpers", "CopyCore.ps1");
    const boundary = `
      . ${quote(boundaryCore)};
      $plan = New-TemplateCopyPlan -Root ${quote(f.source)} -TargetDirectory ${quote(f.target)} -File fresh.txt;
      $global:saveJson = \${function:Write-CopyJson}; $global:injected = $false;
      function Write-CopyJson([string]$Path, $Value, [switch]$New) {
        if ($Value.PSObject.Properties['status'] -and $Value.files[0].state -eq 'writing' -and -not $global:injected) {
          $global:injected = $true; throw 'Injected journal-write failure before file data';
        }
        & $global:saveJson -Path $Path -Value $Value -New:$New;
      }
      try { Invoke-TemplateCopyPlan $plan; throw 'Expected copy-boundary failure' }
      catch { if (-not $_.Exception.Data.Contains('RecoveryPath')) { throw }; 'PASS: boundary recovery recorded' }
    `;
    success(invoke(engine, f, null, "", f.target, boundary));
    assert.equal(fs.statSync(path.join(f.target, "fresh.txt")).size, 0);
    recovery = recoveryFiles(f)[0];
    success(revert(engine, f, recovery));
    assert.ok(!fs.existsSync(path.join(f.target, "fresh.txt")), "An aborted new file was not removed.");
    groups++;

    f = fixture();
    const directoryCore = path.join(path.dirname(f.entry), "helpers", "CopyCore.ps1");
    const failedDirectory = path.join(f.target, "nested");
    const directoryFailure = `
      . ${quote(directoryCore)};
      $plan = New-TemplateCopyPlan -Root ${quote(f.source)} -TargetDirectory ${quote(f.target)} -File @('fresh.txt','nested/binary.bin');
      $global:checkPath = \${function:Assert-CopyPath};
      function Assert-CopyPath([string]$Path) {
        & $global:checkPath $Path;
        if ([IO.Path]::GetFullPath($Path) -eq [IO.Path]::GetFullPath(${quote(failedDirectory)})) { [IO.File]::WriteAllText($Path,'directory blocker') }
      }
      try { Invoke-TemplateCopyPlan $plan; throw 'Expected directory failure' }
      catch { if (-not $_.Exception.Data.Contains('RecoveryPath')) { throw }; 'PASS: directory failure did not claim ownership' }
    `;
    success(invoke(engine, f, null, "", f.target, directoryFailure));
    recovery = recoveryFiles(f)[0];
    assert.deepEqual(JSON.parse(fs.readFileSync(recovery)).directories, [], "Failed directory creation claimed ownership.");
    fs.unlinkSync(failedDirectory);
    fs.mkdirSync(failedDirectory);
    success(revert(engine, f, recovery));
    assert.ok(fs.statSync(failedDirectory).isDirectory(), "Revert removed a later directory it never created.");
    groups++;

    f = fixture();
    write(path.join(f.target, "conflict.txt"), "original first file");
    write(path.join(f.target, "empty.txt"), "original second file");
    success(invoke(engine, f, ["conflict.txt", "empty.txt"], "-ForceCopy"));
    recovery = recoveryFiles(f)[0];
    const retryCore = path.join(path.dirname(f.entry), "helpers", "CopyCore.ps1");
    const secondFile = path.join(f.target, "empty.txt");
    const retry = `
      . ${quote(retryCore)};
      $plan = New-TemplateRevertPlan ${quote(f.source)} ${quote(f.target)} ${quote(recovery)};
      $global:checkPath = \${function:Assert-CopyPath}; $global:undoChecks = 0;
      function Assert-CopyPath([string]$Path) {
        & $global:checkPath $Path;
        if ([IO.Path]::GetFullPath($Path) -eq [IO.Path]::GetFullPath(${quote(secondFile)})) {
          $global:undoChecks++;
          if ($global:undoChecks -eq 2) { [IO.File]::WriteAllText($Path,'edited just before second restore') }
        }
      }
      Invoke-TemplateRevertPlan $plan;
    `;
    failure(invoke(engine, f, null, "", f.target, retry), /changed before revert/);
    journal = JSON.parse(fs.readFileSync(recovery));
    assert.equal(journal.status, "reverting");
    assert.equal(journal.files[0].state, "reverted");
    write(path.join(f.target, "conflict.txt"), "new edit after first restore");
    write(secondFile, "");
    success(revert(engine, f, recovery));
    assert.equal(fs.readFileSync(path.join(f.target, "conflict.txt"), "utf8"), "new edit after first restore");
    assert.equal(fs.readFileSync(secondFile, "utf8"), "original second file");
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
      for (const kind of ["hardlink", "junction", "readonly"]) {
        f = fixture();
        success(invoke(engine, f, ["fresh.txt", "nested/binary.bin"]));
        recovery = recoveryFiles(f)[0];
        const outside = path.join(f.directory, "outside recovery");
        fs.mkdirSync(outside);
        const outsideFile = path.join(outside, "sentinel.txt");
        write(outsideFile, "preserve outside");
        const fresh = path.join(f.target, "fresh.txt");
        if (kind === "hardlink") {
          fs.unlinkSync(fresh);
          fs.linkSync(outsideFile, fresh);
        } else if (kind === "junction") {
          fs.unlinkSync(path.join(f.target, "nested", "binary.bin"));
          fs.rmdirSync(path.join(f.target, "nested"));
          fs.symlinkSync(outside, path.join(f.target, "nested"), "junction");
        } else {
          success(invoke(engine, f, null, "", f.target, `(Get-Item -LiteralPath ${quote(fresh)}).IsReadOnly=$true`));
        }
        before = snapshot(f.directory);
        failure(revert(engine, f, recovery), kind === "readonly" ? /read-only/ : /link|junction/);
        assert.deepEqual(snapshot(f.directory), before, "Unsafe revert modified files.");
        assert.equal(fs.readFileSync(outsideFile, "utf8"), "preserve outside");
        if (kind === "readonly") {
          success(invoke(engine, f, null, "", f.target, `(Get-Item -LiteralPath ${quote(fresh)}).IsReadOnly=$false`));
        }
      }
      groups++;

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
        $global:revertTestAnswer = $false;
        function global:Confirm-TemplateRevert { return $global:revertTestAnswer }
        $ui = New-TemplateCopyForm -Root ${quote(f.source)};
        try {
          Assert (-not $ui.Force.Checked) 'Force must default off';
          Assert ($ui.Files.CheckedItems.Count -eq 0) 'Files must default unchecked';
          Assert (-not $ui.Revert.Enabled) 'Revert must default disabled';
          $ui.Form.Show(); [Windows.Forms.Application]::DoEvents();
          $ui.All.PerformClick(); Assert ($ui.Files.CheckedItems.Count -eq $ui.Files.Items.Count) 'Select all';
          $ui.None.PerformClick(); Assert ($ui.Files.CheckedItems.Count -eq 0) 'Select none';
          $ui.Copy.PerformClick(); Assert ($ui.Status.Text -like 'FAILED*') 'Missing target must fail visibly';
          $ui.Target.Text = ${quote(f.target)};
          $ui.Copy.PerformClick(); Assert ($ui.Status.Text -like 'FAILED*') 'Empty selection must fail visibly';
          $ui.Files.SetItemChecked($ui.Files.Items.IndexOf('conflict.txt'), $true);
          $ui.Copy.PerformClick(); Assert ($ui.Status.Text -like 'DONE*preserved: 1*') $ui.Status.Text;
          Assert ([IO.File]::ReadAllText(${quote(path.join(f.target, "conflict.txt"))}) -eq 'GUI old value') 'GUI normal mode overwrote';
          Assert (-not $ui.Revert.Enabled) 'Unchanged copy must not enable revert';
          $ui.Force.Checked = $true;
          $ui.Copy.PerformClick(); Assert ($ui.Status.Text -like 'Cancelled*') $ui.Status.Text;
          Assert ([IO.File]::ReadAllText(${quote(path.join(f.target, "conflict.txt"))}) -eq 'GUI old value') 'GUI cancel overwrote';
          $global:confirmTestAnswer = $true;
          $ui.Copy.PerformClick(); Assert ($ui.Status.Text -like 'DONE*replaced: 1*') $ui.Status.Text;
          Assert ([IO.File]::ReadAllText(${quote(path.join(f.target, "conflict.txt"))}) -eq "new\`n") 'GUI force did not replace';
          Assert $ui.Revert.Enabled 'Copy must enable revert';
          $ui.Target.Text = 'not the original target';
          $ui.Revert.PerformClick(); Assert ($ui.Status.Text -like 'Revert cancelled*') $ui.Status.Text;
          Assert $ui.Revert.Enabled 'Cancelled revert must remain available';
          $global:revertTestAnswer = $true;
          [IO.File]::WriteAllText(${quote(path.join(f.target, "conflict.txt"))},'later edit');
          $ui.Revert.PerformClick(); Assert ($ui.Status.Text -like 'FAILED*changed since copy*') $ui.Status.Text;
          Assert $ui.Revert.Enabled 'Refused revert must remain available';
          [IO.File]::WriteAllText(${quote(path.join(f.target, "conflict.txt"))},"new\`n");
          $ui.Revert.PerformClick(); Assert ($ui.Status.Text -like 'REVERTED*Restored: 1*') $ui.Status.Text;
          Assert (-not $ui.Revert.Enabled) 'Successful revert must disable button';
          Assert ([IO.File]::ReadAllText(${quote(path.join(f.target, "conflict.txt"))}) -eq 'GUI old value') 'GUI revert did not restore';
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
  console.log(shortAliases
    ? `PASS: ${shortAliases} revert(s) accepted 8.3 short recovery and target paths.`
    : "SKIP: 8.3 short names unavailable here; a short TEMP path (GitHub Windows runners) covers them.");
  console.log(`PASS: ${groups} soft-copy regression groups; all copies and reports used disposable fixtures.`);
} finally {
  fs.rmSync(workspace, { recursive: true, force: true });
}
'@
$source | & $node - $root @engines
if ($LASTEXITCODE -ne 0) { throw "Soft-copy checkups failed with exit code $LASTEXITCODE." }
