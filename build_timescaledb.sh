#!/bin/bash
# POSIX

# Initialize all the option variables.
# This ensures we are not contaminated by variables from the environment.
ORG="lloydalbin"
PG_NAME="postgres"
TS_NAME="timescaledb"
TS_VER=
TS_PREV_VER=
TS_CURRENT_VER=
PG_VER="pg12"
PG_VER_NUMBER=$( echo $PG_VER | cut -c3-)
verbose=0
timescaledb=0
version=0
build_location=~
git=0
patch=0
build=0
push=0
push_only=0
push_force=0
clean=0
clean_location=
override_exit=0

# Usage info
show_help()
{
	cat << EOF
Usage: ${0##*/} [-hv] [-o ORGANIZATION]
	-h/--help					display this help and exit
	-o/--org ORGANIZATION		insert the organization name into the docker name ORGANIZATION/NAME:VERSION - Default: lloydalbin
	-pn/--pg_name NAME			insert the Poistgres name into the docker name ORGANIZATION/NAME:VERSION - Default: postgres
	-tn/--ts_name NAME			insert the TimescaleDB name into the docker name ORGANIZATION/NAME:VERSION - Default: timescaledb
	-v							verbose mode. Can be used multiple times for increased verbosity
								MUST precede the -c command
	-c/--clean					remove both repositories and exit
	--override_exit				override exit after removing repository
	-c/--clean REPOSITORY		remove specific repository and exit
	--location					root repository location - Default: ~
	-V/--version				show version information
	--git						get from repository - Default: --git --patch --build
	--patch						patch the repository - Default: --git --patch --build
	--build						build the repository - Default: --git --patch --build
	--push						push to repository
	--push_only					push to repository and skip building (do not use with --push)
	--push_force				push to repository even if the image already exists (also requires --push or --push_only)
	-pgv/--pgversion VERSION	Overrides the default PostgreSQL version. - Default: $PG_VER
	-tsv/--tsversion VERSION	Overrides the default TimescaleDB version. - Default: $TS_VER

EOF
}

# Version Info
version_info()
{
	cat << EOF
build_timescaledb 0.01
Copyright (C) 2019-2020 Fred Hutchinson Cancer Research Center
License Apache-2.0: Apache version 2 or later.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by Lloyd Albin

EOF
}

die() 
{
	printf '%s\n' "$1" >&2
	exit 1
}

print_verbose()
{
	if [ $verbose -ge $1 ]; then
		echo "$2"
	fi
}

function docker_tag_exists() {
	# https://stackoverflow.com/questions/30543409/how-to-check-if-a-docker-image-with-a-specific-tag-exist-locally
    curl --silent -f -lSL https://index.docker.io/v1/repositories/$1/tags/$2 > /dev/null
}

git_push()
{
	# git_push timescaledb ORG NAME $build_location PG_VER
	print_verbose 1 "Push TimescaleDB Docker Image"

	# TimescaleDB
	if [ $2 -eq 1 ]; then
		VERSION=$( awk '/^ENV TIMESCALEDB_VERSION/ {print $3}' $5/timescaledb-docker/Dockerfile )
		print_verbose 3 "Timescale Version: $VERSION from $5/timescaledb-docker/Dockerfile"

		print_verbose 2 "Pushing Docker Image: $3/$4:$VERSION-$6"
		docker push $3/$4:$VERSION-$6
        
        TS_CURRENT_VER=$( awk '/^ENV TIMESCALEDB_VERSION/ {print $3}' $5/timescaledb-docker/Dockerfile_org )
		if [ $TS_CURRENT_VER == $VERSION ]; then
            # Test if $4 is the most current GitHub Tag
            print_verbose 2 "Pushing Docker Image: $3/$4:latest-$6"
            docker push $3/$4:latest-$6

            local CURRENT_PG_VERSION=$( awk '/^PG_VER=/ {print $1}' ~/timescaledb-docker/Makefile )
            #print_verbose 2 "Current PG Version: ${CURRENT_PG_VERSION:7}"
    		if [ $6 = ${CURRENT_PG_VERSION:7} ]; then
                #if [ $6 = "pg12" ]; then
                print_verbose 2 "Pushing Docker Image: $3/$4:latest"
                docker push $3/$4:latest
            fi
		fi
	fi

}

git_update()
{
	# This code was tweaked from the example at 
	# https://stackoverflow.com/questions/3258243/check-if-pull-needed-in-git

	GIT_PATH=$1
	GIT_REPOSITORY=$2
	GIT_QUIET="--quiet"
	GIT_VER=$3
	if [ $verbose -ge 2 ]; then
		GIT_QUIET=
	fi

	# If GIT_PATH does not exist then clone from repository
	if [ ! -d ${GIT_PATH} ]; then
		print_verbose 1 "Cloning from repository: ${GIT_REPOSITORY} to ${GIT_PATH}"
		git clone ${GIT_REPOSITORY} ${GIT_PATH} ${GIT_QUIET}
	fi

	UPSTREAM="HEAD"
	LOCAL=$(git -C ${GIT_PATH} rev-parse ${UPSTREAM})
	REMOTE=$(git -C ${GIT_PATH} rev-parse "${UPSTREAM}")
	BASE=$(git -C ${GIT_PATH} merge-base HEAD "${UPSTREAM}")

	if [ $LOCAL = $REMOTE ]; then
		print_verbose 1 "Repository Up-to-date: ${GIT_PATH}"
	elif [ $LOCAL = $BASE ]; then
		print_verbose 1 "Need to pull repository: ${GIT_PATH}"
		git -C ${GIT_PATH} pull ${GIT_QUIET}
	elif [ $REMOTE = $BASE ]; then
		print_verbose 1 "Need to push repository: ${GIT_PATH}"
	else
		print_verbose 1 "Repository has Diverged: ${GIT_PATH}"
	fi
}

clean_git()
{
	# clean REPOSITORY_LOCATION
	print_verbose 1 "Removing Repository $1"
	rm -rf $1
}

clean_docker()
{
	# Remove the docker images with REPOSITORY = <none> and TAG = <none>
	print_verbose 1 "Removing Docker Images with REPOSITORY = <none> and TAG = <none>"
	docker images | awk '/^<none>/{print $3}' | xargs docker rmi
	docker system prune -f
}

function check_git_to_docker()
{
	print_verbose 3 "Starting Check"
	#ENV TIMESCALEDB_VERSION 2.0.0-rc2
	local ts_docker_version=$( awk '/^ENV TIMESCALEDB_VERSION/ {print $3}' $build_location/timescaledb-docker/Dockerfile )
	print_verbose 3 "Found GIT Version: $ts_docker_version"

	# TimescaleDB
	print_verbose 3 "Checking for Docker Version: $ORG/$TS_NAME:$ts_docker_version-$PG_VER"
	if docker_tag_exists $ORG/$TS_NAME $ts_docker_version-$PG_VER; then
		print_verbose 3 "Docker Matches GIT Version"
		return 0
	else
		print_verbose 3 "Docker DOES NOT Match GIT Version"
		return 1
	fi
}

timescaledb_patch()
{
	#print_verbose 1 "Checking out TimescaleDB version: $TS_VER"
	#git checkout $TS_VER

    cp $1/timescaledb-docker/Dockerfile $1/timescaledb-docker/Dockerfile_org

	# timescaledb_patch $build_location $ORG $PG_NAME
	print_verbose 1 "Patching TimescaleDB Repository: $1/timescaledb-docker/Dockerfile"
	TS_CURRENT_VER=$( awk '/^ENV TIMESCALEDB_VERSION/ {print $3}' $1/timescaledb-docker/Dockerfile )
	sed -i "s#FROM postgres:#FROM $2/$3:#g" $1/timescaledb-docker/Dockerfile

	# Use a specific version of timescaledb
	if [ ! -z "$GIT_VER" ]; then
		sed -i "s/ENV TIMESCALEDB_VERSION .*$/ENV TIMESCALEDB_VERSION ${GIT_VER}/g" $1/timescaledb-docker/Dockerfile
        if [[ $GIT_VER == "1.7.0" && $PG_VER == "pg12" ]]; then
            # Replace pg12 with pg11 as pg12 did not exist for previous version 1.6.1
            sed -i "s/timescaledb:\${PREV_TS_VERSION}-pg\${PG_VERSION}\${PREV_EXTRA} AS oldversions/timescaledb:\${PREV_TS_VERSION}-pg11\${PREV_EXTRA} AS oldversions/g" $1/timescaledb-docker/Dockerfile
        fi
	fi
}

timescaledb_build()
{
	if [[ -f $1/timescaledb-docker/.build_$VERSION_$5 ]]; then
		print_verbose 1 "Skipping Building Postgres Docker Image: $1/postgres/$4/alpine"
	else
		# timescaledb_build $build_location $ORG $TS_NAME $PG_VER_NUMBER $PG_VER
		print_verbose 1 "Building TimescaleDB Docker Image: $1/timescaledb-docker"
		VERSION=$( awk '/^ENV TIMESCALEDB_VERSION/ {print $3}' $1/timescaledb-docker/Dockerfile )
        wget --directory-prefix=$1/timescaledb-docker https://raw.githubusercontent.com/timescale/timescaledb/$VERSION/version.config
		local PREV_VERSION=$( awk '/^update_from_version =/ {print $3}' $1/timescaledb-docker/version.config )
		print_verbose 3 "Timescale Version: $VERSION"
		print_verbose 3 "Timescale Previous Version: $PREV_VERSION"
		
		# Build exact TimescaleDB Version
		print_verbose 2 "Building Docker Image: $2/$3:$VERSION-$5 in $1/timescaledb-docker"
		docker build --no-cache=true --build-arg PG_VERSION=$4 --build-arg PREV_TS_VERSION=$PREV_VERSION -t $2/$3:$VERSION-$5 $1/timescaledb-docker

		# Tag Latest TimescaleDB Version
        if [ $TS_CURRENT_VER == $VERSION ]; then
            print_verbose 2 "Tagging Docker Image: $2/$3:latest-$5 from $2/$3:$VERSION-$5"
            docker tag $2/$3:$VERSION-$5 $2/$3:latest-$5

            local CURRENT_PG_VERSION=$( awk '/^PG_VER=/ {print $1}' ~/timescaledb-docker/Makefile )
            print_verbose 2 "Current PG Version: ${CURRENT_PG_VERSION:7}"
    		if [ $5 = ${CURRENT_PG_VERSION:7} ]; then
                # Build Latest TimescaleDB Version for Specific Postgres Version
                print_verbose 2 "Tagging Docker Image: $2/$3:latest from $2/$3:$VERSION-$5"
                docker tag $2/$3:$VERSION-$5 $2/$3:latest
            fi
        fi

		touch $1/timescaledb-docker/.build_$VERSION_$5
	fi
}

# Example from http://mywiki.wooledge.org/BashFAQ/035
while :; do
    case $1 in
		-h|-\?|--help)
			show_help    # Display a usage synopsis.
			exit
			;;
        -o|--org)       # Takes an option argument; ensure it has been specified.
			if [ "$2" ]; then
				ORG=$2
				shift
			else
				die 'ERROR: "-o or --org" requires a non-empty option argument.'
			fi
			;;
		-o=?*|--org=?*)
			ORG=${1#*=} # Delete everything up to "=" and assign the remainder.
			;;
		-o=|--org=)         # Handle the case of an empty --org=
			die 'ERROR: "-o or --org" requires a non-empty option argument.'
			;;
        -pn|--pg_name)       # Takes an option argument; ensure it has been specified.
			if [ "$2" ]; then
				PG_NAME=$2
				shift
			else
				die 'ERROR: "-pn or --pg_name" requires a non-empty option argument.'
			fi
			;;
		-pn=?*|--pg_name=?*)
			PG_NAME=${1#*=} # Delete everything up to "=" and assign the remainder.
			;;
		-pn=|--pg_name=)         # Handle the case of an empty --pg_name=
			die 'ERROR: "-pn or --pg_name" requires a non-empty option argument.'
			;;
        -tn|--ts_name)       # Takes an option argument; ensure it has been specified.
			if [ "$2" ]; then
				TS_NAME=$2
				shift
			else
				die 'ERROR: "-tn or --tg_name" requires a non-empty option argument.'
			fi
			;;
		-tn=?*|--ts_name=?*)
			TS_NAME=${1#*=} # Delete everything up to "=" and assign the remainder.
			;;
		-tn=|--ts_name=)         # Handle the case of an empty --ts_name=
			die 'ERROR: "-tn or --tg_name" requires a non-empty option argument.'
			;;
        -pgv|--pgversion)       # Takes an option argument; ensure it has been specified.
			if [ "$2" ]; then
				PG_VER=$2
				PG_VER_NUMBER=$( echo $PG_VER | cut -c3-)
				shift
			else
				die 'ERROR: "-pgv or --pgversion" requires a non-empty option argument.'
			fi
			;;
		-pgv=?*|--pgversion=?*)
			PG_VER=${1#*=} # Delete everything up to "=" and assign the remainder.
			PG_VER_NUMBER=$( echo $PG_VER | cut -c3-)
			;;
		-pgv=|--pgversion=)         # Handle the case of an empty --pgversion=
			die 'ERROR: "-pgv or --pgversion" requires a non-empty option argument.'
			;;
        -tsv|--tsversion)       # Takes an option argument; ensure it has been specified.
			if [ "$2" ]; then
				TS_VER=$2
				shift
			else
				die 'ERROR: "-tsv or --tsversion" requires a non-empty option argument.'
			fi
			;;
		-tsv=?*|--tsversion=?*)
			TS_VER=${1#*=} # Delete everything up to "=" and assign the remainder.
			;;
		-tsv=|--tsversion=)         # Handle the case of an empty --pgversion=
			die 'ERROR: "-tsv or --tsversion" requires a non-empty option argument.'
			;;
        --location)       # Takes an option argument; ensure it has been specified.
			if [ "$2" ]; then
				build_location=$2
				shift
			else
				die 'ERROR: "--location" requires a non-empty option argument.'
			fi
			;;
		--location=?*)
			build_location=${1#*=} # Delete everything up to "=" and assign the remainder.
			;;
		--location=)         # Handle the case of an empty --location=
			die 'ERROR: "--location" requires a non-empty option argument.'
			;;
        -c|--clean)       # Takes an option argument; ensure it has been specified.
			if [ "$2" ]; then
				if [[ "-${2:0:1}" == "--" ]]; then
					clean=$((clean + 1))  # Each -v adds 1 to verbosity.
				else
					clean_location=$2
					shift
				fi
			else
				clean=$((verbose + 1))  # Each -v adds 1 to verbosity.
			fi
			;;
		-c=?*|--clean=?*)
			clean_location=${1#*=} # Delete everything up to "=" and assign the remainder.
			;;
		-c=|--clean=)         # Handle the case of an empty --clean=
			die 'ERROR: "-c or --clean" requires a non-empty option argument.'
			;;
		--override_exit)
			override_exit=1
			;;
        -v|--verbose)
			verbose=$((verbose + 1))  # Each -v adds 1 to verbosity.
        	;;
        -V|--version)
			version=1
        	;;
        --push)
			push=1
        	;;
        --push_only)
			push_only=1
        	;;
        --push_force)
			push_force=1
        	;;
		--)              # End of all options.
			shift
			break
			;;
		-?*)
			printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
			;;
        *) # Default case: No more options, so break out of the loop.
			break
    esac
    shift
done

if [ $timescaledb -eq "0" ]; then
	# If neither was set, then set them both
	timescaledb=1
fi

if [ $version -eq "1" ]; then
	version_info
fi

print_verbose 3 "Verbose level: $verbose"
print_verbose 3 "Organization Name: $ORG"
print_verbose 3 "Postgres Name: $PG_NAME"
print_verbose 3 "TimescaleDB Name: $TS_NAME"
print_verbose 3 "TimescaleDB Version: $TS_VER"
print_verbose 3 "Postgres Version: $PG_VER"
print_verbose 3 "Postgres Version Number: $PG_VER_NUMBER"
print_verbose 3 "Clone/Pull Repositories: $git"
print_verbose 3 "Patch Repositories: $patch"
print_verbose 3 "Build Docker Images: $build"
print_verbose 3 "Push Docker Images (With Build): $push"
print_verbose 3 "Push Docker Images (No Build): $push_only"
print_verbose 3 "Cleaning Level: $clean"
print_verbose 3 "Cleaning Location: $clean_location"
print_verbose 3 "Show Version Information: $version"
print_verbose 3 "Override Exit: $override_exit"
print_verbose 3 "Build Location: $build_location"
print_verbose 3 "Process TimescaleDB: $timescaledb"
print_verbose 3 ""

if [ $clean -ge 1 ]; then
	clean_git ~/timescaledb-docker
	if [ $clean -ge 2 ]; then
		clean_docker
	fi
	if [ $override_exit -eq 0 ]; then
		exit
	fi
fi

if [[ ! -z $clean_location ]]; then
	clean_git "$build_location/$clean_location"
	if [ $override_exit -eq 0 ]; then
		exit
	fi
fi

if [ $timescaledb -eq 1 ]; then
	print_verbose 1 ""
fi

if [ $timescaledb -eq 1 ]; then
	if [ $push_only -eq 1 ]; then
		git_push 0 $push_only $ORG $TS_NAME $build_location $PG_VER
	else
		# Get/Update Repository
		git_update $build_location/timescaledb-docker https://github.com/timescale/timescaledb-docker.git $TS_VER
        # Patch Makefile
        timescaledb_patch $build_location $ORG $PG_NAME
		check_git_to_docker
		check_val=$?
		if [ $check_val -eq "1" ]; then
			do_build=1
		else
			print_verbose 3 "Test Failed???"
			if [ $push_force -eq 1 ]; then
				do_build=1
			else
				do_build=0
			fi
		fi
		if [ $do_build -eq 1 ]; then
            # Build Docker Image
            timescaledb_build $build_location $ORG $TS_NAME $PG_VER_NUMBER $PG_VER
		fi
		if [ $push -eq 1 ]; then
			git_push 0 $push $ORG $TS_NAME $build_location $PG_VER
		fi
	fi
fi

if [ $clean -ge 2 ]; then
	clean_docker
fi

