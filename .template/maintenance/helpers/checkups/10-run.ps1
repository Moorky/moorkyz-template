#requires -Version 5.1
[CmdletBinding()]
param([switch]$DryRun)
if ($DryRun) { Write-Host '[DRY RUN] Would verify RUN.cmd, the runtime bootstrap and moorkyz up in disposable copies; nothing changed.'; return }

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
# A stand-in for the official Node.js archive: the running node.exe in the layout nodejs.org uses.
$archive = 'none'
$staging = Join-Path ([IO.Path]::GetTempPath()) ('mz-run-archive-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
if ($env:OS -eq 'Windows_NT') {
    $arch = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
    $arch = @{ AMD64 = 'x64'; ARM64 = 'arm64' }[$arch]
    $version = (& $node --version).Trim().TrimStart('v')
    $folder = Join-Path $staging "node-v$version-win-$arch"
    [void][IO.Directory]::CreateDirectory($folder)
    Copy-Item -LiteralPath $node -Destination (Join-Path $folder 'node.exe')
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = Join-Path $staging "node-v$version-win-$arch.zip"
    [IO.Compression.ZipFile]::CreateFromDirectory($folder, $archive, [IO.Compression.CompressionLevel]::Fastest, $true)
}
$source = @'
"use strict";
const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const http = require("node:http");
const os = require("node:os");
const path = require("node:path");
const { spawn, spawnSync } = require("node:child_process");
assert.equal(process.versions.node.split(".")[0], "24", "Node.js 24 LTS is required.");
const [root, archive, ...engines] = process.argv.slice(2);
const cli = require(path.join(root, "moorkyz"));
const skip = new Set([".git", ".moorkyz", ".logs", ".archive", "node_modules", "coverage", "dist", "build", "tmp", ".tmp"]);
const workspace = fs.mkdtempSync(path.join(os.tmpdir(), "mz run "));
const windows = process.platform === "win32";
let groups = 0;

function copyTemplate(name) {
  const directory = path.join(workspace, name);
  fs.mkdirSync(directory);
  for (const entry of fs.readdirSync(root)) {
    if (!skip.has(entry)) fs.cpSync(path.join(root, entry), path.join(directory, entry), { recursive: true });
  }
  return directory;
}
function collect(child) {
  return new Promise((resolve) => {
    let output = "";
    child.stdout.on("data", (chunk) => { output += chunk; });
    child.stderr.on("data", (chunk) => { output += chunk; });
    child.on("error", (error) => resolve({ code: 1, output: `${output}${error.message}` }));
    child.on("close", (code) => resolve({ code, output }));
  });
}
function start(command, args, options = {}) {
  // A separate process group lets stop() end the program and every child it started.
  return spawn(command, args, { stdio: ["ignore", "pipe", "pipe"], windowsHide: true, detached: !windows, ...options });
}
function up(directory, args) {
  const result = spawnSync(process.execPath, [path.join(directory, "moorkyz"), "up", ...args], {
    cwd: directory, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], timeout: 300000,
  });
  return { code: result.status, output: `${result.stdout}${result.stderr}` };
}
function request(port, method, target) {
  return new Promise((resolve, reject) => {
    const req = http.request({ host: "127.0.0.1", port, method, path: target }, (res) => {
      let body = "";
      res.on("data", (chunk) => { body += chunk; });
      res.on("end", () => resolve({ status: res.statusCode, headers: res.headers, body }));
    });
    req.on("error", reject);
    req.end();
  });
}
async function waitFor(child, pattern, timeout = 60000) {
  let output = "";
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timed out waiting for ${pattern}:\n${output}`)), timeout);
    const read = (chunk) => {
      output += chunk;
      const match = pattern.exec(output);
      if (match) { clearTimeout(timer); resolve(match); }
    };
    child.stdout.on("data", read);
    child.stderr.on("data", read);
    child.on("close", () => { clearTimeout(timer); reject(new Error(`Exited before ${pattern}:\n${output}`)); });
  });
}
function stop(child) {
  if (child.exitCode === null) {
    if (windows) spawnSync("taskkill", ["/pid", String(child.pid), "/t", "/f"], { stdio: "ignore" });
    else try { process.kill(-child.pid, "SIGTERM"); } catch { child.kill("SIGTERM"); }
  }
}

(async () => {
  try {
    if (windows && archive !== "none") {
      // The bootstrap: refusal without consent, checksum mismatch, verified install, reuse.
      const bytes = fs.readFileSync(archive);
      const file = path.basename(archive);
      const version = /^node-v(\d+\.\d+\.\d+)-win-/.exec(file)[1];
      const sha = crypto.createHash("sha256").update(bytes).digest("hex");
      let sums = `${"0".repeat(64)}  node-v${version}-headers.tar.gz\n${sha}  ${file}\n`;
      let requests = 0;
      const mirror = http.createServer((req, res) => {
        requests++;
        const body = req.url === `/latest-v${version.split(".")[0]}.x/SHASUMS256.txt` ? Buffer.from(sums)
          : req.url === `/v${version}/${file}` ? bytes : null;
        if (!body) { res.writeHead(404); res.end(); return; }
        res.writeHead(200, { "Content-Type": "application/octet-stream", "Content-Length": body.length });
        res.end(body);
      });
      await new Promise((resolve) => mirror.listen(0, "127.0.0.1", resolve));
      try {
        const fixture = copyTemplate("bootstrap fixture");
        const appData = path.join(workspace, "local app data");
        const runtimes = path.join(appData, "Moorkyz", "runtimes");
        const env = Object.fromEntries(Object.entries(process.env).filter(([key]) => !/^path$/i.test(key)));
        const system = process.env.SystemRoot || "C:\\Windows";
        // A PATH without any Node.js, as on a fresh machine.
        env.Path = [path.join(system, "System32"), system, path.join(system, "System32", "WindowsPowerShell", "v1.0")].join(";");
        env.LOCALAPPDATA = appData;
        env.MOORKYZ_NODE_MIRROR = `http://127.0.0.1:${mirror.address().port}`;
        const runner = path.join(fixture, ".template", "run", "Run.ps1");
        const shell = (engine, args) => collect(start(engine, ["-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", runner, ...args], { cwd: workspace, env }));

        for (const engine of engines) {
          const result = await shell(engine, ["--no-start"]);
          assert.equal(result.code, 1, result.output);
          assert.match(result.output, /This project needs Node\.js 24; Node\.js was not found[\s\S]*Run RUN\.cmd in a terminal to download it, pass -Yes/);
          assert.ok(!fs.existsSync(runtimes), "Nothing may be downloaded without consent.");
        }
        sums = `${"f".repeat(64)}  ${file}\n`;
        let result = await shell(engines.at(-1), ["-Yes", "--no-start"]);
        assert.equal(result.code, 1, result.output);
        assert.match(result.output, /Checksum mismatch for .*The download was deleted; nothing was installed\./);
        assert.deepEqual(fs.existsSync(runtimes) ? fs.readdirSync(runtimes) : [], [], "A failed download must leave nothing behind.");
        sums = `${sha}  ${file}\n`;
        const launcher = path.join(fixture, "RUN.cmd");
        result = await collect(start(process.env.ComSpec || "cmd.exe", ["/d", "/s", "/c", `""${launcher}" -Yes --no-start"`],
          { cwd: workspace, env, windowsVerbatimArguments: true }));
        assert.equal(result.code, 0, result.output);
        assert.match(result.output, new RegExp(`Checksum verified; Node\\.js ${version.replaceAll(".", "\\.")} is ready\\.[\\s\\S]*Runtime +Node\\.js ${version.replaceAll(".", "\\.")}[\\s\\S]*Checks +2 passed`));
        assert.deepEqual(fs.readdirSync(runtimes), [path.basename(file, ".zip")], "Exactly the verified runtime may remain.");
        const before = requests;
        for (const engine of engines) {
          result = await shell(engine, ["-RuntimeOnly"]);
          assert.equal(result.code, 0, result.output);
          // Compare canonical paths: an 8.3 TEMP (as on GitHub's runners) may come back in its long form.
          assert.equal(fs.realpathSync.native(result.output.trim()).toLowerCase(),
            fs.realpathSync.native(path.join(runtimes, path.basename(file, ".zip"), "node.exe")).toLowerCase());
        }
        assert.equal(requests, before, "A kept runtime must be reused without downloading.");
        console.log(`PASS: RUN.cmd bootstrap refuses without consent, rejects a checksum mismatch, installs a verified runtime and reuses it (${engines.length} host(s)).`);
        groups++;
      } finally {
        mirror.close();
      }
    } else {
      console.log("[SKIP] The runtime download is Windows-only; moorkyz up is checked below.");
    }

    // up: steps repeat only when their inputs change; failures stop before anything starts.
    const site = copyTemplate("static site");
    let result = up(site, ["--no-start"]);
    assert.equal(result.code, 0, result.output);
    assert.match(result.output, /\u25cf Runtime +Node\.js[\s\S]*\u25cf Files +index\.html[\s\S]*\u25cb Packages +none declared[\s\S]*\u25cf Checks +2 passed in [\d.]+ s \u00b7 \d+ references[\s\S]*\u25cb Start +not started/);
    assert.ok(fs.existsSync(path.join(site, ".moorkyz", "website.up.json")), "The cache belongs in ignored .moorkyz/.");
    result = up(site, ["--no-start"]);
    assert.match(result.output, /\u25cb Checks +unchanged since they passed at/);
    fs.appendFileSync(path.join(site, "README.md"), "\n");
    result = up(site, ["--no-start"]);
    assert.match(result.output, /\u25cf Checks +2 passed/, "A changed file must repeat the checks.");
    result = up(site, ["--no-start", "--force"]);
    assert.match(result.output, /\u25cf Checks +2 passed/, "--force must repeat the checks.");
    groups++;

    const config = path.join(site, "moorkyz.config.json");
    const original = fs.readFileSync(config, "utf8");
    const write = (project) => fs.writeFileSync(config, JSON.stringify({ defaultProject: "website", projects: { website: project } }, null, 2));
    write({ static: ".", open: "index.html", checks: [["node", "-e", "console.log('detail'); process.exit(3)"]] });
    result = up(site, ["--no-start"]);
    assert.equal(result.code, 1, result.output);
    assert.match(result.output, /\u00d7 Checks +-e console\.log\('detail'\); process\.exit\(3\) failed \(exit 3\)\.[\s\S]*detail[\s\S]*nothing was started/);
    write({ static: ".", open: "missing.html" });
    result = up(site, ["--no-start"]);
    assert.equal(result.code, 1);
    assert.match(result.output, /\u00d7 Files +missing\.html is missing\./);
    fs.writeFileSync(config, original);
    fs.writeFileSync(path.join(site, ".node-version"), "99\n");
    result = up(site, ["--no-start"]);
    assert.equal(result.code, 1);
    assert.match(result.output, /\u00d7 Runtime +Node\.js [\d.]+ is older than the pinned 99\./);
    fs.writeFileSync(path.join(site, ".node-version"), "24\n");
    groups++;

    // A script program: no dependencies, its own check, PORT from the configured URL.
    const app = path.join(workspace, "script app");
    fs.mkdirSync(app);
    fs.copyFileSync(path.join(root, "moorkyz"), path.join(app, "moorkyz"));
    fs.writeFileSync(path.join(app, "server.js"), "require('http').createServer((q, s) => s.end('app ' + process.env.NODE_ENV)).listen(Number(process.env.PORT), '127.0.0.1');\n");
    const probe = http.createServer();
    await new Promise((resolve) => probe.listen(0, "127.0.0.1", resolve));
    const port = probe.address().port;
    await new Promise((resolve) => probe.close(resolve));
    fs.writeFileSync(path.join(app, "moorkyz.config.json"), JSON.stringify({ projects: { app: { cwd: ".", dev: "dev", url: `http://127.0.0.1:${port}` } } }));
    fs.writeFileSync(path.join(app, "package.json"), JSON.stringify({ name: "fixture-app", private: true, packageManager: "npm@11.0.0",
      scripts: { dev: "node server.js", verify: "node -e \"\"" } }));
    const managed = start(process.execPath, [path.join(app, "moorkyz"), "up", "--no-open"], { cwd: app });
    try {
      const shown = await waitFor(managed, /\u203a Start +(http:\/\/127\.0\.0\.1:\d+)/);
      assert.equal(shown[1], `http://127.0.0.1:${port}`);
      let response;
      for (let attempt = 0; attempt < 100 && !response; attempt++) {
        try { response = await request(port, "GET", "/"); } catch { await new Promise((resolve) => setTimeout(resolve, 200)); }
      }
      assert.equal(response?.body, "app development", "The dev script must run with PORT and NODE_ENV.");
    } finally {
      stop(managed);
    }
    fs.writeFileSync(path.join(app, "package.json"), JSON.stringify({ name: "fixture-app", private: true, packageManager: "npm@11.0.0",
      scripts: { dev: "node server.js" }, dependencies: { "left-pad": "1.3.0" } }));
    result = up(app, ["--no-start"]);
    assert.equal(result.code, 1, result.output);
    assert.match(result.output, /\u00d7 Packages +package-lock\.json is missing\./);
    groups++;

    // The preview server: hidden files, traversal, casing, methods and directories.
    fs.writeFileSync(path.join(site, ".env"), "SECRET=1\n");
    const server = cli.createStaticServer(site);
    await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
    try {
      const at = server.address().port;
      const page = await request(at, "GET", "/index.html");
      assert.equal(page.status, 200);
      assert.equal(page.headers["content-type"], "text/html; charset=utf-8");
      assert.equal(page.headers["cache-control"], "no-store");
      assert.equal(page.headers["x-content-type-options"], "nosniff");
      assert.equal((await request(at, "GET", "/")).status, 200);
      assert.equal((await request(at, "GET", "/website/catalog.css")).headers["content-type"], "text/css; charset=utf-8");
      for (const hidden of ["/.env", "/.template/README.md", "/%2e%2e/%2e%2e/secret.txt", "/website/..%2f.env", "/missing.html"]) {
        assert.equal((await request(at, "GET", hidden)).status, 404, hidden);
      }
      const cased = await request(at, "GET", "/INDEX.HTML");
      assert.equal(cased.status, 404, "Wrong casing must fail like a case-sensitive server.");
      if (windows) assert.match(cased.body, /case-sensitive/);
      const folder = await request(at, "GET", "/designs");
      assert.equal(folder.status, 308);
      assert.equal(folder.headers.location, "/designs/");
      assert.equal((await request(at, "GET", "/designs/")).status, 200);
      assert.equal((await request(at, "POST", "/index.html")).status, 405);
      assert.equal((await request(at, "HEAD", "/index.html")).body, "");
    } finally {
      server.close();
    }
    const busy = http.createServer();
    await new Promise((resolve) => busy.listen(0, "127.0.0.1", resolve));
    const taken = busy.address().port;
    fs.writeFileSync(config, original.replace("http://127.0.0.1:4173", `http://127.0.0.1:${taken}`));
    const preview = start(process.execPath, [path.join(site, "moorkyz"), "up", "--no-open"], { cwd: site });
    try {
      const shown = await waitFor(preview, /\u203a Start +http:\/\/127\.0\.0\.1:(\d+)\/index\.html/);
      assert.notEqual(Number(shown[1]), taken, "A busy port must not be reused.");
      assert.equal((await request(Number(shown[1]), "GET", "/index.html")).status, 200);
    } finally {
      stop(preview);
      busy.close();
    }
    groups++;
    console.log(`PASS: ${groups} run regression groups; all actions used disposable copies.`);
  } finally {
    fs.rmSync(workspace, { recursive: true, force: true });
  }
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
'@
try {
    $source | & $node - $root $archive @engines
    if ($LASTEXITCODE -ne 0) { throw "Run checkups failed with exit code $LASTEXITCODE." }
}
finally { Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue }
