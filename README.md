# Usage

## tl;dr

```
docker build -t pg-sample-db:local .
```

This will create a PostgreSQL database docker image on your local machine with a sample pg database `sampledb` restored from `sample-dumps/example.pg`. The binary dump file is a backup created with `pg_dump -Fc` from a sample `pgbench`-generated database.

To launch the database, execute

```
docker run --rm -p 5432:5432 pg-sample-db:local
```

The database will be available at:

- host: localhost
- port: 5432
- dbname: sampledb
- dbuser: someuser
- password: P@ssw0rd

## Reference

Essentially, the Dockerfile performs a database restoring during the docker image building time with such steps:

1. launch the postgres service and ensure it's healthy
2. copy the dump file
3. create necessary db user and initial database
4. restore the dump to the running postgresql db cluster

It supports the customization of:

- `PG_POSTGRES_PWD`: password for the superuser `postgres` (default: `postgres`)
- `DBNAME`: name of the restored database (default: `sampledb`)
- `DBUSER`: user name (and also owner) of the restored database (default: `someuser`)
- `DBUSER_PWD`: password of `DBUSER` (default: `P@ssw0rd`)
- `DB_DUMP_FILE`: db dump file name (default: `sample-dumps/example.pg`). Please be aware that only binary format dump is supported

Therefore, a full version docker build command with all parameters provided would be:

```
docker build \
  --build-arg PG_POSTGRES_PWD=S0m3@Str0ng-PwD \
  --build-arg DBNAME=another_db \
  --build-arg DBUSER=another_user \
  --build-arg DBUSER_PWD=aN0ther%PwD \
  --build-arg DB_DUMP_FILE=some/path/to/another_dump.pg \
  -t whatever_name_you_like:whatever_tag_other_than_latest \
  .
```

## Notes

Theoretically, it is possible to create an image with a big dump restored. However, according to some local tests, this would not considerably improve the database provisioning performance in deployment jobs for production.

Another important shortcoming of creating the image from a big dump is: the database data dir (`/pgdata` in this case) within the container could not be exposed to the host, which means the big chunk of database data dir will have to reside in `/var/lib/docker` on docker host. This will cause the following issues (with the default dockerd daemon config):

1. `/` usually doesn't have enough space for holding such big amount of data
2. database data will not be encrypted if `/` is mounted by an unencrypted disk

As a result, we currently would not suggest to use it in production. While for testing purposes, e.g. by [testcontainers](https://www.testcontainers.org/), this approach is sufficient and recommended.

## Further notes about the `wait-for-pg-isready.sh`

As in the [discussion](https://github.com/docker-library/postgres/issues/146) from the official postgres docker project, the postgres servce will start **twice**, which makes the health checking of postgres difficult. But according to the [comment](https://github.com/docker-library/postgres/issues/146#issuecomment-215856076), the key difference of those two times healthy is:

> when it is listening on the network port via its non-loopback interface, it is ready to accept connections

So the `wait-for-pg-isready.sh` script will use `pg_isready` to check if the db is **really** ready on the non-loopback (other than `127.0.0.1`) nic. This can successfully bypass the first-time fake healthy state.