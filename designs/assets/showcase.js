"use strict";
const cards = [...document.querySelectorAll(".collection-card")];
const search = document.querySelector("#design-search");
const count = document.querySelector("#result-count");
const empty = document.querySelector(".empty-state");
const filterButtons = [...document.querySelectorAll("[data-filter]")];
let category = "All";
let kind = "landing";
let previewCard = null;
const dialog = document.querySelector("#preview-dialog");
const frame = document.querySelector("#preview-frame");
let trigger = null;

function filter() {
  const query = search.value.trim().toLowerCase();
  let visible = 0;
  for (const card of cards) {
    card.hidden = !((category === "All" || card.dataset.category === category) && card.dataset.name.includes(query));
    if (!card.hidden) visible++;
  }
  count.textContent = `${visible} direction${visible === 1 ? "" : "s"} / ${visible * 2} pages`;
  empty.hidden = visible !== 0;
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
