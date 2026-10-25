import { writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { designs, documentationThemes } from "../designs/catalog.mjs";

const root = new URL("../", import.meta.url);
const escape = (value) => String(value).replace(/[&<>"']/g, (character) => ({
  "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
})[character]);
const textTitle = (title) => title.replace(/<br>/g, " ").replace(/<\/?em>/g, "");
const mark = `<svg viewBox="0 0 512 512" aria-hidden="true" focusable="false"><path fill="currentColor" d="M40 50c7 5 22 21 29 28l42 40 24 24 64 62c9 9 23 20 30 30l-24 25-19 18-24-23-34-32-22-21v120l1 8 9 8 20 13 41 28 60 41c-3 7-19 19-26 25-3 2-8 7-11 7l-10-5-22-13-77-45-36-21c-12-7-15-6-15-17V50Zm431 0c2 5 1 22 1 28v272c0 11-3 10-15 17l-36 21-77 45-22 13-10 5c-3 0-8-5-11-7-7-6-23-18-26-25l60-41 41-28 20-13 9-8 1-8V201c-6 4-13 12-19 18l-11 10-16 16-35 33-17 17-12 11-28 27c-2 2-9 10-12 10s-11-8-13-10l-31-31 35-35 31-29 24-24 9-8 24-24 10-9 23-23L471 50Z"/></svg>`;
const viewerUrl = (design, kind) => `viewer.html?template=${design.id}&kind=${kind}`;
const pageUrl = (design, kind) => `../designs/${design.id}/${kind === "readme" ? "README" : "landing"}.html`;

function preview(design) {
  return `<div class="template-preview" aria-hidden="true" style="--paper:${escape(design.bg)};--surface:${escape(design.surface)};--ink:${escape(design.ink)};--accent:${escape(design.accent)}">
    <div class="preview-bar"><span class="window-dots"><i></i><i></i><i></i></span><span>${escape(design.name.toLowerCase())}.template</span><span>&#8599;</span></div>
    <div class="preview-landing"><span class="preview-label">${escape(design.label)}</span><strong>${escape(textTitle(design.title))}</strong><span class="preview-rule"></span><span class="preview-pill">Start something good <b>&#8599;</b></span><div class="preview-art art-${escape(design.art)}"><i></i><i></i><i></i></div></div>
    <div class="preview-readme"><div class="preview-sidebar"><i></i><i></i><i></i><i></i></div><div class="preview-document"><span class="preview-label">README.md</span><strong>${escape(design.name)}</strong><span class="doc-line"></span><span class="doc-line short"></span><div class="doc-code"><span></span><span></span><span></span></div><span class="doc-line"></span><span class="doc-line short"></span></div></div>
  </div>`;
}

function card(design, index) {
  const compact = documentationThemes.includes(design.id.slice(3));
  return `<article class="template-card" data-style="${escape(design.category)}">
  ${preview(design)}
  <div class="card-content"><div class="card-heading"><h3>${escape(design.name)}</h3><span class="card-number">${String(index + 1).padStart(2, "0")}</span></div>
  <p class="card-description">${escape(design.note)}</p>
  <div class="card-tags"><span>${escape(design.category)}</span><span>${escape(design.tone)}</span>${compact ? '<span class="compact-tag">Compact README</span>' : ""}</div>
  <div class="card-links"><a data-kind="readme" data-viewer-href="website/${escape(viewerUrl(design, "readme"))}" href="designs/${escape(design.id)}/README.html" aria-label="Open ${escape(design.name)} README">README <span aria-hidden="true">&#8599;</span></a><a data-kind="landing" data-viewer-href="website/${escape(viewerUrl(design, "landing"))}" href="designs/${escape(design.id)}/landing.html" aria-label="Open ${escape(design.name)} landing page">Landing <span aria-hidden="true">&#8599;</span></a></div></div>
  </article>`;
}

export function renderWebsite() {
  const styles = [...new Set(designs.map((design) => design.category))].sort();
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="dark">
  <meta name="description" content="Explore Moorkyz Templates: ${designs.length} original designs, each with a ready-to-explore README and landing page. Find your next starting point.">
  <title>Moorkyz Templates / A better place to start</title>
  <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='8' fill='%23080c14'/%3E%3Cpath d='M7 24V8l9 9 9-9v16M7 8l9 16 9-16' fill='none' stroke='%23c9e7ff' stroke-width='2'/%3E%3C/svg%3E">
  <link rel="stylesheet" href="website/catalog.css">
  <script src="website/catalog.js" defer></script>
</head>
<body data-view="all">
  <a class="skip-link" href="#main">Skip to content</a>
  <header class="site-header">
    <a class="brand" href="./index.html" aria-label="Moorkyz Templates home">${mark}<span>moorkyz<span class="brand-divider">/</span><span class="brand-section">templates</span></span></a>
    <nav aria-label="Main navigation"><a class="nav-current" href="#collection">Templates</a><a href="designs/index.html">Design showcase <span aria-hidden="true">&#8599;</span></a></nav>
    <a class="source-link" href="https://github.com/Moorky/moorkyz-template" aria-label="Moorkyz Templates on GitHub"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path d="m8 7-5 5 5 5m8-10 5 5-5 5M14 4l-4 16"/></svg><span>Source</span></a>
  </header>
  <main id="main">
    <section class="hero" aria-labelledby="hero-title">
      <div class="hero-copy"><p class="eyebrow"><span class="status-dot"></span>THE MOORKYZ TEMPLATE COLLECTION</p>
      <h1 id="hero-title">A better place<br>to <em>start.</em></h1>
      <p class="hero-description">Small beginnings. Distinct personalities.<br>Thoughtfully made templates for your next big thing.</p>
      <a class="explore-link" href="#collection">Find your template <span aria-hidden="true">&#8600;</span></a>
      <div class="hero-facts"><span>${designs.length} original designs</span><span>${designs.length * 2} finished pages</span><span>Just HTML, CSS &amp; JS</span></div></div>
      <div class="hero-art" aria-hidden="true"><div class="orbit orbit-one"></div><div class="orbit orbit-two"></div><div class="floating-label label-top">01 / AN IDEA</div><div class="hero-window"><div class="preview-bar"><span class="window-dots"><i></i><i></i><i></i></span><span>your-next-project.html</span><span>&#8599;</span></div><div class="hero-window-content"><span class="preview-label">A LITTLE STRUCTURE. A LOT OF POSSIBILITY.</span><strong>Make it<br><em>your own.</em></strong><div class="hero-sphere"></div><span class="hero-window-line"></span><span class="hero-window-line short"></span><span class="hero-window-button">Hello, possibility. &#8599;</span></div></div><div class="floating-label label-bottom"><span class="status-dot"></span>READY WHEN YOU ARE</div></div>
    </section>
    <section class="collection" id="collection" aria-labelledby="collection-title">
      <div class="section-heading"><div><p class="eyebrow">BROWSE THE COLLECTION</p><h2 id="collection-title">Different by design<span>.</span></h2></div><p>Find a style that feels like you.<br>Then take it somewhere new.</p></div>
      <div class="catalog-toolbar"><div class="category-title"><span class="category-icon" aria-hidden="true">&#10022;</span><h3>Design</h3><span class="category-count">${designs.length}</span></div>
      <div class="catalog-controls" hidden><div class="view-filters" role="group" aria-label="Template type"><button type="button" data-view-filter="all" aria-pressed="true">All designs</button><button type="button" data-view-filter="readme" aria-pressed="false">README</button><button type="button" data-view-filter="landing" aria-pressed="false">Landing</button></div><label class="style-filter"><span class="sr-only">Design style</span><select id="style-filter"><option value="all">All styles</option>${styles.map((style) => `<option value="${escape(style)}">${escape(style)}</option>`).join("")}</select></label></div></div>
      <div class="collection-caption"><p id="result-count" role="status" aria-live="polite">${designs.length} designs / ${designs.length * 2} templates</p><p>README &amp; Landing, in every style <span aria-hidden="true">&#8600;</span></p></div>
      <div class="template-grid">${designs.map(card).join("\n")}</div>
      <div class="collection-note"><span class="note-mark" aria-hidden="true">&#10035;</span><p>One design. Two ways to begin.<br><span>Every style includes a README edition and a landing page. Open either to explore the full template.</span></p><a href="https://github.com/Moorky/moorkyz-template">Make it yours on GitHub <span aria-hidden="true">&#8599;</span></a></div>
    </section>
  </main>
  <footer class="site-footer"><p>made /w <span class="footer-mark" role="img" aria-label="the Moorkyz mark">${mark}</span> <span>&copy; <span data-year>${new Date().getUTCFullYear()}</span> Moorkyz</span></p><a href="https://moorky.com">moorky.com <span aria-hidden="true">&#8599;</span></a><a href="#main">Back to top <span aria-hidden="true">&#8593;</span></a></footer>
</body>
</html>
`;
}

export function renderViewer() {
  const first = designs[0];
  const last = designs.at(-1);
  const entries = designs.flatMap((design, index) => ["landing", "readme"].map((kind) => {
    const label = kind === "readme" ? "README" : "Landing page";
    return `<a class="viewer-entry" href="${pageUrl(design, kind)}" data-url="${escape(viewerUrl(design, kind))}" data-template="${escape(design.id)}" data-kind="${kind}" data-name="${escape(design.name)}" data-src="${pageUrl(design, kind)}" data-search="${escape(`${design.name} ${design.category} ${design.tone} ${design.note} ${label}${documentationThemes.includes(design.art) ? " compact documentation" : ""}`)}"${index === 0 && kind === "landing" ? ' aria-current="page"' : ""}><span class="entry-number">${String(index + 1).padStart(2, "0")}</span><span class="entry-copy"><span class="entry-name">${escape(design.name)}</span><span class="entry-type">${label} / ${escape(design.category)}</span></span><span class="entry-swatch" style="--swatch:${escape(design.accent)}" aria-hidden="true"></span></a>`;
  })).join("\n");
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="color-scheme" content="dark"><meta name="description" content="Explore every Moorkyz template in a live preview, with search and a full collection sidebar."><title>Template viewer / Moorkyz Templates</title><link rel="stylesheet" href="viewer.css"><script src="../designs/assets/predictive-search.js" defer></script><script src="viewer.js" defer></script></head>
<body><a class="skip-link" href="#viewer-heading">Skip to preview controls</a><div class="viewer">
<aside class="viewer-sidebar" aria-label="Template browser"><div class="sidebar-controls"><a class="collection-link" href="../index.html#collection">&larr; Moorkyz Templates</a><div class="viewer-controls" hidden><label class="control-label" for="viewer-search">Search templates</label><input class="viewer-search" id="viewer-search" type="search" placeholder="Search all entries" autocomplete="off"><div class="selector-row"><label class="template-selector" for="template-selector"><span class="control-label">Template</span><select id="template-selector"><option value="all">All templates</option>${designs.map((design) => `<option value="${escape(design.id)}">${escape(design.name)}</option>`).join("")}</select></label><details class="type-filter"><summary aria-label="Filter page types" title="Filter page types"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><path d="M3 5h18l-7 8v6l-4 2v-8z"/></svg></summary><div class="type-options"><fieldset><legend>Show page types</legend><label><input type="radio" name="page-type" value="all" checked> All entries</label><label><input type="radio" name="page-type" value="landing"> Landing pages</label><label><input type="radio" name="page-type" value="readme"> README editions</label></fieldset></div></details></div></div><p class="entry-count" id="entry-count" role="status" aria-live="polite">${designs.length * 2} entries</p></div><nav class="entry-list" aria-label="Template entries">${entries}<p class="empty-list" hidden>No entries match. Clear the search or choose another template or page type.</p></nav></aside>
<main class="viewer-preview"><header class="viewer-toolbar"><a class="mobile-collection" href="../index.html#collection" aria-label="Back to template collection">&larr; Templates</a><nav class="viewer-navigation" aria-label="Previous and next templates"><a id="previous-template" href="${pageUrl(last, "readme")}" aria-label="Previous template">&lt;&lt;</a><a id="next-template" href="${pageUrl(first, "readme")}" aria-label="Next template">&gt;&gt;</a></nav><h1 class="viewer-heading" id="viewer-heading" tabindex="-1">${escape(first.name)} / Landing page</h1><a class="full-view" id="full-view" href="${pageUrl(first, "landing")}" target="_blank" rel="noopener" aria-label="Full View (opens in a new tab)">Full View <span aria-hidden="true">&#8599;</span></a></header>
<p class="viewer-error" id="viewer-error" role="alert" hidden>This template link is not valid. Choose an entry from the list, use the previous/next controls, or <a href="../index.html#collection">return to the collection</a>.</p><noscript><p>The interactive viewer needs JavaScript. Open templates directly from the list, the arrows or <a href="../index.html#collection">the collection</a>.</p></noscript><iframe class="template-frame" id="template-frame" src="${pageUrl(first, "landing")}" title="${escape(first.name)} landing page preview"></iframe></main>
</div></body></html>
`;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  writeFileSync(new URL("index.html", root), renderWebsite());
  writeFileSync(new URL("website/viewer.html", root), renderViewer());
  console.log(`Built index.html and website/viewer.html: ${designs.length} designs / ${designs.length * 2} template entries.`);
}
