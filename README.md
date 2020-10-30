# timescaledb-docker

|Postgresql-TimescaleDB|Build Status|
|:---:|:---:|
|[![2.0.x-pg1](https://img.shields.io/docker/v/lloydalbin/timescaledb/2.0.0-rc1-pg11)](https://hub.docker.com/r/lloydalbin/timescaledb/tags)|[![Build Status](https://travis-matrix-badges.herokuapp.com/repos/LloydAlbin/timescaledb-docker/branches/main/10)](https://www.travis-ci.org/LloydAlbin/timescaledb-docker/builds)|
|[![2.0.x-pg12](https://img.shields.io/docker/v/lloydalbin/timescaledb/2.0.0-rc2-pg12)](https://hub.docker.com/r/lloydalbin/timescaledb/tags)|[![Build Status](https://travis-matrix-badges.herokuapp.com/repos/LloydAlbin/timescaledb-docker/branches/main/13)](https://www.travis-ci.org/LloydAlbin/timescaledb-docker/builds)|
|**License**|![GitHub](https://img.shields.io/github/license/LloydAlbin/timescaledb-docker)|

|Previous Builds|
|:---:|
|[![1.5.x-pg10](https://img.shields.io/docker/v/lloydalbin/timescaledb/1.5.1-pg10)](https://hub.docker.com/r/lloydalbin/timescaledb/tags)|
|[![1.5.x-pg11](https://img.shields.io/docker/v/lloydalbin/timescaledb/1.5.1-pg11)](https://hub.docker.com/r/lloydalbin/timescaledb/tags)|
|[![1.6.x-pg10](https://img.shields.io/docker/v/lloydalbin/timescaledb/1.6.1-pg10)](https://hub.docker.com/r/lloydalbin/timescaledb/tags)|
|[![1.6.x-pg11](https://img.shields.io/docker/v/lloydalbin/timescaledb/1.6.1-pg11)](https://hub.docker.com/r/lloydalbin/timescaledb/tags)|
|[![1.7.x-pg10](https://img.shields.io/docker/v/lloydalbin/timescaledb/1.7.4-pg10)](https://hub.docker.com/r/lloydalbin/timescaledb/tags)|
|[![1.7.x-pg11](https://img.shields.io/docker/v/lloydalbin/timescaledb/1.7.4-pg11)](https://hub.docker.com/r/lloydalbin/timescaledb/tags)|
|[![1.7.x-pg12](https://img.shields.io/docker/v/lloydalbin/timescaledb/1.7.4-pg12)](https://hub.docker.com/r/lloydalbin/timescaledb/tags)|
|[![2.0.x-pg11](https://img.shields.io/docker/v/lloydalbin/timescaledb/2.0.0-rc1-pg11)](https://hub.docker.com/r/lloydalbin/timescaledb/tags)|
|[![2.0.x=pg12](https://img.shields.io/docker/v/lloydalbin/timescaledb/2.0.0-rc1-pg12)](https://hub.docker.com/r/lloydalbin/timescaledb/tags)|

This is a custom builder that is based off the Official TimescaleDB builder. The build script patches the official Dockerfile and then builds using the updated Dockerfile.

The Official TimescaleDB version is created by default using the PostgreSQL Alpine Linux version that does not support LDAP. We need the LDAP support at work, so this repository contains the code to build the TimescaleDB using a custom PostgreSQL Alpine with LDAP support and a few additional extensions.

* [TimescaelDB](https://www.timescale.com/products) - Timescale Database

# TimescaleDB

Download the pg_monitor repository. The make file will also put the postgres and timescaledb-docker repositories into your home directory by default unless you use the location argument.

```bash
cd ~
# Get the pg_monitor repositories
git clone https://github.com/LloydAlbin/pg_monitor.git
```

## Build Custom TimescaleDB

To run the make command, you need to be inside this directory (~/pg_monitor/timescaledb/custom/).

The make command takes some optional options:

* org
* ts_name
* pg_name
* location
* push
* clean

These options help define the docker image names in this format:

* org/pg_name:VERSION aka lloydalbin/postgres:11-alpine
* org/ts_name:VERSION aka lloydalbin/timescaledb:1.5.1-pg11
* location aka ~ meaning ~/postgres and ~/timescaledb-docker for the two repositories needed to be downloaded
* --push aka push docker image(s) to the repsoitory
* --clean aka delete the two repositories

If you have your own inhouse docker registery, then the ORG name should be the name of your inhouse docker registry.

The build script will download the timescaledb-docker repository.

```bash
# For the first time
~/pg_monitor/timescaledb/custom/build_timescaledb.sh
# Using the optional arguments
~/pg_monitor/timescaledb/custom/build_timescaledb.sh --org=lloydalbin --ts_name=timescaledb --pg_name=postgres

# For the second time, otherwise the postgres Dockerfile will get double patched.
~/pg_monitor/timescaledb/custom/build_timescaledb.sh --clean postgres --override_exit
```

### PostgreSQL Versions

The build_timescaledb.sh script has been updated to use PostgreSQL 12, but still works for PostgreSQL 11. To build PostgreSQL 11, just change the PG_VER variable to be pg11.

## Clean / Delete Repositories

If you wish to delete the repositories, you may do so manually or you can use the make command to clean up the postgres & timescaledb-docker repositories.

```bash
# Delete repositories
~/pg_monitor/timescaledb/custom/build_timescaledb.sh --clean
# Optional: Just Postgres
~/pg_monitor/timescaledb/custom/build_timescaledb.sh --clean postgres
# Optional: Just TimescaleDB
~/pg_monitor/timescaledb/custom/build_timescaledb.sh --clean timescaledb
```

## Cron

You can also have these auto-created via a cronjob on an hourly basis.

```cron
# With default arguments
* 0 * * * $HOME/pg_monitor/timescaledb/custom/build_timescaledb.sh
# With optional arguments
* 0 * * * $HOME/pg_monitor/timescaledb/custom/build_timescaledb.sh --org=lloydalbin --ts_name=timescaledb --pg_name=postgres
```
