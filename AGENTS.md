# AGENTS.md

Notes for coding agents working on this repo. User-facing docs live in `README.md`; keep the two consistent.

## What this is

A PostgreSQL Docker image built on the official `postgres` image, published to `ghcr.io/elbgoods/postgres`. No application code: just a Dockerfile, two init scripts, an entrypoint wrapper and a CI workflow.

## Layout

- `Dockerfile`: two stages. `postgis` (slim: PostGIS only) and `full` (`FROM postgis`, adds pgvector, TimescaleDB and the `postgis` CLI package). `ARG PG_MAJOR` picks the base image (`17` or `18`).
- `entrypoint.sh`: splits a comma-separated `POSTGRES_DB` into `POSTGRES_DB` (first entry) and `POSTGRES_EXTRA_DATABASES`, then `exec`s the official `docker-entrypoint.sh`.
- `init/00-postgresql-settings.sh`: appends shared and `MODE`-specific (`development`/`production`) settings to `$PGDATA/postgresql.conf`.
- `init/01-create-multiple-databases.sh`: creates the extra databases and enables the extensions in every database.
- `.github/workflows/build.yml`: matrix `pg: [17, 18]` × `target: [full, postgis]`, amd64 + arm64 via QEMU, pushes on `main` and `v*` tags only (PRs build without pushing).

## Things that are easy to get wrong

- **`shared_preload_libraries` lives in `postgresql.conf.sample`, not in the init script.** initdb's temporary server has to have TimescaleDB loaded before `CREATE EXTENSION timescaledb` runs, so it is baked in at build time. The `full` stage appends a second line, and the last one wins. If you add a library that needs preloading, add it to both lines.
- **Init scripts run only once**, when the data directory is empty. Settings changes don't reach existing volumes; say so in the docs when it matters.
- **Extensions are listed once**, in `EXTENSIONS` in `init/01-…`, in dependency order (`postgis` before `postgis_topology`/`postgis_tiger_geocoder`, `fuzzystrmatch` before the geocoder). The script joins against `pg_available_extensions`, so one list serves both variants: extensions a variant doesn't ship are skipped silently.
- **Package names use `$PG_MAJOR`** (set by the base image), so a new major only needs a matrix entry once the Debian packages for it exist (PGDG for PostGIS/pgvector, packagecloud for TimescaleDB).
- **PostgreSQL 18 changed the data path** to `/var/lib/postgresql/18/docker`; volumes mount at `/var/lib/postgresql`. Examples in `README.md` show the 17 path.
- **Tag scheme**: the plain tag `<major><variant>` (`17`, `18-postgis`) is published only from the default branch. Every other tag gets the `-<major><variant>` suffix (`sha-abc1234-17`, `1.2.0-18-postgis`). `latest` is disabled on purpose.
- Keep image layers slim: every `apt-get install` ends with the existing cleanup chain (lists, man, locale, docs except copyright).

## Verifying changes

There is no test suite. Build and boot the variant you touched:

```bash
docker buildx build --load --build-arg PG_MAJOR=17 --target full -t pg-test:17 .
docker run --rm -d --name pg-test -e POSTGRES_HOST_AUTH_METHOD=trust \
  -e POSTGRES_USER=app -e POSTGRES_DB=app,other pg-test:17
docker logs -f pg-test   # wait for "database system is ready to accept connections"
docker exec pg-test psql -U app -d other -c '\dx'
docker exec pg-test psql -U app -c 'SHOW shared_preload_libraries'
docker rm -f pg-test
```

Do the same for `--target postgis` and `PG_MAJOR=18` when you touch the Dockerfile or the init scripts. `--load` builds only for the host platform; the CI covers the other architecture.

## Docs

When you change a setting, an extension, a tag or an env var, update the matching table in `README.md`.
