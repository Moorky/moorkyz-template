import { cpSync, existsSync, lstatSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, extname, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const repository = fileURLToPath(new URL("../../", import.meta.url));
const publicExtensions = new Set([".html", ".css", ".js", ".svg", ".png", ".jpg", ".jpeg", ".webp", ".avif", ".ico", ".woff", ".woff2"]);

export function buildSite({ root = repository, output = resolve(root, "dist", "template-website"), commit = process.env.SOURCE_COMMIT } = {}) {
  if (!/^[a-f0-9]{40}$/.test(commit ?? "")) throw new Error("SOURCE_COMMIT must be the full 40-character Git commit SHA.");
  if (existsSync(output) && (lstatSync(output).isSymbolicLink() || readdirSync(output).length)) {
    throw new Error("The deployment output must be a new or empty directory; existing data will not be removed.");
  }
  const files = new Set(["index.html"]);
  function collect(relative, recursive) {
    for (const entry of readdirSync(resolve(root, relative), { withFileTypes: true })) {
      if (entry.name.startsWith(".")) continue;
      const name = `${relative}/${entry.name}`;
      if (entry.isSymbolicLink()) throw new Error(`Public source must not contain symbolic links: ${name}`);
      if (entry.isDirectory() && recursive) collect(name, true);
      else if (entry.isFile() && publicExtensions.has(extname(entry.name))) files.add(name);
    }
  }
  collect("website", false);
  collect("designs", true);

  let rewritten = 0;
  const contents = new Map();
  for (const name of files) {
    const source = resolve(root, name);
    if (!lstatSync(source).isFile() || lstatSync(source).isSymbolicLink()) throw new Error(`Invalid public source: ${name}`);
    if (extname(name) !== ".html") continue;
    const html = readFileSync(source, "utf8").replace(/(\s)(href|src)="([^"]+)"/g, (attribute, space, kind, value) => {
      const url = new URL(value, `https://static.invalid/${name}`);
      if (url.origin !== "https://static.invalid") return attribute;
      const target = decodeURIComponent(url.pathname).slice(1);
      const page = target.endsWith("/") || !target ? `${target}index.html` : target;
      if (files.has(page)) return attribute;
      if (kind === "src") throw new Error(`Unpublished asset in ${name}: ${value}`);
      if (publicExtensions.has(extname(target)) && target !== "README.html") {
        throw new Error(`Unpublished page or asset in ${name}: ${value}`);
      }
      // README editions link to repository documentation, not deployed application files.
      const view = target.endsWith("/") ? "tree" : "blob";
      rewritten += 1;
      return `${space}href="https://github.com/Moorky/moorkyz-template/${view}/${commit}/${url.pathname.slice(1)}${url.search}${url.hash}"`;
    });
    contents.set(name, html);
  }

  mkdirSync(output, { recursive: true });
  for (const name of files) {
    const destination = resolve(output, name);
    mkdirSync(dirname(destination), { recursive: true });
    if (contents.has(name)) writeFileSync(destination, contents.get(name));
    else cpSync(resolve(root, name), destination);
  }
  writeFileSync(resolve(output, "version.json"), `${JSON.stringify({ commit })}\n`);
  console.log(`PASS: packaged ${files.size} public files; ${rewritten} repository links point to GitHub at ${commit}.`);
  return { files, rewritten };
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) buildSite();
