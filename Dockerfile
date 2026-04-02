FROM postgres:17

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgis \
        postgresql-17-postgis-3 \
        postgresql-17-postgis-3-scripts \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/elbgoods-entrypoint.sh
COPY init/ /docker-entrypoint-initdb.d/

RUN chmod +x /usr/local/bin/elbgoods-entrypoint.sh \
    && chmod +x /docker-entrypoint-initdb.d/*.sh

ENTRYPOINT ["/usr/local/bin/elbgoods-entrypoint.sh"]
CMD ["postgres"]
