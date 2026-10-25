import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
import { designs, documentationThemes } from "./catalog.mjs";
import { renderDocumentation, exportDocuments } from "./documentation.mjs";
import { searchBox, searchHead, searchIndex } from "./search.mjs";

const directory = path.dirname(fileURLToPath(import.meta.url));
const root = path.dirname(directory);
const require = createRequire(import.meta.url);
const { renderReadme } = require("../moorkyz");
const args = process.argv.slice(2);
if (args[0] === "docs") {
  exportDocuments(args.slice(1));
  process.exit(0);
}
if (args.some((arg) => !["--check", "--dry-run"].includes(arg))) {
  throw new Error("Usage: node designs/build.mjs [--check | --dry-run]");
}
if (args.includes("--dry-run")) {
  console.log("Dry run: would generate 20 README editions, 20 landing pages, the showcase and the search index. No files read or written.");
  process.exit(0);
}

const escape = (value) => String(value).replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");
const slug = (value) => value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
const variables = (d) => `--bg:${d.bg};--surface:${d.surface};--ink:${d.ink};--muted:${d.muted};--accent:${d.accent};--warm:${d.warm}`;
const marker = '<span class="brand-mark" aria-hidden="true"><i></i><i></i><i></i></span>';
const arrow = '<span aria-hidden="true">&#8599;</span>';
const rootLink = "../../";
const readme = fs.readFileSync(path.join(root, "README.md"), "utf8");
const match = renderReadme(readme).match(/<main>([\s\S]*?)<\/main>/);
if (!match) throw new Error("README renderer did not return its expected main content.");
const readmeContent = match[1].replace(/<h1>[\s\S]*?<\/h1>/, "").replace(/href="([^"]+)"/g, (_, href) =>
  `href="${/^(?:[a-z][a-z0-9+.-]*:|#|\/)/i.test(href) ? href : rootLink + href}"`);
const sections = readmeContent.trim().split(/(?=<h2>)/);
const introduction = sections.shift();
const chapters = sections.map((html, index) => {
  const title = html.match(/<h2>([\s\S]*?)<\/h2>/)?.[1];
  if (!title) throw new Error("README chapter has no heading.");
  const id = slug(title.replace(/<[^>]*>/g, ""));
  return { title, id, html: `<section class="doc-section" id="${id}"><span class="chapter-number" aria-hidden="true">${String(index + 1).padStart(2, "0")}</span>${html}</section>` };
});

function artwork(d, miniature = false) {
  const spans = (count, className = "piece") => Array.from({ length: count }, (_, i) => `<span class="${className} p${i + 1}"></span>`).join("");
  const drawings = {
    orbit: `${spans(3, "ring")}<span class="planet"></span>${spans(4, "star")}`,
    paper: `<div class="paper-sheet"><span>FIELD NOTES</span><strong>Make<br>space.</strong><i></i><small>MOORKYZ / A CONSIDERED FOUNDATION</small></div><span class="paper-shadow"></span>`,
    blueprint: `<svg viewBox="0 0 600 480"><g fill="none" stroke="currentColor"><path d="M90 350V130l210-70 210 70v220l-210 70zM90 130l210 90 210-90M300 220v200M90 350l210-80 210 80M190 95v220l210 80M405 95v220l-210 80"/><circle cx="300" cy="220" r="150" stroke-dasharray="3 9"/><path d="M30 220h540M300 20v440" opacity=".3"/></g></svg>${spans(4, "coordinate")}`,
    prism: `${spans(3, "prism-plane")}<span class="light-beam"></span>`,
    terminal: `<div class="terminal-window"><div class="window-bar"><i></i><i></i><i></i><span>collection / terminal edition</span></div><p><b>01 /</b> Landing page</p><p class="terminal-comment">Monospaced type. Phosphor mint.</p><p><b>02 /</b> README edition</p><p class="terminal-comment">Clear hierarchy. Room for your content.</p><p><b>03 /</b> <span class="cursor">your next idea_</span></p></div>`,
    dune: `<span class="arch arch-back"></span><span class="arch arch-front"></span><span class="dune-sun"></span><span class="ground-line"></span>`,
    glacier: `${spans(4, "ice-plane")}<span class="ice-line"></span>`,
    mono: `<span class="mono-block"></span><span class="mono-circle"></span><span class="mono-rule"></span><span class="mono-index">M / 08</span>`,
    bloom: `${spans(5, "petal")}<span class="bloom-center"></span>`,
    obsidian: `<span class="monolith"></span><span class="monolith-edge"></span><span class="monolith-ground"></span>`,
    atlas: `<svg viewBox="0 0 600 480"><g fill="none" stroke="currentColor">${Array.from({ length: 14 }, (_, i) => `<ellipse cx="${320 - i * 4}" cy="240" rx="${260 - i * 15}" ry="${190 - i * 11}" transform="rotate(-24 300 240)"/>`).join("")}<path d="M50 390L470 70" stroke-dasharray="5 8"/></g><circle cx="300" cy="200" r="8" fill="currentColor"/></svg><span class="map-label">A starting point.<br>Not a destination.</span>`,
    signal: `<span class="signal-square"></span><span class="signal-disc"></span><span class="signal-cross">+</span>`,
    nocturne: `<svg viewBox="0 0 700 350"><g fill="none" stroke="currentColor">${Array.from({ length: 24 }, (_, i) => `<path d="M0 ${110 + i * 4}C150 ${-140 + i * 9} 220 ${480 - i * 6} 350 ${180 + i * 2}S550 ${40 + i * 7} 700 ${160 + i * 4}"/>`).join("")}</g></svg>`,
    solstice: `<span class="sun-disc"></span>${spans(5, "sun-rule")}<span class="sun-horizon"></span>`,
    vector: `<svg viewBox="0 0 600 480"><g fill="none" stroke="currentColor" stroke-width="2"><path d="M100 100h180v140h200M280 100h200v280H100V240h180"/><rect x="60" y="60" width="80" height="80" rx="12"/><rect x="240" y="200" width="80" height="80" rx="12"/><circle cx="480" cy="240" r="40"/><rect x="60" y="340" width="80" height="80" rx="12"/></g><circle cx="280" cy="100" r="9" fill="currentColor"/><circle cx="480" cy="380" r="9" fill="currentColor"/></svg>`,
    halo: `${spans(4, "halo-ring")}<span class="halo-center"></span>`,
    flux: `${spans(4, "ribbon")}<span class="foil-spot"></span>`,
    cabinet: `${["LAYOUTS", "PAGES", "EDITIONS", "DETAILS"].map((name, i) => `<div class="drawer d${i}"><small>0${i + 1} / ESSENTIALS</small><b>${name}</b><span class="drawer-handle"></span></div>`).join("")}`,
    liminal: `<span class="portal portal-back"></span><span class="portal portal-front"></span><span class="portal-floor"></span><span class="portal-light"></span>`,
    continuum: `<span class="eclipse-glow"></span><span class="eclipse"></span><span class="eclipse-horizon"></span>${spans(5, "star")}`,
  };
  return `<div class="art art-${d.art}${miniature ? " miniature" : ""}"${miniature ? "" : " data-light"} aria-hidden="true"><div class="art-surface">${drawings[d.art]}</div>${miniature ? "" : `<span class="art-caption">${escape(d.note)}</span>`}</div>`;
}

function header(d, kind) {
  return `<header class="site-header"><a class="brand" href="../index.html">${marker}<span>Moorkyz Templates<span class="brand-sub"> / ${escape(d.name)}</span></span></a>${searchBox({ root: "../", kind, design: d.id })}<nav aria-label="Page navigation"><a href="${kind === "readme" ? "landing.html" : "README.html"}">${kind === "readme" ? "Landing page" : "README edition"}</a><a href="../index.html#collection">All designs ${arrow}</a></nav><button class="light-toggle js-only" type="button" aria-pressed="true">Ambient light <span>on</span></button></header>`;
}
function footer(d, kind) {
  const index = designs.indexOf(d);
  const previous = designs[(index + designs.length - 1) % designs.length];
  const next = designs[(index + 1) % designs.length];
  const filename = kind === "readme" ? "README.html" : "landing.html";
  return `<footer class="site-footer"><a class="brand" href="../index.html">${marker}<span>Moorkyz Templates</span></a><span>${escape(d.name)} &middot; ${String(index + 1).padStart(2, "0")} / 20</span><nav aria-label="Adjacent designs"><a href="../${previous.id}/${filename}">Previous</a><a href="../${next.id}/${filename}">Next ${arrow}</a></nav></footer>`;
}
function document(d, kind, content) {
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="description" content="${escape(kind === "readme" ? `The complete repository README, in the ${d.name} edition of Moorkyz Templates.` : d.description)}"><meta name="color-scheme" content="${d.tone}"><title>${escape(d.name)} / ${kind === "readme" ? "README / " : ""}Moorkyz Templates</title><link rel="stylesheet" href="../assets/designs.css"><script src="../assets/interactions.js" defer></script>${searchHead("../")}</head>
<body class="edition ${d.id.slice(3)} ${kind}" data-design="${d.id}" data-kind="${kind}" style="${variables(d)}"><a class="skip-link" href="#main">Skip to content</a>${header(d, kind)}${content}${footer(d, kind)}</body></html>\n`;
}
function actions() {
  return `<div class="actions"><a class="button primary" href="README.html">View the README edition ${arrow}</a><a class="text-link" href="../index.html#collection">Browse all templates <span aria-hidden="true">&#8594;</span></a></div>`;
}
function landing(d) {
  const number = d.id.slice(0, 2);
  const copy = `<div class="hero-copy"><p class="eyebrow"><span class="small-rule"></span>${escape(d.label)}</p><h1>${d.title}</h1><p class="hero-description">${escape(d.description)}</p>${actions()}<p class="microcopy">Original layouts. Finished pages. Yours to shape.</p></div>`;
  const art = artwork(d);
  const hero = `<section class="hero" aria-label="${escape(d.name)} introduction"><div class="edition-index" aria-hidden="true">M / ${number}<span>TEMPLATE STUDIES</span></div>${["glacier", "vector", "liminal"].includes(d.art) ? art + copy : copy + art}<div class="hero-bottom"><span>MOORKYZ TEMPLATES</span><span>${escape(d.category)} / ${escape(d.name)}</span><a href="#foundation">Explore this template <span aria-hidden="true">&#8595;</span></a></div></section>`;
  const features = `<section class="foundation section-wrap" id="foundation"><div class="section-heading"><p class="eyebrow">The template</p><h2>One direction.<br>Two finished <em>pages.</em></h2><p>A landing page and a matching README edition, with original typography, artwork and layout. Explore the finished work before making it your own.</p></div><div class="feature-grid">${[
    ["01", "A complete landing page.", "A distinct composition, considered color palette and original artwork, ready to explore on this page.", "#main", "Back to the design"],
    ["02", "A matching README edition.", "See the same visual direction applied to readable documentation with clear section navigation.", "README.html", "View the README"],
    ["03", "Part of a wider collection.", "Twenty directions, from quiet editorial layouts to expressive cosmic compositions. Compare them in the showcase.", "../index.html#collection", "See all twenty"],
  ].map(([n, title, text, href, label]) => `<article class="feature"><span class="feature-number">${n}</span><h3>${title}</h3><p>${text}</p><a href="${href}">${label} ${arrow}</a></article>`).join("")}</div></section>`;
  const start = `<section class="start-section section-wrap" id="begin"><div><p class="eyebrow">Make it yours</p><h2>Start with a template.<br><em>Give it your voice.</em></h2><p>Explore both pages, choose the direction that fits, then adapt the content and visual details for your own project.</p><a class="button primary" href="https://github.com/Moorky/moorkyz-template">View the template source ${arrow}</a></div><div class="start-card"><span class="eyebrow">Inside this edition</span><pre><code>landing.html
README.html</code></pre><p>Two finished pages. Open them directly in your browser and compare the layouts at your own pace.</p><a href="README.html">Open the README edition ${arrow}</a></div></section>`;
  return document(d, "landing", `<main id="main">${hero}${features}${start}</main>`);
}
function readmeEdition(d) {
  if (documentationThemes.includes(d.art)) {
    const index = designs.indexOf(d);
    return renderDocumentation({
      markdown: readme, theme: d.art, sourceName: "README.md", collectionId: d.id, scriptHref: "../assets/interactions.js", searchRoot: "../",
      rewriteHref: (href) => /^(?:[a-z][a-z0-9+.-]*:|#|\/)/i.test(href) ? href : rootLink + href,
      links: [{ label: "All designs", href: "../index.html#collection" }, { label: "Landing page", href: "landing.html" }, { label: "Markdown", href: "../../README.md" }],
      adjacent: [{ label: "Previous", href: `../${designs[(index + 19) % 20].id}/README.html` }, { label: "Next", href: `../${designs[(index + 1) % 20].id}/README.html` }],
    });
  }
  const navigation = chapters.map((chapter, i) => `<a href="#${chapter.id}"><span>${String(i + 1).padStart(2, "0")}</span>${chapter.title}</a>`).join("");
  return document(d, "readme", `<main id="main"><section class="readme-hero"><div><p class="eyebrow">The ${escape(d.name)} edition / README</p><h1>Moorkyz<br><em>Templates.</em></h1><p class="hero-description">A README layout.<br>A direction of your own.</p><div class="readme-badges"><span>README edition</span><span>${escape(d.name)} design</span><a href="../../README.md">Markdown source ${arrow}</a></div></div>${artwork(d)}</section><div class="doc-shell"><aside class="doc-sidebar"><p class="eyebrow">In this guide</p><nav class="doc-nav" aria-label="README chapters">${navigation}</nav><p class="doc-note">Complete repository documentation.<br>Presented in the ${escape(d.name)} layout.</p><a class="text-link" href="landing.html">View the landing page ${arrow}</a></aside><article class="doc-body" aria-label="Complete README"><div class="doc-introduction">${introduction}</div>${chapters.map((chapter) => chapter.html).join("\n")}</article></div></main>`);
}

function showcase() {
  const cards = designs.map((d) => `<article class="collection-card" data-category="${d.category}" data-tone="${d.tone}" data-name="${escape(`${d.name} ${d.note} ${d.category}${documentationThemes.includes(d.art) ? " compact documentation docs" : ""}`.toLowerCase())}"><div class="card-visual edition ${d.id.slice(3)}" style="${variables(d)}"><span class="card-index">${d.id.slice(0, 2)} / 20</span>${artwork(d, true)}<div class="mini-title">${d.title}</div><span class="preview-chip">${escape(d.category)} &middot; ${d.tone === "dark" ? "Dark" : "Light"}</span></div><div class="card-info"><div><h3>${escape(d.name)}</h3><p>${escape(d.note)}</p></div><button class="preview-button js-only" type="button" data-preview="${d.id}" aria-label="Preview ${escape(d.name)}">Preview ${arrow}</button></div><div class="card-links"><a href="${d.id}/landing.html" data-page-link="landing">Landing page ${arrow}</a><a href="${d.id}/README.html" data-page-link="readme">${documentationThemes.includes(d.art) ? "Docs README" : "README"} ${arrow}</a></div></article>`).join("\n");
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="description" content="Moorkyz Templates: a showcase of 20 original template designs, 20 finished landing pages and 20 README editions. Explore the completed collection."><meta name="color-scheme" content="dark"><title>Moorkyz Templates / The template showcase</title><link rel="stylesheet" href="assets/designs.css"><link rel="stylesheet" href="assets/showcase.css"><script src="assets/interactions.js" defer></script>${searchHead("")}<script src="assets/showcase.js" defer></script></head><body class="showcase"><a class="skip-link" href="#main">Skip to content</a>
<header class="showcase-header"><a class="brand" href="./index.html">${marker}<span>Moorkyz Templates</span></a>${searchBox({ root: "", kind: "showcase" })}<nav aria-label="Main navigation"><a href="#collection">Collection</a><a href="#foundation">What's inside</a><a href="./README.md">Collection guide ${arrow}</a></nav><a class="header-cta" href="https://github.com/Moorky/moorkyz-template">View the source ${arrow}</a></header>
<main id="main"><section class="showcase-hero"><div class="hero-copy"><p class="eyebrow"><span class="status-dot"></span>MOORKYZ TEMPLATES / THE COMPLETED COLLECTION</p><h1>Templates,<br><em>by design</em><span class="title-dot" aria-hidden="true">.</span></h1><p class="showcase-description">Twenty original template designs.<br> Finished landing pages and README editions.<br> Explore what we have made.</p><div class="actions"><a class="button primary" href="#collection">Explore the collection <span aria-hidden="true">&#8595;</span></a><a class="text-link" href="#foundation">See what's included ${arrow}</a></div><p class="hero-footnote">Real pages. Original layouts. Ready to explore.</p></div><div class="showcase-sculpture" data-light aria-hidden="true"><span class="sculpture-halo"></span><span class="sculpture-plane plane-one"></span><span class="sculpture-plane plane-two"></span><span class="sculpture-plane plane-three"></span><span class="sculpture-core"></span><span class="sculpture-orbit"></span><span class="sculpture-caption">TWENTY DISTINCT DIRECTIONS.</span><span class="sculpture-coordinate">X: COMPOSITION<br>Y: CHARACTER</span></div><div class="hero-bottom"><span>VOL. 01 / THE TEMPLATE COLLECTION</span><span>LANDING PAGES &amp; README EDITIONS</span></div></section>
<section class="collection-stats" aria-label="What is included"><div><strong>20<span> /</span></strong><p>README editions</p></div><div><strong>20<span> /</span></strong><p>Landing pages</p></div><div><strong>40<span> + 1</span></strong><p>Pages, plus this showcase</p></div><div><strong>5<span> /</span></strong><p>Compact README themes</p></div></section>
<section class="collection-section" id="collection"><div class="collection-heading"><div><p class="eyebrow">THE COLLECTION / 01&mdash;20</p><h2>One collection.<br><em>Twenty points of view.</em></h2></div><p>Some whisper. Some glow.<br> All turn complexity into clarity.<br> Choose a direction, then make it your own.</p></div><div class="collection-controls js-only"><div class="filter-group" role="group" aria-label="Filter design style">${["All", "Quiet", "Cosmic", "Chromatic", "Editorial", "Systematic"].map((name) => `<button type="button" data-filter="${name}" aria-pressed="${name === "All"}">${name}</button>`).join("")}</div></div><div class="collection-meta"><p id="result-count" role="status" aria-live="polite">20 directions / 40 pages</p><div class="view-switch js-only" role="group" aria-label="Prioritize page type"><button type="button" data-kind="landing" aria-pressed="true">Landing pages</button><button type="button" data-kind="readme" aria-pressed="false">README editions</button></div></div><div class="collection-grid">${cards}</div><p class="empty-state" hidden>No designs match this combination. Try another name or choose All.</p></section>
<section class="showcase-foundation" id="foundation"><div><p class="eyebrow">WHAT WE HAVE MADE</p><h2>Original templates.<br><em>Finished in detail.</em></h2><p>A collection of twenty distinct visual directions, each with a landing page and a README edition. Browse the actual pages, compare their character and find a layout that fits.</p><a class="text-link" href="#collection">Browse the completed collection ${arrow}</a></div><div class="foundation-list"><a href="index.html?view=landing#collection"><span>01 / LANDING PAGES</span><h3>20 complete compositions.</h3><p>Original artwork, typography and layouts in light and dark palettes.</p>${arrow}</a><a href="index.html?view=readme#collection"><span>02 / README EDITIONS</span><h3>20 documentation designs.</h3><p>Matching README layouts, including five compact, everyday editions.</p>${arrow}</a><a href="#collection"><span>03 / EXPLORE THE WORK</span><h3>One connected showcase.</h3><p>Compare every direction with live previews and wide or mobile views.</p>${arrow}</a></div></section>
<section class="closing-section"><p class="eyebrow">FIND YOUR NEXT STARTING POINT</p><h2>Choose a template.<br><em>Make it your own.</em></h2><p>Explore the finished pages. Find your direction. Give it your voice.</p><div class="actions"><a class="button primary" href="#collection">Browse Moorkyz Templates ${arrow}</a><a class="text-link" href="./README.md">How to use this collection ${arrow}</a></div><span class="closing-orbit" aria-hidden="true"></span></section></main>
<footer class="showcase-footer"><a class="brand" href="#main">${marker}<span>Moorkyz Templates</span></a><span>Twenty directions. A collection of finished work.</span><a href="../LICENSE">MIT licensed ${arrow}</a></footer>
<dialog id="preview-dialog" aria-labelledby="preview-title"><div class="preview-toolbar"><div><p class="eyebrow">LIVE LOCAL PREVIEW</p><h2 id="preview-title">Design preview</h2></div><div class="preview-tabs" role="group" aria-label="Preview page type"><button type="button" data-preview-kind="landing" aria-pressed="true">Landing</button><button type="button" data-preview-kind="readme" aria-pressed="false">README</button></div><div class="preview-size" role="group" aria-label="Preview viewport"><button type="button" data-size="wide" aria-pressed="true">Wide</button><button type="button" data-size="mobile" aria-pressed="false">Mobile</button></div><a id="open-preview" href="./index.html" target="_blank" rel="noopener">Open page ${arrow}</a><button id="close-preview" type="button" aria-label="Close preview">Close <span aria-hidden="true">&times;</span></button></div><div class="preview-stage"><iframe id="preview-frame" title="Selected design preview"></iframe></div><p class="preview-help">Escape closes preview. Each page also opens directly, without this gallery.</p></dialog></body></html>\n`;
}

if (designs.length !== 20 || new Set(designs.map((d) => d.id)).size !== 20) {
  throw new Error("The collection must contain exactly twenty unique design directions.");
}
const files = new Map([["index.html", showcase()], ["assets/search-index.js", searchIndex({ directory, designs, documentationThemes, chapters })]]);
for (const d of designs) {
  files.set(`${d.id}/README.html`, readmeEdition(d));
  files.set(`${d.id}/landing.html`, landing(d));
}
let stale = 0;
for (const [relative, content] of files) {
  const filename = path.join(directory, relative);
  if (args.includes("--check")) {
    if (!fs.existsSync(filename) || fs.readFileSync(filename, "utf8") !== content) {
      console.error(`STALE: designs/${relative}`);
      stale++;
    }
  } else {
    fs.mkdirSync(path.dirname(filename), { recursive: true });
    fs.writeFileSync(filename, content);
  }
}
if (stale) throw new Error(`${stale} generated page(s) are stale. Run node designs/build.mjs.`);
console.log(`${args.includes("--check") ? "Verified" : "Generated"} 20 README editions, 20 landing pages, 1 showcase and the shared search index.`);
