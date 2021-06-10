#!/bin/bash

# This script is to only be used if there is a bug in the PostgreSQL image and all TimescaleDB images need to be rebuild to fix the bug.

DOCKER_ORG=lloydalbin
DOCKER_IMAGE_NAME_POSTGRES=postgres
DOCKER_IMAGE_NAME_TIMESCALE=timescaledb
DOCKER_USERNAME=lloydalbin
declare -a PGVERSION_Array=("pg9.6" "pg10" "pg11" "pg12" )
declare -a TSVERSION_Array=("1.5.0" "1.5.1" "1.6.0" "1.6.1" "1.7.0" "1.7.1" "1.7.2" "1.7.3" "1.7.4" "1.7.5" )

for TSVERSION in ${TSVERSION_Array[@]}; do
    for PGVERSION in ${PGVERSION_Array[@]}; do
        echo "$DOCKER_PASSWORD" | docker login -u $DOCKER_USERNAME --password-stdin
        ~/timescaledb-docker/build_timescaledb.sh -v -v -v -V -pgv $PGVERSION -tsv $TSVERSION --org $DOCKER_ORG --pg_name $DOCKER_IMAGE_NAME_POSTGRES --ts_name $DOCKER_IMAGE_NAME_TIMESCALE --push --clean --override_exit --push_force
        docker logout
    done 
done 

declare -a PGVERSION_Array=("pg11" "pg12" )
declare -a TSVERSION_Array=("2.0.0" "2.0.1" "2.0.2" )

for TSVERSION in ${TSVERSION_Array[@]}; do
    for PGVERSION in ${PGVERSION_Array[@]}; do
        echo "$DOCKER_PASSWORD" | docker login -u $DOCKER_USERNAME --password-stdin
        ~/timescaledb-docker/build_timescaledb.sh -v -v -v -V -pgv $PGVERSION -tsv $TSVERSION --org $DOCKER_ORG --pg_name $DOCKER_IMAGE_NAME_POSTGRES --ts_name $DOCKER_IMAGE_NAME_TIMESCALE --push --clean --override_exit --push_force
        docker logout
    done 
done 

declare -a PGVERSION_Array=("pg11" "pg12" "pg13" )
declare -a TSVERSION_Array=("2.1.0" "2.1.1" "2.2.0" "2.2.1" "2.3.0" )

for TSVERSION in ${TSVERSION_Array[@]}; do
    for PGVERSION in ${PGVERSION_Array[@]}; do
        echo "$DOCKER_PASSWORD" | docker login -u $DOCKER_USERNAME --password-stdin
        ~/timescaledb-docker/build_timescaledb.sh -v -v -v -V -pgv $PGVERSION -tsv $TSVERSION --org $DOCKER_ORG --pg_name $DOCKER_IMAGE_NAME_POSTGRES --ts_name $DOCKER_IMAGE_NAME_TIMESCALE --push --clean --override_exit --push_force
        docker logout
    done 
done 

#declare -a PGVERSION_Array=("pg12" "pg13" )
#declare -a TSVERSION_Array=("2.4.0" )
#
#for TSVERSION in ${TSVERSION_Array[@]}; do
#    for PGVERSION in ${PGVERSION_Array[@]}; do
#        echo "$DOCKER_PASSWORD" | docker login -u $DOCKER_USERNAME --password-stdin
#        ~/timescaledb-docker/build_timescaledb.sh -v -v -v -V -pgv $PGVERSION -tsv $TSVERSION --org $DOCKER_ORG --pg_name $DOCKER_IMAGE_NAME_POSTGRES --ts_name $DOCKER_IMAGE_NAME_TIMESCALE --push --clean --override_exit --push_force
#        docker logout
#    done 
#done 

