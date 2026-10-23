import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { createRequire } from "node:module";
import { designs } from "./catalog.mjs";

const directory = path.dirname(fileURLToPath(import.meta.url));
const root = path.dirname(directory);
assert.equal(process.versions.node.split(".")[0], "24", "Use Node.js 24 LTS.");
const freshness = spawnSync(process.execPath, [path.join(directory, "build.mjs"), "--check"], { encoding: "utf8" });
if (freshness.error) throw freshness.error;
assert.equal(freshness.status, 0, freshness.stdout + freshness.stderr);
assert.equal(designs.length, 20);
assert.equal(new Set(designs.map((d) => d.art)).size, 20, "Artwork must be unique per direction.");
assert.equal(new Set(designs.map((d) => d.title)).size, 20, "Each landing needs its own editorial direction.");
assert.equal(new Set(designs.map((d) => d.description)).size, 20);
const files = fs.readdirSync(directory, { withFileTypes: true }).filter((entry) => /^\d\d-/.test(entry.name));
assert.deepEqual(files.map((entry) => entry.name).sort(), designs.map((d) => d.id).sort());
const pages = [path.join(directory, "index.html")];
const landingHashes = new Set();
const readmeHashes = new Set();
const css = fs.readFileSync(path.join(directory, "assets", "designs.css"), "utf8");
const rootReadme = fs.readFileSync(path.join(root, "README.md"), "utf8");
const { renderReadme } = createRequire(import.meta.url)("../moorkyz");
const canonicalBody = renderReadme(rootReadme).match(/<main>([\s\S]*?)<\/main>/)[1].replace(/<h1>[\s\S]*?<\/h1>/, "");
const plainText = (html) => html.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim();
const chapterTitles = [...rootReadme.matchAll(/^## (.+)$/gm)].map((match) => match[1]);
const slug = (value) => value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
const hash = (value) => crypto.createHash("sha256").update(value).digest("hex");
function luminance(hex) {
  const channels = hex.slice(1).match(/../g).map((value) => parseInt(value, 16) / 255)
    .map((value) => value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4);
  return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722;
}
function contrast(a, b) {
  const values = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (values[0] + 0.05) / (values[1] + 0.05);
}
for (const d of designs) {
  const folder = path.join(directory, d.id);
  assert.deepEqual(fs.readdirSync(folder).sort(), ["README.html", "landing.html"]);
  for (const name of ["README.html", "landing.html"]) pages.push(path.join(folder, name));
  const readme = fs.readFileSync(path.join(folder, "README.html"), "utf8");
  const landing = fs.readFileSync(path.join(folder, "landing.html"), "utf8");
  readmeHashes.add(hash(readme));
  landingHashes.add(hash(landing));
  for (const title of chapterTitles) assert.ok(readme.includes(`id="${slug(title)}"`), `${d.name}: missing chapter ${title}`);
  const article = readme.match(/<article class="doc-body"[^>]*>([\s\S]*?)<\/article>/)[1]
    .replace(/<span class="chapter-number"[^>]*>\d+<\/span>/g, "");
  assert.equal(plainText(article), plainText(canonicalBody), `${d.name}: README text must be complete and unchanged.`);
  assert.doesNotMatch(readme.match(/<nav aria-label="Adjacent designs">([\s\S]*?)<\/nav>/)[1], /landing\.html/);
  assert.doesNotMatch(landing.match(/<nav aria-label="Adjacent designs">([\s\S]*?)<\/nav>/)[1], /README\.html/);
  assert.ok(readme.includes("node moorkyz help"), `${d.name}: README content is missing.`);
  assert.match(readme, /aria-label="Complete README"/);
  assert.ok(css.includes(`.${d.id.slice(3)} .hero`), `${d.name}: missing individual layout treatment.`);
  assert.ok(css.includes(`.art-${d.art}`) || landing.includes(`class="art art-${d.art}"`), `${d.name}: missing artwork.`);
  for (const color of ["bg", "surface", "ink", "muted", "accent", "warm"]) assert.match(d[color], /^#[0-9a-f]{6}$/i);
  for (const [foreground, background] of [["ink", "bg"], ["muted", "bg"], ["accent", "bg"], ["ink", "surface"], ["muted", "surface"]]) {
    const ratio = contrast(d[foreground], d[background]);
    assert.ok(ratio >= 4.5, `${d.name}: ${foreground}/${background} contrast ${ratio.toFixed(2)} is below 4.5:1.`);
  }
}
assert.equal(pages.length, 41);
assert.equal(landingHashes.size, 20);
assert.equal(readmeHashes.size, 20);
const htmlFiles = [];
function collect(folder) {
  for (const entry of fs.readdirSync(folder, { withFileTypes: true })) {
    const filename = path.join(folder, entry.name);
    assert.ok(!entry.isSymbolicLink(), `Refusing design link: ${filename}`);
    if (entry.isDirectory()) collect(filename);
    else if (entry.name.endsWith(".html")) htmlFiles.push(filename);
  }
}
collect(directory);
assert.deepEqual(htmlFiles.sort(), pages.sort(), "Unexpected or missing HTML pages.");
function exactPath(filename) {
  const relative = path.relative(root, filename);
  assert.ok(relative !== ".." && !relative.startsWith(`..${path.sep}`) && !path.isAbsolute(relative), `Link outside repository: ${filename}`);
  let current = root;
  for (const part of relative.split(path.sep)) {
    assert.ok(fs.readdirSync(current).includes(part), `Missing or incorrectly cased path: ${filename}`);
    current = path.join(current, part);
  }
}
let links = 0;
for (const filename of pages) {
  const html = fs.readFileSync(filename, "utf8");
  assert.match(html, /^<!doctype html>/);
  assert.match(html, /<html lang="en">/);
  assert.match(html, /name="viewport"/);
  assert.equal([...html.matchAll(/<h1(?:\s|>)/g)].length, 1, `${filename}: require one H1.`);
  assert.equal([...html.matchAll(/<main(?:\s|>)/g)].length, 1, `${filename}: require one main.`);
  assert.ok(html.includes('class="skip-link" href="#main"'));
  assert.doesNotMatch(html, /\son(?:click|load|error|mouseover)=/i, "Keep behavior in reviewed local scripts.");
  const ids = [...html.matchAll(/\bid="([^"]+)"/g)].map((match) => match[1]);
  assert.equal(ids.length, new Set(ids).size, `${filename}: duplicate IDs.`);
  for (const match of html.matchAll(/\b(href|src)="([^"]+)"/g)) {
    const [, attribute, target] = match;
    if (/^[a-z][a-z0-9+.-]*:/i.test(target)) {
      assert.equal(attribute, "href", `${filename}: assets must not require external requests.`);
      assert.match(target, /^https:/);
      continue;
    }
    assert.ok(!target.startsWith("//"), "No protocol-relative resources.");
    const [local, fragment] = target.split("#");
    const destination = local ? path.resolve(path.dirname(filename), decodeURIComponent(local)) : filename;
    exactPath(destination);
    if (fragment && destination.endsWith(".html") && destination.startsWith(directory + path.sep)) {
      const content = destination === filename ? html : fs.readFileSync(destination, "utf8");
      assert.ok(content.includes(`id="${fragment}"`), `${filename}: broken anchor ${target}`);
    }
    links++;
  }
}
for (const name of ["designs.css", "showcase.css"]) {
  const source = fs.readFileSync(path.join(directory, "assets", name), "utf8");
  assert.doesNotMatch(source, /@import|url\(/, "Styles must not fetch external assets.");
  assert.match(source, /@media\(max-width:760px\)/);
}
assert.match(css, /prefers-reduced-motion:reduce/);
for (const name of ["interactions.js", "showcase.js"]) {
  const filename = path.join(directory, "assets", name);
  const source = fs.readFileSync(filename, "utf8");
  assert.doesNotMatch(source, /\bfetch\s*\(|XMLHttpRequest|localStorage|sessionStorage|innerHTML|eval\s*\(/);
  const syntax = spawnSync(process.execPath, ["--check", filename], { encoding: "utf8" });
  if (syntax.error) throw syntax.error;
  assert.equal(syntax.status, 0, syntax.stderr);
}
const showcase = fs.readFileSync(path.join(directory, "index.html"), "utf8");
assert.equal([...showcase.matchAll(/class="collection-card"/g)].length, 20);
for (const copy of [
  showcase.match(/<p class="showcase-description">([\s\S]*?)<\/p>/)[1],
  showcase.match(/<div class="collection-heading">[\s\S]*?<p>([\s\S]*?)<\/p>/)[1],
]) assert.doesNotMatch(copy, /<br>(?=\S)/, "Responsive line breaks need whitespace when hidden.");
assert.match(showcase, /20<span> \/<\/span>/);
assert.match(showcase, /40<span> \+ 1<\/span>/);
assert.equal(fs.readdirSync(path.join(root, ".template", "project-types", "helpers", "types"), { withFileTypes: true }).filter((entry) => entry.isDirectory()).length, 9);
console.log(`PASS: exactly 20 unique README editions, 20 unique landings and one showcase; ${links} local links/assets checked.`);
console.log(`PASS: ${chapterTitles.length} complete chapters per README, semantic landmarks, all 100 palette contrast pairs >= 4.5:1.`);
console.log("PASS: generated freshness, reduced-motion/mobile styles, local-only assets and dependency-free script syntax.");
