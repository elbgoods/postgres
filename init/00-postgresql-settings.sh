#!/bin/bash
# Applies PostgreSQL settings based on MODE environment variable.
# MODE=development (default): fast, unsafe — ideal for pg_restore and local dev.
# MODE=production: tuned for 8GB RAM / 4 cores baseline.
# All values can be overridden at runtime via: command: postgres -c key=value

set -euo pipefail

MODE="${MODE:-development}"

cat >> "$PGDATA/postgresql.conf" <<'EOF'

# elbgoods defaults — override via docker-compose command: postgres -c key=value
# (shared_preload_libraries is baked into postgresql.conf.sample at build time
#  so it's loaded for initdb-time CREATE EXTENSION; see Dockerfile.)

# Planner (assumes SSD)
random_page_cost               = 1.1
effective_io_concurrency       = 200
default_statistics_target      = 100

# Locale / time
timezone                       = 'UTC'
log_timezone                   = 'UTC'
EOF

if [ "$MODE" = "production" ]; then
    cat >> "$PGDATA/postgresql.conf" <<'EOF'

# Production settings (8GB RAM / 4 cores baseline)

# Memory
shared_buffers                 = 2GB
work_mem                       = 64MB
maintenance_work_mem           = 512MB
effective_cache_size           = 6GB

# WAL / checkpoints
wal_buffers                    = 64MB
min_wal_size                   = 1GB
max_wal_size                   = 4GB
checkpoint_completion_target   = 0.9

# Safety
fsync                          = on
synchronous_commit             = on
full_page_writes               = on

# Connections
max_connections                = 100

# Parallelism
max_worker_processes           = 8
max_parallel_workers_per_gather = 2
max_parallel_workers           = 4
max_parallel_maintenance_workers = 2
EOF
    echo "Applied elbgoods PRODUCTION postgresql settings"
else
    cat >> "$PGDATA/postgresql.conf" <<'EOF'

# Development settings (fast, unsafe — optimized for pg_restore)

# Memory
shared_buffers                 = 256MB
work_mem                       = 16MB
maintenance_work_mem           = 256MB
effective_cache_size           = 1GB

# WAL / checkpoints
wal_buffers                    = 16MB
min_wal_size                   = 2GB
max_wal_size                   = 8GB
checkpoint_completion_target   = 0.9

# Safety (disabled for speed)
fsync                          = off
synchronous_commit             = off
full_page_writes               = off

# Connections
max_connections                = 100
max_locks_per_transaction      = 256
EOF
    echo "Applied elbgoods DEVELOPMENT postgresql settings"
fi
