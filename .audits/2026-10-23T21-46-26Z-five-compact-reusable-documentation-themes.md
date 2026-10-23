# Five compact reusable documentation themes

| Field | Value |
|---|---|
| Audit ID | `2026-10-23T21-46-26Z-five-compact-reusable-documentation-themes` |
| Created (UTC) | 2026-10-23T21:46:26.550Z |
| Auditor | Copilot SDK assistant in VS Code; self-audit |
| Baseline commit | `fdab97c` at request start; `8a1de7d` after the other owner's soft-copy handoff |
| Outcome | `PASS WITH RISKS` - requested behavior verified; lightweight renderer limits and human review documented |

## Request and outcome

- Requested: five of the twenty README editions should be simple, sleek and
  polished enough to repeat across roughly twenty documentation files per
  project, rather than repeating landing-page decoration.
- Clarification unavailable: selected Paper, Glacier, Mono, Vector and Cabinet,
  and added reusable Markdown batch rendering to the existing collection
  generator. All twenty landing pages and the fifteen other README editions
  remain byte-identical.
- Implemented: small 62-89px measured headers, readable content immediately,
  restrained desktop outlines, native mobile disclosure, code/focus/print
  styling, no hero artwork or ambient-light controls in those five editions.
  The showcase identifies/searches the five with `Docs README` labels.
- Reuse: one chosen theme can render many Markdown files while retaining
  subdirectories, linking selected documents to generated HTML, leaving
  unselected links pointed at their original files, embedding CSS and requiring
  no scripts/assets/server for the exported layout. Source files never change.
- Initial Git state: other owners' soft-copy work was dirty at request start,
  then committed separately as `8a1de7d`; later soft-copy undo changes remain
  unrelated and excluded. Only this request's scheduler row and maintenance
  paragraph are owned here.
- Intentional exclusions: no root CLI move/edit, canonical README change, new
  package/runtime, deployment, copied site assets, live-data cleanup, unrelated
  soft-copy changes or claims of full CommonMark/accessibility certification.

## Changes

| Path | Change | Risk |
|---|---|---|
| [five README editions](../designs/README.md#five-everyday-documentation-themes) | Compact documentation-first layouts instead of decorative hero pages | Human preference/assistive-technology review pending |
| [documentation.css](../designs/assets/documentation.css) | Five restrained typography/surface variants, responsive outlines and print rules | Modern CSS color mixing; system fonts |
| [documentation.mjs](../designs/documentation.mjs) | Shared escaped rendering and scoped, preflighted batch export | Explicit overwrite replaces only selected HTML; not a transactional multi-file filesystem operation |
| [build](../designs/build.mjs), [catalog](../designs/catalog.mjs), [showcase](../designs/index.html) | Reuse the existing generator, select exactly five themes, expose documentation search/labels | Existing default collection mode preserved |
| [verification](../designs/verify.mjs), [disposable regressions](../designs/verify-documentation.mjs) | Full content/collection checks plus 100 real exported documents and refusal cases | Automated coverage is not human approval |
| [collection guide](../designs/README.md), [maintenance guide](../.template/maintenance/README.md), [scheduler](../AGENT_SCHEDULER.md) | Theme selection, batch examples, safe reruns, renderer limits and task closure | Other owners' hunks preserved |

## Verification

Node.js **24.22.0** was selected with
`$env:PATH = "$env:TEMP\moorkyz-node24\node-v24.22.0-win-x64;$env:PATH"`.
No dependency installation was needed.

| Check | Result | Command / evidence |
|---|---|---|
| Collection generation | PASS | `node .\designs\build.mjs`: still exactly twenty README editions, twenty landings and one showcase |
| Collection/documentation verification | PASS | `node .\designs\verify.mjs`: 1,274 local links/assets, all six complete unchanged chapters per edition, twenty unique README/landing pages, five compact labels, all 100 palette pairs >= 4.5:1; generated freshness and syntax pass |
| Twenty-document reuse | PASS | Same verifier invokes `node designs/build.mjs docs --theme <each of five> --out <theme> <20 source paths>` from a disposable outside-CWD project: 100 real embedded-style/no-script HTML outputs; twenty source SHA-256 snapshots unchanged |
| Links/anchors and safe modes | PASS | Same disposable suite: encoded spaces, linked HTML documents, original Markdown fallback with query/fragment, repeated headings, H3/Unicode anchors, fallback title, same-basename READMEs in separate folders, help/dry-run, read-only check and unchanged rerun |
| Refusal/overwrite behavior | PASS | Same suite: unknown theme/option, missing file, duplicate output, root/traversing output, incompatible flags, stale check, differing existing HTML, unsafe link protocols, unclosed fence, multiple H1s, non-directory parent, junction/symlink and hard-linked output; preflight failures leave fixture snapshots unchanged; explicit `--overwrite` succeeds |
| Preserved pages/root surfaces | PASS | `git diff --exit-code -- moorkyz README.md README.html 'designs/*/landing.html'`: unchanged. `git diff --name-only -- 'designs/*/README.html'` lists exactly Paper, Glacier, Mono, Vector and Cabinet |
| Browser layout | PASS | All five compact pages at 1440, 390 and 320 CSS px: 15 checks, no overflow/page errors, no hero/art/toggle, six chapters, font <= 44px, header <= 130px and first paragraph above 340px. Actual headers 62-89px; first paragraphs 168-282px from viewport top |
| No-JavaScript/mobile disclosure | PASS | Existing-page CDP disabled script execution: five of five retain six chapters and immediate content; native mobile disclosure opens through DOM activation without page scripts. Execution restored in `finally` |
| Gallery regression | PASS | Search `documentation` returns exactly the five selected names; real compact Paper iframe contains six chapters and first paragraph at 241px in mobile view; no overflow; iframe Escape closes and source is removed |
| Visual inspection | PASS, limited | Inspected compact Paper desktop screenshot: small header, fine rules, readable sidebar/body/code with no decorative hero. Full human preference and assistive-technology review remain pending |
| Print styling | PASS | Browser print emulation hides header/outline, uses white background and wraps code; screen media restored afterwards |
| Full maintenance on isolated task snapshot | PASS | Temporary `GIT_INDEX_FILE`, `git read-tree HEAD`, only the sixteen owned file changes plus scoped guide/request hunks, and `git checkout-index --all --prefix="$snapshot\"`; then `& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoLogo -NoProfile -File (Join-Path $snapshot '.template\maintenance\RunCheckups.ps1') -NoPause`: **7 passed, 0 failed**. Real shared index and concurrent undo implementation not touched |
| Windows PowerShell 5.1 focused check | PASS | `& 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $snapshot '.template\maintenance\helpers\checkups\06-design-collection.ps1')`: collection plus all 100 export/refusal regressions pass |
| Full Windows PowerShell 5.1 suite | NOT RUN | No PowerShell implementation changed; full suite passed on PowerShell 7, and the affected checkup passed on 5.1. Unrelated in-progress undo changes intentionally excluded |
| Dependency audit | N/A | No manifest/lockfile, third-party package or runtime dependency added; existing Node-core renderer reused |
| Targeted secret scan | PASS | `rg` private-key, GitHub-token, AWS-key and long credential-assignment patterns on collection sources/generated pages and this audit: no matches |
| Whitespace/staged review | PASS | `git diff --check`; final `git diff --cached --check` and sixteen-file scope review before commit. Temporary patch transport's trailing CR warning was normalized for final staging; no unrelated whitespace changes |

## Review

- Secrets/security: no credentials, network fetches, third-party assets,
  tracking or browser storage added. Root renderer escapes source markup;
  documentation hrefs are decoded/re-escaped and unsafe protocols refused.
  Input/output paths reuse the root CLI's scoped symlink/junction guard;
  output files must be regular/unshared and a separate in-project directory.
- Errors/data: all sources, destinations and rendered content are preflighted
  before writing. Unknown options/invalid content/conflicts throw explicit
  errors, not successful fallbacks. Different existing HTML requires explicit
  overwrite; untouched outputs are not rewritten or deleted. Source Markdown
  is read-only. I/O failure during an authorized multi-file write can leave a
  partial set; it fails visibly and is not claimed to be transactional.
- Reuse boundaries: exported HTML embeds styling and has no scripts; local
  links to unselected documents/assets still require those original files.
  The command uses the existing lightweight renderer (headings, paragraphs,
  fenced/inline code and links), not full CommonMark. Lists/tables retain the
  baseline text rendering, documented in the guide.
- Tests only create/remove their newly allocated disposable fixture. Source
  hashes, no-write snapshots and scoped refusal cases are actual assertions.
  No live setup, storage cleanup or user repository copy was performed.
- Residual risks: modern-browser/system-font differences, source Markdown
  renderer limits, non-transactional authorized output writes and pending
  complete human/accessibility review. Native disclosure was verified by DOM
  activation, not physical mouse/keyboard hardware certification.
- Blockers: none. The verification snapshot and temporary index were disposable;
  removed after final comparison. No existing data was cleaned.

## Completion

- Commit: `PENDING` (report the hash; do not edit this audit afterwards)
- Human review: pending
- External actions: none; no push, merge, deployment, login or upload

A generated draft is not verification evidence and a self-audit is not an
independent security review.
