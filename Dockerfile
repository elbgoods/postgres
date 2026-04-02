FROM postgis/postgis:17-3.5

COPY entrypoint.sh /usr/local/bin/elbgoods-entrypoint.sh
COPY init/ /docker-entrypoint-initdb.d/

RUN chmod +x /usr/local/bin/elbgoods-entrypoint.sh \
    && chmod +x /docker-entrypoint-initdb.d/*.sh

ENTRYPOINT ["/usr/local/bin/elbgoods-entrypoint.sh"]
CMD ["postgres"]
