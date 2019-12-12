FROM postgres:9.6.16-alpine

LABEL maintainer="lu@cobrainer.com"
LABEL org="Cobrainer GmbH"

ARG PG_POSTGRES_PWD=postgres
ARG DBUSER=someuser
ARG DBUSER_PWD=P@ssw0rd
ARG DBNAME=sampledb
ARG DB_DUMP_FILE=sample-dumps/example.pg

ENV POSTGRES_DB launchpad
ENV POSTGRES_USER postgres
ENV POSTGRES_PASSWORD ${PG_POSTGRES_PWD}
ENV PGDATA /pgdata

COPY wait-for-pg-isready.sh /tmp/wait-for-pg-isready.sh
COPY ${DB_DUMP_FILE} /tmp/pgdump.pg

RUN set -e && \
    nohup bash -c "docker-entrypoint.sh postgres &" && \
    /tmp/wait-for-pg-isready.sh && \
    psql -U postgres -c "CREATE USER ${DBUSER} WITH SUPERUSER CREATEDB CREATEROLE ENCRYPTED PASSWORD '${DBUSER_PWD}';" && \
    psql -U ${DBUSER} -d ${POSTGRES_DB} -c "CREATE DATABASE ${DBNAME} TEMPLATE template0;" && \
    pg_restore -v --no-owner --role=${DBUSER} --exit-on-error -U ${DBUSER} -d ${DBNAME} /tmp/pgdump.pg && \
    psql -U postgres -c "ALTER USER ${DBUSER} WITH NOSUPERUSER;" && \
    rm -rf /tmp/pgdump.pg

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD pg_isready -U postgres -d launchpad