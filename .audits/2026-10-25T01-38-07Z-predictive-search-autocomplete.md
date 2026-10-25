# Predictive search autocomplete

| Field | Value |
|---|---|
| Audit ID | `2026-10-25T01-38-07Z-predictive-search-autocomplete` |
| Created (UTC) | 2026-10-25T01:38:07.655Z |
| Auditor | Copilot SDK session 7697267e-759b-420e-a03f-3ee3cc92540d (self-audit) |
| Baseline commit | `3b945cc` |
| Outcome | `PASS WITH RISKS` |

## Request and outcome

- Requested behavior and confirmed decisions: owner item 10 (REQ-PREDICTIVE-SEARCH-021): real-time predictive autocomplete with inline ghost text and a compact alternatives dropdown; exact/prefix, normalized, weighted fuzzy, keyboard-typo and abbreviation matching; context/recent ranking; `Tab`/`ArrowRight` accept, `ArrowUp`/`ArrowDown` navigate, `Enter` confirms a highlighted suggestion; never replace input without explicit acceptance; search bar max width 66.67%; 100-180 ms opacity transitions; screen-reader, keyboard and reduced-motion support; local-first, cached, optional remote/semantic provider. Acceptance: `KLSE` can produce `Karlsruhe` when the dictionary/context supports it and one keystroke accepts it. Owner unavailable (autopilot); assumptions recorded in the ledger: the only search bar is the `designs/` showcase, recents stay in page memory (showcase scripts deliberately forbid storage APIs), no remote provider is configured.
- Implemented behavior: new dependency-free `designs/assets/predictive-search.js` exposes `normalize`, `prefixDistance`, `createPredictor` (tiers: exact skip, alias, prefix, word prefix, multiword phrase, acronym, weighted OSA fuzzy prefix distance with QWERTY/QWERTZ adjacency 0.5, transposition 0.6, missing letter 0.8, doubled letter 0.4, normalized substring, abbreviation/subsequence; boosts for weight, kind, shared context and recency/frequency; LRU cache) and `attach` (ARIA 1.2 combobox + listbox, aria-hidden ghost overlay, polite status announcements, IME-safe, optional debounced/abortable `remote(query, { signal })` merged after local results, fast-tier sync + debounced full tier above 1,500 entries). The showcase builds its dictionary from the real cards (design names, character phrases, styles, tones, page files, compact-documentation edition), uses the active style filter and page-type switch as context, records accepted/confirmed/previewed values as session recents, and filters on normalized text including page filenames so every suggestion filters at least one card.
- Initial Git state and unrelated work preserved: HEAD `3b945cc`; pre-existing uncommitted work by the TEMPLATE-INTRO-020 session (`TEMPLATE_INTRODUCTION.md`, its audit, its scheduler rows) and a pre-existing modification that reduced `.template/maintenance/helpers/checkups/04-copilot-setup.ps1` to the single line `runc` were left untouched and are not staged.
- Intentional exclusions: no persistent storage, network calls, geocoding, location tracking or remote/AI provider; no place-name dictionary was invented for the design showcase (Karlsruhe is supported by dictionary/alias/recency in the engine and verified in tests and a browser harness).

## Changes

| Path | Change | Risk |
|---|---|---|
| `designs/assets/predictive-search.js` | New local prediction engine and accessible combobox controller | Medium: new keyboard handling on a public page |
| `designs/assets/showcase.js` | Dictionary from cards, context/recency wiring, normalized filtering incl. filenames, falls back to plain filtering if the predictor is absent | Low |
| `designs/assets/showcase.css` | 66.67% max width, ghost overlay, dropdown, 140 ms opacity transitions, reduced-motion overrides, explicit visually-hidden label | Low |
| `designs/build.mjs`, `designs/index.html` | Load predictor before showcase; `<label for>` instead of wrapping label (keeps the listbox out of `<label>`); regenerated, only `index.html` changed | Low |
| `designs/verify.mjs`, `designs/verify-predictive-search.mjs` | Script hygiene/syntax checks extended to the new script; markup/width assertions; engine regression suite | Low |
| `designs/README.md` | Usage, keyboard model, ranking, privacy and verification docs | Low |
| `AGENT_SCHEDULER.md` | Ledger and queue rows for REQ/PREDICTIVE-SEARCH-021 only | Low |

## Verification

Use `PASS`, `FAIL`, `NOT RUN` (with reason) or `N/A`; record exact commands.

| Check | Result | Command / evidence |
|---|---|---|
| Maintenance checkups, shared working tree | FAIL (unrelated) | Node 24.22.0 (portable, prepended to PATH): `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause` -> 6 passed, 1 failed. Only failure: `04-copilot-setup.ps1` lacks `-DryRun` because another session's uncommitted edit replaced it with `runc`; not caused or modified by this task. |
| Maintenance checkups, isolated baseline | PASS | Disposable `git worktree` of `3b945cc` + this task's eight design files: same command -> `Checkups finished: 7 passed, 0 failed (7 total).` Worktree removed afterwards. |
| Design checkup on Windows PowerShell 5.1 | PASS | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ...\06-design-collection.ps1` in the isolated worktree -> exit 0, all design/predictive PASS lines. |
| Design verification | PASS | `node designs\verify.mjs`: 1,275 local links/assets, freshness, script hygiene (no fetch/XHR/storage/innerHTML/eval) and syntax for `predictive-search.js`; predictive regressions incl. `KLSE` -> `Karlsruhe` (abbreviation, ahead of `Kelsterbach`), typos `Karlsruge`/`Karlruhe`/`Kalrsruhe`, `stutgart`, `zur` -> `Zürich`, `HDLBG`, phrases, acronym, alias `KA`, context/recency, cache hit; 5,001 entries uncached avg 10.9-12.5 ms, fast tier 0.5-0.7 ms. |
| Generated freshness | PASS | `node designs\build.mjs --check` was STALE only for `designs/index.html` before regeneration; `node designs\build.mjs` then verify freshness PASS. |
| Browser behavior (integrated Chromium, `designs/index.html`) | PASS | Scripted keyboard: `aet` ghost `her`, `Tab` -> `Aether`, focus kept, filter 1 direction; `glacer` -> `→ Glacier`, `ArrowRight` accepts; `mid` ghost `night blue`, `ArrowDown` x2/`ArrowUp` move `aria-activedescendant`, `Enter` -> `midnight blue`; `Escape` dismisses and the next `Tab` moves focus normally; mouse option click accepts and keeps focus; Systematic filter reorders `s` suggestions; `terminl readme` -> `05-terminal/README.html`; input value never changed before acceptance; 0 page errors. Acceptance harness (temporary input, location dictionary): typing `KLSE` showed `→ Karlsruhe`, one `Tab` set `Karlsruhe`. |
| Width | PASS | At 390 px viewport: field 220.1 px of 330.2 px controls (66.67%); desktop 240 px of 908 px. |
| Visual check | PASS WITH RISKS | Headless Edge screenshots of disposable copies in `%TEMP%`: ghost text aligned after typed text, `→ Karlsruhe` replacement hint, dropdown with bold matched letters, kind label and `Tab` key hint. One capture caught a mid-fade frame; headless mobile capture is limited by a ~500 px minimum window. |
| Dependency audit | N/A | No dependencies or manifests added. |
| `git diff --check` | PASS | `git diff --check -- designs` exit 0; new files checked with `--no-index --check` (no whitespace errors). |

## Review

- Secrets and security: no secrets, credentials, network requests, storage or dynamic code. Suggestions are rendered with `textContent`/text nodes only (no HTML injection from dictionary or remote values). Remote provider is opt-in, debounced, aborted on new input and failures are ignored.
- Docs and user-guide impact: `designs/README.md` documents keyboard model, ranking tiers, privacy (session-memory recents only), caching/debounce thresholds and the optional provider.
- Findings, residual risks and blockers: abbreviation matching is intentionally permissive, so short queries can list loosely related alternatives below stronger matches; ghost alignment relies on copied font/padding metrics (verified in Chromium only, not Firefox/Safari); screen-reader output was checked structurally (roles, `aria-activedescendant`, live status), not with a real screen reader; recents reset on reload by design. The shared tree's `04-copilot-setup.ps1` truncation belongs to another session and remains for its owner.
## Completion

- Commit: `PENDING` (report the hash; do not edit this audit afterwards)
- Human review: pending
- External actions: none unless separately approved

A generated draft is not verification evidence and a self-audit is not an
independent security review.
