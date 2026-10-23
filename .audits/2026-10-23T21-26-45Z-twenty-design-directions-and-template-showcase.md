# Twenty design directions and template showcase

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T21-26-45Z-twenty-design-directions-and-template-showcase` |
| Created (UTC) | 2026-10-23T21:26:45.263Z |
| Auditor | Copilot SDK assistant in VS Code; self-audit |
| Baseline commit | `42b7a28` after the coordinated tooling/storage changes |
| Outcome | `PASS WITH RISKS` - requested collection verified; human visual/accessibility review pending |

## Request and outcome

- Requested behavior: study the supplied Moorkyz sites first, create twenty
  different README HTML editions and twenty landing pages, then a final
  template landing page advertising the real counts. Balance freedom and
  systematic precision with minimalism, space, modern clarity and selective
  blue/purple/white/orange angle-sensitive light.
- Implemented: exactly 41 static HTML pages across twenty original directions,
  complete current root documentation in every README, shared local assets,
  a searchable/filterable showcase, live local previews and direct navigation.
- Clarification was unavailable. Safe assumptions were to preserve the canonical
  root README and promote the actual template rather than fabricate products.
  The attached Copilot guide was inspected, not overwritten or used to invent
  a different application stack.
- Initial Git state: work overlapped coordinated tooling renames and audit/storage
  changes; those owners' files and commits were preserved. Shared documentation
  integration followed their completed `42b7a28` handoff. The later concurrent
  soft-copy tool, checkup 07, catalog entry and its guide/scheduler additions
  are unrelated and excluded from this task's staging.
- Intentional exclusions: no framework, package manifest, application, database,
  deployment, account, remote state changes, copied site assets, fabricated
  testimonials/adoption metrics or live-data cleanup. Root `moorkyz` stays put.

## Changes

| Path | Change | Risk |
|---|---|---|
| [designs/](../designs/README.md) | Twenty complete README editions, twenty landings and final showcase; original geometry and copy | Additional committed generated pages must be rebuilt after source changes |
| [catalog](../designs/catalog.mjs), [generator](../designs/build.mjs), [verification](../designs/verify.mjs) | Deterministic Node-core generation, read-only freshness mode, exact counts/content, local-link and palette checks | Uses the existing root renderer; its contract is checked |
| [assets](../designs/assets/) | Twenty visual/layout treatments, progressive enhancement, pointer light, reduced-motion/print rules, gallery/dialog lifecycle | Modern browser CSS/dialog support; not a complete accessibility certification |
| [README](../README.md), [canonical HTML](../README.html) | Additive discovery and regeneration guidance; preserve existing baseline content | All twenty derived README editions regenerated with the new sixth chapter |
| [maintenance guide](../.template/maintenance/README.md), [checkup 06](../.template/maintenance/helpers/checkups/06-design-collection.ps1) | Wire read-only collection verification into the existing runner and CI discovery | Remove checkup and documentation references together if removing this optional collection |
| [scheduler](../AGENT_SCHEDULER.md) | Close only this request's row with actual evidence | Preserve all other owners' rows |

## Verification

Commands ran with the cached Node.js **24.22.0** directory prepended to PATH:
`$env:PATH = "$env:TEMP\moorkyz-node24\node-v24.22.0-win-x64;$env:PATH"`.
No package installation was necessary.

| Check | Result | Command / evidence |
|---|---|---|
| Canonical/collection generation | PASS | `node .\moorkyz readme`; `node .\designs\build.mjs`: root HTML regenerated; exactly 20 README editions, 20 landings and one showcase generated |
| Read-only collection checks | PASS | `node .\designs\verify.mjs` (also invokes `build.mjs --check`): 1,259 local links/assets; all six complete chapters and unchanged README text in every edition; unique pages, valid anchors/landmarks, page-kind-preserving Previous/Next links, responsive-copy whitespace and 100 palette pairs >= 4.5:1 |
| PowerShell 7 maintenance | PASS | `& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoLogo -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause`: 6 passed, 0 failed |
| Windows PowerShell 5.1 maintenance | PASS | `& 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\.template\maintenance\RunCheckups.ps1 -NoPause`: 6 passed, 0 failed |
| Isolated staged-snapshot maintenance | PASS | Exported exactly the reviewed index using `git checkout-index --all --prefix="$($fixture.FullName)\"`; ran PowerShell 7 `-NoLogo -NoProfile -File (Join-Path $fixture.FullName '.template\maintenance\RunCheckups.ps1') -NoPause`: all 6 passed, 0 failed. Verified 55 task-owned staged files; concurrent soft-copy code, rows and guide additions absent. Disposable snapshot removed afterwards |
| Responsive browser sweep | PASS | Integrated-browser Playwright navigation of all 41 pages at 1440, 390 and 320 CSS px: 123 checks, no horizontal overflow or page errors; 20 distinct measured desktop landing composition signatures |
| Genuine JavaScript-disabled browsing | PASS | Existing-page CDP `Emulation.setScriptExecutionDisabled`: 41/41 retain main content and direct navigation, all six README chapters present, enhancement controls hidden; restored execution in `finally` |
| Gallery interaction | PASS | Quiet filter = 5, Flux search = 1, empty/reset = 0/20; actual six-chapter iframe README, README/landing tabs and 390px preview; Escape from iframe and toolbar, focus return and synchronous source cleanup; forged parent close message ignored |
| Decorative light/reduced motion | PASS | Two hit-testable pointer positions changed angle approximately 188 to 272 degrees and brightness 1.052 to 0.968; reduced-motion prevents new angle changes and computes `transform: none`; DOM button activation toggles state/body class |
| Native light-button activation | NOT VERIFIED | Embedded click/Space/CDP Enter attempts did not reliably activate the button; source inspection shows a single standard-button listener, and DOM activation works. Physical mouse/keyboard approval remains a human-review item, not a claimed pass |
| Visual inspection | PASS, limited | Inspected final showcase desktop/mobile, Flux landing and Paper README; final local sculpture/ribbon screenshots inspected. This is not human approval of every design |
| Reference study | PASS, public scope | Before authoring, browsed Moorkyz's six panels; Cards homepage/designer/membership/claim/sign-in/legal pages; AI collection/capabilities/all ten experiments; Transcriptor's five sections; The Dot public information tabs. Full observations and source links are in the [collection guide](../designs/README.md#reference-study) |
| Dependency audit / npm baseline | N/A | No root manifest/lockfile or third-party runtime dependencies; did not invent a manifest or install tooling. Used the repository's actual maintenance runner |
| Targeted secret scan | PASS | `rg` private-key, GitHub-token, AWS-key and long credential-assignment patterns across task-owned sources, generated pages and documentation: no matches |
| Whitespace / focused staged review | PASS | `git diff --check`; `git diff --cached --check`; reviewed task-owned staged sources/docs and generated file inventory before the local commit |

The six-check maintenance results were observed before another owner added its
unfinished soft-copy tool/checkup 07. That concurrent tool and its checks are
not covered by these results or included in this task's commit.

## Review

- Secrets/security: no credentials, third-party scripts/fonts/images, tracking,
  storage APIs, network-fetch code, dynamic HTML injection or evaluation added.
  External URLs are explicit ordinary links. Generated content uses the
  existing escaping renderer and escaped catalog fields; authored title markup
  is trusted local source. Preview close messages require the current iframe
  window and exact fixed signal; a forged parent message was rejected.
- Dependencies/input/errors: Node core only; unsupported generator arguments
  throw; stale/missing output exits nonzero. The new PowerShell check propagates
  Node errors. `--dry-run` and `-DryRun` are no-ops. Verification never regenerates
  pages or invokes cleanup. Existing disposable maintenance regressions ran,
  not live adoption/storage actions.
- Docs: canonical Markdown/HTML and all twenty additional README editions agree.
  The collection guide documents the full direction table, export boundaries,
  regeneration, public reference evidence and removal of optional checks.
- Fixed during verification: one muted palette failed the 4.5:1 threshold and
  was darkened; preview Escape/focus/source cleanup was made explicit; adjacent
  navigation now preserves page type; hidden mobile line breaks retain spaces.
- Browser-test limitations: separate-context creation was rejected by the
  embedded browser and file-routing did not actually block scripts; neither was
  counted as a no-JS pass. Existing-page CDP provided the genuine no-JS result.
  Native screenshot scrolling/actionability waits also stalled; direct capture
  worked. A reduced-motion test initially treated pointerleave's normal reset
  as a failure; hit-tested positions and explicit media-state assertions passed.
  Native light-button activation remains unverified as described above.
- Residual risks: measured palette pairs/basic semantics/keyboard dialog behavior
  are not full WCAG certification, assistive-technology testing, cross-engine
  coverage or owner visual approval. No authenticated reference content was
  accessed; the supplied `/cards` URL was 404 and the live Cards subdomain was
  discovered from the public Projects panel.
- Blockers: none for the requested static deliverables. Native light-button
  activation, export-specific link rewrites and complete human review remain
  explicit review items. No source/runtime data was cleaned or moved.

## Completion

- Commit: `PENDING` (report the hash; do not edit this audit afterwards)
- Human review: pending; owner has not selected/approved a direction
- External actions: public reference browsing only; no push, merge, deployment,
  login, upload or remote state changes

A generated draft is not verification evidence and a self-audit is not an
independent security review.
