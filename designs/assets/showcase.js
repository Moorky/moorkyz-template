"use strict";
const cards = [...document.querySelectorAll(".collection-card")];
const search = document.querySelector("#design-search");
const count = document.querySelector("#result-count");
const empty = document.querySelector(".empty-state");
const filterButtons = [...document.querySelectorAll("[data-filter]")];
const predictive = window.MoorkyzPredictiveSearch;
const fold = predictive ? predictive.normalize : (value) => value.trim().toLowerCase();
let category = "All";
let kind = "landing";
let previewCard = null;
const dialog = document.querySelector("#preview-dialog");
const frame = document.querySelector("#preview-frame");
let trigger = null;
const pageLinks = (card) => [...card.querySelectorAll("[data-page-link]")];
const haystacks = new Map(cards.map((card) => [card, fold([card.dataset.name, card.dataset.tone, ...pageLinks(card).map((link) => link.getAttribute("href"))].join(" "))]));

function filter() {
  const query = fold(search.value);
  let visible = 0;
  for (const card of cards) {
    card.hidden = !((category === "All" || card.dataset.category === category) && haystacks.get(card).includes(query));
    if (!card.hidden) visible++;
  }
  count.textContent = `${visible} direction${visible === 1 ? "" : "s"} / ${visible * 2} pages`;
  empty.hidden = visible !== 0;
  return visible;
}
function suggestionEntries() {
  const entries = [];
  for (const card of cards) {
    const contexts = [card.dataset.category, card.dataset.tone];
    entries.push({ value: card.querySelector("h3").textContent.trim(), kind: "Design", weight: 40, contexts });
    for (const phrase of card.querySelector(".card-info p").textContent.split("/")) entries.push({ value: phrase.trim(), kind: "Character", weight: 20, contexts });
    entries.push({ value: card.dataset.category, kind: "Style", weight: 30, contexts });
    entries.push({ value: card.dataset.tone === "dark" ? "Dark" : "Light", kind: "Tone", weight: 10, contexts });
    if (card.dataset.name.includes("compact documentation")) entries.push({ value: "Compact documentation", kind: "Edition", weight: 15, contexts: [...contexts, "readme"] });
    for (const link of pageLinks(card)) entries.push({ value: link.getAttribute("href"), kind: "File", weight: -40, contexts: [...contexts, link.dataset.pageLink] });
  }
  return entries;
}
const predictor = predictive?.createPredictor({ entries: suggestionEntries(), limit: 6 });
if (predictor) {
  predictive.attach(search, predictor, {
    label: "Design suggestions",
    context: () => [category === "All" ? "" : category, kind],
    onCommit: (value) => {
      if (filter() > 0) predictor.record(value);
    },
  });
}
for (const button of filterButtons) {
  button.addEventListener("click", () => {
    category = button.dataset.filter;
    for (const item of filterButtons) item.setAttribute("aria-pressed", String(item === button));
    filter();
  });
}
search.addEventListener("input", filter);
function pressGroup(selector, attribute, value) {
  for (const button of document.querySelectorAll(selector)) button.setAttribute("aria-pressed", String(button.dataset[attribute] === value));
}
function updatePreview() {
  if (!previewCard) return;
  const link = previewCard.querySelector(`[data-page-link="${kind}"]`);
  frame.src = link.href;
  const name = previewCard.querySelector("h3").textContent;
  frame.title = `${name} ${kind === "landing" ? "landing page" : "README"} preview`;
  document.querySelector("#preview-title").textContent = name;
  document.querySelector("#open-preview").href = link.href;
  pressGroup("[data-preview-kind]", "previewKind", kind);
}
for (const button of document.querySelectorAll("[data-kind]")) {
  button.addEventListener("click", () => {
    kind = button.dataset.kind;
    document.body.classList.toggle("readme-priority", kind === "readme");
    pressGroup("[data-kind]", "kind", kind);
  });
}
for (const button of document.querySelectorAll("[data-preview]")) {
  button.addEventListener("click", () => {
    trigger = button;
    previewCard = button.closest(".collection-card");
    predictor?.record(previewCard.querySelector("h3").textContent.trim());
    updatePreview();
    dialog.showModal();
  });
}
for (const button of document.querySelectorAll("[data-preview-kind]")) {
  button.addEventListener("click", () => {
    kind = button.dataset.previewKind;
    updatePreview();
    document.body.classList.toggle("readme-priority", kind === "readme");
    pressGroup("[data-kind]", "kind", kind);
  });
}
for (const button of document.querySelectorAll("[data-size]")) {
  button.addEventListener("click", () => {
    const size = button.dataset.size;
    frame.classList.toggle("mobile-preview", size === "mobile");
    pressGroup("[data-size]", "size", size);
  });
}
function cleanupPreview() {
  if (!previewCard) return;
  frame.removeAttribute("src");
  previewCard = null;
  if (trigger?.isConnected) trigger.focus();
}
function closePreview() {
  dialog.close();
  cleanupPreview();
}
document.querySelector("#close-preview").addEventListener("click", closePreview);
dialog.addEventListener("cancel", (event) => {
  event.preventDefault();
  closePreview();
});
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && dialog.open) {
    event.preventDefault();
    closePreview();
  }
});
window.addEventListener("message", (event) => {
  if (dialog.open && event.source === frame.contentWindow && event.data === "moorkyz:close-preview") closePreview();
});
dialog.addEventListener("click", (event) => {
  if (event.target !== dialog) return;
  const bounds = dialog.getBoundingClientRect();
  if (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom) closePreview();
});
dialog.addEventListener("close", cleanupPreview);
