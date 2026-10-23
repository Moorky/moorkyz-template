# Single-root Moorkyz launcher and clean restarts

Historical report: commands and results describe this task's original state.
See [current names and locations](README.md#current-names-and-locations) for later moves and removals.

- Date: 2026-10-23 UTC
- Scope: consolidate the launcher, retain only `moorkyz` as a root script, preserve
  local helper assets under ignored `.moorkyz/scripts/`, and make repeat starts
  replace only the verified owned instance on the same port.
- Initial Git state: unborn `master` branch, no commits, and an entirely untracked
  baseline. Existing assets and unrelated work were preserved. No files were
  staged, committed, or pushed.

## Changes

- [moorkyz](../moorkyz) now embeds the existing storage implementation and needs
  no relative runtime imports. It runs as an extensionless Node entry in both
  CommonJS and ESM projects. The CommonJS storage API remains available by
  requiring the root file. The redundant root CJS implementations were folded
  into that file rather than retained as required ignored dependencies.
- Existing Windows shortcuts, the profile installer, initial setup, and settings
  assets were moved into local `.moorkyz/scripts/`. The relocated CMD launcher
  and installer resolve the root entry with relative paths.
- Starts and restarts validate their requested script and package manager before
  stopping a verified running instance. Stop waits up to five seconds for the
  previous port to become bindable. Random port selection and retry-on-another-port
  behavior were removed; saved ports are reused while the configured URL matches.
  A new configured URL selects its new port. Default Vite arguments use
  `--strictPort`. Other applications must honor `PORT` or configured `portArgs`.
- A fresh run gets a new process, token, and log. Project data and local scripts
  are not deleted as a restart mechanism. Existing retention still applies to logs.
- Added a dependency-free tooling [manifest](../.template/project-types/helpers/types/node/package.json) (now optional), npm
  `package-lock.json` (since removed; see [layout history](2026-10-23T18-30-00Z-stack-neutral-baseline-and-readm-removal.md)), and disposable regression
  `tests/` (since removed; current checks use [maintenance](../.template/maintenance/RunCheckups.ps1)).
  There is no application runtime, development server,
  deployment destination, or additional npm dependency.
- Audit discovery now uses the existing [template](../docs/AUDIT_TEMPLATE.md),
  fills its actual placeholders, and writes drafts into root `audits/`.
  The previous audit index was moved from `.audits/` to [.audits/README.md](README.md).
- Updated the [README](../README.md) and
  [CLI guide](../docs/INFRASTRUCTURE.md). `node moorkyz readme` regenerates both
  [README.html](../README.html) and `READM.html` (since removed); tests reject stale
  editions and broken README/guide documentation links.

## Actual validation

- Before changing the implementation, the occupied-port regression failed against
  the original CLI: it returned success on a different port instead of rejecting
  the unrelated listener. The disposable owned server was stopped by test cleanup.
- Initial standalone lifecycle suite: 9 tests passed.
- Final baseline: Node.js **24.21.0**, npm **11.5.2**,
  `npm ci --ignore-scripts --no-audit --no-fund`, then `npm run verify`:
  **23 tests passed, 0 failed, 0 skipped** on Windows.
  Explicitly invoked the installed npm 11 CLI with Node 24 because the system npm
  shim otherwise selects Node 22. An intermediate invocation of the bundled npm 10
  emitted an engine warning; the final npm 11 run completed without that warning.
- Tests cover occupied and managed-reserved ports, fresh process identity and logs
  across starts/restarts, production mode, changed URLs, ESM projects, paths with
  spaces, concurrent starts, port release, missing replacement scripts, dead and
  unverified state, failed binds, startup timeouts, missing manifests, and audit
  template expansion.
- Storage tests independently read ZIP records, decompress payloads, and verify
  exact bytes, CRC32, empty files/directories, copy-only backups, exact log caps,
  active-log protection, preserved scripts/trash, and rejected path escapes.
- `node moorkyz doctor`: root entry, npm declaration, tooling scripts, and actual
  audit template detected correctly. Root layout test confirms one root script.
- Relocated CMD help succeeded. Relocated PowerShell installer passed install,
  repeated-install, and uninstall checks against a disposable temporary profile,
  preserving the original profile text. The developer's real profile was not edited.
- `git check-ignore` confirmed the relocated launcher and installer remain ignored.
  Verification never ran maintenance, archival, or cleanup against existing project data.

## Copilot documentation follow-up

The user also asked whether Copilot CLI replaces custom scheduler/task/review
documents and how to keep documentation clean. Current official documentation
confirms automatically discovered repository instructions, including `AGENTS.md`,
and `/instructions` for checking discovery. Arbitrary scheduler filenames are not
listed as instruction sources; installation is not a promise to maintain them.

- [Custom instructions](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions):
  use the existing project guide rather than duplicating rules in competing files.
  Instruction changes require a new or resumed CLI session.
- [CLI overview](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/overview):
  built-in agents include code review, but review is not automatic reconciliation
  of arbitrary project documents.
- [Scheduled prompts](https://docs.github.com/en/copilot/how-tos/copilot-cli/automate-copilot-cli/schedule-prompts):
  `/every` and `/after` are experimental, require experimental mode, and only fire
  while their interactive session is running. They can schedule `/review` or a
  documentation-check prompt; they are not a durable unattended scheduler.
- [Hooks](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-hooks):
  hooks can run checks, but supported events and behavior differ across Copilot
  surfaces. CI remains the verification gate; instructions guide model behavior
  rather than guaranteeing semantic documentation accuracy.

No agent instructions, user profile, hooks, or scheduler automation were installed
or changed for this follow-up.

During the final Git status check, an externally added
[AGENT_SCHEDULER.md](../AGENT_SCHEDULER.md) appeared. It was preserved untouched.
Its heading identifies a work queue for a different project, Moorkyz Evidence,
and it explicitly says it is a coordination document, not an automatic launcher
or atomic locking service. Its historical commit claims cannot be treated as
verified history for this template's unborn branch. No imported queue items were
claimed or executed.

## Secret review, limitations, and human review

- No credentials, environment values, production data, or third-party dependencies
  were introduced. Targeted common private-key/token-pattern scanning of the root
  entry, tests, README Markdown, and CLI guide returned no matches. This is a
  limited secret check, not a comprehensive security audit.
- Linux/macOS execution remains unverified locally. The existing Node 24 CI matrix
  targets Windows and Ubuntu; CI has not been run or claimed successful here.
- A configured application must honor its requested port and remain in the
  supervised process tree. TCP readiness is not application health verification.
  An external process can still race the interval between port probing and bind.
  Alive but unverified supervisors and stale locks still require explicit inspection.
- The preserved legacy task-entry UI assets still reference missing external
  TaskEntry/scheduler components; they are not required by the standalone CLI.
  Optional ignored helpers are local conveniences, not fresh-checkout dependencies.
- Human review: **pending**. No commit was created because the baseline has no
  existing commit and all unrelated starting content is untracked.
