# Uniform predictive search on every design page

| Field | Value |
|---|---|
| Audit ID | `2026-10-25T03-04-38Z-uniform-predictive-search-on-every-design-page` |
| Created (UTC) | 2026-10-25T03:04:38.632Z |
| Auditor | Copilot SDK session 7c17b682-cac5-4fdf-ad2e-75afa30b907f (self-audit) |
| Baseline commit | `a3d7387` (Add predictive autocomplete to the design search) |
| Outcome | `PASS WITH RISKS` |

## Request and outcome

- Requested behavior and confirmed decisions: owner (2026-10-25T02:42Z), "Fix it already and have the searchbar uniform everywhere", repeating item 10 (REQ-SEARCH-UNIFORM-022). Same acceptance: `KLSE` can produce `Karlsruhe` with supporting context/dictionary and one keystroke accepts; ghost text, compact alternatives, `Tab`/`ArrowRight`, `ArrowUp`/`ArrowDown`, `Enter`, never replacing input without acceptance; width at most 66.67%; 100-180 ms opacity; keyboard, screen-reader and reduced-motion support; local-first, cached, optional remote. Owner unavailable (autopilot): "everywhere" = all 41 pages of the design collection; recent values stay in page memory (existing no-storage rule).
- Reproduced defects before the change (integrated Chromium, `designs/index.html`): typing `KLSE` gave no ghost text or list and `Tab` moved focus to the next control, because the only dictionary was the design cards; the input used 10 px text with 8 px suggestion labels; only the showcase had a search bar.
- Implemented behavior: one identical search form in the header of the showcase, all 20 landings and all 20 README editions (expressive and compact). Shared [search.css](../designs/assets/search.css) (40 px, 14 px Arial, 8 px radius, icon, at most `min(420px,66.67%)`, page palette tokens for contrast), shared controller [site-search.js](../designs/assets/site-search.js) and one generated index [search-index.js](../designs/assets/search-index.js) built from the catalog, README chapters, real project-type folders and the validated workspace dictionary [search-dictionary.json](../designs/search-dictionary.json) (project, Moorkyz location `Karlsruhe`, tools, documents, view settings). Accept only fills the field; `Enter` opens an exact destination (design page of the current type, chapter heading with focus, tool/document README, filtered collection) or searches the collection; the showcase filters in place and reads `?q=`, `?style=`, `?view=`. Escape inside a previewed page dismisses suggestions before closing the preview.
- Initial Git state and unrelated work preserved: another session's uncommitted `04-copilot-setup.ps1` truncation, `TEMPLATE_INTRODUCTION.md`, its audit and its scheduler rows stay unstaged and untouched; only this task's scheduler rows are committed.
- Intentional exclusions: no storage, network, geocoding or remote/semantic provider (hook only); standalone `docs` exports stay script- and link-free; no change to the ranking engine.

## Changes

| Path | Change | Risk |
|---|---|---|
| `designs/search.mjs`, `designs/search-dictionary.json` | Shared form/head markup; index generation; dictionary validation (fields, duplicates, existing relative `href`) | Low: build fails explicitly on bad entries |
| `designs/assets/search.css`, `site-search.js`, `search-index.js` (generated) | Uniform component, controller and local index | Medium: header layout across 20 designs, verified below |
| `designs/build.mjs`, `designs/documentation.mjs` | Header search + assets on all pages; index output; optional `searchRoot` for collection editions only | Low |
| `designs/assets/showcase.js`, `showcase.css`, `interactions.js` | Showcase uses the shared header search, URL parameters and commit event; old field/styles removed; Escape respects `defaultPrevented` | Low |
| `designs/index.html`, `designs/*/landing.html`, `designs/*/README.html` | Regenerated (41 pages) | Low |
| `designs/verify.mjs`, `verify-predictive-search.mjs`, `designs/README.md` | Regressions and documentation | Low |
| `AGENT_SCHEDULER.md` | REQ-SEARCH-UNIFORM-022 / SEARCH-UNIFORM-022 rows only | Low |

## Verification

| Check | Result | Command / evidence |
|---|---|---|
| Maintenance checkups, isolated worktree (HEAD + this task's 54 design files) | PASS | Node 24.22.0 prepended to PATH: `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause` -> 7 passed, 0 failed; same with `powershell` (5.1) -> 7 passed, 0 failed. Temporary worktree removed. |
| Maintenance checkups, exact staged tree (design files + audit + scheduler row) | PASS WITH RISKS | First run: PowerShell 7 -> 7/7; Windows PowerShell 5.1 -> 6/7, `07-soft-copy.ps1` exited 1 during a >10-minute run. Rerunning that checkup alone on the same snapshot passed all 54 groups on both hosts (166 s); it does not use the design collection. Recorded as an intermittent GUI-timing failure, not hidden. Final full rerun recorded in the next row. |
| Maintenance checkups, final staged tree `91c35a4` (identical to the commit except this row) | PASS | Fresh worktree: `powershell` (5.1) -> 7 passed, 0 failed (225 s); `pwsh` -> 7 passed, 0 failed (219 s). Worktree removed. |
| Maintenance checkups, shared working tree | FAIL (unrelated) | Same command -> 6 passed, 1 failed: `04-copilot-setup.ps1` "A side-effect-free -DryRun parameter is required" because of another session's uncommitted truncation; not modified here. |
| Design verification | PASS | `node designs\verify.mjs`: 1,438 local links/assets, freshness, contrast, script hygiene, one identical header search with assets on all 41 pages, 100 compact exports script/link-free, index KLSE -> Karlsruhe, 7 dictionary refusals, 5,001-entry average 11.1 ms (fast tier 0.8 ms). |
| Browser acceptance (integrated Chromium) | PASS | On showcase, Aether landing/README, Paper README, Terminal landing, Cabinet README: `KLSE` -> ghost `→ Karlsruhe`, top option Karlsruhe, one `Tab` fills `Karlsruhe`, focus stays; 420x40 px, 14px Arial, 8 px radius, no page errors. |
| Browser layout matrix | PASS | 41 pages x 7 widths (1440/1180/1024/960/900/800/375) = 287 checks: inside header, ratio <= 0.6667, 420 px at >= 800 px, 211-213 px at 375 px, search above page links on phones, no header text wrapping, no new horizontal overflow. `20-continuum/README.html` overflows 11 px at 375 px in the committed baseline too (eclipse artwork), unchanged. |
| Browser behavior | PASS | `Get started` + `Enter` scrolls to and focuses `#get-started`; `KLSE`/`Tab`/`Enter` on a README opens `index.html?q=Karlsruhe#collection` with an honest empty state; showcase `Quiet` commit filters in place (5 directions); `glac`/`ArrowRight`/`Enter` opens `07-glacier/landing.html`; `?view=readme&style=Editorial` restores state; ArrowDown sets `aria-activedescendant`; Escape keeps the typed text; Escape in a previewed page dismisses suggestions, a second Escape closes the preview. |
| Accessibility/motion | PASS (structural) | `role=search` form, explicit label, `combobox`/`listbox`/`option`, `aria-expanded`, `aria-controls`, `aria-autocomplete=both`, polite status; 0.14 s transitions become 0 s with emulated reduced motion; search hidden when `has-js` is absent. |
| Dependency audit | N/A | No dependency or manifest change. |
| `git diff --check` | PASS | `git diff --check -- designs` exit 0. |

## Review

- Secrets and security: no credentials, storage, network calls, `innerHTML` or `eval`; suggestions render with `textContent`. Dictionary `href` values must be existing relative paths. `Karlsruhe` is the public Moorkyz business location (moorkyz-site imprint), not personal tracking data.
- Docs and user-guide impact: [designs/README.md](../designs/README.md) documents placement, sizing, index sources, dictionary editing, commit behavior, URL parameters and the optional remote hook.
- Findings, residual risks and blockers: on phones, the 66.67% rule leaves a 211 px field; the list widens to at least 280 px. Locations have no page, so committing `Karlsruhe` shows the empty collection result. Abbreviation matching remains permissive for short queries. Ghost alignment and layout were verified in Chromium only (not Firefox/Safari); screen-reader output checked structurally, not with a real screen reader. A separate no-JavaScript browser context was unavailable; the hidden state was verified by removing `has-js`. The unrelated `04-copilot-setup.ps1` truncation and the Continuum mobile overflow remain for their owners.

## Completion

- Commit: `PENDING` (report the hash; do not edit this audit afterwards)
- Human review: pending
- External actions: none unless separately approved

A generated draft is not verification evidence and a self-audit is not an
independent security review.
