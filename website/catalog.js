(() => {
  const controls = document.querySelector(".catalog-controls");
  const buttons = [...document.querySelectorAll("[data-view-filter]")];
  const styleFilter = document.querySelector("#style-filter");
  const cards = [...document.querySelectorAll(".template-card")];
  const status = document.querySelector("#result-count");
  let view = "all";

  function update() {
    document.body.dataset.view = view;
    buttons.forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.viewFilter === view));
    });
    let count = 0;
    cards.forEach((card) => {
      card.hidden = styleFilter.value !== "all" && card.dataset.style !== styleFilter.value;
      if (!card.hidden) count += 1;
    });
    status.textContent = view === "all"
      ? `${count} designs / ${count * 2} templates`
      : `${count} ${view === "readme" ? "README" : "Landing"} templates`;
  }

  buttons.forEach((button) => {
    button.addEventListener("click", () => {
      view = button.dataset.viewFilter;
      update();
    });
  });
  styleFilter.addEventListener("change", update);
  controls.hidden = false;
  for (const link of document.querySelectorAll("[data-viewer-href]")) link.href = link.dataset.viewerHref;
  document.querySelector("[data-year]").textContent = new Date().getFullYear();
})();
