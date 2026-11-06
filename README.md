# elbgoods/postgres

PostgreSQL image built on the official [`postgres`](https://hub.docker.com/_/postgres) image, with PostGIS, pgvector and TimescaleDB, extensions enabled on init, multiple databases from one env var and dev/prod tuning presets. Multi-arch (amd64 + arm64).

```bash
docker pull ghcr.io/elbgoods/postgres:17
```

Images are published to the GitHub Container Registry on every push to `main` and every `v*` tag.

## Tags

| Tag | PostgreSQL | Extensions |
|---|---|---|
| `17-postgis`, `18-postgis` | 17 / 18 | PostGIS, pg_trgm, pg_stat_statements — slim |
| `17`, `18` | 17 / 18 | + pgvector, TimescaleDB, PostGIS CLI tools — full |

Every other tag carries the variant as suffix: `sha-<commit>-17-postgis`, `main-18`, `1.0.0-17`.

PostgreSQL 18 images keep their data in `/var/lib/postgresql/18/docker`: mount the volume at `/var/lib/postgresql`, not `/var/lib/postgresql/data`.

## Quick start

```yaml
services:
  postgres:
    image: ghcr.io/elbgoods/postgres:17
    ports:
      - "5432:5432"
    environment:
      POSTGRES_HOST_AUTH_METHOD: trust
      POSTGRES_DB: myapp
      POSTGRES_USER: myapp
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

`POSTGRES_HOST_AUTH_METHOD: trust` lets anyone who reaches the port connect without a password. Use it only for local development and set `POSTGRES_PASSWORD` everywhere else.

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `POSTGRES_DB` | yes | Database name(s) — comma-separated to create multiple (first is primary) |
| `POSTGRES_USER` | yes | Database superuser |
| `POSTGRES_PASSWORD` | no | Password — optional when using `trust` auth |
| `POSTGRES_HOST_AUTH_METHOD` | no | Auth method: `trust`, `md5`, `scram-sha-256` (default: `scram-sha-256`) |
| `MODE` | no | `development` (default) or `production` — see [Mode](#mode) below |

## Multiple Databases

Pass a comma-separated list to `POSTGRES_DB`. The first value is the primary database; the rest are created automatically and owned by `POSTGRES_USER`.

```yaml
environment:
  POSTGRES_DB: primary,secondary,analytics
  POSTGRES_USER: myuser
```

## Extensions

The following extensions are enabled automatically in every database, as far as the variant ships them (`vector` and `timescaledb` only in the full tags):

| Extension | Purpose |
|---|---|
| `postgis` | Spatial/geographic data types and functions |
| `postgis_topology` | Topological data model |
| `postgis_tiger_geocoder` | US address geocoding |
| `fuzzystrmatch` | Fuzzy string matching (required by Tiger geocoder) |
| `vector` | pgvector — vector similarity search / embeddings |
| `pg_trgm` | Trigram-based fuzzy text search and similarity |
| `pg_stat_statements` | Query performance statistics |
| `timescaledb` | Time-series data — hypertables, continuous aggregates |

## Mode

The `MODE` environment variable controls PostgreSQL tuning. Default is `development`.

Settings are appended to `postgresql.conf` by an init script, so they are written **once, when the data directory is first initialized**. Changing `MODE` on an existing volume has no effect; use `-c` overrides (below) or recreate the volume.

### `development` (default)

Optimized for speed — disables fsync, synchronous_commit, and full_page_writes for fast pg_restore and local development. **Not safe for data you care about.**

| Setting | Value |
|---|---|
| `shared_buffers` | 256MB |
| `work_mem` | 16MB |
| `maintenance_work_mem` | 256MB |
| `effective_cache_size` | 1GB |
| `wal_buffers` | 16MB |
| `min_wal_size` / `max_wal_size` | 2GB / 8GB |
| `checkpoint_completion_target` | 0.9 |
| `fsync` | off |
| `synchronous_commit` | off |
| `full_page_writes` | off |
| `max_connections` | 100 |
| `max_locks_per_transaction` | 256 |

### `production`

Tuned for a server with 8GB RAM and 4 cores. Override individual settings via `command: postgres -c key=value` for larger machines.

| Setting | Value |
|---|---|
| `shared_buffers` | 2GB |
| `work_mem` | 64MB |
| `maintenance_work_mem` | 512MB |
| `effective_cache_size` | 6GB |
| `wal_buffers` | 64MB |
| `min_wal_size` / `max_wal_size` | 1GB / 4GB |
| `checkpoint_completion_target` | 0.9 |
| `fsync` | on |
| `synchronous_commit` | on |
| `full_page_writes` | on |
| `max_connections` | 100 |
| `max_worker_processes` | 8 |
| `max_parallel_workers` | 4 |
| `max_parallel_workers_per_gather` | 2 |
| `max_parallel_maintenance_workers` | 2 |

### Shared settings (both modes)

| Setting | Value | Notes |
|---|---|---|
| `shared_preload_libraries` | pg_stat_statements,postgis-3 (+ timescaledb in full) | Baked into `postgresql.conf.sample` at build time so extensions load during init; PostGIS preloaded so connections don't load it on first use |
| `pg_stat_statements.track` | all | |
| `random_page_cost` | 1.1 | Tuned for SSD |
| `effective_io_concurrency` | 200 | Tuned for SSD |
| `default_statistics_target` | 100 | |
| `jit` | off | JIT compile cost usually outweighs gains for OLTP queries; enable per session with `SET jit = on` |
| `timezone` / `log_timezone` | UTC | |

Override any setting at runtime:

```yaml
command: >
  postgres
  -c shared_buffers=512MB
  -c max_connections=200
```

## Build locally

```bash
docker buildx build --platform linux/amd64,linux/arm64 --build-arg PG_MAJOR=17 --target postgis -t elbgoods-postgres:17-postgis .
docker buildx build --platform linux/amd64,linux/arm64 --build-arg PG_MAJOR=18 --target full -t elbgoods-postgres:18 .
```

## How it works

| File | Role |
|---|---|
| `Dockerfile` | Two targets: `postgis` (slim) and `full` (extends it). `PG_MAJOR` build arg selects 17 or 18. Bakes `shared_preload_libraries` into `postgresql.conf.sample`. |
| `entrypoint.sh` | Splits a comma-separated `POSTGRES_DB` into the primary database and `POSTGRES_EXTRA_DATABASES`, then hands off to the official entrypoint. |
| `init/00-postgresql-settings.sh` | Appends the shared and `MODE`-specific settings to `postgresql.conf`. |
| `init/01-create-multiple-databases.sh` | Creates the extra databases and enables the extensions in every database. |
| `.github/workflows/build.yml` | Builds and pushes the 2×2 matrix (17/18 × slim/full) for amd64 + arm64. |

## License

[MIT](LICENSE)
