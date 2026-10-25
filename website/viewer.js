"use strict";
(() => {
  const entries = [...document.querySelectorAll(".viewer-entry")];
  const search = document.querySelector("#viewer-search");
  const selector = document.querySelector("#template-selector");
  const filter = document.querySelector(".type-filter");
  const radios = [...document.querySelectorAll("[name=page-type]")];
  const count = document.querySelector("#entry-count");
  const empty = document.querySelector(".empty-list");
  const frame = document.querySelector("#template-frame");
  const heading = document.querySelector("#viewer-heading");
  const fullView = document.querySelector("#full-view");
  const error = document.querySelector("#viewer-error");
  const previous = document.querySelector("#previous-template");
  const next = document.querySelector("#next-template");
  const mobile = matchMedia("(max-width: 900px)");
  const normalize = globalThis.MoorkyzPredictiveSearch.normalize;
  let selected = entries[0];
  let visible = entries;
  let type = "all";

  function updateNavigation() {
    const index = visible.indexOf(selected);
    for (const [link, step] of [[previous, -1], [next, 1]]) {
      const target = visible.length ? visible[index < 0 ? (step < 0 ? visible.length - 1 : 0) : (index + step + visible.length) % visible.length] : null;
      link.setAttribute("aria-disabled", String(!target || target === selected));
      if (target && target !== selected) link.href = target.dataset.url;
      else link.removeAttribute("href");
    }
  }

  function updateList() {
    const query = normalize(search.value);
    visible = entries.filter((entry) => {
      const matches = mobile.matches || (
        (selector.value === "all" || selector.value === entry.dataset.template) &&
        (type === "all" || type === entry.dataset.kind) &&
        normalize(entry.dataset.search).includes(query)
      );
      entry.hidden = !matches;
      return matches;
    });
    count.textContent = `${visible.length} ${visible.length === 1 ? "entry" : "entries"}`;
    empty.hidden = visible.length !== 0;
    filter.dataset.active = String(type !== "all");
    updateNavigation();
  }

  function select(entry, push = false) {
    selected = entry;
    error.hidden = true;
    const title = `${entry.dataset.name} / ${entry.dataset.kind === "readme" ? "README" : "Landing page"}`;
    for (const item of entries) {
      if (item === entry) item.setAttribute("aria-current", "page");
      else item.removeAttribute("aria-current");
    }
    frame.title = `${title} preview`;
    if (frame.getAttribute("src") !== entry.dataset.src) frame.src = entry.dataset.src;
    heading.textContent = title;
    document.title = `${title} / Moorkyz Templates`;
    fullView.href = entry.dataset.src;
    fullView.setAttribute("aria-label", `Full View: ${title} (opens in a new tab)`);
    if (push) history.pushState(null, "", entry.dataset.url);
    updateNavigation();
    if (!mobile.matches && !entry.hidden) entry.scrollIntoView({ block: "nearest" });
  }

  function readLocation() {
    const params = new URLSearchParams(location.search);
    const template = params.get("template") ?? entries[0].dataset.template;
    const kind = params.get("kind") ?? "landing";
    const entry = entries.find((item) => item.dataset.template === template && item.dataset.kind === kind);
    if (!entry) {
      error.hidden = false;
      frame.removeAttribute("src");
      fullView.removeAttribute("href");
      heading.textContent = "Template not found";
      document.title = "Template not found / Moorkyz Templates";
      for (const item of entries) item.removeAttribute("aria-current");
      return;
    }
    select(entry);
  }

  function navigate(event, entry) {
    if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    if (entry) select(entry, true);
  }
  for (const entry of entries) entry.addEventListener("click", (event) => navigate(event, entry));
  for (const link of [previous, next]) link.addEventListener("click", (event) => {
    const entry = link.hasAttribute("href") ? entries.find((item) => new URL(item.dataset.url, location.href).href === link.href) : null;
    navigate(event, entry);
  });
  search.addEventListener("input", updateList);
  selector.addEventListener("change", updateList);
  for (const radio of radios) radio.addEventListener("change", () => {
    type = radio.value;
    updateList();
    filter.open = false;
    filter.querySelector("summary").focus();
  });
  filter.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      event.preventDefault();
      filter.open = false;
      filter.querySelector("summary").focus();
    }
  });
  mobile.addEventListener("change", () => {
    filter.open = false;
    updateList();
  });
  window.addEventListener("popstate", readLocation);
  document.querySelector(".viewer-controls").hidden = false;
  updateList();
  readLocation();
})();
