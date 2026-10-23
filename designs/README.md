# The foundation collection

**20 original design directions. 20 complete README editions. 20 landing pages.
One final template showcase.**

Open [the collection](index.html) directly in a modern browser. No server,
package installation, account, API key or internet connection is needed for
the collection itself. External repository links need connectivity.

The canonical [root README](../README.md) and its [HTML edition](../README.html)
remain the baseline documentation. These are additional visual editions, not
replacements, product runtimes or deployment configuration.

## Browse and use

- Search by name or descriptive terms; filter Quiet, Cosmic, Chromatic,
  Editorial or Systematic.
- Each direction contains `README.html` and `landing.html`. Both open directly.
  The showcase offers a live preview, README/landing tabs, Wide/Mobile viewport
  controls and a direct-page link. Escape closes the preview.
- The page-type switch prioritizes the corresponding links and preview type;
  card artwork is an illustrative design thumbnail, not a screenshot of a README.
- Every README includes the complete current root documentation, usable chapter
  navigation, code samples and root-relative links rewritten for its directory.
- All landing pages promote the actual Moorkyz template. No customer counts,
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
  Search, filtering, live preview and light controls are progressive enhancements.

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
generates exactly 41 HTML pages. Rebuild after changing the canonical README.
`--check` is read-only and fails for stale output; `--dry-run` performs no file
reads or writes. Shared visual assets live in [assets](assets/).

The [verification script](verify.mjs) checks page counts, unique directions,
generated freshness, chapter completeness, links/anchors, local-only assets,
landmarks and palette contrast. Browser checks additionally cover every page
at desktop/mobile sizes, reduced motion, no-JavaScript access and gallery
interactions. Automated checks do not replace human visual/accessibility review.
The regular maintenance runner discovers the read-only
[design checkup](../.template/maintenance/helpers/checkups/06-design-collection.ps1).
If an adopted project removes this optional collection, remove that checkup
with it rather than leaving a broken verification reference.

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
