# Contributing

Check the [script catalog](.scripts/README.md) when a task may need existing
tooling. Read the relevant README and use that tool when it fits; do not run all
scripts automatically. Keep entry script(s) and README together in
`.scripts/<tool>/`, with support files under `helpers/`.

Read [README.md](README.md), [AGENTS.md](AGENTS.md) and the
[work queue](AGENT_SCHEDULER.md) first. Preserve unrelated work.

1. Keep each change focused and update related docs and tests.
2. Keep the root stack-neutral; framework-specific files belong in
   `.scripts/project-types/helpers/types/<type>/` at their root-relative path. See the
   [project types guide](.scripts/project-types/README.md). Shared tooling stays in `.scripts/`.
3. Run `pwsh -NoProfile -File .\.scripts\maintenance\RunCheckups.ps1 -NoPause` with
   Node.js 24 LTS on PATH, plus any product checks. Keep new checkups read-only
   and give PowerShell entrypoints a side-effect-free `-DryRun` option.
4. Create an audit with `node moorkyz audit "task title"` and record actual results.
5. Describe the change and its validation in the commit or pull request.

Never commit secrets, personal data or logs. The local `.trash/`, `.logs/`,
`.archive/` and `.moorkyz/` folders stay ignored; never migrate or delete existing data without approval. Audits stay tracked in `audits/`. Report vulnerabilities as described in
[SECURITY.md](SECURITY.md), not in public issues.
