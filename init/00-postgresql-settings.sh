#!/bin/bash
# Applies sensible default settings to postgresql.conf.
# All values can be overridden at runtime via: command: postgres -c key=value

set -euo pipefail

cat >> "$PGDATA/postgresql.conf" <<'EOF'

# elbgoods defaults — override via docker-compose command: postgres -c key=value

# Memory
shared_buffers                 = 256MB
work_mem                       = 16MB
maintenance_work_mem           = 256MB
effective_cache_size           = 1GB

# WAL / checkpoints
wal_buffers                    = 16MB
min_wal_size                   = 512MB
max_wal_size                   = 2GB
checkpoint_completion_target   = 0.9

# Planner (assumes SSD)
random_page_cost               = 1.1
effective_io_concurrency       = 200
default_statistics_target      = 100

# Connections
max_connections                = 100

# Locale / time
timezone                       = 'UTC'
log_timezone                   = 'UTC'
EOF

echo "Applied elbgoods default postgresql settings"
