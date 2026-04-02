# elbgoods-postgres

Company-wide PostgreSQL + PostGIS Docker image. Multi-arch (amd64 + arm64).

## Image

```
ghcr.io/elbgoods/postgres:17
```

## Usage

```yaml
services:
  postgres:
    image: ghcr.io/elbgoods/postgres:17
    environment:
      POSTGRES_HOST_AUTH_METHOD: trust
      POSTGRES_DB: myapp
      POSTGRES_USER: myapp
    command: >
      postgres
      -c shared_buffers=256MB
      -c max_connections=200
```

## Environment Variables

| Variable | Description |
|---|---|
| `POSTGRES_DB` | Primary database name (created automatically) |
| `POSTGRES_USER` | Database superuser |
| `POSTGRES_PASSWORD` | Password (optional when using `trust` auth) |
| `POSTGRES_HOST_AUTH_METHOD` | Auth method (e.g. `trust`, `md5`, `scram-sha-256`) |
| `POSTGRES_MULTIPLE_DATABASES` | Comma-separated list of additional databases to create |

## Multiple Databases

```yaml
environment:
  POSTGRES_DB: primary
  POSTGRES_USER: myuser
  POSTGRES_MULTIPLE_DATABASES: secondary,analytics
```

All databases are owned by `POSTGRES_USER` and have PostGIS enabled.

## PostGIS

The following extensions are enabled in every database:

- `postgis`
- `postgis_topology`
- `fuzzystrmatch`
- `postgis_tiger_geocoder`

## Build Locally

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t elbgoods-postgres .
```
