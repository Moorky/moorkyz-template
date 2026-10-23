import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { createRequire } from "node:module";
import { designs, documentationThemes } from "./catalog.mjs";

const { renderReadme, scopedPath } = createRequire(import.meta.url)("../moorkyz");
const escape = (value) => String(value).replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");
const decode = (value) => value.replaceAll("&quot;", '"').replaceAll("&gt;", ">").replaceAll("&lt;", "<").replaceAll("&amp;", "&");
const plain = (value) => decode(value.replace(/<[^>]*>/g, ""));
const slug = (value) => plain(value).toLowerCase().replace(/[^\p{L}\p{N}]+/gu, "-").replace(/^-|-$/g, "") || "section";
const key = (filename) => process.platform === "win32" ? filename.toLowerCase() : filename;

export function renderDocumentation({ markdown, theme = "paper", sourceName = "README.md", rewriteHref = (href) => href, links = [], adjacent = [], collectionId, scriptHref }) {
  const design = designs.find((item) => item.art === theme && documentationThemes.includes(theme));
  if (!design) throw new Error(`Unknown documentation theme '${theme}'. Choose ${documentationThemes.join(", ")}.`);
  const rendered = renderReadme(markdown).match(/<main>([\s\S]*?)<\/main>/);
  if (!rendered) throw new Error("README renderer did not return main content.");
  let content = rendered[1].trim();
  const titles = [...content.matchAll(/<h1>([\s\S]*?)<\/h1>/g)];
  if (titles.length > 1) throw new Error(`${sourceName}: use one H1 title and H2/H3 section headings.`);
  if (!titles.length) content = `<h1>${escape(path.basename(sourceName, path.extname(sourceName)))}</h1>\n${content}`;
  const title = plain(content.match(/<h1>([\s\S]*?)<\/h1>/)[1]);
  const used = new Set(["main"]);
  const headings = [];
  content = content.replace(/<h([1-3])>([\s\S]*?)<\/h\1>/g, (_, level, text) => {
    const base = slug(text);
    let id = base;
    for (let suffix = 2; used.has(id); suffix++) id = `${base}-${suffix}`;
    used.add(id);
    if (level === "2") headings.push({ id, text: plain(text) });
    return `<h${level} id="${escape(id)}">${text}</h${level}>`;
  });
  content = content.replace(/href="([^"]+)"/g, (_, encoded) => {
    const href = decode(encoded);
    const protocol = href.replace(/[\u0000-\u0020\u007f]/g, "");
    if (protocol.startsWith("//") || (/^[a-z][a-z0-9+.-]*:/i.test(protocol) && !/^(https?|mailto):/i.test(protocol))) {
      throw new Error(`${sourceName}: unsupported link protocol in '${href}'.`);
    }
    return `href="${escape(rewriteHref(href))}"`;
  });
  const sections = content.split(/(?=<h2\b)/);
  const intro = sections.shift();
  content = `<div class="doc-introduction">${intro}</div>` + sections.map((section) => `<section class="doc-section">${section}</section>`).join("\n");
  const outline = headings.map(({ id, text }) => `<a href="#${encodeURIComponent(id)}">${escape(text)}</a>`).join("");
  const navigation = (items) => items.map(({ href, label }) => `<a href="${escape(href)}">${escape(label)}</a>`).join("");
  const colors = ["bg", "surface", "ink", "muted", "accent"].map((name) => `--${name}:${design[name]}`).join(";");
  const styles = fs.readFileSync(new URL("./assets/documentation.css", import.meta.url), "utf8");
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="color-scheme" content="light"><title>${escape(title)}</title><style>${styles}</style>${scriptHref ? `<script src="${escape(scriptHref)}" defer></script>` : ""}</head>
<body class="documentation documentation-${theme}" data-documentation-theme="${theme}"${collectionId ? ` data-design="${escape(collectionId)}" data-kind="readme"` : ""} style="${colors};--line:color-mix(in srgb,var(--ink) 17%,transparent)"><a class="skip-link" href="#main">Skip to content</a>
<header class="document-header"><a class="document-label" href="#main">Documentation</a><span class="document-filename">${escape(sourceName)}</span>${links.length ? `<nav aria-label="Page navigation">${navigation(links)}</nav>` : ""}</header>
${outline ? `<details class="mobile-outline"><summary>On this page</summary><nav aria-label="Document sections">${outline}</nav></details>` : ""}
<main id="main" class="document-layout${outline ? "" : " without-outline"}">${outline ? `<aside class="document-outline"><p class="outline-label">On this page</p><nav aria-label="README chapters">${outline}</nav></aside>` : ""}<article class="doc-body" aria-label="Complete README">${content}</article></main>
${adjacent.length ? `<footer class="document-footer"><span>${escape(design.name)} / Documentation edition</span><nav aria-label="Adjacent designs">${navigation(adjacent)}</nav></footer>` : ""}</body></html>
`;
}

export function exportDocuments(args) {
  const usage = "node designs/build.mjs docs --theme paper --out html-docs [--check | --overwrite] file.md [more.md ...]";
  if (args.includes("--dry-run")) {
    console.log("Dry run: would render Markdown documentation. No source/config reads, outputs or directories changed.");
    return;
  }
  if (args.includes("--help")) {
    console.log(`${usage}\nThemes: ${documentationThemes.join(", ")}. Paths are relative to the current working directory.`);
    return;
  }
  const inputs = [];
  const options = { theme: "paper", out: null, check: false, overwrite: false };
  for (let index = 0; index < args.length; index++) {
    const arg = args[index];
    if (arg === "--") { inputs.push(...args.slice(index + 1)); break; }
    if (arg === "--check" || arg === "--overwrite") options[arg.slice(2)] = true;
    else if (arg === "--theme" || arg === "--out") {
      const value = args[++index];
      if (!value || value.startsWith("--")) throw new Error(`Missing value for ${arg}. Usage: ${usage}`);
      options[arg.slice(2)] = value;
    } else if (arg.startsWith("--")) throw new Error(`Unknown option '${arg}'. Usage: ${usage}`);
    else inputs.push(arg);
  }
  if (!options.out || !inputs.length) throw new Error(`An output directory and Markdown files are required. Usage: ${usage}`);
  if (options.check && options.overwrite) throw new Error("--check and --overwrite cannot be combined.");
  if (!documentationThemes.includes(options.theme)) throw new Error(`Choose a documentation theme: ${documentationThemes.join(", ")}.`);
  if (process.versions.node.split(".")[0] !== "24") throw new Error("Use Node.js 24 LTS.");
  const root = fs.realpathSync(process.cwd());
  const out = scopedPath(root, options.out, true);
  if (out === root) throw new Error("Choose a separate output subdirectory, not the project root.");
  if (fs.existsSync(out) && !fs.statSync(out).isDirectory()) throw new Error("The output path must be a directory.");
  const sources = inputs.map((input) => {
    const source = scopedPath(root, input);
    if (!/\.md$/i.test(source) || !fs.statSync(source).isFile()) throw new Error(`Expected a Markdown file: ${input}`);
    return source;
  });
  const outputs = new Map();
  const destinations = new Set();
  for (const source of sources) {
    const target = scopedPath(root, path.join(out, path.relative(root, source).replace(/\.md$/i, ".html")), true);
    if (destinations.has(key(target))) throw new Error(`Duplicate output for '${path.relative(root, source)}'.`);
    destinations.add(key(target));
    outputs.set(key(source), target);
  }
  const plans = sources.map((source) => {
    const target = outputs.get(key(source));
    let parent = path.dirname(target);
    while (!fs.existsSync(parent)) parent = path.dirname(parent);
    if (!fs.statSync(parent).isDirectory()) throw new Error(`Output parent is not a directory: ${parent}`);
    const html = renderDocumentation({
      markdown: fs.readFileSync(source, "utf8"), theme: options.theme, sourceName: path.relative(root, source).split(path.sep).join("/"),
      rewriteHref(href) {
        if (/^(?:[a-z][a-z0-9+.-]*:|#|\/)/i.test(href)) return href;
        const url = new URL(href, pathToFileURL(source));
        const linked = fileURLToPath(url);
        const destination = outputs.get(key(linked)) || linked;
        const relative = path.relative(path.dirname(target), destination).split(path.sep).map(encodeURIComponent).join("/");
        return relative + url.search + url.hash;
      },
    });
    const existing = fs.existsSync(target);
    if (existing) {
      const stat = fs.lstatSync(target);
      if (!stat.isFile() || stat.nlink !== 1) throw new Error(`Output is not an ordinary unshared file: ${target}`);
    }
    const unchanged = existing && fs.readFileSync(target, "utf8") === html;
    if (existing && !unchanged && !options.overwrite && !options.check) throw new Error(`Output differs: ${target}. Review it, then use --overwrite to replace only selected HTML files.`);
    return { target, html, existing, unchanged };
  });
  if (options.check) {
    const stale = plans.filter((plan) => !plan.unchanged);
    if (stale.length) throw new Error(`${stale.length} documentation output(s) missing or stale:\n${stale.map((plan) => path.relative(root, plan.target)).join("\n")}`);
  } else {
    for (const plan of plans) {
      if (plan.unchanged) continue;
      scopedPath(root, plan.target, true);
      fs.mkdirSync(path.dirname(plan.target), { recursive: true });
      fs.writeFileSync(plan.target, plan.html, { flag: plan.existing ? "w" : "wx" });
    }
  }
  console.log(`${options.check ? "Verified" : "Rendered"} ${plans.length} documentation page(s) with ${options.theme}. Markdown sources unchanged.`);
}
