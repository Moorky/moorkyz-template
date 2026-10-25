import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, readFileSync, readdirSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { buildSite } from "./build.mjs";

const commit = "a".repeat(40);

function fixture(t) {
  const root = mkdtempSync(join(tmpdir(), "moorkyz-template-deploy-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  for (const folder of ["website", "website/deploy", "designs", ".git", ".moorkyz"]) mkdirSync(join(root, folder), { recursive: true });
  writeFileSync(join(root, "index.html"), '<a href="website/viewer.html" data-href="do-not-rewrite.md">View</a><a href="README.md#start">Docs</a><a href="moorkyz">CLI</a>');
  writeFileSync(join(root, "website", "viewer.html"), '<script src="viewer.js"></script><a href="../">Home</a>');
  writeFileSync(join(root, "website", "viewer.js"), '"use strict";');
  writeFileSync(join(root, "website", "build.mjs"), "private build source");
  writeFileSync(join(root, "website", "deploy", "secret.js"), "must not be published");
  writeFileSync(join(root, "designs", "README.md"), "repository documentation");
  writeFileSync(join(root, ".env"), "DISPOSABLE_FIXTURE=not-a-real-secret");
  writeFileSync(join(root, ".git", "config"), "fixture metadata");
  return { root, output: join(root, "dist"), commit };
}

test("packages only public files and preserves site navigation", (t) => {
  const options = fixture(t);
  const { files, rewritten } = buildSite(options);
  assert.deepEqual([...files].sort(), ["index.html", "website/viewer.html", "website/viewer.js"]);
  assert.equal(rewritten, 2);
  assert.deepEqual(readdirSync(options.output).sort(), ["index.html", "version.json", "website"]);
  assert.deepEqual(readdirSync(join(options.output, "website")).sort(), ["viewer.html", "viewer.js"]);
  assert.equal(JSON.parse(readFileSync(join(options.output, "version.json"))).commit, commit);
  assert.match(readFileSync(join(options.output, "index.html"), "utf8"), new RegExp(`blob/${commit}/README.md#start`));
  assert.match(readFileSync(join(options.output, "index.html"), "utf8"), new RegExp(`blob/${commit}/moorkyz`));
  assert.match(readFileSync(join(options.output, "index.html"), "utf8"), /data-href="do-not-rewrite.md"/);
  assert.match(readFileSync(join(options.output, "website", "viewer.html"), "utf8"), /href="\.\.\/"/);
  assert.throws(() => buildSite(options), /new or empty directory/);
});

test("refuses missing commit identity and missing public assets", (t) => {
  const options = fixture(t);
  assert.throws(() => buildSite({ ...options, commit: "master" }), /40-character/);
  writeFileSync(join(options.root, "index.html"), '<script src="missing.js"></script>');
  assert.throws(() => buildSite(options), /Unpublished asset/);
  writeFileSync(join(options.root, "index.html"), '<a href="missing.html">Missing</a>');
  assert.throws(() => buildSite(options), /Unpublished page/);
});

test("refuses symbolic links in the public source", { skip: process.platform === "win32" ? "Windows symlink creation requires privileges; exercised by Linux CI." : false }, (t) => {
  const options = fixture(t);
  symlinkSync(join(options.root, ".env"), join(options.root, "designs", "leak.js"));
  assert.throws(() => buildSite(options), /symbolic links/);
});
