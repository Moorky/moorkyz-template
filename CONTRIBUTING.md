# Contributing

Check the [template-tool catalog](.template/README.md) when a task may need existing
template tooling. Read the relevant README and use that tool when it fits; do not
run all tools automatically. Keep template entrypoint(s) and README together in
`.template/<tool>/`, with support files under `helpers/`.
Keep project-owned source and tooling separate from this reusable template baseline.

Read [README.md](README.md), [AGENTS.md](AGENTS.md) and the
[work queue](AGENT_SCHEDULER.md) first. Preserve unrelated work.

## Work steps

Use the same four phases as [the agent workflow](AGENTS.md#workflow). Keep the
effort proportional to the change, but do not skip required evidence or approvals.

### Analyzing and Reading

- Read the request, affected source, callers, documentation and tests; inspect
  Git state and preserve unrelated work.
- Record the requested outcome, acceptance criteria and relevant edge cases.
- For a bug report, include the affected commit, operating system, Node and
  PowerShell versions, exact command, expected/actual behavior and a minimal
  reproduction using disposable data. Redact private paths and output.
- Coordinate shared files through the work queue. Do not take over active work,
  stage another contributor's changes or rewrite their history.

### Researching and Planning

- Search existing issues, documentation and reusable helpers before proposing
  new behavior. Consult the template-tool catalog and read only fitting guides.
- Check unfamiliar APIs, commands and external guidance against authoritative
  sources and the installed/supported versions; record assumptions and limits.
- Choose a focused approach and identify affected consumers, documentation,
  generated outputs and checks before developing.
- For a feature, describe the problem and acceptance criteria before choosing a
  product runtime, adding dependencies or changing a public command. Obtain any
  required approval before high-impact or external actions.

Use a supported Node.js 24 LTS patch and PowerShell 7 (`pwsh`) for the full
maintenance command. Windows PowerShell 5.1 compatibility is also covered by
the relevant script checks. The root template needs no package installation.
Optional presets are configuration, not instructions to install every tool.

### Developing

- Keep each change focused and update related docs and tests. Preserve behavior
  outside the request and do not silently change public commands or defaults.
- Keep the root stack-neutral; framework-specific files belong in
   `.template/project-types/helpers/types/<type>/` at their root-relative path. See the
   [project types guide](.template/project-types/README.md). Shared tooling stays in `.template/`.
- Keep new checkups read-only and give PowerShell entrypoints a side-effect-free
  `-DryRun` option.

Use disposable fixtures for copying, adoption, settings and storage actions.
`-DryRun` / `--dry-run` checks entrypoint loading only; it is not a substitute
for testing real actions safely. Never run adoption or destructive storage
commands against this template as a test.

### Clean Up

Complete these gates in order before the final audit and local commit:

1. **Test the changes.** Verify acceptance criteria, regression behavior and edge
   cases. Run `pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause`
   with Node.js 24 LTS on PATH, plus affected product tests, builds, type and lint
   checks. Mark each result `PASS`, `FAIL`, `NOT RUN` with a reason, or `N/A`.
2. **Review best practices and safety.** Inspect all task-owned changes for
   correctness, maintainability, consistency, redundant/dead code, unnecessary
   dependencies, compatibility, error handling, secrets and missing coverage.
   Fix findings within scope and repeat affected tests. Record who reviewed the
   work and distinguish self-review, independent review and human approval.
   Required approval is a gate; unrequested optional review stays pending or
   not requested, never implicitly approved by passing tests.
3. **Validate final references and content.** Check changed code and consumers
   for unresolved imports/exports/symbols, incorrect path casing, missing files
   or assets, unavailable APIs/dependencies, invalid commands and configuration.
   Check documentation links and anchors too. Verify changed external references
   and version-specific claims against their authoritative source; record exact
   unreachable/unverifiable content, impact and any blocker rather than inventing
   replacements. Local maintenance checks do not prove external availability.
4. **Update and recheck everything affected.** Synchronize guides, examples,
   generated outputs and the task's queue evidence. Regenerate only affected
   outputs with existing tools; never hand-edit generated HTML. When the README
   changes, use:

   ```powershell
   node .\moorkyz readme
   node .\designs\build.mjs
   pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause
   ```

   Keep optional collection sources and editions together. Remove only your
   own disposable fixtures and temporary artifacts, not existing user data.
   Repeat affected tests, quality review and reference checks after corrections
   or regeneration so the final state, not an earlier draft, is verified.
5. **Audit the evidence.** Run `node moorkyz audit "task title"` and fill in the
   [audit template](docs/AUDIT_TEMPLATE.md): phase decisions, actual commands and
   results, review findings, reference availability, docs updated, blockers,
   remaining risks and human-review status. A draft is not verification.
6. **Commit and report.** Inspect the staged diff and run `git diff --cached --check`.
   Commit only task-owned changes and their audit in one focused local commit
   when required checks and approvals pass. Report the outcome, evidence, audit
   path, commit hash and remaining risks; record completion or a precise handoff
   in the queue. Do not mark blocked work complete or push without approval.

## Review checklist

- The requested behavior and edge cases have reproducible evidence.
- Relevant tests, syntax checks and generated files are current. Report each
  check as `PASS`, `FAIL`, `NOT RUN` with a reason, or `N/A`.
- Documentation explains changed commands, defaults and compatibility limits.
- Final code references, local links and changed external content have explicit
  verification evidence or a recorded limitation; generated outputs are current.
- The audit records actual results, secret review, blockers, remaining risks and
  whether a human reviewed or approved the work. Self-review is labeled as such.
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
