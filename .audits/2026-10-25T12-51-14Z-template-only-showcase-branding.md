# Template-only showcase branding

| Field | Value |
|---|---|
| Audit ID | `2026-10-25T12-51-14Z-template-only-showcase-branding` |
| Created (UTC) | 2026-10-25T12:51:14.283Z |
| Auditor | Copilot SDK session 712393c4-1c88-4c5a-82ba-b596a999b488 (self-audit) |
| Baseline commit | `d4599ab8e85229cc2683deedb697c9af3e18c3bf` |
| Outcome | `PASS WITH RISKS` |

## Request and outcome

- Requested behavior: rename the website to focus on templates and showcase completed work; never present the offering as tools. Chosen public name: **Moorkyz Templates**.
- Implemented behavior: consistent public titles/branding across the showcase and twenty landing/README pairs, including compact documentation headers. Showcase content advertises the actual twenty designs, twenty landing pages, twenty README editions and five compact themes. Landing features, CTAs and Terminal/Cabinet decorative copy showcase finished pages rather than CLI, presets, maintenance or storage. The shared search placeholder and dictionary promote templates, page views and the collection guide; internal utility/document/preset destinations were removed. Previous project-name spelling remains an accepted search alias.
- Initial Git state preserved: unrelated modified Copilot checkup and scheduler introduction rows, untracked introduction, introduction audit and editor settings. A separate root catalog session subsequently added `index.html`, `website/` and its own scheduler rows; all remain outside this task's ownership/staging. Its new root website already uses the same public name.
- Coordination: the owner-unavailable parallel-scope question returned an instruction to choose pragmatically; proceeded with disjoint design-site scope and retained the older introduction claim. Cross-session messaging was attempted when the new catalog appeared but refused by the host's message limit; the other session's ledger explicitly confirms disjoint scope and preservation of these edits.
- Intentional exclusions: no repository/CLI rename, runtime, dependency, deployment or utility behavior change. Technical repository README content remains complete in all documentation editions; utility instructions there are reference content, not website marketing.

## Changes

| Path | Change | Risk |
|---|---|---|
| `designs/build.mjs`, `catalog.mjs` | Template-only showcase/landing copy, page titles, navigation, artwork labels, counts and collection links | Low; layouts and existing assets preserved |
| `designs/documentation.mjs` | Collection README titles and header brand; standalone exports retain their source title and header | Low; existing 100-export suite passes |
| `designs/search.mjs`, `search-dictionary.json`, generated `assets/search-index.js` | Collection-focused placeholder and vocabulary; remove project-type folder discovery and utility destinations | Low; existing keyboard/ranking engine unchanged |
| `designs/index.html`, twenty `landing.html` and twenty `README.html` editions | Regenerated from the reviewed sources | Low; freshness and all local destinations verified |
| `designs/verify.mjs`, `verify-predictive-search.mjs` | Public-name, template-only marketing, placeholder, dictionary and real-count assertions; local-link validator recognizes URL query strings | Low; all prior structural/content/export/predictor checks retained |
| `README.md`, `README.html`, `designs/README.md` | Updated collection name, scope and search guidance; generated canonical HTML | Low; technical documentation unchanged except the collection description |
| `AGENT_SCHEDULER.md` | This task's request closure only; unrelated rows excluded from the index | Low |

## Verification

Use `PASS`, `FAIL`, `NOT RUN` (with reason) or `N/A`; record exact commands.

| Check | Result | Command / evidence |
|---|---|---|
| Maintenance, isolated task snapshot | PASS | Node 24.22.0 on PATH; `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause` in a disposable detached worktree at `d4599ab` plus this task's 52 website/doc files: **7 passed, 0 failed**. SHA-256 comparisons confirm all 52 current task files are byte-identical to the verified snapshot. No baseline utility file replaced in the shared worktree. |
| Maintenance, shared worktree | FAIL (unrelated) | Same command: **6 passed, 1 failed**. `01-runnables.ps1` refuses the pre-existing truncated `04-copilot-setup.ps1` because it lacks a side-effect-free `-DryRun` parameter. That file remained untouched. Its own direct invocation emits an existing unrecognized-command error; it is not treated as meaningful Copilot coverage. |
| Design regressions | PASS | `node .\designs\verify.mjs`: 41 unique pages, **1,439 local links/assets**, six complete unchanged chapters per README, all 100 palette pairs >= 4.5:1, shared search, template-only marketing and generated freshness. |
| Documentation/predictor regressions | PASS | Same suite: 5 compact themes x 20 disposable Markdown fixtures = **100 self-contained outputs**, unchanged sources, export refusal/rerun checks; shipped-index `KLSE` -> `Karlsruhe`, public-name prefix, dictionary validation, ranking/cache tests. Final isolated 5,001-entry uncached average **12.8 ms**, prefix tier **0.7 ms**, within existing 40/15 ms thresholds. |
| Responsive browser matrix | PASS | Integrated Chromium, all 41 design pages at 1440/1180/1024/800/375 px = **205 checks**: correct public titles, no header-child overlaps, search height 40 px and width <=66.67%, no page overflow >12 px. The existing Continuum README mobile artwork overflow is not changed by this copy task. |
| Browser interactions | PASS | `moorkyz tem` + one `Tab` fills `Moorkyz Templates`; `KLSE` + one `Tab` fills `Karlsruhe`; the new README collection card link selects the README view; Paper live preview opens `02-paper/README.html`, Mobile toggles, Escape closes, Quiet filter yields 5 directions / 10 pages. Desktop screenshot inspected. |
| No-JavaScript browser smoke | NOT RUN | Attempted isolated browser context, but host rejected its page with "Sandboxed browser views must use their owning agent session storage affinity." Existing structural/no-script export checks pass; no behavior script was changed. |
| Dependency audit | N/A | No dependency or manifest change; no package installation. |
| `git diff --check` | PASS | `git diff --check -- designs README.md README.html` exit 0. Final staged whitespace and documentation checks performed before commit. |

## Review

- Secrets and security: inspected the task diff for credentials, dependency changes, unsafe content rendering and data loss. No secrets, external requests, new dependencies, storage operations or runtime configuration were added. Existing HTML escaping and dictionary validation remain in place; new hrefs are local collection pages or the existing HTTPS repository destination. No exploit or independent security review was requested or performed.
- Docs and user-guide impact: root collection links use the new public name; the collection guide documents template-focused promotion/search and explicitly distinguishes complete technical README sample content. Standalone documentation exports retain prior behavior.
- Findings addressed during verification: local-link checking initially treated a query string as a filename; now strips query before exact-case path/fragment validation. The initial brand assertion used an exact predictor query, which intentionally produces no completion; replaced it with the real partial-prefix acceptance test. The browser-held local file was released before regenerating pages.
- Remaining risks/blockers: shared full maintenance is still blocked by someone else's Copilot-checkup edit; isolated 7/7 verifies this task against intact baseline utilities without discarding that work. Firefox/Safari and real screen-reader/human visual review are pending. The collection's technical README content still accurately describes repository utilities; it is deliberately not stripped or misrepresented. Concurrent root catalog work is outside this audit.

## Completion

- Commit: `PENDING` (report the hash; do not edit this audit afterwards)
- Human review: pending
- External actions: none unless separately approved

A generated draft is not verification evidence and a self-audit is not an
independent security review.
