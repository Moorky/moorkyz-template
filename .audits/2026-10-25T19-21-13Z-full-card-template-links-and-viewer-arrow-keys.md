# Full-card template links and viewer arrow keys

| Field | Value |
|---|---|
| Audit ID | `2026-10-25T19-21-13Z-full-card-template-links-and-viewer-arrow-keys` |
| Created (UTC) | 2026-10-25T19:21:13.492Z |
| Auditor | Copilot SDK session 8aefbe87-2824-436b-a26b-dd2170988306; self-audit |
| Baseline commit | `9b6cc2f3eaa7a08423828c594e56a5b6b63ba7b3` |
| Outcome | `PASS WITH RISKS`: requested local behavior verified; human review and publication not performed |

## Request and outcome

- Requested behavior: make the entire template card clickable. Follow-up:
  physical arrow keys must navigate the design viewer, not only arrow buttons.
- Implemented behavior: existing native links cover the card; All designs and
  Landing open the landing page, README opens its README edition. Explicit
  page-type links remain separate. Left/Right reuse the existing viewer buttons,
  including filtering, wrapping, history and same-origin iframe focus.
- Initial Git state: modified scheduler and six design files (`designs/README.md`,
  `designs/assets/showcase.js`, `designs/assets/site-search.js`, `designs/build.mjs`,
  `designs/index.html`, `designs/verify.mjs`); two untracked earlier audits,
  `.vscode/` and `TEMPLATE_INTRODUCTION.md`. All preserved and excluded from
  staging. Only this task's scheduler additions are eligible for staging.
- Intentional exclusions: no showcase redesign, generated-page edits, new
  dependencies, deployment, push, other queue claims or unrelated repairs.

## Analyzing and Reading

- Read [agent contract](../AGENTS.md), [queue](../AGENT_SCHEDULER.md),
  [contribution workflow](../CONTRIBUTING.md), root README, tool catalog,
  maintenance guide, audit skill/template, website generator, catalog CSS/JS,
  viewer JS, website guide and verifier; checked existing showcase key handling.
- Acceptance: every card surface opens the correct type at desktop/mobile widths;
  explicit README/Landing links, keyboard activation and no-JS browsing remain
  functional. Left/Right work in the viewer and after iframe navigation; search,
  selectors, editable fields, composing/handled/modified keys retain their behavior.
  Empty/single results cannot navigate; desktop filters survive mobile resizing.
- Baseline reproduction in the integrated Chromium browser: a card preview
  hit-test returned no anchor; ArrowRight left the initial iframe source unchanged.
- Windows; default Node 22.18.0 is unsupported for maintenance. Used the existing
  Node 24.22.0 installation on command-local PATH and PowerShell 7.6.6, without
  changing system PATH or installing dependencies.
- Coordination approval question returned owner unavailable with instruction to
  choose pragmatically. Recorded this bounded follow-up; preserved the other
  sessions' active viewer/deployment/introduction claims and all dirty work.

## Researching and Planning

- Reused existing native anchors, data-kind view selectors, focus styling,
  viewer previous/next destinations and their click handler. Existing generated
  markup already contains every needed anchor; regeneration is unnecessary.
- CSS stretches the active anchor's pseudo-element across its positioned,
  isolated card; the independent README link remains above the landing overlay.
  No nested anchors, duplicate links, click-only article roles or JS redirect.
- Viewer key handling calls the appropriate existing link only when enabled.
  Binds both the initial iframe document and subsequent load documents, avoiding
  a cached/already-loaded iframe race. Cross-origin documents are not accessed.
- Planned focused VM/static regressions, real Chromium hit tests and keyboard
  tests, mandatory maintenance, final references, self-review, audit and local commit.
- Existing browser runtime: Playwright Core 1.64.0 and installed Chromium, used
  only for disposable local acceptance checks. No new application tooling.
  No external actions were needed or authorized by this follow-up.

## Developing

- Added four CSS rules for positioned cards, primary-link overlay, secondary-link
  stacking and full-card focus indication; preserved existing filtering and layout.
- Added one guarded key handler and one iframe binding helper. Editing controls,
  semantic text/combobox/slider widgets, composition, handled keys and modifiers
  are excluded; vertical arrows retain scrolling.
- Extended [website verification](../website/verify.mjs) with overlay/focus
  invariants, initial/reloaded iframe events, wrapping, editing/modifier guards,
  mobile navigation and single/empty filtered-result cases.
- Updated [website guide](../website/README.md) with card defaults, native-link
  behavior, arrow shortcuts and the same-origin boundary.
- During self-review, covered the already-loaded iframe race explicitly.
  No unrelated product behavior or generated output changed.

| Path | Change | Risk |
|---|---|---|
| [catalog.css](../website/catalog.css) | Stretch existing links without changing DOM or tab order | Overlay stacking; checked 1,080 browser hit points and explicit CTA centers |
| [viewer.js](../website/viewer.js) | Parent and iframe Left/Right handlers reuse existing navigation | Editable controls and iframe lifecycle; unit and browser checks |
| [verify.mjs](../website/verify.mjs) | Focused CSS/VM regression coverage | No dependencies or live fixtures |
| [website guide](../website/README.md) | Document click and keyboard behavior | Local links checked |
| [queue](../AGENT_SCHEDULER.md), this audit | Scoped claim and completion evidence | Only task-owned scheduler additions staged |

## Clean Up

### Verification

Commands run from the repository root with existing Node 24.22.0 first on the
command-local PATH. Browser test script lived only in this session's files area.

| Check | Result | Command / evidence |
|---|---|---|
| Full maintenance | PASS | `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause`: 8 passed, 0 failed |
| Catalog/viewer regression | PASS | `node .\website\verify.mjs`: 20 designs, 40 pages, 48 catalog links/anchors, 18 filter combinations, 40 viewer selections; added keyboard/iframe/guard cases pass |
| Syntax | PASS | `node --check .\website\viewer.js`; final runnable check also covers the verifier |
| Public packaging regressions | PASS; one platform skip | `node --test .\website\deploy\build.test.mjs`: 2 passed, 0 failed; symlink test intentionally skipped on Windows, covered by existing Linux CI |
| Real Chromium acceptance | PASS | `node <session>\files\verify-template-navigation.cjs` with existing Playwright Core selected by `MOORKYZ_PLAYWRIGHT_CORE`: 1,080 hit points, all 20 cards / 3 views / 375, 768, 1440 px, independent CTA centers, native pointer/Enter activation, 40 arrow transitions and both wraps, iframe/reload/editing guards, filtered/single/empty results, real mobile resize/filter restoration, real JavaScript-disabled fallback; no page errors |
| Integrated browser acceptance | PASS with harness limitations superseded | Initial symptom reproduced, 1,080 card hit points and desktop/mobile iframe navigation pass. Hidden integrated page delayed resize media events; separate Chromium verified actual resize. New no-JS context rejected by integrated affinity restriction; disposable standalone Chromium context verified real no-JS browsing instead |
| Browser harness corrections | RESOLVED | Awaited native Enter navigation, then reset the selector after its native ArrowRight selection change; final isolated acceptance passes. No product workaround needed |
| Container HTTP verification | N/A for this change; initial attempt failed prerequisite | `node .\website\deploy\verify.mjs` encountered `ECONNREFUSED 127.0.0.1:8080`: no local deployment container was running. This checks deployment health/headers, not changed card/key behavior; packaging regressions pass, and no deployment/HTTP-health claim is made |
| Dependency audit | N/A | No manifest, dependency or lockfile changed; no package install |
| Whitespace | PASS | `git diff --check -- website\catalog.css website\viewer.js website\verify.mjs website\README.md AGENT_SCHEDULER.md`; staged check required before commit |
| Final runnable recheck | PASS | `pwsh -NoProfile -File .\.template\maintenance\helpers\checkups\01-runnables.ps1`: final JavaScript syntax, PowerShell parsing and safe modes pass |
| Final documentation recheck | PASS | `pwsh -NoProfile -File .\.template\maintenance\helpers\checkups\02-documentation.ps1`: exact-case local Markdown/HTML links, README freshness and tool/runtime/CI references pass after audit and queue closure |

### Quality and safety review

- Self-review: inspected the entire task-owned implementation diff and staged
  queue addition; the staged implementation matches the reviewed files. Reused existing links,
  click navigation, filtered destinations and URL/history behavior; no parallel
  selection algorithm, dependency, dead code or unnecessary configuration.
- Tests cover overlay stacking and original CTA destinations, no-JS fallback,
  focus indication, iframe load/reload/initial availability, composition,
  modifiers, prevented keys, input/textarea/select/contenteditable/widget guards,
  invalid routes, empty/single results and desktop/mobile filtering.
- Corrected the initial/already-loaded iframe binding race before final tests.
  Native selector arrows continue changing the select value, not the preview.
- Security/secrets self-review: no credentials, external messages, dynamic HTML,
  remote requests, filesystem actions or unvalidated destinations added.
  Existing generated local links remain the only navigation destinations;
  iframe document access is limited by the browser's same-origin policy.
- Independent review: not requested, not performed. Human review: pending,
  optional for this local follow-up; no required approval remains outstanding.
- Residual limitation: arrow shortcuts inside a cross-origin iframe are
  intentionally unavailable; parent-toolbar arrows/shortcuts remain usable.
  Manual human UX review and production publication are not implied by tests.

### Final references and documentation

| Reference / content | Availability / validity | Command / source / evidence and impact |
|---|---|---|
| CSS selectors and data attributes | PASS | Generated card markup has both page-type links; VM checks, all-card browser hit tests and focused verifier |
| Viewer handlers and iframe consumers | PASS | Existing link click handler, enabled hrefs, history and iframe contentDocument/closest/event APIs exercised in Chromium and VM tests |
| Local docs/assets/anchors and exact path casing | PASS | Website verifier, existing full maintenance documentation check and final affected documentation rerun |
| Generated pages | PASS; unchanged | `node .\website\verify.mjs` confirms root index and viewer match the existing generator |
| Changed external references | N/A | No external link or version-specific API claim introduced; unrelated footer/domain/deployment state left unchanged |

- No unavailable content blocks the requested behavior. Full container HTTP
  verification lacked a running deployment container and is explicitly excluded
  from this local UI follow-up; no deployment configuration was modified.
- Website guide and only this request's queue evidence updated. Canonical README
  and generated outputs are unchanged, so README/design regeneration is N/A.
- Disposable browser contexts and loopback test server close in finally blocks.
  Session-only acceptance harness is removed after the final successful run;
  existing user data, installed runtimes and unrelated files remain untouched.
- Final source regression, syntax and local-reference checks cover the completed
  code, docs, audit and queue closure. Required staged whitespace/scope review
  occurs immediately before the focused local commit.

### Completion

- Commit: `PENDING` (report the hash; do not edit this audit afterwards)
- Staged scope and `git diff --cached --check`: PASS; exactly four website files,
  this audit and one added scheduler ledger row. Existing unrelated scheduler
  edits remain unstaged. Final staged content and whitespace checked again before commit.
- Human review: pending
- Required checks pass; release only this task's implementation claim with the
  focused commit. Other sessions' active or blocked tasks remain unchanged.
- External actions: no push, merge, PR, deployment, DNS, credential or account changes.

A generated draft is not verification evidence and a self-audit is not an
independent security review.
