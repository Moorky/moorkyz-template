# Deploy the template website

This is the deployment contract for **https://template.moorkyz.com**:
GitHub supplies the reviewed source, Coolify builds and runs the static container
on an existing Hetzner server, and Cloudflare manages DNS. This does not change
the template baseline into a Node application or install a database.

**Status:** the package passes local and clean-source verification. Production
activation is in progress on the existing Coolify destination; Cloudflare DNS
has been created, but public TLS, the deployed revision and remote GitHub checks
must still be verified. Do not treat the package or DNS record as proof of a
healthy production deployment.

## What is published

[build.mjs](build.mjs) packages the root catalog, top-level website HTML/CSS/JS,
and public HTML/CSS/JS/image/font files under `designs/`. It does not publish
repository metadata, secrets, tools, audits or local runtime data. README
edition links to repository-only documentation are rewritten to the same
commit on GitHub; internal template links retain their relative paths.
The selected commit must therefore exist on GitHub before production deployment.

The [Dockerfile](Dockerfile) builds with Node.js 24, then serves only packaged
files with unprivileged Nginx on port **8080**. Node is not present in the final
runtime image. The Dockerfile-specific [ignore file](Dockerfile.dockerignore)
excludes repository metadata and local configuration from the build context.
The build and runtime images are digest-pinned; review and update those digests
when applying upstream security updates.

`/healthz` reports container liveness. `/version.json` reports the full source
commit. Missing files return 404; there is no SPA fallback. Same-origin framing
is permitted for the template viewer. Browsers revalidate assets because their
filenames are not content-hashed.

## Required access

- The documented shared Coolify instance is
  [deploy.moorkyz.com](https://deploy.moorkyz.com). Configuration requires an
  authorized operator session and the intended project/environment and
  destination server; no dashboard credential belongs in the application image.
- The intended existing Hetzner server/IP. Provisioning a new paid server
  requires a separate approved budget; none is assumed.
- The public Git source for `Moorky/moorkyz-template` needs no credential.
  If the repository becomes private, use a scoped GitHub App installation or
  deploy key. Never put a GitHub token in the image or build args.
- Cloudflare access to the `moorkyz.com` zone. For API access, use a token scoped
  to **Zone:Read** and **DNS:Edit** for this zone, not a global API key.

Use local credential storage, Coolify secrets or GitHub environment secrets.
Do not paste credentials into this repository, workflow logs or chat.
Use an authorized Cloudflare zone session. Do not assume that the Coolify
control-plane hostname's IP is the website's Hetzner origin; verify the
destination against the existing production records before creating DNS.

## Local verification

Use Node.js 24 and a running Linux Docker engine. From the repository root:

```powershell
$commit = git rev-parse HEAD
node .\website\verify.mjs
node --test .\website\deploy\build.test.mjs
docker build --build-arg "SOURCE_COMMIT=$commit" --file .\website\deploy\Dockerfile --tag moorkyz-template:check .
docker run --detach --name moorkyz-template-check --read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges --publish 127.0.0.1:8080:8080 moorkyz-template:check
$env:EXPECTED_COMMIT = $commit
node .\website\deploy\verify.mjs http://127.0.0.1:8080
docker rm --force moorkyz-template-check
Remove-Item Env:\EXPECTED_COMMIT
pwsh -NoProfile -File .\.template\maintenance\RunCheckups.ps1 -NoPause
```

Wait for `/healthz` to respond before running the HTTP verification. Use a free
local port and a unique container name if these are occupied; do not stop
another user's container. Always remove the test container when finished.
Use a clean, reviewed Git snapshot for publication: a working-tree build with
uncommitted changes is not proof that those changes are available at its SHA.

The [GitHub workflow](../../.github/workflows/template-website.yml) runs the
catalog, packaging, real-container HTTP and full maintenance checks on pushes,
pull requests and manual dispatch. It deliberately has no deployment credentials
and does not claim to have configured GitHub or Coolify remotely.

## Coolify configuration

On the **existing, approved Hetzner destination**, create an application from
the GitHub repository. Confirm these settings against the installed Coolify
version; UI names can vary:

| Setting | Value |
|---|---|
| Repository | `Moorky/moorkyz-template` |
| Branch | `master` (the current repository branch) |
| Build pack | Dockerfile |
| Base directory / build context | Repository root (`/`) |
| Dockerfile location | `/website/deploy/Dockerfile` |
| Exposed container port | `8080` |
| Domain | `https://template.moorkyz.com` |
| Health check | HTTP GET `/healthz`, port `8080`, expect `200` |
| Persistent volumes / database | None |
| Build argument | `SOURCE_COMMIT`, the exact full deployed Git SHA |

Under **Advanced > Build**, make `SOURCE_COMMIT` **Available during build**;
current Coolify versions otherwise exclude it for caching. The Dockerfile
declares its own build argument. A missing SHA fails the build explicitly.
Do not publish port 8080 directly: let the Coolify proxy terminate HTTPS.

The initial release uses public Git source and reviewed manual deployments.
For optional automation, connect a scoped GitHub App and verify webhook
delivery in GitHub and Coolify. Keep automatic deployments **off** until the
initial clean snapshot passes CI, the integration is verified, and production
routing is checked.
For subsequent updates, deploy only a reviewed commit with passing
`Project tooling` and `Template website` checks. Coolify's native push webhook
must not be assumed to wait for GitHub CI; a CI-gated deployment integration
must be configured and tested against the installed Coolify before enabling it.
No such remote integration is claimed by this package.

## Cloudflare DNS and HTTPS

1. Confirm the actual Hetzner/Coolify public origin IP. Inspect existing records
   for `template.moorkyz.com`; do not overwrite an existing target blindly.
2. Create the `template` **A** record pointing to that origin IPv4. Add an AAAA
   record only if this exact origin has working IPv6/proxy routing.
3. Initially select **DNS only** so Coolify can obtain a public certificate.
   Allow inbound TCP 80/443 to the Coolify proxy and preserve existing SSH
   restrictions. Do not expose Docker, databases or the Coolify admin API.
4. Deploy the reviewed Git commit in Coolify and verify the origin certificate
   and HTTPS domain. Enable Cloudflare proxying only after origin HTTPS works.
5. Use **Full (strict)** SSL/TLS, never Flexible. If other applications share
   the zone, do not change zone-wide TLS settings without checking their
   origin certificates; use a hostname-scoped rule where appropriate.
6. Bypass any existing **Cache Everything** rule for this hostname, especially
   `/version.json`, `/healthz` and HTML. Do not enable script rewriting such as
   Rocket Loader without rechecking the local template scripts.

Do not request a Cloudflare Origin CA key or change account-wide credentials
just to deploy this site. Coolify's public certificate is sufficient.

## Production acceptance and rollback

After the source is pushed and the infrastructure is configured:

```powershell
Resolve-DnsName template.moorkyz.com
$env:EXPECTED_COMMIT = git rev-parse HEAD
node .\website\deploy\verify.mjs https://template.moorkyz.com
Remove-Item Env:\EXPECTED_COMMIT
```

Also verify a valid certificate, HTTP-to-HTTPS redirect, desktop/mobile viewer,
Full View, README documentation links and the actual Coolify deployment logs.
The HTTP verifier crawls same-origin public links, checks the exact source SHA,
and confirms repository/private routes cannot be served. It does not replace
browser review or prove the GitHub webhook has run.

For rollback, select the previous known-good commit/deployment in Coolify,
redeploy it and rerun the public checks with that SHA. There is no application
state or migration to roll back. Preserve DNS unless the origin changes.

## References

- [Coolify Dockerfile builds and source-commit availability](https://coolify.io/docs/applications/builds/dockerfile)
- [Cloudflare Full (strict) requirements](https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes/full-strict/)
