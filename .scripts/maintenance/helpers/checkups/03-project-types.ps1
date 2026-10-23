#requires -Version 5.1
[CmdletBinding()]
param([switch]$DryRun)

if ($DryRun) {
    Write-Host '[DRY RUN] Would validate presets and exercise selectors in disposable copies; no fixtures or actions created.'
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
assert.equal(process.versions.node.split(".")[0], "24", "Node.js 24 LTS is required.");
const sourceRelative = path.join(".scripts", "project-types");
const source = path.join(root, sourceRelative);
const typesDirectory = path.join(source, "helpers", "types");
for (const directory of [source, typesDirectory]) {
  const entry = fs.lstatSync(directory);
  assert.ok(entry.isDirectory() && !entry.isSymbolicLink(), `Refusing preset directory link: ${directory}`);
}
const types = fs.readdirSync(typesDirectory, { withFileTypes: true })
  .filter((entry) => entry.isDirectory()).map((entry) => entry.name).sort();
for (const name of ["node", "web", "docker", "typescript", "eslint", "prettier",
  "stylelint", "markdownlint", "vscode"]) assert.ok(types.includes(name), `Missing preset: ${name}`);
for (const name of types) assert.match(name, /^[a-z][a-z0-9-]*$/);

function files(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const filename = path.join(directory, entry.name);
    assert.ok(!entry.isSymbolicLink(), `Refusing preset link: ${filename}`);
    return entry.isDirectory() ? files(filename) : [filename];
  });
}

function snapshot(directory) {
  const entries = [];
  function visit(current) {
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      const filename = path.join(current, entry.name);
      assert.ok(!entry.isSymbolicLink(), `Refusing fixture link: ${filename}`);
      entries.push([path.relative(directory, filename), entry.isDirectory() ? null :
        crypto.createHash("sha256").update(fs.readFileSync(filename)).digest("hex")]);
      if (entry.isDirectory()) visit(filename);
    }
  }
  visit(directory);
  return entries.sort(([a], [b]) => a.localeCompare(b));
}

function invoke(executable, args, cwd) {
  const result = spawnSync(executable, args, {
    cwd, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], timeout: 30000,
  });
  if (result.error) throw result.error;
  assert.equal(result.signal, null, `Selector terminated by signal: ${result.signal}`);
  return { code: result.status, output: `${result.stdout}${result.stderr}` };
}

for (const filename of files(typesDirectory)) {
  if (/\.(json|webmanifest)$/i.test(filename)) {
    const config = JSON.parse(fs.readFileSync(filename, "utf8"));
    assert.ok(config && typeof config === "object" && !Array.isArray(config),
      `Expected a configuration object: ${filename}`);
  }
  else if (/\.mjs$/i.test(filename)) {
    const syntax = invoke(process.execPath, ["--check", filename], root);
    assert.equal(syntax.code, 0, syntax.output);
    assert.match(fs.readFileSync(filename, "utf8"), /\bexport default\b/, filename);
  }
}
const node = JSON.parse(fs.readFileSync(path.join(typesDirectory, "node", "package.json"), "utf8"));
assert.equal(node.private, true);
for (const field of ["dependencies", "devDependencies"]) {
  const dependencies = node[field];
  assert.ok(dependencies === undefined || (dependencies && typeof dependencies === "object" &&
    !Array.isArray(dependencies)), `${field} must be an object when present.`);
  assert.equal(Object.keys(dependencies ?? {}).length, 0, `Baseline ${field} must remain empty.`);
}
assert.match(node.scripts.test, /RunCheckups\.ps1\s+-NoPause/);
assert.match(node.scripts.verify, /^(?:npm test|.*RunCheckups\.ps1\s+-NoPause)$/);
assert.doesNotMatch(JSON.stringify(node.scripts), /node --test/);
for (const name of ["typescript", "eslint", "prettier", "stylelint", "markdownlint", "vscode"])
  assert.ok(!fs.existsSync(path.join(typesDirectory, name, "package.json")),
    `${name} must remain a configuration-only preset.`);
const tsconfig = JSON.parse(fs.readFileSync(path.join(typesDirectory, "typescript", "tsconfig.json"), "utf8"));
assert.equal(tsconfig.compilerOptions.strict, true);
assert.equal(tsconfig.compilerOptions.noEmit, true);
assert.equal(tsconfig.compilerOptions.forceConsistentCasingInFileNames, true);
console.log(`PASS: ${types.length} preset sources, JSON/ESM syntax, strict TypeScript and dependency-free maintenance scripts.`);

const workspace = fs.mkdtempSync(path.join(os.tmpdir(), "moorkyz preset checkups "));
try {
  let sequence = 0;
  function fixture() {
    const directory = path.join(workspace, `fixture ${++sequence}`);
    fs.mkdirSync(directory);
    fs.cpSync(source, path.join(directory, sourceRelative), { recursive: true });
    fs.writeFileSync(path.join(directory, "existing-user.txt"), "existing user content\n");
    return directory;
  }

  function assertApplied(directory, selected) {
    const expected = new Map([["existing-user.txt", crypto.createHash("sha256").update("existing user content\n").digest("hex")]]);
    for (const name of selected) {
      const preset = path.join(directory, sourceRelative, "helpers", "types", name);
      for (const filename of files(preset)) {
        const relative = path.relative(preset, filename);
        const content = fs.readFileSync(filename);
        assert.deepEqual(fs.readFileSync(path.join(directory, relative)), content, `${name}: ${relative}`);
        expected.set(relative, crypto.createHash("sha256").update(content).digest("hex"));
        for (let parent = path.dirname(relative); parent !== "."; parent = path.dirname(parent))
          expected.set(parent, null);
      }
    }
    const actual = snapshot(directory).filter(([name]) => name.split(path.sep)[0] !== ".scripts");
    assert.deepEqual(actual, [...expected].sort(([a], [b]) => a.localeCompare(b)),
      "Only explicitly selected preset files may be added; user files must stay intact.");
  }

  function exercise(label, select) {
    for (const name of types) {
      const directory = fixture();
      const originals = snapshot(path.join(directory, sourceRelative));
      const applied = select(directory, [name]);
      assert.equal(applied.code, 0, `${label}, ${name}: ${applied.output}`);
      assertApplied(directory, [name]);
      assert.deepEqual(snapshot(path.join(directory, sourceRelative)), originals);
    }
    console.log(`PASS: ${label}: all ${types.length} presets are independently opt-in; copies match and originals remain byte-identical.`);

    const directory = fixture();
    const before = snapshot(directory);
    const originals = snapshot(path.join(directory, sourceRelative));
    const preview = select(directory, [...types, "-WhatIf"]);
    assert.equal(preview.code, 0, `${label} preview: ${preview.output}`);
    assert.deepEqual(snapshot(directory), before, `${label}: preview changed files.`);
    const applied = select(directory, types);
    assert.equal(applied.code, 0, `${label} combined apply: ${applied.output}`);
    assertApplied(directory, types);
    assert.deepEqual(snapshot(path.join(directory, sourceRelative)), originals);
    const after = snapshot(directory);
    const repeated = select(directory, types);
    assert.equal(repeated.code, 0, `${label} rerun: ${repeated.output}`);
    assert.deepEqual(snapshot(directory), after, `${label}: rerun changed files.`);
    for (const invalid of ["missing-checkup-type", "../node"]) {
      const rejected = select(directory, ["node", invalid]);
      assert.notEqual(rejected.code, 0, `${label}: accepted invalid selection ${invalid}.`);
      assert.deepEqual(snapshot(directory), after, `${label}: failed selection changed files.`);
    }

    const conflict = fixture();
    fs.writeFileSync(path.join(conflict, "package.json"), "existing user config\n");
    const conflictBefore = snapshot(conflict);
    const rejected = select(conflict, types);
    assert.notEqual(rejected.code, 0, `${label}: overwrote differing package.json.`);
    assert.deepEqual(snapshot(conflict), conflictBefore, `${label}: conflict caused partial copies or user-data changes.`);
    console.log(`PASS: ${label}: combined preview/apply/rerun, invalid selections and conflict preflight; spaced paths and user/source bytes preserved.`);
  }

  for (const engine of engines) {
    exercise(path.basename(engine), (directory, args) => invoke(engine, [
      "-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
      "-File", path.join(directory, sourceRelative, "SetProjectType.ps1"), ...args,
    ], directory));
  }
  if (process.platform === "win32") {
    exercise("CMD", (directory, args) => {
      const command = `call "${path.join(directory, sourceRelative, "SetProjectType.cmd")}" ${args.join(" ")}`;
      const script = `& $env:ComSpec /d /c '${command.replaceAll("'", "''")}'`;
      return invoke(engines[0], [
        "-NoLogo", "-NoProfile", "-NonInteractive", "-EncodedCommand",
        Buffer.from(script, "utf16le").toString("base64"),
      ], directory);
    });
  }
  else console.log("SKIP: CMD requires Windows; Windows CI covers the batch entrypoint.");
}
finally {
  fs.rmSync(workspace, { recursive: true, force: true });
}
console.log("PASS: disposable preset fixtures removed; no selector action targeted the live repository.");
'@
$source | & $node - $root @engines
if ($LASTEXITCODE -ne 0) { throw "Project-type checkup exited with code $LASTEXITCODE." }
