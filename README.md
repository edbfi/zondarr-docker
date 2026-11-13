<p align="center">
  <img src="docs/assets/zondarr-docker-logo.svg" alt="zondarr-docker logo" width="160" height="155">
</p>

<h1 align="center">zondarr-docker</h1>

<p align="center"><strong>Multi-architecture Docker packaging for Zondarr.</strong></p>

<p align="center">
  <a href="https://github.com/edbfi/zondarr-docker/blob/release/LICENSE" title="Docker packaging license">
    <img src="https://img.shields.io/badge/License%20(Image)-GPL--3.0-orange?style=flat" alt="Docker packaging license: GPL-3.0">
  </a>
  <a href="https://github.com/moby/moby" title="Moby source, Docker Engine's open-source foundation">
    <img src="https://img.shields.io/badge/Docker-2496ED?style=flat&amp;logo=docker&amp;logoColor=white" alt="Docker">
  </a>
  <a href="https://git.savannah.gnu.org/cgit/bash.git/" title="GNU Bash source">
    <img src="https://img.shields.io/badge/Bash-4EAA25?style=flat&amp;logo=gnubash&amp;logoColor=white" alt="Bash">
  </a>
  <a href="https://github.com/edbfi/zondarr-docker/actions/workflows/call-build.yml?query=branch%3Arelease"><img src="https://img.shields.io/github/actions/workflow/status/edbfi/zondarr-docker/call-build.yml?branch=release&amp;event=push&amp;label=CI&amp;style=flat" alt="CI"></a>
</p>

Docker packaging for [Zondarr](https://github.com/edbfi/zondarr), running its backend and frontend with s6-overlay.

[Documentation and examples](https://web.edb.fi/containers/zondarr/).
See the [nightly README](https://github.com/edbfi/zondarr-docker/blob/nightly/README.md)
for nightly instructions.

Nightly builds from the latest commit on `main`. The `release` branch builds the
latest zondarr release tag; none has been published yet. Do not treat a nightly
image as a stable release.

The release channel follows the app's latest published, non-prerelease GitHub
Release with a plain `X.Y.Z` tag (release titles may say `v`). Publish only an
owner-approved, tested commit from `main`; never move a published tag. A bare
tag does not publish anything.

Images built from a Zondarr version on SvelteKit 3 start the frontend through
`scripts/serve.ts`. Set `ORIGIN` to the address people open in the browser, for
example `ORIGIN=http://192.168.1.10:3000`. It is required when serving plain HTTP:
without it the frontend assumes `https://<Host>`, so signing in, first-run setup and
saving changes fail with 403. Leave it unset only behind an HTTPS reverse proxy that
passes the original `Host`. It must be a bare origin (no path, query or credentials).
`CSRF_ORIGIN` defaults to `ORIGIN` when that is set; set it yourself only to use a
different origin, or when `ORIGIN` is unset.

Behind a reverse proxy, set `ADDRESS_HEADER=x-forwarded-for` (and `XFF_DEPTH` to the
number of proxies, default `1`) only when every request goes through that proxy.
`PROTOCOL_HEADER` and `HOST_HEADER` are for setups without `ORIGIN`, behind a trusted
proxy. `SHUTDOWN_TIMEOUT` defaults to `5` seconds so a plain `docker stop` (10 s)
finishes cleanly; if you raise it, raise the stop timeout too (`docker stop -t`,
`stop_grace_period`). Publish only the frontend port; the backend port is internal.

## License

- Docker packaging: [GPL-3.0 license](LICENSE).
- Application: [AGPL-3.0-or-later source repository](https://github.com/edbfi/zondarr).
