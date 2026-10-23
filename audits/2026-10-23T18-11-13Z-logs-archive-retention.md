# Log naming, capped retention and compressed project archives

Historical report: commands and results describe this task's original state.
See [current names and locations](README.md#current-names-and-locations) for later moves and removals.

- Date: 2026-10-23 UTC.
- Scope and user request: keep at most 50 timestamp-named logs, archive malformed
  and oldest excess logs, compress recoverable project deletions into one ZIP per
  operation, expose archival to code, and reclaim oldest archives under disk pressure.
- Initial Git state and unrelated work preserved: unborn `master` branch with an
  entirely untracked baseline. Existing local data and unrelated assets were not
  cleaned or moved. Concurrent additions to contribution documentation and
  documentation tests were preserved. No files were staged, committed or pushed.

## Changed files and concrete behavior

- [moorkyz](../moorkyz): the existing shared storage policy already provided
  canonical UTC log/ZIP names, verified streaming ZIPs, batched source removal,
  active-log leases, project scope checks and background maintenance. Completed
  the missing guards and retention reporting instead of adding another subsystem:
  - `createLog(root, { policy })` refuses to exceed the default 50 entries or a
    configured lower cap. Managed starts pass the same policy to maintenance and
    creation. Callers serialize operations and run maintenance to make room first.
  - Archival checks free space before writing and again after publishing the
    verified ZIP and removing unchanged sources. The new recovery ZIP remains
    protected for that operation.
  - Returned retention results include deletions from both checks. An exhausted
    archive set that recovers above the minimum but below the requested target
    still reports low space. CLI archival, startup and background/explicit
    maintenance emit an explicit stderr warning when reclamation is insufficient.
  - Initialize the compressor before opening its source stream, preventing an
    unhandled asynchronous read error if compression initialization fails.
- `tests/storage.test.cjs` (since removed; current checks use [maintenance](../.template/maintenance/RunCheckups.ps1)): added exact 50/lower-cap checks,
  timestamp and calendar validation, oldest-first rotation independent of mtime,
  malformed files/directories plus trash in one ZIP, single-file DEFLATE,
  overlapping multi-file batches, protected archives/logs, byte and percentage
  targets, incomplete recovery, post-write reclamation, full removal accounting,
  compression failure preservation, and CLI low-space warnings.
- Updated [README](../README.md), both generated HTML editions
  ([README.html](../README.html), `READM.html`, since removed), and the
  [CLI/storage guide](../docs/INFRASTRUCTURE.md). Added this report to the
  [audit index](README.md).
- Created local root `logs/`, `archive/` and `trash/` through the existing
  directory-initialization helper. Existing `.moorkyz/` was preserved. The
  existing [.gitignore](../.gitignore) already excludes all four; no placeholders
  were created and no ignore changes were needed.

## Validation commands and actual results

- Initial Node 24 focused storage run: **11 passed, 5 failed**, reproducing
  missing creation caps, incomplete-target reporting, post-write checks and
  pre-write deletion accounting.
- After those fixes, the focused suite passed **16/16**. The expanded failure
  regression then detected an asynchronous read-stream error after compressor
  initialization failed. Reordering initialization fixed that leak.
- `node moorkyz readme`: regenerated both HTML editions successfully.
- `git check-ignore logs archive trash .moorkyz`: confirmed all four local
  runtime directories are ignored. Initialization did not invoke maintenance.
- Final baseline on Windows: **Node.js 24.21.0, npm 11.5.2**,
  `npm ci --ignore-scripts`, then `npm run verify`:
  **40 passed, 0 failed, 0 skipped**. This includes **21 storage tests/subtests**,
  existing lifecycle coverage, exact README HTML freshness and local documentation
  links. Source ZIP payloads are independently decompressed and checked by tests.
- An earlier complete baseline run also passed 40 tests but used bundled npm
  10.9.3 and emitted the expected engine warning. The final run explicitly used
  the installed npm 11 CLI with the cached Node 24 executable and had no engine
  warning. Neither runtime nor packages were newly installed for this task.
- Editor diagnostics: no errors in the launcher, storage tests, README Markdown
  or CLI guide.
- Final documentation-only check after adding this audit:
  `node --test tests/documentation.test.cjs`, **4 passed, 0 failed**. Rechecked
  directory presence and trailing-separator Git ignore paths for all four local
  runtime directories; all were present and ignored.
- All cleanup, archival and simulated disk-pressure tests used disposable
  temporary directories. No existing project data was subjected to retention.

## Secret/security review

- No secrets, external runtime dependencies, remote services or deployment
  configuration were added. Targeted common private-key, GitHub-token and AWS
  access-key pattern checks of the modified launcher, storage tests, README
  Markdown/HTML, CLI guide and audit files found no matches. This is not a
  comprehensive security audit.
- npm reported **0 vulnerabilities** for the dependency-free baseline.
- Scope boundaries, active-writer protection, verified archives before source
  removal, compression failure recovery and preservation of unrelated project
  files were exercised. ZIP compression is not encryption.

## User-guide impact, known limits and review status

- Names use UTC `log_yyyy-mm-dd-hh-mm-ss-mmm.log` and
  `log_yyyy-mm-dd-hh-mm-ss-mmm.zip`. Malformed logs and oldest excess logs are
  removed from `logs/` only after their batch archive is verified.
- Ordinary filesystem directories cannot intercept unrelated writes or OS/editor
  deletions. Recoverable deletion must use `node moorkyz archive` or
  `archivePaths`; external loggers must use the API or invoke maintenance.
- Maintenance runs before managed starts, every 30 seconds while managed
  services run, and explicitly with `node moorkyz maintain`. There is no separate
  always-running system watcher. Library callers serialize concurrent operations
  and inspect returned low-space results.
- Retention defaults trigger below the greater of 1 GiB or 5% free, targeting the
  greater of 2 GiB or 10% free. Only eligible canonical ZIPs in this project's
  archive are permanently pruned, oldest filename first. Protected or insufficient
  recovery data can prevent reaching the target; durable backups belong elsewhere.
- No application runtime or deployment destination was invented. Linux/macOS and
  CI execution were not performed locally; the existing CI matrix remains the
  cross-platform gate.
- Task commit: none; the unrelated untracked baseline was not included in a commit.
  Human review: **pending**.
