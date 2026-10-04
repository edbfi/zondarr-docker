# Zondarr Docker image — retained release channel

This branch retains historical packaging. Its legacy build and update workflows
are disabled. The maintained build channel is `nightly`; do not treat a nightly
image as a stable release.

For current installation instructions, Docker Compose examples and published
image tags, use the [Zondarr container documentation](https://web.edb.fi/containers/zondarr/)
and the [maintained nightly README](https://github.com/edbfi/zondarr-docker/blob/nightly/README.md).
The historical Compose example has been removed to avoid recommending obsolete
image names and runtime settings.

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
`stop_grace_period`).

## License

- Docker packaging: [GPL-3.0 license](LICENSE).
- Application: [AGPL-3.0 source repository](https://github.com/edbfi/zondarr).
