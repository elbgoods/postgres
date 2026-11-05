# Built per PostgreSQL major (PG_MAJOR) and target, one tag each (see .github/workflows/build.yml):
#   postgis → :<major>-postgis  official postgres image + PostGIS only
#   full    → :<major>          + pgvector + TimescaleDB

ARG PG_MAJOR=17

FROM postgres:${PG_MAJOR} AS postgis

# PG_MAJOR is set by the base image.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-$PG_MAJOR-postgis-3 \
        postgresql-$PG_MAJOR-postgis-3-scripts \
    && rm -rf /var/lib/apt/lists/* /usr/share/man/* /usr/share/info/* /usr/share/locale/* \
    && find /usr/share/doc -depth -type f ! -name copyright -delete \
    && find /usr/share/doc -empty -delete

# Preload in the conf template so initdb's temp server has the libraries loaded before
# init scripts run CREATE EXTENSION. postgis-3 is preloaded so a connection doesn't pay
# the library load on its first spatial query.
RUN printf '\nshared_preload_libraries = '\''pg_stat_statements,postgis-3'\''\npg_stat_statements.track = all\n' \
        >> /usr/share/postgresql/postgresql.conf.sample

COPY entrypoint.sh /usr/local/bin/elbgoods-entrypoint.sh
COPY init/ /docker-entrypoint-initdb.d/

RUN chmod +x /usr/local/bin/elbgoods-entrypoint.sh \
    && chmod +x /docker-entrypoint-initdb.d/*.sh

ENTRYPOINT ["/usr/local/bin/elbgoods-entrypoint.sh"]
CMD ["postgres"]

FROM postgis AS full

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl gnupg ca-certificates \
    && echo "deb https://packagecloud.io/timescale/timescaledb/debian/ $(. /etc/os-release && echo $VERSION_CODENAME) main" > /etc/apt/sources.list.d/timescaledb.list \
    && curl -fsSL https://packagecloud.io/timescale/timescaledb/gpgkey | gpg --dearmor -o /etc/apt/trusted.gpg.d/timescaledb.gpg \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        postgis \
        postgresql-$PG_MAJOR-pgvector \
        timescaledb-2-postgresql-$PG_MAJOR \
    && rm -rf /var/lib/apt/lists/* /usr/share/man/* /usr/share/info/* /usr/share/locale/* \
    && find /usr/share/doc -depth -type f ! -name copyright -delete \
    && find /usr/share/doc -empty -delete

# The last shared_preload_libraries line wins; timescaledb hard-requires preloading.
RUN printf 'shared_preload_libraries = '\''pg_stat_statements,postgis-3,timescaledb'\''\n' \
        >> /usr/share/postgresql/postgresql.conf.sample
