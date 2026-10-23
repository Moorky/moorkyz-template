import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { documentationThemes } from "./catalog.mjs";
import { renderDocumentation } from "./documentation.mjs";

export function verifyDocumentation() {
  const fixture = fs.mkdtempSync(path.join(os.tmpdir(), "moorkyz-compact-docs-"));
  const project = path.join(fixture, "project space");
  const command = fileURLToPath(new URL("./build.mjs", import.meta.url));
  const run = (args, valid = true) => {
    const result = spawnSync(process.execPath, [command, "docs", ...args], { cwd: project, encoding: "utf8" });
    if (result.error) throw result.error;
    if (valid) assert.equal(result.status, 0, result.stdout + result.stderr);
    else assert.notEqual(result.status, 0, `Expected refusal: ${args.join(" ")}`);
    return result;
  };
  const digest = (filename) => crypto.createHash("sha256").update(fs.readFileSync(filename)).digest("hex");
  const snapshots = (folder) => {
    const result = {};
    for (const entry of fs.readdirSync(folder, { withFileTypes: true })) {
      const filename = path.join(folder, entry.name);
      result[entry.name] = entry.isDirectory() ? snapshots(filename) : entry.isSymbolicLink() ? fs.readlinkSync(filename) : digest(filename);
    }
    return result;
  };
  try {
    fs.mkdirSync(path.join(project, "guides"), { recursive: true });
    const inputs = Array.from({ length: 20 }, (_, index) => path.join("guides", `doc ${String(index + 1).padStart(2, "0")}.md`));
    inputs.forEach((input, index) => {
      const next = `doc%20${String((index + 1) % 20 + 1).padStart(2, "0")}.md`;
      fs.writeFileSync(path.join(project, input), `# Component ${index + 1}\n\nA readable reference & original content.\n\n## Usage\n\n[Next](${next}#usage) and [original notes](../notes.md?view=raw&mode=full#notes).\n\n## Usage\n\nSecond section.\n\n### Details\n\nA literal example:\n\n\`\`\`html\n<script>not executable</script>\n\`\`\`\n`);
    });
    fs.writeFileSync(path.join(project, "notes.md"), "# Notes\n\nA supporting source, not selected for rendering.\n");
    const sources = snapshots(project);
    run(["--theme", "paper", "--out", "preview", "--dry-run", ...inputs]);
    run(["--dry-run", "--out", "not-created", "missing.md"]);
    run(["--help"]);
    assert.deepEqual(snapshots(project), sources, "Help/dry-run must not read or write outputs.");
    for (const theme of documentationThemes) {
      run(["--theme", theme, "--out", theme, ...inputs]);
      const folder = path.join(project, theme, "guides");
      assert.equal(fs.readdirSync(folder).length, 20);
      for (const [index, input] of inputs.entries()) {
        const html = fs.readFileSync(path.join(project, theme, input.replace(/\.md$/, ".html")), "utf8");
        assert.match(html, new RegExp(`data-documentation-theme="${theme}"`));
        assert.match(html, new RegExp(`<h1 id="component-${index + 1}">Component ${index + 1}</h1>`));
        assert.match(html, /id="usage-2"/);
        assert.match(html, /id="details"/);
        assert.match(html, /href="doc%20\d\d\.html#usage"/);
        assert.match(html, /href="\.\.\/\.\.\/notes\.md\?view=raw&amp;mode=full#notes"/);
        assert.match(html, /&lt;script&gt;not executable&lt;\/script&gt;/);
        assert.doesNotMatch(html, /<script\b|<link\b|class="readme-hero"/);
      }
    }
    assert.deepEqual(snapshots(path.join(project, "guides")), sources.guides, "All twenty Markdown sources must remain byte-identical.");
    for (const name of ["a", "b"]) {
      fs.mkdirSync(path.join(project, name));
      fs.writeFileSync(path.join(project, name, "README.md"), `# ${name}\n\n[Other](../${name === "a" ? "b" : "a"}/README.md)\n`);
    }
    run(["--out", "same-basename", path.join("a", "README.md"), path.join("b", "README.md")]);
    for (const name of ["a", "b"]) {
      const html = fs.readFileSync(path.join(project, "same-basename", name, "README.html"), "utf8");
      assert.match(html, new RegExp(`href="../${name === "a" ? "b" : "a"}/README.html"`));
    }
    const before = snapshots(project);
    run(["--theme", "paper", "--out", "paper", "--check", ...inputs]);
    run(["--theme", "paper", "--out", "paper", ...inputs]);
    assert.deepEqual(snapshots(project), before, "Check and unchanged rerun must not change any files.");
    for (const args of [
      ["--theme", "missing", "--out", "bad", ...inputs],
      ["--out", "bad", inputs[0], "missing.md"],
      ["--out", "..", inputs[0]],
      ["--out", ".", inputs[0]],
      ["--out", "bad", inputs[0], inputs[0]],
      ["--out", "bad", "--unknown", inputs[0]],
      ["--out", "bad", "--check", "--overwrite", inputs[0]],
      ["--out", "missing-output", "--check", inputs[0]],
    ]) run(args, false);
    assert.deepEqual(snapshots(project), before, "Invalid input/check must leave every file unchanged.");
    const first = path.join(project, "paper", inputs[0].replace(/\.md$/, ".html"));
    fs.writeFileSync(first, "Existing user HTML.");
    const conflict = snapshots(project);
    run(["--out", "paper", ...inputs], false);
    run(["--out", "paper", "--check", ...inputs], false);
    assert.deepEqual(snapshots(project), conflict, "Conflict refusal must not rewrite user HTML.");
    run(["--out", "paper", "--overwrite", ...inputs]);
    assert.notEqual(fs.readFileSync(first, "utf8"), "Existing user HTML.");
    fs.writeFileSync(path.join(project, "unsafe.md"), "# Unsafe\n\n[No](javascript:alert(1))\n");
    const unsafe = snapshots(project);
    run(["--out", "new-output", inputs[0], "unsafe.md"], false);
    assert.deepEqual(snapshots(project), unsafe, "All documents must be validated before any output writes.");
    fs.mkdirSync(path.join(project, "blocked"));
    fs.writeFileSync(path.join(project, "blocked", "guides"), "Not a directory.");
    const blocked = snapshots(project);
    run(["--out", "blocked", ...inputs], false);
    assert.deepEqual(snapshots(project), blocked);
    fs.writeFileSync(path.join(project, "outside.md"), "# Outside sentinel\n");
    fs.mkdirSync(path.join(project, "linked"));
    fs.symlinkSync(path.join(project, "guides"), path.join(project, "linked", "guides"), process.platform === "win32" ? "junction" : "dir");
    const linked = snapshots(project);
    run(["--out", "linked", "--overwrite", ...inputs], false);
    run(["--out", "new-output", path.join("linked", inputs[0])], false);
    assert.deepEqual(snapshots(project), linked, "Links/junctions must not be followed for sources or output.");
    fs.mkdirSync(path.join(project, "shared", "guides"), { recursive: true });
    fs.linkSync(path.join(project, "outside.md"), path.join(project, "shared", "guides", "doc 01.html"));
    const shared = snapshots(project);
    run(["--out", "shared", "--overwrite", ...inputs], false);
    assert.deepEqual(snapshots(project), shared, "Hard-linked output must not modify another file.");
    const noTitle = renderDocumentation({ markdown: "A short note.\n", sourceName: "guide.md" });
    assert.match(noTitle, /<h1 id="guide">guide<\/h1>/);
    assert.doesNotMatch(noTitle, /class="document-outline"/);
    assert.throws(() => renderDocumentation({ markdown: "# One\n\n# Two\n" }), /one H1/);
    assert.throws(() => renderDocumentation({ markdown: "# Bad\n\n[No](data:text/html,unsafe)\n" }), /unsupported link protocol/);
    assert.throws(() => renderDocumentation({ markdown: "# Bad\n\n```js\nunclosed" }), /unclosed code fence/);
    const unicode = renderDocumentation({ markdown: "# Caf\u00e9 & tea\n\n## \u65e5\u672c\u8a9e\n\nA short note.\n" });
    assert.match(unicode, /id="\u65e5\u672c\u8a9e"/);
    assert.match(unicode, /<title>Caf\u00e9 &amp; tea<\/title>/);
    console.log("PASS: five compact themes x 20 real Markdown files = 100 self-contained HTML outputs; sources unchanged, links/anchors, no-op/check/rerun, safe refusal and explicit overwrite verified in disposable fixtures.");
  } finally {
    fs.rmSync(fixture, { recursive: true, force: true });
  }
}
