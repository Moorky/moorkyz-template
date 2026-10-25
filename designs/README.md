# Moorkyz Templates

**20 original design directions. 20 complete README editions. 20 landing pages.
One final template showcase.**

The website showcases completed template designs, not a tools or services
offering. Its public name is **Moorkyz Templates**. Showcase and landing copy,
decorative artwork and search suggestions focus on the actual collection.
README editions retain the complete technical repository documentation as
sample content; those instructions are documentation, not advertised products.

Open [the collection](index.html) directly in a modern browser. No server,
package installation, account, API key or internet connection is needed for
the collection itself. External repository links need connectivity.

To open every HTML page in this folder (recursively) in the default browser,
run `pwsh -NoProfile -File .\designs\OpenAll.ps1`. Add `-DryRun` to list the
files without opening them.

The canonical [root README](../README.md) and its [HTML edition](../README.html)
remain the baseline documentation. These are additional visual editions, not
replacements, product runtimes or deployment configuration.

## Five everyday documentation themes

Five of the twenty README editions are deliberately **compact documentation
themes**, not miniature landing pages. They have small headers, immediate
content, restrained section navigation, readable code and print styles.
No hero artwork, marketing blocks, light controls or motion compete with the
documentation. The twenty landing pages and fifteen expressive README editions
keep their original visual layouts.

| Theme | Best fit | Preview |
|---|---|---|
| `paper` | Warm, quiet editorial notes; serif headings | [Paper README](02-paper/README.html) |
| `glacier` | Clean blue-white guides; subtle content surface | [Glacier README](07-glacier/README.html) |
| `mono` | Crisp, neutral technical references | [Mono README](08-mono/README.html) |
| `vector` | Ordered engineering documentation; restrained teal | [Vector README](15-vector/README.html) |
| `cabinet` | Polished file-by-file reference; warm indexed navigation | [Cabinet README](18-cabinet/README.html) |

Choose one theme and use it for every document in a project. The existing
generator can render multiple Markdown files in one invocation:

```powershell
node .\designs\build.mjs docs --theme paper --out html-docs README.md docs\INFRASTRUCTURE.md .template\copilot-settings\README.md
```

For a documentation folder containing twenty files (or any other number):

```powershell
$files = @(Get-ChildItem -LiteralPath .\docs -Filter *.md -File -Recurse | ForEach-Object { $_.FullName })
node .\designs\build.mjs docs --theme paper --out html-docs @files
```

Run from the project root with Node.js 24 LTS. Paths must stay inside that
working directory; symlinks/junctions are refused. Outputs preserve source
subdirectories, so different files named `README.md` do not collide.
Selected Markdown links become links to their generated HTML counterparts;
unselected local links point back to the original files. Other assets are not
copied. Source files are never changed.

Exported HTML embeds its stylesheet and needs no JavaScript, framework, font,
server or shared asset folder. Copying an HTML file elsewhere still requires
reviewing its links to other documents/assets. The command uses the existing
lightweight root Markdown renderer: headings, paragraphs, fenced/inline code
and links, not full CommonMark; lists/tables keep the baseline text rendering.

An identical rerun leaves files alone. Different existing output is refused
before any writes; review it and explicitly add `--overwrite` to regenerate
only the selected HTML files. `--check` verifies without writing; `--dry-run`
does not read source/config files or create anything. No output directory may
be the project root. Use `docs --help` for the command summary.

## Browse and use

- Every one of the 41 pages has the same search bar in its header: identical
  markup, size (40 px high, at most 420 px and never more than 66.67% of the
  header), 14 px type, icon, keyboard behavior and suggestion list. Colors come
  from each page's verified palette tokens, so light and dark editions keep their
  contrast. Below 1,180 px (compact documentation: 960 px) it moves to its own
  header row; on phones it sits above the page links.
- Suggestions come from one generated local index,
  [search-index.js](assets/search-index.js): the twenty designs and their
  character phrases, styles, tones and page files, the README chapters, the
  collection guide, page-view settings and the workspace
  vocabulary in [search-dictionary.json](search-dictionary.json) (project name,
  the Moorkyz location `Karlsruhe`, view settings). Edit that dictionary for an
  adopted project; `build.mjs` refuses unknown fields, duplicates and `href`
  values that are not existing relative paths.
- A matching prefix appears as subtle inline ghost text (`mid` + `night blue`);
  typos, missing letters, phrases and abbreviations appear as
  `typed → Suggestion` (`KLSE → Karlsruhe`), with alternatives in a compact
  list. `Tab` or `ArrowRight` (caret at the end) accepts the inline suggestion,
  `ArrowDown`/`ArrowUp` browse alternatives, `Enter` confirms the highlighted
  one and `Escape` dismisses. The typed text is never replaced without one of
  these explicit actions or a click on a suggestion. Accepting only fills the
  field.
- `Enter` on an accepted or typed value then acts: a design opens its page of the
  current type, a chapter jumps to that heading (on a README page) or opens it, a
  collection guide opens its document, and a style, tone or view setting opens the
  filtered collection. Anything else searches the collection
  (`index.html?q=…#collection`); on the showcase this filters in place. The
  showcase also accepts `?q=`, `?style=` and `?view=landing|readme`.
- Ranking runs locally in [predictive-search.js](assets/predictive-search.js):
  exact and prefix matches, normalized matching, weighted edit distance with
  keyboard-adjacency, transposition and missing-letter costs, acronyms and
  abbreviations, then context and recency. The current design's style and tone,
  the page type and the active style filter act as workspace context; accepted,
  confirmed and previewed values become recent values for the current page
  session only (no storage, network or tracking). Results are cached;
  dictionaries above 1,500 entries show immediate prefix suggestions and debounce
  the fuzzy pass. A page may define `globalThis.MoorkyzSearchRemote(query,
  { signal, context })` before [site-search.js](assets/site-search.js) runs to
  add optional semantic suggestions after local ones; none is configured.
- Filter the showcase by Quiet, Cosmic, Chromatic, Editorial or Systematic.
  Matching ignores case, accents and punctuation and also covers page filenames
  such as `01-aether/landing.html`.
- Each direction contains `README.html` and `landing.html`. Both open directly.
  The showcase offers a live preview, README/landing tabs, Wide/Mobile viewport
  controls and a direct-page link. Escape closes the preview.
- The page-type switch prioritizes the corresponding links and preview type;
  card artwork is an illustrative design thumbnail, not a screenshot of a README.
- Every README includes the complete current root documentation, usable chapter
  navigation, code samples and root-relative links rewritten for its directory.
- All landing pages showcase their finished template design and matching README.
  They link to collection pages and the template source, not internal utilities.
  No customer counts,
  testimonials, pricing, uptime, application services or deployment destinations
  are invented. The advertised 20/20/40+1 counts are verified from real files.
- To reuse a page, copy its numbered directory and the adjacent `assets`
  directory, keeping their relative layout. Review project-specific copy and
  repository/documentation links. Full README editions intentionally link back
  into this repository; rewrite those links if exporting elsewhere.
- Ambient light reacts gently to a fine pointer's position and angle on
  decorative artwork. The page-level toggle disables the effect.
  Reduced-motion preferences disable perspective changes; there are no flashing
  animations, auto-playing video, trackers, webfonts or third-party assets.
- Without JavaScript, all 41 pages and their direct navigation remain usable.
  Search, filtering, live preview and light controls are progressive
  enhancements; the inactive search bar stays hidden. Standalone `docs` exports
  contain no search, script or stylesheet link.

## Twenty directions

| Direction | Character | README | Landing |
|---|---|---|---|
| Aether | Midnight orbital space | [Read](01-aether/README.html) | [Open](01-aether/landing.html) |
| Paper | Quiet ivory editorial | [Read](02-paper/README.html) | [Open](02-paper/landing.html) |
| Blueprint | Measured technical grid | [Read](03-blueprint/README.html) | [Open](03-blueprint/landing.html) |
| Prism | Pearlescent refraction | [Read](04-prism/README.html) | [Open](04-prism/landing.html) |
| Terminal | Honest monospaced workspace | [Read](05-terminal/README.html) | [Open](05-terminal/landing.html) |
| Dune | Warm sculpted earth | [Read](06-dune/README.html) | [Open](06-dune/landing.html) |
| Glacier | Airy ice-blue planes | [Read](07-glacier/README.html) | [Open](07-glacier/landing.html) |
| Mono | Strict black-and-white typography | [Read](08-mono/README.html) | [Open](08-mono/landing.html) |
| Bloom | Soft lilac modularity | [Read](09-bloom/README.html) | [Open](09-bloom/landing.html) |
| Obsidian | Dark copper restraint | [Read](10-obsidian/README.html) | [Open](10-obsidian/landing.html) |
| Atlas | Topographic field notes | [Read](11-atlas/README.html) | [Open](11-atlas/landing.html) |
| Signal | Cobalt and orange clarity | [Read](12-signal/README.html) | [Open](12-signal/landing.html) |
| Nocturne | Violet waveform space | [Read](13-nocturne/README.html) | [Open](13-nocturne/landing.html) |
| Solstice | Warm balanced sunlight | [Read](14-solstice/README.html) | [Open](14-solstice/landing.html) |
| Vector | Connected process geometry | [Read](15-vector/README.html) | [Open](15-vector/landing.html) |
| Halo | Bright orbital calm | [Read](16-halo/README.html) | [Open](16-halo/landing.html) |
| Flux | Angle-sensitive chromatic ribbon | [Read](17-flux/README.html) | [Open](17-flux/landing.html) |
| Cabinet | Carefully indexed archival paper | [Read](18-cabinet/README.html) | [Open](18-cabinet/landing.html) |
| Liminal | Quiet dimensional architecture | [Read](19-liminal/README.html) | [Open](19-liminal/landing.html) |
| Continuum | Violet-orange eclipse horizon | [Read](20-continuum/README.html) | [Open](20-continuum/landing.html) |

Compositions, typography, artwork, documentation layouts and section treatments
vary, not merely the color tokens. Light/quiet directions intentionally balance
the more expressive cosmic/chromatic ones.

## Regenerate and verify

Use Node.js 24 LTS. No package manifest or dependencies are required.

```powershell
node .\designs\build.mjs
node .\designs\build.mjs --check
node .\designs\verify.mjs
```

[catalog.mjs](catalog.mjs) defines the twenty directions. [build.mjs](build.mjs)
uses the existing root CLI README renderer, adds full-document layouts and
generates exactly 41 HTML pages plus the search index. [search.mjs](search.mjs)
holds the shared search markup and index generation. Rebuild after changing the
canonical README, the catalog or the search dictionary.
`--check` is read-only and fails for stale output; `--dry-run` performs no file
reads or writes. Shared visual assets live in [assets](assets/).

The [verification script](verify.mjs) checks page counts, unique directions,
generated freshness, chapter completeness, links/anchors, local-only assets,
landmarks, palette contrast, the public website name and template-only marketing.
Browser checks additionally cover every page
at desktop/mobile sizes, reduced motion, no-JavaScript access and gallery
interactions. Automated checks do not replace human visual/accessibility review.
The regular maintenance runner discovers the read-only
[design checkup](../.template/maintenance/helpers/checkups/06-design-collection.ps1).
If an adopted project removes this optional collection, remove that checkup
with it rather than leaving a broken verification reference.
Its [documentation regressions](verify-documentation.mjs) render twenty source
files in each of the five compact themes (100 real outputs), entirely in
disposable directories. They check source preservation, nested links/anchors,
standalone styling, unchanged reruns, check/dry-run modes and refusal of unsafe
inputs or conflicting outputs.
Its [predictive-search regressions](verify-predictive-search.mjs) cover the
`KLSE` → `Karlsruhe` acceptance case against the shipped workspace index,
dictionary validation, typo/accent/phrase/alias handling, context and recency
ranking, caching and a 5,001-entry responsiveness budget. The main verification
also requires the identical header search and its assets on all 41 pages.
Browser keyboard, focus and layout behavior still needs browser checks.

## Reference study

The work uses original CSS geometry and original copy, not copied layouts,
source code, logos, fonts, screenshots or other site assets.

| Public reference explored before implementation | Design observations |
|---|---|
| [Moorkyz](https://moorkyz.com/) | Orbital navigation, restrained midnight gradients and illuminated panel edges; explored About, Services, Projects, Career, Contact and Legal panels |
| [The Dot](https://thedot.moorkyz.com/) and [More](https://thedot.moorkyz.com/more) | Dark-violet negative space, tiny stars, quiet chroma and restrained mono controls; inspected public information tabs, not authenticated gameplay |
| [Moorkyz Cards](https://cards.moorkyz.com/), [designer](https://cards.moorkyz.com/try), membership, claim, sign-in and public legal pages | Light editorial scale, tactile preview surfaces, generous spacing and selective purple accents |
| [Video Transcriptor](https://transcriptor.moorkyz.com/) | Disciplined workspace rail, numbered steps, dark slate panels, fine rules and clear boundaries; inspected its access/video/review/method/privacy sections without entering credentials or uploading data |
| [Moorkyz AI](https://ai.moorkyz.com/), [project collection](https://ai.moorkyz.com/projects), capabilities and all ten linked project pages | Purple-white typography, diagrammatic geometry, clear experiment/control hierarchy and small worlds expressed with a few precise shapes |

The supplied `https://moorkyz.com/cards` returned 404; the live Cards destination
was discovered through Moorkyz's Projects panel. Some initial browser loads
failed and succeeded on retry. The Dot reports accounts unavailable and a 401
for account access; no account, private page or remote state was accessed.
