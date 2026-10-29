#requires -Version 5.1
[CmdletBinding()]
param([switch]$DryRun)
if ($DryRun) { Write-Host '[DRY RUN] Would verify release metadata, references, provenance and adoption in disposable copies; nothing changed.'; return }

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
const cli = require(path.join(root, "moorkyz"));
const skip = new Set([".git", ".moorkyz", ".logs", ".archive", "node_modules", "coverage", "dist", "build", "tmp", ".tmp"]);
const setup = path.join(".template", "claim-template");
const selector = path.join(root, ".template", "project-types", "SetProjectType.ps1");
const templateUrl = "https://github.com/Moorky/moorkyz-template.git";
const workspace = fs.mkdtempSync(path.join(os.tmpdir(), "mz integrity "));
let groups = 0;

// Every Git call, including those inside CreateProject.ps1, reads only this configuration;
// it redirects the template URL to a disposable upstream, so the production code path runs unchanged.
const upstream = path.join(workspace, "upstream.git");
const gitconfig = path.join(workspace, "gitconfig");
fs.writeFileSync(gitconfig, [
  "[user]", "\tname = Integrity Checkup", "\temail = checkup@example.invalid",
  "[core]", "\tautocrlf = false",
  "[init]", "\tdefaultBranch = master",
  `[url "${upstream.replaceAll("\\", "/")}"]`, `\tinsteadOf = ${templateUrl}`, "",
].join("\n"));
process.env.GIT_CONFIG_GLOBAL = gitconfig;
process.env.GIT_CONFIG_NOSYSTEM = "1";
// A dedicated temporary folder shows whether adoption cleans up after itself, also with -WhatIf.
const scratch = path.join(workspace, "temp");
fs.mkdirSync(scratch);
process.env.TEMP = scratch;
process.env.TMP = scratch;

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
function git(cwd, args) {
  const result = run("git", args, cwd);
  assert.equal(result.code, 0, `git ${args.join(" ")}\n${result.output}`);
  return result.output.trim();
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
function adoptionRecord(directory) {
  const name = records(directory).find((entry) => entry.endsWith("-adopted-from-moorkyz-template.md"));
  assert.ok(name, `No adoption record in ${directory}`);
  return fs.readFileSync(path.join(directory, ".audits", name), "utf8");
}

try {
  // Release metadata: the changelog, the archive stamp and the version labels.
  const changelog = fs.readFileSync(path.join(root, ".template", "CHANGELOG.md"), "utf8");
  const releases = [...changelog.matchAll(/^## v(\d+)\.(\d+)\.(\d+) \u2014 (\d{4}-\d{2}-\d{2})$/gm)];
  assert.ok(releases.length, "The template changelog must list at least one release.");
  assert.doesNotMatch(changelog, /^## (?!v\d+\.\d+\.\d+ \u2014 \d{4}-\d{2}-\d{2}$)/m, "Release headings must read '## vX.Y.Z \u2014 YYYY-MM-DD'.");
  for (const [index, release] of releases.entries()) {
    assert.ok(!Number.isNaN(Date.parse(`${release[4]}T00:00:00Z`)), `Invalid release date: ${release[0]}`);
    if (index) {
      const newer = releases[index - 1].slice(1, 4).map(Number);
      const older = release.slice(1, 4).map(Number);
      assert.ok(newer[0] > older[0] || (newer[0] === older[0] && (newer[1] > older[1] || (newer[1] === older[1] && newer[2] > older[2]))),
        `Releases must be listed newest first: ${releases[index - 1][0]} before ${release[0]}.`);
    }
  }
  const checkedOut = run("git", ["-C", root, "describe", "--tags", "--exact-match", "--match", "v[0-9]*", "HEAD"]);
  let tagNote = "no release tag checked out";
  if (checkedOut.code === 0) {
    const tag = checkedOut.output.trim();
    assert.match(changelog, new RegExp(`^## ${tag.replaceAll(".", "\\.")} \u2014 `, "m"), `The changelog must describe the checked-out release ${tag}.`);
    tagNote = `the checked-out release ${tag} is described`;
  }
  assert.ok(fs.readFileSync(path.join(root, ".gitattributes"), "utf8").split(/\r?\n/)
    .includes(".template/claim-template/helpers/template-commit.txt export-subst"), "GitHub downloads must record their template commit.");
  // The placeholder in Git checkouts; GitHub ZIP downloads contain the filled-in commit instead.
  assert.match(fs.readFileSync(path.join(root, setup, "helpers", "template-commit.txt"), "utf8"), /^(?:\$Format:%H\$|[0-9a-f]{40})\n$/);
  const labels = path.join(workspace, "labels");
  fs.mkdirSync(labels);
  assert.equal(cli.versionLabel(labels), "no Git history");
  git(labels, ["init", "-q"]);
  fs.writeFileSync(path.join(labels, "file.txt"), "one\n");
  git(labels, ["add", "-A"]);
  git(labels, ["commit", "-q", "-m", "one"]);
  assert.match(cli.versionLabel(labels), /^development build [0-9a-f]{7}$/);
  git(labels, ["tag", "-a", "v1.2.3", "-m", "v1.2.3"]);
  assert.equal(cli.versionLabel(labels), "v1.2.3");
  fs.writeFileSync(path.join(labels, "file.txt"), "two\n");
  git(labels, ["commit", "-qam", "two"]);
  assert.match(cli.versionLabel(labels), /^development build [0-9a-f]{7} \u00b7 1 commit after v1\.2\.3$/);
  fs.writeFileSync(path.join(labels, "file.txt"), "three\n");
  assert.match(cli.versionLabel(labels), / \u00b7 local changes$/);
  console.log(`PASS: release metadata (${releases.length} release(s) in the changelog; ${tagNote}), archive stamp and version labels.`);
  groups++;

  // Reference integrity: the repository, rule-by-rule units and a mutated copy.
  const repository = cli.scanReferences(root);
  assert.deepEqual(repository.broken, [], `Broken references:\n${repository.broken.map((entry) => `${entry.file}:${entry.line} ${entry.target}`).join("\n")}`);
  assert.ok(repository.checked > 500, "The reference scan found suspiciously few references.");
  const unit = path.join(workspace, "references unit");
  for (const [name, text] of Object.entries({
    "README.md": "# Unit\n",
    "docs/guide.md": "[ok](../README.md) [gone](missing.md) [web](https://example.com/a/b) [top](#top)\n",
    "tools/build.ps1": "$a = Join-Path $root 'docs\\guide.md'\n$b = Join-Path $root 'docs\\gone.md'\n$c = Join-Path $other 'docs\\x.md'\n$d = \"$root\\docs\\$name\"\n# 'docs/commented.md' is a comment\n",
    "tools/app.mjs": "import \"./helper.mjs\";\nconst p = path.join(root, \"docs\", \"guide.md\");\nconst q = path.join(root, \"docs\", \"absent.md\");\nconst r = path.join(dir, name);\nconst s = \"../relative/unknown.txt\";\n",
    "tools/helper.mjs": "export {};\n",
    "config/settings.json": "{ \"entry\": \"docs/guide.md\", \"gone\": \"docs/nowhere.md\", \"url\": \"https://example.com/a/b\" }\n",
    ".github/workflows/ci.yml": "jobs:\n  a:\n    steps:\n      - run: node tools/app.mjs && node tools/absent.mjs\n      - run: echo ${{ github.sha }}/x\n",
    "run.cmd": "@call \"%~dp0tools\\missing.cmd\"\r\n",
    "Dockerfile": "COPY docs ./docs\nCOPY nothing ./x\nCOPY --from=build /a /b\n",
    "tests/fixture.test.mjs": "const f = \"docs/not-real.md\";\n",
  })) {
    fs.mkdirSync(path.dirname(path.join(unit, name)), { recursive: true });
    fs.writeFileSync(path.join(unit, name), text);
  }
  const units = cli.scanReferences(unit);
  const brokenUnits = units.broken.map((entry) => `${entry.file} ${entry.target}`).sort();
  assert.deepEqual(brokenUnits, [
    ".github/workflows/ci.yml tools/absent.mjs",
    "Dockerfile nothing",
    "config/settings.json docs/nowhere.md",
    "docs/guide.md missing.md",
    "run.cmd %~dp0tools\\missing.cmd",
    "tools/app.mjs docs/absent.md",
    "tools/build.ps1 docs\\gone.md",
  ], `Unexpected reference findings:\n${brokenUnits.join("\n")}`);
  const unverified = units.unverified.map((entry) => `${entry.file} ${entry.reason}`).sort();
  for (const expected of [
    ".github/workflows/ci.yml dynamic", "tools/app.mjs dynamic", "tools/app.mjs relative to an unknown base",
    "tools/build.ps1 dynamic", "tools/build.ps1 relative to a base that is not the repository",
  ]) assert.ok(unverified.includes(expected), `Expected an unverified '${expected}':\n${unverified.join("\n")}`);
  assert.equal(units.fixtureFiles, 1, "Test files must be treated as fixtures.");
  const mutated = copyTemplate("mutated");
  for (const [from, to] of [
    [".template/maintenance/RunCheckups.ps1", ".template/maintenance/RunAll.ps1"],
    ["website/verify.mjs", "website/verify-renamed.mjs"],
    [".template/project-types/SetProjectType.ps1", ".template/project-types/SetTypes.ps1"],
    ["designs/catalog.mjs", "designs/catalog-old.mjs"],
    ["website/deploy/nginx.conf", "website/deploy/nginx-old.conf"],
  ]) fs.renameSync(path.join(mutated, from), path.join(mutated, to));
  const mutations = cli.scanReferences(mutated).broken;
  for (const [file, target] of [
    [".github/workflows/project-tooling.yml", "RunCheckups.ps1"],
    [".template/project-types/helpers/types/node/package.json", "RunCheckups.ps1"],
    [".template/project-types/SetProjectType.cmd", "SetProjectType.ps1"],
    [".template/claim-template/CreateProject.ps1", "SetProjectType.ps1"],
    ["website/build.mjs", "catalog.mjs"],
    ["website/deploy/Dockerfile", "nginx.conf"],
    ["moorkyz.config.json", "website/verify.mjs"],
    ["README.md", "SetProjectType.ps1"],
  ]) assert.ok(mutations.some((entry) => entry.file === file && entry.target.includes(target)), `${file} must report its broken ${target} reference.`);
  const removal = cli.scanReferences(root, { removing: ["designs"] }).removed;
  for (const reason of ["link", "mention", "name"]) {
    assert.ok(removal.some((entry) => entry.reason === reason), `Removing designs must report a ${reason}.`);
  }
  assert.ok(!removal.some((entry) => entry.file.startsWith(".audits/") || entry.file === "AGENT_SCHEDULER.md"), "History is not a removal blocker.");
  console.log(`PASS: ${repository.checked} references in ${repository.files} files resolve; ${repository.unverified.length} dynamic or base-relative expressions are reported as not verifiable; rule units, a mutated copy and removal checks pass.`);
  groups++;

  // A disposable upstream with a tagged release and a later development commit.
  const sourceCopy = copyTemplate("upstream source");
  git(sourceCopy, ["init", "-q"]);
  git(sourceCopy, ["add", "-A"]);
  git(sourceCopy, ["commit", "-q", "-m", "Release snapshot"]);
  const released = git(sourceCopy, ["rev-parse", "HEAD"]);
  git(sourceCopy, ["tag", "-a", "v1.0.0", "-m", "v1.0.0"]);
  fs.appendFileSync(path.join(sourceCopy, "CONTRIBUTING.md"), "\n");
  git(sourceCopy, ["commit", "-qam", "Development change"]);
  const developed = git(sourceCopy, ["rev-parse", "HEAD"]);
  git(workspace, ["clone", "--bare", "-q", sourceCopy, upstream]);
  const stranger = git(sourceCopy, ["commit-tree", `${developed}^{tree}`, "-p", developed, "-m", "Never published"]);

  const refusals = copyTemplate("refusals");
  refused(refusals, ["-WhatIf"], /projectName: set[\s\S]*displayName: set/, "Shipped config must ask for the project values");
  assert.doesNotMatch(claim(refusals, ["-WhatIf"]).output, /projectTypes:/, "The shipped projectTypes value must be valid.");
  configure(refusals, { projectTypes: "selected at CreateProject.ps1" });
  refused(refusals, ["-WhatIf"], /projectTypes: must be a JSON array/, "Placeholder text in a typed field must be refused");
  configure(refusals);
  refused(refusals, ["-Yes"], /Cannot tell which template commit[\s\S]*-TemplateCommit/, "Adoption without provenance must be refused");
  refused(refusals, ["-Yes", "-TemplateCommit", "abc123"], /full 40-character/, "Short commit SHAs must be refused");
  refused(refusals, ["-Yes", "-TemplateCommit", "0123456789abcdef0123456789abcdef01234567"], /is not part of/, "Unknown commits must be refused");
  refused(refusals, ["-Yes", "-TemplateCommit", stranger], /is not part of/, "Commits that were never published upstream must be refused");
  configure(refusals, { projectTypes: ["web"] });
  assert.match(claim(refusals, ["-WhatIf", "-TemplateCommit", released]).output, /Types: +web/, "A one-element array is a valid list.");
  configure(refusals, { remove: ["designs"] });
  refused(refusals, ["-Yes", "-TemplateCommit", released], /still referenced/, "Removing a still-referenced folder must be refused");
  assert.match(claim(refusals, ["-Yes", "-TemplateCommit", released]).output, /(?:links to|mentions|names) [^\r\n]*designs/);
  configure(refusals, { remove: [".audits"] });
  refused(refusals, ["-Yes", "-TemplateCommit", released], /would delete the audit trail/, "Removing the audit trail must be refused");
  groups++;

  configure(refusals);
  fs.mkdirSync(path.join(refusals, "notes"));
  fs.writeFileSync(path.join(refusals, "notes", "broken.md"), "[Missing](missing.md)\n");
  let result = claim(refusals, ["-Yes", "-TemplateCommit", released.toUpperCase()]);
  assert.notEqual(result.code, 0, result.output);
  assert.match(result.output, /1 reference\(s\) are broken:[\s\S]*notes\/broken\.md:1: missing\.md/);
  let trail = records(refusals);
  assert.equal(trail.length, 2, `Only the clean README and the adoption record may remain: ${trail}`);
  let record = adoptionRecord(refusals);
  for (const fact of [released, "| Template version | v1.0.0 |", "supplied with -TemplateCommit; verified in the template repository"])
    assert.ok(record.includes(fact), `The manual adoption record lacks ${fact}`);
  assert.match(record, /\| Reference validation \| FAIL: 1 of \d+ references/);
  fs.rmSync(path.join(refusals, "notes"), { recursive: true });
  result = claim(refusals, ["-Yes"]);
  assert.equal(result.code, 0, result.output);
  assert.match(result.output, /already has its own audit trail[\s\S]*Checks: +PASS/);
  assert.deepEqual(records(refusals), trail, "Rerunning must not change the audit trail.");
  record = adoptionRecord(refusals);
  assert.match(record, /\| Reference validation \| PASS: \d+ references [^|\n]*\(rerun at \d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ after the first validation did not pass\) \|/,
    "A rerun must record the passing validation in the adoption record.");
  groups++;
'@
$source += @'
  for (const executable of engines) {
    const label = path.basename(executable);
    const clone = path.join(workspace, `clone ${label}`);
    git(workspace, ["clone", "-q", templateUrl, clone]);
    assert.equal(git(clone, ["rev-parse", "HEAD"]), developed, "The clone must come from the redirected upstream.");
    configure(clone);
    git(clone, ["commit", "-qam", "Local setup"]);
    const templateRecords = records(clone).filter((name) => name !== "README.md");
    assert.ok(templateRecords.length, "The fixture must contain template audit records.");
    let before = snapshot(clone);
    result = claim(clone, ["-WhatIf"], executable);
    assert.equal(result.code, 0, result.output);
    const devLabel = `development build ${developed.slice(0, 7)} (1 commit after v1.0.0)`;
    assert.ok(result.output.includes(`at ${developed} (version: ${devLabel}; this repository's Git history; 1 local commit after it)`), result.output);
    assert.deepEqual(snapshot(clone), before, `${label}: -WhatIf changed files.`);

    result = claim(clone, ["-Yes"], executable);
    assert.equal(result.code, 0, result.output);
    assert.match(result.output, new RegExp(`${templateRecords.length} template record\\(s\\) not inherited[\\s\\S]*Checks: +PASS`));
    trail = records(clone);
    assert.equal(trail.length, 2, `${label}: ${trail}`);
    const recordName = trail.find((name) => name.endsWith("-adopted-from-moorkyz-template.md"));
    record = adoptionRecord(clone);
    for (const fact of [developed, `| Template version | ${devLabel} |`, "1 local commit after it", `| Template audit records not inherited | ${templateRecords.length},`,
      "README.html regenerated; design README editions regenerated", "| Reference validation | PASS:"]) {
      assert.ok(record.includes(fact), `${label}: adoption record lacks ${fact}`);
    }
    const auditGuide = fs.readFileSync(path.join(clone, ".audits", "README.md"), "utf8");
    assert.ok(auditGuide.includes("## Template provenance") && auditGuide.includes(developed) && auditGuide.includes(`(${recordName})`));
    assert.doesNotMatch(auditGuide, /^## Current names and locations/m, "Template history sections must not be inherited.");
    const scheduler = fs.readFileSync(path.join(clone, "AGENT_SCHEDULER.md"), "utf8");
    assert.deepEqual(scheduler.match(/^\| REQ-[^ ]+ \|/gm), ["| REQ-001 |"], "Only the example request may remain.");
    assert.deepEqual(scheduler.match(/^\| [A-Z][A-Z0-9-]*-\d+ \| P\d \|/gm), ["| EXAMPLE-01 | P1 |"], "Only the example queue item may remain.");
    const pinned = `https://github.com/Moorky/moorkyz-template/blob/${developed}/.audits/`;
    assert.ok(fs.readFileSync(path.join(clone, "TEMPLATE_INTRODUCTION.md"), "utf8").includes(pinned), "Evidence links must point to the template commit.");
    for (const file of ["SECURITY.md", path.join(".github", "ISSUE_TEMPLATE", "config.yml")]) {
      assert.ok(fs.readFileSync(path.join(clone, file), "utf8").includes("https://github.com/fixture-owner/adopted-app/security/advisories/new"), file);
    }
    assert.equal(fs.readFileSync(path.join(clone, "README.md"), "utf8").split(/\r?\n/)[0], "# Adopted App");
    assert.equal(run(process.execPath, [path.join("designs", "build.mjs"), "--check"], clone).code, 0, `${label}: design outputs are stale after adoption.`);
    assert.deepEqual(cli.scanReferences(clone).broken, [], `${label}: the adopted copy has broken references.`);
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

  // GitHub's "Use this template": a new history whose first commit has the release's exact files.
  const checkout = path.join(workspace, "release checkout");
  git(workspace, ["clone", "-q", "--no-checkout", upstream, checkout]);
  const copy = path.join(workspace, "template copy");
  fs.mkdirSync(copy);
  git(checkout, [`--work-tree=${copy}`, "checkout", released, "--", "."]);
  git(copy, ["init", "-q"]);
  git(copy, ["add", "-A"]);
  git(copy, ["commit", "-q", "-m", "Initial commit"]);
  assert.equal(git(copy, ["rev-parse", "HEAD^{tree}"]), git(workspace, [`--git-dir=${upstream}`, "rev-parse", `${released}^{tree}`]), "The simulated copy must have the release's exact tree.");
  configure(copy);
  result = claim(copy, ["-Yes"]);
  assert.equal(result.code, 0, result.output);
  record = adoptionRecord(copy);
  for (const fact of [released, "| Template version | v1.0.0 |", "GitHub template copy", "| Reference validation | PASS:"])
    assert.ok(record.includes(fact), `The template-copy adoption record lacks ${fact}`);
  groups++;

  // GitHub ZIP downloads: git archive fills in the export-subst stamp.
  const archived = path.join(workspace, "zip download");
  fs.mkdirSync(archived);
  const tarball = path.join(workspace, "release.tar");
  git(workspace, [`--git-dir=${upstream}`, "archive", "--format=tar", "-o", tarball, "v1.0.0"]);
  const extract = run("tar", ["-xf", tarball, "-C", archived]);
  assert.equal(extract.code, 0, extract.output);
  assert.equal(fs.readFileSync(path.join(archived, setup, "helpers", "template-commit.txt"), "utf8").trim(), released);
  configure(archived);
  result = claim(archived, ["-WhatIf"]);
  assert.equal(result.code, 0, result.output);
  assert.ok(result.output.includes(`at ${released} (version: v1.0.0; recorded in the GitHub download; verified in the template repository)`), result.output);
  groups++;

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
  result = claim(generated, ["-WhatIf", "-TemplateCommit", released]);
  assert.equal(result.code, 0, `Generated configuration must pass validation.\n${result.output}`);
  assert.match(result.output, /Types: +node, web/);
  groups++;
'@
$source += @'
  assert.deepEqual(fs.readdirSync(scratch).filter((name) => name.startsWith("moorkyz-template-")), [],
    "Claim Template must remove its temporary template history, also after -WhatIf.");
  console.log(`PASS: ${groups} template integrity groups; all actions used disposable copies and a disposable upstream.`);
} finally {
  fs.rmSync(workspace, { recursive: true, force: true });
}
'@
$source | & $node - $root @engines
if ($LASTEXITCODE -ne 0) { throw "Template integrity checkups failed with exit code $LASTEXITCODE." }
