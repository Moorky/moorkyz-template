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
assert.ok(!fs.existsSync(path.join(root, ".scripts", "moorkyz", "moorkyz")),
  "Do not move or duplicate the root CLI under .scripts.");
const { renderReadme } = require(cliPath);
const excluded = new Set([".git", ".moorkyz", ".logs", ".archive", ".trash",
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

const errors = [];
const sources = files(root);
for (const filename of sources.filter((name) => /\.(md|html)$/i.test(name))) {
  const source = fs.readFileSync(filename, "utf8");
  const pattern = filename.endsWith(".html") ? /(?:href|src)=["']([^"']+)["']/g :
    /!?\[[^\]]*\]\((?:<([^>]+)>|([^)\s]+))(?:\s+"[^"]*")?\)/g;
  for (const match of source.matchAll(pattern)) {
    const target = match[1] || match[2];
    if (/^[a-z][a-z0-9+.-]*:|^#|^\/\//i.test(target)) continue;
    const local = decodeURIComponent(target.split(/[?#]/)[0]);
    if (!exactPath(path.resolve(path.dirname(filename), local)))
      errors.push(`${path.relative(root, filename)}: ${target}`);
  }
}
assert.deepEqual(errors, [], `Broken or incorrectly cased links:\n${errors.join("\n")}`);
console.log("PASS: all local Markdown/HTML links exist with exact filename casing.");
const markdown = fs.readFileSync(path.join(root, "README.md"), "utf8");
assert.equal(fs.readFileSync(path.join(root, "README.html"), "utf8"), renderReadme(markdown),
  "README.html is stale; run node moorkyz readme");
console.log("PASS: README.html matches README.md.");
const scriptsDirectory = path.join(root, ".scripts");
assert.ok(exactPath(path.join(scriptsDirectory, "README.md")), "Missing script catalog.");
const toolEntrypoints = {
  copilot: ["Setup-CopilotProject.ps1"],
  "claim-template": ["CreateProject.ps1"],
  maintenance: ["RunCheckups.ps1"],
  "project-types": ["SetProjectType.ps1", "SetProjectType.cmd"],
};
for (const [tool, entrypoints] of Object.entries(toolEntrypoints)) {
  const directory = path.join(scriptsDirectory, tool);
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
  assert.ok(fs.readFileSync(path.join(root, file), "utf8").includes(".scripts/README.md"),
    `${file} must point agents and users to the script catalog.`);
}
assert.ok(exactPath(path.join(root, "moorkyz")), "The CLI must remain at the repository root.");
console.log("PASS: all four tool folders have adjacent entrypoints/README, helpers are nested, root CLI is preserved, and script discovery is documented.");
assert.ok(!fs.existsSync(path.join(root, "READM.html")), "Retired duplicate READM.html must not return.");
const cli = fs.readFileSync(cliPath, "utf8");
assert.doesNotMatch(cli, /require\(["']\.\.?\//, "The portable CLI must not depend on local helpers.");
const ignored = fs.readFileSync(path.join(root, ".gitignore"), "utf8");
const dockerIgnored = fs.readFileSync(path.join(root, ".scripts", "project-types", "helpers", "types", "docker", ".dockerignore"), "utf8");
for (const name of [".logs", ".archive", ".trash", ".moorkyz"]) {
  assert.ok(ignored.split(/\r?\n/).includes(`/${name}/`), `${name} must stay Git-ignored.`);
  assert.ok(dockerIgnored.split(/\r?\n/).includes(name), `${name} must stay Docker-ignored.`);
}
assert.doesNotMatch(ignored, /^\/?audits\/?$/m, "Audit history must remain tracked.");

const retired = new RegExp([
  ["create", "project"].join("") + "\\.ps1",
  ["un", "pack"].join("") + "\\.ps1",
  "(?:overlay|\\.optional)[/\\\\]",
  ["[Mm]ake", "[Tt]his", "[Yy]ours"].join("[ -]"),
].join("|"));
assert.ok(!fs.existsSync(path.join(scriptsDirectory, ["make", "this", "yours"].join("-"))),
  "The adoption tool must live under .scripts/claim-template/.");
assert.doesNotMatch(cli, /\.projecttypes[/\\]/,
  "CLI help must reference .scripts/project-types/.");
for (const filename of sources) {
  if (path.relative(root, filename).split(path.sep)[0] === "audits") continue;
  assert.doesNotMatch(fs.readFileSync(filename, "utf8"), retired, path.relative(root, filename));
}
console.log("PASS: active documentation and PowerShell examples use current script names.");

const publicDirectory = path.join(root, ".scripts", "project-types", "helpers", "types", "web", "public");
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
assert.ok(workflow.includes(".scripts\\maintenance\\RunCheckups.ps1"),
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
'@
$source | & $node - $root
if ($LASTEXITCODE -ne 0) { throw "Documentation check exited with code $LASTEXITCODE." }
