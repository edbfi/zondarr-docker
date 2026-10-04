# Zondarr Docker Image

<p align="center">
  <img src="https://web.edb.fi/img/image-logos/zondarr.svg" alt="zondarr" style="width: 30%;"/>
</p>

<p align="center">
  <a href="https://github.com/edbfi/zondarr-docker/blob/nightly/LICENSE"><img src="https://img.shields.io/badge/License%20(Image)-GPL--3.0-orange" alt="License (Image)"></a>
  <a href="https://github.com/edbfi/zondarr"><img src="https://img.shields.io/badge/License%20(App)-AGPL--3.0-blue" alt="License (App)"></a>
  <a href="https://github.com/edbfi/zondarr/stargazers"><img src="https://img.shields.io/github/stars/edbfi/zondarr.svg" alt="GitHub Stars"></a>
</p>

## About

Zondarr is a full-stack application with a Python/Litestar backend and SvelteKit/Bun frontend. This Docker image runs both services using s6-overlay process supervision.

Only nightly images have been published; no stable application release has been selected. Builds pin the application revision, source checksum, Bun, uv, Python and native base images.

## Docker Compose

```yaml
services:
  zondarr:
    container_name: zondarr
    image: ghcr.io/edbfi/zondarr-docker:nightly
    ports:
      - 3000:3000   # Frontend (SvelteKit SSR)
    environment:
      - PUID=1000
      - PGID=1000
      - UMASK=002
      - TZ=Etc/UTC
      # - SECRET_KEY=           # Auto-generated on first run, persisted to /config/data/.secret_key
      # - DATABASE_URL=         # Default: SQLite at /config/data/zondarr.db
      # - ORIGIN=http://192.168.1.10:3000  # Public URL of the frontend; required for plain HTTP
      # - PUBLIC_API_URL=       # Leave empty to use the same-origin API proxy
      # - SECURE_COOKIES=true   # Set when serving over HTTPS (enforces Secure flag on cookies)
      # - CSRF_ORIGIN=https://zondarr.example.com  # Defaults to ORIGIN; set it only without ORIGIN or to differ
      # - PLEX_API_TIMEOUT_SECONDS=30  # Timeout for Plex API calls (min: 5)
      # - GRANIAN_WORKERS=1            # Worker processes (keep 1 for SQLite)
    volumes:
      - ./config:/config
    restart: unless-stopped
```

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `PUID` | `1000` | User ID for file permissions |
| `PGID` | `1000` | Group ID for file permissions |
| `UMASK` | `002` | File creation mask |
| `TZ` | `Etc/UTC` | Timezone |
| `SECRET_KEY` | *(auto-generated)* | JWT signing key. Auto-generated on first run and persisted to `/config/data/.secret_key`. Set explicitly to override. |
| `DATABASE_URL` | `sqlite+aiosqlite:///config/data/zondarr.db` | Database connection string. Supports SQLite (default) and PostgreSQL. |
| `ORIGIN` | *(none)* | Public origin of the frontend, for example `http://192.168.1.10:3000`. **Required when serving plain HTTP**: without it the frontend assumes `https://<Host>` and rejects every write (sign-in, first-run setup, saves) with 403, and logs a startup warning. Leave it unset only behind an HTTPS reverse proxy that passes the original `Host`. Must be a bare `http(s)` origin (no path, query or credentials), or the frontend does not start. `CSRF_ORIGIN` defaults to it. |
| `PUBLIC_API_URL` | *(empty)* | Leave empty to use the same-origin frontend API proxy. |
| `INTERNAL_API_URL` | `http://localhost:8000` | Internal backend URL, derived from `BACKEND_PORT` by default. |
| `SECURE_COOKIES` | `false` | Set to `true` when serving over HTTPS to enforce the Secure flag on cookies. |
| `CSRF_ORIGIN` | `ORIGIN` *(if set)* | Trusted origin for CSRF protection. Defaults to `ORIGIN` when that is set; set it only to use a different origin. Without `ORIGIN`, set it to your public URL (e.g., `https://zondarr.example.com`). |
| `PLEX_API_TIMEOUT_SECONDS` | `30` | Timeout in seconds for Plex API requests. Minimum: 5. Increase for slow/remote Plex servers. |
| `GRANIAN_WORKERS` | `1` | Number of Granian worker processes. Keep at 1 for SQLite. Increase to match CPU cores when using PostgreSQL. |
| `ADDRESS_HEADER`, `XFF_DEPTH` | *(none)*, `1` | Behind a reverse proxy, set `ADDRESS_HEADER=x-forwarded-for` (and `XFF_DEPTH` to the number of proxies) only when every request goes through that proxy, so the frontend sees the real client address. |
| `PROTOCOL_HEADER`, `HOST_HEADER` | *(none)* | Only without `ORIGIN`, behind a trusted proxy that sets them. |
| `SHUTDOWN_TIMEOUT` | `5` | Seconds the frontend waits for open requests when the container stops. The default lets a plain `docker stop` (10 s) finish cleanly; if you raise it, raise the stop timeout too (`docker stop -t`, `stop_grace_period`). |

## Ports

| Port | Service |
|---|---|
| `3000` | Frontend — SvelteKit SSR server (Bun) |
| `8000` | Backend — Litestar API server (Granian) |

## Data Persistence

All persistent data is stored in `/config/data/`:
- `zondarr.db` — SQLite database (default)
- `.secret_key` — Auto-generated JWT signing key
- `.bootstrap_token` — Persistent first-admin setup token

Back up the entire `/config` volume before replacing the container. Preserve any explicitly supplied `SECRET_KEY`. The frontend setup page uses the bootstrap token for first-admin creation; only the frontend port needs publishing. Set `ORIGIN` to your public URL when serving plain HTTP or behind a reverse proxy that does not preserve `Host` (`CSRF_ORIGIN` follows it), and enable `SECURE_COOKIES` for HTTPS.

Database migrations (Alembic) run automatically on every container startup.

## Building

Run `./build.sh amd64` or `./build.sh arm64` from the repository root to build the image locally. It needs `docker` and `jq`, passes the `meta.json` keys as build arguments, and the Dockerfiles verify the source archive against `source_sha256`. No workflow in this repository builds or publishes images.

## License

- **Docker Image**: Licensed under the GPL-3.0 License. See the [LICENSE](https://github.com/edbfi/zondarr-docker/blob/nightly/LICENSE) file for details.
- **Zondarr Application**: Licensed under the AGPL-3.0 License. See the [zondarr repository](https://github.com/edbfi/zondarr) for details.
