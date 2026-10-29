#requires -Version 5.1
[CmdletBinding()]
param([switch]$DryRun)

if ($DryRun) {
    Write-Host '[DRY RUN] Would check documentation links and generated HTML; nothing executed.'
    return
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$node = (Get-Command node -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$source = @'
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const root = process.argv[2];
const cliPath = path.join(root, "moorkyz");
assert.ok(fs.statSync(cliPath).isFile(), "The moorkyz entry must stay at the repository root.");
assert.ok(!fs.existsSync(path.join(root, ".template", "moorkyz", "moorkyz")),
  "Do not move or duplicate the root CLI under .template.");
const { renderReadme } = require(cliPath);
const excluded = new Set([".git", ".moorkyz", ".logs", ".archive",
  "node_modules", "coverage", "dist", "build", "tmp", ".tmp"]);

function files(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    if (excluded.has(entry.name)) return [];
    const filename = path.join(directory, entry.name);
    if (entry.isSymbolicLink()) throw new Error(`Refusing link: ${filename}`);
    if (entry.isDirectory()) return files(filename);
    return entry.isFile() && /\.(md|html|ps1)$/i.test(entry.name) ? [filename] : [];
  });
}

function exactPath(filename) {
  const relative = path.relative(root, filename);
  if (relative === ".." || relative.startsWith(`..${path.sep}`) || path.isAbsolute(relative)) return false;
  let directory = root;
  for (const part of relative.split(path.sep).filter(Boolean)) {
    if (!fs.existsSync(directory) || !fs.statSync(directory).isDirectory() ||
        !fs.readdirSync(directory).includes(part)) return false;
    directory = path.join(directory, part);
  }
  return true;
}

const sources = files(root);
// Links and literal paths are validated by the shared reference engine in 09-template-integrity.ps1.
const markdown = fs.readFileSync(path.join(root, "README.md"), "utf8");
assert.equal(fs.readFileSync(path.join(root, "README.html"), "utf8"), renderReadme(markdown),
  "README.html is stale; run node moorkyz readme");
console.log("PASS: README.html matches README.md.");
const templateToolsDirectory = path.join(root, ".template");
assert.ok(!fs.existsSync(path.join(root, [".template", "tools"].join("-"))),
  "The retired template-tool parent must not return; use .template/.");
assert.ok(!fs.existsSync(path.join(templateToolsDirectory, "copilot")),
  "The Copilot settings tool must live under .template/copilot-settings/.");
const catalog = path.join(templateToolsDirectory, "README.md");
assert.ok(exactPath(catalog), "Missing template-tool catalog.");
assert.match(fs.readFileSync(catalog, "utf8"), /^# Template tools\r?$/m,
  "The catalog must identify reusable template tools, not project-owned tooling.");
const toolEntrypoints = {
  "copilot-settings": ["Setup-CopilotProject.ps1"],
  "claim-template": ["CreateProject.ps1"],
  maintenance: ["RunCheckups.ps1"],
  "project-types": ["SetProjectType.ps1", "SetProjectType.cmd"],
  run: ["Run.ps1"],
  "script-icons": ["SetScriptIcons.ps1"],
  "soft-copy": ["CopyTemplate.ps1"],
};
for (const [tool, entrypoints] of Object.entries(toolEntrypoints)) {
  const directory = path.join(templateToolsDirectory, tool);
  const readme = path.join(directory, "README.md");
  assert.ok(exactPath(readme), `${tool}: missing adjacent README.`);
  assert.match(fs.readFileSync(readme, "utf8"), /^## When to use$/m, `${tool}: missing usage guidance.`);
  for (const filename of entrypoints) assert.ok(exactPath(path.join(directory, filename)), filename);
  const allowed = new Set(["README.md", "helpers", ...entrypoints]);
  for (const entry of fs.readdirSync(directory)) {
    assert.ok(allowed.has(entry), `${tool}: supporting files must live under helpers/: ${entry}`);
  }
}
for (const file of ["AGENTS.md", "README.md"]) {
  assert.ok(fs.readFileSync(path.join(root, file), "utf8").includes(".template/README.md"),
    `${file} must point agents and users to the template-tool catalog.`);
}
assert.ok(exactPath(path.join(root, "moorkyz")), "The CLI must remain at the repository root.");
const launcher = fs.readFileSync(path.join(root, "RUN.cmd"), "utf8");
assert.match(launcher, /%~dp0\.template\\run\\Run\.ps1/, "RUN.cmd must stay a thin launcher for .template/run/Run.ps1.");
assert.ok(launcher.includes("\r\n") && !/[^\r]\n/.test(launcher), "RUN.cmd needs CRLF line endings.");
console.log(`PASS: all ${Object.keys(toolEntrypoints).length} tool folders have adjacent entrypoints/README, helpers are nested, the root CLI and RUN.cmd launcher are preserved, and template-tool discovery is documented.`);
assert.ok(!fs.existsSync(path.join(root, "READM.html")), "Retired duplicate READM.html must not return.");
const cli = fs.readFileSync(cliPath, "utf8");
assert.doesNotMatch(cli, /require\(["']\.\.?\//, "The portable CLI must not depend on local helpers.");
const ignored = fs.readFileSync(path.join(root, ".gitignore"), "utf8");
const dockerIgnored = fs.readFileSync(path.join(root, ".template", "project-types", "helpers", "types", "docker", ".dockerignore"), "utf8");
for (const name of [".logs", ".archive", ".moorkyz"]) {
  assert.ok(ignored.split(/\r?\n/).includes(`/${name}/`), `${name} must stay Git-ignored.`);
  assert.ok(dockerIgnored.split(/\r?\n/).includes(name), `${name} must stay Docker-ignored.`);
}
assert.doesNotMatch(ignored, /^\/?\.audits\/?$/m, "Audit history must remain tracked.");
assert.ok(exactPath(path.join(root, ".audits", "README.md")), "Missing versioned audit history.");
assert.ok(exactPath(path.join(root, "docs", "AUDIT_TEMPLATE.md")), "Audit template must live directly under docs/.");
assert.ok(!fs.existsSync(path.join(root, "audits")), "Reports must live under .audits/.");
assert.ok(!fs.existsSync(path.join(root, "docs", "audits")), "The obsolete docs audit folder must not return.");

const retired = new RegExp([
  ["create", "project"].join("") + "\\.ps1",
  ["un", "pack"].join("") + "\\.ps1",
  "(?:overlay|\\.optional)[/\\\\]",
  ["[Mm]ake", "[Tt]his", "[Yy]ours"].join("[ -]"),
].join("|"));
assert.ok(!fs.existsSync(path.join(templateToolsDirectory, ["make", "this", "yours"].join("-"))),
  "The adoption tool must live under .template/claim-template/.");
assert.doesNotMatch(cli, /\.projecttypes[/\\]/,
  "CLI help must reference .template/project-types/.");
for (const filename of sources) {
  if (path.relative(root, filename).split(path.sep)[0] === ".audits") continue;
  assert.doesNotMatch(fs.readFileSync(filename, "utf8"), retired, path.relative(root, filename));
}
console.log("PASS: active documentation and PowerShell examples use current script names.");

const publicDirectory = path.join(root, ".template", "project-types", "helpers", "types", "web", "public");
const manifest = JSON.parse(fs.readFileSync(path.join(publicDirectory, "site.webmanifest"), "utf8"));
assert.ok(Array.isArray(manifest.icons) && manifest.icons.length, "Web manifest must list icons.");
for (const icon of manifest.icons) {
  assert.equal(typeof icon.src, "string", "Icon source must be a string.");
  const filename = path.resolve(publicDirectory, icon.src.replace(/^\//, ""));
  assert.ok(filename.startsWith(publicDirectory + path.sep) && exactPath(filename) &&
    fs.statSync(filename).isFile(), icon.src);
}
const workflow = fs.readFileSync(path.join(root, ".github", "workflows", "project-tooling.yml"), "utf8");
const versionFile = workflow.match(/^\s*node-version-file:\s*(\S+)\s*$/m);
assert.ok(versionFile, "CI must reference the shared Node pin.");
assert.ok(exactPath(path.join(root, versionFile[1])), versionFile[1]);
assert.equal(fs.readFileSync(path.join(root, versionFile[1]), "utf8").trim(), "24");
assert.match(workflow, /RunCheckups\.ps1\s+-NoPause/);
assert.ok(workflow.includes(".template\\maintenance\\RunCheckups.ps1"),
  "CI must run the consolidated maintenance entrypoint.");
assert.match(workflow, /^\s*shell:\s*pwsh\s*$/m);
assert.doesNotMatch(workflow, /node --test/);
console.log("PASS: icon filenames, CI Node pin and maintenance entrypoint are current.");

const policy = fs.readFileSync(path.join(root, "SECURITY.md"), "utf8");
assert.match(policy, /https:\/\/github\.com\/[A-Za-z0-9-]+\/[A-Za-z0-9_.-]+\/security\/advisories\/new/);
assert.ok(!policy.includes(`github.com/Moorky/${["moorkyz", "project"].join("-")}/security/`),
  "Private reporting must not point to the template placeholder.");
const rendered = renderReadme("# Example\n\n`<unsafe>` & text\n\n```sh\n<command>\n```\n");
assert.match(rendered, /<title>Example<\/title>/);
assert.match(rendered, /<code>&lt;unsafe&gt;<\/code> &amp; text/);
assert.match(rendered, /<pre><code>&lt;command&gt;<\/code><\/pre>/);
assert.throws(() => renderReadme("```js\nunfinished"), /unclosed code fence/);
console.log("PASS: portable CLI, runtime ignore boundaries, private reporting and README escaping safeguards.");

const forms = path.join(root, ".github", "ISSUE_TEMPLATE");
if (fs.existsSync(forms)) {
  const advisory = policy.match(/https:\/\/github\.com\/[A-Za-z0-9-]+\/[A-Za-z0-9_.-]+\/security\/advisories\/new/)[0];
  const chooser = fs.readFileSync(path.join(forms, "config.yml"), "utf8");
  assert.ok(chooser.includes(`url: ${advisory}`), "The issue chooser must send vulnerabilities to the SECURITY.md reporting link.");
  const names = fs.readdirSync(forms).filter((name) => /\.ya?ml$/.test(name) && name !== "config.yml");
  assert.ok(names.length, "The issue template folder must contain at least one issue form.");
  for (const name of names) {
    const form = fs.readFileSync(path.join(forms, name), "utf8");
    for (const key of ["name", "description", "body"]) assert.match(form, new RegExp(`^${key}:`, "m"), `${name}: missing ${key}`);
    const ids = [...form.matchAll(/^\s+id: ([a-z0-9_-]+)\r?$/gm)].map((match) => match[1]);
    assert.equal(new Set(ids).size, ids.length, `${name}: issue form field ids must be unique.`);
  }
  console.log(`PASS: ${names.length} issue forms have required keys and unique ids; the chooser points to private vulnerability reporting.`);
}
'@
$source | & $node - $root
if ($LASTEXITCODE -ne 0) { throw "Documentation check exited with code $LASTEXITCODE." }
