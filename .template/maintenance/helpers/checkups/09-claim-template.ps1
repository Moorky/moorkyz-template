#requires -Version 5.1
[CmdletBinding()]
param([switch]$DryRun)
if ($DryRun) { Write-Host '[DRY RUN] Would verify template adoption in disposable copies; no repositories or files changed.'; return }

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
const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
assert.equal(process.versions.node.split(".")[0], "24", "Node.js 24 LTS is required.");
const root = process.argv[2];
const engines = process.argv.slice(3);
const engine = engines[0];
const skip = new Set([".git", ".moorkyz", ".logs", ".archive", "node_modules", "coverage", "dist", "build", "tmp", ".tmp"]);
const setup = path.join(".template", "claim-template");
const selector = path.join(root, ".template", "project-types", "SetProjectType.ps1");
const manualCommit = "0123456789ABCDEF0123456789ABCDEF01234567";
const workspace = fs.mkdtempSync(path.join(os.tmpdir(), "moorkyz claim checkups "));
let groups = 0;

function copyTemplate(name) {
  const directory = path.join(workspace, name);
  fs.mkdirSync(directory);
  for (const entry of fs.readdirSync(root)) {
    if (!skip.has(entry)) fs.cpSync(path.join(root, entry), path.join(directory, entry), { recursive: true });
  }
  return directory;
}
function configure(directory, values = {}) {
  fs.writeFileSync(path.join(directory, setup, "helpers", "setup.config.json"), `${JSON.stringify({
    projectName: "adopted-app", displayName: "Adopted App", githubOwner: "fixture-owner",
    projectTypes: [], remove: [], ...values,
  }, null, 2)}\n`);
}
function run(executable, args, cwd = workspace) {
  const result = spawnSync(executable, args, {
    cwd, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], timeout: 300000, maxBuffer: 64 * 1024 * 1024,
  });
  if (result.error) throw result.error;
  return { code: result.status, output: `${result.stdout}${result.stderr}` };
}
function powershell(executable, file, args = []) {
  return run(executable, ["-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", file, ...args]);
}
function claim(directory, args = [], executable = engine) {
  return powershell(executable, path.join(directory, setup, "CreateProject.ps1"), ["-NoPause", ...args]);
}
function snapshot(directory) {
  const state = {};
  (function visit(current) {
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      if (entry.name === ".git") continue;
      const filename = path.join(current, entry.name);
      if (entry.isDirectory()) visit(filename);
      else state[path.relative(directory, filename)] = crypto.createHash("sha256").update(fs.readFileSync(filename)).digest("hex");
    }
  })(directory);
  return state;
}
function refused(directory, args, pattern, message) {
  const before = snapshot(directory);
  const result = claim(directory, args);
  assert.notEqual(result.code, 0, `${message}\n${result.output}`);
  assert.match(result.output, pattern, message);
  assert.deepEqual(snapshot(directory), before, `${message}: refused adoption changed files.`);
}
function records(directory) {
  return fs.readdirSync(path.join(directory, ".audits")).sort();
}

try {
  const shipped = JSON.parse(fs.readFileSync(path.join(root, setup, "helpers", "setup.config.json"), "utf8"));
  assert.deepEqual(Object.keys(shipped), ["projectName", "displayName", "githubOwner", "projectTypes", "remove"]);
  assert.equal(shipped.projectName, "", "Ship projectName empty; placeholder text is not a value.");
  assert.equal(shipped.displayName, "", "Ship displayName empty; placeholder text is not a value.");
  assert.match(shipped.githubOwner, /^[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}$/);
  assert.ok(Array.isArray(shipped.projectTypes) && shipped.projectTypes.every((type) =>
    fs.statSync(path.join(root, ".template", "project-types", "helpers", "types", type)).isDirectory()), "projectTypes must be an array of existing types.");
  assert.ok(Array.isArray(shipped.remove) && shipped.remove.every((entry) => typeof entry === "string"), "remove must be an array of paths.");
  groups++;

  const refusals = copyTemplate("refusals");
  refused(refusals, ["-WhatIf"], /projectName: set[\s\S]*displayName: set/, "Shipped config must ask for the project values");
  assert.doesNotMatch(claim(refusals, ["-WhatIf"]).output, /projectTypes:/, "The shipped projectTypes value must be valid.");
  configure(refusals, { projectTypes: "selected at CreateProject.ps1" });
  refused(refusals, ["-WhatIf"], /projectTypes: must be a JSON array/, "Placeholder text in a typed field must be refused");
  configure(refusals);
  refused(refusals, ["-Yes"], /Pass -TemplateCommit/, "Adoption without provenance must be refused");
  refused(refusals, ["-Yes", "-TemplateCommit", "abc123"], /full 40-character/, "Short commit SHAs must be refused");
  configure(refusals, { projectTypes: ["web"] });
  assert.match(claim(refusals, ["-WhatIf", "-TemplateCommit", manualCommit]).output, /Types: +web/, "A one-element array is a valid list.");
  configure(refusals, { remove: ["designs"] });
  refused(refusals, ["-Yes", "-TemplateCommit", manualCommit], /still referenced/, "Removing a still-referenced folder must be refused");
  assert.match(claim(refusals, ["-Yes", "-TemplateCommit", manualCommit]).output, /(?:links to|mentions) [^\r\n]*designs[\\/]/);
  configure(refusals, { remove: [".audits"] });
  refused(refusals, ["-Yes", "-TemplateCommit", manualCommit], /would delete the audit trail/, "Removing the audit trail must be refused");
  groups++;

  configure(refusals);
  fs.mkdirSync(path.join(refusals, "notes"));
  fs.writeFileSync(path.join(refusals, "notes", "broken.md"), "[Missing](missing.md)\n");
  let result = claim(refusals, ["-Yes", "-TemplateCommit", manualCommit]);
  assert.notEqual(result.code, 0, result.output);
  assert.match(result.output, /1 internal link\(s\) are broken:[\s\S]*notes\/broken\.md: missing\.md/);
  let trail = records(refusals);
  assert.equal(trail.length, 2, `Only the clean README and the adoption record may remain: ${trail}`);
  const manualRecord = fs.readFileSync(path.join(refusals, ".audits", trail.find((name) => name.endsWith("-adopted-from-moorkyz-template.md"))), "utf8");
  assert.ok(manualRecord.includes(manualCommit.toLowerCase()), "The supplied commit must be recorded in lowercase.");
  assert.match(manualRecord, /not detected \(commit supplied with -TemplateCommit\)/);
  assert.match(manualRecord, /\| Internal link validation \| FAIL: 1 of \d+ local links/);
  fs.rmSync(path.join(refusals, "notes"), { recursive: true });
  result = claim(refusals, ["-Yes"]);
  assert.equal(result.code, 0, result.output);
  assert.match(result.output, /already has its own audit trail[\s\S]*Links: +PASS/);
  assert.deepEqual(records(refusals), trail, "Rerunning must not change the audit trail.");
  const fixedRecord = fs.readFileSync(path.join(refusals, ".audits", trail.find((name) => name.endsWith("-adopted-from-moorkyz-template.md"))), "utf8");
  assert.match(fixedRecord, /\| Internal link validation \| PASS: \d+ local links [^|\n]*\(rerun at \d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ after the first validation did not pass\) \|/,
    "A rerun must record the passing validation in the adoption record.");
  assert.doesNotMatch(fixedRecord, /\| Internal link validation \| FAIL/, "The fixed record must not keep the failed result.");
  groups++;
'@
$source += @'
  for (const executable of engines) {
    const label = path.basename(executable);
    const clone = copyTemplate(`clone ${label}`);
    configure(clone);
    const git = (args) => {
      const output = run("git", ["-c", "core.autocrlf=false", "-c", "user.name=Checkup", "-c", "user.email=checkup@example.invalid", ...args], clone);
      assert.equal(output.code, 0, output.output);
      return output.output.trim();
    };
    git(["init", "-q"]);
    git(["add", "-A"]);
    git(["commit", "-q", "-m", "Template snapshot"]);
    git(["remote", "add", "origin", "https://github.com/Moorky/moorkyz-template.git"]);
    const head = git(["rev-parse", "HEAD"]);
    const templateRecords = records(clone).filter((name) => name !== "README.md");
    assert.ok(templateRecords.length, "The fixture must contain template audit records.");
    let before = snapshot(clone);
    result = claim(clone, ["-WhatIf"], executable);
    assert.equal(result.code, 0, result.output);
    assert.ok(result.output.includes(`at ${head} (version: untagged; Git origin Moorky/moorkyz-template; working tree clean)`), result.output);
    assert.deepEqual(snapshot(clone), before, `${label}: -WhatIf changed files.`);

    result = claim(clone, ["-Yes"], executable);
    assert.equal(result.code, 0, result.output);
    assert.match(result.output, new RegExp(`${templateRecords.length} template record\\(s\\) not inherited[\\s\\S]*Links: +PASS`));
    trail = records(clone);
    assert.equal(trail.length, 2, `${label}: ${trail}`);
    const recordName = trail.find((name) => name.endsWith("-adopted-from-moorkyz-template.md"));
    const record = fs.readFileSync(path.join(clone, ".audits", recordName), "utf8");
    for (const fact of [head, "| Template version | untagged |", "working tree clean", `| Template audit records not inherited | ${templateRecords.length},`,
      "README.html regenerated; design README editions regenerated", "| Internal link validation | PASS:"]) {
      assert.ok(record.includes(fact), `${label}: adoption record lacks ${fact}`);
    }
    const auditGuide = fs.readFileSync(path.join(clone, ".audits", "README.md"), "utf8");
    assert.ok(auditGuide.includes("## Template provenance") && auditGuide.includes(head) && auditGuide.includes(`(${recordName})`));
    assert.doesNotMatch(auditGuide, /^## Current names and locations/m, "Template history sections must not be inherited.");
    const scheduler = fs.readFileSync(path.join(clone, "AGENT_SCHEDULER.md"), "utf8");
    assert.deepEqual(scheduler.match(/^\| REQ-[^ ]+ \|/gm), ["| REQ-001 |"], "Only the example request may remain.");
    assert.deepEqual(scheduler.match(/^\| [A-Z][A-Z0-9-]*-\d+ \| P\d \|/gm), ["| EXAMPLE-01 | P1 |"], "Only the example queue item may remain.");
    const pinned = `https://github.com/Moorky/moorkyz-template/blob/${head}/.audits/`;
    assert.ok(fs.readFileSync(path.join(clone, "TEMPLATE_INTRODUCTION.md"), "utf8").includes(pinned), "Evidence links must point to the template commit.");
    const relative = /\]\((?:\.\.\/)*\.audits\/(?!README\.md)[^)]*\)|href="(?:\.\.\/)*\.audits\/(?!README\.md)/;
    for (const [name] of Object.entries(snapshot(clone))) {
      if (/\.(md|html)$/.test(name) && !name.startsWith(`.audits${path.sep}`)) {
        assert.doesNotMatch(fs.readFileSync(path.join(clone, name), "utf8"), relative, `${label}: ${name} still links to a removed audit record.`);
      }
    }
    for (const file of ["SECURITY.md", path.join(".github", "ISSUE_TEMPLATE", "config.yml")]) {
      assert.ok(fs.readFileSync(path.join(clone, file), "utf8").includes("https://github.com/fixture-owner/adopted-app/security/advisories/new"), file);
    }
    assert.equal(fs.readFileSync(path.join(clone, "README.md"), "utf8").split(/\r?\n/)[0], "# Adopted App");
    assert.equal(run(process.execPath, [path.join("designs", "build.mjs"), "--check"], clone).code, 0, `${label}: design outputs are stale after adoption.`);
    const documentation = powershell(engine, path.join(clone, ".template", "maintenance", "helpers", "checkups", "02-documentation.ps1"));
    assert.equal(documentation.code, 0, `${label}: the adopted copy fails its documentation check.\n${documentation.output}`);

    fs.writeFileSync(path.join(clone, ".audits", "2026-11-01T00-00-00Z-project-task.md"), "# Project task\n");
    before = snapshot(clone);
    result = claim(clone, ["-Yes"], executable);
    assert.equal(result.code, 0, result.output);
    assert.match(result.output, /already has its own audit trail[\s\S]*Placeholder replaced in 0 file\(s\)/);
    assert.deepEqual(snapshot(clone), before, `${label}: rerunning changed the adopted project.`);
    groups++;

    const menu = path.join(workspace, `menu ${label}.ps1`);
    fs.writeFileSync(menu, [
      "$ErrorActionPreference = 'Stop'",
      `$ast = [Management.Automation.Language.Parser]::ParseFile('${selector.replaceAll("'", "''")}', [ref]$null, [ref]$null)`,
      "$definition = $ast.Find({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Read-ProjectTypeSelection' }, $true)",
      ". ([scriptblock]::Create($definition.Extent.Text))",
      "function Clear-Host { }",
      "$script:keys = New-Object 'System.Collections.Generic.Queue[object]'",
      "function Read-SelectorKey { $script:keys.Dequeue() }",
      "function Send([int]$Code, [string]$Text = '') { $script:keys.Enqueue([pscustomobject]@{ VirtualKeyCode = $Code; Character = if ($Text) { [char]$Text } else { [char]0 } }) }",
      "Send 32 ' '; Send 40; Send 32 ' '; Send 13; Send 89 'y'",
      "$picked = @(Read-ProjectTypeSelection @('alpha', 'beta', 'gamma') -SelectOnly)",
      "if (($picked -join ',') -ne 'alpha,beta') { throw \"Multiple selection returned '$($picked -join ',')'.\" }",
      "Send 51 '3'; Send 32 ' '; Send 13; Send 78 'n'; Send 81 'q'",
      "if (@(Read-ProjectTypeSelection @('alpha', 'beta', 'gamma') -SelectOnly).Count) { throw 'Quitting must select no types.' }",
      "Send 27",
      "if (@(Read-ProjectTypeSelection @('alpha') -SelectOnly).Count) { throw 'Escape must select no types.' }",
      "'PASS: select-only menu'",
    ].join("\n"));
    result = powershell(executable, menu);
    assert.equal(result.code, 0, result.output);
    assert.match(result.output, /Esc\/Q: no types[\s\S]*Use these project types: alpha, beta\?[\s\S]*PASS: select-only menu/);
    result = powershell(executable, selector, ["-SelectOnly"]);
    assert.notEqual(result.code, 0);
    assert.match(result.output, /requires an interactive terminal/);
    assert.match(powershell(executable, selector, ["-SelectOnly", "node"]).output, /do not pass project type names/);
    groups++;
  }

  const generated = copyTemplate("generated");
  const writer = path.join(workspace, "writer.ps1");
  fs.writeFileSync(writer, [
    "$ErrorActionPreference = 'Stop'",
    `$ast = [Management.Automation.Language.Parser]::ParseFile('${path.join(root, setup, "CreateProject.ps1").replaceAll("'", "''")}', [ref]$null, [ref]$null)`,
    "foreach ($name in 'ConvertTo-JsonText', 'ConvertTo-SetupJson') {",
    "  $definition = $ast.Find({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name }.GetNewClosure(), $true)",
    "  . ([scriptblock]::Create($definition.Extent.Text))",
    "}",
    "$plan = [pscustomobject]@{ ProjectName = 'generated-app'; DisplayName = ('Quote \"x\" \\ path | ' + [char]0x00FC + 'n' + [char]0x00EF + 'code'); Owner = 'fixture-owner'",
    "  ProjectTypes = @('node', 'web'); RemoveEntries = @('docs/old notes.md') }",
    `[IO.File]::WriteAllText('${path.join(generated, setup, "helpers", "setup.config.json").replaceAll("'", "''")}', (ConvertTo-SetupJson $plan), (New-Object Text.UTF8Encoding($false)))`,
  ].join("\n"));
  result = powershell(engine, writer);
  assert.equal(result.code, 0, result.output);
  const saved = JSON.parse(fs.readFileSync(path.join(generated, setup, "helpers", "setup.config.json"), "utf8"));
  assert.deepEqual(saved, { projectName: "generated-app", displayName: "Quote \"x\" \\ path | \u00fcn\u00efcode",
    githubOwner: "fixture-owner", projectTypes: ["node", "web"], remove: ["docs/old notes.md"] });
  result = claim(generated, ["-WhatIf", "-TemplateCommit", manualCommit]);
  assert.equal(result.code, 0, `Generated configuration must pass validation.\n${result.output}`);
  assert.match(result.output, /Types: +node, web/);
  groups++;
'@
$source += @'
  console.log(`PASS: ${groups} adoption regression groups; all actions used disposable copies.`);
} finally {
  fs.rmSync(workspace, { recursive: true, force: true });
}
'@
$source | & $node - $root @engines
if ($LASTEXITCODE -ne 0) { throw "Claim template checkups failed with exit code $LASTEXITCODE." }
