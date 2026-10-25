"use strict";
document.documentElement.classList.add("has-js");
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && !event.defaultPrevented && window.parent !== window) {
    window.parent.postMessage("moorkyz:close-preview", "*");
  }
});
const lightButton = document.querySelector(".light-toggle");
if (lightButton) {
  lightButton.addEventListener("click", () => {
    const enabled = lightButton.getAttribute("aria-pressed") !== "true";
    lightButton.setAttribute("aria-pressed", String(enabled));
    lightButton.querySelector("span").textContent = enabled ? "on" : "off";
    document.body.classList.toggle("light-disabled", !enabled);
  });
}
const reducedMotion = matchMedia("(prefers-reduced-motion: reduce)");
const finePointer = matchMedia("(pointer: fine)");
for (const surface of document.querySelectorAll("[data-light]")) {
  surface.addEventListener("pointermove", (event) => {
    if (reducedMotion.matches || !finePointer.matches || document.body.classList.contains("light-disabled")) return;
    const bounds = surface.getBoundingClientRect();
    const x = Math.max(0, Math.min(1, (event.clientX - bounds.left) / bounds.width));
    const y = Math.max(0, Math.min(1, (event.clientY - bounds.top) / bounds.height));
    surface.style.setProperty("--spot-x", `${x * 100}%`);
    surface.style.setProperty("--spot-y", `${y * 100}%`);
    surface.style.setProperty("--turn", `${160 + x * 140}deg`);
    surface.style.setProperty("--rx", `${(0.5 - y) * 7}deg`);
    surface.style.setProperty("--ry", `${(x - 0.5) * 9}deg`);
    surface.style.setProperty("--brightness", String(0.94 + (1 - y) * 0.14));
  });
  surface.addEventListener("pointerleave", () => {
    for (const key of ["--spot-x", "--spot-y", "--turn", "--rx", "--ry", "--brightness"]) surface.style.removeProperty(key);
  });
}
