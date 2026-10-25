import assert from "node:assert/strict";
import { designs } from "../../designs/catalog.mjs";

const base = new URL(process.argv[2] ?? "http://127.0.0.1:8080");
assert.ok(["http:", "https:"].includes(base.protocol), "An HTTP(S) origin is required.");
assert.equal(base.pathname, "/", "Use the website origin without a path.");
const expected = process.env.EXPECTED_COMMIT;
if (expected !== undefined) assert.match(expected, /^[a-f0-9]{40}$/);

async function get(path) {
  return fetch(new URL(path, base), { redirect: "error", signal: AbortSignal.timeout(15000), headers: { "Cache-Control": "no-cache" } });
}

const health = await get("/healthz");
assert.equal(health.status, 200, "Health endpoint must be available.");
assert.equal(await health.text(), "ok\n");
const version = await get(`/version.json?verify=${Date.now()}`);
assert.equal(version.status, 200);
const { commit } = await version.json();
assert.match(commit, /^[a-f0-9]{40}$/);
if (expected) assert.equal(commit, expected, "The deployed revision differs from the requested Git commit.");

const templates = designs.flatMap(({ id }) => [`/designs/${id}/README.html`, `/designs/${id}/landing.html`]);
const queue = ["/", "/website/viewer.html", "/designs/index.html", ...templates];
const seen = new Set();
const pages = new Set();
for (let index = 0; index < queue.length; index += 1) {
  const path = queue[index];
  if (seen.has(path)) continue;
  seen.add(path);
  const response = await get(path);
  assert.equal(response.status, 200, `${path} must return 200.`);
  assert.equal(response.headers.get("x-content-type-options"), "nosniff");
  assert.equal(response.headers.get("x-frame-options"), "SAMEORIGIN", "The same-origin viewer must remain embeddable.");
  assert.equal(response.headers.get("cache-control"), "no-cache");
  const type = response.headers.get("content-type") ?? "";
  if (!type.includes("text/html")) continue;
  const pathname = new URL(path, base).pathname;
  pages.add(pathname.endsWith("/") ? `${pathname}index.html` : pathname);
  const html = await response.text();
  for (const match of html.matchAll(/\s(?:href|src)="([^"]+)"/g)) {
    const url = new URL(match[1].replaceAll("&amp;", "&"), new URL(path, base));
    if (url.origin === base.origin) queue.push(url.pathname + url.search);
  }
}
assert.ok(pages.size >= templates.length + 3, `Expected the catalog, viewer, showcase and every template; received ${pages.size} HTML pages.`);
for (const path of ["/.git/config", "/.env", "/.moorkyz/state.json", "/website/deploy/Dockerfile", "/website/build.mjs", "/designs/catalog.mjs", "/README.md", "/AGENTS.md", "/missing.html"]) {
  const response = await get(path);
  assert.equal(response.status, 404, `${path} must not be served.`);
}
console.log(`PASS: ${pages.size} distinct HTML pages and ${seen.size} public routes; health, revision ${commit}, security/cache headers, same-origin frames and nine private/missing routes.`);
