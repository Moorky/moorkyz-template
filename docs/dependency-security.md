# Dependency maintenance

Consult the [template-tool catalog](../.template/README.md) when existing tooling may fit
the task. Use reviewed preset/setup tools only when needed; they do not authorize
dependency installation, upgrades or external actions by themselves.

The shared baseline has no root package manifest, lockfile or third-party npm
dependencies. Its GitHub Actions are pinned to commits, Node.js is pinned to
major 24 for shared tooling, and optional presets contain example configuration.
These are different update responsibilities; selecting a preset does not
install or audit its packages.

## GitHub setup

1. Enable Dependency graph, Dependabot alerts and Dependabot security updates in
   the repository settings; [dependabot.yml](../.github/dependabot.yml) alone
   only schedules weekly GitHub Actions updates.
2. Enable private vulnerability reporting in the repository's code-security
   settings (public repositories; see the [current GitHub instructions](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository))
   so the [SECURITY.md](../SECURITY.md) form link works;
   [CreateProject.ps1](../.template/claim-template/CreateProject.ps1) fills in the repository name and owner during one-time adoption.
3. Protect the default branch with required pull requests and passing CI.

These are administrator actions, not effects of copying this repository. Check
the actual settings and private-reporting destination after adoption; do not
assume a configuration file has enabled remote security features.

## Shared tooling updates

- Keep [.node-version](../.node-version), the Node preset's engine range,
  [CI](../.github/workflows/project-tooling.yml) and documented support aligned.
  Use a supported patch in the pinned LTS major; consult the
  [Node.js release schedule](https://nodejs.org/en/about/previous-releases) before
  proposing a major change. A newer Current release is not an automatic upgrade.
- Review Dependabot's GitHub Actions changes against the action's official
  release notes and commit, retain commit-SHA pins, and rerun maintenance on
  Windows and Linux through CI. Keep workflow tokens least-privileged.
- The Node preset's `packageManager` is a reviewed example pin, not a claim to
  track the latest npm release. Choose the adopted project's actual manager
  version deliberately and create its matching authoritative lockfile.
- External documentation links should point to the authoritative maintained
  page. Update moved references and record access failures separately from
  repository test results. Historical audits retain the evidence from their
  original task rather than being rewritten as present-day claims.

## When the stack is chosen

- Declare and pin the package manager and commit one authoritative lockfile
  (for Node, select `.template/project-types/helpers/types/node/` with
  `.\.template\project-types\SetProjectType.ps1 node`; see [project types](../.template/project-types/README.md)).
- Add a reproducible install (for example `npm ci --ignore-scripts`) to CI.
- Add that ecosystem (and `docker`, if used) to Dependabot.
- Run its production dependency audit in CI (for example `npm audit --omit=dev --audit-level=high`).

## Update policy

- No blind `latest` or major upgrades; read release notes and run the full CI.
- Never suppress failed audits or auto-merge unreviewed updates.
- Secrets belong in the deployment environment or ignored local configuration,
  never in workflows, logs, archives or test fixtures.

For each update, record the changed versions or action commits, commands and
actual outcomes, compatibility/migration requirements and unresolved advisories
in the [task audit](AUDIT_TEMPLATE.md). An unavailable registry or missing
credentials means `NOT RUN`, not a clean audit. Do not run `audit fix`, enable
automatic major upgrades or change credentials as part of a read-only check.

## Authoritative references

- [Dependabot configuration options](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference)
- [GitHub Actions security hardening](https://docs.github.com/en/actions/reference/security/secure-use)
- [Reproducible npm installs](https://docs.npmjs.com/cli/v11/commands/npm-ci/)
- [npm audit behavior](https://docs.npmjs.com/cli/v11/commands/npm-audit/)
