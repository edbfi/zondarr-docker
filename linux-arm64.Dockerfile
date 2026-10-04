# syntax=docker/dockerfile:1
# check=skip=InvalidDefaultArgInFrom
ARG UPSTREAM_IMAGE
ARG UPSTREAM_TAG_SHA

# ── Stage 1: Frontend Builder ──────────────────────────────────────
FROM oven/bun:alpine AS frontend-builder
RUN apk add --no-cache curl
ARG VERSION
RUN mkdir /build && \
    curl -fsSL "https://github.com/engels74/zondarr/archive/${VERSION}.tar.gz" \
      | tar xzf - -C "/build" --strip-components=1
WORKDIR /build/frontend
# bun install runs the root prepare script even with --production, and it needs dev
# dependencies (svelte-kit). Remove it before the production install.
RUN bun install --frozen-lockfile && \
    bun run build && \
    rm -rf node_modules && \
    bun -e 'const p = await Bun.file("package.json").json(); delete p.scripts.prepare; await Bun.write("package.json", JSON.stringify(p));' && \
    bun install --production --frozen-lockfile

# ── Stage 2: Backend Builder ───────────────────────────────────────
FROM ghcr.io/astral-sh/uv:alpine AS backend-builder
RUN apk add --no-cache curl
ARG VERSION
RUN mkdir /build && \
    curl -fsSL "https://github.com/engels74/zondarr/archive/${VERSION}.tar.gz" \
      | tar xzf - -C "/build" --strip-components=1
WORKDIR /build/backend
ENV UV_PYTHON_INSTALL_DIR=/opt/python
RUN uv sync --python 3.14 --no-dev --frozen --compile-bytecode --no-editable

# ── Stage 3: Runtime ───────────────────────────────────────────────
FROM ${UPSTREAM_IMAGE}:${UPSTREAM_TAG_SHA}
ARG IMAGE_STATS
# Docker stops a container after 10 s by default; the Hotio s6 teardown after the app exits
# takes about 3.3 s, so the app may drain requests for 5 s and still exit in time. Override
# with -e SHUTDOWN_TIMEOUT=<seconds> together with a longer stop timeout (docker stop -t).
ENV IMAGE_STATS=${IMAGE_STATS} \
    FRONTEND_PORT=3000 \
    BACKEND_PORT=8000 \
    WEBUI_PORTS="3000/tcp,3000/udp,8000/tcp,8000/udp" \
    SHUTDOWN_TIMEOUT=5
EXPOSE ${FRONTEND_PORT} ${BACKEND_PORT}

# Bun runtime
RUN apk add --no-cache curl unzip && \
    curl -fsSL https://bun.sh/install | bash && \
    mv /root/.bun/bin/bun /usr/local/bin/ && \
    rm -rf /root/.bun

# Standalone Python 3.14 (musl) from builder
COPY --from=backend-builder /opt/python /opt/python

# Backend: venv + source + migrations
COPY --from=backend-builder /build/backend/.venv "${APP_DIR}/backend/.venv"
COPY --from=backend-builder /build/backend/src "${APP_DIR}/backend/src"
COPY --from=backend-builder /build/backend/migrations "${APP_DIR}/backend/migrations"
COPY --from=backend-builder /build/backend/alembic.ini "${APP_DIR}/backend/alembic.ini"
COPY --from=backend-builder /build/backend/pyproject.toml "${APP_DIR}/backend/pyproject.toml"

# Frontend: built SSR server + production node_modules
COPY --from=frontend-builder /build/frontend/build "${APP_DIR}/frontend/build"
COPY --from=frontend-builder /build/frontend/node_modules "${APP_DIR}/frontend/node_modules"
COPY --from=frontend-builder /build/frontend/package.json "${APP_DIR}/frontend/package.json"
# The production entry: it fronts the adapter when ORIGIN is set, else loads build/index.js.
COPY --from=frontend-builder /build/frontend/scripts/serve.ts "${APP_DIR}/frontend/scripts/serve.ts"

# Data directory + permissions
RUN mkdir -p "${CONFIG_DIR}/data" && \
    chmod -R u=rwX,go=rX "${APP_DIR}"

# s6 services
COPY root/ /
RUN find /etc/s6-overlay/s6-rc.d -name "run*" -execdir chmod +x {} +
