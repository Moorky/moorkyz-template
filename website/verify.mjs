import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import vm from "node:vm";
import { createRequire } from "node:module";
import { designs, documentationThemes } from "../designs/catalog.mjs";
import { renderWebsite, renderViewer } from "./build.mjs";

const root = fileURLToPath(new URL("../", import.meta.url));
const file = resolve(root, "index.html");
const html = readFileSync(file, "utf8");
assert.equal(html, renderWebsite(), "Root catalog is stale: run node website\\build.mjs");
assert.equal((html.match(/class="template-card"/g) || []).length, designs.length);
assert.equal((html.match(/data-kind="/g) || []).length, designs.length * 2);
assert.equal((html.match(/class="compact-tag"/g) || []).length, documentationThemes.length);
assert.ok(!/impressum|privacy|terms of|href="[^"]*(?:legal|datenschutz)/i.test(html));
assert.ok(html.includes('class="catalog-controls" hidden'), "No-JS mode must hide inactive controls");
assert.ok(html.includes('role="status" aria-live="polite"'));
assert.ok(html.includes("made /w"));
assert.match(html, /<footer\b[^>]*>[\s\S]*<a href="https:\/\/moorky\.com">moorky\.com <span aria-hidden="true">&#8599;<\/span><\/a>[\s\S]*<\/footer>/,
  "The catalog footer must retain the owner-requested moorky.com link.");
for (const design of designs) {
  for (const page of ["README.html", "landing.html"]) {
    assert.ok(html.includes(`href="designs/${design.id}/${page}"`), `Missing ${design.id}/${page}`);
  }
}

let localLinks = 0;
for (const match of html.matchAll(/\s(?:href|src)="([^"]+)"/g)) {
  const value = match[1];
  if (/^(?:https:|data:)/.test(value)) continue;
  const [relative, anchor] = value.split("#");
  const target = relative ? resolve(dirname(file), relative) : file;
  assert.ok(existsSync(target), `Broken local link: ${value}`);
  if (anchor) assert.ok(readFileSync(target, "utf8").includes(`id="${anchor}"`), `Missing anchor: ${value}`);
  localLinks += 1;
}

const script = readFileSync(new URL("./catalog.js", import.meta.url), "utf8");
const handlers = new Map();
const buttons = ["all", "readme", "landing"].map((kind) => ({
  dataset: { viewFilter: kind },
  pressed: undefined,
  setAttribute(name, value) { assert.equal(name, "aria-pressed"); this.pressed = value; },
  addEventListener(name, callback) { handlers.set(`${kind}:${name}`, callback); },
}));
const cards = designs.map((design) => ({ dataset: { style: design.category }, hidden: false }));
const controls = { hidden: true };
const filter = {
  value: "all",
  addEventListener(name, callback) { handlers.set(`style:${name}`, callback); },
};
const status = { textContent: "" };
const year = { textContent: "" };
const body = { dataset: { view: "all" } };
const viewerLinks = designs.flatMap((design) => ["readme", "landing"].map((kind) => ({
  dataset: { viewerHref: `website/viewer.html?template=${design.id}&kind=${kind}` },
})));
const elements = { ".catalog-controls": controls, "#style-filter": filter, "#result-count": status, "[data-year]": year };
vm.runInNewContext(script, {
  document: {
    body,
    querySelector(selector) { assert.ok(selector in elements, `Unexpected selector ${selector}`); return elements[selector]; },
    querySelectorAll(selector) {
      if (selector === "[data-view-filter]") return buttons;
      if (selector === "[data-viewer-href]") return viewerLinks;
      assert.equal(selector, ".template-card");
      return cards;
    },
  },
});
assert.equal(controls.hidden, false);
assert.equal(year.textContent, new Date().getFullYear());
for (const link of viewerLinks) assert.equal(link.href, link.dataset.viewerHref);
let combinations = 0;
for (const view of ["all", "readme", "landing"]) {
  handlers.get(`${view}:click`)();
  assert.equal(body.dataset.view, view);
  buttons.forEach((button) => assert.equal(button.pressed, String(button.dataset.viewFilter === view)));
  for (const style of ["all", ...new Set(designs.map((design) => design.category))]) {
    filter.value = style;
    handlers.get("style:change")();
    const count = designs.filter((design) => style === "all" || design.category === style).length;
    cards.forEach((card) => assert.equal(card.hidden, style !== "all" && card.dataset.style !== style));
    assert.equal(cards.filter((card) => !card.hidden).length, count);
    assert.equal(status.textContent, view === "all" ? `${count} designs / ${count * 2} templates` : `${count} ${view === "readme" ? "README" : "Landing"} templates`);
    combinations += 1;
  }
}

console.log(`PASS: fresh static catalog; ${designs.length} designs / ${designs.length * 2} templates; ${localLinks} local links and anchors; ${combinations} type/style combinations; no-JS controls, compact badges and Moorkyz footer.`);

const viewer = readFileSync(new URL("./viewer.html", import.meta.url), "utf8");
assert.equal(viewer, renderViewer(), "Template viewer is stale: run node website\\build.mjs");
assert.equal([...viewer.matchAll(/class="viewer-entry"/g)].length, 40);
assert.equal([...viewer.matchAll(/<iframe\b/g)].length, 1);
assert.match(viewer, /id="full-view"[^>]*target="_blank" rel="noopener"/);
assert.match(viewer, /id="viewer-error" role="alert" hidden/);
for (const match of viewer.matchAll(/\s(?:href|src)="([^"]+)"/g)) {
  const [relative, anchor] = match[1].split("#");
  const target = relative ? resolve(root, "website", relative) : resolve(root, "website", "viewer.html");
  assert.ok(existsSync(target), `Broken viewer link: ${match[1]}`);
  if (anchor) assert.ok(readFileSync(target, "utf8").includes(`id="${anchor}"`));
}
const viewerCss = readFileSync(new URL("./viewer.css", import.meta.url), "utf8");
assert.match(viewerCss, /grid-template-columns: 300px minmax\(0, 1fr\)/);
assert.match(viewerCss, /height: 100dvh/);
assert.match(viewerCss, /@media \(max-width: 900px\)[\s\S]*\.viewer-sidebar \{ display: none; \}/);
const viewerScript = readFileSync(new URL("./viewer.js", import.meta.url), "utf8");
assert.doesNotMatch(viewerScript, /\bfetch\s*\(|XMLHttpRequest|localStorage|sessionStorage|innerHTML|eval\s*\(/);

function element(dataset = {}, attributes = {}) {
  const events = new Map();
  return {
    dataset, attributes, events, hidden: false, value: "", textContent: "",
    addEventListener(name, handler) { events.set(name, handler); },
    setAttribute(name, value) { attributes[name] = value; },
    getAttribute(name) { return attributes[name] ?? null; },
    hasAttribute(name) { return name in attributes; },
    removeAttribute(name) { delete attributes[name]; },
    get href() { return attributes.href ? new URL(attributes.href, "https://fixture.test/website/viewer.html").href : ""; },
    set href(value) { attributes.href = value; },
    get src() { return attributes.src; },
    set src(value) { attributes.src = value; },
    scrollIntoView() {},
    focus() { this.focused = true; },
  };
}
const items = designs.flatMap((design) => ["landing", "readme"].map((kind) => element({
  template: design.id, name: design.name, kind,
  url: `viewer.html?template=${design.id}&kind=${kind}`,
  src: `../designs/${design.id}/${kind === "readme" ? "README" : "landing"}.html`,
  search: `${design.name} ${design.category} ${design.note} ${kind}`,
})));
const search = element();
const selector = element();
selector.value = "all";
const typeFilter = element();
const summary = element();
typeFilter.querySelector = (value) => { assert.equal(value, "summary"); return summary; };
const radios = ["all", "landing", "readme"].map((value) => Object.assign(element(), { value }));
const frame = element();
const heading = element();
const fullView = element();
const error = element();
const previous = element();
const next = element();
const entryCount = element();
const empty = element();
const viewerControls = element();
viewerControls.hidden = true;
const media = element();
media.matches = false;
const events = new Map();
const location = { href: "https://fixture.test/website/viewer.html", search: "" };
const history = { pushState(_state, _title, url) { location.href = new URL(url, location.href).href; location.search = new URL(location.href).search; } };
const lookup = {
  "#viewer-search": search, "#template-selector": selector, ".type-filter": typeFilter,
  "#entry-count": entryCount, ".empty-list": empty, "#template-frame": frame,
  "#viewer-heading": heading, "#full-view": fullView, "#viewer-error": error,
  "#previous-template": previous, "#next-template": next, ".viewer-controls": viewerControls,
};
const document = {
  title: "",
  querySelector(value) { assert.ok(value in lookup, `Unexpected viewer selector ${value}`); return lookup[value]; },
  querySelectorAll(value) {
    if (value === ".viewer-entry") return items;
    assert.equal(value, "[name=page-type]");
    return radios;
  },
};
vm.runInNewContext(viewerScript, {
  document, location, history, URL, URLSearchParams,
  MoorkyzPredictiveSearch: createRequire(import.meta.url)("../designs/assets/predictive-search.js"),
  matchMedia(query) { assert.equal(query, "(max-width: 900px)"); return media; },
  window: { addEventListener(name, handler) { events.set(name, handler); } },
});
function click(item, extras = {}) {
  let prevented = false;
  item.events.get("click")({ button: 0, preventDefault() { prevented = true; }, ...extras });
  return prevented;
}
assert.equal(viewerControls.hidden, false);
assert.equal(frame.src, items[0].dataset.src);
assert.equal(entryCount.textContent, "40 entries");
for (const item of items) {
  assert.ok(click(item));
  assert.equal(frame.src, item.dataset.src);
  assert.equal(fullView.attributes.href, item.dataset.src);
  assert.equal(item.getAttribute("aria-current"), "page");
  assert.equal(items.filter((entry) => entry.hasAttribute("aria-current")).length, 1);
  assert.equal(location.search, `?template=${item.dataset.template}&kind=${item.dataset.kind}`);
}
click(next);
assert.equal(frame.src, items[0].dataset.src, "Next wraps to the beginning.");
click(previous);
assert.equal(frame.src, items.at(-1).dataset.src, "Previous wraps to the end.");
const before = frame.src;
assert.equal(click(items[0], { ctrlKey: true }), false, "Modified clicks keep native link behavior.");
assert.equal(frame.src, before);
for (const radio of radios) {
  radio.events.get("change")();
  assert.equal(entryCount.textContent, radio.value === "all" ? "40 entries" : "20 entries");
}
selector.value = designs[1].id;
selector.events.get("change")();
assert.equal(entryCount.textContent, "1 entry");
search.value = "no-such-template";
search.events.get("input")();
assert.equal(entryCount.textContent, "0 entries");
assert.equal(empty.hidden, false);
assert.equal(next.hasAttribute("href"), false);
assert.equal(previous.getAttribute("aria-disabled"), "true");
assert.equal(frame.src, before, "Filtering must not replace the selected preview.");
media.matches = true;
media.events.get("change")();
assert.equal(entryCount.textContent, "40 entries", "Mobile browses the whole collection.");
media.matches = false;
media.events.get("change")();
assert.equal(entryCount.textContent, "0 entries", "Desktop filters survive resizing.");
search.value = "PÁPER";
search.events.get("input")();
assert.equal(entryCount.textContent, "1 entry", "Search normalization reuses the shared helper.");
location.search = "?template=02-paper&kind=readme";
events.get("popstate")();
assert.equal(frame.src, items[3].dataset.src);
for (const query of [
  "?template=../../secret&kind=landing",
  "?template=https://example.com&kind=landing",
  "?template=01-aether&kind=unknown",
  "?template=&kind=readme",
]) {
  location.search = query;
  events.get("popstate")();
  assert.equal(error.hidden, false);
  assert.equal(frame.hasAttribute("src"), false);
  assert.equal(fullView.hasAttribute("href"), false);
}
click(items[2]);
assert.equal(error.hidden, true, "Selecting a known entry recovers from a bad URL.");
assert.equal(frame.src, items[2].dataset.src);
console.log("PASS: fresh viewer; 40 selections and Full View destinations; previous/next wrap, URL/history, combined filters, empty states, mobile resize, normalized search, modified clicks and four invalid-link refusals.");
