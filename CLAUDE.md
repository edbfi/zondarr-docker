# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## This branch is the release channel

`release` (the default branch) builds the latest zondarr release tag; `nightly` builds every commit
to zondarr's `main`. On both branches `call-build` builds and publishes an image on every push, and
the hourly `call-update` refreshes `meta.json` and pushes, which triggers a build. Apart from the
docs and `pullfrog.yml`, the branches differ only in `meta.json`'s channel values (`description`,
`latest`, `version`, `version__command`) and the bot-managed `packages.txt`; the callers,
`build.sh`, both Dockerfiles and the s6 tree under `root/` are the same. Packaging fixes belong on
both branches: run `git diff origin/release origin/nightly -- <path>` before porting anything in
either direction.

Packaging only: both Dockerfiles download the app source from
`https://github.com/edbfi/zondarr/archive/${VERSION}.tar.gz` at build time. No app code lives here.

## Commands

No test suite, linter, formatter or typechecker exists on this branch. Validation means building
the image and running a smoke test.

```sh
./build.sh amd64   # or arm64; needs docker, jq and a git checkout; tags "zondarr-docker-amd64"
docker run --rm --network host zondarr-docker-amd64   # then, from another shell:
curl -fsSL http://localhost:3000                      # test_url in meta.json
```

`./build.sh` fails as committed: `meta.json` has `"version": "null"`, so the build fetches
`archive/null.tar.gz`. To build locally, set `version` to a real upstream ref temporarily and do not
commit it.

## meta.json

- `./build.sh amd64|arm64` turns every key except the `__command` keys into an uppercase
  `--build-arg`. The Dockerfiles consume only `VERSION`, `UPSTREAM_IMAGE` and `UPSTREAM_TAG_SHA`
  (plus `IMAGE_STATS`, which is not in `meta.json`). A new build arg needs a lowercase key here
  plus an `ARG` in both Dockerfiles.
- `<key>__command` is a shell probe whose output is written back to `<key>` by the hourly update
  workflow (and by `./build.sh update`). `version` and `upstream_tag_sha` are resolved values:
  change the `__command`, not them.

## Gotchas

- `linux-amd64.Dockerfile` and `linux-arm64.Dockerfile` are byte-identical. Apply every edit to both.
- Keep the `# syntax=` and `# check=skip=InvalidDefaultArgInFrom` header lines. The skip is what
  lets `FROM ${UPSTREAM_IMAGE}:${UPSTREAM_TAG_SHA}` pass BuildKit's checks.
- `APP_DIR`, `CONFIG_DIR`, `UMASK`, the `hotio` user, `/etc/s6-overlay/scripts/bash-functions`
  (`log_inf`) and the `init-setup`/`init-wireguard` services come from the base image
  (`ghcr.io/edbfi/base-image:alpinevpn`). Use those variables and helpers instead of redefining
  them or hardcoding paths.
- A `oneshot`'s `export` never reaches later services. Persist values with
  `printf '%s' "${VAR}" > /var/run/s6/container_environment/VAR`, as `init-setup-app/run` does.
- Long-running services drop privileges with `exec s6-setuidgid hotio ...`. Don't run the app as root.
- Changing a default port touches `ENV FRONTEND_PORT`/`BACKEND_PORT`/`WEBUI_PORTS` in both
  Dockerfiles, the `!= "3000" || != "8000"` guard in `init-setup-app/run`, and `test_url` in
  `meta.json`.
- `Modified: meta.json` commits come from the bot. Human commits use Conventional Commits.

## Adding an s6 service

All paths are under `root/etc/s6-overlay/`:

1. `s6-rc.d/<name>/type` containing `oneshot` or `longrun`.
2. `s6-rc.d/<name>/run` starting with `#!/command/with-contenv bash`. A `oneshot` also needs `up`
   holding the absolute in-container path of its `run` (copy `init-setup-app/up`).
3. Ordering: an empty file `s6-rc.d/<name>/dependencies.d/<dependency>`. This orders starts only
   and does not wait for readiness.
4. Enable it: an empty file `user-bundles.d/user/contents.d/<name>`. The old location,
   `s6-rc.d/user/contents.d/`, makes the service silently never start on s6-overlay >= 3.2.3.1
   (commit `83de859`).

No `chmod` is needed, because the Dockerfiles `chmod +x` every `run*` under `s6-rc.d`.

## Reference

- `README.md`: names the channels and points to the container docs and the `nightly` README.
  Read it before changing anything user-facing.
- `.github/workflows/call-*.yml` are thin callers into
  `edbfi/base-image/.github/workflows/*-on-call.yml@workflows`. Build, tag and publish logic
  lives there, not here. Read them before assuming how CI consumes `meta.json`.
