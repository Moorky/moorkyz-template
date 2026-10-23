# Dependency maintenance

Consult the [template-tool catalog](../.template-tools/README.md) when existing tooling may fit
the task. Use reviewed preset/setup tools only when needed; they do not authorize
dependency installation, upgrades or external actions by themselves.

The baseline has no package manifest, lockfile or third-party dependencies; only
the pinned GitHub Actions are updated.

## GitHub setup

1. Enable Dependency graph, Dependabot alerts and Dependabot security updates in
   the repository settings; [dependabot.yml](../.github/dependabot.yml) alone
   only schedules weekly GitHub Actions updates.
2. Enable private vulnerability reporting (Settings → Advanced Security; public
   repositories) so the [SECURITY.md](../SECURITY.md) form link works;
   [CreateProject.ps1](../.template-tools/claim-template/CreateProject.ps1) fills in the repository name and owner during one-time adoption.
3. Protect the default branch with required pull requests and passing CI.

## When the stack is chosen

- Declare and pin the package manager and commit one authoritative lockfile
  (for Node, select `.template-tools/project-types/helpers/types/node/` with
  `.\.template-tools\project-types\SetProjectType.ps1 node`; see [project types](../.template-tools/project-types/README.md)).
- Add a reproducible install (for example `npm ci --ignore-scripts`) to CI.
- Add that ecosystem (and `docker`, if used) to Dependabot.
- Run its production dependency audit in CI (for example `npm audit --omit=dev --audit-level=high`).

## Update policy

- No blind `latest` or major upgrades; read release notes and run the full CI.
- Never suppress failed audits or auto-merge unreviewed updates.
- Secrets belong in the deployment environment or ignored local configuration,
  never in workflows, logs, archives or test fixtures.
