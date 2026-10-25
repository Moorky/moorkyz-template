"use strict";
const cards = [...document.querySelectorAll(".collection-card")];
const search = document.querySelector("#site-search");
const searchForm = document.querySelector("[data-site-search]");
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
function setCategory(value) {
  if (!filterButtons.some((button) => button.dataset.filter === value)) return;
  category = value;
  for (const item of filterButtons) item.setAttribute("aria-pressed", String(item.dataset.filter === value));
}
function setKind(value) {
  if (!["landing", "readme"].includes(value)) return;
  kind = value;
  document.body.classList.toggle("readme-priority", kind === "readme");
  pressGroup("[data-kind]", "kind", kind);
}
// Collection links from the shared search on other pages: ?q=, ?style= and ?view=.
function applyParameters(params) {
  if (params.has("q")) search.value = params.get("q");
  if (params.has("style")) setCategory(params.get("style"));
  if (params.has("view")) setKind(params.get("view"));
  return filter();
}
for (const button of filterButtons) {
  button.addEventListener("click", () => {
    setCategory(button.dataset.filter);
    filter();
  });
}
search.addEventListener("input", filter);
searchForm.addEventListener("moorkyz:search-commit", (event) => {
  const target = new URL(event.detail.href, location.href);
  if (target.pathname !== location.pathname) return;
  event.preventDefault();
  if (!target.searchParams.has("q")) search.value = event.detail.value;
  if (applyParameters(target.searchParams) > 0) event.detail.record();
  window.MoorkyzSiteSearch?.refresh();
  document.querySelector("#collection").scrollIntoView({ block: "start", behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth" });
});
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
  button.addEventListener("click", () => setKind(button.dataset.kind));
}
const initial = new URLSearchParams(location.search);
if (["q", "style", "view"].some((name) => initial.has(name))) applyParameters(initial);
for (const button of document.querySelectorAll("[data-preview]")) {
  button.addEventListener("click", () => {
    trigger = button;
    previewCard = button.closest(".collection-card");
    window.MoorkyzSiteSearch?.record(previewCard.querySelector("h3").textContent.trim());
    updatePreview();
    dialog.showModal();
  });
}
for (const button of document.querySelectorAll("[data-preview-kind]")) {
  button.addEventListener("click", () => {
    setKind(button.dataset.previewKind);
    updatePreview();
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
