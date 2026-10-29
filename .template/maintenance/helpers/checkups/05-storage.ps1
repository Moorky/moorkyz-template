#requires -Version 5.1
[CmdletBinding()]
param([switch]$DryRun)

if ($DryRun) {
    Write-Host '[DRY RUN] Would verify archive retention and audit paths in disposable copies; no fixtures or actions created.'
    return
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$node = (Get-Command node -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$source = @'
"use strict";
const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const root = process.argv[2];
assert.equal(process.versions.node.split(".")[0], "24", "Node.js 24 LTS is required.");
const storage = require(path.join(root, "moorkyz"));
const now = Date.UTC(2026, 9, 24);
const day = 86_400_000;
const space = () => ({ available: 1_000_000_000_000, total: 2_000_000_000_000 });
const policy = (settings = {}) => storage.storagePolicy({
  minFreeBytes: 0, targetFreeBytes: 0, minFreePercent: 0, targetFreePercent: 0,
  maxArchiveAgeDays: 0, ...settings,
});
const workspace = fs.mkdtempSync(path.join(os.tmpdir(), "moorkyz storage checkups "));
let sequence = 0;
let passed = 0;
function fixture() {
  const directory = path.join(workspace, `fixture ${++sequence}`);
  fs.mkdirSync(directory);
  storage.ensureDirectories(directory);
  assert.ok(!fs.existsSync(path.join(directory, ".trash")), "Trash must not be recreated.");
  return directory;
}
async function archive(directory, days, size) {
  const input = path.join(directory, `source-${sequence++}.bin`);
  fs.writeFileSync(input, crypto.randomBytes(size));
  const result = await storage.archivePaths(directory, [input], { policy: policy() });
  assert.ok(!fs.existsSync(input));
  assert.ok(!result.retention.overLimit);
  const filename = path.join(directory, ".archive",
    storage.timestamp(new Date(now - days * day)) + ".zip");
  fs.renameSync(result.filename, filename);
  return filename;
}
function prune(directory, settings = {}, protectedPaths = [], measure = space) {
  return storage.pruneArchives(directory, policy(settings), protectedPaths, measure, now);
}
function relative(directory, filename) { return path.relative(directory, filename); }
async function check(label, action) {
  await action();
  passed++;
  console.log(`PASS: ${label}`);
}
async function main() {
  try {
    await check("validated defaults and rejected legacy/invalid settings", async () => {
      assert.equal(storage.DEFAULTS.maxArchiveBytes, 100_000_000_000);
      assert.equal(storage.DEFAULTS.maxArchiveAgeDays, 30);
      assert.equal(storage.DEFAULTS.archivePruneOrder, "oldest");
      for (const settings of [
        { maxArchiveBytes: -1 }, { maxArchiveBytes: 1.5 }, { maxArchiveBytes: Infinity },
        { maxArchiveBytes: Number.MAX_SAFE_INTEGER + 1 }, { maxArchiveBytes: "100" },
        { maxArchiveAgeDays: -1 }, { maxArchiveAgeDays: 0.5 }, { maxArchiveAgeDays: NaN },
        { archivePruneOrder: "biggest" }, { archivePruneOrder: null },
        { maxTrashBytes: 100 }, { unknown: 1 },
      ]) assert.throws(() => storage.storagePolicy(settings), /storage/i);
      assert.equal(policy({ maxArchiveBytes: 0, maxArchiveAgeDays: 0 }).maxArchiveBytes, 0);
      const directory = fixture();
      await assert.rejects(storage.maintainStorage(directory, { includeTrash: true }), /staging was removed/);
    });
    await check("exact size boundary retains archives; oldest-first prunes to the cap", async () => {
      const directory = fixture();
      const oldest = await archive(directory, 2, 100);
      const newest = await archive(directory, 1, 300);
      const total = fs.statSync(oldest).size + fs.statSync(newest).size;
      assert.deepEqual(prune(directory, { maxArchiveBytes: total }).removed, []);
      const result = prune(directory, { maxArchiveBytes: total - 1 });
      assert.deepEqual(result.removed, [relative(directory, oldest)]);
      assert.equal(result.bytes, fs.statSync(newest).size);
      assert.equal(result.overLimit, false);
    });
    await check("largest-first differs from oldest-first; ties use oldest filename", async () => {
      const directory = fixture();
      const oldest = await archive(directory, 3, 100);
      const largest = await archive(directory, 2, 800);
      const newest = await archive(directory, 1, 100);
      const total = [oldest, largest, newest].reduce((sum, file) => sum + fs.statSync(file).size, 0);
      assert.deepEqual(prune(directory, {
        maxArchiveBytes: total - 1, archivePruneOrder: "largest",
      }).removed, [relative(directory, largest)]);
      const tie = path.join(directory, ".archive", storage.timestamp(new Date(now)) + ".zip");
      fs.copyFileSync(oldest, tie);
      // Make all candidates the same size so timestamp is the only tie breaker.
      fs.copyFileSync(oldest, newest);
      const equalTotal = fs.statSync(oldest).size * 3;
      assert.deepEqual(prune(directory, {
        maxArchiveBytes: equalTotal - 1, archivePruneOrder: "largest",
      }).removed, [relative(directory, oldest)]);
    });
    await check("age boundary, UTC creation age, disabled expiry and expiry before size ordering", async () => {
      const directory = fixture();
      const expired = await archive(directory, 31, 100);
      const boundary = await archive(directory, 30, 800);
      const fresh = await archive(directory, 1, 100);
      fs.utimesSync(expired, new Date(), new Date());
      assert.deepEqual(prune(directory).removed, []);
      const total = [expired, boundary, fresh].reduce((sum, file) => sum + fs.statSync(file).size, 0);
      const result = prune(directory, {
        maxArchiveAgeDays: 30, archivePruneOrder: "largest",
        maxArchiveBytes: total - fs.statSync(expired).size,
      });
      assert.deepEqual(result.removed, [relative(directory, expired)]);
      assert.ok(fs.existsSync(boundary));
      assert.equal(result.expiredRemaining, 0);
    });
    await check("protected paths/live leases count toward limits and survive cleanup", async () => {
      const directory = fixture();
      const protectedFile = await archive(directory, 32, 100);
      const leased = await archive(directory, 31, 100);
      const leases = path.join(directory, ".moorkyz", "archive-leases");
      fs.mkdirSync(leases, { recursive: true });
      fs.writeFileSync(path.join(leases, path.basename(leased) + ".json"),
        JSON.stringify({ pid: process.pid, archive: path.basename(leased) }));
      const result = prune(directory, { maxArchiveBytes: 0, maxArchiveAgeDays: 30 }, [protectedFile]);
      assert.deepEqual(result.removed, []);
      assert.equal(result.overLimit, true);
      assert.equal(result.expiredRemaining, 2);
      assert.equal(result.bytes, fs.statSync(protectedFile).size + fs.statSync(leased).size);
    });
    await check("non-ZIP, unmanaged files, directories and junctions are not deleted", async () => {
      const directory = fixture();
      const fake = path.join(directory, ".archive", storage.timestamp(new Date(now - 31 * day)) + ".zip");
      fs.writeFileSync(fake, "not a ZIP");
      const unmanaged = path.join(directory, ".archive", "keep.zip");
      fs.writeFileSync(unmanaged, "user-owned");
      const outside = path.join(workspace, `outside ${sequence++}`);
      fs.mkdirSync(outside);
      fs.writeFileSync(path.join(outside, "sentinel"), "keep");
      const linked = path.join(directory, ".archive", storage.timestamp(new Date(now - 32 * day)) + ".zip");
      fs.symlinkSync(outside, linked, process.platform === "win32" ? "junction" : "dir");
      const result = prune(directory, { maxArchiveBytes: 0, maxArchiveAgeDays: 30 });
      assert.deepEqual(result.removed, []);
      assert.equal(result.overLimit, true);
      assert.equal(result.expiredRemaining, 1);
      assert.equal(fs.readFileSync(unmanaged, "utf8"), "user-owned");
      assert.equal(fs.readFileSync(path.join(outside, "sentinel"), "utf8"), "keep");
      if (process.platform === "win32") fs.rmdirSync(linked);
      else fs.unlinkSync(linked);
    });
    await check("disk-space safeguard honors chosen order and stops at its target", async () => {
      const directory = fixture();
      const oldest = await archive(directory, 2, 100);
      const largest = await archive(directory, 1, 800);
      const result = prune(directory, {
        minFreeBytes: 1, targetFreeBytes: 10, archivePruneOrder: "largest",
      }, [], () => ({ available: fs.existsSync(largest) ? 0 : 10, total: 100 }));
      assert.deepEqual(result.removed, [relative(directory, largest)]);
      assert.equal(result.lowSpace, false);
      assert.ok(fs.existsSync(oldest));
    });
    await check("new archive survives its creation pass; subsequent maintenance enforces zero cap", async () => {
      const directory = fixture();
      const source = path.join(directory, "payload");
      fs.writeFileSync(source, "recoverable source");
      const result = await storage.archivePaths(directory, [source], { policy: policy({ maxArchiveBytes: 0 }) });
      assert.ok(fs.existsSync(result.filename));
      assert.ok(!fs.existsSync(source));
      assert.equal(result.retention.overLimit, true);
      const maintained = await storage.maintainStorage(directory, { policy: policy({ maxArchiveBytes: 0 }) });
      assert.equal(maintained.pruned.bytes, 0);
      assert.equal(maintained.pruned.overLimit, false);
      assert.ok(!fs.existsSync(result.filename));
      assert.ok(!fs.existsSync(path.join(directory, ".trash")));
    });
    await check("log rotation archives malformed/excess logs and preserves live log leases", async () => {
      const directory = fixture();
      const oldest = path.join(directory, ".logs", storage.timestamp(new Date(now - day)) + ".log");
      const active = path.join(directory, ".logs", storage.timestamp(new Date(now)) + ".log");
      const malformed = path.join(directory, ".logs", "malformed.log");
      for (const filename of [oldest, active, malformed]) fs.writeFileSync(filename, "log data");
      const release = storage.registerLog(directory, active);
      try {
        const result = await storage.maintainStorage(directory, { policy: policy({ maxLogs: 1 }) });
        assert.equal(result.archived.length, 1);
        assert.ok(fs.existsSync(result.archived[0].filename));
        assert.ok(!fs.existsSync(oldest));
        assert.ok(!fs.existsSync(malformed));
        assert.equal(fs.readFileSync(active, "utf8"), "log data");
      } finally { release(); }
    });
    await check("CLI audit uses .audits and docs/AUDIT_TEMPLATE.md; errors and no-op mode stay explicit", async () => {
      const directory = fixture();
      fs.mkdirSync(path.join(directory, "docs"));
      fs.copyFileSync(path.join(root, "docs", "AUDIT_TEMPLATE.md"), path.join(directory, "docs", "AUDIT_TEMPLATE.md"));
      const invoke = (args) => {
        const result = spawnSync(process.execPath, [path.join(root, "moorkyz"), ...args], {
          cwd: directory, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], timeout: 10000,
        });
        if (result.error) throw result.error;
        return result;
      };
      const created = invoke(["audit", "Fixture audit"]);
      assert.equal(created.status, 0, created.stderr);
      const reports = fs.readdirSync(path.join(directory, ".audits"));
      assert.equal(reports.length, 1);
      assert.match(fs.readFileSync(path.join(directory, ".audits", reports[0]), "utf8"), /^# Fixture audit/);
      assert.ok(!fs.existsSync(path.join(directory, "audits")));
      assert.ok(!fs.existsSync(path.join(directory, "docs", "audits")));
      fs.unlinkSync(path.join(directory, "docs", "AUDIT_TEMPLATE.md"));
      const missing = invoke(["audit", "Missing template"]);
      assert.notEqual(missing.status, 0);
      assert.match(missing.stderr, /docs[/\\]AUDIT_TEMPLATE\.md/);
      const dryRun = invoke(["maintain", "--dry-run"]);
      assert.equal(dryRun.status, 0, dryRun.stderr);
      assert.ok(!fs.existsSync(path.join(directory, ".trash")));
      fs.writeFileSync(path.join(directory, "moorkyz.config.json"), JSON.stringify({
        storage: { maxArchiveBytes: 0, maxArchiveAgeDays: 0, minFreeBytes: 0,
          targetFreeBytes: 0, minFreePercent: 0, targetFreePercent: 0 },
      }));
      fs.writeFileSync(path.join(directory, "payload"), "CLI archive source");
      const archived = invoke(["archive", "payload"]);
      assert.equal(archived.status, 0, archived.stderr);
      assert.match(archived.stderr, /above storage\.maxArchiveBytes/);
      assert.ok(!fs.existsSync(path.join(directory, "payload")));
      assert.equal(fs.readdirSync(path.join(directory, ".archive")).length, 1);
      const maintained = invoke(["maintain"]);
      assert.equal(maintained.status, 0, maintained.stderr);
      assert.match(maintained.stdout, /0 managed archive bytes remain/);
      const blocked = path.join(directory, ".archive",
        storage.timestamp(new Date(Date.now() - 2 * day)) + ".zip");
      fs.writeFileSync(blocked, "not a ZIP");
      fs.writeFileSync(path.join(directory, "moorkyz.config.json"), JSON.stringify({
        storage: { maxArchiveBytes: 0, maxArchiveAgeDays: 1, minFreeBytes: 0,
          targetFreeBytes: 0, minFreePercent: 0, targetFreePercent: 0 },
      }));
      const warning = invoke(["maintain"]);
      assert.equal(warning.status, 0, warning.stderr);
      assert.match(warning.stderr, /expired archive\(s\) could not be pruned/);
      assert.match(warning.stderr, /above storage\.maxArchiveBytes/);
      assert.ok(fs.existsSync(blocked));
    });
    console.log(`PASS: ${passed} storage/audit regression groups; all actions used disposable fixtures.`);
  } finally {
    fs.rmSync(workspace, { recursive: true });
  }
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
'@

$source | & $node - $root
if ($LASTEXITCODE -ne 0) { throw 'Storage/audit regression check failed.' }
