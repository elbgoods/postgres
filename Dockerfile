FROM postgres:17-alpine

RUN apk add --no-cache postgis

COPY entrypoint.sh /usr/local/bin/elbgoods-entrypoint.sh
COPY init/ /docker-entrypoint-initdb.d/

RUN chmod +x /usr/local/bin/elbgoods-entrypoint.sh \
    && chmod +x /docker-entrypoint-initdb.d/*.sh

ENTRYPOINT ["/usr/local/bin/elbgoods-entrypoint.sh"]
CMD ["postgres"]
