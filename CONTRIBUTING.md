# Contributing

Check the [template-tool catalog](.template/README.md) when a task may need existing
template tooling. Read the relevant README and use that tool when it fits; do not
run all tools automatically. Keep template entrypoint(s) and README together in
`.template/<tool>/`, with support files under `helpers/`.
Keep project-owned source and tooling separate from this reusable template baseline.

Read [README.md](README.md), [AGENTS.md](AGENTS.md) and the
[work queue](AGENT_SCHEDULER.md) first. Preserve unrelated work.

## Before making a change

- Search existing issues and documentation before proposing new behavior.
- For a bug report, include the affected commit, operating system, Node and
  PowerShell versions, exact command, expected/actual behavior and a minimal
  reproduction using disposable data. Redact private paths and output.
- For a feature, describe the problem and acceptance criteria before choosing a
  product runtime, adding dependencies or changing a public command.
- Coordinate shared files through the work queue. Do not take over active work,
  stage another contributor's changes or rewrite their history.

Use a supported Node.js 24 LTS patch and PowerShell 7 (`pwsh`) for the full
maintenance command. Windows PowerShell 5.1 compatibility is also covered by
the relevant script checks. The root template needs no package installation.
Optional presets are configuration, not instructions to install every tool.

## Implementation and verification

1. Keep each change focused and update related docs and tests.
2. Keep the root stack-neutral; framework-specific files belong in
   `.template/project-types/helpers/types/<type>/` at their root-relative path. See the
   [project types guide](.template/project-types/README.md). Shared tooling stays in `.template/`.
3. Run `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause` with
   Node.js 24 LTS on PATH, plus any product checks. Keep new checkups read-only
   and give PowerShell entrypoints a side-effect-free `-DryRun` option.
4. Create an audit with `node moorkyz audit "task title"` and record actual results.
5. Describe the change and its validation in the commit or pull request.

Generated documentation is part of the change when its source changes:

```powershell
node .\moorkyz readme
node .\designs\build.mjs
pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause
```

Regenerate only the outputs affected by the task. Keep the optional collection's
source and generated editions together; do not hand-edit generated HTML.
Maintenance validates local links and generated freshness without rewriting
files. Check external references against their authoritative documentation;
record unreachable URLs rather than claiming that they work.

Use disposable fixtures for copying, adoption, settings and storage actions.
`-DryRun` / `--dry-run` checks entrypoint loading only; it is not a substitute
for testing real actions safely. Never run adoption or destructive storage
commands against this template as a test.

## Review checklist

- The requested behavior and edge cases have reproducible evidence.
- Relevant tests, syntax checks and generated files are current. Report each
  check as `PASS`, `FAIL`, `NOT RUN` with a reason, or `N/A`.
- Documentation explains changed commands, defaults and compatibility limits.
- The audit records actual results, secret review, blockers, remaining risks and
  whether a human reviewed the work.
- The change includes only task-owned files and no secrets, runtime data or
  unrelated formatting. Publication and other external actions need approval.

There is no application deployment or package publication implied by passing
template checks. Product-specific checks belong to the adopted project's
documented stack and must be run separately.

## Safety and licensing

Never commit secrets, personal data or logs. The local `.logs/`,
`.archive/` and `.moorkyz/` folders stay ignored; never migrate or delete existing data without approval. Audits stay tracked in `.audits/`. Report vulnerabilities as described in
[SECURITY.md](SECURITY.md), not in public issues.

Keep applicable notices from [LICENSE](LICENSE), and identify the origin and
license of newly introduced third-party assets. Do not copy reference sites'
proprietary content into the template.
