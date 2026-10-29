# Template changelog

Releases of the Moorkyz template, newest first. A release is a `vMAJOR.MINOR.PATCH`
Git tag ([Semantic Versioning](https://semver.org/)) on a commit whose release
checks passed; any other commit is a development build, named by its commit
(`node moorkyz version`). Adopted projects record the template version and commit
they started from in their adoption record, and keep this file as part of the
template tooling. The release procedure is in
[TEMPLATE_INTRODUCTION.md](../TEMPLATE_INTRODUCTION.md#release-the-template).

## v1.0.0 — 2026-10-29

First release.

- **Run in one step.** [RUN.cmd](../RUN.cmd) provides the pinned Node.js (an official
  build, downloaded only with consent and verified against its SHA-256 checksum),
  checks files, packages and tests, repeating only what changed, and starts the
  program. `node moorkyz up` does the same on any platform.
- **Adopt with verified provenance.** [Claim Template](claim-template/README.md)
  recognizes clones, GitHub template copies and GitHub ZIP downloads, verifies the
  template commit in the template repository, records the release or development
  build, and starts the project's own audit trail.
- **References you can rely on.** `node moorkyz references` checks links and literal
  paths in Markdown, HTML, CSS, scripts, JSON, YAML, PowerShell, batch files and
  Dockerfiles, and reports dynamic paths instead of guessing.
- **Long Windows paths.** Script icons plan shortcuts first and explain the ones
  Windows cannot store, instead of failing midway.
- **Baseline.** Agent contract and work queue, task audits, maintenance checkups,
  project-type presets, Copilot settings, script icons, soft copy, twenty designs
  with README and landing editions, and the template website.
