# Run

## When to use

Double-click [RUN.cmd](../../RUN.cmd) in the repository root, or run `.\RUN.cmd`
in a terminal, to go from a fresh copy to the running program in one step. Later
runs repeat only the steps whose inputs changed. See the
[template-tool catalog](../README.md).

```powershell
.\RUN.cmd              # check what is needed, then start the default program
.\RUN.cmd --no-start   # check only; nothing is started
.\RUN.cmd --force      # repeat installs and checks even if nothing changed
.\RUN.cmd admin        # another program configured in moorkyz.config.json
node moorkyz up        # the same steps on any platform with Node.js 24
```

## What happens

| Step | First run | Later runs |
|---|---|---|
| Runtime | Uses Node.js from PATH when it matches [`.node-version`](../../.node-version), else one kept in `%LOCALAPPDATA%\Moorkyz\runtimes`; otherwise asks before downloading the official build and verifies its SHA-256 checksum | Reuses the runtime |
| Files | Confirms the configured program exists: a static entry page, or `package.json` with its `dev` script | Same, instantly |
| Packages | Installs exactly from the reviewed lockfile (`npm ci`, `pnpm install --frozen-lockfile`, ...) when dependencies are declared | Only when the lockfile or `package.json` changed, or `node_modules` is missing |
| Checks | Runs the configured checks, or the `verify`/quality scripts, then checks file references | Only when a file or the Node.js version changed since they passed |
| Start | Serves a static program on `127.0.0.1`, or runs the `dev` script, and opens the browser | Same |

Each step is one line in the window. A failure stops before anything starts,
shows the last lines of output and says what to do. The program runs in the
foreground: press Ctrl+C or close the window to stop it. Broken references are
shown as a warning and do not block the program; maintenance checks enforce them.

## Programs

[moorkyz.config.json](../../moorkyz.config.json) names the programs and the default
one (see [projects](../../docs/INFRASTRUCTURE.md#projects)). The template ships a
single static program: the template website, checked by its website and design
verifiers. Projects point it at their app, for example
`{ "cwd": "apps/web", "dev": "dev", "url": "http://localhost:3000" }`, or add more.
For another double-click launcher, save `RUN-Admin.cmd` next to `RUN.cmd` with:

```bat
@call "%~dp0RUN.cmd" admin %*
```

## Safety and limits

- Downloads happen only after you agree (or with `-Yes`), from nodejs.org or the
  mirror in `MOORKYZ_NODE_MIRROR`, whose checksum list is trusted the same way. The
  archive must match its published SHA-256; staging files are removed on any
  failure, and the runtime stays per user. PATH changes only for the run.
- The preview server listens on `127.0.0.1` only. It never serves hidden files or
  folders (`.git`, `.env`, `.moorkyz`), rejects path traversal, answers wrong
  filename casing with 404 like case-sensitive production servers, and disables
  caching.
- The cache is `.moorkyz/<program>.up.json` (ignored by Git). `--force`, or deleting
  it, repeats every step. A changed Node.js version also repeats the checks.
- RUN.cmd is for people: it keeps the program in the foreground. Agents and CI use
  `node moorkyz up --no-start` for the checks, and `moorkyz start` for managed
  background services.
- `-DryRun` only loads the script. `-RuntimeOnly` makes sure Node.js is available
  and prints the path of `node.exe` for other tools, such as Claim Template.
- Non-Windows systems run `node moorkyz up` with their own Node.js 24; the download
  offer is Windows-only.

The [run checkup](../maintenance/helpers/checkups/10-run.ps1) exercises the
download (with a local mirror), the cache, failures and the preview server in
disposable copies.
