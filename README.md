# elbgoods-postgres

Company-wide PostgreSQL 17 + PostGIS + pgvector image. Multi-arch (amd64 + arm64).

## Access

The image is hosted on GitHub Container Registry (GHCR) as a private package under the `elbgoods` org.

**Each repository that pulls this image must be granted access explicitly.**
Manage access here: [packages/postgres → Package settings → Manage Actions access](https://github.com/orgs/elbgoods/packages/container/postgres/settings)

To pull locally, authenticate first:

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

## Image

```
ghcr.io/elbgoods/postgres:17
```

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

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `POSTGRES_DB` | yes | Database name(s) — comma-separated to create multiple (first is primary) |
| `POSTGRES_USER` | yes | Database superuser |
| `POSTGRES_PASSWORD` | no | Password — optional when using `trust` auth |
| `POSTGRES_HOST_AUTH_METHOD` | no | Auth method: `trust`, `md5`, `scram-sha-256` (default: `scram-sha-256`) |

## Multiple Databases

Pass a comma-separated list to `POSTGRES_DB`. The first value is the primary database; the rest are created automatically and owned by `POSTGRES_USER`.

```yaml
environment:
  POSTGRES_DB: primary,secondary,analytics
  POSTGRES_USER: myuser
```

## Extensions

The following extensions are enabled automatically in every database:

| Extension | Purpose |
|---|---|
| `postgis` | Spatial/geographic data types and functions |
| `postgis_topology` | Topological data model |
| `postgis_tiger_geocoder` | US address geocoding |
| `fuzzystrmatch` | Fuzzy string matching (required by Tiger geocoder) |
| `vector` | pgvector — vector similarity search / embeddings |
| `pg_trgm` | Trigram-based fuzzy text search and similarity |

## Default PostgreSQL Settings

These defaults are applied at init time and can be overridden via `command`:

| Setting | Default | Notes |
|---|---|---|
| `shared_buffers` | 256MB | Increase for dedicated DB servers |
| `work_mem` | 16MB | Per sort/hash operation |
| `maintenance_work_mem` | 256MB | VACUUM, CREATE INDEX |
| `effective_cache_size` | 1GB | Planner hint |
| `wal_buffers` | 16MB | |
| `min_wal_size` / `max_wal_size` | 512MB / 2GB | |
| `random_page_cost` | 1.1 | Tuned for SSD |
| `effective_io_concurrency` | 200 | Tuned for SSD |
| `timezone` | UTC | |

Override any setting at runtime:

```yaml
command: >
  postgres
  -c shared_buffers=512MB
  -c max_connections=200
```

## Build Locally

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t elbgoods-postgres .
```
