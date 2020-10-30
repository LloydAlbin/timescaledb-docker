#!/bin/bash

# To install and use
# git clone https://github.com/LloydAlbin/timescaledb-docker.git ~/lloydalbin-timescaledb-docker

DOCKER_ORG=lloydalbin
DOCKER_IMAGE_NAME_POSTGRES=postgres
DOCKER_IMAGE_NAME_TIMESCALE=timescaledb
DOCKER_USERNAME=lloydalbin
declare -a PGVERSION_Array=("pg11" "pg12" )

for PGVERSION in ${PGVERSION_Array[@]}; do
    echo "$DOCKER_PASSWORD" | docker login -u $DOCKER_USERNAME --password-stdin
    ~/lloydalbin-timescaledb-docker/build_timescaledb.sh -v -v -v -V -pgv $PGVERSION --org $DOCKER_ORG --pg_name $DOCKER_IMAGE_NAME_POSTGRES --ts_name $DOCKER_IMAGE_NAME_TIMESCALE --push --clean --override_exit
    # Use the following line to rebuild images even if the images already exist.
    # This is needed if there is an error in the Docker images and it needs replacing.
    #~/timescaledb-docker/build_timescaledb.sh -v -v -v -V -pgv $PGVERSION --org $DOCKER_ORG --pg_name $DOCKER_IMAGE_NAME_POSTGRES --ts_name $DOCKER_IMAGE_NAME_TIMESCALE --push --clean --override_exit --push_force
    docker logout
done 
