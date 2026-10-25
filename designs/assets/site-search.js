"use strict";
// Mounts the shared predictive search on any design page. Suggestions come from the generated
// local index; accepting only fills the field, Enter opens an exact destination or searches the collection.
(() => {
  const engine = globalThis.MoorkyzPredictiveSearch;
  const index = globalThis.MoorkyzSearchIndex;
  const form = document.querySelector("[data-site-search]");
  const input = form?.querySelector("input");
  if (!engine || !index || !form || !input) return;

  const root = form.dataset.searchRoot ?? "";
  const kind = form.dataset.searchKind;
  const here = index.designs.find((d) => d.id === form.dataset.searchDesign);
  const pageKind = () => (kind === "showcase" ? (document.body.classList.contains("readme-priority") ? "readme" : "landing") : kind);
  const local = (relative) => root + relative;
  const collection = (params) => () => local(`index.html?${new URLSearchParams(params)}#collection`);
  const entries = [];
  const targets = new Map();

  function add(entry, target) {
    entries.push(entry);
    if (!target) return;
    for (const key of [entry.value, ...(entry.aliases ?? [])].map(engine.normalize)) if (key && !targets.has(key)) targets.set(key, target);
  }

  const categories = new Set();
  for (const d of index.designs) {
    const contexts = [d.category, d.tone];
    const open = () => local(`${d.id}/${pageKind() === "readme" ? "README" : "landing"}.html`);
    add({ value: d.name, kind: "Design", weight: d === here ? 20 : 40, contexts }, open);
    for (const phrase of d.note.split("/").map((part) => part.trim()).filter(Boolean)) add({ value: phrase, kind: "Character", weight: 20, contexts }, open);
    add({ value: `${d.id}/landing.html`, kind: "File", weight: -40, contexts: [...contexts, "landing"] }, () => local(`${d.id}/landing.html`));
    add({ value: `${d.id}/README.html`, kind: "File", weight: -40, contexts: [...contexts, "readme"] }, () => local(`${d.id}/README.html`));
    categories.add(d.category);
  }
  for (const category of categories) add({ value: category, kind: "Style", weight: 30, contexts: [category] }, collection({ style: category }));
  add({ value: "Dark", kind: "Tone", weight: 10, contexts: ["dark"] }, collection({ q: "dark" }));
  add({ value: "Light", kind: "Tone", weight: 10, contexts: ["light"] }, collection({ q: "light" }));
  add({ value: "Compact documentation", kind: "Edition", weight: 15, contexts: ["readme"] }, collection({ q: "compact documentation" }));
  for (const chapter of index.chapters) {
    const target = () => (kind === "readme" ? `#${chapter.id}` : local(`${here ? `${here.id}/README.html` : index.chapterHome}#${chapter.id}`));
    add({ value: chapter.title, kind: "Chapter", weight: kind === "readme" ? 45 : 25, contexts: ["readme"] }, target);
  }
  for (const entry of index.entries) add({ ...entry, contexts: [] }, entry.href ? () => local(entry.href) : null);

  const predictor = engine.createPredictor({ entries, limit: 6 });
  const context = () => {
    const filter = document.querySelector("[data-filter][aria-pressed=true]")?.dataset.filter;
    return [here?.category, here?.tone, pageKind(), filter === "All" ? "" : filter].filter(Boolean);
  };
  const remote = globalThis.MoorkyzSearchRemote;
  const controller = engine.attach(input, predictor, {
    label: "Search suggestions",
    context,
    remote: typeof remote === "function" ? (query, options) => remote(query, options) : null,
  });

  function reveal(hash) {
    const target = document.getElementById(decodeURIComponent(hash.slice(1)));
    if (!target) return false;
    if (!target.hasAttribute("tabindex")) target.setAttribute("tabindex", "-1");
    target.scrollIntoView({ block: "start", behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth" });
    target.focus({ preventScroll: true });
    return true;
  }
  function commit(raw) {
    const value = raw.trim();
    if (!engine.normalize(value)) return;
    const target = targets.get(engine.normalize(value));
    const href = target ? target() : collection({ q: value })();
    const detail = { value, href, matched: Boolean(target), record: () => predictor.record(value) };
    if (!form.dispatchEvent(new CustomEvent("moorkyz:search-commit", { cancelable: true, detail }))) return;
    if (target) predictor.record(value);
    controller.dismiss();
    if (href.startsWith("#") && reveal(href)) {
      history.replaceState(null, "", href);
      return;
    }
    location.assign(href);
  }
  form.addEventListener("submit", (event) => {
    event.preventDefault();
    commit(input.value);
  });
  globalThis.MoorkyzSiteSearch = { input, record: (value) => predictor.record(value), refresh: () => controller.refresh(), suggestions: () => controller.suggestions };
})();
