# Static template catalog

Open [the website](../index.html) directly in a browser, or serve the repository
with any static file server. No package install, application runtime or build
step is needed to browse the committed website.

The catalog covers all twenty [designs](../designs/README.md), with a README
edition and a landing page for each. **Design** is the category; **README** and
**Landing** select the page type. Style filtering combines with either view.
Five documentation-first README editions have a **Compact README** badge.
All forty template links remain available when JavaScript is disabled.

The header uses the Moorkyz mark and restrained dark chrome; the footer keeps
the `made /w [mark] © year Moorkyz` house style and a visible link to
[moorky.com](https://moorky.com). External links navigate only when activated;
they do not fetch assets or track visitors. There are intentionally no
Impressum, privacy or other legal navigation links. No external fonts,
analytics, dependencies, storage or remote requests are used. The viewer embeds
only the local template pages.

## Opening a template

With JavaScript enabled, catalog links open the [template viewer](viewer.html).
The desktop view has two full-height panels: a 300 px sidebar and the remaining
space for a live iframe. The sidebar contains search, a template selector, an
icon that opens the page-type filter (all, landing pages or README editions),
and a scrollable vertical list of all forty entries. These filters combine;
an empty result is explained without replacing the selected preview.

At 900 px and below the sidebar is hidden. `<<` and `>>` browse all forty entries,
wrapping at either end. Desktop arrows browse the filtered entries instead.
Changing the viewport does not discard desktop filter choices. **Full View** in
the top-right opens the selected template directly in a new tab, without the
viewer.

Selections update the URL (`viewer.html?template=02-paper&kind=readme`), so links,
reload and browser Back/Forward restore the selected template. Only generated
catalog entries can be loaded; unknown template or type parameters show an
explicit error. Sidebar filters are temporary page state and are not stored.
Without JavaScript, catalog and viewer-list links open the actual pages
directly; the viewer explains that its interactive controls need JavaScript.

## Editing and verification

- [build.mjs](build.mjs) reads the existing [design catalog](../designs/catalog.mjs)
  and generates [index.html](../index.html) and [viewer.html](viewer.html); it never rebuilds or edits the
  separate design showcase or template pages.
- [catalog.css](catalog.css) owns the responsive layout and schematic template
  illustrations. These are illustrative previews, not screenshots; card links
  open the interactive viewer, with direct-template fallbacks without JavaScript.
- [catalog.js](catalog.js) progressively enables type/style controls and updates
  their pressed states, live result count and footer year. It uses no network or
  persistence APIs.
- [viewer.css](viewer.css) provides the full-height sidebar/iframe layout and
  mobile controls. [viewer.js](viewer.js) manages combined filters, selection,
  previous/next navigation and browser history. Search normalization reuses the
  existing local predictive-search helper; no extra dependency is installed.
- [verify.mjs](verify.mjs) checks generated freshness, complete catalog coverage,
  local links and anchors, compact badges, legal-link exclusion and the control
  state combinations.

From the repository root:

```powershell
node .\website\build.mjs
node .\website\verify.mjs
pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause
```

Use Node.js 24 LTS for repository tooling. Static hosting must retain the relative
paths between the catalog, viewer and design assets. Publish only public files,
not the entire repository, local configuration or deployment tooling.
The [deployment package](deploy/README.md) targets `template.moorkyz.com` on
Hetzner/Coolify with Cloudflare DNS and includes GitHub container checks.
Production access, DNS, TLS and the remote GitHub integration still require
configuration and live verification; the package alone does not deploy the site.
