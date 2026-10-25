# Complete template standards and current references

| Field | Value |
|---|---|
| Audit ID | `2026-10-25T13-56-35Z-complete-template-standards-and-current-references` |
| Created (UTC) | 2026-10-25T13:56:35.667Z |
| Auditor | Copilot SDK in VS Code; session 472aa981-0576-40bc-af57-5950318595a3; self-audit |
| Baseline commit | `923b10f` |
| Outcome | `PASS WITH RISKS` |

## Request and outcome

- Requested behavior: complete remaining standard template content, refresh references, and add another website link to `moorky.com`.
- Scope clarification returned owner unavailable with direction to choose pragmatically. Completed the shared baseline and a minimal catalog-footer addition; did not invent product identity, runtime, infrastructure or credentials.
- Implemented behavior: expanded readiness, contribution, security and dependency-maintenance guidance; documented completion requirements for all nine presets; restored the truncated Copilot regression checkup; refreshed generated documentation and search chapters; added the exact requested HTTPS link and a footer regression assertion.
- Initial Git state: pre-existing changes to the scheduler, Copilot checkup and design/viewer integration; untracked catalog, viewer, introduction, editor settings and earlier audits. Deployment files also appeared during this session. Preserved those owners' implementation and did not claim their checks or audits as this task's work.
- Intentional exclusions: no package upgrades or installs, application scaffolding, real adoption, live settings changes, runtime-data operations, account configuration, publishing or deployment. Historical audits were not rewritten as current evidence.

## Changes

| Path | Change | Risk |
|---|---|---|
| [README.md](../README.md), [README.html](../README.html), [README editions](../designs/README.md), [search index](../designs/assets/search-index.js) | Readiness and support/license guidance; current authoritative setup references; regenerated eight-chapter editions and search entries. | Low; generated freshness/content/link checks passed. |
| [CONTRIBUTING.md](../CONTRIBUTING.md) | Reproduction requirements, prerequisites, verification workflow, review checklist and licensing boundaries. | Low; documentation only. |
| [SECURITY.md](../SECURITY.md) | Accurate best-effort support scope, private reporting setup, sanitized evidence, credential incident guidance and verification limits. | Low; no credentials or remote settings changed. |
| [Dependency maintenance](../docs/dependency-security.md) | Separate tooling/preset/product responsibilities and current canonical GitHub/npm references. | Low; no dependencies, action pins or package-manager versions changed. |
| [Preset guide](../.template/project-types/README.md) | Completion checklist and authoritative references for all nine existing opt-in presets. | Low; no preset activation or runtime assumptions. |
| [Copilot checkup](../.template/maintenance/helpers/checkups/04-copilot-setup.ps1) | Replaced the pre-existing single word `runc` with the existing tracked disposable-fixture regression implementation. Relative to the baseline commit, only its final newline differs. | Actual setup actions remain isolated from real user profiles; both available PowerShell hosts passed. |
| Working-tree `website/build.mjs`, `index.html`, `website/verify.mjs`, `website/README.md` | Added a visible `https://moorky.com` footer anchor, generated output, exact-destination regression and related guide text. These paths are not linked because they are not in this task's baseline commit. | Domain did not resolve; existing site is shared untracked work, so these files remain outside the baseline-only commit. |
| [Scheduler](../AGENT_SCHEDULER.md) | Recorded this request, bounded claim and observed completion/commit limitation. | Only this task's rows are eligible for staging; other claims remain unchanged. |

## Verification

Use `PASS`, `FAIL`, `NOT RUN` (with reason) or `N/A`; record exact commands.

| Check | Result | Command / evidence |
|---|---|---|
| Initial environment probe | FAIL, resolved | `pwsh -NoProfile -File .\.template\maintenance\helpers\checkups\01-runnables.ps1` rejected the default Node `v22.18.0`. Subsequent checks used an already available Node `v24.21.0` through this process's PATH; no installation or global PATH edit. |
| Regeneration | PASS | `node .\moorkyz readme`; `node .\designs\build.mjs`; `node .\website\build.mjs`. Generated canonical HTML, twenty README editions, twenty landings, showcase/search index and catalog/viewer. Existing source integration was preserved. |
| Maintenance checkups | PASS | `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause` under Node 24: **7 passed, 0 failed**. Includes runnable syntax/no-op entrypoints, exact-case local documentation links, generated freshness and disposable selector/settings/storage/copy actions. |
| Repaired Copilot checkup | PASS | Runner exercised Windows PowerShell 5.1 and PowerShell 7: success/idempotence, preserved JSONC backup and instructions, previews, four validation failures, three aggregated failures, redirected input and isolated user scopes; source unchanged. |
| Documentation collection | PASS | Runner checked twenty complete eight-chapter editions, twenty landings and showcase; **1,629 local links/assets**, all **100** palette contrast pairs at least **4.5:1**, shared search/branding, **100** compact exports and predictive-search regressions. |
| Catalog/viewer regression | PASS | `node .\website\verify.mjs`: twenty designs/forty templates, 48 local catalog links/anchors, eighteen type/style combinations; forty viewer selections/Full View destinations, history, wraparound, filters, resize and four invalid-link refusals. Footer assertion requires the exact `https://moorky.com` anchor. |
| Browser footer | PASS | Integrated Chromium, local `index.html`, widths **375, 768 and 1,440 px**: exact HTTPS destination; link visible, focusable and within viewport; no horizontal overflow. Initial automated stable-scroll wait timed out; reduced-motion/instant scrolling completed the same assertions. |
| Authoritative external documentation | PASS | Retrieved twenty official source pages on 2026-10-25: Node, PowerShell, GitHub reporting/Dependabot/Actions, npm ci/audit/manifest, MDN manifest, Docker, TypeScript, ESLint, Prettier, Stylelint, markdownlint and four VS Code setup references. Updated moved GitHub and PowerShell references to returned canonical routes. This is a point-in-time content check, not continuous monitoring. |
| Requested external destination | FAIL, external DNS | Both the web fetch and `curl.exe --head --location --max-time 20 --silent --show-error https://moorky.com` could not resolve the hostname; curl exit 6. Retained the exact owner-requested domain, without substituting another spelling or claiming the destination is live. |
| Dependency audit | N/A | No root application manifest, lockfile or third-party package changes. Native tool/preset packages were not installed. |
| Empty files / recognizable secrets | PASS | Read-only scan: all 180 currently versioned/nonignored repository files nonempty; 33 task-related files checked for recognizable GitHub/AWS token and private-key patterns, no matches. This signature check complements the manual content review, not a guarantee against all secret formats. |
| Linux / remote CI / live deployment | NOT RUN | Local Windows task; no remote publication or infrastructure access authorized here. Existing CI matrix is not evidence of a run. |
| Staged snapshot | PASS | Thirty focused staged files; all **1,808** local documentation links resolve inside the staged snapshot; generated canonical HTML matches staged Markdown. Removing the two owned scheduler rows reproduces the original staged baseline exactly, excluding every other session's scheduler changes. |
| `git diff --check` | PASS | Scoped source whitespace check and `git diff --cached --check` both passed. |

## Review

- Secrets: reviewed task-owned text/code for credentials and private key material. No secrets added; local runtime folders and editor settings excluded. The existing example pins and placeholders are not credentials.
- Input validation/error handling: no public CLI behavior changed. The restored regression checks refusal and real exit/output shapes, rather than treating failed setup as success. The footer is an ordinary user-activated HTTPS navigation, not an automatic request, iframe or tracking dependency.
- Dependencies/data loss: no new dependencies or global settings; no real project adoption, cleanup, process termination or storage mutation. Existing disposable checkup fixtures perform their own scoped cleanup.
- Missing tests: no new application exists to test. Browser verification covered the changed footer, not an independent re-review of the other sessions' complete viewer/deployment work. This self-audit is not an independent security review.
- Docs: source, canonical HTML, twenty README editions and search chapters are synchronized; examples remain examples and production decisions are explicitly documented.
- Remaining risk: `moorky.com` needs working DNS/hosting from its owner. No DNS changes were attempted.
- Commit boundary: the existing root catalog and all `website/` files are untracked work belonging to other active sessions. Staging them would absorb their entire implementation, not just this task's footer hunk. Preserve the link/generator/assertion/guide changes on disk for the website owner's commit. The focused baseline commit includes only independently owned tracked documentation/generated outputs, restored-checkup newline, this audit and this task's scheduler rows.

## Completion

- Commit: focused baseline commit prepared after final checks; report its hash externally without editing this report afterwards. The shared website footer changes remain unstaged for their owning integration commit.
- Human review: pending
- External actions: none unless separately approved

A generated draft is not verification evidence and a self-audit is not an
independent security review.
