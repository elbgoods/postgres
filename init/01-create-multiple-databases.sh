#!/bin/bash
# Creates databases listed in POSTGRES_EXTRA_DATABASES (comma-separated).
# These are the values after the first in a comma-separated POSTGRES_DB.
# Each database is owned by POSTGRES_USER and gets the extensions this image variant ships.

set -euo pipefail

# In dependency order; extensions the variant doesn't ship (vector, timescaledb in the -postgis tags) are skipped.
EXTENSIONS="postgis,postgis_topology,fuzzystrmatch,postgis_tiger_geocoder,vector,pg_trgm,pg_stat_statements,timescaledb"

create_extensions() {
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$1" <<-EOSQL
        SELECT format('CREATE EXTENSION IF NOT EXISTS %I', wanted.name)
        FROM unnest(string_to_array('$EXTENSIONS', ',')) WITH ORDINALITY AS wanted(name, position)
        JOIN pg_available_extensions available ON available.name = wanted.name
        ORDER BY wanted.position\gexec
EOSQL
}

create_database() {
    local db="$1"
    echo "Creating database: $db"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        SELECT 'CREATE DATABASE "$db" OWNER "$POSTGRES_USER"'
        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db')\gexec
EOSQL
    create_extensions "$db"
}

if [ -n "${POSTGRES_EXTRA_DATABASES:-}" ]; then
    echo "Creating extra databases: $POSTGRES_EXTRA_DATABASES"
    IFS=',' read -ra DATABASES <<< "$POSTGRES_EXTRA_DATABASES"
    for db in "${DATABASES[@]}"; do
        db="$(echo -e "${db}" | tr -d '[:space:]')"
        [ -n "$db" ] && create_database "$db"
    done
fi

# Ensure PostGIS is available in the primary database
echo "Enabling extensions in primary database: $POSTGRES_DB"
create_extensions "$POSTGRES_DB"
