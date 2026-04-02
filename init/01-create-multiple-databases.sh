#!/bin/bash
# Creates additional databases listed in POSTGRES_MULTIPLE_DATABASES (comma-separated).
# Each database is owned by POSTGRES_USER and gets the PostGIS extension.
# The primary database defined in POSTGRES_DB is already created by the base image.

set -euo pipefail

create_database() {
    local db="$1"
    echo "Creating database: $db"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        SELECT 'CREATE DATABASE "$db" OWNER "$POSTGRES_USER"'
        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db')\gexec
        \connect "$db"
        CREATE EXTENSION IF NOT EXISTS postgis;
        CREATE EXTENSION IF NOT EXISTS postgis_topology;
        CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
        CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;
EOSQL
}

if [ -n "${POSTGRES_MULTIPLE_DATABASES:-}" ]; then
    echo "Creating additional databases: $POSTGRES_MULTIPLE_DATABASES"
    IFS=',' read -ra DATABASES <<< "$POSTGRES_MULTIPLE_DATABASES"
    for db in "${DATABASES[@]}"; do
        db="$(echo -e "${db}" | tr -d '[:space:]')"
        if [ "$db" != "$POSTGRES_DB" ]; then
            create_database "$db"
        fi
    done
fi

# Ensure PostGIS is available in the primary database
echo "Enabling PostGIS in primary database: $POSTGRES_DB"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS postgis;
    CREATE EXTENSION IF NOT EXISTS postgis_topology;
    CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
    CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;
EOSQL
