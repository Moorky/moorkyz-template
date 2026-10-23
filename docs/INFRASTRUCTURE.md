# Moorkyz CLI

Portable, dependency-free Node.js CLI for local project management. The
self-contained [moorkyz](../moorkyz) entry must stay at the repository root,
not under `.template/`. Copy just the script if needed; it runs in
CommonJS and ESM projects and always operates on the **current working directory**.

Consult the [template-tool catalog](../.template/README.md) when a task may need existing
tooling. Use this CLI for audits, README generation or explicitly authorized
project/storage actions; choose maintenance, setup or presets only when they fit.

## Setup

Requires Node.js 24 LTS for shared tooling, even when the product uses another language. Package-script and lifecycle commands additionally require a Node project, its declared package manager and the scripts you intend to run. Maintenance, archive, audit and README commands work without a manifest. The CLI does not fabricate runners for other languages.

```powershell
node .\moorkyz help
# Optional session shortcut:
function moorkyz { & node 'C:\absolute\repo\moorkyz' @args }
```

```bash
chmod +x ./moorkyz && ./moorkyz help
# Optional shell function (persist it in your shell init file):
moorkyz() { node /absolute/repo/moorkyz "$@"; }
```

The CLI never edits profiles, installs packages or changes PATH. Keep reusable
tool folders under `.template/`, except the root `moorkyz` entry; optional personal shell aliases are not required and
are not installed by the template.

## Commands

| Command | Action |
|---|---|
| `moorkyz help [command]` | Command help |
| `moorkyz start [name\|all] [--prod]` | Start a fresh managed instance on the saved/configured port and open its URL |
| `moorkyz stop [name\|all]` | Stop only processes the CLI started and verified |
| `moorkyz restart [name\|all] [--prod]` | Stop, start and open the URL |
| `moorkyz status [name\|all]` | Show tracked process state |
| `moorkyz logs [name] --lines 80 --follow` | Read or follow logs |
| `moorkyz list` | Show configured projects |
| `moorkyz doctor` | Check Node, package manager, scripts and audit template |
| `moorkyz verify [name]` | Run `verify`, else `validate`, else available format/lint/typecheck/test/build scripts |
| `moorkyz build\|test\|lint\|typecheck [name]` | Run that script |
| `moorkyz security [name]` | Read-only dependency vulnerability audit |
| `moorkyz install [name]` | Reproducible install from the reviewed lockfile; never regenerates it |
| `moorkyz run <script> [name]` | Run an existing `package.json` script |
| `moorkyz audit "task title"` | Create an unfilled draft in `.audits/` from `docs/AUDIT_TEMPLATE.md` |
| `moorkyz readme` | Regenerate `README.html` from `README.md` |
| `moorkyz archive <path> [path ...]` | Compress paths into one verified ZIP, then remove the originals |
| `moorkyz maintain` | Archive malformed/excess logs, then apply archive age, size and free-space retention |

Database migrations, deployment and Git operations are separate project workflows.

## Package managers

The nearest `package.json` with `packageManager` is authoritative. Otherwise the CLI detects `pnpm-lock.yaml`, `package-lock.json` or `yarn.lock` within the repository; competing lockfiles require an explicit declaration, and no declaration or lockfile defaults to pnpm. The tool must already be installed.

Installs use `pnpm install --frozen-lockfile`, `npm ci`, `yarn install --frozen-lockfile` (Classic) or `yarn install --immutable`. Installs run at the manager's root and scripts in the project directory. `security` uses the manager's native audit, reports its real exit status and never applies upgrades.

## Projects

Without `moorkyz.config.json`, one root project named `default` runs `dev` for `start` and `start` for `start --prod` (with `NODE_ENV=production`). The script must exist; nothing is fabricated.

For several Node projects, select the `node` [project type](../.template/project-types/README.md)
to add `moorkyz.config.example.json`, then copy it to `moorkyz.config.json`:

```json
{
  "defaultProject": "web",
  "projects": {
    "web": { "cwd": "apps/web", "dev": "dev", "prod": "start", "url": "http://localhost:3000" },
    "worker": { "cwd": "apps/worker", "dev": "dev", "prod": "start", "url": "http://localhost:3001" }
  }
}
```

- `start` uses `defaultProject`; `start all` launches every project. Without a default, name the project.
- After a successful start the URL opens in the browser, except in CI and non-interactive sessions.
- The port is saved in `.moorkyz/<name>.preferences.json` and reused while `url` is unchanged. There is no random or fallback port: an occupied or reserved port (IPv4 and IPv6 loopback) fails explicitly and leaves other processes alone. A global lock separates simultaneous starts; give projects on one host distinct URLs.
- The CLI sets `PORT`, passes `--port` to Vite/Astro (Vite also gets `--strictPort`) and supports `"portArgs": ["--port", "{port}"]`. `startupTimeoutMs` defaults to 20000 (1000–300000). Success means a verified supervisor heartbeat plus a TCP listener, not an HTTP health check.
- Restarting validates the replacement script first, stops only the verified instance, waits up to five seconds for the port and starts a new process and log. Project files, scripts, caches and recovery data are kept.

## Safety

- State lives in ignored `.moorkyz/`. State, locks and log paths refuse symlinks/junctions; corrupt state stops with an error and is preserved.
- Per-project locks (`.moorkyz/<project>.lock.json`) serialize lifecycle commands. `stop` requires matching token, supervisor PID and fresh heartbeat; an alive but unverified supervisor needs manual inspection.
- A killed CLI can leave a lock. Confirm its owner PID is gone before removing that exact lock. Stop services started by an older CLI with that version before upgrading.
- Unix stops send SIGTERM to the process group; Windows uses `taskkill /T /F` on the verified tree. Daemonized descendants may escape control, so this is not a production process manager.
- `start --prod` runs a production script locally; it does not deploy.
- `security` only reports advisories; Dependabot proposes updates ([dependency maintenance](dependency-security.md)).

## Logs and archives

Keep `.logs/`, `.archive/` and `.moorkyz/` ignored by Git and Docker, without tracked placeholders. Only these dot-prefixed runtime paths are created. A dot prefix is a naming convention, not the Windows Hidden attribute or a Git ignore rule. Reports in [.audits/](../.audits/README.md) remain tracked; the [audit template](AUDIT_TEMPLATE.md) lives directly in `docs/`.

- Each start creates `.logs/log_yyyy-mm-dd-hh-mm-ss-mmm.log` (UTC, exclusive create). At most 50 (or `storage.maxLogs`) are kept; running services' logs are protected and a start fails if they fill the cap.
- Maintenance runs before each start, every 30 seconds while a service runs, and on `moorkyz maintain`. It compresses invalid and expired logs in one ZIP before removing them. Other programs' writes cannot be blocked, so the cap is enforced eventually.
- Trash staging has been removed. Use `node moorkyz archive <path> [path ...]` to archive selected project-relative files/directories directly. Existing copies' legacy trash data is not automatically migrated or deleted; review it before explicitly archiving it. The retired `storage.maxTrashBytes` setting and `includeTrash` API option fail explicitly rather than being silently ignored.
- Managed ZIPs have a default **100 GB = 100,000,000,000 compressed-byte** total cap. Expired ZIPs are deleted first, then eligible ZIPs are pruned until the remaining total is at or below the cap. Exactly-at-cap archives are retained.
- Each archive expires after **30 days** by default, measured from the UTC creation timestamp in its canonical filename, not filesystem access/modification time. An archive exactly at its lifetime is retained until it is older. Set the age limit to `0` to disable expiry.
- No independent watcher runs when managed services are stopped. External writes can temporarily exceed the limit; other code must invoke maintenance periodically. Deletions by other tools cannot be intercepted; use `moorkyz archive` for recoverable deletion.

Applications writing managed logs should call `createLog(root, { policy })`, then `registerLog(root, logPath)` and call the returned release callback after closing the stream. Live PID leases in `.moorkyz/log-leases/` protect those logs from any process's maintenance; dead leases are cleaned automatically. Run `maintainStorage(root, { policy, reserveLogs: 1 })` before opening a new log; creation refuses to exceed the same configured cap. Omit `policy` to use defaults, or pass the same configured settings to all helpers. Code API (CommonJS):

```js
const { archivePaths, maintainStorage, storagePolicy } = require("./moorkyz");
const root = process.cwd();
const policy = storagePolicy({
  maxArchiveBytes: 100_000_000_000,
  maxArchiveAgeDays: 30,
  archivePruneOrder: "oldest",
});
const result = await archivePaths(root, ["generated/report.json", "old-assets"], { policy });
if (result.retention.lowSpace) console.error("Archive retention could not free enough space.");
if (result.retention.overLimit) console.error("Protected archives still exceed the size cap.");
if (result.retention.expiredRemaining) console.error("Some expired archives could not be removed.");
const maintained = await maintainStorage(root, { policy });
if (maintained.pruned.lowSpace) console.error("Storage maintenance could not free enough space.");
if (maintained.pruned.overLimit) console.error("Protected archives still exceed the size cap.");
if (maintained.pruned.expiredRemaining) console.error("Some expired archives could not be removed.");
```

`archivePaths` accepts `{ remove: false }` for copy-only backups; serialize concurrent library calls yourself.

Set the following under `storage` in `moorkyz.config.json` (merge with existing settings), or pass the same fields to `storagePolicy`:

```json
{
  "storage": {
    "maxArchiveBytes": 100000000000,
    "maxArchiveAgeDays": 30,
    "archivePruneOrder": "oldest"
  }
}
```

`maxArchiveBytes` is a non-negative safe integer in bytes; multiply your desired
decimal GB by 1,000,000,000. `maxArchiveAgeDays` is a non-negative safe integer in
days. `archivePruneOrder` accepts `"oldest"` (creation timestamp, default) or
`"largest"` (compressed ZIP size descending, oldest filename breaks ties).
Expiry applies regardless of size/order. A zero-byte cap requests removal of all
eligible archives. A newly created ZIP is protected for its creation pass, even
when larger than the cap; the CLI warns, and a later maintenance run may delete it.
Live archive leases and explicitly protected paths are also retained and counted
in the managed-byte total. Unrecognized filenames, directories, symlinks and
non-ZIP data are never pruned; noncanonical names are outside the managed budget.
Canonical-looking non-ZIP files count toward the budget but are preserved with
explicit warnings if they prevent compliance. Code callers inspect `bytes`,
`maxBytes`, `overLimit` and `expiredRemaining` on the retention result.

Archives are named `.archive/log_yyyy-mm-dd-hh-mm-ss-mmm.zip`, keep relative UTF-8 paths, permissions and empty directories, and stream with bounded buffers. Classic ZIP limits (under 4 GiB, at most 65534 entries) fail before source removal; split oversized data into supported operations before retrying. Each ZIP is decompressed and checked (CRC32, SHA-256), and sources are re-checked before unlinking. The root, Git metadata, runtime state, the archive directory, symlinks and special files cannot be selected. Stop writers first; this is not a sandbox against racing processes.

The existing free-space safeguard checks the archive filesystem before archival and after source removal: below the greater of 1 GiB or 5% free, eligible canonical ZIPs are deleted in the chosen pruning order until the greater of 2 GiB or 10% is free. It can prune before age/size limits are reached. Configure `minFreeBytes`, `targetFreeBytes`, `minFreePercent` and `targetFreePercent` under `storage`; set all four to `0` to use only age/size retention. Only canonical ZIPs in `.archive/` are pruned, never source files, newly created ZIPs or archives still removing their sources. The CLI warns on stderr if eligible archives cannot reach a target; code callers inspect `retention.lowSpace` (archive result) or `pruned.lowSpace` (maintenance result), plus the size/expiry flags above. Archives are compressed, not encrypted; keep durable backups elsewhere.

No script is needed inside `.archive/`. The root CLI already runs cleanup before
managed starts, every 30 seconds while a service runs, on explicit archival, and
when you run `node moorkyz maintain`. When no service/CLI operation is active,
there is no background cleanup. For strict wall-clock expiry even while idle,
configure an external scheduler to run that command from the project root; no
system task is installed by this template.

## Verification

Run `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause` with Node.js
24 LTS on PATH. The [maintenance runner](../.template/maintenance/README.md) checks every
script/runnable without applying its actions, then checks documentation,
icon/CI references and preset configuration syntax. Selector, Copilot and storage/audit action
checks use only newly created disposable copies, never this repository
or existing runtime data.
All PowerShell entrypoints accept `-DryRun`; `node moorkyz <command> --dry-run`
checks the command name and returns before configuration loading, process
management, package commands or file changes. These are no-op entrypoint checks,
not simulations of the real action or validation of its arguments/configuration.
Existing setup `-WhatIf` previews remain available. Checkups never clean existing
data or edit profiles; action-level regressions require disposable fixtures.

References: Node 24 [net](https://nodejs.org/docs/latest-v24.x/api/net.html), [fs](https://nodejs.org/docs/latest-v24.x/api/fs.html), [child_process](https://nodejs.org/docs/latest-v24.x/api/child_process.html), [zlib](https://nodejs.org/docs/latest-v24.x/api/zlib.html); [npm run](https://docs.npmjs.com/cli/v11/commands/npm-run/), [npm ci](https://docs.npmjs.com/cli/v11/commands/npm-ci/), [Yarn install](https://yarnpkg.com/cli/install), [Yarn audit](https://yarnpkg.com/cli/npm/audit); [PKWARE APPNOTE](https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT).
