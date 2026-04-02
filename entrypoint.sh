#!/bin/bash
# If POSTGRES_DB is comma-separated, split it:
# - first value becomes the primary database (as the base image expects)
# - remaining values are stored in POSTGRES_EXTRA_DATABASES for the init script

if [[ "${POSTGRES_DB:-}" == *","* ]]; then
    IFS=',' read -ra _DBS <<< "$POSTGRES_DB"
    export POSTGRES_DB="${_DBS[0]}"
    remaining=("${_DBS[@]:1}")
    export POSTGRES_EXTRA_DATABASES="$(IFS=','; echo "${remaining[*]}")"
fi

exec docker-entrypoint.sh "$@"
