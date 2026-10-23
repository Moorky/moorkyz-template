#requires -Version 5.1
[CmdletBinding()]
param([switch]$DryRun)

if ($DryRun) {
    Write-Host '[DRY RUN] Would check Copilot setup results in disposable copies; no settings or fixtures changed.'
    return
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$node = (Get-Command node -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$engines = @((Get-Process -Id $PID).Path)
if ($env:OS -eq 'Windows_NT') {
    foreach ($name in 'pwsh', 'powershell.exe') {
        $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command -and $engines -notcontains $command.Source) { $engines += $command.Source }
        elseif (-not $command) { Write-Host "[SKIP] Additional PowerShell host unavailable: $name" }
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
const root = process.argv[2];
const engines = process.argv.slice(3);
const source = path.join(root, ".template-tools", "copilot");
assert.equal(process.versions.node.split(".")[0], "24", "Node.js 24 LTS is required.");
function snapshot(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const filename = path.join(directory, entry.name);
    assert.ok(!entry.isSymbolicLink(), `Refusing fixture/source link: ${filename}`);
    return entry.isDirectory() ? [[filename, null], ...snapshot(filename)] :
      [[filename, crypto.createHash("sha256").update(fs.readFileSync(filename)).digest("hex")]];
  }).sort(([a], [b]) => a.localeCompare(b));
}
const originals = snapshot(source);
const workspace = fs.mkdtempSync(path.join(os.tmpdir(), "moorkyz copilot checkups "));
try {
  let sequence = 0;
  function fixture() {
    const directory = path.join(workspace, `fixture ${++sequence}`);
    const tool = path.join(directory, "copilot");
    const project = path.join(directory, "project with spaces");
    const appdata = path.join(directory, "user profile");
    fs.mkdirSync(project, { recursive: true });
    fs.mkdirSync(appdata);
    fs.cpSync(source, tool, { recursive: true });
    const config = path.join(tool, "helpers", "copilot-config.json");
    fs.writeFileSync(config, JSON.stringify({
      globalSettings: { "chat.agent.enabled": true },
      projectSettings: { "chat.agent.enabled": true },
      sandbox: "off", createAgentsMd: true, mcpServers: {},
    }));
    fs.writeFileSync(path.join(project, "existing-user.txt"), "preserve me\n");
    return { directory, tool, project, appdata, config };
  }
  function write(filename, content) {
    fs.mkdirSync(path.dirname(filename), { recursive: true });
    fs.writeFileSync(filename, content);
  }
  function invoke(engine, fixture, args = [], pause = false) {
    const result = spawnSync(engine, [
      "-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
      "-File", path.join(fixture.tool, "Setup-CopilotProject.ps1"),
      ...(!args.includes("-ProjectPath") ? ["-ProjectPath", fixture.project] : []),
      ...(!args.includes("-Scope") ? ["-Scope", "Project"] : []),
      ...(!pause ? ["-NoPause"] : []), ...args,
    ], {
      cwd: fixture.directory, env: { ...process.env, APPDATA: fixture.appdata },
      encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], timeout: 30000,
    });
    if (result.error) throw result.error;
    assert.equal(result.signal, null);
    return { code: result.status, output: `${result.stdout}${result.stderr}` };
  }
  function success(result) {
    assert.equal(result.code, 0, result.output);
    assert.match(result.output, /ALL SET - Copilot configuration completed successfully\./);
    assert.doesNotMatch(result.output, /FAILED|INCOMPLETE|PREVIEW ONLY|Press any key/);
  }
  function failure(result, ...steps) {
    assert.equal(result.code, 1, result.output);
    assert.match(result.output, /FAILED - Copilot setup has \d+ failed step\(s\):/);
    assert.doesNotMatch(result.output, /ALL SET/);
    for (const step of steps) assert.ok(result.output.includes(`  - ${step}:`), result.output);
  }
  for (const engine of engines) {
    const label = path.basename(engine);
    let fixtureData = fixture();
    success(invoke(engine, fixtureData));
    const applied = snapshot(fixtureData.directory);
    const rerun = invoke(engine, fixtureData);
    success(rerun);
    assert.match(rerun.output, /Updated: 0; unchanged\/preserved: 2;/);
    assert.deepEqual(snapshot(fixtureData.directory), applied, "Rerun changed files or added backups.");
    assert.equal(JSON.parse(fs.readFileSync(path.join(fixtureData.project, ".vscode", "settings.json")))["chat.agent.enabled"], true);
    assert.equal(fs.readFileSync(path.join(fixtureData.project, "existing-user.txt"), "utf8"), "preserve me\n");

    fixtureData = fixture();
    const settings = path.join(fixtureData.project, ".vscode", "settings.json");
    const originalSettings = '{ // keep in backup\n"editor.fontSize": 17,\n"chat.agent.enabled": false,\n}\n';
    write(settings, originalSettings);
    write(path.join(fixtureData.project, "AGENTS.md"), "existing instructions\n");
    success(invoke(engine, fixtureData));
    assert.equal(JSON.parse(fs.readFileSync(settings))["editor.fontSize"], 17);
    assert.equal(fs.readFileSync(path.join(fixtureData.project, "AGENTS.md"), "utf8"), "existing instructions\n");
    const backups = fs.readdirSync(path.dirname(settings)).filter((name) => name.startsWith("settings.json.bak."));
    assert.equal(backups.length, 1);
    assert.equal(fs.readFileSync(path.join(path.dirname(settings), backups[0]), "utf8"), originalSettings);

    for (const mode of ["-WhatIf", "-DryRun"]) {
      fixtureData = fixture();
      const before = snapshot(fixtureData.directory);
      const result = invoke(engine, fixtureData, [mode]);
      assert.equal(result.code, 0, result.output);
      assert.match(result.output, mode === "-WhatIf" ? /PREVIEW ONLY/ : /\[DRY RUN\]/);
      assert.doesNotMatch(result.output, /ALL SET|FAILED|Press any key/);
      assert.deepEqual(snapshot(fixtureData.directory), before);
    }
    for (const invalid of ["missing-config", "invalid-json", "invalid-mcp", "missing-project"]) {
      fixtureData = fixture();
      let args = [];
      if (invalid === "missing-config") args = ["-ConfigPath", path.join(fixtureData.directory, "missing.json")];
      if (invalid === "invalid-json") fs.writeFileSync(fixtureData.config, "{ invalid");
      if (invalid === "invalid-mcp") {
        const config = JSON.parse(fs.readFileSync(fixtureData.config));
        config.mcpServers = [];
        fs.writeFileSync(fixtureData.config, JSON.stringify(config));
      }
      if (invalid === "missing-project") args = ["-ProjectPath", path.join(fixtureData.directory, "missing")];
      const before = snapshot(fixtureData.directory);
      failure(invoke(engine, fixtureData, args), "Setup validation");
      assert.deepEqual(snapshot(fixtureData.directory), before, `${invalid} wrote files.`);
    }

    fixtureData = fixture();
    const config = JSON.parse(fs.readFileSync(fixtureData.config));
    config.mcpServers = { reviewedExample: { type: "stdio", command: "not-executed" } };
    fs.writeFileSync(fixtureData.config, JSON.stringify(config));
    write(path.join(fixtureData.project, ".vscode", "settings.json"), "{ invalid");
    write(path.join(fixtureData.project, ".vscode", "mcp.json"), "{ invalid");
    const globalSettings = path.join(fixtureData.appdata, "Code", "User", "settings.json");
    write(globalSettings, "{ invalid");
    const partial = invoke(engine, fixtureData, ["-Scope", "Both"]);
    failure(partial, "Global settings", "Project settings", "MCP settings");
    assert.match(partial.output, /has 3 failed step\(s\)/);
    assert.ok(fs.existsSync(path.join(fixtureData.project, "AGENTS.md")), "Independent step was not attempted.");
    assert.equal(fs.readFileSync(globalSettings, "utf8"), "{ invalid");
    assert.equal(fs.readFileSync(path.join(fixtureData.project, ".vscode", "settings.json"), "utf8"), "{ invalid");

    fixtureData = fixture();
    fs.unlinkSync(path.join(fixtureData.tool, "helpers", "AGENTS.template.md"));
    failure(invoke(engine, fixtureData), "AGENTS.md");
    assert.ok(fs.existsSync(path.join(fixtureData.project, ".vscode", "settings.json")));

    fixtureData = fixture();
    const beforePreview = snapshot(fixtureData.directory);
    const preview = invoke(engine, fixtureData, ["-WhatIf"], true);
    assert.equal(preview.code, 0, preview.output);
    assert.match(preview.output, /PREVIEW ONLY/);
    assert.match(preview.output, /Press any key to exit/);
    assert.deepEqual(snapshot(fixtureData.directory), beforePreview);
    const pausedSuccess = invoke(engine, fixtureData, [], true);
    assert.equal(pausedSuccess.code, 0, pausedSuccess.output);
    assert.match(pausedSuccess.output, /ALL SET/);
    assert.match(pausedSuccess.output, /Press any key to exit/);
    fs.writeFileSync(fixtureData.config, "{ invalid");
    const pausedFailure = invoke(engine, fixtureData, [], true);
    failure(pausedFailure, "Setup validation");
    assert.match(pausedFailure.output, /Press any key to exit/);
    assert.match(pausedFailure.output, /Input is redirected/);
    const noRead = invoke(engine, fixtureData, ["-DryRun"]);
    assert.equal(noRead.code, 0, noRead.output);
    assert.doesNotMatch(noRead.output, /FAILED|ALL SET|Press any key/);

    if (process.platform === "win32") {
      for (const [scope, edition] of [["Both", "Stable"], ["Global", "Insiders"]]) {
        fixtureData = fixture();
        success(invoke(engine, fixtureData, ["-Scope", scope, "-VSCode", edition]));
        const codeDirectory = edition === "Insiders" ? "Code - Insiders" : "Code";
        const global = JSON.parse(fs.readFileSync(path.join(fixtureData.appdata, codeDirectory, "User", "settings.json")));
        assert.equal(global["chat.agent.enabled"], true);
        assert.equal(global["chat.agent.sandbox.enabled"], "off");
        assert.equal(fs.existsSync(path.join(fixtureData.project, "AGENTS.md")), scope === "Both");
      }
    }
    console.log(`PASS: ${label}: success/rerun, JSONC backup/preservation, preview/dry-run, four validation failures, three aggregated step failures, missing template, redirected pause and isolated user scopes.`);
  }
  assert.deepEqual(snapshot(source), originals, "Copilot setup source bytes changed.");
  console.log("PASS: all setup actions used disposable project/user directories; source bytes unchanged.");
} finally {
  fs.rmSync(workspace, { recursive: true, force: true });
}
'@
$source | & $node - $root @engines
if ($LASTEXITCODE -ne 0) { throw "Copilot setup check exited with code $LASTEXITCODE." }
